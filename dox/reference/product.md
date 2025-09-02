# mulle-sde product - Complete Reference

## Quick Start
Locate and manage build products (executables, libraries) created by `mulle-sde craft`, with support for multi-product projects, cross-platform executables, and flexible discovery mechanisms.

## All Available Options

### Basic Options (in usage)
```
list                : list built products
symlink             : symlink current product into ~/bin (deprecated, use mulle-sde symlink)
searchpath          : show product search paths
-h                  : show help
--configuration <c> : set build configuration (Debug/Release)
--debug              : shortcut for --configuration Debug
--release            : shortcut for --configuration Release
--restrict           : run with restricted environment
--sdk <sdk>          : set target SDK
```

### Advanced Options (hidden)
```
--if-exists          : only proceed if product exists (no auto-build)
--select             : enable interactive selection for multiple executables
--name <name>        : specify product name to target specific executable
--no-run-env         : disable mulle-sde environment setup for run operations
--1, -first-only    : return only the most recently modified product

# Product type arguments for searchpath:
binary               : search for executables
library              : search for static/dynamic libraries
```

### Environment Variables
```
- PROJECT_TYPE: determines product type (executable/library/none)
- PROJECT_NAME: base name for product discovery
- MULLE_EXE_EXTENSION: platform-specific executable extension (.exe on Windows)
- MULLE_USER_PWD: current working directory for relative paths
- MULLE_VIRTUAL_ROOT: mulle-sde project root directory
- MULLE_CRAFT_SDKS: default SDKs for cross-compilation
- MULLE_TECHNICAL_FLAGS: additional craft flags
```

## Hidden Behaviors Explained

### Sophisticated Product Discovery

#### Multi-Source Product Detection
The product command uses a hierarchical discovery system:

1. **Kitchen Directory Search**: Automatically locates build output directory using `mulle-sde kitchen-dir`
2. **Build Metadata Parsing**: Reads `.motd` (message of the day) files for precise executable lists
3. **Fallback Pattern Matching**: Searches for `PROJECT_NAME` and `PROJECT_NAME.exe` as fallbacks
4. **Multi-Executable Handling**: Provides interactive selection when multiple executables exist

#### Automatic Build Trigger
- **Implicit Crafting**: If no products found and kitchen directory missing, automatically runs `mulle-sde craft`
- **Configuration Awareness**: Respects build configurations (Debug/Release)
- **SDK Targeting**: Handles cross-compilation with specific SDKs

#### Platform-Specific Handling
- **Windows Executables**: Automatically appends `.exe` extension
- **Unix Executables**: Handles shebang scripts and binary executables
- **Library Discovery**: Locates both static (`.a`, `.lib`) and dynamic (`.so`, `.dylib`, `.dll`) libraries
- **Debug Variants**: On Windows, also searches for `PROJECT_NAMEd.lib` (debug libraries)

### Configuration-Aware Product Resolution

#### Build Configuration Integration
- **Release vs Debug**: Separate search paths for different configurations
- **SDK Separation**: Different products per SDK (iphoneos, macosx, etc.)
- **Kitchen Directory Structure**: Respects mulle-craft's organized build structure

#### Smart Product Selection
- **Most Recent Priority**: Returns products ordered by modification time (newest first)
- **Interactive Selection**: When multiple products exist, presents user-friendly menu
- **Name-Based Filtering**: Allows targeting specific executables by name
- **Type-Specific Discovery**: Separate handling for executables vs libraries

### Cross-Platform Executable Handling

#### Extension Management
- **Unix Systems**: No extension required, respects shebang
- **Windows**: Automatic `.exe` handling
- **Cross-Platform**: Uses `MULLE_EXE_EXTENSION` for platform abstraction

#### Path Resolution
- **Relative Paths**: Returns paths relative to current directory for readability
- **Absolute Paths**: Provides full system paths when needed
- **Symbolic Link Resolution**: Follows symlinks to actual product locations

