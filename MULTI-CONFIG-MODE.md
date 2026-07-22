# MULTI CONFIG REFLECTION - FULL IMPLEMENTATION NOTES

This document captures the multi-config reflection work end-to-end, including
all relevant behavior, code paths, tests, and companion template changes.

The core goal is to support shared/symlinked source trees without clobbering
generated reflection artifacts between sourcetree configs.


## 1. Problem Statement

Before this work, reflected/generated files lived in single fixed locations:

- `cmake/reflect/...`
- `src/reflect/...`

When multiple sourcetree configs (`config`, `alt`, `x11`, `wayland`, ...) were
used in the same checkout, reflecting one config overwrote output for the other.
That is especially problematic for symlinked/shared dependency trees.


## 2. High-Level Design

Controlled by `MULLE_SDE_REFLECT_CONFIGS` (colon-separated list stored in
`.mulle/etc/sde/reflect-configs`):

- Empty/unset: legacy single-config behavior (`cmake/reflect/`, `src/reflect/`)
- Non-empty (e.g. `config:alt`): multi-config with config-specific dirs

In multi-config mode for config `<name>`, output is written to:

- `cmake/reflect.<name>/...`
- `src/reflect.<name>/...`

Key principle: **reflect only the active config**. The active config is set via
`MULLE_SOURCETREE_CONFIG_NAME`. Use `mulle-sde config craft` to iterate all
configs (reflect + build each).


## 3. Command Interface

### 3.1 `mulle-sde config` (redesigned)

```bash
mulle-sde config                              # print current config (same as get)
mulle-sde config get                          # print current active config
mulle-sde config set <name>                   # change active config
mulle-sde config list                         # show project + dependency configs (--all default)
mulle-sde config list --project               # project configs only
mulle-sde config list --dependency            # dependency configs only
mulle-sde config show                         # alias for reflect-configs display
mulle-sde config craft                        # iterate all configs: reflect + craft each
mulle-sde config reflect-configs [val]        # set/print reflect-configs

mulle-sde config dependency list              # list dependency configs with current values
mulle-sde config dependency get <dep>         # get dependency's active config
mulle-sde config dependency set <dep> <name>  # set dependency config + clean fetch
```

### 3.2 `mulle-sde dependency config`

Alias — dispatches to `sde::config::dependency "$@"`.

### 3.3 Environment variables

- `MULLE_SDE_REFLECT_CONFIGS=config:alt:...` — colon-separated list of build configs
- `MULLE_SOURCETREE_CONFIG_NAME` — active config for reflect/build
- `MULLE_SOURCETREE_CONFIG_NAME_<DEP>` — per-dependency config selection

### 3.4 Marker file

`.mulle/etc/sde/reflect-configs` — contains the config list (e.g. `config:alt`).
Used by:
- Parent projects to detect multi-config deps (skip "need config switch" error)
- `config list` to discover available configs per dependency
- `config dependency list` to enumerate deps that have configs

### 3.5 Config switching (`dependency set`)

```bash
mulle-sde config dependency set MulleGLFW wayland
```

What it does:
1. Sets `MULLE_SOURCETREE_CONFIG_NAME_<DEP>=<name>` in `--this-host` scope
2. Runs `clean fetch` to invalidate stash + kitchen (different transitive deps)

Options: `--this-host` (default), `--this-os`, `--global`, `--scope <name>`

No symlink check — just sets the env var. The dependency doesn't need to be
re-reflected since all configs are pre-reflected.


## 4. Core `mulle-sde` Code Changes

### 4.1 `src/mulle-sde-reflect.sh`

- Multi-config block only reflects the **active** config (from
  `MULLE_SOURCETREE_CONFIG_NAME`), not all configs
- `sde::reflect::configure_paths_for_config` — sets `reflect.<name>` output
  paths + exports `MULLE_SOURCETREE_CONFIG_NAME`
- `MULLE_SOURCETREE_TO_C_OBJC_DEPS_FILE` set to DISABLE in multi-config
  (build-time `mulle-objc-deps-tool` handles it)

### 4.2 `src/mulle-sde-config.sh` (full redesign)

