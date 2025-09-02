# mulle-sde linkorder - Complete Reference

## Quick Start
Generate the correct linking order and flags for all project dependencies based on their dependency relationships and platform-specific requirements.

## All Available Options

### Basic Options (in usage)
```
--output-format <format>  : specify node,file,file_lf or ld, ld_lf
--output-omit <library>   : do not emit link commands for library
--startup                 : include startup libraries (default)
--no-startup              : exclude startup libraries
```

### Advanced Options (hidden)

#### Output Control
- **--output-format <format>**: Controls the output format for linking information
  - **When to use**: When integrating with different build systems or tools
  - **Available formats**:
    - `ld`: Standard linker arguments (space-separated, no trailing newline)
    - `ld_lf`: Linker arguments with line feeds
    - `file`: Just the library file paths
    - `file_lf`: File paths with line feeds
    - `node`: Dependency node names only
    - `csv`: Comma-separated values
    - `cmake`: CMake-compatible list (semicolon-separated)
    - `debug`: Debug information about dependency processing
  - **Example**: `mulle-sde linkorder --output-format cmake`
  - **Side effects**: Changes how downstream build systems must parse the output

- **--output-omit <library>**: Skip specific libraries from the link order
  - **When to use**: When you need to manually control which libraries are linked
  - **Example**: `mulle-sde linkorder --output-omit "zlib,openssl"`
  - **Side effects**: Libraries are completely excluded from output

#### Library Type Control
- **--preferred-library-style <style>**: Override the default library style preference
  - **When to use**: When you need to force a specific library type
  - **Available styles**: `static`, `dynamic`, `standalone`
  - **Example**: `mulle-sde linkorder --preferred-library-style static`
  - **Side effects**: Overrides platform defaults and project preferences

- **--dynamic**: Shorthand for `--preferred-library-style dynamic`
- **--static**: Shorthand for `--preferred-library-style static`
- **--standalone**: Shorthand for `--preferred-library-style standalone`

#### Startup Libraries
- **--startup**: Include startup libraries (default for executables)
  - **When to use**: When linking final executables
  - **Side effects**: Includes libraries marked with `no-intermediate-link`

- **--no-startup**: Exclude startup libraries (default for shared libraries)
  - **When to use**: When creating shared libraries or intermediate targets
  - **Side effects**: Filters out startup-only dependencies

#### Path and RPATH Control
- **--output-rpath**: Include RPATH flags in output (default: YES)
  - **When to use**: When creating relocatable binaries
  - **Side effects**: Adds `-Wl,-rpath,...` flags for library search paths

- **--output-no-rpath**: Exclude RPATH flags
  - **When to use**: When creating static binaries or system packages
  - **Side effects**: No runtime path information embedded

- **--output-ld-path**: Include library search paths (default: YES)
  - **When to use**: Default behavior for most builds
  - **Side effects**: Adds `-L` flags for library directories

- **--output-no-ld-path**: Exclude library search paths
  - **When to use**: When paths are handled elsewhere
  - **Side effects**: Only library names without paths

#### Processing Options
- **--reverse**: Reverse the dependency order
  - **When to use**: Rare, mainly for debugging dependency relationships
  - **Example**: `mulle-sde linkorder --reverse`
  - **Side effects**: Dependencies appear in reverse topological order

- **--no-reverse**: Maintain natural dependency order (default)

- **--simplify**: Simplify whole-archive flags (default: YES)
  - **When to use**: Reduces redundant whole-archive specifications
  - **Side effects**: More efficient linker command lines

- **--no-simplify**: Disable whole-archive optimization

- **--whole-archive-format <format>**: Control whole-archive flag format
  - **When to use**: Cross-platform builds with different toolchains
  - **Example**: `mulle-sde linkorder --whole-archive-format gcc`
  - **Side effects**: Changes how static libraries are handled

#### Configuration Control
- **--configuration <config>**: Use specific build configuration
  - **When to use**: Multi-configuration builds (Debug/Release)
  - **Example**: `mulle-sde linkorder --configuration Release`
  - **Side effects**: Uses different library search paths

- **--bequeath**: Include bequeathed dependencies
  - **When to use**: When working with complex project hierarchies
  - **Side effects**: Includes dependencies from parent projects

