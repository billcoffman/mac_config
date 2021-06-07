
use strict;
use warnings;

my %status_order = (
    DEAD => 1,
    DEPR => 2,
    UNK  => 3,
    ''   => 4,
    REVW => 5,
    LIVE => 6 );
sub compare_status {
    my $status_a = $a->[1];
    my $status_b = $b->[1];

    $status_a = '' if !defined $status_a;
    $status_b = '' if !defined $status_b;

    my $order_a = $status_order{$status_a};
    warn "no order defind for status \"$status_a\"\n" if !defined $order_a;
    my $order_b = $status_order{$status_b};
    warn "no order defind for status \"$status_b\"\n" if !defined $order_b;
    return $order_a <=> $order_b;
}

open my $fh, "../../branch_info";
chomp(my @branch_info = <$fh>);
my %documented;
for my $line (@branch_info) {
    my ($branch, $status, $description) = split "\t", $line;
    $documented{$branch} = [$status, $description];
}

my $i = 0;
my @git_branches = `git branch`;
my (@g, @out_data);
for (@git_branches) {
    my ($status, $description, $br, $indent) = ('', '', '', '');
    /(.*?)(\w.*)/ && (($indent, $br) = ($1, $2));
    if ($br && $documented{$br}) {
        ($status, $description) = @{$documented{$br}};
    }
    push @out_data, [$indent, $status, $br, $description];
    my $out_line = sprintf" %3d\t%2s %4s  %-25s\t %s\n", ++$i,
            $indent, $status, $br, $description;
    push @g, sprintf" %3d\t%s", $i, $_;
    print $out_line;
}
@out_data = sort {$a->[0] cmp $b->[0]
        or compare_status()
        or $a->[2] cmp $b->[2]} @out_data;
#print map {sprintf "%2s %4s %-25s\t %s\n", @$_ } @out_data;
#print "\n";
print"   ?\t  ";
my $n = readline(STDIN);
chomp($n);
system map {(m/ $n\t\s*(.*)/) ?"git checkout \"$1\"" : () } @g
