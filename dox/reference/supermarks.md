# mulle-sde Supermarks System

## Overview

The **supermarks** system is an advanced build configuration framework within mulle-sde that automatically derives high-level build characteristics from dependency and library marks. Supermarks are computed properties that influence how dependencies are built, linked, and integrated into your project.

Unlike regular marks that are explicitly set by users, supermarks are automatically determined by analyzing the combination of existing marks, project type, and dependency characteristics. They serve as a bridge between user-friendly configuration and complex build system requirements.

## Command Analysis

The supermarks system operates as a plugin within the `mulle-sourcetree` infrastructure. It provides:

- **Automatic language detection** (C vs Objective-C)
- **Link behavior analysis** (static, dynamic, framework linking)
- **Header management** (public/private headers, header-only libraries)
- **Build phase optimization** (single-phase vs multi-phase builds)
- **Cross-platform compatibility** handling

## Supermark Types

### Language Detection Supermarks

#### `C`
**Purpose**: Identifies C language dependencies
**Auto-detected when**:
- `no-import` mark is present (uses `#include` instead of `#import`)
- Dependency lacks Objective-C specific patterns

**Build implications**:
- Disables Objective-C specific loader mechanisms
- Uses C-style header inclusion
- Enables C-specific optimization flags

#### `ObjC`
**Purpose**: Identifies Objective-C language dependencies
**Auto-detected when**:
- `import` mark is present (uses `#import` directive)
- `all-load` mark indicates Objective-C runtime requirements

**Build implications**:
- Enables Objective-C runtime support
- Uses `#import` for header inclusion
- Enables Objective-C specific linker flags

### Link Configuration Supermarks

#### `LinkForce`
**Purpose**: Forces specific linking behavior for C libraries
**Auto-detected when**:
- Language is C (`C` supermark present)
- `link` mark is enabled
- `all-load` mark conflicts with C linking patterns

**Build implications**:
- Overrides automatic linking behavior
- Ensures symbols are properly exported
- Resolves C/Objective-C linking conflicts

#### `LinkLeaf`
**Purpose**: Creates leaf-node linking for isolated dependencies
**Auto-detected when**:
- `link` mark is enabled
- `no-cmake-inherit` mark prevents dependency inheritance

**Build implications**:
- Prevents transitive linking
- Creates standalone library linking
- Useful for plugin architectures

#### `LinkStaticToExe`
**Purpose**: Links static libraries directly to executable
**Auto-detected when**:
- `link` mark is enabled
- `no-dynamic-link` and `no-intermediate-link` marks are present

**Build implications**:
- Bypasses intermediate shared libraries
- Direct static linking to final executable
- Reduces runtime dependencies

#### `Startup`
**Purpose**: Identifies startup/system initialization libraries
**Auto-detected when**:
- `all-load` mark is present
- `singlephase` build is requested
- Specific no-link/no-header patterns are detected

**Build implications**:
- Ensures early initialization
- Prevents optimization removal
- Guarantees symbol availability

### Header Management Supermarks

#### `HeaderLess`
**Purpose**: Libraries without public headers
**Auto-detected when**:
- `no-header` mark is present
- `link` mark indicates linking-only dependency

**Build implications**:
- Skips header installation
- Reduces include path complexity
- Suitable for implementation-only libraries

#### `HeaderOnly`
**Purpose**: Header-only libraries
**Auto-detected when**:
- `header` mark is present
- `no-link` mark indicates no linking required

**Build implications**:
- No library compilation
- Header-only distribution
- Compile-time only dependency

#### `HeaderPrivate`
**Purpose**: Libraries with private headers only
**Auto-detected when**:
- `no-public` mark is present
- Headers exist but aren't exposed publicly

**Build implications**:
- Private header installation
- Internal API usage only
- Implementation detail encapsulation

### Build Phase Supermarks

#### `Serial`
**Purpose**: Single-phase build dependencies
**Auto-detected when**:
- `singlephase` mark is enabled
- Not an embedded or library type project

**Build implications**:
- Sequential build process
- Simplified dependency resolution
- Faster build for simple projects

#### `Parallel`
**Purpose**: Multi-phase build dependencies
**Auto-detected when**:
- `no-singlephase` mark is present
- Complex project structure detected

**Build implications**:
- Parallel build phases
- Advanced dependency management
- Optimal for large projects

#### `UnknownLanguage`
**Purpose**: Fallback for unrecognized language patterns
**Auto-detected when**:
- Language cannot be determined from marks
- Mixed language characteristics

**Build implications**:
- Conservative build settings
- Maximum compatibility mode
- Manual review recommended

## Usage Patterns

### Viewing Supermarks

Supermarks are displayed as part of the dependency listing:

```bash
# List dependencies with supermarks
mulle-sde dependency list --verbose

# View specific dependency supermarks
mulle-sde dependency get <dependency-name> --format=supermarks
```

### Supermarks in Build Configuration

Supermarks influence the generated CMake configuration:

```bash
# Reflect changes and see supermark effects
mulle-sde reflect

# Check craftinfo for supermark-derived settings
mulle-sde craftinfo <dependency-name>
```

### Manual Supermark Override

While supermarks are auto-detected, you can influence them through marks:

```bash
# Force C language detection
mulle-sde dependency add github:user/libc-project --marks no-import

# Force Objective-C detection
mulle-sde dependency add github:user/objc-project --marks import,all-load

# Create header-only library
mulle-sde dependency add github:nothings/stb --marks header,no-link
```

## Hidden Options and Advanced Usage

### Supermark Decomposition

Supermarks can be decomposed into their constituent marks:

