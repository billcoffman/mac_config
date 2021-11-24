#!/usr/bin/env perl
use strict;
use warnings;

my $start = time;
my $t0 = $start;
my @default_time_fields = split " ", localtime($t0);
my ($day0, $month0, $day_of_month0, $time0, $year0) = @default_time_fields;
my ($day1, $month1, $day_of_month1, $time1, $year1) = @default_time_fields;
my $block_start = "$t0 $day0-$time0, daily duration:   0 min.\n";
my $block_latest = "$t0 $day0-$time0, daily duration:   0 min.\n";
my $full_log = "minutes.log";

my $n_sec = 60;            # Granularity of checks.
my $truncate = 5.0;        # Last seconds assumed inactive before sleep.


sub logg {
    my $log_entry = shift;
    open LOG, ">>", "$full_log" or die "$! $full_log";
    print LOG $log_entry;
    close LOG;
}

sub log_work_block {
    my ($block_start, $block_latest) = @_;

    my ($epoc0, $time0, $_dur0, $dur0) = split " ", $block_start;
    my ($epoc1, $time1, $_dur1, $dur1) = split " ", $block_latest;

    my $hours_worked = ($epoc1 - $epoc0) / 3600;
    my $h = sprintf "%.2f", $hours_worked;
    my $from = substr($time0, 0, -4);
    my $to = substr($time1, 4, -4);

    my $log_entry = "$month1-$day_of_month1: $from - $to  (hours=$h)\n";
    logg($log_entry);
    return $log_entry;
}


use sigtrap qw/handler signal_exit_handler normal-signals/;
sub signal_exit_handler {
    my $entry = log_work_block $block_start, $block_latest;
    print "\n\n$entry\n Exiting.  See $full_log for log info.\n";
    die;
}


my $old_fh = select(LOG); $| = 1; select($old_fh);  # autoflush
my $intro = "\nStarting timer, @default_time_fields\n\n";
print $intro;
logg($intro);
my $rec = "$t0 $day0-$time0, dayly duration:   0 min.\n";
while ($day0 eq $day1) {
    $block_latest = $rec;
    logg($rec);
    sleep $n_sec;
    my $t1 = time;
    ($day1, $month1, $day_of_month1, $time1, $year1) = split " ", localtime($t1);

    my $d = sprintf "%3d", ($t1 - $start)/60.0;    # convert to minutes
    my $break_duration = ($t1 - $t0 - $n_sec - $truncate);
    $break_duration = 0   if $break_duration <= 0;

    $rec = "$t1 $day0-$time1, dayly duration: $d min.\n";
    if ($break_duration || $day0 ne $day1) {
        my $entry = log_work_block $block_start, $block_latest;
        $block_start = $rec;
        $block_latest = $rec;
        # $start = $t1;
    }
    $t0 = $t1;
}
