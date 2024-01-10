# 💠 Cross-platform IDE for the command-line

... for Android, BSDs, Linux, macOS, SunOS, Windows (MinGW, WSL)

MulleSDE is an IDE and a dependency (package) manager for the commandline.
You could call it a [npm](https://www.npmjs.com/) or a [virtualenv](//pypi.org/project/virtualenv)
for C languages. [De Re mulle-sde](https://www.mulle-kybernetik.com/de-re-mulle-sde/) is a
a short introductory guide, that gives an overview of some of the capabilities.

MulleSDE strives to be self-explanatory through help texts and file comments.
The [mulle-sde WiKi](//github.com/mulle-sde/mulle-sde/wiki) contains more in-depth information,
that doesn't fit into the help texts of the various mulle-sde commands


| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/mulle-sde/mulle-sde.svg?branch=release)  | [RELEASENOTES](RELEASENOTES.md) |

## Documentation


The basic principle in mulle-sde is the Edit-Reflect-Craft cycle

### ERC : Edit - Reflect - Craft

#### Edit

You use the editor of your choice and any GUI or terminal to manage the
project files.

#### Reflect

Changes in the filesystem are picked up by `mulle-sde reflect` and are used
to update build system files and header files.

#### Craft

`mulle-sde` fetches dependencies, builds them and installs them local to your
project. Then it will build your project. A repeated craft, will then
rebuild only your project.

All commands have a `help` subcommand for usage information. Most commands have
subcommands, that also have further help. E.g. `mulle-sde help` and
`mulle-sde dependency help`.

There is also quite a bit of documentation in the [mulle-sde WiKi](//github.com/mulle-sde/mulle-sde/wiki).


# Commands






## Quick Start

In a very basic mulle-sde scenario you have an existing project and
you only want to maintain its dependencies with mulle-sde, the rest is
kept as is:

``` sh
mulle-sde add github:madler/zlib # add one or more dependencies
```

This will create four folders inside your project:

```
.
├── .mulle       # internal mulle-sde maintenance
├── dependency   # the desired output will be found here
├── kitchen      # temporary build folder
└── stash        # downloaded dependencies
```

In `dependency` you will then find the familiar file structure with include and
lib folders, ready for inclusion and linking in your project. You can change
the positions of the three visible folders to any place you like with
environment variables.

If you want to embed the project instead and compile it yourself use:

``` sh
mulle-sde dependency add --embedded github:madler/zlib # add one or more dependencies
```



## mulle-sde add

![](dox/mulle-sde-add.svg)

You can create a templated source file for installed languages with
the `add` command. These files can be optionally pre-loaded with
personalized copyright statements and so forth.

``` sh
mulle-sde add src/Foo.m
```

This command will automatically run `reflect`.

The `add` command can be run outside of an existing mulle-sde environment.


## mulle-sde craft

![](dox/mulle-sde-craft.svg)

Builds your project including all dependencies.


``` sh
mulle-sde  craft
```

## mulle-sde dependency

![](dox/mulle-sde-dependency.svg)

*Dependencies* are typically GitHub projects, that provide a library (like zlib)
or headers only. These will be downloaded, unpacked and built into `dependency`
with the next build:

``` sh
mulle-sde dependency add https://github.com/madler/zlib/archive/v1.2.11.tar.gz
```

You can also embed dependencies in your project, if you want to build them within your project.
*Dependencies* can have nested *dependencies*. mulle-sde will resolve them all
and build them in the appropriate order.

This the most powerful aspect of mulle-sde. See the
[mulle-sde Wiki](https://github.com/mulle-sde/mulle-sde/wiki) for more
information about dependencies.


## mulle-sde environment

![](dox/mulle-sde-environment.svg)

*Environment* variables are the setting mechanism of **mulle-sde**. They are
handled by [mulle-env](/mulle-sde/mulle-env). These settings can vary,
depending on operating system, host or user.

You can add or remove environment variables with *environment*.

``` sh
mulle-sde environment list
```

``` sh
mulle-sde environment set FOO "my foo value"
```

## mulle-sde extension

![](dox/mulle-sde-extension.svg)

*Extensions* add support for build systems, language runtimes and other tools
like editors and IDEs to mulle-sde. *Extensions* are used during *init* to
setup a project, but can also be added at a later date.

*mulle-sde* knows about five different extension types

| Extensiontype  | Description
|----------------|-------------------------------------
|buildtool       | Support for build environment and tools like **cmake** .
|extra           | Support for extra features like **git**.
|meta            | A wrapper for extensions (usually buildtool+runtime+extra).
|oneshot         | A special kind of extra extension, that can be installed multiple |times but is not upgradable. Used primarily for source files.
|runtime         | Support for language/runtime combinations like C or Objective-C.

Extensions are installable plugins. The package [mulle-sde-developer](//github.com/mulle-sde/mulle-sde-developer)
provides the basic set of extension. Use *list* to see the *extensions* installed on your system:

``` sh
mulle-sde extension list
```

Use *usage* to see special notes for a certain *extension*:


``` sh
mulle-sde extension usage mulle-sde/extension
```

*upgrade* is the mechanism to install newer or different versions of your
choice of *extensions*:

``` sh
mulle-sde extension upgrade
```

See the [mulle-sde Wiki](https://github.com/mulle-sde/mulle-sde/wiki) for more
information about adding and writing extensions.


## mulle-sde init

Creates a mulle-sde project.

As the various tools that comprise mulle-sde are configured with
environment variables, `mulle-sde init` will create  a virtual environment
using [mulle-env](//github.com/mulle-sde/mulle-env), so that various projects
can coexist on a filesystem with minimized interference.

This is an example, that creates a cmake project for C (this is the default):

``` sh
mulle-sde init -d hello -m mulle-sde/c-developer executable
```

You can now enter the environment sub-shell with:

``` sh
mulle-sde hello
```

or just `cd` to your project:

``` sh
$ cd hello
```

> Note: You can run mulle-sde commands inside the subshell or outside of it.
> It's a matter of taste. Initially running commands in the subshell maybe
> easier to get acquainted with the local environment and its restrictions.


Maybe have a look at the project configuration:

``` sh
mulle-sde list
```

Build it:

``` sh
mulle-sde craft
```

Run it:

``` sh
$ ./kitchen/Debug/hello
```

Update your source or project files manually. Then let mulle-sde reflect your
changes back into the Makefiles and into header files and build again:

``` sh
mulle-sde reflect
mulle-sde craft

```

Or add a template generated source file with reflection for free:

``` sh
mulle-sde add src/foo.c
```

Leave the environment:

``` sh
$ exit
```

> #### Tip:
>
> Use an alias like `alias sde=mulle-sde` to avoid typing the `mulle-` prefix
> every time.


## mulle-sde library

![](dox/mulle-sde-library.svg)

Libraries are operating system provided libraries (like `libm.a`) that you
don't build yourself.

``` sh
mulle-sde library add m
```

You can exclude libraries on a per-platform level (as you can dependencies)

``` sh
mulle-sde  library mark m no-platform-windows
```

See the [mulle-sde Wiki](https://github.com/mulle-sde/mulle-sde/wiki) for more
information about managing libraries.


## mulle-sde linkorder

![](dox/mulle-sde-linkorder.svg)

The *linkorder* command outputs clang/gcc-style link commands that you can
use to link your *dependencies* and *libraries* outside of *mulle-sde*:


e.g.

``` sh
mulle-sde linkorder --output-format ld

-Wl,--whole-archive -Wl,--no-as-needed -lMulleObjC -Wl,--as-needed -Wl,--no-whole-archive -ldl -lmulle-container -Wl,--whole-archive -Wl,--no-as-needed -lmulle-objc-runtime -Wl,--as-needed -Wl,--no-whole-archive -lmulle-stacktrace -lmulle-vararg -lmulle-concurrent -lmulle-aba -lmulle-thread -lpthread -lmulle-allocator
```

## mulle-sde list

![](dox/mulle-sde-list.svg)

List environment variables, definitions, files and dependencies that comprise
your project:

``` sh
mulle-sde list
```

To see only the project files use:

``` sh
mulle-sde list --files
```

See [mulle-match](https://github.com/mulle-sde/mulle-match) for more
information on this command.


## mulle-sde log

![](dox/mulle-sde-log.svg)

List and inspect log files produced by craft.

``` sh
mulle-sde log list
mulle-sde log cat
mulle-sde log -p "MulleObjC" grep 'foo'
```


## mulle-sde patternfile

![](dox/mulle-sde-patternfile.svg)

Patternfile control the reflection of source files to the project files.
Manage the *patternfiles* that are used by `mulle-sde list` to classify the
files inside your project:

``` sh
mulle-sde patternfile list
```

See [mulle-match](https://github.com/mulle-sde/mulle-match) for more
information on this command.


## mulle-sde reflect

![](dox/mulle-sde-reflect.svg)

This command **reflects** changes made in the filesystem back into the
build-system "Makefiles", typically the `cmake/reflect` folder. In a C
language family based project, the reflection will also create header files
for inclusion in the `src/reflect` folder:

``` sh
rm src/foo.*
mulle-sde reflect
```

mulle-sde executes the tasks returned by the *callbacks* `source` and
`sourcetree`. The actual work is done by *tasks* of the chosen *extensions*.


## mulle-sde status

![](dox/mulle-sde-status.svg)

Get a quick description about the state of the mulle-sde project.

``` sh
mulle-sde status
```


## mulle-sde tool

![](dox/mulle-sde-tool.svg)

*Tools* are the commandline tools available in the virtual environment
provided by [mulle-env](/mulle-sde/mulle-env).
You can add or remove tools with this command set.

> This is only applicable to environment styles `restricted` and `tight`.
> The `inherit` style uses the default **PATH**.

``` sh
mulle-sde tool add nroff
```


## mulle-sde view

![](dox/mulle-sde-view.svg)

View combines the commands `craftinfo`, `dependency`, `library`,
`definition` to give an overview over craft relevant settings and linkage,
that are defined by mulle-sde. Build settings defined in **cmake** files are
not shown though.

``` sh
mulle-sde view
```



## Afterword

There are many more commands in mulle-sde. These are the most commonly
used ones.

# Quick Commands

Inside the **mulle-sde** subshell, you have a few aliases defined to save
you typework. These are

Command  | Description
---------|--------------------------------
c        | craft project
C        | clean and craft project
CC       | clean project and dependencies, then craft
t        | run tests that haven't run yet or failed one by one
tt       | craft project, then run tests like 't'
T        | clean and craft project, then run tests in parallel
TT       | clean project and dependencies, then craft, then test
l        | list files and dependencies
r        | reflect project


To have the same functionality without entering the subshell, define these
aliases in your `.bashrc`:

``` sh
alias c="mulle-sde craft"
alias C="mulle-sde clean; mulle-sde craft"
alias CC="mulle-sde clean all; mulle-sde craft"
alias t="mulle-sde test rerun --serial"
alias tt="mulle-sde test craft ; mulle-sde test rerun --serial"
alias T="mulle-sde test craft ; mulle-sde test"
alias TT="mulle-sde test clean all; mulle-sde test"
alias r="mulle-sde reflect"
alias l="mulle-sde list --files"
```



## You are here

![](dox/mulle-sde-overview.svg)



## Install

See [mulle-sde-developer](//github.com/mulle-sde/mulle-sde-developer) how to
install mulle-sde, which will also install mulle-sde with required
dependencies.

The command to install only the latest mulle-sde into
`/usr/local` (with **sudo**) is:

``` bash
curl -L 'https://github.com/mulle-sde/mulle-sde/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-sde-latest' && sudo ./bin/installer /usr/local
```



## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK


