# 🏋🏼 Cross-platform IDE for the command-line

... for Linux, OS X, FreeBSD, Windows

**mulle-sde** is a command-line based software development environment. The
idea is to organize your project with the filesystem, and then let
**mulle-sde** reflect the changed filesystem back to the "Makefile".

** mulle-sde**

* provides a form of package management (called dependencies)
* creates projects and template files
* can build your project with [mulle-craft](//github.com/mulle-sde/mulle-craft) or some other buildtool
* tests your project with [mulle-test](//github.com/mulle-sde/mulle-test) or some other testtool
* monitors filesystem changes via [mulle-monitor](//github.com/mulle-sde/mulle-monitor) and updates your project files
* can be extended to other languages and buildtools

![](dox/mulle-sde-overview.png)



Executable      | Description
----------------|--------------------------------
`mulle-sde`     | Create projects, add and remove dependencies, monitor filesystem and rebuild and test on demand


> **mulle-sde** strives to be buildtool and language agnostic. But out of the 
> box, it supports only C
> and cmake as no other extensions are available yet.


## Create a **mulle-sde** "hello world" project

As the various tools that comprise **mulle-sde** are configured with 
environment variables, `mulle-sde init` will create  a virtual environment 
using **mulle-env**, so that various projects can coexist on a filesystem with 
minimized interference.

> For the following you need to install the following extensions:
> [mulle-sde-c](//github.com/mulle-sde/mulle-sde-c) and 
> [mulle-sde-cmake](//github.com/mulle-sde/mulle-sde-cmake) 
> 

This is an example, that creates a cmake project for C (this is the default):

```
$ mulle-sde init -d hello -b mulle-sde:cmake -r mulle-sde:c executable
```

Enter the environment:

```
$ mulle-sde hello
```

Build it:

```
$ mulle-sde craft
```

Run it:

```
$ ./build/hello
```

Monitor the filesystem for new, deleted or modified source files. Then update 
some of your source or project files. **mulle-sde** will rebuild your project 
automatically:

```
$ mulle-sde monitor
```

Leave the environment:

```
$ exit
```

# Commands

## mulle-sde craft

![](dox/mulle-sde-craft.png)

Builds your project including all dependencies.


```
mulle-sde craft
```


## mulle-sde dependency

![](dox/mulle-sde-dependency.png)

*Dependencies* are typically GitHub projects, that provide a library (like zlib).
These will be downloaded, unpacked and built into `dependencies` with the next build:

```
mulle-sde dependency add https://github.com/madler/zlib/archive/v1.2.11.tar.gz
```


## mulle-sde extension

*Extensions* add support for build systems, language runtimes and other tools to mulle-sde. *Extensions* are used during *init* to setup a project. A project, setup with a hypothetically "spellcheck" mulle-sde extension, might be look like this:

![](dox/mulle-sde-extension.png)

There is a *patternfile* `00-text-all` to classify interesting files to spellcheck. There is a *callback* `text-callback` that gets activated via this *patternfile* that will schedule the *task* `aspell-task.sh`. Also the extension may install template files like `demo.txt`.

*mulle-sde* knows about four different extension types

Extensiontype  | Description
---------------|-------------------------------------
common         | Provides most basic functionality like a default README file.
buildtool      | Support for buildtools like **cmake** .
runtime        | Support for language/runtime combinations like C with X11 
extra          | Support for extra features like **git**

The builtin support is:

Extensiontype  | Vendor    | Name   | Description
---------------|-----------|--------|--------------------------
common         | mulle-sde | sde    | Provides the executable `create-build-motd`. It also provides a default README.md file.

Use `mulle-sde extension list` to check the extensions available.

See the [mulle-sde Wiki](https://github.com/mulle-sde/mulle-sde/wiki) for more 
information about adding and writing extensions.


## mulle-sde library

![](dox/mulle-sde-library.png)

Libraries are operating system provided libraries (like `libm.a`) that you don't want to build 
yourself as a dependency.

```
mulle-sde library add m
```

## mulle-sde monitor

Conceptually, *monitor* waits on changes to the filesystem and then calls the appropriate callback (see below) to rebuild and retest your project.

![](dox/mulle-sde-monitor.png)


Environment       | Default        | Description
------------------|----------------|--------------------
`MULLE_SDE_CRAFT` | `mulle-craft`  | Build tool to invoke
`MULLE_SDE_TEST`  | `mulle-test`   | Test tool to invoke

> Resist the itch to replace `mulle-craft` with **make** or some other tool. Rather
> write a *buildtool* extension to create Makefiles and write a **mulle-craft** plugin
> to let it deal with Makefiles. 



## mulle-sde tool

![](dox/mulle-sde-tool.png)

*Tools* are the commandline tools available in the virtual environment 
provided by [mulle-env](/mulle-sde/mulle-env).
You can add or remove tools with this command set.

> This is only applicable to environment styles `:restricted` and `:none`.
> The `:inherit` style uses the default **PATH**.

```
mulle-sde tool add nroff
```

## mulle-sde update

An *update* reflects changes made in the filesystem back into the buildsystem "Makefiles". **mulle-sde** executes the task returned by the *callbacks* `source` and `sourcetree`. The actual work is done by *tasks* of the chosen *extensions*.

![](dox/mulle-sde-update.png)

