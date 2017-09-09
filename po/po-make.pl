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
use File::Path qw(make_path);
use File::Copy qw(copy);

sub read_package();
sub usage(;$);
sub command(@);
sub fatal($);
sub failure();
sub safe_rename($$);

my %actions = (
  pot => \&make_pot,
  config => \&make_config,
  'update-po' => \&make_update_po,
  'update-mo' => \&make_update_mo,
  install => \&make_install,
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
$package{XGETTEXT} = 'xgettext' if !defined $package{XGETTEXT};
$package{CATOBJEXT} = '.po' if !defined $package{CATOBJEXT};

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

sub make_pot {
    require Locale::TextDomain;

    my ($pox, $pot) = ('plfiles.pox', 'plfiles.pot');
    my @options = split / /, Locale::TextDomain->options;
    my @cmd = ($package{XGETTEXT},
               "--output=$pox", "--from-code=utf-8",
               "--add-comments=TRANSLATORS:", "--files-from=PLFILES",
               "--copyright-holder='$package{COPYRIGHT_HOLDER}'", "--force-po",
               "--msgid-bugs-address='$package{MSGID_BUGS_ADDRESS}'",
               @options);
    failure if 0 != command @cmd;

    print "# rm -f $pot\n";
    unlink $pot;

    print "# mv $pox $pot\n";
    safe_rename $pox, $pot;

    ($pox, $pot) = ("$package{TEXTDOMAIN}.pox", "$package{TEXTDOMAIN}.pot");
    @cmd = ($package{XGETTEXT_TT2},
               "--output=$pox", "--from-code=utf-8",
               "--add-comments=TRANSLATORS:", "--files-from=POTFILES",
               "--copyright-holder='$package{COPYRIGHT_HOLDER}'", "--force-po",
               "--msgid-bugs-address='$package{MSGID_BUGS_ADDRESS}'");
    failure if 0 != command @cmd;

    print "# rm -f $pot\n";
    unlink $pot;

    print "# mv $pox $pot\n";
    safe_rename $pox, $pot;

    return 1;
}

sub make_update_po {
    my @linguas = split /[ \t]+/, $package{LINGUAS};

    foreach my $lang (@linguas) {
        print "$lang:\n";
        
        print "# mv $lang.po $lang.old.po\n";
        safe_rename "$lang.po", "$lang.old.po";

        my @cmd = ($package{MSGMERGE}, "$lang.old.po", 
                   "$package{TEXTDOMAIN}.pot", '-o', "$lang.po");
        if (0 == command @cmd) {
            print "# rm -f $lang.old.po\n";
        } else {
            warn "$package{MSGMERGE} for $lang failed.\n";
            print "# mv $lang.old.po $lang.po\n";
            safe_rename "$lang.old.po", "$lang.po";
        }
    }

    return 1;
}

sub make_update_mo {
    my @linguas = split /[ \t]+/, $package{LINGUAS};

    foreach my $lang (@linguas) {
        my @cmd = ($package{MSGFMT}, "--check", 
                   "--statistics", "--verbose",
                   '-o', "$lang.gmo", "$lang.po");
        failure if 0 != command @cmd;
    }

    return 1;
}

sub make_install {
    my @linguas = split /[ \t]+/, $package{LINGUAS};

    my $targetdir = File::Spec->catfile('..', 'LocaleData');
    foreach my $lang (@linguas) {
        my $destdir = File::Spec->catfile($targetdir, $lang, 'LC_MESSAGES');
        print "# mkdir -p $destdir\n";
        make_path $destdir if !-e $destdir;
        my $dest = File::Spec->catfile($destdir, "$package{TEXTDOMAIN}.mo");
        print "# cp $lang.gmo $dest\n";
        copy "$lang.gmo", $dest or fatal $!;
    }

    return 1;
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

sub command(@) {
    my (@args) = @_;

    my @pretty;
    foreach my $arg (@args) {
        my $pretty = $arg;
        $pretty =~ s{(["\\])}{\\$1}g;
        $pretty = qq{"$pretty"} if $pretty =~ /[ \t]/;
        push @pretty, $pretty;
    }

    my $pretty = join ' ', @pretty;
    print "# $pretty\n";

    system @args;
}

sub fatal($) {
    my ($msg) = @_;
    
    chomp $msg;

    die "$0: *** $msg.  Stop!\n";
}

sub failure() {
    if ($? == -1) {
        fatal "failed to execute: $!";
    } elsif ($? & 127) {
        fatal sprintf "child died with signal %d, %s coredump\n",
                                ($? & 127),  ($? & 128) ? 'with' : 'without';
    }

    my $error = $? >> 8;
    fatal "Error $error";
}

sub safe_rename($$) {
    my ($from, $to) = @_;

    return 1 if rename $from, $to;

    fatal "mv: rename '$from' to '$to': $!";
}

