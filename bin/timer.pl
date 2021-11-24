#!/usr/bin/env perl
use strict;
use warnings;

my $start = time;
my ($day0, $month, $day_of_month, $time, $year) = split " ", localtime();
my $day1 = $day0;         # Check for day changes with this.
my $full_log = "debug-hours.log";
my $hours_log = "my-hours.log";

my $n_sec = 60;            # Granularity of checks.
my $enough_seconds = 120;  # Slept enough to consider it sleeping.
my $truncate = 5.0;        # Last seconds assumed inactive before sleep.
my $slept = undef;         # Bool - did we sleep?
my @record = ();
my @week = ();
my $t0 = $start;

my $Min_records = 1 + int(1e6 - int(1e6 - $enough_seconds/$n_sec));


sub log_work_block {
    my @recs = @_;

    my $login = $recs[0];
    if (@recs < $Min_records) {
        print "Not enough time to compute.\n";
        return;
    }
    my $last_awake = $recs[-$Min_records];
    my ($epoc0, $time0, $_dur0, $dur0) = split " ", $login;
    my ($epoc1, $time1, $_dur1, $dur1) = split " ", $last_awake;

    my $hours_worked = ($epoc1 - $epoc0) / 3600;
    my $h = sprintf "%.2f", $hours_worked;
    $time0 = substr($time0, 0, -4);
    $time1 = substr($time1, 0, -4);

    my $log_entry = "$month-$day_of_month: $time0 - $time1  (hours=$h)\n";
    print $log_entry;
    open LOG, ">>", $hours_log or die "$! $hours_log";
    print LOG $log_entry;
    close LOG;
    return $log_entry;
}


use sigtrap qw/handler signal_exit_handler normal-signals/;
sub signal_exit_handler {
    my $entry = log_work_block @record;
    print "\n\n$entry\n Exiting.  See $hours_log and $full_log for log info.\n";
    die;
}


open DBG, ">>", "$full_log" or die "$! $full_log";
my $old_fh = select(DBG); $| = 1; select($old_fh);  # autoflush
my $intro = "\nStarting timer, " . localtime() . "\n\n";
print $intro;
print DBG $intro;
my $rec = "$t0 $time,  duration: 0.00 min.\n";
while (1) {
    push @record, $rec;
    print DBG $rec;
    sleep $n_sec;
    ($day1, $month, $day_of_month, $time, $year) = split " ", localtime();
    my $t1 = time;
    my $d = sprintf "%.2f", ($t1 - $start)/60.0;      # convert to minutes
    $slept = (($t1 - $t0 - $n_sec) >= $truncate);     # minimum time to count as sleep

    my $enough_records = (@record > $Min_records);    # bool
    my $slept_enough = ($slept && $enough_records);   # bool
    $rec = "$t1 $time,  duration: $d min.\n";
    if ($slept || $day0 ne $day1) {
        # if ($slept_enough || $day0 ne $day1);
        # print "I WAS SLEEPING!!!\n"  if $slept;
        # print "I SLEPT ENOuGH!!!\n"  if $slept_enough;
        if ($slept_enough) {
            my $entry = log_work_block @record;
            print DBG $rec;
            print DBG $entry;
            @record = ();
            $start = $t1;
        }
    }
    $t0 = $t1;
}
