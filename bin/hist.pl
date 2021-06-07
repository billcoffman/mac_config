#!/usr/bin/perl
use strict;
use warnings;
use POSIX;

sub archive($$) {
    my ($file, $archive) = @_;
    print "archiving file $file\n";
    open my($fh_in), $file or die "$! reading $file";
    open my($fh_out), ">>", $archive or die "$! appending to $archive";
    while (<$fh_in>) {
        print $fh_out;
    }
    unlink $file;
}

sub timestr($) {
    my ($time) = @_;
    return "<no time specified>"   if $time<0;
    return strftime "%F %T", localtime($time);
}

my %seen;

sub translate($@) {
    my ($file, $pid) = @_;
    print "reading file $file\n";
    my (@hist, @revhist);
    open my($fh), $file or die "$_ reading $file";
    my @lines = <$fh>;
    #print @lines;
    for (my $j=0; $j<@lines; $j++) {
        my $time = -1;
        if ($lines[$j] =~ m/^#(\d+)$/) {
            $time = $1;
            $j++;
        }
        push @hist, [$pid, $time, $lines[$j]];
    }
    return \@hist;
}

sub merge_sort_lists(@) {
    my @lists = @_;
    # use: @triples = merge_sort_lists(@lists);
    my @sorted_triples;
    for (@lists) {
        @sorted_triples = sort {$a->[1] <=> $b->[1] or $a->[0] <=> $b->[0]}
                            @sorted_triples, @$_;
    }
    return @sorted_triples;
}

sub dedup_triples(@) {
    my @triples = @_;
    my (@rev_triples, %seen);
    for (reverse @triples) {
        my ($pid, $time, $line) = @$_;
        next   if exists $seen{$line} && $seen{$line} >= $time;

        $seen{$line} = $time;
        push @rev_triples, $_;
    }
    return reverse @rev_triples;
}

sub format_triples(@) {
    my @triples = @_;
    my @formatted;
    # use: print format_triples(@triples);
    for (@triples) {
        my ($pid, $time, $line) = @$_;
        my $time_string = timestr($time);
        push @formatted, "$time_string $pid $line";
    }
    return @formatted;
}

sub process_uniquely($@) {
    my ($file, $pid) = @_;
    print "uniquely processing file $file\n";
    my (@hist, @revhist);
    open my($fh), $file or die "$_ reading $file";
    my @lines = <$fh>;
    #print @lines;
    for (my $j=0; $j<@lines; $j++) {
        my $time = -1;
        if ($lines[$j] =~ m/^#(\d+)$/) {
            $time = $1;
            $j++;
        }
        push @hist, [$pid, $time, $lines[$j]];
    }
    for (reverse @hist) {
        my ($pid, $time, $line) = @$_;
        next   if exists $seen{$line} && $seen{$line} >= $time;

        $seen{$line} = $time;
        my $time_string = timestr($time);
        push @revhist, "$time_string $pid $line";
    }
    return reverse @revhist;
}

sub process($@) {
    my ($file, $pid) = @_;
    print "processing file $file\n";
    open my($fh), $file or die "$_ reading $file";
    my @lines = <$fh>;
    for (my $j=0; $j<@lines; $j++) {
        my $time = 0;
        if ($lines[$j] =~ m/^#(\d+)$/) {
            $time = $1;
            $j++;
        }
        my $time_string = timestr($time);
        print "$time_string $lines[$j]";
    }
}

my $archive = "$ENV{HOME}/.bash_eternal_history_archive";
my @files = glob "$ENV{HOME}/.bash_eternal_history_*";
#print "Found: ", map {"$_\n"} @files;
my @lists;
for my $file (@files) {
    my ($pid) = ($file =~ m/_(\d+)$/);
    push @lists, translate($file, $pid);
    $pid = 0   unless $pid;
    if (!kill 0, $pid) {
        archive($file, $archive);
    }
}
my @triples = merge_sort_lists(@lists);
print format_triples(dedup_triples(@triples));
