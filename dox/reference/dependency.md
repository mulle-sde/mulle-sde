# mulle-sde dependency - Complete Reference

## Quick Start
Manage project dependencies including third-party libraries, frameworks, and remote source files. Handles fetching, building, and integrating dependencies into your C/C++/Objective-C project.

## All Available Options

### Basic Options (in usage)
- `add`: Add a dependency to the sourcetree
- `binaries`: List all binaries in the built dependencies folder
- `duplicate`: Duplicate a dependency for OS-specific settings
- `craftinfo`: Change build options for a dependency
- `etcs`: List all etc files in the built dependencies folder
- `export`: Export dependency as script command
- `fetch`: Fetch dependencies (same as `mulle-sde fetch`)
- `get`: Retrieve dependency settings from the sourcetree
- `headers`: List all headers in the built dependencies folder
- `libraries`: List all libraries in the built dependencies folder
- `list`: List dependencies in the sourcetree (default)
- `mark`: Add marks to a dependency in the sourcetree
- `move`: Reorder dependencies in the sourcetree
- `rcopy`: Copy dependency from another project with sourcetree
- `remove`: Remove a dependency from the sourcetree
- `set`: Change dependency settings in the sourcetree
- `shares`: List all share files in the built dependencies folder
- `stashes`: List downloaded dependencies
- `source-dir`: Find the source location of a dependency
- `unmark`: Remove marks from a dependency in the sourcetree

### Advanced Options (hidden)

#### Dependency Type Detection
- **Automatic dialect detection**: When no `--c` or `--objc` flag is provided, the system automatically detects the dependency type based on naming conventions:
  - Names starting with uppercase letters → Objective-C
  - Names with underscores or lowercase → C
  - Names containing "StartUp" or "-Startup" → Startup libraries

#### URL Enhancement System
- **Environment variable substitution**: URLs are automatically enhanced with environment variables for flexible versioning:
  - `${PROJECTNAME_URL}`: Base URL override
  - `${PROJECTNAME_TAG}`: Version/tag override  
  - `${PROJECTNAME_BRANCH}`: Branch override
  - `${PROJECTNAME_NODETYPE}`: SCM type override

#### Hidden Mark Categories
**C-specific marks** (auto-applied with `--c`):
- `no-import`: Uses `#include` instead of `#import`
- `no-all-load`: Enables cherry-picked symbol loading
- `no-cmake-loader`: Disables ObjC loader for C code
- `no-cmake-searchpath`: Prevents header flattening
- `singlephase`: Assumes old-fashioned C build process

**Objective-C-specific marks** (auto-applied with `--objc`):
- `no-singlephase`: Assumes mulle-objc compatibility

**Framework-specific marks** (auto-applied with `--framework`):
- `singlephase`: Frameworks can't do multiphase builds
- `no-cmake-add`: No framework info needed
- `no-cmake-all-load`: Can't force-load frameworks
- `no-cmake-inherit`: Framework linking isolation
- `only-framework`: Marks as macOS framework

**Embedded dependency marks** (auto-applied with `--embedded`):
- `no-build`: Skip building
- `no-header`: No header processing
- `no-link`: No library linking
- `no-share`: No shared resources
- `cmake-inherit`: CMake configuration inheritance
- `cmake-searchpath`: CMake search path setup

#### Special URL Patterns
- **Local project detection**: Single argument without URL assumes local project in `MULLE_FETCH_SEARCH_PATH`
- **GitHub shorthand**: `--github user/repo` expands to full GitHub URL
- **clib projects**: `clib:user/repo` automatically sets embedded mode
- **Version templating**: URLs with `${MULLE_TAG}` get automatic substitution

### Environment Control

#### Core Environment Variables
- `MULLE_FETCH_SEARCH_PATH`: Colon-separated paths for local project discovery
  - **Default**: Current directory and parent directories
  - **Set with**: `export MULLE_FETCH_SEARCH_PATH="/path1:/path2"`
  - **Use case**: Local development with sister projects

- `MULLE_USERNAME`: Default username for GitHub/GitLab shorthand URLs
  - **Default**: System username
  - **Set with**: `export MULLE_USERNAME="mygithubuser"`
  - **Use case**: Consistent GitHub project references

