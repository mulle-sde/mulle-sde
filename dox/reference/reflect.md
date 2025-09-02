# mulle-sde reflect - Complete Reference

## Quick Start
`mulle-sde reflect` automatically updates build system files and headers based on changes in your source files and dependency configuration.

## All Available Options

### Basic Options (in usage)
```
--craft       : craft after reflect
--if-needed   : reflect if there was a change in the sourcetree name
--no-recurse  : do not recurse into subprojects
--optimistic  : run only those tasks that are needed
--serial      : don't reflect subprojects in parallel
```

### Hidden/Advanced Options

#### Task Serialization Control
- **Callback name with `@` suffix**: Forces serial execution of specific callbacks
  - **When to use**: When parallel execution causes race conditions or conflicts
  - **Example**: `mulle-sde reflect source@ sourcetree@`  
  - **Side effects**: Appends '@' to task names, forces sequential processing

### Environment Control

#### Core Environment Variables
- **MULLE_SDE_REFLECT_CALLBACKS**: Defines which callbacks to run during reflect
  - **Default**: `"source sourcetree"`
  - **Set with**: `export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree custom-task"`
  - **Use case**: When you have custom reflection tasks or want to skip default ones

- **MULLE_SDE_REFLECT_BEFORE_CRAFT**: Forces reflect before craft operations
  - **Default**: `NO`
  - **Set with**: `export MULLE_SDE_REFLECT_BEFORE_CRAFT=YES`
  - **Use case**: When you need to ensure reflection happens before every build

#### Project Identification Variables
- **PROJECT_NAME**: Name of the current project
  - **Default**: Determined from project directory
  - **Set with**: Automatically set by mulle-sde
  - **Use case**: Used for generating build files and identifying project context

- **PROJECT_SOURCE_DIR**: Directory containing source files
  - **Default**: `src`
  - **Set with**: `export PROJECT_SOURCE_DIR=source`
  - **Use case**: When source files are in non-standard locations

- **PROJECT_UPCASE_IDENTIFIER**: Uppercase identifier for project
  - **Default**: Auto-generated from PROJECT_NAME
  - **Use case**: Used in environment variable naming for multi-config projects

- **MULLE_SOURCETREE_CONFIG_NAME**: Current sourcetree configuration
  - **Default**: `config`
  - **Set with**: `export MULLE_SOURCETREE_CONFIG_NAME=debug`
  - **Use case**: Managing different build configurations (debug, release, etc.)

- **MULLE_SOURCETREE_CONFIG_NAME_<UPPERCASE_PROJECT>**: Project-specific config override
  - **Default**: Based on PROJECT_UPCASE_IDENTIFIER
  - **Set with**: `export MULLE_SOURCETREE_CONFIG_NAME_MYPROJECT=release`
  - **Use case**: When different projects need different default configurations

#### Technical Control Variables
- **MULLE_FLAG_MAGNUM_FORCE**: Force execution of all reflection tasks
  - **Default**: Not set
  - **Set with**: `export MULLE_FLAG_MAGNUM_FORCE=YES`
  - **Use case**: When you want to bypass optimization checks and force full reflection

- **MULLE_TECHNICAL_FLAGS**: Technical flags passed to underlying tools
  - **Default**: System-specific
  - **Use case**: Debugging or passing specific technical options

## Hidden Behaviors Explained

### Sourcetree Change Detection
**Behavior**: Automatic detection of sourcetree configuration changes
- **Mechanism**: Maintains a reflection state file in `etc/reflect`
- **Content**: Stores the last reflected sourcetree configuration name
- **Trigger**: Changes in `MULLE_SOURCETREE_CONFIG_NAME` or equivalent
- **Example**: 
  ```bash
  # Initial state (config)
  mulle-sde reflect
  
  # Switch to debug config
  mulle-sde config switch debug
  mulle-sde reflect  # Will detect change and re-reflect
  ```

### Multi-Sourcetree Management
**Behavior**: Projects with multiple sourcetree configurations track which was last reflected
- **File location**: `etc/reflect` (relative to project root)
- **Format**: Single line with configuration name
- **Git integration**: File should be committed to git for team consistency
- **Example**:
  ```bash
  # After reflecting with different configs
  cat etc/reflect  # Shows: debug
  ```

### Reflection Task Persistence
**Behavior**: Tasks remember their completion status to avoid redundant work
- **Storage**: Internal mulle-monitor task tracking
- **Override**: `MULLE_FLAG_MAGNUM_FORCE=YES` bypasses persistence
- **Reset**: Tasks can be reset with `mulle-monitor task reset <taskname>`

### Subproject Reflection Cascade
**Behavior**: Reflection cascades through dependency projects
- **Mechanism**: `sde::subproject::map` function handles subproject traversal
- **Parallel vs Serial**: Controlled by `--serial` flag
- **Command propagation**: `mulle-sde reflect <options>` is run in each subproject
- **Example**:
  ```bash
  # Reflect main project and all dependencies in parallel
  mulle-sde reflect
  
  # Reflect only main project
  mulle-sde reflect --no-recurse
  
  # Reflect serially through dependencies
  mulle-sde reflect --serial
  ```