- `get` / bare command — prints current config
- `set` / `switch` — changes active config
- `list` — two sections with `log_info` headers:
  - "Project config:" — reads reflect-configs, shows `<project> = <active> (<available>)`
  - "Dependency configs:" — walks stash dir for deps with reflect-configs marker
- `dependency list/get/set` — sub-subcommands for dependency config management
- `craft` — iterates `MULLE_SDE_REFLECT_CONFIGS`, for each: reflect + craft
  using `-DMULLE_SOURCETREE_CONFIG_NAME=<name>`
- `reflect_configs` — persist config list + marker file + cleanup stale dirs

### 4.3 `src/mulle-sde-dependency.sh`

- `config)` case dispatches to `sde::config::dependency "$@"`

### 4.4 `src/mulle-sde-craft.sh`

- Added check: if dependency has `.mulle/etc/sde/reflect-configs` marker,
  skip the "need config switch" error entirely (all configs pre-reflected)


## 5. CMake Template Changes (`mulle-sde-developer`)

### 5.1 `CMakeLists.txt` templates (all 5 project-oneshot types)

Minimal reflect-dir selection logic:

```cmake
if( NOT DEFINED ENV{MULLE_SOURCETREE_CONFIG_NAME} AND NOT MULLE_SOURCETREE_CONFIG_NAME)
   set( MULLE_SDE_REFLECT_DIR "reflect")
else()
   if( MULLE_SOURCETREE_CONFIG_NAME)
      set( MULLE_SDE_REFLECT_DIR "reflect.${MULLE_SOURCETREE_CONFIG_NAME}")
   else()
      set( MULLE_SDE_REFLECT_DIR "reflect.$ENV{MULLE_SOURCETREE_CONFIG_NAME}")
   endif()
endif()
```

Reads `MULLE_SOURCETREE_CONFIG_NAME` from:
- cmake `-D` variable (passed by mulle-craft for dep builds)
- `$ENV{}` (set locally during reflect)

If unset → legacy `reflect` directory. No fallback, no EXISTS checks.

### 5.2 `Headers.cmake`

- `_mulle_filter_reflect_entries()` — filters out entries from non-active
  reflect dirs in INCLUDE_DIRS, headers lists
- Ensures active reflect dir is in INCLUDE_DIRS

### 5.3 `Files.cmake`

Default for legacy projects without new CMakeLists.txt:

```cmake
if( NOT MULLE_SDE_REFLECT_DIR)
   set( MULLE_SDE_REFLECT_DIR "reflect")
endif()
```

Uses `${MULLE_SDE_REFLECT_DIR}` for install source paths:

```cmake
if( EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/_Dependencies.cmake")
   list( APPEND INSTALL_CMAKE_INCLUDES "cmake/_Dependencies.cmake")
elseif( EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${MULLE_SDE_REFLECT_DIR}/_Dependencies.cmake")
   list( APPEND INSTALL_CMAKE_INCLUDES "cmake/${MULLE_SDE_REFLECT_DIR}/_Dependencies.cmake")
endif()
```

**Critical:** Projects must `mulle-sde upgrade` to get this fix. Without it,
`MULLE_SDE_REFLECT_DIR` is empty and `_Dependencies.cmake` / `_Libraries.cmake`
don't get installed → missing transitive link deps.

### 5.4 `filesystem-task.sh` (cmake + c-cmake)

Log message includes `${MULLE_SOURCETREE_CONFIG_NAME}` for clarity.


## 6. mulle-craft Changes

### 6.1 Config name pass-through (`mulle-craft-build.sh`)

When building a dependency with non-default config, mulle-craft passes
`-DMULLE_SOURCETREE_CONFIG_NAME=<name>` to cmake. This lets the dependency's
`CMakeLists.txt` select the correct `reflect.<name>` directory.


## 7. Companion Tool Changes

### 7.1 `mulle-sourcetree-to-c` (line 894)

Fixed category dependency format:
```
{ @selector( MulleObjCDeps), @selector( %s) }
```

### 7.2 `mulle-objc-deps-tool`

Added `chmod a+w` before write and `chmod a-w` after, matching project
convention for generated files.

### 7.3 `CreateDepsIncObjC.cmake`

