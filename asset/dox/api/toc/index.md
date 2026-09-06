# mulle-sde Library Documentation for AI
<!-- Keywords: ide, cli, dependency-manager, reflect, craft, environment, bash -->

## 1. Introduction & Purpose

mulle-sde (MulleSDE) is a cross-platform command-line IDE and dependency
(package) manager for C-family projects (C, Objective-C, likely C++), running
on Android, BSDs, Linux, macOS, SunOS, and Windows (MinGW, WSL). It is written
entirely in Bash and acts as a convenience front-end over a stack of
lower-level MullekybernetiK tools (`mulle-env`, `mulle-sourcetree`,
`mulle-craft`, etc.).

The core workflow is the **Edit - Reflect - Craft** cycle:

* **Edit** - Use any editor (optionally set up via `mulle-sde edit`) to manage
  project files in `src/`.
* **Reflect** - File-system changes are picked up by `mulle-sde reflect`,
  which regenerates build-system files (CMake) and header files
  (recursively created `_include.h`, `_Dependencies.cmake`, etc.).
* **Craft** - `mulle-sde craft` fetches dependencies, builds them locally
  into the project, and then builds the project itself.

It also manages third-party dependencies (GitHub projects and the like),
second-party (OS) libraries (e.g. `pthread`), environment variables, project
definition flags (CFLAGS etc.), platforms, subprojects, patternfiles, and
tests. It is the "user interface" for the `mulle-sde` ecosystem: the actual
power comes from the underlying commands like `mulle-env` and
`mulle-sourcetree`, which are almost never called directly when using
mulle-sde.

## 2. Key Concepts & Design Philosophy

* **Edit-Reflect-Craft** is the fundamental development cycle. The filesystem
  is the source of truth; `reflect` reads it and produces derived artifacts.
* **Virtual environment / subshell**: `mulle-sde` executes most commands
  inside a `mulle-env` subshell (bounced via `-C`). This is why the command
  set differs between "outside" a project (init, add, install, ...) and
  "inside" a project (craft, dependency, reflect, ...). The project root is
  identified by `MULLE_VIRTUAL_ROOT` and its fnv1a-32 hash
  `MULLE_VIRTUAL_ROOT_ID`.
* **Bounce architecture**: Many commands are thin wrappers that dispatch to
  dedicated `src/mulle-sde-<name>.sh` implementation files, each exposing a
  `sde::<name>::main()` entry point, or directly forward to an underlying
  tool (e.g. `craft` -> `mulle-craft`, `json` -> `mulle-sourcetree json`,
  `callback`/`task` -> `mulle-monitor`).
* **Two tiers of "party" libraries**: third-party dependencies (remote
  projects, via `sourcetree`/`dependency`) vs. second-party OS libraries
  (via `library`, e.g. `pthread`).
* **Configuration files**: project configuration lives under `.mulle/etc/`
  (`env/` for environment, `sourcetree/` for the dependency graph). Derived
  artifacts are written to `cmake/reflect.<config>/` and `src/reflect.<config>/`.
* **Multi-config (reflect-mode)**: The `-DMULLE_SOURCETREE_CONFIG_NAME=<name>`
  define selects a configuration so that reflect output is generated
  per-config into `reflect.<config>` directories; a marker file
  `.mulle/etc/sde/reflect-configs` records the set of configs.
* **Vibecoding / sweatcoding**: special modes (`mulle-sde vibecoding`) that
  guard against unsafe operations and fake-platform overrides, aimed at
  AI-assisted development. When active, craft/log may be redirected to the
  test environment, and the exit trap shows a howto hint on failure.
* **Environment transition**: `-E`/`--environment-transition`,
  `-e`/`--environment-override`, and search flags govern how `mulle-env`
  locates or (re)enters the virtual environment.

## 3. Core API & Data Structures

mulle-sde is a Bash CLI, not a C library: there are no `.h` headers. Its
public API is the `mulle-sde [flags] [command] [options]` command line. The
entry point is the executable `mulle-sde` (dispatch in `sde::main`), with all
command implementations in `src/mulle-sde-<name>.sh`.

### 3.1. Global flags (dispatch in `sde::main`)