- `MULLE_SOURCETREE_TO_C_INCLUDE_FILE`: Controls automatic header inclusion
  - **Default**: ON
  - **Set with**: `export MULLE_SOURCETREE_TO_C_INCLUDE_FILE=OFF`
  - **Use case**: Disable automatic header generation

- `MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE`: Controls private header inclusion
  - **Default**: ON
  - **Set with**: `export MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE=OFF`
  - **Use case**: Prevent private headers from being exposed

#### Project-specific Variables
- `${PROJECTNAME}_URL`: Override dependency URL
- `${PROJECTNAME}_TAG`: Override dependency tag/version
- `${PROJECTNAME}_BRANCH`: Override dependency branch
- `${PROJECTNAME}_NODETYPE`: Override SCM type (git/tar/zip)

## Hidden Behaviors Explained

### Automatic URL Construction

#### GitHub Projects
```bash
# Automatic expansion
mulle-sde dependency add zlib
# Becomes: https://github.com/${MULLE_USERNAME}/zlib/archive/latest.tar.gz

# With specific user
mulle-sde dependency add --github madler zlib
# Becomes: https://github.com/madler/zlib/archive/latest.tar.gz
```

#### Domain Shorthand System
```bash
# GitLab shorthand
mulle-sde dependency add --gitlab user/repo
# Bitbucket shorthand  
mulle-sde dependency add --bitbucket user/repo

# Generic domain handling
mulle-sde dependency add --domain gitlab --user myuser --repo myproject
```

### Mark Inheritance System

#### Automatic Mark Application
When adding dependencies, marks are automatically applied based on:
1. **Dialect detection** (C vs Objective-C)
2. **Naming patterns** (startup libraries)
3. **URL type** (framework vs library)
4. **Build configuration** (embedded vs external)

#### Mark Composition Rules
```bash
# Startup library detection
mulle-sde dependency add MyStartup
# Automatically adds: all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header,no-cmake-inherit

# Embedded source
mulle-sde dependency add --embedded --address src/vendor \
  --marks "no-clobber,no-share-shirk" \
  clib:user/project
```

### Version Flexibility System

#### Environment-based Versioning
```bash
# Flexible version control
export ZLIB_TAG=1.2.11
mulle-sde dependency add 'https://zlib.net/zlib-${ZLIB_TAG}.tar.gz'

# Branch switching
export OPENSSL_BRANCH=OpenSSL_1_1_1-stable
mulle-sde dependency add --branch ${OPENSSL_BRANCH} openssl
```

#### Latest Version Detection
```bash
# Automatic latest version detection
mulle-sde dependency add --latest openssl
# Queries remote repository for latest tag
```

### Local Project Integration

#### Sister Project Discovery
```bash
# With MULLE_FETCH_SEARCH_PATH="/home/user/projects"
cd /home/user/projects/myproject
mulle-sde dependency add sisterproject
# Discovers ../sisterproject and creates symlink dependency
```

#### File-based Dependencies
```bash
# Local file dependencies
mulle-sde dependency add file:///path/to/local/project
# Creates symlink-based dependency without fetching
```

## Practical Examples

### Common Hidden Usage Patterns

#### Advanced Dependency Configuration
```bash
# Add with specific build flags
mulle-sde dependency add --marks "singlephase,no-cmake-loader" \
  --fetchoptions "--depth=1" \
  https://github.com/user/project.git

# Add embedded clib with custom address
mulle-sde dependency add --embedded --address src/vendor \
  --marks "no-clobber,no-share-shirk" \
  clib:user/project
```

#### Platform-specific Dependencies
```bash
# Add dependency excluding specific platforms
mulle-sde dependency add --marks "platform-excludes:windows" \
  https://github.com/unix-only/project.git

# Set platform exclusions after adding
mulle-sde dependency set libfoo platform-excludes "windows,android"
```

#### Private Dependencies
```bash
# Add private dependency (headers not exposed)
mulle-sde dependency add --private internal-lib
# Equivalent to: --marks "no-public"

# Check private status
mulle-sde dependency get internal-lib marks | grep -q "no-public"
```

