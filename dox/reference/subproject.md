# mulle-sde subproject - Complete Reference

## Quick Start

The `mulle-sde subproject` command manages subprojects within a mulle-sde project. Subprojects are contained subdirectories with their own isolated development environments that cannot be built independently but integrate seamlessly into the main project's build system.

## Overview

Subprojects enable modular development by allowing you to break large projects into smaller, manageable components while maintaining a unified build process. Unlike dependencies, subprojects are **not standalone projects** - they inherit configuration from the parent project and are built as part of the main project's craft process.

**Key Characteristics:**
- Contained within the main project directory structure
- Have their own `.mulle/share/sde` environment
- Inherit extensions and environment style from parent
- Cannot be built independently
- Integrate into the main project's craft order
- Automatically excluded from main project pattern matching

## All Available Options

### Basic Options (in usage)

```
-s <subproject> : choose subproject to run command in
-h              : show usage information
```

### Subproject Commands

#### Core Commands
- **add**: Add an existing subproject to the project
- **init**: Create and initialize a new subproject
- **remove**: Remove a subproject from the project
- **list**: List all subprojects (default)
- **move**: Change build order position of subproject
- **enter**: Open subshell for subproject

#### Configuration Commands
- **set**: Modify subproject settings
- **get**: Retrieve subproject settings
- **mark/unmark**: Add or remove marks from subprojects

#### Advanced Commands
- **map**: Execute commands across all subprojects
- **dependency**: Run dependency commands in subproject context
- **environment**: Run environment commands in subproject context
- **patternfile**: Run patternfile commands in subproject context

### Advanced Options (hidden)

#### Environment Control Flags
- **--existing**: Skip initialization for existing projects (used with `init`)
- **--append**: Append values instead of replacing (used with `set`)
- **--style <style>**: Override inherited environment style (used with `init`)
- **--meta <meta>**: Specify meta extension explicitly (used with `init`)

#### Map Mode Options (internal)
- **lenient**: Continue execution even if subprojects fail
- **parallel**: Execute commands in parallel across subprojects
- **no-env**: Skip environment setup when executing commands

### Environment Variables

#### Subproject Configuration
- **MULLE_VIRTUAL_ROOT**: Root directory of the main project
- **MULLE_SDE_VAR_DIR**: Variable directory for subproject state
- **PARENT_PROJECT_NAME**: Name of the parent project (inherited)
- **PARENT_PROJECT_TYPE**: Type of the parent project (inherited)
- **PARENT_PROJECT_DIALECT**: Dialect of the parent project (inherited)
- **PARENT_PROJECT_EXTENSIONS**: Extensions from parent (inherited)
- **PARENT_PROJECT_LANGUAGE**: Language from parent (inherited)

#### Build Integration
- **MULLE_SOURCETREE**: Path to sourcetree executable
- **MULLE_MATCH**: Path to match executable
- **MULLE_ENV**: Path to env executable

## Hidden Behaviors Explained

### Automatic Pattern File Management

When subprojects are added or removed, mulle-sde automatically updates the `30-subproject--none` ignore patternfile to exclude subproject directories from the main project's pattern matching. This prevents conflicts between main project and subproject file detection.

**Internal Process:**
1. Subproject paths are collected via `sde::subproject::get_addresses()`
2. Pattern file `30-subproject--none` is regenerated with subproject paths
3. Each subproject path is added as `subproject-name/` pattern

### Build Order Integration

Subprojects participate in the main project's craft order based on their position in the sourcetree. The `move` command allows adjusting this order:

- **top**: Builds first (dependencies for other components)
- **bottom**: Builds last (depends on other components)
- **up/down**: Move relative to current position

### Environment Isolation

Each subproject runs in its own environment context:

```bash
# Environment variables for subproject execution
MULLE_VIRTUAL_ROOT="/path/to/subproject"
PROJECT_NAME="subproject-name"
PROJECT_TYPE="inherited-from-parent"
```

### Configuration Inheritance

During `subproject init`, the following are inherited from the parent:
- Extensions (unless overridden with `-m`)
- Environment style (unless overridden with `-s`)
- Build configuration patterns
- Platform settings

## Practical Examples

### Basic Subproject Management

#### Creating a New Subproject
```bash
# Initialize a library subproject
mulle-sde subproject init -d src/mylib library

# Create with custom style
mulle-sde subproject init -d src/gui -s "foundation/objc-developer" library

# Add to existing directory
mulle-sde subproject init -d src/existing --existing
```

#### Adding Existing Subprojects
```bash
# Add existing directory as subproject
mulle-sde subproject add src/mylib

# Add multiple subprojects
mulle-sde subproject add src/core
mulle-sde subproject add src/ui
mulle-sde subproject add src/tests
```

#### Listing and Managing Subprojects
```bash
# List all subprojects
mulle-sde subproject list

# List with detailed information
mulle-sde subproject list --format '%a;%m;%i={aliases,,-------};%i={include,,-------}\n'

# Change build order
mulle-sde subproject move src/core top
mulle-sde subproject move src/tests bottom
```

