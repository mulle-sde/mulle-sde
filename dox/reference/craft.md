# mulle-sde craft - Complete Reference

## Quick Start
Build your project and all its dependencies with automatic dependency management and build system generation.

```bash
mulle-sde craft                    # Build everything
mulle-sde craft project            # Build only the main project
mulle-sde craft craftorder         # Build only dependencies
mulle-sde craft --clean --serial   # Clean build with single-threaded compilation
```

## All Available Options

### Basic Options (in usage)
- `-h`: Show help
- `-v`: Show verbose tool output
- `-C`: Clean all before crafting
- `-g`: Clean gravetidy before crafting
- `-q`: Skip uptodate checks (quick mode)
- `--`: Pass remaining flags to mulle-craft
- `--analyze`: Run clang analyzer
- `--build-style <style>`: Set build configuration (Debug/Release/Test/RelDebug)
- `--c-build-style <style>`: Set separate configuration for dependencies
- `--clean`: Clean before crafting
- `--cppcheck`: Run cppcheck after crafting
- `--from <domain>`: Clean specific dependency before crafting
- `--run`: Run produced executable after build
- `--serial`: Compile one file at a time

### Advanced Options (hidden)

#### Clean Control Options
- `--clean-domain <name>`: Clean specific domain (alias for `--from`)
  - **When to use**: When you need to clean only a specific dependency or subsystem
  - **Example**: `mulle-sde craft --clean-domain zlib`
  - **Side effects**: Only removes build artifacts for the specified domain

- `--clean-all`: Clean all build artifacts
  - **When to use**: When you want to force a complete rebuild
  - **Example**: `mulle-sde craft --clean-all`
  - **Side effects**: Equivalent to `mulle-sde clean all`

- `--tidy`: Clean using tidy mode
  - **When to use**: When you want to clean build artifacts but preserve some cache
  - **Example**: `mulle-sde craft --tidy`
  - **Side effects**: Removes build artifacts but keeps configuration cache

- `--no-clean`: Skip automatic cleaning
  - **When to use**: When you trust existing build artifacts and want faster builds
  - **Example**: `mulle-sde craft --no-clean`
  - **Side effects**: May fail if build artifacts are stale

#### Build Configuration Options
- `--build-type <style>`: Alias for `--build-style`
- `--c-build-type <style>`: Alias for `--c-build-style`
- `--craftorder-build-type <style>`: Alias for `--c-build-style`
- `--craftorder-build-style <style>`: Alias for `--c-build-style`

- `--debug`: Quick flag for Debug build
  - **When to use**: When developing and need debugging symbols
  - **Example**: `mulle-sde craft --debug`
  - **Side effects**: Sets build style to Debug

- `--release`: Quick flag for Release build
  - **When to use**: When building for production
  - **Example**: `mulle-sde craft --release`
  - **Side effects**: Sets build style to Release

#### Analysis Options
- `--analyze-dir <path>`: Custom output directory for analyzer results
  - **When to use**: When you need analyzer output in a specific location
  - **Example**: `mulle-sde craft --analyze --analyze-dir /tmp/analysis`
  - **Side effects**: Overrides MULLE_SCAN_BUILD_DIR environment variable

#### Reflection Control
- `--no-reflect`: Skip automatic reflection
  - **When to use**: When you've manually run reflect and want to skip it
  - **Example**: `mulle-sde craft --no-reflect`
  - **Side effects**: Build may fail if dependencies are out of sync

- `--quick`: Alias for `--no-reflect`
- `no-update`: Alias for `--no-reflect`

#### Parallel Build Control
- `--parallel`: Enable parallel compilation (default)
- `--no-parallel`: Disable parallel compilation

#### Debug Options
- `--dump-env`: Dump environment variables and exit
  - **When to use**: When debugging environment issues
  - **Example**: `mulle-sde craft --dump-env`
  - **Side effects**: Shows sorted environment, then exits without building

- `--no-motd`: Skip message of the day
  - **When to use**: When running in CI or automated environments
  - **Example**: `mulle-sde craft --no-motd`
  - **Side effects**: Suppresses informational messages