* `-d <dir>`: change to `<dir>` (via `cd`) before executing the command.
* `-DKEY=VALUE`: define a one-time environment variable for the command.
* `--defines`: read `-DKEY=VALUE` lines (one per line) from the next argument.
* `-e` / `--environment-override`: treat `$PWD` as the virtual root
  (`MULLE_VIRTUAL_ROOT`) without entering a `mulle-env` subshell.
* `-E` / `--environment-transition`: attempt a proper transition between
  environments (adds `--environment-transition` to `MULLE_ENV_FLAGS`).
* `-f` / `--force`: force operations (sets `MULLE_FLAG_MAGNUM_FORCE`).
* `-c` / `-C`: immediately run `mulle-env` instead (used for entering).
* `-N` / `--search-nearest` / `--no-search`: control environment searching
  (`--no-search` is historic); also `--search-as-is`, `--search-here`,
  `--search-none`.
* `--style <val>`: select an environment style (see `mulle-env help`).
* `--no-vibe*`: turn vibecoding off (`MULLE_VIBECODING=NO`).
* `--no-test-check`: disable the test-environment assertion
  (`MULLE_SDE_TEST_CHECK=NO`).
* `--git-terminal-prompt`: allow git to prompt (sets `GIT_TERMINAL_PROMPT`).
* `--version`: print `MULLE_EXECUTABLE_VERSION` (currently `3.9.0`).
* `--list-flags`: print all supported flags.
* Technical flags (`options_technical_flags`, from `mulle-bashfunctions`):
  `-n` (dry run), `-s` (quiet), `-v`/`-vv`/`-vvv` (verbose), `-ld` (debug),
  `-le` (environment debug), `-lt` (bash tracing), `-lx` (external command
  log).

Two modes of `-h|--help|help`: shows the minimal command set outside a
project, and the full command set inside a project. `mulle-sde commands`
prints the complete machine-readable list of all commands (including aliases,
e.g. `dep` -> `dependency`, `files` -> `list`, `def` -> `definition`,
`env` -> `environment`, `lib` -> `library`, `pat` -> `patternfile`,
`config` <-> `sourcetree`, `sweatcoding` <-> `vibecoding`).

### 3.2. Commands (organized by function)

The full list is obtained with `mulle-sde commands`. Grouped:

**Project lifecycle and scaffolding**
- `init`: create a new project (interactive or with `-d <dir> -m <extension>`).
- `init-and-enter`: init then immediately start a `mulle-env` subshell.
- `reinit`: destructive re-init (requires `-f`; `--allow-project`/`--allow-demo`).
- `add`: create a source file from templates.
- `remove`: remove files from the project.
- `project`: rename a project and its files.
- `steal`: copy files from another project.
- `protect` / `unprotect`: set/clear the write-protect attribute
  (`a-w` / `ug+w`) on project files.
- `symlink`: create symlinks in the project.
- `product`: print the main executable/library location (heuristic).
- `project-dir` / `source-dir`: print project root / source directory.
- `upgrade`: upgrade an older mulle-sde project layout.
- `migrate`: development-only migration helper (requires `-f`).

**Reflection and build configuration**
- `reflect` (alias `update`): regenerate project makefiles and headers.
- `config` (alias `sourcetree`): show multiple sourcetree configurations;
  subcommand `reflect-mode`/`reflect-configs` manages per-config reflection.
- `callback` / `task`: manage reflection callbacks/tasks (via `mulle-monitor`).
- `monitor`: watch project files and run reflect + craft.
- `definition` (aliases `def`, `definitions`): change craft options like CFLAGS.
- `style`: show or set the project style.
- `tool` / `tool-env`: manage build tools / show tool environment variables.

**Craft / build / run**
- `craft` (via `mulle-craft`), `recraft` (= `craft --tidy`) and `crun`
  (craft and run).
- `check`: fast syntax check of project sources (no link).
- `craftinfo`: show build flags of dependencies.
- `craftorder` / `craftstatus` (alias `craft-status`): show craft order/status.
- `donefile`: show contents of `mulle-craft` donefiles.
- `log` (alias `logstatus`): show craft results.
- `run` / `debug`: run / debug the executable product.
- `searchpath`: show search path for build products.
- `link-args` / `linkorder`: show linker arguments / header include order
  for dependencies and libraries.
- `headerorder`: show header includes for dependencies and libraries.

