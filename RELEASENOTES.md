## 0.19.0

* inheritmarks added, so that an extension can turn off parts of another extension


### 0.18.8

* use `LC_ALL=C` for sorting, fix some bugs

### 0.18.7

* remove some old text from README

### 0.18.6

* simplify README

### 0.18.5

* use -RLa for homebrew

### 0.18.4

* remove file from git

### 0.18.3

* simplify README

### 0.18.2

* rename definition to buildinfo, fix extension searchpath

### 0.18.1

* improve buildinfo a bit more

## 0.18.0

* add buildinfo command (incomplete)


### 0.17.7

* use -C option of mulle-env to pass commandline

### 0.17.6

* fix useless quoting for mulle-env

### 0.17.5

* add definition command

### 0.17.4

* fix dependencies

### 0.17.3

* fix package dependencies more

### 0.17.2

* fix homebrew install ruby script

### 0.17.1

* fix lost commands

## 0.17.0

* fixed reinit to work with older projects
* clean dependency now does what I expect it to do
* now most commands can be run without entering a subshell
* a problem with the order of template files writes has been corrected


### 0.16.3

* improved cleaning, improved reinit

### 0.16.2

* fix installer-all

### 0.16.1

* rename install to installer, because of name conflict

## 0.16.0

* subproject support added. Fix various extension problems


### 0.15.17

* and even nicers

### 0.15.16

* fix

### 0.15.15

* improve install-all

### 0.15.14

* add install-all, rename install.sh to install
* add install-all, rename install.sh to install

### 0.15.13

* add install-all, rename install.sh to install

### 0.15.12

* started work on dependency definition subcommand

### 0.15.11

* even more dox improvements

### 0.15.10

* improve README.md

### 0.15.9

* fix upgrade and reinit

### 0.15.8

* improve extension handling again, use new mulle-craft

### 0.15.7

* use : as separator for environment variables, extra extensions can be inherited from all

### 0.15.6

* support `DIALECT_EXTENSION`

### 0.15.5

* fix cmake

### 0.15.4

* move extension out of project, meta extensions now only inherit
* move extension out of project, meta extensions now only inherit

### 0.15.2

* add support for include for library

### 0.15.1

* fix CMakeLists.txt

## 0.15.0

* use only singular directory names
* mulle-sde craft can now be called from outside of the subshell


### 0.14.3

* Various small improvements

### 0.14.2

* make upgrade a bit more foolproof

### 0.14.1

* improved usage texts, support clobber and all extension folders

## 0.14.0

* simplify ignore by just looking into src and tests (and .mulle-sourcetree/etc)
* extension add should work now well
* dial back to `MULLE_VIRTUAL_ROOT` for a choice of commands
* simplify upgrade
* reinit is now a proper command


### 0.13.1

* bug fixes, save extensions with quotes and use --aux for init environment

## 0.13.0

* use / as vendor extension separator instead of :
* added bash completion
* adapt to changes in inferior tools


### 0.12.5

* uniform help, remove obsolete cmake-include

### 0.12.4

* fix -D environment variables not showing up in templates

### 0.12.2

* Various small improvements

### 0.12.1

* Various small improvements


## 0.12.0

* Greatly improved extension handling


### 0.11.1

* Various small improvements

## 0.10.0

* lots of work and refinement on extensions


## 0.9.0

* redo extension lookup so its more amenable to development
* improve and simplify documentation
* move c and cmake extensions into their own projects


## 0.8.0

* use a gitignore like scheme to classify files and directories


### 0.7.4

* allow extensions to suppress functionality of inherited extensions with marks

### 0.7.2

* redid the extensions, so it is now much easier to create one

## 0.7.0

* rewrite monitor to be more functional even if cmake is not used
* improve README.md somewhat


### 0.6.1

* general progress on all fronts

## 0.6.0

* working as intended with c and cmake extensions


## 0.5.0

* use .mulle-sde subdirectory for configuration


## 0.4.0

* use -- to separate options from mulle-bootstrap flags


### 0.3.1

* Various small improvements

## 0.3.0

* add -c option
* MULLE_BOOTSTRAP_VIRTUAL_ENVIRONMENT is now MULLE_SDE_VIRTUAL_ENVIRONMENT
* search for .mulle-sde-environment.sh to determine root of virtual environment
* source .environment.sh if present
* fix mulle-bootstrap running if there is not .bootstrap or .bootstrap.local folder


### 0.1.1

* Various small improvements

## 0.1.0

* Various small improvements


### 0.0.3

* Various small improvements

### 0.0.2

* various improvements and bugfixes
