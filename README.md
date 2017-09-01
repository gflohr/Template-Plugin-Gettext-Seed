# Template-Plugin-Gettext-Seed

This is a seed project for [https://github.com/Template-Plugin-Gettext](https://github.com/Template-Plugin-Gettext).  It includes all the boilerplate stuff you need for localizing a project using Template-Plugin-Gettext and additional source code in Perl and C (just as an example).

## Getting Started

First, clone the repository to a location of your choice.  If you want to
use Git as your version control system, simply remove the remote:

```
$ cd Template-Plugin-Gettext-Seed
$ git remote rm origin
```

Otherwise delete the git directory:

```
$ cd Template-Plugin-Gettext-Seed
$ rm -rf .git
```

For all following commands, it is assumed that your current working
directory is the top-level directory.

### Prerequisites

Apart from Perl, the Template Toolkit and Template-Plugin-Gettext, you also
need GNU make and the tools for GNU Gettext.  Both are definitely available
as pre-built packages for your operating system.

You also need a recent version of `libintl-perl`, at least version 
1.28.  If your vendor doesn't have a sufficiently recent version, 
install it from the sources with the command `sudo cpan install 
Locale::TextDomain`.

### Prepare PO Directory

Rename the file `po/PACKAGE.sample`.

```
$ cd po
$ mv PACKAGE.sample PACKAGE
$ cd ..
```

Now open `PACKAGE` with a text editor of your choice and edit it to
your needs.

### Testing

The seed project has an example template and example translations for
Bulgarian, German, French, and Italian.  Make sure that the locale
definitions for at least one of these languages is installed on your
system.  You can usually check that with the command `locale -a`.

Now compile and install the translations:

```
$ cd po
$ make all
$ cd ..
```

The make target "all" will run all the necessary steps with just one command.  Now try to render the template:

```
$ perl render.pl TEXTDOMAIN fr
<!DOCTYPE html>
<html>
  <head>
    <title>Example pour Template-Plugin-Gettext</title> 
  </head>
  <body>
    <h1>Bonjour, guido !</h1>
    <p>
      Le « locale » actuellement utilisé pour la domaine « com.mydomain.www » et langue « fr » est « fr_FR.utf-8 ».
    </p>
  </body>
</html>
```

Replace `TEXTDOMAIN` above with the textdomain that you have
configured in `po/PACKAGE` and `fr` with a language abbreviation
that is supported by your system.  The script `render.pl` will
render the template file `templates/index.html` using the language
that you have specified on the command-line.

If you don't see output in the selected language, but in English,
inspect the last paragraph.  It should read something like

```
<p>
The current locale for textdomain 'com.mydomain.www' and language 'en' is 'en_US.utf-8'!
</p>
```

Instead of `en_US.utf-8` you may see another locale identifier.
It means that switching to a French locale has failed.  You can
try "de", "it", or "bg" for other languages.  If that alsl fails,
open the Perl script `render.pl` and edit this it:

```
use Locale::Messages;
Locale::Messages->select_package('gettext_pp');
```

Replace `gettext_pp` with `gettext_dumb`.  If that still fails,
please file a bug report.

## Translation Workflow

The translation workflow is less complicated than it looks at
first glance.

### Adding And Removing Templates

Whenever you add or remove a template, you have to edit the file
po/POTFILES accordingly.  If you prefer to generate the file, go
ahead but try to make sure that it doesn't contain backups, test
files or other garbage.

### Changing Templates

After templates have been changed, you have to update the master
catalog and merge the new strings into the existing translations.

```
$ cd po
$ make pot
... output omitted ...
$ make update-po
... output omitted ...
$ cd ..
```

The step `make pot` will recreate the file `po/TEXTDOMAIN.pot`,
the step `make update-po` will merge the new set of translatable
strings into all existing translations.

In fact, `make update-po` will call `make pot` automatically, when
needed.

You should now hand out the translation files (the `.po` files) to
your translators.  They hopefully know what to do with them.

If you are using version control, you should commit all `.pot`
files.

### Installating Translations

When you receive translated `.po` files, copy them into the `po`
subdirectory and commit them if you are using version control. 
Next compile and install them:

```
$ cd po
$ make update-mo
... output omitted ...
$ make install
... output omitted ...
$ cd ..
```

The `.po` files get compiled into `.gmo` files with 
`make update-mo`.  This step may fail if the `.po` files are 
syntactically incorrect.  In this case you have to fix the errors
before you can proceed.

`make install` copies the the `.gmo` files as `.mo` files into the 
top-level directory `LocaleData`, where libintl-perl expects them.
You should commit the installed `.mo` files in `LocaleData` under
version control but ignore the generated `.gmo` files in the
`po` directory.  If you are unsing Git, you can simple copy the
top-level `.gitignore` and `po/.gitignore` into your project.

### Adding A New Language

Let's assume that we want to add a Spanish translation.  You first
have to edit `po/PACKAGE` and add `es` to the list of languages in
the variable `LINGUA`.

Now create a stub translation file `po/es.po`.  This is easiest done
with the program `msginit`:

```
$ cd po
$ msginit --input=TEXTDOMAIN.pot --locale=es
$ make update-po
```

As always, replace `TEXTDOMAIN` with the text domain configured in
`PACKAGE`.

The command `msginit` creates the file `es.po` and with some
boilerplate.  With `make update-po` you copy all translatable
strings from `TEXTDOMAIN.pot` into the `.po` file.

Don't forget to put the Spanish `po/es.po` file under version
control.  After it has been translated, compile and install it
as described in the previous section.

## Translation Workflow For the Lazy

The only thing that you have to remember is to always keep the
list of input files `po/POTFILES` up-to-date.  Then, whenever
you feel that something about the translations have to be done:

```
$ cd po
$ make all
$ cd ..
```

That may do things that are not necessary but it will never break
anything.

## Adding Perl Files

It will often happen that your template toolkit project also contains
localized Perl files.  This seed project is already prepared for 
that.  Take a look into `po/POTFILES`.  The last line should read
`./plfiles.pot`.

The file `po/plfiles.pot` contains the PO entries for all Perl source
files (more precisely those listed in `po/PLFILES`).  The Makefile
takes extract the strings from the Perl files with GNU `xgettext`
and writes them into `po/plfiles.pot`.  This file is then used
as an input source file for `xgettext-tt2` from
[Template-Plugin-Gettext](https://github.com/gflohr/Template-Plugin-Gettext).
This works because `xgettext-tt2` just like GNU `xgettext` also 
support input files in `.po` format.

If there are no Perl files in your project, just delete the 
line with `./plfiles.pot` in `po/POTFILES`.