**Dependencies, libraries and environment**
- `dependency` (alias `dep`): manage third-party components (GitHub projects
  etc.). Subcommands include `add`, `remove`, `move`, `list`, `mark`,
  `unmark`, `comment`, `headers`, `libraries`, `craftinfo`.
- `library` (aliases `lib`, `libraries`): manage second-party (OS) libraries.
- `export`: export a dependency or library as `mulle-sde` commands.
- `fetch`: fetch the sourcetree (also triggered automatically on `craft`).
- `json`: show dependencies and libraries as JSON (via `mulle-sourcetree`).
- `treestatus`: show all four sourcetree configuration states.
- `environment` (alias `env`): manage environment variables (project
  settings). `get`/`set` fetch/set single variables through `mulle-env`.
- `env-identifier`: map a name like `MulleUIOS` to `MULLE_UIOS`.
- `enter`: enter the `mulle-sde` subshell environment.
- `exec` (alias `execute`): run a command inside the subshell.
- `install`: install a remote mulle-sde project (like `make install`).
- `extension` (alias `ext`): manage language and buildtool extensions;
  `show` lists available meta extensions.

**File handling / patternfiles**
- `list` (alias `file`, `files`): list project files matching patternfiles.
- `match` (alias `patternmatch`): experiment with patternfiles.
- `patternfile` (aliases `pat`, `patternfiles`): manage patternfiles.
- `patterncheck` / `patternenv` / `filename`: check/predict pattern matching.
- `ignore`: block files from being crafted.
- `move`: move/rename files in the project.
- `mark` / `unmark`: mark files with attributes (through `dependency::main`).

**Inspection / status**
- `status` (alias `doctor`): show project state / diagnose issues.
- `verify`: verify the project product against its sources.
- `symbol` (alias `symbols`): list C and Objective-C symbols of the project.
- `view`: give an overview over the project settings.
- `commands`: list all available commands (with aliases and help availability).
- `howto`: show a list of development topics for more extensive help.
- `api`: show API documentation from dependencies.
- `code`: search and navigate dependency source code.
- `unveil`: produce sandbox CSV output.

**Platform / identity (no environment needed)**
- `uname`, `hostname`, `username`: print simplified machine identity from
  `MULLE_UNAME`, `MULLE_HOSTNAME`, `MULLE_USERNAME`.
- `common-unames`: list supported platform names.
- `version`: print `MULLE_EXECUTABLE_VERSION`.
- `libexec-dir` (alias `library-path`): print mulle-sde libexec directory.

**Tests / IDE**
- `test` (alias `retest`): run tests via `mulle-test`. Main subcommands are
  `init`, `craft`, `run`, `status`, `clean`, `coverage`, `verify`,
  `test-dir`, `platform <p> craft`, `rerun`. Multiple test directories can be
  targeted, and a `test/` directory (`<dir>/.mulle/share/test`) must exist.
- `editor` and `<topic>-editor`
  (`definition-editor`, `environment-editor`, `monitor-editor`,
  `patternfile-editor`, `sourcetree-editor`, `tool-editor`): run GUI tools
  (needs node.js; installs `mulle-<topic>-editor`).
- `edit`: open the project in the preferred editor.
- `vibecoding` / `sweatcoding`: enable the (AI) development mode.
- `todo`: show TODO items (via `mulle-todo`).

**Directory shortcuts (command suffixes)**
For dependency/kitchen/stash directories, `-dir`, `-ls`, `-open`, `-tree`,
`-exec`, `-eval` suffixes act on that directory, e.g. `kitchen-dir`,
`kitchen-tree`, `dependency-exec`, and `<name>::<cmd>` evaluates a command
inside that directory.

### 3.3. Key environment variables

- `MULLE_VIRTUAL_ROOT`: physical project root; `MULLE_VIRTUAL_ROOT_ID` is its
  fnv1a-32 hex id (env `environment.sh` must set both).
- `MULLE_SDE_LIBEXEC_DIR`: location of the implementation scripts
  (`src` in development, `<prefix>/libexec` when installed).
- `MULLE_SDE_VAR_DIR`, `MULLE_SDE_ETC_DIR`, `MULLE_SDE_SHARE_DIR`: provided
  by `mulle-env mulle-tool-env sde`.
