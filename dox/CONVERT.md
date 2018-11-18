# Turn an existing project into a mulle-sde project

1. Checkout the project
2. Move old CMakeLists.txt away (but keep it for now)
3. Find suitable extension with `mulle-sde extension show`
4. mulle-sde init with the existing option
5. If something goes wrong during init, the easiest way to start a new is  `rm -rf .mulle-env .mulle-sde`

Example:

```
git clone <whatever>
cd whatever
mv CMakeLists.txt CMakeLists.txt.old
mulle-sde init --existing -m mulle-objc/objc-developer library
```


## Convert old `.bootstrap` folders to mulle-sde

List the contents of `.bootstrap/repositories`  and `.bootstrap/embedded_respositories`
folders.

`.bootstrap/repositories` example:
```
${MULLE_REPOSITORIES:-https://github.com/mulle-nat}/mulle-buffer;;${MULLE_BUFFER_BRANCH:-release}
${MULLE_REPOSITORIES:-https://github.com/mulle-nat}/mulle-utf;;${MULLE_UTF_BRANCH:-release}
${MULLE_REPOSITORIES:-https://github.com/mulle-nat}/mulle-sprintf;;${MULLE_SPRINTF_BRANCH:-release}

${MULLE_OBJC_REPOSITORIES:-https://github.com/mulle-objc}/MulleObjC;;${MULLE_OBJC_BRANCH:-release}
```


Add dependencies with the expanded URL, mulle-sde will do the rest. Versioning
is done implicitly with tags, which are part of the GitHub URL.

```
mulle-sde dependency add https://github.com/mulle-c/mulle-buffer/archive/latest.tar.gz
mulle-sde dependency add https://github.com/mulle-c/mulle-utf/archive/latest.tar.gz
mulle-sde dependency add https://github.com/mulle-c/mulle-sprintf/archive/latest.tar.gz
mulle-sde dependency add https://github.com/mulle-objc/MulleObjC/archive/latest.tar.gz
```

Check the
resulting "value added" URL, for modification possibilities `mulle-sourcetree list`.

> Optionally update  MULLE_FETCH_SEARCH_PATH for symlinks:
>
> `mulle-sde environment set MULLE_FETCH_SEARCH_PATH \
> '${MULLE_VIRTUAL_ROOT}/..:${MULLE_VIRTUAL_ROOT}/../../mulle-c:${MULLE_VIRTUAL_ROOT}/../../mulle-objc'`


## Add patternfiles if so desired

If you're not happy with he way `mulle-sde find` associates the files with
their type/category add a few more patternfiles.

Example:

There is a more finegrained distictions of headers and sources, to allow
selective removal of subprojects:

Exampl `SOURCES` is made up of `MULLE_OBJC_CORE_SOURCES`:

```
set( SOURCES
${MULLE_OBJC_CORE_SOURCES}
)
```

Figure out regexp to select the files and add them to a new patternfile, which
is ahead of the installed default rules:

```
cat 'src/Core/**/*.[cm]
src/Base/**/*.[cm]
src/Container/**/*.[cm]
src/Data/**/*.[cm]
src/Exception/**/*.[cm]
src/String/**/*.[cm]
src/Value/**/*.[cm]
' | mulle-sde patternfile add -p 40 -c mulle-objc-core-sources source -


## Set `MULLE_SDE_FETCH_PATH` to symlink depedency projects

Typically you would like to find your subprojects locally, so setup the search
path accordingly. Here is an example:


```
mulle-sde environment set MULLE_FETCH_SEARCH_PATH "/home/nat/srcO/mulle-c:/home/nat/srcO/mulle-objc:/home/nat/srcO/mulle-foundation:${PWD}/.."
```


## Clean some old cruft

Clean old stuff from the `mulle-bootstrap` era:

```
rm .CC
rm -rf .bootstrap.*
```

Modernize some stuff:

```
git mv tests test
git rm -rf templates
```

## Create a Sublime Text project


```
mulle-sde extension add mulle-sde/sublime-text
```