```bash
# Decompose supermarks to understand underlying marks
mulle-sourcetree supermark-decompose C
# Output: no-all-load,no-import

mulle-sourcetree supermark-decompose Startup
# Output: all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header,no-cmake-searchpath,no-cmake-loader
```

### Cross-Platform Supermark Behavior

Supermarks adapt to target platforms:

- **Linux**: Emphasizes static linking (`LinkStaticToExe`)
- **macOS**: Enables framework detection patterns
- **Windows**: Adjusts for DLL boundaries
- **BSD**: Optimizes for ports system compatibility

### Debug Supermark Detection

Enable detailed supermark logging:

```bash
# Enable supermark debug output
MULLE_SOURCETREE_TRACE=YES mulle-sde dependency list

# View supermark calculation for specific dependency
MULLE_SOURCETREE_TRACE=YES mulle-sde dependency get <name>
```

## Integration Points

### With `craft` Command

Supermarks directly influence craft behavior:

```bash
# Supermarks affect build order and flags
mulle-sde craft

# Recraft respects new supermark configurations
mulle-sde recraft
```

### With `reflect` Command

Supermarks are recalculated during reflection:

```bash
# Reflect updates supermark-based CMakeLists.txt
mulle-sde reflect

# Force supermark recalculation
mulle-sde reflect --force
```

### With `dependency` Management

Supermarks evolve with dependency changes:

```bash
# Adding dependencies triggers supermark recalculation
mulle-sde dependency add github:user/new-lib

# Moving dependencies affects supermark inheritance
mulle-sde dependency move old-lib to after new-lib

# Removing dependencies cleans up supermark references
mulle-sde dependency remove old-lib
```

## Practical Examples

### Example 1: C Library Integration

```bash
# Add a C library (automatic C supermark)
mulle-sde dependency add github:madler/zlib

# Verify C supermark is applied
mulle-sde dependency get zlib --format=supermarks
# Output: C,LinkStaticToExe

# Check derived build flags
mulle-sde craftinfo zlib CFLAGS
# Output: -Wno-import -DNO_IMPORT
```

### Example 2: Objective-C Framework

```bash
# Add Objective-C framework with proper supermarks
mulle-sde dependency add github:MulleFoundation/MulleObjC --marks import,all-load

# Verify ObjC supermark
mulle-sde dependency get MulleObjC --format=supermarks
# Output: ObjC,Startup

# Framework-specific flags applied
mulle-sde craftinfo MulleObjC LDFLAGS
# Output: -framework Foundation -all_load
```

### Example 3: Header-Only Library

```bash
# Add header-only library
mulle-sde dependency add github:nothings/stb --marks header,no-link

# Verify HeaderOnly supermark
mulle-sde dependency get stb --format=supermarks
# Output: HeaderOnly

# No linking flags generated
mulle-sde craftinfo stb LDFLAGS
# Output: (empty)
```

### Example 4: Cross-Platform Configuration

```bash
# Add platform-specific dependency
mulle-sde dependency add github:user/platform-lib --marks no-import,no-singlephase

# Supermarks adapt per platform
mulle-sde config switch linux
mulle-sde dependency get platform-lib --format=supermarks
# Output: C,LinkStaticToExe,Serial

mulle-sde config switch macos
mulle-sde dependency get platform-lib --format=supermarks
# Output: C,LinkLeaf,Parallel
```

## Advanced Configuration

### Custom Supermark Detectors

Developers can extend supermark detection:

```bash
# Add custom supermark detector (advanced)
export MULLE_SOURCETREE_SUPERMARK_DETECTORS="my-detector:$PWD/detectors"
```

### Supermark Inheritance Rules

Supermarks follow inheritance patterns:

- **Parent dependencies**: Supermarks cascade to sub-dependencies
- **Platform constraints**: Target platform overrides generic supermarks
- **Manual overrides**: Explicit marks can override supermark detection

### Performance Optimization

Supermarks enable build optimizations:

```bash
# Optimize for parallel builds
mulle-sde dependency set all --marks no-singlephase

# Reduce linking overhead
mulle-sde dependency set large-lib --marks no-all-load

# Minimize header exposure
mulle-sde dependency set internal-lib --marks no-public
```

## Troubleshooting

### Common Supermark Issues

1. **Incorrect Language Detection**:
   ```bash
   # Force correct language
   mulle-sde dependency set lib --marks import  # Force ObjC
   mulle-sde dependency set lib --marks no-import  # Force C
   ```

2. **Unexpected Linking Behavior**:
   ```bash
   # Diagnose linking supermarks
   MULLE_SOURCETREE_TRACE=YES mulle-sde craftinfo lib LDFLAGS
   ```

3. **Header Issues**:
   ```bash
   # Check header supermarks
   mulle-sde dependency get lib --format=supermarks | grep Header
   ```

### Debug Commands

```bash
# View all supermarks for project
mulle-sourcetree list --format='%{name} %{supermarks}'

# Check supermark calculation logic
MULLE_SOURCETREE_TRACE=YES mulle-sde dependency list --verbose

# Validate supermark consistency
mulle-sde doctor --check supermarks
```

## Best Practices

1. **Let supermarks auto-detect** when possible
2. **Use explicit marks** to override only when necessary
3. **Test cross-platform behavior** early in development
4. **Document manual supermark overrides** in project README
5. **Regularly review** supermark configurations with `mulle-sde doctor`

## See Also

- [mulle-sde dependency documentation](dependency.md)
- [mulle-sde craft documentation](craft.md)
- [mulle-sourcetree manual](https://github.com/mulle-sde/mulle-sourcetree)
- [CMake integration guide](cmake-integration.md)