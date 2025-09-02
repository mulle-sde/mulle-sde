# mulle-sde debug - Complete Reference

## Quick Start
Launch an interactive debugger for your project executable with automatic Objective-C zombie detection enabled by default.

## All Available Options

### Basic Options (in usage)
```
- -h, --help, help                    : Show usage information
- --configuration <c>                 : Set build configuration (Debug/Release)
- --debug                             : Shortcut for --configuration Debug
- --executable <exe>                  : Use specific executable path
- --leak                              : Enable mulle-objc leak tracing
- --release                           : Shortcut for --configuration Release
- --restrict                          : Run debugger with restricted environment
- --sdk <sdk>                         : Set SDK for debugging
- --unordered                         : Don't sort executable menu
- --zombie                            : Enable mulle-objc zombie tracing (DEFAULT)
- --no-zombie                         : Disable mulle-objc zombie tracing
```

### Advanced Options (hidden)
```
- --objc-trace-leak, --trace-leak    : Alias for --leak
  - **When to use**: When you need explicit leak tracing beyond default zombie detection
  - **Example**: `mulle-sde debug --trace-leak myapp`
  - **Side effects**: Sets MULLE_TESTALLOCATOR=3 and MULLE_OBJC_TRACE_LEAK=YES

- --objc-trace-zombie, --trace-zombie : Alias for --zombie
  - **When to use**: When you want to explicitly enable zombie tracing (already default)
  - **Example**: `mulle-sde debug --trace-zombie myapp`
  - **Side effects**: Sets MULLE_OBJC_TRACE_ZOMBIE=YES

- --no-objc-trace-zombie, --no-trace-zombie : More explicit alias for --no-zombie
  - **When to use**: When debugging performance issues where zombie detection overhead is problematic
  - **Example**: `mulle-sde debug --no-trace-zombie myapp`
  - **Side effects**: Disables all Objective-C runtime debugging features

- --restrict-environment              : Alias for --restrict
  - **When to use**: When debugging environment variable issues or creating minimal repro cases
  - **Example**: `mulle-sde debug --restrict-environment myapp`
  - **Side effects**: Removes -E flag from mudo, running debugger without environment inheritance

- --select, --reselect                : Force debugger selection prompt
  - **When to use**: When you want to override saved debugger preference or switch debuggers
  - **Example**: `mulle-sde debug --select`
  - **Side effects**: Ignores MULLE_SDE_DEBUGGER_CHOICE setting and shows selection menu

- --no-mudo                           : Skip mudo environment wrapper (run debugger directly)
  - **When to use**: When debugging environment setup issues or using external debuggers
  - **Example**: `mulle-sde debug --no-mudo myapp`
  - **Side effects**: Environment variables from `mulle-sde env` are NOT available

- -e, -E                              : Mudo flags for environment handling
  - **When to use**: Advanced mudo control during debugging sessions
  - **Example**: `mulle-sde debug -e myapp` (preserve environment)
  - **Side effects**: Controls how environment variables are passed to debugger

- --                                  : Pass remaining arguments as program arguments
  - **When to use**: When your program arguments conflict with mulle-sde options
  - **Example**: `mulle-sde debug -- -h --verbose` (pass -h --verbose to your program)
```

### Environment Control Variables

