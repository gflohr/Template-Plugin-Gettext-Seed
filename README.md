# Template-Plugin-Gettext-Seed

This is a seed project for [https://github.com/Template-Plugin-Gettext](https://github.com/Template-Plugin-Gettext).  It includes all the boilerplate stuff you need for localizing a project using Template-Plugin-Gettext and additional source code in Perl and C (just as an example).

## Usage

First, clone the repository to a location of your choice.  If you want to
use Git as your version control system, simply remove the remote:

```
cd Template-Plugin-Gettext-Seed
git remote rm origin
```

Otherwise delete the git directory:

```
cd Template-Plugin-Gettext-Seed
rm -rf .git
```

### Prerequisites

Apart from Perl, the Template Toolkit and Template-Plugin-Gettext, you also
need GNU make and the tools for GNU Gettext.  Both are definitely available
as pre-built packages for your operating system.

### Prepare PO Directory

Rename the file `po/PACKAGE.sample`.

```
cd po
mv PACKAGE.sample PACKAGE
```

Now open `PACKAGE` with a text editor of your choice and edit it to
your needs.

### Create Master Catalog

First you have to create the master catalog for your project.  This is
usually the file `po/TEXTDOMAIN.pot` where `TEXTDOMAIN` is the text domain
that you have configured in `po/PACKAGE`.  Create it like this:

```
cd po
make pot
```

