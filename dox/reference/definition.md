# mulle-sde definition - Complete Reference

## Quick Start
The `mulle-sde definition` command manages build definitions (compiler flags, build settings, and environment variables) for mulle-sde projects, allowing fine-grained control over the build process across different platforms and scopes.

## All Available Options

### Basic Options (in usage)
- `--definition-dir <dir>`: specify the definition directory to manipulate
- `--platform <name>`: use the platform specific scope instead of global

### Advanced Options (hidden)
- `--share-definition-dir <dir>`: override the shared definition directory location
  - **Default**: `.mulle/share/craft/definition`
  - **When to use**: When working with custom mulle-sde installations or shared configuration repositories
  - **Example**: `mulle-sde definition --share-definition-dir /opt/mulle/share/craft/definition list`
  - **Side effects**: Changes where system-wide defaults are read from

- `--etc-definition-dir <dir>`: override the etc definition directory location
  - **Default**: `.mulle/etc/craft/definition`
  - **When to use**: When using custom project layouts or centralized configuration management
  - **Example**: `mulle-sde definition --etc-definition-dir /etc/mulle/definitions set CFLAGS "-O3"`
  - **Side effects**: User overrides will be stored in the specified directory

- `--global`: operate only on global definitions (not platform-specific)
  - **When to use**: When setting universal build settings that apply across all platforms
  - **Example**: `mulle-sde definition --global set CC "clang"`
  - **Side effects**: Creates/modifies `.mulle/etc/craft/definition/` instead of platform-specific subdirectories

- `--all`: operate across all defined scopes (global + all platform scopes)
  - **When to use**: When viewing or modifying definitions across all platforms simultaneously
  - **Example**: `mulle-sde definition --all list` (shows definitions for all platforms)
  - **Side effects**: May display duplicate keys with different values per platform

- `--platform <name>` / `--os <name>` / `--scope <name>`: target specific platform scope
  - **When to use**: When setting platform-specific compiler flags or build settings
  - **Valid scopes**: Any platform name (linux, darwin, windows, etc.)
  - **Example**: `mulle-sde definition --platform linux set CFLAGS "-DLINUX=1"`
  - **Side effects**: Creates/modifies `.mulle/etc/craft/definition.linux/` directory

- `--additive`: append to existing definition values instead of replacing (default: YES)
  - **When to use**: When adding flags without removing existing ones
  - **Example**: `mulle-sde definition --additive set CFLAGS "-Wall"` (adds -Wall to existing CFLAGS)
  - **Side effects**: Uses += operator in makefiles instead of =

- `--non-additive`: replace entire definition value (opposite of --additive)
  - **When to use**: When completely replacing build settings
  - **Example**: `mulle-sde definition --non-additive set CFLAGS "-O2 -g"`
  - **Side effects**: Replaces all existing flags for the specified key

- `--terse`: reduce output verbosity
  - **When to use**: When scripting or parsing output programmatically
  - **Example**: `mulle-sde definition --terse get CFLAGS`
  - **Side effects**: Removes informational messages and headers from output

### Environment Control
- `MULLE_MAKE`: override the mulle-make executable path
  - **Default**: `mulle-make`
  - **Set with**: `export MULLE_MAKE=/opt/mulle/bin/mulle-make`
  - **Use case**: When using custom mulle-make installations or debugging

- `MULLE_CRAFT`: override the mulle-craft executable path
  - **Default**: `mulle-craft`
  - **Set with**: `export MULLE_CRAFT=/opt/mulle/bin/mulle-craft`
  - **Use case**: When using custom craft implementations

- `MULLE_UNAME`: override platform detection
  - **Default**: Auto-detected platform name
  - **Set with**: `export MULLE_UNAME=myplatform`
  - **Use case**: When cross-compiling or simulating different platforms

- `MULLE_TECHNICAL_FLAGS`: pass additional flags to underlying tools
  - **Default**: empty
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="--debug --verbose"
  - **Use case**: Debugging mulle-make or mulle-craft behavior

- `MULLE_FLAG_LOG_TERSE`: control default verbosity
  - **Default**: empty (verbose)
  - **Set with**: `export MULLE_FLAG_LOG_TERSE=YES`
  - **Use case**: Making all mulle-sde commands less verbose by default

## Hidden Behaviors Explained

### Definition Resolution Order
When retrieving definitions, mulle-sde follows this precedence:
1. **User etc definitions** (`.mulle/etc/craft/definition[.platform]/`)
2. **Shared definitions** (`.mulle/share/craft/definition[.platform]/`)
3. **Global fallback** (if no platform-specific definition exists)

### Platform Scope Detection
- **Automatic scopes**: Based on `${MULLE_UNAME}` (linux, darwin, windows, etc.)
- **Custom scopes**: Any directory name matching `definition.*` pattern
- **Scope inheritance**: Platform-specific definitions inherit from global unless explicitly overridden

### Definition Storage Format
- **Location**: Key-value pairs in simple text files
- **Structure**: Each definition stored as individual file named after the key
- **Content**: Single line containing the definition value
- **Override mechanism**: User etc definitions completely replace shared definitions

### Automatic Directory Management
- **Creation**: Directories created automatically when first definition is set
- **Cleanup**: Empty directories removed automatically during unset operations
- **Protection**: Empty directories protected with `keep/README` files to prevent re-creation

### Cross-Platform Definition Synchronization
- **ALL scope**: When using `--all` with `set`, applies to global + all existing platform scopes
- **DEFAULT scope**: Uses current platform as primary, falls back to global
- **Platform detection**: Automatically creates platform-specific directories as needed

## Practical Examples

### Common Hidden Usage Patterns

