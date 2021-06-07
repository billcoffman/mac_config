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
        print "$status $file\n";
    }
}
defined(-M $_) || print "\"$_\" can't find age\n"   for @untracked;
@untracked = sort {-M $a <=> -M $b} @untracked;

my @ignored = (qr{^\.\./ecd/tests/regression/test\d+.json\.\w+$},
               qr(^\.\./ecd/ecd_\w+.log.index\d+\.\d{10}$),
               qr(^\.\./ecd/p[ly]sdr_results_\w+\.log\.\d{10}$),
               qr(^.*\.log$),
              );
my $ignore = join "|", @ignored;
my $regexp = qr{$ignore};
my @filtered_untracked = grep {!/$regexp/} @untracked;
my $untracked_files = grep {!-d $_} @untracked;
my $untracked_dirs = grep {-d $_} @untracked;

my @e=qw/ac add am anomaly_logrotate beanstalkd c celerybeat celeryd c-icap cls
conf cpp crontab-api-madmin crontab-api-root crt cs css csv d dat db def default
discovery discovery_sftp_service dll doc docx dsl dslr dtd elasticsearch eot exe
exp g gif gitignore graphml gz h htm html init inl jar java jmx jpg js json jzb
key list lst Makefile manifest master_workflow md mod2 mongoReplKey monitrc msi
p12 pdb pdf pem php pl pm png policy_evaluator pptx properties py pylintrc R rc
rdf rds README realtime_workflow resources rtf schema scss sh sln sql stats suo
svg template tsv ttf txt TXT Vagrantfile vcb vcproj wixobj wixpdb wixproj woff
wsdl wxs xlsx xml xpi xul yaml yml zip/;
my %extensions_to_keep = map {$_ => 1} @e;
sub keep {
    my $ext = shift;
    return 1 if -d $ext;
    $ext =~ s|.*/||;
    $ext =~ s|.*\.|.|;
    return undef if $ext !~ m/^\.(.*)/;
    return $extensions_to_keep{$1};
}

sub trim_if_defined {
    my ($array_ref, $max_len) = @_;
    return if !defined $max_len || $max_len >= @$array_ref;
    @$array_ref = @$array_ref[0..$max_len-1];
}

@filtered_untracked = grep {keep($_)} @filtered_untracked;
@filtered_untracked = grep {$Age >= -M $_} @filtered_untracked   if defined $Age;
trim_if_defined(\@filtered_untracked, $Files_and_dirs);
@filtered_untracked = @untracked   if $Unfiltered;
my (@dirs, @files);
for my $f (@filtered_untracked) {
    if ( -d $f ) {
        push @dirs, "$f/";
    } else {
        push @files, $f;
    }
}
trim_if_defined(\@files, $Files);
trim_if_defined(\@dirs, $Dirs);
sub age {
    my $f = shift;
    my $days = -M $f;
    my $d = int $days;
    my $hrs = 24*($days - $d);
    my $h = int $hrs;
    my $min = 60*($hrs - $h);
    my $m = int $min;
    my $day_str = $d ? sprintf "%dd", $d : "";
    return sprintf "%s %02d:%02d", $day_str, $h, $m;
}
print "\n______Age    Top files of $untracked_files untracked files:\n" if @files;
print map {sprintf("%9s    %s\n", age($_), $_)} @files;
print "\n______Age    Top Directories of $untracked_dirs untracked dirs:\n" if @dirs;
print map {sprintf("%9s    %s\n", age($_), $_)} @dirs;

__END__
print "

Not yet implemenated ... feel free!

Here's the specs:
 * show branch
 * show any modifed files under git
 * show any added files
 * Show the five most recently modifed, not under git
 * Filter out certain files?
   - This should be git-ignore.
   - Well, perl regexps are so much easier.
   - Maybe add message here reminding about .gitignore
   - Filter out regression test results, logs, pyc files

 "