### Advanced Configuration

#### Platform-Specific Configuration
```bash
# Exclude subproject from specific platforms
mulle-sde subproject set src/windows-only platform-excludes "darwin,linux"

# Add platform aliases
mulle-sde subproject set src/mylib aliases "core,base"

# Retrieve configuration
mulle-sde subproject get src/mylib platform-excludes
```

#### Cross-Subproject Operations
```bash
# Execute commands across all subprojects
mulle-sde subproject map craft

# Parallel execution (advanced)
mulle-sde subproject map --parallel craft

# Lenient mode (continue on errors)
mulle-sde subproject map --lenient test run

# Skip environment setup
mulle-sde subproject map --no-env status
```

#### Subproject-Specific Commands
```bash
# Enter subproject environment
mulle-sde subproject enter -s src/mylib

# Run dependency commands in subproject
mulle-sde subproject dependency -s src/mylib list

# Update subproject patterns
mulle-sde subproject patternfile -s src/mylib list

# Manage subproject environment
mulle-sde subproject environment -s src/mylib list
```

### Integration with Main Project Workflow

#### Complete Development Cycle
```bash
# 1. Initialize project with subprojects
mulle-sde init -d myproject executable
mulle-sde subproject init -d src/core library
mulle-sde subproject init -d src/ui library

# 2. Add files to subprojects
mulle-sde add -s src/core src/core/myclass.c
mulle-sde add -s src/ui src/ui/gui.c

# 3. Reflect changes across all subprojects
mulle-sde reflect
mulle-sde subproject map reflect

# 4. Build everything
mulle-sde craft

# 5. Test subprojects
mulle-sde subproject map test run
```

#### Nested Subproject Structure
```bash
# Create complex nested structure
mulle-sde subproject init -d src/network/http library
mulle-sde subproject init -d src/network/tcp library
mulle-sde subproject init -d src/ui/widgets library

# Manage build dependencies
mulle-sde subproject move src/network/tcp top
mulle-sde subproject move src/network/http up
```

### Environment Variable Overrides

#### Custom Build Configuration
```bash
# Override parent settings for specific subproject
export MULLE_SDE_VAR_DIR="/custom/var"
mulle-sde subproject craft -s src/mylib

# Use different sourcetree for subproject operations
export MULLE_SOURCETREE="/usr/local/bin/mulle-sourcetree"
mulle-sde subproject list

# Debug subproject operations
export MULLE_TECHNICAL_FLAGS="-v"
mulle-sde subproject map reflect
```

## Troubleshooting

### Common Issues and Solutions

#### Subproject Not Found
```bash
# Check if subproject is properly registered
mulle-sde subproject list

# Verify directory structure
ls -la src/mylib/.mulle/share/sde/

# Re-register if needed
mulle-sde subproject remove src/mylib
mulle-sde subproject add src/mylib
```

#### Build Order Problems
```bash
# Check current order
mulle-sde craftorder list

# Adjust subproject position
mulle-sde subproject move src/dependency top
mulle-sde craft
```

#### Pattern File Conflicts
```bash
# Force pattern file update
mulle-sde subproject update-patternfile

# Check generated patterns
cat .mulle/var/match/patternfile/30-subproject--none

# Manual pattern adjustment
mulle-match patternfile edit 30-subproject--none
```

#### Environment Issues
```bash
# Debug subproject environment
mulle-sde subproject environment -s src/mylib list

# Reset subproject environment
mulle-sde subproject environment -s src/mylib reset

# Check parent inheritance
mulle-env list | grep PARENT_
```

### When to Use Hidden Options

#### Use `--existing` when:
- Directory already contains a mulle-sde project
- You want to preserve existing configuration
- Migrating existing code into subproject structure

#### Use `--append` when:
- Adding additional platform excludes
- Extending alias lists
- Preserving existing configuration while adding new values

#### Use parallel execution when:
- Multiple independent subprojects
- Performance optimization needed
- CI/CD pipeline optimization

#### Use lenient mode when:
- Testing across multiple subprojects
- Some subprojects may have temporary issues
- Development environment exploration

### Debugging Subproject Operations

```bash
# Verbose subproject operations
MULLE_TECHNICAL_FLAGS="-v" mulle-sde subproject map craft

# Check subproject registration details
mulle-sourcetree list --marks "dependency,no-mainproject,no-delete" --nodetypes local

# Verify environment isolation
mulle-sde subproject environment -s src/mylib list | grep -E "(PROJECT_|MULLE_)"

# Test subproject build in isolation
mulle-sde craft -s src/mylib
```

## Cross-References

- **mulle-sde dependency**: Related commands for managing external dependencies
- **mulle-sde craft**: Main build process that includes subprojects
- **mulle-sde reflect**: Updates build files across subprojects
- **mulle-sourcetree**: Underlying tool for managing project structure
- **mulle-match**: Pattern matching system for subproject exclusion