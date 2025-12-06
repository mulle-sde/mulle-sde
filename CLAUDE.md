# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**mulle-sde** is a cross-platform command-line IDE and dependency manager for C languages (C, Objective-C, C++). It provides a complete development environment similar to npm or virtualenv but for C/C++ projects.

## Core Development Cycle

- **Edit**: Use your preferred editor/IDE to modify source files
- **Reflect**: `mulle-sde reflect` automatically updates build system files and headers  
- **Craft**: `mulle-sde craft` fetches dependencies, builds them, and builds your project

## Key Commands

### Project Setup
```bash
# Initialize new project
mulle-sde init -d myproject -m foundation/objc-developer executable

# Interactive setup
mulle-sde init  # choose options interactively
```

### Development Workflow
```bash
mulle-sde edit              # Set up editor
mulle-sde add src/MyClass.m # Add new source file
mulle-sde reflect          # Update build files
mulle-sde craft            # Build project and dependencies
mulle-sde run              # Run executable
mulle-sde debug            # Debug executable
```

### Dependency Management
```bash
mulle-sde add github:madler/zlib.tar    # Add third-party dependency
mulle-sde dependency move zlib to top   # Reorder dependencies
mulle-sde dependency list               # List dependencies
mulle-sde craftinfo zlib CFLAGS "-DBAR=1"  # Configure build flags
```

### Testing
```bash
mulle-sde test init        # Initialize test framework
mulle-sde test craft       # Build tests
mulle-sde test run         # Run tests
mulle-sde test coverage    # Generate coverage report
```

## Build and Test Commands

### Installation
```bash
curl -L 'https://github.com/mulle-sde/mulle-sde/archive/latest.tar.gz' | tar xfz - && cd 'mulle-sde-latest' && sudo ./bin/installer /usr/local
```

### Development Build
```bash
mkdir build && cd build
cmake ..
make
```

### Test Suite
```bash
./test/run-test           # Run full test suite
cd test/00-init-none && ./run-test  # Run individual test
```

## Architecture

- **Language**: Primarily bash shell scripts with supporting tools
- **Build System**: CMake integration with automatic CMakeLists.txt generation
- **Extension System**: Plugin-based architecture in `src/mulle-sde/`
- **Cross-platform**: Android, BSDs, Linux, macOS, SunOS, Windows

## Key Directories

- `src/` - Core shell scripts (139 .sh files)
- `src/mulle-sde/` - Extension system with craftinfo templates
- `test/` - Test suite with run-test framework
- `example/` - Example projects
- `bin/` - Installation scripts

## Environment Management

- **Virtual environments**: Isolated build environments per project
- **Config switching**: `mulle-sde config switch x11` for different environments
- **Cross-compilation**: Support for targeting different platforms and SDKs