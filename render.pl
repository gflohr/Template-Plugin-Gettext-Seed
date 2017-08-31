#! /usr/bin/env perl

use strict;

use Template;
use Cwd 'abs_path';
use File::Basename qw(dirname);
use File::Spec;

use Locale::Messages;
#Locale::Messages->select_package('gettext_dumb');
Locale::Messages->select_package('gettext_pp');

die "Usage: $0 TEXTDOMAIN LANG\n" if 2 != @ARGV;

my ($textdomain, $lang) = @ARGV;

my $name = getpwuid $<;
$name = 'User' unless defined $name && length $name;

my $data = {
        textdomain => $textdomain,
        username => $name,
        lang => $lang,
};

my $wd = dirname abs_path $0;
# Make sure that ./LocaleData is in include path.
unshift @INC, $wd;
my $template= File::Spec->catfile($wd, 'templates', 'index.html');

# Our filename is absolute.
my $tt = Template->new(ABSOLUTE => 1) or die Template->error;
$tt->process($template, $data) or die $tt->error;