### Optimistic Execution Mode
**Behavior**: `--optimistic` flag runs only tasks that are actually needed
- **Detection**: Checks task status before execution
- **Performance**: Significant speedup for large projects with minimal changes
- **Limitation**: May miss edge cases where manual force is needed
- **Example**:
  ```bash
  # Fast reflect - only changed tasks
  mulle-sde reflect --optimistic
  
  # Force all tasks
  MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde reflect
  ```

## Practical Examples

### Common Hidden Usage Patterns

#### Custom Reflection Tasks
```bash
# Create custom reflection task
mulle-monitor task create my-custom-reflect "mulle-sde craftinfo regenerate"

# Use custom task alongside defaults
export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree my-custom-reflect"
mulle-sde reflect

# Run only custom task
mulle-sde reflect my-custom-reflect
```

#### Configuration-Specific Reflection
```bash
# Set up different configurations
mulle-sde config create debug
mulle-sde config create release

# Reflect with specific configuration
export MULLE_SOURCETREE_CONFIG_NAME=debug
mulle-sde reflect

# Switch and reflect release
mulle-sde config switch release
mulle-sde reflect
```

#### Forced Reflection Scenarios
```bash
# Force reflection despite no detected changes
MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde reflect

# Force reflection before craft (useful in CI)
export MULLE_SDE_REFLECT_BEFORE_CRAFT=YES
mulle-sde craft
```

#### Subproject Control
```bash
# Reflect without touching dependencies
mulle-sde reflect --no-recurse

# Reflect specific subproject
mulle-sde reflect --no-recurse source

# Force serial processing for debugging
mulle-sde reflect --serial --verbose
```

#### Task-Specific Reflection
```bash
# Run only source reflection
mulle-sde reflect source

# Run only sourcetree reflection
mulle-sde reflect sourcetree

# Run with serial execution for specific tasks
mulle-sde reflect source@ sourcetree
```

### Environment Variable Overrides

#### Development Setup
```bash
# ~/.bashrc or ~/.zshrc additions
export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree prebuild"
export MULLE_SDE_REFLECT_BEFORE_CRAFT=YES
export PROJECT_SOURCE_DIR=src/main
```

#### CI/CD Configuration
```bash
# CI script with forced reflection
#!/bin/bash
export MULLE_FLAG_MAGNUM_FORCE=YES
export MULLE_SDE_REFLECT_BEFORE_CRAFT=YES
mulle-sde craft --release
```

#### Multi-Project Environment
```bash
# Project-specific overrides
export MULLE_SOURCETREE_CONFIG_NAME_MYLIB=release
export MULLE_SOURCETREE_CONFIG_NAME_MYAPP=debug
mulle-sde reflect  # Uses appropriate config for each project
```

## Troubleshooting

### When to Use Hidden Options

#### "Reflect isn't picking up my changes"
- **Problem**: Reflection tasks are being skipped due to optimization
- **Solution**: Use `MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde reflect`
- **Root cause**: Task persistence thinks work is already done

#### "Subproject reflection is failing"
- **Problem**: Parallel execution causing race conditions
- **Solution**: `mulle-sde reflect --serial`
- **Alternative**: Use `@` suffix for specific problem tasks: `mulle-sde reflect source@`

#### "Wrong configuration being reflected"
- **Problem**: `etc/reflect` file has stale configuration
- **Solution**: `rm etc/reflect && mulle-sde reflect`
- **Prevention**: Ensure `etc/reflect` is committed to git

#### "Custom reflection tasks not running"
- **Problem**: `MULLE_SDE_REFLECT_CALLBACKS` not set or overwritten
- **Solution**: Check current value with `env | grep MULLE_SDE_REFLECT_CALLBACKS`
- **Fix**: Set explicitly: `export MULLE_SDE_REFLECT_CALLBACKS="source sourcetree mytask"`

#### "Reflection taking too long"
- **Problem**: All tasks running regardless of need
- **Solution**: Use optimistic mode: `mulle-sde reflect --optimistic`
- **Advanced**: Use `--if-needed` for even more selective execution

#### "Environment variables not taking effect"
- **Problem**: Variables set in wrong context
- **Solution**: 
  ```bash
  # Check current environment
  mulle-sde env list | grep REFLECT
  
  # Set persistent environment
  mulle-sde env set MULLE_SDE_REFLECT_CALLBACKS "source sourcetree custom"
  ```

### Debugging Reflection Issues
```bash
# Enable verbose logging
mulle-sde reflect --verbose

# Check task status
mulle-monitor task status

# Reset specific task
mulle-monitor task reset source

# Force specific task
mulle-sde reflect source

# Check reflection history
cat etc/reflect 2>/dev/null || echo "No reflection history"
```