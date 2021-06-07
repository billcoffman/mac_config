#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
my ($Dirs, $Files, $Age, $Files_and_dirs, $Unfiltered);
GetOptions("age=s" => \$Age, "total=i" => \$Files_and_dirs,
    "files=i" => \$Files, "dirs=i" => \$Dirs, unfiltered=>\$Unfiltered)
    or die "git status --porcelain is the source, so .gitignore filters
are fully enforced.  Read \"git help status\" for more info.
    
    usage: $0 [ -age <days-back> ] [ -total <total-files-and-dirs> ]
    [ -dirs <max-dirs> ] [ -files <max-files> ] [ -unfiltered ]\n";
if (!(grep {defined} ($Dirs, $Files, $Age, $Files_and_dirs, $Unfiltered))) {
    ($Dirs, $Files) = (6, 12);
}

chdir $ARGV[0] if @ARGV==1;

chomp(my $currdir = `pwd`);
chomp(my $gitroot = `git rev-parse --show-toplevel`);
$currdir = substr($currdir, length $gitroot)
                if $gitroot eq substr $currdir, 0, length $gitroot;
$currdir = substr($currdir, 1)   if substr($currdir, 0, 1) eq '/';
my @currdir = split '/', $currdir;

print `git branch`;
print `pwd`;
my @untracked;
my @add;
for my $file (`git status --porcelain`) {
    $file =~ m/(..) (.*)/;
    my $status = $1;
    $file = $2;
    my @path = split '/', $file;
    my $j = 0;
    while ($j < @path && $j < @currdir && $path[$j] eq $currdir[$j]) {
        $j++;
    }
    for (my $k=0; $k < $j; $k++) {
        shift @path;
    }
    for (my $k=0; $k < @currdir - $j; $k++) {
        unshift @path, '..';
    }
    $file = join('/', @path);
    if ($status eq '??') {
        push @untracked, $file;
    } else {
        print "adding: $status $file\n";
        push @add, $file;
    }
}
system "git add @add";
