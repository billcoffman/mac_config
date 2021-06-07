#!/usr/bin/perl -w
#===============================================================================
#         FILE:  switch_branch.pl
#        USAGE:  ./switch_branch.pl [<branch-name>]
#
#  DESCRIPTION:  switch branch in a git repository
#                This program doesn't actually change the branch, but puts
#                the new directory in the file ~/.sb/curr  The idea is to
#                support the bash function:
#
#                function sb () { switch_branch.pl $@ && git checkout $(cat ${HOME}/.sb/curr);}
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  Don't run this program directly.
#       AUTHOR:  Bill Coffman, <bill.coffman@gmail.com>
#      LICENSE:  GPL
#      VERSION:  1.0
#      CREATED:  07/01/2015
#     REVISION:  2.0
#===============================================================================

use strict;
use warnings;
#use Getopt::Std;
use Getopt::Long;
use POSIX qw(getcwd strftime tzname);

my $new = shift;

die "Home directory not set (env var HOME).\n" if !defined $ENV{HOME};
die "$ENV{HOME} is not a directory.\n" if !-d $ENV{HOME};
chomp( my $cbranch = `git rev-parse --abbrev-ref HEAD` );
my $dir = "$ENV{HOME}/.sb";
-d $dir || mkdir $dir || die "mkdir $dir failed: $!\n";

my $max  = 20;
my $curr = "$dir/curr";
my $branches = "$dir/branch_hist";
my %documented = %{load_branch_descriptions()};

unless (open DD, $branches) {
    open DD, ">>$branches" or die "$!\n";
    open DD, $branches or die "$!\n";
}
chomp ( my @branches = <DD> );

if (!defined $new) {
    # No comand line argument.  Select from previous branch.

    chomp(my @active_branches = map {substr($_, 2)} `git branch`);
    my %active = map {$_ => 1} @active_branches;
    my @inactive_branches = grep {!exists $active{$_}} @branches;
    @branches = grep {exists $active{$_}} @branches;

    if (@inactive_branches) {
        my $timestamp = strftime("%D %T", localtime()) . " " . [tzname()]->[0];
        open DBR, ">>$dir/deleted_branches" or die "$!\n";
        print DBR map {"$timestamp  $_\n"} @inactive_branches;
        close DBR;
    }

    my $idx=0;
    print map { sprintf "  %2d .. %-35s %4s  %s\n", $idx++, $_, get_doc($_) } @branches;
    $|=1;
    print " branch? ";
    chomp ( $new = <STDIN> );
}
$new = $branches[$new]   if $new =~ m#^\d+$#;
exit unless length $new;

# validate existence of new branch
my $r = system "git rev-parse --verify $new >/dev/null 2>&1";
$r = system "git ls-remote --exit-code . origin/$new >/dev/null 2>&1"   if $r;
die "Cannot sb \"$new\" -- $!\n" if $r;

# update file status.
my %x;
@branches = map { exists $x{$_} ? () : ($x{$_}=$_) } ($new, $cbranch, @branches);
open DD, ">$branches" or die "$!\n";
print DD map {"$_\n"} splice @branches, 0, $max;
open DD, ">$curr" or die "$!\n";
print DD "$new\n";

sub get_doc {
    my ($branch) = @_;
    my $record = exists $documented{$branch} ? $documented{$branch} : undef;
    if ($record) {
        my ($status, $descr) = @$record;
        return ($status, $descr);
    } else {
        return ("", "");
    }
}

sub load_branch_descriptions {

    open my $fh, "../../branch_info" or return {};
    chomp(my @branch_info = <$fh>);
    my %documented;
    for my $line (@branch_info) {
        my ($branch, $status, $description) = split "\t", $line;
        $documented{$branch} = [$status, $description];
    }
    return \%documented;
}
