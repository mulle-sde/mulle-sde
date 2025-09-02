# mulle-sde steal - Complete Reference

## Quick Start
Download and flatten source code from mulle-c compatible repositories into a single directory with automatically generated include headers.

```bash
# Steal source files from a GitHub repository
mulle-sde steal github:mulle-c/mulle-container

# Steal to a specific directory
mulle-sde steal -d vendor/mulle-container github:mulle-c/mulle-container
```

## All Available Options

### Basic Options (in usage)
- `-d <dir>`: Change destination directory (defaults to current working directory)
- `-h, --help, help`: Show usage information

### Advanced Options (hidden)
- `--keep-tmp`: Preserve temporary working directory for debugging
  - **When to use**: When steal fails or you want to inspect fetched sources
  - **Example**: `mulle-sde steal --keep-tmp github:mulle-c/mulle-container`
  - **Side effects**: Temporary directory remains at system tmp location (usually `/tmp/steal-XXXXXX`)

### Environment Control
- `MULLE_SOURCETREE`: Path to mulle-sourcetree executable
  - **Default**: Uses `command -v mulle-sourcetree` to find in PATH
  - **Set with**: `export MULLE_SOURCETREE=/usr/local/bin/mulle-sourcetree`
  - **Use case**: When mulle-sourcetree is installed in non-standard location

- `MULLE_SOURCETREE_STASH_DIRNAME`: Directory name for source tree stash
  - **Default**: `stash`
  - **Set with**: `export MULLE_SOURCETREE_STASH_DIRNAME=my-stash`
  - **Use case**: When working with custom source tree configurations

- `MULLE_TECHNICAL_FLAGS`: Technical flags passed to mulle-sourcetree
  - **Default**: None (empty)
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="--verbose --dry-run"`
  - **Use case**: Debugging mulle-sourcetree operations

## Hidden Behaviors Explained

### Source File Selection & Filtering
When stealing source files, the command applies sophisticated filtering to extract only relevant source files:

**File Type Filtering**:
- **Included**: `.c`, `.m`, `.h`, `.inc`, `.aam` files
- **Excluded**: Test files (`*-test.c`, `*-test.h`, `*-test.inc`, `*-test.aam`)
- **Excluded**: Standalone files (`*-standalone.c`, `*-standalone.m`)
- **Excluded**: Configuration files (anything in `.*/\.[a-z]/.*`)

**Directory Filtering**:
- **Excluded**: Any directory containing `main.c` or `main.m` (assumed to be test/demo projects)
- **Excluded**: `.git`, `.mulle`, and other hidden directories
- **Only from**: `*/src/` directories within fetched repositories

**Header File Processing**:
- **Excluded**: Individual `include.h` and `include-private.h` files
- **Generated**: Unified `include.h` and `include-private.h` files that aggregate all headers

### Cross-Platform Compatibility
The steal command works across platforms but has specific behaviors:

**Path Handling**:
- Uses `find` command with POSIX-compliant options
- Handles both Unix (`/`) and Windows (`\`) path separators
- Preserves file permissions using `cp -p -n` (no-clobber copy)

**Temporary Directory Management**:
- Creates platform-appropriate temporary directories
- Uses `r_make_tmp` function for cross-platform tmp directory creation
- Automatically cleans up unless `--keep-tmp` is specified

### Repository URL Processing
The command accepts various URL formats through mulle-sourcetree:

**Supported URL Patterns**:
- `github:user/repo` - GitHub shorthand
- `github:user/repo.tar` - GitHub tarball
- Full git URLs: `https://github.com/user/repo.git`
- Local paths: `/path/to/repository`
- Mulle-c specific URLs: `mulle-c:container`

**Repository Structure Expectations**:
- Expects standard mulle-c project structure with `src/` directory
- Works best with projects that have `include.h` and `include-private.h` headers
- Handles multiple repositories in a single steal operation

### Header Generation Process
The command automatically generates unified header files:

**include.h Creation**:
- Collects all `_*-include.h` files from stolen sources
- Creates `#include "_dependency-include.h"` directives
- Uses project directory name as include guard identifier

**include-private.h Creation**:
- Collects all `_*-include-private.h` files from stolen sources
- Creates `#include "_dependency-include-private.h"` directives
- Follows same naming convention as public headers

## Practical Examples

### Common Hidden Usage Patterns

