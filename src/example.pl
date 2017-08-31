use strict;

use Locale::TextDomain qw(whatever);
use Locale::Messages qw(:locale_h :libintl_h);
use POSIX qw(setlocale);

# Set the locale from the environment.  Locale::TextDomain sets the default
# domain for us.

setlocale Locale::Messages::LC_ALL(), '';

my $num = 1 + time % 5;
print(__nx("One world!\n", "{num} worlds!\n", $num, num => $num));
