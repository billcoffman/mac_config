#!/usr/bin/perl -w
#===============================================================================
#         FILE:  create_branch.pl
#        USAGE:  ./create_branch.pl [<branch-name>]
#
#  DESCRIPTION:  create branch in git repository
#
#                This program creates the branch and updates the database of files
#                in ~/.sb directory (the switch_branch utility).
#                Adds the new directory to the file ~/.sb/curr file.
#
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Bill Coffman, <bill.coffman@gmail.com>
#      LICENSE:  GPL
#      VERSION:  1.0
#      CREATED:  07/23/2015
#     REVISION:  ---
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
    print " Base? ";
    chomp ( $new = <STDIN> );
}
$new = $branches[$new]   if $new =~ m#^\d+$#;
exit unless length $new;
system "sb $new && gplo";
print "base branch is $new ... what is your new branch name? ";
chomp ( $new = <STDIN> );
print "\nDescription? ";
chomp ( my $descript = <STDIN> );
system "git checkout -b $descript";
open DBR, ">>../../branch_info" or die "$!\n";
print DBR "$new\tLIVE\t$descript\n";

