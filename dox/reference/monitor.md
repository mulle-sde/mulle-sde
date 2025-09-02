# mulle-sde monitor - Complete Reference

## Quick Start
`mulle-sde monitor` starts continuous filesystem monitoring that automatically triggers build system updates and project reflection based on file changes.

## All Available Options

### Basic Options (in usage)
```
-h  : show this usage
```

### Advanced Options (hidden)

#### Environment Variable Overrides
- **MULLE_MONITOR**: Override the default mulle-monitor executable
  - **Default**: `mulle-monitor`
  - **Set with**: `export MULLE_MONITOR=/path/to/custom/mulle-monitor`
  - **Use case**: When using a development version of mulle-monitor

- **MULLE_TECHNICAL_FLAGS**: Technical flags passed to mulle-monitor
  - **Default**: System-specific
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="-v -vv"
  - **Use case**: Debugging or passing specific technical options

#### Monitor Control Variables
- **MULLE_USAGE_NAME**: Controls the displayed command name in help
  - **Default**: `mulle-sde`
  - **Set with**: `export MULLE_USAGE_NAME="my-custom-sde"
  - **Use case**: Custom wrappers or branded installations

## Hidden Behaviors Explained

### Monitor Integration Architecture

#### Underlying System
**Behavior**: `mulle-sde monitor` is a thin wrapper around `mulle-monitor`
- **Mechanism**: Delegates to mulle-monitor with project-specific configuration
- **Location**: Uses system mulle-monitor or custom via MULLE_MONITOR
- **Integration**: Automatically inherits mulle-sde project context

#### Patternfile Discovery
**Behavior**: Automatic discovery of monitoring patterns
- **Location**: Project `.mulle/share/mulle-monitor/patternfiles/`
- **Generation**: Created automatically during project setup
- **Patterns**: Includes source files, headers, CMakeLists.txt, and dependency files
- **Customization**: Editable via `mulle-sde patternfile` commands

#### Callback Registration System
**Behavior**: Pre-configured callbacks for standard mulle-sde operations
- **Callbacks**: `source`, `sourcetree`, `craft`
- **Tasks**: Each callback maps to specific mulle-sde operations
- **Storage**: Stored in `.mulle/share/mulle-monitor/callbacks/`
- **Persistence**: Survives project rebuilds

### Continuous Build Integration

#### Automatic Reflection Chain
**Behavior**: File changes trigger complete reflection cascade
- **Trigger**: Source file modifications (*.c, *.h, *.m, etc.)
- **Chain**: Filesystem ’ Callback ’ Task ’ Reflect ’ Craft
- **Coalescence**: Multiple rapid changes are batched (default 1s delay)
- **Parallelism**: Subproject reflection runs in parallel by default

#### Build System Regeneration
**Behavior**: Automatic CMakeLists.txt and build file updates
- **Trigger**: New source files, deleted files, or dependency changes
- **Scope**: Affects main project and all dependent subprojects
- **Validation**: Build files validated before regeneration
- **Backup**: Previous versions backed up automatically

#### Header File Synchronization
**Behavior**: Automatic header file management across dependencies
- **Detection**: Changes in public headers
- **Propagation**: Updates include paths in dependent projects
- **Validation**: Checks for circular dependencies
- **Cleanup**: Removes stale header references

## Practical Examples

### Basic Monitoring Setup

#### Start Continuous Monitoring
```bash
# Start monitoring with default settings
mulle-sde monitor

# Monitor in background
mulle-sde monitor &

# Monitor with verbose output
MULLE_TECHNICAL_FLAGS="-v" mulle-sde monitor
```

#### Development Workflow Integration
```bash
# Start monitoring in one terminal
mulle-sde monitor

# In another terminal, edit files
vim src/main.c
# Changes automatically trigger reflection and craft

# Add new source file
mulle-sde add src/new_module.c
# Monitor detects and processes automatically
```

### Advanced Monitoring Patterns

#### Custom Monitoring Scope
```bash
# Monitor specific directories only
mulle-monitor patternfile create my-scope "src/core/**"
mulle-sde monitor

# Exclude certain files from monitoring
echo "build/**" > .mulle/share/mulle-monitor/patternfiles/exclude
```

#### Custom Callback Tasks
```bash
# Create custom monitoring task
mulle-monitor task create quick-reflect "mulle-sde reflect --optimistic"

# Create custom callback that triggers on specific patterns
mulle-monitor callback create my-callback "echo quick-reflect"

# Add to monitoring workflow
export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree quick-reflect"
mulle-sde monitor
```

#### Multi-Project Monitoring
```bash
# Monitor main project and dependencies
mulle-sde monitor --recurse

# Monitor specific subprojects only
mulle-sde monitor project1 project2

# Monitor with different configurations per project
MULLE_SOURCETREE_CONFIG_NAME=debug mulle-sde monitor
```

### Integration with Development Tools

#### Editor Integration
```bash
# Vim integration example
# In .vimrc:
# autocmd BufWritePost *.c silent !mulle-sde reflect --optimistic

# VS Code integration
# In tasks.json:
# {
#   "label": "mulle-sde monitor",
#   "type": "shell",
#   "command": "mulle-sde monitor",
#   "isBackground": true
# }
```

#### CI/CD Pipeline Integration
```bash
# CI script with monitoring
#!/bin/bash
# Start background monitoring
mulle-sde monitor &
MONITOR_PID=$!

# Run tests that modify files
touch src/test_trigger.c
sleep 2  # Allow monitoring to process

# Stop monitoring
kill $MONITOR_PID
```

### Environment-Specific Monitoring

#### Development Environment
```bash
# ~/.bashrc additions for mulle-sde development
export MULLE_TECHNICAL_FLAGS="-v"
export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree"