- `MULLE_SOURCETREE_CONFIG_NAME`: selects a sourcetree configuration for
  per-config reflection (set via `-DMULLE_SOURCETREE_CONFIG_NAME=<name>`).
- `MULLE_UNAME`, `MULLE_HOSTNAME`, `MULLE_USERNAME`: platform identity
  (must not be overridden to fake a platform when vibecoding).
- `MULLE_VIBECODING`: `YES` enables the guarded development mode.
- `MULLE_SDE_TEST_CHECK`: `NO` skips the test-environment checks.
- `MULLE_SDE_CLEAN_BEFORE_CRAFT`, `MULLE_TEST_CLEAN_BEFORE_RUN`,
  `MULLE_SDE_CLEAN_DEFAULT`: control automatic cleaning in the test cycle.
- `MULLE_SDE_TRACE`: `YES` enables trace output at start-up.
- `MULLE_SDE_SANDBOX` / `MULLE_SDE_SANDBOX_FLAGS`: optional sandbox wrapper
  (e.g. lljail) around `mulle-env` invocations.
- `MULLE_SDE_CURRENT_CMD`: current command name, exported for hooks.
- `MULLE_SDE_<CMD>_OK` / `MULLE_SDE_<CMD>_FAIL`: user hook variables executed
  after a command succeeds/fails.

### 3.4. Directory layout (generated by `mulle-sde`)

- `.mulle/etc/env/environment.sh`: project environment.
- `.mulle/etc/sourcetree/`: dependency sourcetree configuration.
- `.mulle/etc/sde/reflect-configs`: colon-separated list of config names for
  multi-config reflection (e.g. `config:alt`).
- `.mulle/share/test`, `test/`: test environments.
- `cmake/reflect.<config>/`, `src/reflect.<config>/`: per-config reflect
  output (generated headers like `_<project>-include.h`, `_Dependencies.cmake`).
- `kitchen/`: build directory.
- `src/`: project sources; `dox/`: documentation.

## 4. Performance Characteristics

mulle-sde is a Bash script orchestrating external tools; performance is
dominated by process spawns and the `mulle-env` subshell bounce, not by
in-memory algorithms.

* **Subshell bounce**: every in-project command typically re-execs through
  `mulle-env -C`, so each invocation is relatively expensive (O(1) but with
  high constant). The README warns: "Try to avoid running mulle-sde commands
  in parallel."
* **Sourcetree operations**: delegated to `mulle-sourcetree`/`mulle-fetch`;
  dependency ordering (`craftorder`, `linkorder`, `headerorder`) is a
  topological sort of the (typically small) dependency graph.
* **Reflection**: `reflect` regenerates files for the whole project, so
  incremental edits are cheaper than re-running `reflect`; use `monitor` for
  automatic reflects.
* **Symbol listing** (`symbol`): a scan over the project sources.
* **Thread-safety**: not applicable (single-process CLI). Concurrency hazards
  come from running multiple `mulle-sde` processes on the same project; use
  the included `craft` lock (see `74-craft-lock-release` test).

## 5. AI Usage Recommendations & Patterns

* **Always use the two principal invocations correctly**: initialize new
  projects with `mulle-sde init [ -d <dir> ] [ -m <mode> ] <type>` where type
  is e.g. `executable` or `library`; enter an existing project with
  `mulle-sde <dir>` (or `cd <dir>` first).
* **After any file-system edit** (add/remove/rename/move in `src/`), run
  `mulle-sde reflect` before `mulle-sde craft`.
* **Remember the environment split**: outside a project only
  `add, api, code, extension, howto, init, install, show, commands,
  init-and-enter, libexec-dir, uname, version` exist. Everything else
  requires being inside a project environment (or use `-e` to treat `$PWD`
  as a virtual root).
* **Use `-n` (dry run) and `-v`/`-vv` (verbose) to observe what a command
  would do, especially for destructive ones (`reinit`, `clean`, `project`).
  `reinit` and `migrate` require `-f`.
* **Platform checks use the real host**; do not override
  `MULLE_HOSTNAME`, `MULLE_UNAME` or `MULLE_USERNAME` to fake a platform.
  Use `mulle-sde test --platform <platform> craft` for cross-compilation.
