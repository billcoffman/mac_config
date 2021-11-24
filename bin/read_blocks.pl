#!/usr/bin/env perl
use strict;
use warnings;

my $BREAK = shift || 20;

my $start = time;
my ($day0, $month, $day_of_month, $time, $year) = split " ", localtime();
my $day1 = $day0;         # Check for day changes with this.
my $full_log = "minutes.log";
my $hours_log = "my-hours.log";

my $n_sec = 60;            # Granularity of checks.
my $enough_seconds = 120;  # Slept enough to consider it sleeping.
my $truncate = 5.0;        # Last seconds assumed inactive before sleep.
my $contig = $n_sec + $truncate;
my $max_break = $BREAK*60;
my $max_break_total_per_day = 3600;
my $slept = undef;         # Bool - did we sleep?
my @record = ();
my @week = ();
my $t0 = $start;

my $Min_records = 1 + int(1e6 - int(1e6 - $enough_seconds/$n_sec));

my $week_total = 0;
my $break_daily_total_min = 0;
my $last_date_processed = undef;
my $prev_finished = undef;
my ($num_micro_breaks_per_day, $break_total) = (0, 0);


sub display_block {
    my ($start, $finish, $total, $day) = @_;

    my $hours_worked = ($finish - $start) / 3600;
    my $h = sprintf "%.2f", $hours_worked;
    my ($day0, $month0, $day_of_month0, $time_of_day0, $year0) = split " ", localtime($start);
    my ($day1, $month1, $day_of_month1, $time_of_day1, $year1) = split " ", localtime($finish);

    my $date0 = "$month0-$day_of_month0";
    my $date1 = "$month1-$day_of_month1";
    my $t0 = substr($time_of_day0, 0, -3);
    my $t1 = substr($time_of_day1, 0, -3);
    $day = $date1   unless $day;
    if ($day ne $date1) {
        $week_total += $total;
        printf "%.2f %s                              weekly %.3f\n\n",
                $total, $last_date_processed, $week_total;
        $week_total = 0   if $day0 eq 'Mon';
        $total = 0;
        $day = $date1;
    }
    $total += $hours_worked;
    my $tot = sprintf ", tot %.2f", $total;

    if ( $prev_finished ) {
        # Print "break" info.
        my $break = int(($start - $prev_finished)/60);
        $break_daily_total_min += $break;
        printf "brk: %d     (tot %.1f)\n", $break, $break_daily_total_min/60;
    }
    # print "$start $finish ";
    my $log_entry = "$date0: $t0 - $t1  (hours=$h$tot)\n";
    print $log_entry;
    $last_date_processed = $day0;
    $prev_finished = $finish;  # for next context-sensitive call
    return ($total, $day);
}


sub read_full_log {
    my @logs = ();
    open my $fh, $full_log or die "$! $full_log";
    while (<$fh>) {
        next unless m/(^\d+)/;
        push @logs, int($1);
    }
    return @logs;
}


sub blockify {
    my $everything = shift;
    my @blocks = ([]);  # generate a list of blocks
    for my $t (@$everything) {
        my $last = $blocks[-1];  # last block in the list of blocks
        my $gap = @$last ? $t - $last->[-1] - $contig : 0;
        push @blocks, []   if $gap >= $max_break;
        push @{$blocks[-1]}, $t;
        $gap -= 120;  # first two min. of break not counted
        if ( $gap > 0 )  {
            $num_micro_breaks_per_day += 1;
            $break_total += $gap;
        }
    }
    return @blocks;
}


my @everything = read_full_log();
my @blocks = blockify(\@everything);
@blocks = grep {@$_ >= $Min_records} @blocks;
my @work_log = map { [$_->[0], $_->[-$Min_records]] } @blocks;
my ($total, $date) = (0, undef);
for my $entry (@work_log) {
    my ($start, $finish) =  @$entry;
    ($total, $date) = display_block($start, $finish, $total, $date);
}
$week_total += $total;
printf "%.2f %s                              weekly %.3f\n\n",
        $total, $last_date_processed, $week_total;
