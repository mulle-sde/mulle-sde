# mulle-sde install - Complete Reference

## Quick Start
Fetch, build and install a mulle-sde project and all its dependencies into a specified prefix directory.

```bash
# Install a project from GitHub
mulle-sde install https://github.com/mulle-core/mulle-sprintf/archive/latest.zip

# Install to custom prefix
mulle-sde install --prefix /usr/local https://github.com/user/project

# Install local project with symlinks
mulle-sde install --symlink --prefix /tmp/myinstall .
```

## All Available Options

### Basic Options (in usage)
- `--branch <name>`: branch to checkout
- `--c`: project is C
- `--debug`: install as debug instead of release
- `--keep-tmp`: don't delete temporary directory
- `--linkorder`: produce linkorder output
- `--objc`: project is Objective-C (default)
- `--only-project`: install only the main project
- `--post-init`: run post-init on temporary project
- `--prefix <prefix>`: installation prefix ($PWD)
- `--standalone`: create a whole-archive shared library if supported
- `--static`: produce shared libraries
- `--symlink`: allow symlinks for dependency fetches
- `--tag <name>`: tag to checkout
- `-d <dir>`: directory to fetch into (/tmp/...)
- `-k <dir>`: kitchen directory ($PWD/kitchen)

### Advanced Options (hidden)
- `--configuration <config>`: Set build configuration explicitly
  - **When to use**: When you need specific build configurations beyond debug/release
  - **Example**: `mulle-sde install --configuration RelWithDebInfo https://github.com/user/project`
  - **Side effects**: Overrides --debug/--release flags

- `--language <lang>`: Specify project language explicitly
  - **When to use**: When automatic language detection fails or you want to override
  - **Example**: `mulle-sde install --language c https://github.com/user/c-project`
  - **Side effects**: Bypasses automatic language detection based on project name

- `--preferred-library-style|--library-style <style>`: Control library type preference
  - **When to use**: When you need specific library types (static, dynamic, standalone)
  - **Example**: `mulle-sde install --library-style dynamic https://github.com/user/project`
  - **Side effects**: Affects how dependencies are built and linked

- `--shared|--dynamic`: Alias for --library-style dynamic
  - **When to use**: Quick way to force dynamic/shared libraries
  - **Example**: `mulle-sde install --shared https://github.com/user/project`

- `--release`: Override debug configuration to release
  - **When to use**: Explicitly force release build
  - **Example**: `mulle-sde install --debug --release https://github.com/user/project`

- `--test`: Use Test configuration
  - **When to use**: When installing test builds
  - **Example**: `mulle-sde install --test https://github.com/user/project`

- `--no-linkorder`: Suppress linkorder output (inverse of --linkorder)
  - **When to use**: When you explicitly don't want link information
  - **Example**: `mulle-sde install --no-linkorder https://github.com/user/project`

- `--marks <marks>`: Add additional sourcetree marks
  - **When to use**: For advanced project configuration
  - **Example**: `mulle-sde install --marks "no-tests,no-examples" https://github.com/user/project`
  - **Side effects**: Modifies how dependencies are processed

- `--url <url>`: Alternative way to specify URL
  - **When to use**: When URL contains special characters
  - **Example**: `mulle-sde install --url "https://github.com/user/project?ref=main"`

- `--build-dir|--kitchen-dir <dir>`: Set kitchen directory explicitly
  - **When to use**: When you need control over build location
  - **Example**: `mulle-sde install --kitchen-dir /tmp/build https://github.com/user/project`

### Environment Control

- **MULLE_FETCH_SEARCH_PATH**: Specify places to search local dependencies
  - **Default**: Current directory and system paths
  - **Set with**: `export MULLE_FETCH_SEARCH_PATH="/path/to/deps:/another/path"`
  - **Use case**: Building local projects with local dependencies

- **MULLE_SDE_FETCH**: Disable fetching entirely
  - **Default**: Not set (fetching enabled)
  - **Set with**: `export MULLE_SDE_FETCH=NO`
  - **Use case**: Offline builds or when dependencies are pre-fetched

- **TMPDIR**: Control temporary directory location
  - **Default**: /tmp
  - **Set with**: `export TMPDIR=/my/tmp`
  - **Use case**: When /tmp is too small or has special requirements

- **MULLE_VIRTUAL_ROOT**: Should not be set externally
  - **Default**: Managed internally
  - **Use case**: Internal use only - setting may cause issues

## Hidden Behaviors Explained

### URL/Pattern Detection
**Automatic language detection based on project name:**
- If project name is all lowercase ’ assumed C project
- If project name contains uppercase ’ assumed Objective-C project
- Override with --c or --objc flags

**Local vs Remote Repository Detection:**
- If URL is a local directory path ’ builds with local dependencies
- If URL is file:// ’ treated as local
- If URL is http/https/ftp ’ treated as remote
- Local builds automatically enable symlinks when --symlink is used

### Template Resolution Order
**Project initialization sequence:**
1. Creates temporary project directory
2. Runs `mulle-sde init` with detected language
3. Adds target project as dependency
4. Updates sourcetree to fetch all dependencies
5. Processes craftorder to determine build sequence
6. Builds all dependencies in correct order
7. Installs final products to --prefix location

### Context-Dependent Behaviors

**Project vs Non-Project Mode:**
- **Non-project mode** (default): Creates temporary project, adds target as dependency
- **Project mode** (--only-project): Builds existing project directly without dependency management

**Dependency Installation Strategy:**
- **Default mode**: All dependencies installed to --prefix via DEPENDENCY_DIR
- **Project-only mode**: Only main project installed, dependencies must exist elsewhere