#### Pass-through Options
- `--sync-flags <flags>`: Pass flags to sourcetree sync operations
  - **When to use**: When you need to control sourcetree behavior
  - **Example**: `mulle-sde craft --sync-flags --serial`
  - **Side effects**: Flags passed to underlying mulle-sourcetree operations

### Environment Control

#### Build Configuration
- `MULLE_SDE_CRAFT_STYLE`: Default build style for the project
  - **Default**: Debug
  - **Set with**: `export MULLE_SDE_CRAFT_STYLE=Release`
  - **Use case**: Setting a project-wide default build configuration

- `MULLE_SDE_CRAFTORDER_STYLE`: Default build style for dependencies
  - **Default**: Same as MULLE_SDE_CRAFT_STYLE
  - **Set with**: `export MULLE_SDE_CRAFTORDER_STYLE=Release`
  - **Use case**: Building dependencies in Release while debugging main project

- `MULLE_SDE_TARGET`: Default target to build
  - **Default**: all
  - **Set with**: `export MULLE_SDE_TARGET=project`
  - **Use case**: Always building only the project without dependencies

- `MULLE_SDE_CRAFT_TARGET`: Alias for MULLE_SDE_TARGET

#### Analysis Tools
- `MULLE_SCAN_BUILD`: Tool to use for static analysis
  - **Default**: mulle-scan-build (macOS), scan-build (Linux)
  - **Set with**: `export MULLE_SCAN_BUILD=/opt/custom/scan-build`
  - **Use case**: Using a custom static analyzer

- `MULLE_SCAN_BUILD_DIR`: Output directory for analyzer results
  - **Default**: kitchen/analyzer
  - **Set with**: `export MULLE_SCAN_BUILD_DIR=/tmp/analysis`
  - **Use case**: Redirecting analysis output to a specific location

- `MULLE_SCAN_BUILD_OPTIONS`: Additional options for scan-build
  - **Default**: None
  - **Set with**: `export MULLE_SCAN_BUILD_OPTIONS="-enable-checker security"
  - **Use case**: Enabling specific static analysis checks

#### Build Flags
- `MULLE_SDE_MAKE_FLAGS`: Flags passed to mulle-make via mulle-craft
  - **Default**: None
  - **Set with**: `export MULLE_SDE_MAKE_FLAGS="-j8"
  - **Use case**: Controlling parallel build behavior

- `MULLE_CRAFT_MAKE_FLAGS`: Alias for MULLE_SDE_MAKE_FLAGS

#### Reflection Control
- `MULLE_SDE_REFLECT_BEFORE_CRAFT`: Force reflection before building
  - **Default**: NO
  - **Set with**: `export MULLE_SDE_REFLECT_BEFORE_CRAFT=YES`
  - **Use case**: Ensuring build files are always up-to-date

- `MULLE_SDE_REFLECT_CALLBACKS`: Callbacks to run during reflection
  - **Default**: None
  - **Set with**: `export MULLE_SDE_REFLECT_CALLBACKS="filesystem,sourcetree"
  - **Use case**: Controlling which reflection tasks run

#### Cppcheck Configuration
- `CPPCHECK`: Path to cppcheck executable
  - **Default**: cppcheck from PATH
  - **Set with**: `export CPPCHECK=/usr/local/bin/cppcheck`
  - **Use case**: Using a specific cppcheck version

- `CPPCHECKFLAGS`: Default flags for cppcheck
  - **Default**: --inconclusive --enable=warning,performance,portability --max-ctu-depth=8
  - **Set with**: `export CPPCHECKFLAGS="--enable=all --xml"
  - **Use case**: Customizing cppcheck analysis

