#include <stdio.h>
#include <libintl.h>

/* Because we know that this is most probably installed.  */
#define PACKAGE "gettext-tools"

/* Common gettext shortcut.  */
#define _(s) dcgettext(PACKAGE, s, LC_MESSAGES)

int
main(int argc, char *argv[])
{
        setlocale(LC_ALL, "");
        /* bindtextdomain(PACKAGE, path_to_locale_dir) */
        bindtextdomain("gettext-tools", "/opt/local/share/locale");
        textdomain(PACKAGE);

        printf(_("Try '%s --help' for more information.\n"), argv[0]);
}