* **Multi-config projects**: reflect with
  `mulle-sde -DMULLE_SOURCETREE_CONFIG_NAME=<config> reflect`; each config
  produces isolated `reflect.<config>` output, and `mulle-sde config list
  --project` shows the available configs.
* **Vibecoding mode** (`mulle-sde vibecoding`) redirects `craft`/`log`
  toward the test environment and blocks `edit`/`editor`; disable it with
  `--no-vibe` if a plain workflow is needed.
* **Common pitfalls**: do not edit generated reflection output under
  `cmake/reflect.*` or `src/reflect.*` (regenerated); do not delete the
  `kitchen/` directory with `clean` variants you do not understand
  (`clean tidy` vs. `clean gravetidy`); remember `clean` inside a test
  directory requires the `test` prefix.

## 6. Integration Examples

These examples are written in plain Bash, following the style of the
project's own tests (3-space indent, Allman-ish function braces are used in
the `.sh` sources; shell examples use the existing test conventions).

### Example 1: Initialize an executable project (non-interactive)

```bash
#!/bin/sh
# Initialize an Objective-C executable project in "myproject".
# -d creates and changes into the directory, -m selects a template bundle.
mulle-sde init -d myproject -m foundation/objc-developer executable
cd myproject || exit 1

# Overview commands
mulle-sde view        # project summary
mulle-sde files       # files that match patternfiles
mulle-sde dependency  # third-party dependencies
mulle-sde library     # second-party (OS) libraries
```

### Example 2: The Edit-Reflect-Craft cycle

```bash
#!/bin/sh
# Add a source file, reflect the change and craft the project.
mulle-sde add src/MyClass.m

mulle-sde ignore src/MyClass.m src/MyClass.h   # optional: skip pattern matching
mulle-sde files --unmatched                    # see what does not match yet

mulle-sde reflect    # regenerate makefiles and generated headers
mulle-sde craft      # fetch dependencies, build them, build the project
mulle-sde run        # run the built executable product
```

### Example 3: Manage a third-party dependency

```bash
#!/bin/sh
# Add a GitHub dependency, position it, tweak its flags and craft.
mulle-sde dependency add github:madler/zlib.tar
mulle-sde dependency move zlib to top
mulle-sde dependency list

mulle-sde craftinfo zlib CFLAGS "-DBAR=1"   # set per-dependency CFLAGS
mulle-sde dependency headers                # header include order
mulle-sde dependency libraries              # linker library order

mulle-sde craft
```

### Example 4: Multi-config (reflect-mode) reflection

```bash
#!/bin/bash
# Reflect per sourcetree configuration (see test/80-multi-config-backend).
mulle-sde init -d mylib -m mulle-sde/c-developer library
cd mylib || exit 1

# default config
mulle-sde dependency add --address foo 'https://example.com/foo.tar.gz'
mulle-sourcetree set foo userinfo "include=foo/foo.h"

# config "config" and "alt"
mulle-sde config add alt
mulle-sde config list --project          # -> config, alt

mulle-sde -DMULLE_SOURCETREE_CONFIG_NAME=config reflect   # -> src/reflect.config
mulle-sde -DMULLE_SOURCETREE_CONFIG_NAME=alt reflect      # -> src/reflect.alt

grep -q "foo/foo.h" mylib/src/reflect.config/_mylib-include.h
grep -q "bar/bar.h" mylib/src/reflect.alt/_mylib-include.h

cat .mulle/etc/sde/reflect-configs       # -> config:alt
```

### Example 5: Test cycle

```bash
#!/bin/sh
# Initialize, craft and run the test suite for the project.
mulle-sde test init
mulle-sde test craft      # builds test executables (prefers --dynamic libs)
mulle-sde test run
mulle-sde test coverage
mulle-sde test verify     # syntax-verify test sources
```

## 7. Dependencies

Direct dependencies (from `.mulle/etc/project/formula-info.sh`):

- `mulle-bashfunctions`
- `mulle-env`
- `mulle-craft`
- `mulle-menu`
- `mulle-monitor`
- `mulle-platform`
- `mulle-sourcetree`
- `mulle-template`
- `mulle-test`

`mulle-fetch` is also invoked at runtime (e.g. by `install` and
`try_to_enter_or_download`), and the editors (node-based) are optional
late downloads.