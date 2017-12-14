# mulle-sde `virtualenv` for C and Objective-C

> work in progress

mulle-sde is a terminal based software development environment and is a
collection of bash scripts. It is based on
[mulle-bootstrap](//github.com/mulle-nat/mulle-bootstrap)


Executable          | Description
--------------------|--------------------------------
`mulle-sde`         | Virtual environment shell
`mulle-sde-monitor` | Monitor filesystem and rebuild,test on demand
`mulle-sde-init`    | Setup C, ObjC, C++ projects with tests, git repo etc.


## What mulle-sde does in a nutshell

If you know Python's
[virtualenv](https://python-guide-pt-br.readthedocs.io/en/latest/dev/virtualenvs/)
does, you pretty much know what **mulle-sde** does. Essentially, mulle-sde is a
shortcut for typing:

```
${SHELL}
cd "${directory}"
eval `mulle-bootstrap paths run`
[ ! -d ".bootstrap.auto" ] && mulle-bootstrap
```

mulle-sde starts a new subshell with the working directory set to the given
project. The environment by default is reset to a minimal set of values.
It then adds the dependencies of your project to the PATH and LD_LIBRARY_PATH.

If there are dependencies that need to be bootstrap, mulle-sde does that too.

If there is a file called `.mulle-sde-environment.sh` mulle-sde will source it.


