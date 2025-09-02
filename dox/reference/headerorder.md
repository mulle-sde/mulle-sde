# mulle-sde headerorder - Complete Reference

## Quick Start
Generate ordered include statements for C/C++ dependencies based on their build configuration and dependency relationships.

## All Available Options

### Basic Options (in usage)
```
--recurse                 : print recursive headers
--output-format <format>  : specify c or objc
--output-omit <library>   : do not emit include commands for library
```

### Advanced Options (hidden)

#### Configuration Control
- **-c, --configuration <config>**
  - **What it does**: Specify build configuration (Debug, Release, etc.)
  - **When to use**: When you need headers for a specific build configuration
  - **Default**: Uses `MULLE_CRAFT_CONFIGURATIONS` or "Debug"
  - **Example**: `mulle-sde headerorder --configuration Release`

#### Hidden Recursion Options
- **--recursive**
  - **What it does**: Include all transitive dependencies (full dependency tree)
  - **When to use**: When you need to see the complete include order including indirect dependencies
  - **Default**: Disabled (--flat)
  - **Example**: `mulle-sde headerorder --recursive --output-format c`

- **--no-recursive**
  - **What it does**: Explicitly disable recursion (flat mode)
  - **When to use**: When you only want direct dependencies
  - **Example**: `mulle-sde headerorder --no-recursive`

#### Hidden Bequeath Options
- **--bequeath**
  - **What it does**: Include dependencies from parent/source projects
  - **When to use**: When working with project hierarchies or umbrella projects
  - **Default**: Disabled
  - **Example**: `mulle-sde headerorder --bequeath --output-format c`

- **--no-bequeath**
  - **What it does**: Exclude dependencies from parent/source projects
  - **When to use**: When you want only local project dependencies
  - **Example**: `mulle-sde headerorder --no-bequeath`

#### Hidden Reverse Options
- **--reverse**
  - **What it does**: Reverse the final header order
  - **When to use**: When you need reverse dependency order for specific build scenarios
  - **Default**: Disabled
  - **Example**: `mulle-sde headerorder --reverse --output-format c`

- **--no-reverse**
  - **What it does**: Explicitly disable reverse order
  - **When to use**: When you want to ensure standard dependency order
  - **Example**: `mulle-sde headerorder --no-reverse`

#### Additional Output Formats
- **--output-format csv**
  - **What it does**: Output raw dependency data in CSV format (address;marks;include;headerpath)
  - **When to use**: For parsing by external tools or debugging
  - **Example**: `mulle-sde headerorder --output-format csv`

#### Debug Mode
- **--output-format debug**
  - **What it does**: Output raw node data before processing
  - **When to use**: For debugging dependency resolution issues
  - **Example**: `mulle-sde headerorder --output-format debug`

### Environment Variables

#### Build Configuration
- **MULLE_CRAFT_CONFIGURATIONS**
  - **What it controls**: Default build configuration(s)
  - **Default**: "Debug"
  - **Set with**: `export MULLE_CRAFT_CONFIGURATIONS="Release,Debug"`
  - **Use case**: When working with multiple build configurations

#### Platform Detection
- **MULLE_UNAME**
  - **What it controls**: Platform-specific behavior for requirements
  - **Default**: Auto-detected platform name
  - **Set with**: `export MULLE_UNAME="linux"`
  - **Use case**: Cross-compilation scenarios