```
- MULLE_SDE_DEBUGGERS
  - **Default**: "mulle-gdb:gdb:lldb"
  - **Set with**: `export MULLE_SDE_DEBUGGERS="lldb:gdb:custom-debugger"`
  - **Use case**: When you have custom debuggers or want to change search order
  - **Behavior**: Colon-separated list of debugger names to search for

- MULLE_SDE_DEBUGGER_CHOICE
  - **Default**: None (user-selected)
  - **Set with**: `mulle-sde env --this-user set MULLE_SDE_DEBUGGER_CHOICE lldb`
  - **Use case**: Persist debugger choice across sessions
  - **Behavior**: Saves last selected debugger to avoid selection prompts

- MULLE_EXE_EXTENSION
  - **Default**: Platform-specific (empty on Unix, ".exe" on Windows)
  - **Set with**: Automatically determined by mulle-sde
  - **Use case**: Cross-platform debugging support
  - **Behavior**: Appended to debugger executable name

- MULLE_ENV_VAR_DIR
  - **Default**: Project-specific environment directory
  - **Set with**: Managed by mulle-env
  - **Use case**: Custom environment variable injection
  - **Behavior**: Location for custom-post-environment.* files

- MULLE_ENV_PID
  - **Default**: Process ID of mulle-sde
  - **Set with**: Automatically by mulle-env
  - **Use case**: Unique environment file identification
  - **Behavior**: Used to create unique environment files

- MULLE_VIRTUAL_ROOT
  - **Default**: Project root when in mulle-sde project
  - **Set with**: Automatically by mulle-sde
  - **Use case**: Project context detection
  - **Behavior**: Enables project-specific paths (KITCHEN_DIR, etc.)
```

## Hidden Behaviors Explained

### Automatic Debugger Discovery
The system searches for debuggers in this exact order from MULLE_SDE_DEBUGGERS:
1. **mulle-gdb** - Custom gdb build with mulle-objc support
2. **gdb** - Standard GNU debugger
3. **lldb** - LLVM debugger (macOS default)

**Example search behavior:**
```bash
# With MULLE_SDE_DEBUGGERS="lldb:gdb:custom-debugger"
# System will use first available in PATH:
# 1. lldb (if exists)
# 2. gdb (if lldb missing)
# 3. custom-debugger (if both above missing)
```

### Environment Variable Inheritance
When running without `--no-mudo`, the debugger inherits a complete mulle-sde environment:

**Automatic environment variables:**
- `ADDICTION_DIR` - Path to addiction dependencies
- `DEPENDENCY_DIR` - Path to main dependencies
- `KITCHEN_DIR` - Build output directory
- `STASH_DIR` - Source tree stash location

**Custom environment injection:**
```bash
# Create custom environment file
cat > "${MULLE_ENV_VAR_DIR}/custom-post-environment.$$" << EOF
CUSTOM_DEBUG=1
VERBOSE_LOGGING=1
EOF

# These variables will be available during debugging
mulle-sde debug myapp
```

### Objective-C Runtime Debugging
The system automatically configures Objective-C debugging based on debug environment selection:

**Zombie mode (default):**
- `NSZombieEnabled=YES`
- `NSDeallocateZombies=YES`

**Enhanced zombie mode:**
- `MULLE_OBJC_TRACE_ZOMBIE=YES`

**Leak detection mode:**
- `MULLE_TESTALLOCATOR=3`
- `MULLE_OBJC_TRACE_LEAK=YES`

### Configuration Resolution
The debug command automatically resolves executable paths:

**Executable discovery order:**
1. Explicit `--executable` path
2. Command-line argument as preferred name
3. Most recent executable in build directory
4. Interactive selection if multiple exist

**Configuration cascading:**
```bash
# Resolution order for Debug configuration:
# 1. --configuration Debug (explicit)
# 2. --debug (shortcut)
# 3. Default project configuration
# 4. "Debug" fallback
```

### IDE Integration Generation
The command can generate configuration for popular IDEs:

**Sublime Text debug configuration:**
```bash
# Generate .sublime-project debug settings
mulle-sde debug sublime-debug > .sublime-project.debug
```

**VS Code launch.json generation:**
```bash
# Generate VS Code debug configuration
mulle-sde debug vscode-debug > .vscode/launch.json
```

## Practical Examples

### Common Hidden Usage Patterns

**Debug with custom debugger:**
```bash
# Use custom debugger
export MULLE_SDE_DEBUGGERS="my-custom-debugger:gdb"
mulle-sde debug myapp

# Override for single session
MULLE_SDE_DEBUGGERS="lldb" mulle-sde debug myapp
```

