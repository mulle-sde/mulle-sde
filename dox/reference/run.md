# mulle-sde run - Complete Reference

## Quick Start
Execute built products within the mulle-sde environment with automatic dependency setup and environment configuration.

```bash
mulle-sde run                           # Run the main executable
mulle-sde run mytool                    # Run specific executable by name
mulle-sde run --debug -- --help         # Run Debug build with --help argument
mulle-sde run -e --version             # Run outside mulle-sde environment
mulle-sde run -b                       # Run in background
```

## All Available Options

### Basic Options (in usage)
- `--`: Pass remaining options as arguments to the executable
- `-e`: Run the executable outside of the mulle-sde environment
- `-b`: Run the executable in the background (&)

### Advanced Options (hidden)

#### Configuration Control Options
- `--configuration <config>`: Specify build configuration to run
  - **When to use**: When you have multiple configurations and want to run a specific one
  - **Example**: `mulle-sde run --configuration Release`
  - **Side effects**: Looks for executable in Release build directory

- `--sdk <sdk>`: Target specific SDK for cross-compilation
  - **When to use**: When working with cross-compilation toolchains
  - **Example**: `mulle-sde run --sdk iphoneos`
  - **Side effects**: Uses SDK-specific build paths and environment

- `--debug`: Shortcut for `--configuration Debug`
  - **When to use**: For testing debug builds with extra assertions/symbols
  - **Example**: `mulle-sde run --debug`
  - **Side effects**: Uses Debug build configuration

- `--release`: Shortcut for `--configuration Release`
  - **When to use**: For performance testing release builds
  - **Example**: `mulle-sde run --release`
  - **Side effects**: Uses Release build configuration

#### Execution Control Options
- `--if-exists`: Only run if executable exists (no auto-build)
  - **When to use**: In scripts where you want to avoid automatic building
  - **Example**: `mulle-sde run --if-exists || echo "Not built yet"`
  - **Side effects**: Skips automatic `mulle-sde craft` if executable missing

- `--select`: Interactive executable selection when multiple exist
  - **When to use**: When project has multiple executables and you want to choose
  - **Example**: `mulle-sde run --select`
  - **Side effects**: Shows menu of available executables

- `--no-run-env`: Skip mulle-sde environment setup
  - **When to use**: When you want minimal environment setup
  - **Example**: `mulle-sde run --no-run-env`
  - **Side effects**: Only basic environment variables are set

- `--restrict` / `--restrict-environment`: Run with restricted/clean environment
  - **When to use**: For testing with minimal system environment
  - **Example**: `mulle-sde run --restrict`
  - **Side effects**: Minimal environment variables, no inherited settings

- `--background`: Alias for `-b`
  - **When to use**: When you want to run long processes
  - **Example**: `mulle-sde run --background`
  - **Side effects**: Process runs in background, returns immediately

- `--foreground`: Override background settings
  - **When to use**: To force foreground execution even with POST_RUN set
  - **Example**: `mulle-sde run --foreground`
  - **Side effects**: Ignores MULLE_SDE_POST_RUN background implication

#### Debugging Options
- `--objc-trace-leak` / `--leak` / `--trace-leak`: Enable Objective-C leak tracing
  - **When to use**: Debugging memory leaks in Objective-C code
  - **Example**: `mulle-sde run --leak`
  - **Side effects**: Sets MULLE_TESTALLOCATOR=3 and MULLE_OBJC_TRACE_LEAK=YES

- `--objc-trace-zombie` / `--zombie` / `--trace-zombie`: Enable zombie object detection
  - **When to use**: Debugging use-after-free in Objective-C
  - **Example**: `mulle-sde run --zombie`
  - **Side effects**: Sets MULLE_OBJC_TRACE_ZOMBIE=YES

- `--no-objc-trace-zombie` / `--no-zombie` / `--no-trace-zombie`: Disable zombie detection
  - **When to use**: When zombie detection interferes with debugging
  - **Example**: `mulle-sde run --no-zombie`
  - **Side effects**: Disables default zombie detection

### Environment Variables

