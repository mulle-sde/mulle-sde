# mulle-sde library - Complete Reference

## Quick Start

Manage system libraries and frameworks for linking into your C/C++/Objective-C project. The library command handles system libraries (like `-lm` for math), frameworks (like Cocoa on macOS), and provides platform-specific linking configuration.

## All Available Options

### Basic Options (in usage)

#### Commands
- `add`: Add system libraries or frameworks to your project
- `export`: Export library configuration as a script
- `get`: Retrieve library settings and properties
- `list`: List all configured libraries (default)
- `remove`: Remove a library from configuration
- `set`: Modify library settings like aliases, includes, or platform exclusions

#### Global Options
- `-h, --help`: Show detailed usage information

### Library Add Options
- `-l<name>`: Add a system library (e.g., `-lm` for libm)
- `-f<name>`: Add a macOS framework (e.g., `-fCocoa`)
- `--framework`: Mark library as macOS framework
- `--objc`: Configure for Objective-C linking
- `--optional`: Library is optional (won't fail build if missing)
- `--<platform>`: Use library only on specific platform
- `--no-<platform>`: Exclude library on specific platform
- `--no-header`: Don't generate include statements
- `--private`: Headers won't be visible to API consumers
- `--public`: Make library publicly visible

### Library Set Options
- `--append`: Append to existing values instead of replacing

### Library List Options
- `-c`: Use columnar output format
- `--json`: Output in JSON format (default)
- `--`: Pass remaining arguments to underlying sourcetree

## Command Analysis

### Purpose in mulle-sde Ecosystem
The `library` command serves as the bridge between your project and system-installed libraries/frameworks. While `dependency` handles third-party source code that needs building, `library` handles pre-compiled system resources that only need linking.

### Key Distinctions
- **vs Dependencies**: Libraries are pre-built system resources, dependencies need compilation
- **vs Symbols**: Libraries provide linking information, symbols provide compile-time definitions
- **vs Frameworks**: Libraries are cross-platform (.a, .so), frameworks are macOS-specific (.framework)

## Usage Patterns

### Basic Library Addition
```bash
# Add standard C math library
mulle-sde library add m

# Add pthread library
mulle-sde library add pthread

# Add multiple libraries at once
mulle-sde library add -lm -lpthread -lz
```

### Framework Management (macOS)
```bash
# Add Cocoa framework
mulle-sde library add -fCocoa

# Add as framework explicitly
mulle-sde library add --framework CoreData
```

### Platform-Specific Configuration
```bash
# Add Windows-specific library
mulle-sde library add --windows winmm

# Exclude on Linux
mulle-sde library add --no-linux some-windows-lib

# macOS-only framework
mulle-sde library add --darwin --framework AppKit
```

### Objective-C Configuration
```bash
# Add with Objective-C linking
mulle-sde library add --objc objc

# Add Foundation framework for ObjC
mulle-sde library add --framework --objc Foundation
```

## Hidden Options and Advanced Features

### Automatic Extension Detection
The system automatically determines library extensions based on platform:
- **Linux/BSD**: `.so` (shared), `.a` (static)
- **macOS**: `.dylib` (shared), `.a` (static), `.framework`
- **Windows**: `.dll` (shared), `.lib` (static)

### Library Name Validation
- **Warning System**: Detects common mistakes like including "lib" prefix or file extensions
- **Example**: `libm.so` ’ warning: use just `m`
- **Cross-platform**: Adjusts warnings based on target platform

### Advanced Library Configuration

#### Aliases for Flexible Linking
```bash
# Set alternative names for library search
mulle-sde library set pthread aliases pthread,pthreads

# Add additional search names
mulle-sde library set --append pthread aliases pthreadGC2
```

#### Custom Include Headers
```bash
# Override default header inclusion
mulle-sde library set zlib include zlib.h

# Use subdirectory headers
mulle-sde library set openssl include openssl/ssl.h
```

#### Platform Exclusion Management
```bash
# Exclude library on specific platforms
mulle-sde library set some-lib platform-excludes windows,linux

# Add platform to existing exclusions
mulle-sde library set --append some-lib platform-excludes freebsd
```

## Practical Examples

### Real-World Scenarios

#### Graphics Programming Setup
```bash
# OpenGL development
mulle-sde library add --linux GL
mulle-sde library add --darwin --framework OpenGL
mulle-sde library add --windows opengl32

# GLFW for window management
mulle-sde library add --linux glfw
mulle-sde library add --darwin --framework GLFW
```

#### Audio Processing
```bash
# Linux audio
mulle-sde library add --linux asound

# macOS audio
mulle-sde library add --darwin --framework AudioToolbox

# Cross-platform audio
mulle-sde library add --optional sndfile
```

#### Database Connectivity
```bash
# MySQL client
mulle-sde library add mysqlclient

# PostgreSQL
mulle-sde library add pq

# SQLite
mulle-sde library add sqlite3
```

#### Network Programming
```bash
# Basic networking
mulle-sde library add socket
mulle-sde library add nsl

# SSL/TLS
mulle-sde library add ssl crypto
```

### Using pkg-config Integration
```bash
# Use pkg-config for complex library configurations
mulle-sde library add $(pkg-config --static --libs-only-l glfw3)

# Combine with manual additions
mulle-sde library add $(pkg-config --libs-only-l gtk+-3.0) -lm
```

## Integration Points

### With mulle-sde reflect
When you run `mulle-sde reflect`, library information is used to:
- Generate appropriate linker flags in build system
- Create platform-specific conditional compilation blocks
- Update CMakeLists.txt with find_library calls

### With mulle-sde craft
During the craft process:
- Libraries are validated for existence on target platform
- Missing optional libraries generate warnings, not errors
- Platform-specific libraries are filtered based on build target

### With mulle-sde dependency
Libraries and dependencies work together:
- Dependencies provide source code that might generate libraries
- Libraries provide system dependencies that dependencies might need
- Order matters: system libraries typically link after project dependencies

### With mulle-sde test
For testing scenarios:
- Test-specific libraries can be added without affecting main build
- Platform-specific test libraries can be conditionally included
- Optional libraries allow tests to skip when system requirements aren't met

## Advanced Usage

### Complex Platform Scenarios

#### Multi-Platform Graphics Application
```bash
# Core libraries for all platforms
mulle-sde library add m

# Platform-specific graphics
mulle-sde library add --linux GL X11 Xrandr Xi Xxf86vm Xcursor
mulle-sde library add --darwin --framework OpenGL --framework Cocoa
mulle-sde library add --windows opengl32 gdi32 winmm

# Optional debugging
mulle-sde library add --optional --linux glfw
mulle-sde library add --optional --darwin --framework GLFW
```

#### Cross-Compilation Setup
```bash
# Target-specific libraries for ARM Linux
mulle-sde library add --linux-arm64 GLESv2 EGL

# x86_64 specific
mulle-sde library add --linux-x86_64 GL

# Conditional based on actual build target
mulle-sde library add --optional $(test $ARCH = arm64 && echo GLESv2 || echo GL)
```

### Library Chains and Dependencies
```bash
# Libraries that depend on other libraries
mulle-sde library add png
mulle-sde library add z  # zlib dependency for png

# Framework dependencies
mulle-sde library add --framework CoreData
mulle-sde library add --framework Foundation  # CoreData depends on Foundation
```

### Dynamic Configuration
```bash
# Script-based library detection
for lib in $(ldconfig -p | grep -o 'libssl\.so\.[0-9.]*' | head -1 | sed 's/libssl\.so\.//'); do
    mulle-sde library add ssl
    break
done

# Environment-based library selection
if [ "$USE_STATIC" = "YES" ]; then
    mulle-sde library add --no-header z
else
    mulle-sde library add z
fi
```

### Troubleshooting Common Issues

#### Library Not Found
```bash
# Check what's available
ldconfig -p | grep libm
pkg-config --list-all | grep ssl

# Add with optional flag if uncertain
mulle-sde library add --optional ssl
```

#### Platform Detection Issues
```bash
# Verify platform detection
mulle-sde common-unames

# Explicit platform specification
mulle-sde library add --$(uname -s | tr '[:upper:]' '[:lower:]') specific-lib
```

#### Header Inclusion Problems
```bash
# Check default header inclusion
mulle-sde library get openssl include

# Override with correct path
mulle-sde library set openssl include openssl/opensslv.h
```

## Best Practices

### Naming Conventions
- Always use library names without `lib` prefix or file extensions
- Use framework names without `.framework` extension
- Prefer lowercase for consistency across platforms

### Platform Organization
- Group platform-specific libraries together in documentation
- Use consistent ordering: linux, darwin, windows, then others
- Consider using scripts for complex platform detection

### Version Management
- Document library version requirements in project README
- Use optional flags for libraries with varying availability
- Consider containerized builds for consistent library availability

### Integration with Build Systems
- After adding libraries, always run `mulle-sde reflect` to update build files
- Use `mulle-sde library list --json` for programmatic access in CI/CD
- Keep library additions in version control with clear commit messages