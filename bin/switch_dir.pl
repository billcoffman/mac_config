#!/usr/bin/perl -w
#===============================================================================
#         FILE:  sd.pl
#        USAGE:  ./sd.pl [<dir>]
#
#  DESCRIPTION:  switch directory  -- shades of vms?
#                This program doesn't actually change the directory, but puts
#                the new directory in the file ~/.sd/curr  The idea is to
#                support the bash function:
#
#                function sd () { sd.pl $@ && cd $(cat ${HOME}/.sd/curr);}
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  Don't run this program directly.
#       AUTHOR:  Bill Coffman, <bill.coffman@gmail.com>
#      LICENSE:  GPL
#      VERSION:  1.0
#      CREATED:  02/04/2007 09:36:30 AM PST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
#use Getopt::Std;
use Getopt::Long;
use POSIX qw(getcwd);

my $new = "@ARGV";

die "Home directory not set (env var HOME).\n" if !defined $ENV{HOME};
die "$ENV{HOME} is not a directory.\n" if !-d $ENV{HOME};
my $cwd = getcwd();
my $dir = "$ENV{HOME}/.sd";
-d $dir || mkdir $dir || die "mkdir $dir failed: $!\n";

my $max  = 20;
my $curr = "$dir/curr";
my $dirs = "$dir/dir_hist";

unless (open DD, $dirs) {
    open DD, ">>$dirs" or die "$!\n";
    open DD, $dirs or die "$!\n";
}
chomp ( my @dirs = <DD> );

if (!length $new) {

    # No comand line argument.  Select from previous dir.
    my $idx=0;
    print map { "  (@{[$idx++]}) $_\n" } @dirs;
    $|=1;
    print " dir? ";
    chomp ( $new = <STDIN> );
}
$new = $dirs[$new]   if $new =~ m#^\d+$#;
exit unless length $new;

# validate existence of new dir, and canonize
die "Cannot sd \"$new\" -- $!\n" if !-d $new;
$new = substr($new,0,1) eq "/" ? $new : "$cwd/$new";
do {
    $new =~ s#/+#/#g;
    $new =~ s#([^/]*)/\.\.(/|$)#/#;
    $new =~ s#/\.(/|$)#/#;
    $new =~ s#/+#/#g;
    $new =~ s#(.)/$#$1#;
} while ( $new =~ m#(/|^)\.\.?(/|$)# );
die "Cannot sd \"$new\" -- $!\n" if !-d $new;

# update file status.
@dirs = map { exists $_{$_} ? () : ($_{$_}=$_) } ($new, $cwd, @dirs);
open DD, ">$dirs" or die "$!\n";
print DD map {"$_\n"} splice @dirs, 0, $max;
open DD, ">$curr" or die "$!\n";
print DD "$new\n";
