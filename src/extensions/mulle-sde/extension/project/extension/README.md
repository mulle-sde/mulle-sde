# <|PROJECT_NAME|>,  <|PROJECT_DESCRIPTION|>

This is a mulle-sde extension.


## Use without installation

```
# from where this README.md is 
MULLE_SDE_EXTENSION_PATH="${PWD}:${MULLE_SDE_EXTENSION_PATH}"
export MULLE_SDE_EXTENSION_PATH

mulle-sde extension list
```

## Install

```
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make install
```


## Source

The source is located at [src/extensions/<|VENDOR_NAME|>/<|PROJECT_NAME|>]()

See the [mulle-sde Wiki](https://github.com/mulle-sde/mulle-sde/wiki) for 
information about how to develop extensions.