- `CPPCHECKAUXFLAGS`: Additional flags for cppcheck
  - **Default**: None
  - **Set with**: `export CPPCHECKAUXFLAGS="--suppress=missingIncludeSystem"
  - **Use case**: Adding project-specific suppressions

- `CPPCHECKPLATFORMS`: Platforms to analyze with cppcheck
  - **Default**: native
  - **Set with**: `export CPPCHECKPLATFORMS=all`
  - **Use case**: Cross-platform static analysis

#### Build Environment
- `MULLE_SDE_ALLOW_BUILD_SCRIPT`: Allow custom build scripts
  - **Default**: Not set
  - **Set with**: `export MULLE_SDE_ALLOW_BUILD_SCRIPT=YES`
  - **Use case**: Enabling custom build scripts in project

#### Project Information
- `PROJECT_TYPE`: Type of project (automatically set)
  - **Values**: executable, library, none
  - **Use case**: When PROJECT_TYPE=none, only dependencies are built

- `PROJECT_DIALECT`: Programming language dialect
  - **Values**: c, objc, cpp
  - **Use case**: Influences analyzer tool selection

- `PROJECT_NAME`: Name of the project
  - **Automatic**: Derived from directory name
  - **Use case**: Used for executable naming

## Hidden Behaviors Explained

### Automatic Dependency Management

#### Sourcetree Status Detection
The craft command automatically detects sourcetree changes:
- **Status 0**: Clean - no changes detected
- **Status 1**: Missing - no sourcetree (initial setup)
- **Status 2**: Dirty - changes detected, triggers rebuild
- **Status 3**: Force mode (via MULLE_FLAG_MAGNUM_FORCE)

#### Automatic Reflection Triggers
Reflection runs automatically when:
1. Sourcetree status is >= 2 (dirty/changed)
2. MULLE_SDE_REFLECT_BEFORE_CRAFT=YES
3. No craftorder file exists (initial setup)
4. Dependencies have different config names

#### Config Name Validation
For each dependency, craft validates that the sourcetree config name matches:
```bash
# Automatic check performed for each dependency
mulle-sde config switch -d <dependency> <config-name>
```

### Build Style Resolution

#### Resolution Order
1. Command line option (--build-style, --debug, --release, etc.)
2. Environment variable (MULLE_SDE_CRAFT_STYLE)
3. Default: Debug

#### Style Mapping
- **Debug**: `--debug`
- **Release**: `--release`
- **RelDebug**: `--release-debug` (Release with debug symbols)
- **Test**: `--test --library-style dynamic`

### Craftorder File Generation

#### Automatic Creation
The craftorder file is recreated when:
1. Sourcetree status is >= 2 (dirty/changed)
2. Target is 'all' or 'craftorder'
3. File doesn't exist (initial setup)

#### Host-specific Naming
Craftorder files are host-specific:
```
.craftorder/<hostname>.craftorder
```

### Cross-platform Behavior

#### Platform Detection
- **Windows**: Uses scan-build.exe and win32/win64 platforms
- **macOS**: Uses mulle-scan-build by default for Objective-C
- **Linux**: Uses standard scan-build

#### Platform-specific cppcheck
Automatic platform detection for cppcheck:
- **64-bit**: unix64, win64
- **32-bit**: unix32, win32A, win32W, mips32
- **16-bit**: pic16
- **8-bit**: avr8, elbrus-e1cp, pic8, pic8-enhanced

### Target Resolution Logic

#### Target Processing Order
1. Command line argument
2. MULLE_SDE_TARGET environment variable
3. MULLE_SDE_CRAFT_TARGET environment variable
4. Default: "all"

#### Special Target Handling
- **"NONE"**: Skips all building (useful for CI)
- **""** (empty): Defaults to "all"
- **PROJECT_TYPE=none**: Forces "craftorder" target

## Practical Examples

### Common Hidden Usage Patterns

#### Development Workflow
```bash
# Fast rebuild without reflection (when you're sure nothing changed)
mulle-sde craft --no-reflect

# Debug build with specific flags
mulle-sde craft --debug --serial -- -j1

# Release build with clean
mulle-sde craft --release --clean-all

# Build and immediately test
mulle-sde craft --run
```

#### CI/CD Pipeline
```bash
# CI build with specific configuration
export MULLE_SDE_CRAFT_STYLE=Release
export MULLE_SDE_CRAFTORDER_STYLE=Release
mulle-sde craft --no-motd --clean-all

# Static analysis in CI
mulle-sde craft --analyze --cppcheck --no-motd
```

#### Cross-compilation Setup
```bash
# Build dependencies in Release, project in Debug
mulle-sde craft --c-build-style Release --build-style Debug