## Practical Examples

### Common Product Discovery Patterns

#### Basic Product Listing
```bash
# List all built products
mulle-sde product list

# List only the most recent product
mulle-sde product list --1

# List products for specific configuration
mulle-sde product list --configuration Debug
```

#### Product Search Path Investigation
```bash
# Show where products are expected to be found
mulle-sde product searchpath binary

# Show library search paths
mulle-sde product searchpath library

# Show paths for specific SDK
mulle-sde product searchpath --sdk iphoneos binary
```

#### Cross-Platform Product Handling
```bash
# Windows executable discovery
MULLE_EXE_EXTENSION=.exe mulle-sde product list

# Debug configuration on Windows (finds both myapp.exe and myappd.exe)
mulle-sde product list --configuration Debug

# Cross-compiled iOS products
mulle-sde product list --sdk iphoneos
```

### Advanced Usage Scenarios

#### Multi-Executable Project Management
```bash
# Project with multiple executables (server, client, cli)
mulle-sde product list
# Output might show:
# kitchen/build/Debug/server
# kitchen/build/Debug/client  
# kitchen/build/Debug/cli

# Interactive selection for specific executable
mulle-sde product --select
# Presents menu:
# Choose executable:
# 1) server
# 2) client
# 3) cli

# Target specific executable by name
mulle-sde product --name client list
```

#### Library Product Discovery
```bash
# Library project - find built libraries
mulle-sde product list
# Output: libmylib.a, libmylib.dylib, libmylib.so (depending on platform)

# Find specific library type
mulle-sde product searchpath library
# Shows search paths like:
# /project/kitchen/build/Debug
# /project/kitchen/lib/Debug
```

#### Integration with Other Commands
```bash
# Chain product discovery with execution
mulle-sde run $(mulle-sde product --name server list --1)

# Debug specific product
mulle-sde debug $(mulle-sde product --name client list --1)

# Install specific configuration
mulle-sde symlink --configuration Release /usr/local/bin
```

### Environment Variable Usage

#### Custom Build Targets
```bash
# Cross-compilation setup
export MULLE_CRAFT_SDKS="iphoneos macosx"
mulle-sde product list --sdk iphoneos

# Windows development on Unix
export MULLE_EXE_EXTENSION=.exe
export MULLE_UNAME=mingw64
mulle-sde product list
```

#### Debug Configuration Discovery
```bash
# Force debug product discovery
export OPTION_CONFIGURATION=Debug
mulle-sde product list

# SDK-specific development
export MULLE_CRAFT_SDKS="macosx iphoneos appletvos"
mulle-sde product list --sdk macosx
```

### Troubleshooting Product Discovery

#### Missing Product Investigation
```bash
# Enable verbose discovery
MULLE_TRACE=YES mulle-sde product list

# Check if kitchen directory exists
mulle-sde kitchen-dir

# Verify build configuration
mulle-sde env get PROJECT_TYPE
mulle-sde env get PROJECT_NAME

# Manual product verification
find $(mulle-sde kitchen-dir) -name "$(mulle-sde env get PROJECT_NAME)*" -type f -perm +111
```

#### Configuration Issues
```bash
# Debug configuration problems
mulle-sde product searchpath binary --configuration Debug

# SDK-specific path issues
mulle-sde product searchpath --sdk iphoneos binary

# Check environment variables
mulle-sde env | grep -E "(PROJECT_|MULLE_)"
```

### Multi-Platform Development Workflows

#### iOS/macOS Universal Development
```bash
# Build for both platforms
mulle-sde craft --sdk iphoneos
mulle-sde craft --sdk macosx

# List products for each platform
mulle-sde product list --sdk iphoneos
mulle-sde product list --sdk macosx

# Create platform-specific symlinks
mulle-sde symlink --sdk iphoneos ~/ios-bin
mulle-sde symlink --sdk macosx ~/mac-bin
```

