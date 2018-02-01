# 🏋🏼 Cross-platform IDE for the command-line

... for Linux, OS X, FreeBSD, Windows

**mulle-sde** is a command-line based software development environment. The idea is to organize your project with the filesystem, and then let **mulle-sde** reflect the changed filesystem back to the "Makefile".

* creates projects
* can build your project via **mulle-craft** or some other buildtool
* tests your project via **mulle-test** or some other testtool
* adds and removes dependencies via **mulle-sourcetree**
* monitors filesystem changes and updates your project files
* can be extended to other languages and buildtools

![](dox/mulle-sde-overview.png)



Executable      | Description
----------------|--------------------------------
`mulle-sde`     | Create projects, add and remove dependencies, monitor filesystem and rebuild and test on demand


> **mulle-sde** strives to be buildtool and language agnostic. But out of the box, it supports only C
> and cmake as no other extensions are available yet.


## Create a **mulle-sde** "hello world" project

As the various tools that comprise **mulle-sde** are configured with environment variables, `mulle-sde init` will create  a virtual environment using **mulle-env**, so that various projects can coexist.

This is an example, that creates a cmake project for C (this is the default):

```
$ mulle-sde init -d hello executable
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

Monitor the filesystem for new, deleted or modified source files. Then update project files and rebuild or retest:

```
$ mulle-sde monitor
```

Leave the environment:

```
$ exit
```

## Commands

### mulle-sde dependencies

![](dox/mulle-sde-dependencies.png)

**Dependencies** are typically GitHub projects, that provide a library (like zlib).
These will be downloaded, unpacked and built into `dependencies`:

```
mulle-sde dependencies add https://github.com/madler/zlib/archive/v1.2.11.tar.gz
```


### mulle-sde extensions

**Extensions** are the build systems supported by mulle-sde. The built-in support is:

Extensiontype  | Vendor  | Name   | Description
---------------|---------|--------|--------------------------
common         | builtin | common | Provides the executables `create-build-motd`, `is-test-file`, `source-directory-names`, `test-directory-names`. It also provides a default README.md file.
runtime        | builtin | c      | Provides the executables `classify-headers`, `classify-sources`, `is-header-or-source` for C projects. And it also provides a bunch of template files for initial C projects.
buildtool      | builtin | cmake  | Provides the executables `did-update-sourcetree`, `did-update-src` for cmake projects. And it also provides a bunch of template files for cmake projects.

Use `mulle-sde extensions list` to check if your extensions are picked up.

See the [mulle-sde Wiki](https://github.com/mulle-sde/mulle-sde/wiki) for more information about extensions.


### mulle-sde libraries

![](dox/mulle-sde-libraries.png)

Libraries are OS provide libraries (like libm.a) that you don't want to build yourself as a dependency.

```
mulle-sde libraries add m
```

### mulle-sde monitor

Conceptually, **monitor** waits on changes to the filesystem and then calls **update** (see below) to rebuild and retest your project.

![](dox/mulle-sde-monitor.png)


Environment       | Default        | Description
------------------|----------------|--------------------
`MULLE_SDE_CRAFT` | `mulle-craft`  | Build tool to invoke
`MULLE_SDE_TEST`  | `mulle-test`   | Test tool to invoke

See **update** for a slew of other environment variables, that also
affect **monitor**.

> You can use a different built tool, than `mulle-craft`, but you'll be losing
> out on a lot of functionality.

### mulle-sde tools

![](dox/mulle-sde-tools.png)

**Tools** are the commandline tools available in the virtual environment provided by [mulle-env](/mulle-sde/mulle-env).
You can add or remove tools with this command set.

```
mulle-sde tools add nroff
```

### mulle-sde update

An **update** reflects your changes made in the filesystem back into 'Makefiles'.

In the case of `cmake` the script `did-update-src` will create the files `_CMakeHeaders.cmake` and `_CMakeSources.cmake`. They will be created by examining the contents of the folder `src` and its subfolders. `did-update-sourcetree` will create `_CMakeDependencies.cmake` and `_CMakeLibraries.cmake` from the contents of the [mulle-sourcetree](/mulle-sde/mulle-sourcetree).

![](dox/mulle-sde-update.png)

The way **update** is creating the output can be customized. You can substitute the `did-update-...` scripts with your own. Or you can tweak the output quite a bit, by changes to the inferior scripts like `classify-sources`.

Environment                        | Default                  | Description
-----------------------------------|--------------------------|-------------------
`MULLE_SDE_DID_UPDATE_SRC`         | `did-update-src`         | Invoked, when a change to sourcefiles has been detected. If you set this to "NO", it will not be called.
`MULLE_SDE_DID_UPDATE_SOURCETREE`  | `did-update-sourcetree`  | Invoked, when a change to a `./mulle-sourcetree/config` has been detected. . If you set this to "NO", it will not be called.
`MULLE_SDE_IS_HEADER_OR_SOURCE`    | `is-header-or-source"`   | Determines by filename if a file is a source file
`MULLE_SDE_IS_TEST_FILE`           | `is-test-file`           | Determines by filename if a file is a test file
`MULLE_SDE_CLASSIFY_HEADERS`       | `classify-headers`       | Classify headers as public, private
`MULLE_SDE_CLASSIFY_SOURCES`       | `classify-sources`       | Classify sources as normal or standalone


If you did set both `MULLE_SDE_DID_UPDATE_SRC` and `MULLE_SDE_DID_UPDATE_SOURCETREE`
to "NO", nothing will happen.

>
> It is probably easiest, to copy the installed script and edit it. Then set the environment variable to use
> your edited script instead of the default.
>
> You could also just edit the installed script directly. It is after all a private copy to the project.
> But there is a slight chance of losing your changes, if someone reinitializes your project
> (to use a different buildtool maybe)
>