#### Technical Flags
- **MULLE_TECHNICAL_FLAGS**
  - **What it controls**: Technical flags passed to mulle-craft
  - **Default**: Empty
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="--verbose"`
  - **Use case**: Debugging craft system interactions

#### Directory Configuration
- **MULLE_SOURCETREE_STASH_DIRNAME**
  - **What it controls**: Source tree stash directory name
  - **Default**: ".mulle-sourcetree"
  - **Set with**: `export MULLE_SOURCETREE_STASH_DIRNAME=".custom-stash"`
  - **Use case**: Custom directory structures

- **OPTION_SHAREDIR**
  - **What it controls**: Share directory for environment setup
  - **Default**: Platform-specific
  - **Set with**: `export OPTION_SHAREDIR="/usr/local/share"`
  - **Use case**: Custom installation directories

## Hidden Behaviors Explained

### Marks-Based Filtering

The headerorder system respects various marks that control inclusion behavior:

#### Header Inclusion Marks
- **no-header**: Completely skip this dependency for header inclusion
  - **Example**: A library that provides only runtime functionality, no headers
  - **Effect**: Dependency will be built but not included in header order

#### Requirement Marks
- **no-require**: Skip missing headers without error
  - **Example**: Optional system dependencies that may not be present
  - **Effect**: Dependency will be silently skipped if headers not found

- **no-require-os-{platform}**: Platform-specific requirement skip
  - **Example**: `no-require-os-linux` skips on Linux but requires on macOS
  - **Effect**: Conditional requirement based on target platform

#### Dependency Marks
- **no-dependency**: Skip dependency checking for headers
  - **Example**: System headers that don't need explicit dependency tracking
  - **Effect**: Missing headers won't trigger build errors

#### Load Marks
- **no-all-load**: Force #include instead of #import for Objective-C
  - **Example**: When you need C-style inclusion for Objective-C compatibility
  - **Effect**: Changes Objective-C output from #import to #include

### Search Path Resolution

The system uses multiple search path sources:

1. **Header Search Path**: `mulle-craft searchpath header`
2. **Library Search Path**: `mulle-craft searchpath library`
3. **Framework Search Path**: `mulle-craft searchpath framework`

Each path is configuration-specific and may be empty if dependencies haven't been built.

### Header Location Algorithm

1. **Primary Search**: Look for `{name}/{name}.h` in header search path
2. **Custom Include**: Use user-specified include path from sourcetree node
3. **Validation**: Check if header exists before inclusion
4. **Fallback**: Handle missing headers based on marks

### Output Format Differences

#### C Format (`--output-format c`)
- Uses `#include <header.h>` syntax
- Appropriate for C/C++ projects
- Includes `-isystem` flags for compiler

#### Objective-C Format (`--output-format objc`)
- Uses `#import <header.h>` syntax by default
- Falls back to `#include` for specific marks
- Appropriate for Objective-C/C++ projects

#### CSV Format (`--output-format csv`)
- Raw data format: `address;marks;include;headerpath`
- Useful for external tool integration
- Includes complete dependency metadata

## Practical Examples

### Common Hidden Usage Patterns

#### Debug Dependency Resolution
```bash
# See raw dependency data
mulle-sde headerorder --output-format debug

# Get CSV output for external processing
mulle-sde headerorder --output-format csv > headers.csv
```

#### Cross-Platform Development
```bash
# Get headers for release build
mulle-sde headerorder --configuration Release --output-format c

# Exclude system dependencies
mulle-sde headerorder --output-omit "zlib,openssl" --output-format c
```

#### Project Hierarchy Management
```bash
# Include parent project dependencies
mulle-sde headerorder --bequeath --recursive --output-format c

# Only local dependencies
mulle-sde headerorder --no-bequeath --no-recursive --output-format c
```

#### Reverse Dependency Order
```bash
# Get reverse dependency order for cleanup scripts
mulle-sde headerorder --reverse --output-format c

# Combine with exclusion
mulle-sde headerorder --reverse --output-omit "test-framework" --output-format c
```

### Environment Variable Overrides

#### Custom Build Configuration
```bash
# Set custom configuration
export MULLE_CRAFT_CONFIGURATIONS="CustomConfig"
mulle-sde headerorder --output-format c

# Override for specific platform
export MULLE_UNAME="darwin"
mulle-sde headerorder --output-format c
```

#### Debug Craft System
```bash
# Enable verbose craft output
export MULLE_TECHNICAL_FLAGS="--verbose"
mulle-sde headerorder --output-format c

# Custom stash directory
export MULLE_SOURCETREE_STASH_DIRNAME=".my-stash"
mulle-sde headerorder --output-format c
```

## Troubleshooting

### When to Use Hidden Options

#### "Headers not found" errors
```bash
# Check if dependencies are built for the right configuration
mulle-sde headerorder --configuration Debug --output-format debug

# Skip problematic dependencies
mulle-sde headerorder --output-omit "missing-lib" --output-format c
```

#### Cross-compilation issues
```bash
# Force specific platform behavior
export MULLE_UNAME="linux"
mulle-sde headerorder --configuration Release --output-format c
```

#### Project structure problems
```bash
# Include parent dependencies when working in subproject
mulle-sde headerorder --bequeath --output-format c

# Exclude parent dependencies for isolation
mulle-sde headerorder --no-bequeath --output-format c
```

### Debugging Steps

1. **Check configuration**: Ensure dependencies are built for the target configuration
2. **Verify search paths**: Use `--output-format debug` to see search paths
3. **Check marks**: Review dependency marks for filtering behavior
4. **Test specific dependencies**: Use `--output-omit` to isolate problematic ones

### Common Error Solutions

- **Empty searchpath**: Run `mulle-sde craft` to build dependencies
- **Missing headers**: Check if dependency has `no-header` mark
- **Wrong order**: Use `--reverse` to check reverse dependency relationships
- **Platform issues**: Set `MULLE_UNAME` for cross-compilation scenarios