#### Debugging Failed Steals
```bash
# Keep temporary directory to debug fetch issues
mulle-sde steal --keep-tmp github:mulle-c/mulle-container
echo "Check /tmp/steal-* for fetched repositories"

# Use verbose sourcetree operations
MULLE_TECHNICAL_FLAGS="--verbose" mulle-sde steal github:mulle-c/mulle-container
```

#### Custom Destination Layout
```bash
# Steal to vendor directory
mulle-sde steal -d vendor/mulle-container github:mulle-c/mulle-container

# Steal to system include directory (requires permissions)
sudo mulle-sde steal -d /usr/local/include/mulle-container github:mulle-c/mulle-container
```

#### Multiple Repository Stealing
```bash
# Steal multiple dependencies at once
mulle-sde steal \
  github:mulle-c/mulle-container \
  github:mulle-c/mulle-data \
  github:mulle-c/mulle-thread
```

#### Integration with Build Systems
```bash
# Steal sources and integrate with CMake project
mkdir -p third_party
mulle-sde steal -d third_party/mulle-container github:mulle-c/mulle-container

# Then in CMakeLists.txt
add_subdirectory(third_party/mulle-container)
target_link_libraries(your_target mulle-container)
```

### Environment Variable Overrides

#### Non-standard Tool Locations
```bash
# When mulle-sourcetree is not in PATH
export MULLE_SOURCETREE=/opt/mulle/bin/mulle-sourcetree
mulle-sde steal github:mulle-c/mulle-container

# Custom stash directory for large projects
export MULLE_SOURCETREE_STASH_DIRNAME=dependencies
mulle-sde steal github:mulle-c/mulle-container
```

#### Debugging Source Tree Operations
```bash
# Debug sourcetree operations in detail
export MULLE_TECHNICAL_FLAGS="--verbose --trace"
mulle-sde steal github:mulle-c/mulle-container
```

## Troubleshooting

### When to Use Hidden Options

#### Steal Fails with "No mulle-sourcetree found"
```bash
# Check if mulle-sourcetree is installed
which mulle-sourcetree

# If not in PATH, specify location
export MULLE_SOURCETREE=/usr/local/bin/mulle-sourcetree
mulle-sde steal github:mulle-c/mulle-container
```

#### Permission Denied During Copy
```bash
# Use sudo if stealing to system directories
sudo mulle-sde steal -d /usr/local/include/ github:mulle-c/mulle-container

# Or use user-writable directory
mulle-sde steal -d ~/include/ github:mulle-c/mulle-container
```

#### Missing Source Files After Steal
```bash
# Check what was actually fetched
mulle-sde steal --keep-tmp github:mulle-c/mulle-container
ls -la /tmp/steal-*/stash/*/src/

# Verify expected file extensions are present
find /tmp/steal-*/stash/*/src/ -name "*.[chm]" -o -name "*.inc" -o -name "*.aam"
```

#### Generated Headers Missing Dependencies
```bash
# Check if individual include files exist
ls -la _*-include.h _*-include-private.h

# Manual header creation if needed
sde::steal::create_include "PROJECT_NAME" > include.h
sde::steal::create_include_private "PROJECT_NAME" > include-private.h
```

### Integration Issues

#### CMake Integration Problems
```bash
# After stealing, ensure CMakeLists.txt exists
mulle-sde steal -d vendor/mulle-container github:mulle-c/mulle-container
cd vendor/mulle-container

# If no CMakeLists.txt, create one or use add_custom_target()
```

#### Duplicate Symbol Errors
```bash
# Steal uses no-clobber copy, but check for conflicts
mulle-sde steal --keep-tmp github:mulle-c/mulle-container
diff /tmp/steal-*/stash/*/src/ ./

# Remove conflicting files if necessary
rm conflicting-file.c
mulle-sde steal github:mulle-c/mulle-container
```

## Migration Path from steal

### Obsolescence Notice
The `steal` command is marked as **obsoleted by clib.json** in its usage text. Consider migrating to:

1. **clib.json**: Modern dependency management system
2. **mulle-sourcetree**: Direct usage for more control
3. **mulle-sde dependency**: Standard dependency management

### Migration Example
```bash
# Instead of steal
mulle-sde steal github:mulle-c/mulle-container

# Use dependency management
mulle-sde dependency add github:mulle-c/mulle-container
mulle-sde craft
```

### Legacy Support
Despite being marked obsolete, `steal` remains functional for:
- Quick prototyping and experimentation
- Legacy project maintenance
- Situations where flattened source layout is preferred
- Projects not yet migrated to clib.json system