**Build Configuration Cascade:**
1. --configuration flag takes highest precedence
2. --debug/--release flags override each other
3. --test sets Test configuration
4. Default is Release configuration

## Practical Examples

### Common Hidden Usage Patterns

#### Cross-Platform Installation
```bash
# Install with specific library style for Windows
mulle-sde install --library-style static --prefix /mingw64 https://github.com/user/project

# Install debug build for development
mulle-sde install --debug --keep-tmp --prefix /tmp/debug-install https://github.com/user/project

# Install specific branch/tag
mulle-sde install --branch develop --prefix /tmp/dev https://github.com/user/project
mulle-sde install --tag v1.2.3 --prefix /tmp/stable https://github.com/user/project
```

#### Local Development Workflow
```bash
# Install local project with all local dependencies
export MULLE_FETCH_SEARCH_PATH="/path/to/local/deps"
mulle-sde install --symlink --prefix /tmp/local-install .

# Build and install only current project
mulle-sde install --only-project --prefix /tmp/project-only .
```

#### Advanced Configuration
```bash
# Install with custom marks for embedded systems
mulle-sde install --marks "no-tests,no-docs,embedded" --configuration MinSizeRel https://github.com/user/embedded-lib

# Install standalone library (whole-archive)
mulle-sde install --standalone --prefix /usr/local https://github.com/user/monolithic-lib

# Install with specific build flags passed through
mulle-sde install --prefix /opt/custom https://github.com/user/project -- CFLAGS="-O3 -march=native"
```

#### Integration with Build Systems
```bash
# Install dependencies for CI/CD
mulle-sde install --serial --prefix $WORKSPACE/deps https://github.com/user/dependency

# Install and capture link information
mulle-sde install --linkorder --prefix /tmp/deps https://github.com/user/project > link-flags.txt

# Install with test configuration for integration testing
mulle-sde install --test --prefix /tmp/test-deps https://github.com/user/project
```

### Environment Variable Overrides

#### Custom Dependency Resolution
```bash
# Build project with local dependency overrides
export MULLE_FETCH_SEARCH_PATH="/home/user/projects:/opt/local/lib"
mulle-sde install --symlink --prefix /tmp/custom https://github.com/user/project

# Offline build with pre-downloaded dependencies
export MULLE_SDE_FETCH=NO
export MULLE_FETCH_SEARCH_PATH="/path/to/pre-downloaded/deps"
mulle-sde install --prefix /tmp/offline https://github.com/user/project
```

#### Temporary Directory Management
```bash
# Use SSD for faster builds
export TMPDIR=/mnt/fast-ssd/tmp
mulle-sde install --prefix /opt/project https://github.com/user/large-project

# Keep temporary files for debugging
export TMPDIR=/tmp/debug-builds
mulle-sde install --keep-tmp --debug --prefix /tmp/project-debug https://github.com/user/project
```

## Troubleshooting

### When to Use Hidden Options

#### Build Failures
**Problem**: Dependencies fail to build with default settings
**Solution**: Use --serial for sequential builds
```bash
mulle-sde install --serial --prefix /tmp/debug https://github.com/user/project
```

**Problem**: Library conflicts with system libraries
**Solution**: Use --only-project to skip dependencies
```bash
mulle-sde install --only-project --prefix /usr/local https://github.com/user/project
```

#### Performance Issues
**Problem**: Slow builds due to dependency complexity
**Solution**: Use local builds with symlinks
```bash
export MULLE_FETCH_SEARCH_PATH="/path/to/local/deps"
mulle-sde install --symlink --prefix /tmp/local https://github.com/user/project
```

#### Debug Complex Installations
**Problem**: Need to inspect build artifacts
**Solution**: Keep temporary directory
```bash
mulle-sde install --keep-tmp --debug --prefix /tmp/inspect https://github.com/user/project
# Build artifacts available in /tmp/mulle-sde-*
```

### Integration with Other Commands

#### With `craft` Command
```bash
# Install uses craft internally, so craft flags can be passed
mulle-sde install https://github.com/user/project -- --cmake-options="-DCMAKE_VERBOSE_MAKEFILE=ON"

# Install dependencies first, then craft project
mulle-sde install --prefix /opt/deps https://github.com/user/dependency
craft --dependency-dir /opt/deps
```

#### With `product` Command
```bash
# Install to product directory
mulle-sde install --prefix "$(mulle-sde product get-dir)" https://github.com/user/dependency

# Install and update product manifest
mulle-sde install --prefix /opt/products https://github.com/user/lib
mulle-sde product add /opt/products
```

#### With `dependency` Command
```bash
# Install dependency to project-specific location
mulle-sde dependency add github:user/project
mulle-sde install --prefix .deps github:user/project
mulle-sde dependency set-dir project github:user/project .deps
```

#### With `export` Command
```bash
# Install and create redistributable package
mulle-sde install --prefix /tmp/install-root https://github.com/user/project
mulle-sde export --source /tmp/install-root --destination /tmp/package.tar.gz
```

### Common Error Scenarios

#### Network Issues
```bash
# Use local mirrors or cached dependencies
export MULLE_FETCH_SEARCH_PATH="/path/to/mirror"
mulle-sde install --symlink --prefix /tmp/local https://github.com/user/project
```

#### Permission Problems
```bash
# Install to user directory
mulle-sde install --prefix $HOME/.local https://github.com/user/project

# Use different temporary directory
export TMPDIR=$HOME/tmp
mulle-sde install --prefix $HOME/.local https://github.com/user/project
```

#### Build Configuration Issues
```bash
# Override automatic detection
mulle-sde install --c --prefix /usr/local https://github.com/user/c-project
mulle-sde install --objc --prefix /usr/local https://github.com/user/objc-project
```