**Performance debugging without runtime checks:**
```bash
# Disable zombie detection for performance testing
mulle-sde debug --no-zombie --configuration Release myapp -- --benchmark
```

**Memory debugging session:**
```bash
# Full memory debugging with leak detection
mulle-sde debug --leak --configuration Debug myapp
```

**Environment isolation:**
```bash
# Debug with minimal environment (troubleshooting env issues)
mulle-sde debug --restrict --no-mudo myapp
```

**Multi-executable projects:**
```bash
# Debug specific executable by name
mulle-sde debug --executable build/Debug/server myapp

# Debug with program arguments
mulle-sde debug -- server --port 8080 --debug
```

### Environment Variable Overrides

**Custom debugger chain:**
```bash
# Add valgrind to debugger chain
export MULLE_SDE_DEBUGGERS="valgrind:gdb:lldb"

# Use valgrind for memory debugging
mulle-sde debug --select  # Choose valgrind from menu
```

**Persistent debugger choice:**
```bash
# Set and forget debugger choice
mulle-sde env --this-user set MULLE_SDE_DEBUGGER_CHOICE lldb

# Now always uses lldb without prompting
mulle-sde debug myapp
```

**Cross-platform debugging:**
```bash
# Windows debugging with specific extension
MULLE_EXE_EXTENSION=.exe mulle-sde debug myapp.exe

# macOS universal binary debugging
mulle-sde debug --sdk macosx myapp
```

### Advanced Debugging Scenarios

**Debugging build artifacts:**
```bash
# Debug specific build configuration
mulle-sde debug --configuration RelWithDebInfo myapp

# Debug with custom SDK
mulle-sde debug --sdk iphoneos --configuration Debug myapp
```

**IDE integration workflow:**
```bash
# Setup VS Code debugging
mkdir -p .vscode
mulle-sde debug vscode-debug > .vscode/launch.json

# Setup Sublime Text debugging
mulle-sde debug sublime-debug > sublime-project.debug
```

**Custom environment debugging:**
```bash
# Create custom debug environment
mulle-sde env --this-user set DEBUG_MODE extensive

# Debug with custom environment
mulle-sde debug -- myapp --debug-level=verbose
```

## Troubleshooting

### When to Use Hidden Options

**Debugger not found:**
```bash
# Check available debuggers
which gdb lldb mulle-gdb

# Install missing debugger or use alternative
export MULLE_SDE_DEBUGGERS="lldb:gdb"
```

**Performance issues during debugging:**
```bash
# Disable runtime debugging features
mulle-sde debug --no-zombie --configuration Release myapp

# Use release build for performance testing
mulle-sde debug --release myapp
```

**Environment variable conflicts:**
```bash
# Debug without mulle-sde environment
mulle-sde debug --no-mudo myapp

# Debug with restricted environment
mulle-sde debug --restrict myapp
```

**Multiple executables confusion:**
```bash
# Explicitly specify executable
mulle-sde debug --executable build/Debug/myapp myapp

# Force reselection of executable
mulle-sde debug --select
```

### Debugging Environment Issues

**Check environment setup:**
```bash
# Verify environment variables
mulle-sde env --this-user list | grep DEBUG

# Check debugger preference
mulle-sde env --this-user get MULLE_SDE_DEBUGGER_CHOICE
```

**Test debugger availability:**
```bash
# Check if debugger is in PATH
which $(mulle-sde env --this-user get MULLE_SDE_DEBUGGER_CHOICE)

# List available debuggers
echo $MULLE_SDE_DEBUGGERS | tr ':' '\n' | while read debugger; do
    if which "$debugger" > /dev/null; then
        echo " $debugger available"
    else
        echo " $debugger missing"
    fi
done
```

**Verbose debugging output:**
```bash
# Enable verbose logging
export MULLE_FLAG_LOG_FLUFF=YES
mulle-sde debug -- myapp

# Check what environment is being set
mulle-sde env
```