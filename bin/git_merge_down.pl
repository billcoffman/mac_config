use strict;
use warnings;

sub mysys {
    my $cmd = shift;
    print "$cmd\n";
    system $cmd;
    die "Failed: $@"  if $?
}

my @diffs = `git diff`;
die "git checkin or stash changes first.  git diff: ".@diffs." lines\n" if @diffs;

my $i = 0;
my @g = map{sprintf" %3d\t%s", ++$i, $_}`git branch`;
print @g;
print"   ?\t  ";
chomp ( my $n=readline(STDIN) );
my ($new_branch) = map { (m/ $n\t\s*(.*)/) ? $1 : () } @g;

my $orig_branch = curr_branch();
git_pull($orig_branch);
git_checkout($new_branch);
git_pull($new_branch);
git_checkout($orig_branch);
mysys("git merge \"$new_branch\"");

sub curr_branch {
    chomp ( my $br = `git rev-parse --abbrev-ref HEAD` );
    die "cannot determine git branch" if $? or !$br;
    return $br;
}

sub git_checkout {
    my $br = shift;
    mysys("git checkout \"$br\"");
}

sub git_pull {
    my $current_branch = shift;
    mysys("git pull origin \"$current_branch\"");
}