#### Windows Cross-Compilation
```bash
# Setup Windows cross-compilation
export MULLE_UNAME=mingw64
export MULLE_EXE_EXTENSION=.exe

# Build Windows executables
mulle-sde craft

# Discover Windows products
mulle-sde product list  # Finds *.exe files
```

### Advanced Project Structures

#### Mono-repo with Multiple Executables
```bash
# Project structure with multiple executables
# src/server/main.c
# src/client/main.c  
# src/cli/main.c

# After building, discover all products
mulle-sde product list
# Shows:
# kitchen/build/Debug/server
# kitchen/build/Debug/client
# kitchen/build/Debug/cli

# Target specific executable
mulle-sde product --name server list

# Interactive selection when multiple exist
mulle-sde run --select  # Presents executable choice menu
```

#### Library with Demo Executables
```bash
# Library project with demo executables
# src/libmylib/
# demos/simple/
# demos/advanced/

# Library products
mulle-sde product list  # Shows libmylib.a, libmylib.so, etc.

# Demo executable discovery (falls back to find)
mulle-sde product searchpath binary  # Shows demo directories
```

## Troubleshooting

### Common Product Discovery Issues

#### "Product not found" Errors
```bash
# Issue: Product hasn't been built yet
# Solution: Build first
mulle-sde craft
mulle-sde product list

# Issue: Wrong configuration
# Solution: Specify configuration
mulle-sde product list --configuration Release

# Issue: Wrong SDK
# Solution: Use correct SDK
mulle-sde product list --sdk macosx
```

#### Multi-Executable Confusion
```bash
# Issue: Multiple executables, need specific one
# Solutions:
mulle-sde product --name myspecificapp list
# OR
mulle-sde product --select  # Interactive choice

# Issue: Products in unexpected locations
# Investigation:
mulle-sde kitchen-dir
mulle-sde product searchpath binary
```

#### Cross-Platform Issues
```bash
# Issue: Windows executables not found on Unix
# Solution: Check extension handling
export MULLE_EXE_EXTENSION=.exe
mulle-sde product list

# Issue: Debug libraries not found on Windows
# Solution: Windows debug libraries use 'd' suffix
mulle-sde product list --configuration Debug
```

### Debugging Product Discovery

#### Verbose Discovery Mode
```bash
# Enable detailed logging
MULLE_TRACE=YES mulle-sde product list

# Check discovery process step by step
mulle-sde kitchen-dir
ls -la $(mulle-sde kitchen-dir)
find $(mulle-sde kitchen-dir) -name "*.motd" -type f
```

#### Environment Verification
```bash
# Check all relevant environment variables
mulle-sde env | grep -E "(PROJECT_|MULLE_|OPTION_)"

# Verify project configuration
mulle-sde env get PROJECT_TYPE
mulle-sde env get PROJECT_NAME

# Check SDK configuration
mulle-sde env get MULLE_CRAFT_SDKS
```

### Integration Debugging

#### Product Command with Other Tools
```bash
# Debug product integration with run
MULLE_TRACE=YES mulle-sde run

# Check product discovery for debug
mulle-sde debug $(mulle-sde product --1 list)

# Verify symlink integration
mulle-sde symlink $(mulle-sde product --name myapp list --1) ~/bin/
```

### Performance Optimization

#### Faster Product Discovery
```bash
# Skip automatic building (if you know products exist)
mulle-sde product list --if-exists

# Get only the most recent product
mulle-sde product list --1

# Cache SDK-specific paths
mulle-sde product searchpath --sdk iphoneos binary > ios-paths.txt
```

#### Batch Operations
```bash
# Process multiple configurations
for config in Debug Release; do
    echo "=== $config Products ==="
    mulle-sde product list --configuration $config
done

# Process multiple SDKs
for sdk in macosx iphoneos; do
    echo "=== $sdk Products ==="
    mulle-sde product list --sdk $sdk
done
```