#### Runtime Control Variables
- `MULLE_SDE_RUN`: Custom command line template for execution
  - **Default**: Direct executable execution
  - **Set with**: `export MULLE_SDE_RUN="lldb -- ${EXECUTABLE}"`
  - **Use case**: Automatic debugger attachment, profiling tools
  - **Variable expansion**: `${EXECUTABLE}` is replaced with actual executable path

- `MULLE_SDE_PRE_RUN`: Command to execute before running the executable
  - **Default**: None
  - **Set with**: `export MULLE_SDE_PRE_RUN="echo 'Starting...'"`
  - **Use case**: Setup tasks, logging, environment preparation

- `MULLE_SDE_POST_RUN`: Command to execute after executable starts
  - **Default**: None
  - **Set with**: `export MULLE_SDE_POST_RUN="echo 'Process started'"`
  - **Use case**: Background process management, notifications
  - **Side effect**: Implies background execution (`-b`)

#### Project Context Variables
- `MULLE_VIRTUAL_ROOT`: Root directory of the virtual environment
  - **Default**: Project root
  - **Use case**: Reference project structure from scripts

- `PROJECT_NAME`: Name of the current project
  - **Default**: Directory name
  - **Use case**: Executable name determination

- `PROJECT_TYPE`: Type of project (executable/library/none)
  - **Default**: From project configuration
  - **Use case**: Determines if `mulle-sde run` is valid

## Hidden Behaviors Explained

### Automatic Build Detection
When no executable is found, `mulle-sde run` automatically triggers `mulle-sde craft` to build the project. This happens:

1. **Kitchen directory check**: Looks in `mulle-sde kitchen-dir` for executables
2. **Build trigger**: If kitchen directory doesn't exist or no executables found
3. **Post-build search**: Re-scans for executables after successful build

**Example flow**:
```bash
$ mulle-sde run --help
# No executable found
# Automatically runs: mulle-sde craft
# Then runs: ./build/Debug/myproject --help
```

### Executable Discovery Algorithm
The run command uses a sophisticated search algorithm:

1. **Direct path**: If argument is an existing executable path, use it directly
2. **Project executables**: Search for PROJECT_NAME[.exe] in kitchen directory
3. **Multiple executables**: Use modification time to pick the freshest
4. **Interactive selection**: If `--select` is used and multiple found

**Search order**:
```
kitchen_dir/PROJECT_NAME[.exe] (newest first)
kitchen_dir/*/.motd files (parse for executable names)
kitchen_dir/*/PROJECT_NAME[.exe] (fallback)
```

### Environment Setup Process
The mulle-sde environment setup involves:

1. **Virtual environment activation**: Sets up paths for dependencies
2. **Library path configuration**: Adds dependency library paths
3. **Environment variable injection**: Applies craftinfo environment settings
4. **Cross-compilation support**: Uses SDK-specific paths when `--sdk` specified

### Objective-C Runtime Integration
Special handling for Objective-C projects:

- **Default zombie detection**: Automatically enables NSZombieEnabled unless disabled
- **Memory debugging**: Leak detection via environment variables
- **Runtime tracing**: Zombie and leak tracing via mulle-objc runtime

## Practical Examples

### Common Usage Patterns

#### Basic Execution
```bash
# Run the main project executable
mulle-sde run

# Run with arguments
mulle-sde run -- --config-file /path/to/config.ini --verbose

# Run specific executable in multi-executable project
mulle-sde run mytool
```

#### Development Workflow
```bash
# Debug build with debugger
mulle-sde run --debug -- --help

# Release build for performance testing
mulle-sde run --release --benchmark

# Cross-platform testing
mulle-sde run --sdk macosx -- --test-suite all
```

#### Background Processing
```bash
# Start server in background
mulle-sde run --background -- --port 8080 --daemon

# Start with post-execution notification
export MULLE_SDE_POST_RUN="notify-send 'Server started'"
mulle-sde run --background
```

#### Debugging Integration
```bash
# Run with debugger
export MULLE_SDE_RUN="lldb -- ${EXECUTABLE}"
mulle-sde run -- --debug-flag

# Run with profiler
export MULLE_SDE_RUN="valgrind --leak-check=full ${EXECUTABLE}"
mulle-sde run

# Memory debugging for Objective-C
mulle-sde run --leak --zombie
```