# Same effect with environment variables
export MULLE_SDE_CRAFTORDER_STYLE=Release
export MULLE_SDE_CRAFT_STYLE=Debug
mulle-sde craft
```

#### Debugging Build Issues
```bash
# Diagnose environment issues
mulle-sde craft --dump-env

# Verbose build with single threading
mulle-sde -v craft --serial --debug

# Force rebuild everything
MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde craft --clean-all
```

### Environment Variable Overrides

#### Custom Build Configuration
```bash
# Set up for production builds
export MULLE_SDE_CRAFT_STYLE=Release
export MULLE_SDE_CRAFTORDER_STYLE=Release
export MULLE_SDE_MAKE_FLAGS="-j$(nproc)"

# Set up for development with custom flags
export MULLE_SDE_CRAFT_STYLE=Debug
export MULLE_SDE_MAKE_FLAGS="-j4 VERBOSE=1"
export CPPCHECKFLAGS="--enable=all --xml"
```

#### Static Analysis Setup
```bash
# Custom analyzer setup
export MULLE_SCAN_BUILD="/usr/local/bin/scan-build"
export MULLE_SCAN_BUILD_DIR="/tmp/static-analysis"
export MULLE_SCAN_BUILD_OPTIONS="-enable-checker security"

# Run with custom cppcheck
export CPPCHECK="/opt/cppcheck/cppcheck"
export CPPCHECKPLATFORMS="all"
mulle-sde craft --cppcheck
```

#### CI Environment
```bash
# Skip all interactive elements
export MULLE_SDE_REFLECT_BEFORE_CRAFT=YES
export MULLE_SDE_ALLOW_BUILD_SCRIPT=YES
mulle-sde craft --no-motd --clean-all
```

## Troubleshooting

### When to Use Hidden Options

#### Build Failures
- **Issue**: CMake cache issues after dependency changes
- **Solution**: `mulle-sde craft --clean-all`

- **Issue**: Parallel build failures
- **Solution**: `mulle-sde craft --serial`

- **Issue**: Out-of-date build files
- **Solution**: `mulle-sde craft --clean` or set `MULLE_SDE_REFLECT_BEFORE_CRAFT=YES`

#### Performance Issues
- **Issue**: Slow builds due to unnecessary reflection
- **Solution**: `mulle-sde craft --no-reflect` when you know dependencies haven't changed

- **Issue**: Want faster parallel builds
- **Solution**: `export MULLE_SDE_MAKE_FLAGS="-j$(nproc)"`

#### Static Analysis
- **Issue**: scan-build not found
- **Solution**: `export MULLE_SCAN_BUILD=/path/to/scan-build`

- **Issue**: cppcheck not found
- **Solution**: `export CPPCHECK=/usr/local/bin/cppcheck`

### Environment Debugging
```bash
# Check current configuration
mulle-sde craft --dump-env | grep -E "(MULLE_SDE_|PROJECT_)"

# Verify target resolution
echo "Target: ${MULLE_SDE_TARGET:-${MULLE_SDE_CRAFT_TARGET:-all}}"

# Check build style
echo "Build style: ${MULLE_SDE_CRAFT_STYLE:-Debug}"
echo "Craftorder style: ${MULLE_SDE_CRAFTORDER_STYLE:-${MULLE_SDE_CRAFT_STYLE:-Debug}}"
```

### Common Error Messages

#### "Need config switch for <dependency>"
This occurs when a dependency is configured with a different sourcetree config name than expected.
```bash
# Check current config
mulle-sde config list -d <dependency>
# Switch to expected config
mulle-sde config switch -d <dependency> <expected-config>
```

#### "Analyzer tool is not available in PATH"
Install the required tool or set the environment variable:
```bash
# For macOS
brew install llvm
export MULLE_SCAN_BUILD=/usr/local/opt/llvm/bin/scan-build

# For Ubuntu/Debian
sudo apt-get install clang-tools
```

#### "Can't find executable to run"
The executable name is derived from PROJECT_NAME. Check the actual executable:
```bash
ls kitchen/*/  # See what's actually built
mulle-sde craft --run --build-style Debug  # Ensure matching build style
```