#### Platform-Specific Compiler Flags
```bash
# Set different optimization levels per platform
mulle-sde definition --platform linux set CFLAGS "-O3 -march=native"
mulle-sde definition --platform darwin set CFLAGS "-O2 -arch x86_64 -arch arm64"
mulle-sde definition --platform windows set CFLAGS "-O2 -DWIN32_LEAN_AND_MEAN"

# Verify platform-specific settings
mulle-sde definition --platform linux get CFLAGS
mulle-sde definition --all list  # Show all platform definitions
```

#### Cross-Compilation Setup
```bash
# Configure for ARM cross-compilation on x86_64 Linux
export MULLE_UNAME=linux_arm
mulle-sde definition --platform linux_arm set CC "arm-linux-gnueabihf-gcc"
mulle-sde definition --platform linux_arm set CFLAGS "-march=armv7-a -mfpu=neon"

# Build setting for embedded target
mulle-sde definition --platform embedded set CFLAGS "-Os -ffunction-sections -fdata-sections"
mulle-sde definition --platform embedded set LDFLAGS "-Wl,--gc-sections"
```

#### Conditional Build Flags
```bash
# Add debug flags only for development builds
mulle-sde definition --additive set CFLAGS_DEBUG "-DDEBUG=1 -g3"

# Set preprocessor definitions for feature toggles
mulle-sde definition set FEATURE_X "-DENABLE_FEATURE_X=1"
mulle-sde definition set NO_DEPRECATED "-Wno-deprecated-declarations"
```

#### Build System Integration
```bash
# Configure CMake generator
mulle-sde definition set CMAKE_GENERATOR "Unix Makefiles"
mulle-sde definition --platform windows set CMAKE_GENERATOR "Visual Studio 16 2019"

# Set custom build directories
mulle-sde definition set BUILD_DIR "build/${MULLE_UNAME}"
mulle-sde definition set INSTALL_PREFIX "/opt/myproject"
```

### Environment Variable Overrides
```bash
# Use custom mulle-make for debugging
export MULLE_MAKE="mulle-make --debug"
mulle-sde definition list  # Will use debug-enabled mulle-make

# Cross-compilation environment
export MULLE_UNAME="raspberry"
mulle-sde definition set CC "arm-linux-gnueabihf-gcc"
mulle-sde definition set CXX "arm-linux-gnueabihf-g++"

# Verbose logging for troubleshooting
export MULLE_FLAG_LOG_TERSE=""
export MULLE_TECHNICAL_FLAGS="--verbose --debug"
mulle-sde definition --all list  # Shows detailed processing information
```

### Complex Multi-Platform Configuration
```bash
# Setup complete cross-platform build environment
# Global defaults
mulle-sde definition --global set CC "clang"
mulle-sde definition --global set CFLAGS "-Wall -Wextra"

# Platform-specific optimizations
mulle-sde definition --platform linux set CFLAGS "-O3 -march=native"
mulle-sde definition --platform darwin set CFLAGS "-O2 -arch x86_64 -arch arm64"
mulle-sde definition --platform windows set CC "cl"
mulle-sde definition --platform windows set CFLAGS "/O2 /W4"

# Verify configuration
mulle-sde definition --all list | grep -E "^(linux|darwin|windows|global)"
```

## Troubleshooting

### When to Use Hidden Options

#### Problem: Build flags not taking effect
**Solution**: Check scope precedence
```bash
# See what definitions are active
mulle-sde definition --all list

# Check if platform-specific definition is overriding global
mulle-sde definition --platform $(uname -s | tr '[:upper:]' '[:lower:]') get CFLAGS
mulle-sde definition --global get CFLAGS
```

#### Problem: Cross-compilation settings ignored
**Solution**: Use custom platform scope
```bash
# Create platform-specific scope for cross-compilation
export MULLE_UNAME="cross_arm"
mulle-sde definition --platform cross_arm set CC "arm-linux-gnueabihf-gcc"
```

#### Problem: Definitions mysteriously reappear after unset
**Solution**: Check shared vs. etc definitions
```bash
# See both shared and etc definitions
ls -la .mulle/share/craft/definition*/
ls -la .mulle/etc/craft/definition*/

# Force removal of shared definitions
mulle-sde definition --global remove
```

#### Problem: Platform detection issues
**Solution**: Override platform name
```bash
# Check current platform detection
echo "Current platform: $(uname -s | tr '[:upper:]' '[:lower:]')"
echo "MULLE_UNAME: ${MULLE_UNAME:-not set}"

# Override for testing
export MULLE_UNAME="linux_test"
mulle-sde definition --platform linux_test set CFLAGS "-DDEBUG=1"
```

### Integration Points

#### With `mulle-sde craft`
Definitions are automatically used during craft operations:
```bash
# Set custom compiler flags before building
mulle-sde definition set CFLAGS "-O3 -march=native"
mulle-sde craft  # Uses the custom CFLAGS
```

#### With `mulle-sde reflect`
Definitions influence reflect-generated build files:
```bash
# Set CMake-specific variables
mulle-sde definition set CMAKE_BUILD_TYPE "Release"
mulle-sde reflect  # Generates CMakeLists.txt with build type
```

#### With `mulle-sde dependency`
Dependency-specific definitions use craftinfo instead:
```bash
# For project-level definitions (use definition)
mulle-sde definition set CFLAGS "-O2"

# For dependency-specific definitions (use craftinfo)
mulle-sde dependency craftinfo zlib CFLAGS "-Os"
```

#### With `mulle-sde config`
Definitions work alongside configuration switching:
```bash
# Set definitions for specific configuration
mulle-sde config switch debug
mulle-sde definition set CFLAGS "-O0 -g3 -DDEBUG=1"

mulle-sde config switch release
mulle-sde definition set CFLAGS "-O3 -DNDEBUG=1"
```