- **--no-bequeath**: Exclude bequeathed dependencies

#### Miscellaneous
- **--no-libraries**: Skip library file collection
  - **When to use**: When you only need dependency information
  - **Side effects**: Returns node names instead of file paths

- **--output-no-final-lf**: Suppress trailing newline
  - **When to use**: When output is captured by build systems
  - **Side effects**: Cleaner integration with some build tools

### Environment Control

#### Core Environment Variables
- **MULLE_CRAFT_CONFIGURATIONS**: Default configuration to use
  - **Default**: "Debug"
  - **Set with**: `export MULLE_CRAFT_CONFIGURATIONS=Release`
  - **Use case**: Setting project-wide default build configuration

- **MULLE_CRAFT_WHOLE_ARCHIVE_FORMAT**: Default whole-archive format
  - **Default**: Platform-specific (gcc, clang, msvc)
  - **Set with**: `export MULLE_CRAFT_WHOLE_ARCHIVE_FORMAT=gcc`
  - **Use case**: Cross-platform build scripts

- **MULLE_SOURCETREE_STASH_DIR**: Override stash directory location
  - **Default**: `.mulle-sourcetree`
  - **Set with**: `export MULLE_SOURCETREE_STASH_DIR=/custom/path`
  - **Use case**: Working with multiple project variants

#### Platform Integration Variables
- **MULLE_UNAME**: Override platform detection
  - **Default**: Auto-detected (linux, darwin, windows)
  - **Set with**: `export MULLE_UNAME=linux`
  - **Use case**: Cross-compilation scenarios

#### Technical Flags
- **MULLE_TECHNICAL_FLAGS**: Pass technical flags to underlying tools
  - **Default**: None
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="--verbose"
  - **Use case**: Debugging dependency resolution

## Hidden Behaviors Explained

### Dependency Resolution Algorithm

The linkorder command implements a sophisticated dependency resolution algorithm that handles:

1. **Topological Sorting**: Dependencies are ordered based on their relationship graph
2. **Circular Dependency Detection**: Automatically handles circular dependencies by prioritizing based on dependency depth
3. **Platform-specific Rules**: Different handling for static vs. dynamic libraries based on platform capabilities

### Library Location Strategy

The system searches for libraries in this exact order:

1. **Project-specific build directories**: `build/${configuration}/lib`
2. **Dependency build directories**: Each dependency's build output
3. **System library paths**: Platform-specific library locations
4. **Framework directories**: macOS-specific framework locations

### Mark-based Filtering

Different dependency marks affect linkorder behavior:

- **`no-intermediate-link`**: Excluded when `--no-startup` is used
- **`only-standalone`**: Treated as standalone libraries
- **`no-dynamic-link`**: Forces static linking
- **`no-static-link`**: Forces dynamic linking
- **`no-actual-link`**: Header-only libraries, excluded from linking
- **`no-dependency`**: OS libraries, handled specially

### Cross-platform Library Handling

- **Linux**: Prefers `.so` files but falls back to `.a`
- **macOS**: Supports both `.dylib` and `.a`, plus `.framework`
- **Windows**: Uses `.lib` and `.dll` with platform-specific naming

### Alias Resolution

When dependencies have aliases defined:

1. **Type-prefixed aliases**: `library:mylib` vs `framework:MyFramework`
2. **Version-specific aliases**: `mylib-1.0` vs `mylib-2.0`
3. **Platform-specific aliases**: Different names per platform

## Practical Examples

### Common Hidden Usage Patterns

#### Build System Integration
```bash
# CMake integration
set(MULLE_LINK_FLAGS "${shell mulle-sde linkorder --output-format cmake}")

# Makefile integration
LIBS := $(shell mulle-sde linkorder --output-format ld)
LDFLAGS := $(shell mulle-sde linkorder --output-format ld --output-no-rpath)

# Xcode integration
$(eval LINK_FLAGS := $(shell mulle-sde linkorder --output-format ld --preferred-library-style static))
```

#### Cross-compilation Scenarios
```bash
# Targeting different architectures
export MULLE_UNAME=darwin
mulle-sde linkorder --output-format ld --configuration Release

# Creating static-only builds
mulle-sde linkorder --preferred-library-style static --output-no-rpath

# Framework builds on macOS
mulle-sde linkorder --output-format ld --preferred-library-style dynamic
```