### Environment Variable Examples

#### Custom Runtime Environment
```bash
# Setup for debugging session
export MULLE_SDE_PRE_RUN="echo '=== Starting Debug Session ==='"
export MULLE_SDE_RUN="lldb -- ${EXECUTABLE}"
export MULLE_SDE_POST_RUN="echo '=== Debug Session Complete ==='"

mulle-sde run --debug
```

#### Cross-Platform Testing
```bash
# iOS simulator testing
export MULLE_SDE_RUN="ios-sim launch ${EXECUTABLE}"
mulle-sde run --sdk iphonesimulator

# Android testing
export MULLE_SDE_RUN="adb shell ${EXECUTABLE}"
mulle-sde run --sdk android
```

### Advanced Scenarios

#### Multiple Executable Projects
```bash
# List all available executables
mulle-sde product list

# Interactive selection
mulle-sde run --select

# Specific executable selection
mulle-sde run test-driver -- --gtest_filter=MathTest.*
```

#### Conditional Execution
```bash
# Only run if already built
if mulle-sde run --if-exists -- --version; then
    echo "Version check passed"
else
    echo "Build required"
    mulle-sde craft && mulle-sde run -- --version
fi
```

#### Integration with Testing
```bash
# Run tests with environment setup
mulle-sde run --debug -- --test-output xml

# Run with coverage
export MULLE_SDE_RUN="${EXECUTABLE} --coverage"
mulle-sde run --debug -- --test-suite unit
```

## Troubleshooting

### Common Issues and Solutions

#### "Could not figure what product was build"
**Problem**: No executable found after build
**Solutions**:
1. Check project type: `mulle-sde env get PROJECT_TYPE` (must be "executable")
2. Verify build success: `mulle-sde craft` should complete without errors
3. Check executable permissions: `find build -type f -perm +111`

#### Multiple Executables Found
**Problem**: Project builds multiple executables, wrong one runs
**Solutions**:
1. Use specific naming: `mulle-sde run myspecificexecutable`
2. Use interactive selection: `mulle-sde run --select`
3. Check build products: `mulle-sde product list`

#### Environment Issues
**Problem**: Executable can't find libraries
**Solutions**:
1. Ensure mulle-sde environment is active (don't use `-e` unless necessary)
2. Check library paths: `mulle-sde env | grep -i library`
3. Verify dependencies: `mulle-sde dependency list`

#### Cross-Compilation Issues
**Problem**: Wrong executable architecture
**Solutions**:
1. Specify correct SDK: `mulle-sde run --sdk <target-sdk>`
2. Check target architecture: `file $(mulle-sde product list | head -1)`
3. Verify build configuration: `mulle-sde craft --configuration Debug --sdk <sdk>`

### Debugging Run Issues

#### Verbose Execution
```bash
# Enable verbose logging
MULLE_LOG_LEVEL=3 mulle-sde run --debug

# Check what executable will be used
mulle-sde product list

# Validate environment
mulle-sde env | grep -E "(PATH|LD_LIBRARY|DYLD)"
```

#### Environment Inspection
```bash
# Preview environment without running
mulle-sde env

# Check specific variables
mulle-sde env get MULLE_SDE_RUN
mulle-sde env get PROJECT_NAME
```

#### Build Validation
```bash
# Force rebuild and then run
mulle-sde craft --clean && mulle-sde run

# Check build artifacts
find build -name "*.exe" -o -perm +111 -type f
```

### Integration with Other Commands

#### Development Cycle Integration
```bash
# Complete development cycle
mulle-sde add src/newfeature.c
mulle-sde reflect
mulle-sde craft
mulle-sde run -- --test-newfeature
```

#### Testing Integration
```bash
# Run specific test configuration
mulle-sde test craft && mulle-sde run --debug -- --run-tests

# Coverage analysis
mulle-sde test coverage
mulle-sde run --debug -- --coverage-report
```

#### Debugging Integration
```bash
# Build with debug symbols and run in debugger
mulle-sde craft --configuration Debug
export MULLE_SDE_RUN="lldb -- ${EXECUTABLE}"
mulle-sde run
```