#! /usr/bin/env perl

# Copyright (c) 2017 Guido Flohr, <guido.flohr@cantanea.com>,
# http://www.guido-flohr.net/

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use strict;

use File::Basename qw(dirname);
use File::Spec;

sub read_package();
sub usage(;$);

my %actions = (
  pot => \&make_pot,
  config => \&make_config,
);

my $action = $ARGV[0];

if (@ARGV != 1) {
    usage "too many arguments!"
} elsif (!$actions{$action}) {
    usage "unrecognized action '$action'";
}

my %package = read_package;
$package{PERL} = 'perl' if !defined $package{PERL};
$package{MSGMERGE} = 'msgmerge' if !defined $package{MSGMERGE};
$package{MSGFMT} = 'msgfmt' if !defined $package{MSGFMT};
$package{XGETTEXT_TT2} = 'xgettext-tt2' if !defined $package{XGETTEXT_TT2};
$package{XGETTEXT} = 'xgettext-tt2' if !defined $package{XGETTEXT};
$package{CATOBJEXT} = 'xgettext-tt2' if !defined $package{CATOBJEXT};

$actions{$action}->();

sub read_package() {
   my $base_dir = dirname $0;
   my $package_file = File::Spec->catfile($base_dir, 'PACKAGE');

   open my $fh, '<', $package_file
       or die "Cannot open '$package_file' for reading: $!\n";

   my %variables;
   my $lineno = 0;

   my $this_line = '';
   while (my $line = <$fh>) {
       ++$lineno;
       if ($line =~ s/\\\n//) {
           $this_line .= $line;
           continue;
       } else {
           $this_line = '';
       }

       # Unescape like make does.
       sub unescape {
           my ($capture) = @_;
           my $first = substr $capture, 0, 1, '';
           return '#' eq $first ? '' : $capture;
       }
       $line =~ s/(\\.|#.*)/unescape $1/ge;
       chomp $line;

       $line =~ s/^[ \012-\015]+//;
       $line =~ s/[ \012-\015]+$//;
       next if !length $line;

       if ($line !~ /^([_a-zA-Z][_a-zA-Z0-9]*)[ \012-\015]*=[ \012-\015]*(.*)/) {
           die "$0: $package_file:$lineno: syntax error!\n";
       }

       $variables{$1} = $2;
   }

   return %variables;
}

sub usage(;$) {
    my ($msg) = @_;

    my $text = '';
    if (defined $msg && length $msg) {
        chomp $msg;
        $text = "$0: $msg\n";
    }

    $text .= <<EOF;
Usage: $0 ACTION

Available actions:
  pot                       - remake master catalog
  update-po                 - merge po files
  update-mo                 - regenerate mo files
  install                   - install mo files
  all                       - all of the above
  config                    - show configuration
EOF

    if (defined $msg && length $msg) {
        die $text;
    }

    print $text;
    exit 0;
}

sub make_config {
    print <<EOF;
Configuration variables:

EOF

    foreach my $var (sort keys %package) {
        print "    $var = $package{$var}\n";
    }

    print <<EOF;

You can override all of the following configuration variables in the file
'PACKAGE' in the current directory.
EOF
}