# Alias for quick monitoring
alias msmon='mulle-sde monitor'
```

#### Production Build Environment
```bash
# Production monitoring setup
export MULLE_MONITOR=/opt/mulle/bin/mulle-monitor
export MULLE_TECHNICAL_FLAGS="-s"  # Silent mode
mulle-sde monitor
```

#### Cross-Platform Configuration
```bash
# Platform-specific monitoring
if [[ "$OSTYPE" == "darwin"* ]]; then
    export MULLE_TECHNICAL_FLAGS="--sleep 2"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export MULLE_TECHNICAL_FLAGS="--sleep 1"
fi
mulle-sde monitor
```

### Advanced Monitoring Scenarios

#### Custom Build Triggers
```bash
# Create task for specific build target
mulle-monitor task create build-tests "mulle-sde test craft"

# Create callback for test file changes
mulle-monitor callback create test-monitor "grep -q 'test.*\\.c$' && echo build-tests"

# Integrate with monitoring
mulle-sde monitor
```

#### Dependency Change Detection
```bash
# Monitor dependency configuration changes
mulle-monitor patternfile create deps "*sourcetree*" "*dependency*"

# Create specialized callback
mulle-monitor task create rebuild-deps "mulle-sde dependency refresh && mulle-sde craft"
mulle-monitor callback create deps-callback "echo rebuild-deps"
```

#### Performance Optimization
```bash
# Optimistic monitoring (faster for large projects)
mulle-sde monitor --optimistic

# Reduce monitoring overhead
export MULLE_TECHNICAL_FLAGS="--sleep 3 -s"
mulle-sde monitor

# Monitor specific file types only
echo "*.c" > .mulle/share/mulle-monitor/patternfiles/c-only
echo "*.h" >> .mulle/share/mulle-monitor/patternfiles/c-only
```

### Troubleshooting

#### Monitor Not Starting
```bash
# Check if mulle-monitor is available
which mulle-monitor

# Check with custom path
export MULLE_MONITOR=/usr/local/bin/mulle-monitor
mulle-sde monitor

# Verify project setup
mulle-sde status
```

#### Monitor Not Detecting Changes
```bash
# Check current patterns
mulle-monitor patternfile list

# Verify patternfile content
mulle-monitor patternfile cat filesystem

# Test manual trigger
mulle-monitor callback run filesystem

# Reset monitoring state
mulle-monitor task reset filesystem
mulle-monitor task reset sourcetree
```

#### Monitor Overwhelming System
```bash
# Reduce monitoring sensitivity
export MULLE_TECHNICAL_FLAGS="--sleep 5"
mulle-sde monitor

# Monitor fewer files
mulle-monitor patternfile create minimal "src/**"

# Use manual mode instead
mulle-sde reflect  # Run manually when needed
```

#### Cross-Platform Issues
```bash
# macOS specific
export MULLE_TECHNICAL_FLAGS="--sleep 2"

# Linux specific  
export MULLE_TECHNICAL_FLAGS="--sleep 1"

# Windows (WSL)
export MULLE_TECHNICAL_FLAGS="--sleep 3"
```

### Debugging Monitor Behavior

#### Verbose Monitoring
```bash
# Full debug output
export MULLE_TECHNICAL_FLAGS="-vvv"
mulle-sde monitor

# Monitor with callback tracing
mulle-monitor callback run filesystem -v

# Check task execution order
mulle-monitor task ps
```

#### Pattern Debugging
```bash
# Test pattern matching
mulle-match find "*.c" src/

# Check what's being monitored
mulle-monitor patternfile list
mulle-monitor patternfile cat filesystem

# Create test pattern
mulle-monitor patternfile create test "test/**"
```

#### Integration Testing
```bash
# Test complete monitoring cycle
touch src/test_file.c
sleep 2
mulle-monitor task status

# Verify reflection occurred
cat etc/reflect
ls -la CMakeLists.txt
```

## Environment Variable Reference

### Core Monitoring Variables
```bash
# Override mulle-monitor executable
export MULLE_MONITOR=/custom/path/mulle-monitor

# Technical flags for mulle-monitor
export MULLE_TECHNICAL_FLAGS="-v --sleep 2"

# Usage name in help text
export MULLE_USAGE_NAME="my-sde"
```

### Project-Specific Variables
```bash
# Project source directory
export PROJECT_SOURCE_DIR=src

# Reflect callbacks
export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree"

# Configuration name
export MULLE_SOURCETREE_CONFIG_NAME=debug
```

### Debugging Variables
```bash
# Enable debug logging
export MULLE_FLAG_LOG_EXEKUTOR=YES
export MULLE_TECHNICAL_FLAGS="-vvv"

# Force operations
export MULLE_FLAG_MAGNUM_FORCE=YES
```

## Best Practices

### Development Workflow
1. **Start monitoring early**: Begin monitoring at project start
2. **Use optimistic mode**: For faster development cycles
3. **Commit patternfiles**: Include .mulle/share/mulle-monitor/ in git
4. **Test changes**: Verify monitoring works after major refactoring

### Team Collaboration
1. **Standardize configurations**: Ensure consistent monitoring across team
2. **Document custom callbacks**: Share custom monitoring tasks
3. **Use environment files**: Store monitoring preferences in .mulle/env/
4. **Handle merge conflicts**: Coordinate when multiple developers change patterns

### Performance Optimization
1. **Limit scope**: Monitor only necessary directories
2. **Adjust coalescence**: Increase sleep time for less frequent builds
3. **Use selective monitoring**: Monitor specific file types during focused work
4. **Cache optimization**: Leverage task persistence for large projects