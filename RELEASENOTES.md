## 3.10.0

* a new shared command allows reuse of dependency build products across repositories, reducing craft times
* help AI to prevent common -D passing mistakes in vibecode mode












* dependency-dir (and other *-dir commands) now pass their options through to mulle-craft, so `--configuration` is honored instead of being dropped and silently falling back to Debug











feature: add platform support guards, syntax check, and expanded API exploration

* new `mulle-sde check` (also `craft --check`) runs a fast syntax/type check with -fsyntax-only, without linking
* `mulle-sde api` now scans crafted dependency headers and gains a `classes` command plus optional class/library arguments and `--class`/`--library` filters for symbols, functions, methods and factories
* `mulle-sde dependency add` supports `--amalgamated` and `--clibmode` (copy, deep-copy, hardlink, symlink); amalgamated clib deps default to manifest-src-only copy and land under the project source dir
* new `mulle-sde clean shared` explicitly removes the opt-in shared dependency store (kept out of tidy/gravetidy)
* projects can declare ``MULLE_SDE_SUPPORTED_PLATFORMS`` / ``MULLE_SDE_UNSUPPORTED_PLATFORMS`;` craft skips hosts that are not supported unless a platform was requested explicitly
* howto keyword matching canonicalizes dialect spellings (obj/objc, c++/cpp) and finds keyword lists on any line
* dependency renames are applied data-driven and idempotently on upgrade, with a new v3.9 -> v3.10 migration renaming CMake includes (InstallCMakeInclude -> AddSubdirectorySupport, InstallCMakePackage -> FindPackageSupport, InstallRpath -> Rpath)
* **BREAKING**: removed the `mulle-sde find` command alias


## 3.9.1

* `MULLE_SDE_REFLECT_CALLBACKS=NONE` now explicitly disables reflect callbacks (useful for fresh CI checkouts lacking the generated .mulle/share/monitor callbacks)


## 3.9.0



* new dependency comment sub-command


## 3.8.0



* new dependency comment sub-command
