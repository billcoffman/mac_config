#!/usr/bin/env perl
use strict;
use warnings;

my $start = time;
my ($day0, $month, $day_of_month, $time, $year) = split " ", localtime();
my $day1 = $day0;         # Check for day changes with this.
my $full_log = "minutes.log";
my $hours_log = "my-hours.log";

my $n_sec = 60;            # Granularity of checks.
my $enough_seconds = 120;  # Slept enough to consider it sleeping.
my $truncate = 5.0;        # Last seconds assumed inactive before sleep.
my $slept = undef;         # Bool - did we sleep?
my @record = ();
my @week = ();
my $t0 = $start;

my $Min_records = 1 + int(1e6 - int(1e6 - $enough_seconds/$n_sec));


sub analyze_record {
    my ($prev, $latest) = @_;
    my ($day0, $month0, $day_of_month0, $time_of_day0, $year0) = split " ", localtime($prev);
    my ($day1, $month1, $day_of_month1, $time_of_day1, $year1) = split " ", localtime($latest);

    my $on_break = (($latest - $prev - $n_sec) >= $truncate);
    return $on_break;
}


sub analyze_block {
    my @recs = @_;
    my $epoc0 = $recs[0];
    if (@recs < $Min_records) {
        return;
    }
    my $epoc1 = $recs[-$Min_records];
    return   if $epoc0 >= $epoc1;
    return ($epoc0, $epoc1);
}


sub summarize_block {
    my ($last_finish, $last_date, $total, @block) = @_;
    my ($start, $finish) = analyze_block(@block);
    return   unless $start;

    my $hours_worked = ($finish - $start) / 3600;
    my $last_break = $last_finish ? ($start - $last_finish) / 60 : undef;
    my $h = sprintf "%.2f", $hours_worked;
    my $b = $last_break ? sprintf ", break %.0f min", (0.5+$last_break) : "";
    my ($day0, $month0, $day_of_month0, $time_of_day0, $year0) = split " ", localtime($start);
    my ($day1, $month1, $day_of_month1, $time_of_day1, $year1) = split " ", localtime($finish);

    my $date0 = "$month0-$day_of_month0";
    my $date1 = "$month1-$day_of_month1";
    my $t0 = "$time_of_day0";
    my $t1 = "$time_of_day1";
    if ($last_date ne $date1) {
        print "\n";
        $total = 0;
        $b = "";
    }
    $total += $hours_worked;
    my $tot = sprintf ", tot %.2f", $total;

    # print "$start $finish ";
    my $log_entry = "$date0: $t0 - $t1  (hours=$h$b$tot)\n";
    return ($total, $log_entry);
}


sub read_full_log {
    my $prev;
    my @block = ();
    open my $fh, $full_log or die "$! $full_log";
    my $last_finish = undef;
    my $last_date = "";
    my $total = 0;
    my $log_entry = "";
    while (<$fh>) {
        next unless m/(^\d+) \S+,/;
        my $cur = $1;
        my $break = undef;
        if (defined($prev)) {
            $break = analyze_record($prev, $cur);
        }
        if ($break) {
            my ($start, $finish) = analyze_block(@block);
            if ($start) {
                @block = ();
                my $hours_worked = ($finish - $start) / 3600;
                my $last_break = $last_finish ? ($start - $last_finish) / 60 : undef;
                my $h = sprintf "%.2f", $hours_worked;
                my $b = $last_break ? sprintf ", break %.0f min", (0.5+$last_break) : "";
                my ($day0, $month0, $day_of_month0, $time_of_day0, $year0) = split " ", localtime($start);
                my ($day1, $month1, $day_of_month1, $time_of_day1, $year1) = split " ", localtime($finish);

                my $date0 = "$month0-$day_of_month0";
                my $date1 = "$month1-$day_of_month1";
                my $t0 = "$time_of_day0";
                my $t1 = "$time_of_day1";
                if ($last_date ne $date1) {
                    print "\n";
                    $total = 0;
                    $b = "";
                }
                $total += $hours_worked;
                my $tot = sprintf ", tot %.2f", $total;

                # print "$start $finish ";
                $log_entry = "$date0: $t0 - $t1  (hours=$h$b$tot)\n";
                print $log_entry;
                $last_finish = $finish;
                $last_date = $date1;
            }
        }
        push @block, $cur;
        $prev = $cur;
    }
    ($total, $log_entry) = summarize_block($last_finish, $last_date, $total, @block);
    print $log_entry   if $log_entry;
}
read_full_log();


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
exit();


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
