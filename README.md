## What mulle-sde does in a nutshell

Essentially, mulle-sde is a shortcut for typing:

```
${SHELL}
cd "${directory}"
eval `mulle-bootstrap paths run`
[ ! -d ".bootstrap.auto" ] && mulle-bootstrap
```

So what mulle-sde does is start a new subshell. Changes to the given directory
and adds the dependencies of that directory to the PATH and LD_LIBRARY_PATH.

If there are dependencies that need to be bootstrap, mulle-sde does that too.