#### Debugging Dependency Issues
```bash
# See what dependencies are being processed
mulle-sde linkorder --output-format debug

# Check library search paths
mulle-sde linkorder --output-format ld --output-no-ld-path | tr ' ' '\n' | grep "^-L"

# Verify specific library exclusion
mulle-sde linkorder --output-omit "problematic-lib" --output-format ld
```

#### Complex Project Scenarios
```bash
# Multi-configuration setup
Debug: mulle-sde linkorder --configuration Debug
Release: mulle-sde linkorder --configuration Release

# Excluding system libraries for static builds
mulle-sde linkorder --output-omit "m,pthread,dl" --preferred-library-style static

# Custom framework builds
mulle-sde linkorder --output-format cmake --preferred-library-style dynamic --output-rpath
```

### Environment Variable Overrides

#### Project-specific Settings
```bash
# Set project-wide defaults
cat > .mulle/etc/env/environment.sh << EOF
export MULLE_CRAFT_CONFIGURATIONS="Release"
export MULLE_CRAFT_WHOLE_ARCHIVE_FORMAT="gcc"
EOF

# Override for specific builds
MULLE_CRAFT_CONFIGURATIONS=Debug mulle-sde linkorder
```

#### Cross-platform Build Scripts
```bash
#!/bin/bash
case "$(uname)" in
  Darwin)
    export MULLE_UNAME="darwin"
    export MULLE_CRAFT_WHOLE_ARCHIVE_FORMAT="clang"
    ;;
  Linux)
    export MULLE_UNAME="linux"
    export MULLE_CRAFT_WHOLE_ARCHIVE_FORMAT="gcc"
    ;;
esac

mulle-sde linkorder --output-format ld
```

## Troubleshooting

### Common Issues and Solutions

#### "Library not found" errors
```bash
# Check if dependencies are built
mulle-sde craft

# Verify library search paths
mulle-sde linkorder --output-format ld --output-ld-path

# Check specific library location
mulle-sde linkorder --output-format debug | grep "missing-library"
```

#### Link order issues with circular dependencies
```bash
# Use debug output to understand the resolution
mulle-sde linkorder --output-format debug > debug.txt

# Manually adjust with output-omit for problematic cases
mulle-sde linkorder --output-omit "circular-dep1,circular-dep2"
```

#### Cross-compilation library mismatches
```bash
# Verify platform detection
echo "Platform: $MULLE_UNAME"

# Check library style preference
mulle-sde linkorder --preferred-library-style static --output-format debug

# Validate search paths
mulle-sde linkorder --output-ld-path --configuration Release
```

### Integration with Other Commands

#### Workflow Integration
```bash
# Complete build and link workflow
mulle-sde reflect    # Update build files
mulle-sde craft      # Build all dependencies
mulle-sde linkorder  # Get final link flags
```

#### Testing Integration
```bash
# Get link flags for test executables
mulle-sde test linkorder --output-format ld --startup

# Debug test linking issues
mulle-sde test linkorder --output-format debug
```

#### Installation Integration
```bash
# Get link flags after installation
mulle-sde install --linkorder --prefix /usr/local
```

### Performance Optimization

#### Faster Linkorder Generation
```bash
# Skip library validation for faster results
mulle-sde linkorder --output-format ld --no-libraries

# Use cached results where possible
export MULLE_TECHNICAL_FLAGS="--cache"
```

#### Memory Usage
```bash
# Reduce memory for large projects
mulle-sde linkorder --bequeath --output-format ld
```

## Integration Points

### Related Commands
- **mulle-sde dependency**: Manages the dependency tree that linkorder processes
- **mulle-sde craft**: Builds libraries that linkorder locates
- **mulle-sde reflect**: Updates build configurations that affect linking
- **mulle-sde library**: Manages library-specific settings used by linkorder
- **mulle-sde craftorder**: Determines build order (inverse of linkorder)

### Build System Templates
The linkorder command works with craftinfo templates to provide platform-specific linking behavior, ensuring consistent cross-platform builds.