### Environment Variable Overrides

#### Development Overrides
```bash
# Override all GitHub URLs for local development
export GITHUB_USERNAME=myfork
export GITHUB_DOMAIN=github.enterprise.com

# Version pinning across project
export ZLIB_TAG=1.2.11
export OPENSSL_TAG=1.1.1w

# Branch-based development
export FEATURE_BRANCH=experimental
mulle-sde dependency add --branch ${FEATURE_BRANCH} myproject
```

#### Cross-compilation Setup
```bash
# Target-specific dependencies
export MULLE_FETCH_SEARCH_PATH="/opt/cross-deps/arm64:/opt/cross-deps/x86_64"

# Platform-specific URLs
export MULLE_PLATFORM=ios
mulle-sde dependency add --domain ios-framework UIKit
```

### Complex URL Patterns

#### Archive with Version Substitution
```bash
# PostgreSQL with flexible versioning
mulle-sde dependency add \
  --c \
  --address postgres \
  --tag 11.2 \
  --marks singlephase \
  'https://ftp.postgresql.org/pub/source/v${POSTGRES_TAG}/postgresql-${POSTGRES_TAG}.tar.bz2'

# Override version via environment
export POSTGRES_TAG=12.1
```

#### Git with Custom Configuration
```bash
# Shallow clone with specific branch
mulle-sde dependency add \
  --branch develop \
  --fetchoptions "--depth 1 --single-branch" \
  https://github.com/user/project.git
```

## Troubleshooting

### When to Use Hidden Options

#### Dependency Resolution Issues
```bash
# Library not found during linking
mulle-sde dependency set mylib aliases "mylib,mylib2,libmylib"

# Header not found during compilation
mulle-sde dependency set mylib include "mylib/mylib.h"

# Platform-specific linking
mulle-sde dependency set mylib platform-excludes "windows"
```

#### Build System Conflicts
```bash
# CMake conflicts with Objective-C frameworks
mulle-sde dependency add --framework --marks "no-cmake-add,no-cmake-inherit" \
  /System/Library/Frameworks/Foundation.framework

# C libraries in Objective-C projects
mulle-sde dependency add --c --marks "no-import,no-cmake-loader" \
  https://github.com/c-library/zlib.git
```

#### Embedded Source Management
```bash
# Prevent clobbering during updates
mulle-sde dependency add --embedded --marks "no-clobber,no-share-shirk" \
  --address src/vendor/mylib \
  https://github.com/user/mylib.git

# Exclude from build system
mulle-sde dependency add --embedded --marks "no-build,no-link,no-header" \
  src/data-only-assets
```

### Debugging Unexpected Behavior

#### Verbose Dependency Analysis
```bash
# List detailed information
mulle-sde dependency list --json --raw

# Check specific dependency settings
mulle-sde dependency get zlib aliases
mulle-sde dependency get zlib include

# Export dependency configuration
mulle-sde dependency export zlib
```

#### Environment Variable Inspection
```bash
# Check active environment variables
env | grep -E "(MULLE_|PROJECT_)" | sort

# Test URL resolution
mulle-sde dependency add --dry-run --plain https://github.com/user/project.git
```

#### Mark Analysis
```bash
# List all marks for a dependency
mulle-sourcetree get myproject marks

# Add/remove specific marks
mulle-sde dependency mark myproject singlephase
mulle-sde dependency unmark myproject no-singlephase
```

### Cross-Platform Considerations

#### macOS Framework Handling
```bash
# Proper framework dependency setup
mulle-sde dependency add --framework \
  --marks "singlephase,no-cmake-all-load,no-cmake-inherit,only-framework" \
  /System/Library/Frameworks/CoreFoundation.framework
```

#### Windows-specific Configuration
```bash
# Handle Windows library naming
mulle-sde dependency set mylib aliases "mylib,mylib.dll,libmylib"

# Exclude Windows-specific dependencies on Unix
mulle-sde dependency add --marks "platform-excludes:windows,linux,bsd" \
  windows-specific-lib
```
