# mulle-sde `virtualenv` for bash

mulle-sde is a terminal based software development environment. It opens a sub-shell, with a restricted environment. Developing inside a **mulle-sde** shell protects you from the following common mistakes:

* inadvertant reliance on non-standard tools
* reproducabilty problems due to non-standard environment variables

Executable          | Description
--------------------|--------------------------------
`mulle-sde`         | Virtual environment sub-shell

<!-- `mulle-sde-monitor` | Monitor filesystem and rebuild,test on demand (Future) -->


## What mulle-sde does in a nutshell

mulle-sde uses `env` to restrict the environment of the subshell to a minimal set of values. The PATH is modified, so that only a definable subset of tools is available.

As an example here is my environment when running normally:

```
Apple_PubSub_Socket_Render=/private/tmp/com.apple.launchd.yxJqn34O3N/Render
CAML_LD_LIBRARY_PATH=/Volumes/Users/nat/.opam/system/lib/stublibs:/usr/local/lib/ocaml/stublibs
DISPLAY=/private/tmp/com.apple.launchd.gKyY8aVeiV/org.macosforge.xquartz:0
HOME=/Volumes/Users/nat
LANG=de_DE.UTF-8
LOGNAME=nat
MANPATH=:/Volumes/Users/nat/.opam/system/man
OCAML_TOPLEVEL_PATH=/Volumes/Users/nat/.opam/system/lib/toplevel
OLDPWD=/Volumes/Source/srcO
OPAMUTF8MSGS=1
PATH=/Volumes/Users/nat/.opam/system/bin:/Volumes/Source/srcO/mulle-foundation-developer:/Volumes/Source/srcO/mulle-objc-developer:/Volumes/Source/srcM/mulle-sde:/Volumes/Source/srcM/mulle-templates:/Volumes/Source/srcM/mulle-project:/Volumes/Source/srcM/mulle-build:/Volumes/Source/srcM/mulle-dispense:/Volumes/Source/srcM/mulle-bootstrap:/Volumes/Source/srcM/mulle-sourcetree:/Volumes/Source/srcM/mulle-settings:/Volumes/Source/srcM/mulle-make:/Volumes/Source/srcM/mulle-fetch:/Volumes/Source/srcM/mulle-bashfunctions:/Volumes/Applications/Applications/Sublime Text.app/Contents/SharedSupport/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin
PERL5LIB=/Volumes/Users/nat/.opam/system/lib/perl5:
PWD=/Volumes/Source/srcO/MulleObjC-master
SHELL=/bin/bash
SHLVL=1
SSH_AUTH_SOCK=/private/tmp/com.apple.launchd.YrEMJV1DUq/Listeners
TERM=xterm-color
TERM_PROGRAM=Apple_Terminal
TERM_PROGRAM_VERSION=388.1.1
TERM_SESSION_ID=852D5E60-9A1B-43E0-A3D4-BC61BCD9134E
TMPDIR=/var/folders/jb/svqk0p3n73j46c3hfj_4fn3r0000xv/T/
USER=nat
XPC_FLAGS=0x0
XPC_SERVICE_NAME=0
_=/usr/bin/env
__CF_USER_TEXT_ENCODING=0x3BB:0x0:0x3
```

and this is inside **mulle-sde**

```
DISPLAY=/private/tmp/com.apple.launchd.gKyY8aVeiV/org.macosforge.xquartz:0
HOME=/Volumes/Users/nat
LOGNAME=nat
MULLE_UNAME=darwin
MULLE_VIRTUAL_ROOT=/Volumes/Source/srcO/MulleObjC-master
PATH=/Volumes/Source/srcO/MulleObjC-master/bin
PS1=\u@\h[MulleObjC-master] \W$ 
PWD=/Volumes/Source/srcO/MulleObjC-master
SHLVL=2
TERM=xterm-color
TMPDIR=/var/folders/jb/svqk0p3n73j46c3hfj_4fn3r0000xv/T/
USER=nat
_=/Volumes/Source/srcO/MulleObjC-master/bin/env
```

The `PATH` does not "escape" the virtual root as defined `MULLE_VIRTUAL_ROOT`.


## Prepare a directory to use mulle-sde

A directory must be set up properly, before you can use **mulle-sde** on it.
Let's try an example with a `/tmp/a` directory. We want a minimal portable set of commandline tools, so we specify the style as "none:empty".

```
mulle-sde init --style none:empty /tmp/a
```

And this is what happens:

```
$ mulle-sde /tmp/a
$ ls
bin
$ echo $PATH
/private/tmp/a/bin
$ cd bin
$ ls -l
total 336
lrwxr-xr-x  1 nat  wheel  12 Dec 18 15:40 awk -> /usr/bin/awk
lrwxr-xr-x  1 nat  wheel  17 Dec 18 15:40 basename -> /usr/bin/basename
...
lrwxr-xr-x  1 nat  wheel  14 Dec 18 15:40 which -> /usr/bin/which
```

## Enter the subshell

```
mulle-sde
```

## Leave the subshell

```
exit
```


## Adding tools 

> It is assumed, that your project is still in `/tmp/a`. 

You modify the `.mulle-sde-tools` file like this:

```
echo "cc" >> /tmp/a/.mulle-sde/tools
mulle-sde /tmp/a
```

## Adding environment variables

During start of the subshell the file `.mulle-sde/environment.sh` will be sourced. You can easily expand this file. Unless you reinitialize, your edits will be safe. Do not forget to `export` your environment variables.


## Tips and Tricks


#### Allow /bin and /usr/bin always

Use `mulle-sde -style none:restricted init` when initalizing your environment.

#### Reinitialize an environment

Use `mulle-sde -f init` to overwrite a previous environment.

#### Specify a global list of tools

Tools that you always require can be specified globally `~/.config/mulle-sde/tools`. These will be installed in addition to those found in `.mulle-sde/tools`.

#### Specify platform specific tools

If you need some tools only on a certain platform, figure out the platform name with `mulle-sde uname`. Then use this name (`MULLE_UNAME`) as the extension for `~/.config/mulle-sde/tools.${MULLE_UNAME}` or `.mulle-sde/tools.${MULLE_UNAME}`. 

Platform specifiy tool configuration files take precedence over the cross-platform ones without the extension.

#### Specify personal preferences (like a different shell)

Short of executing `exec zsh` - or whatever the shell flavor du jour is - everytime you enter the **mulle-sde** subshell, you can add this to your `.mulle-sde/environment-${USER}-user.sh` file:

```
$ cat <<EOF >> .mulle-sde/environment-${USER}-user.sh
if [ "${MULLE_SDE_SHELL}" = "INTERACTIVE" ]
then
   exec /bin/zsh
fi
EOF
```

    