Uses `MULLE_SDE_REFLECT_DIR` for output path instead of hardcoded `src/reflect/`.


## 8. Tests

### 8.1 `test/53-config-list/run-test`

Updated assertion to match new `config list` output format.

### 8.2 `test/54-config-commands/run-test`

New test covering:
- `config get` — prints current config
- `config list --all` / `--project` / `--dependency`
- `config dependency list` / `get`
- Help text output

### 8.3 `test/80-multi-config-backend/run-test`

End-to-end multi-config reflection test:
- Creates a library with two sourcetree configs (config→foo, alt→bar)
- Reflects each config via `-DMULLE_SOURCETREE_CONFIG_NAME=<name>`
- Verifies `cmake/reflect.<name>/` and `src/reflect.<name>/` dirs created
- Verifies includes are config-specific and independent
- Verifies marker file content
- Verifies per-config `_Dependencies.cmake`


## 9. Practical Usage

```bash
# Enable multi-config in a library
mulle-sde config reflect-configs "config:alt"

# Reflect a specific config
mulle-sde -DMULLE_SOURCETREE_CONFIG_NAME=config reflect
mulle-sde -DMULLE_SOURCETREE_CONFIG_NAME=alt reflect

# Or reflect+craft all configs at once
mulle-sde config craft

# In parent project: switch dependency config (does clean fetch)
mulle-sde config dependency set MulleGLFW wayland
mulle-sde craft

# Check current state
mulle-sde config                    # current project config
mulle-sde config list               # full overview
mulle-sde config dependency list    # dependency configs
```


## 10. Files Modified

In `mulle-sde`:
- `src/mulle-sde-reflect.sh` — single-config reflect, configure_paths_for_config
- `src/mulle-sde-config.sh` — full redesign (list, dependency, craft, get/set)
- `src/mulle-sde-dependency.sh` — alias wiring for `dependency config`
- `src/mulle-sde-craft.sh` — skip config check for multi-config deps

In `mulle-sde-developer`:
- `src/mulle-sde/cmake/project-oneshot/*/CMakeLists.txt` (all 5 variants)
- `src/mulle-sde/c-cmake/project/all/cmake/share/Headers.cmake`
- `src/mulle-sde/cmake/project/all/cmake/share/Files.cmake`
- `src/mulle-sde/cmake/share/monitor/libexec/filesystem-task.sh`
- `src/mulle-sde/c-cmake/share/monitor/libexec/filesystem-task.sh`

In `mulle-craft`:
- `src/mulle-craft-build.sh`

In `mulle-sourcetree`:
- `mulle-sourcetree-to-c` — line 894 format fix

In `mulle-objc`:
- `mulle-objc-list/mulle-objc-deps-tool` — chmod fix
- `mulle-objc-developer/.../CreateDepsIncObjC.cmake` — MULLE_SDE_REFLECT_DIR


## 11. Known Issues / TODO

### 11.1 Projects need `mulle-sde upgrade`

All projects need `mulle-sde upgrade` to pick up the new `Files.cmake` with
the `MULLE_SDE_REFLECT_DIR` default. Without it, `_Dependencies.cmake` and
`_Libraries.cmake` don't get installed into the dependency include dir,
causing missing link-time symbols for transitive deps.

### 11.2 Patternfiles in share

Default `70-header--*-generated-headers` patternfiles only match
`src/reflect/*.h`. Need `src/reflect.*/*.h` added to the share versions in
`mulle-sde-developer` so projects get multi-config support without manual
overrides.

### 11.3 `-D` flag required for config name

`MULLE_SOURCETREE_CONFIG_NAME` must be passed via `mulle-sde -D...` flag
(not just exported as env var) because `mulle-env` doesn't pass through
external environment variables into the virtual environment.

### 11.4 `config craft` uses `-D` flag

`config craft` passes `-DMULLE_SOURCETREE_CONFIG_NAME=<name>` to ensure the
config name reaches both reflect and craft stages inside the virtual env.

### 11.5 `config dependency set` scope

Defaults to `--this-host` scope. When a value exists in a lower-priority scope
(e.g. `os-linux`), mulle-env shows an "Overriding" info message. This is
correct behavior — host-specific values take precedence.
