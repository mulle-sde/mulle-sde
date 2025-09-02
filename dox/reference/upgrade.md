# mulle-sde upgrade - Complete Reference

## Quick Start
Upgrade your mulle-sde installation and project files to the latest version while preserving your source code and custom configurations.

```bash
# Basic upgrade (safe - preserves project files)
mulle-sde upgrade

# Upgrade with cleanup of build artifacts
mulle-sde upgrade --clean

# Upgrade project template files (use with caution)
mulle-sde upgrade project
```

## All Available Options

### Basic Options (in usage)
- `--clean`: Clean tidy, mirrors, archives before upgrading
- `--project-file <file>`: Update a single project file to newest version
- `--no-parallel`: Do not upgrade projects in parallel
- `--no-project`: Do not upgrade the project
- `--no-subprojects`: Do not upgrade subprojects
- `--no-test`: Do not upgrade a test folder if it exists

### Advanced Options (hidden)
- `--serial`: Alias for `--no-parallel` (same functionality)
- `--no-recurse`: Alias for `--no-subprojects` (same functionality)

### Environment Variables
- `MULLE_SDE_TEST_PATH`: Controls which directories are checked for test upgrades
  - **Default**: `test` (single directory named "test")
  - **Set with**: `export MULLE_SDE_TEST_PATH="test:tests:unittests"`
  - **Use case**: When your tests are in non-standard directories

- `MULLE_VIRTUAL_ROOT`: Automatically set to current working directory during subproject upgrades
  - **Default**: Current directory (`pwd -P`)
  - **Set with**: Not typically set by users (managed internally)
  - **Use case**: Internal use for subproject upgrade orchestration

- `MULLE_TECHNICAL_FLAGS`: Technical flags passed to underlying mulle-sde commands
  - **Default**: Empty
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="-v"` for verbose output
  - **Use case**: Debug upgrade process or pass technical options

- `MULLE_FLAG_MAGNUM_FORCE`: Force flag for subproject operations
  - **Default**: `NO`
  - **Set with**: `export MULLE_FLAG_MAGNUM_FORCE=YES`
  - **Use case**: Force operations that might otherwise be skipped

- `MULLE_FLAG_LOG_VERBOSE`: Controls visibility of hidden commands
  - **Default**: Not set (hidden commands not shown)
  - **Set with**: `export MULLE_FLAG_LOG_VERBOSE=YES`
  - **Use case**: Reveal additional hidden commands in help output

### Internal Environment Variables (managed by system)
These are unset during upgrade process to ensure clean environment:
- `MULLE_SDE_ETC_DIR`
- `MULLE_SDE_SHARE_DIR`
- `MULLE_MATCH_ETC_DIR`
- `MULLE_MATCH_SHARE_DIR`
- `MULLE_MATCH_VAR_DIR`

## Hidden Behaviors Explained

### Upgrade Scope and File Preservation
The upgrade command has a **selective upgrade strategy** that preserves critical user files:

**What Gets Upgraded:**
- `.mulle/share/` directory contents (completely replaced)
- `cmake/share/` directory contents (completely replaced)
- Extension templates and craftinfo files
- Build system metadata

**What Gets Preserved:**
- Source files (*.c, *.h, *.m, *.cpp, etc.)
- CMakeLists.txt files (unless explicitly targeted)
- Custom configurations in project root
- Dependency source code

### Subproject Upgrade Orchestration
When upgrading projects with subprojects, the system uses parallel processing by default:

**Parallel Upgrade Process:**
1. Main project upgrade runs first
2. Subprojects are upgraded concurrently using `sde::subproject::map`
3. Each subproject upgrade runs with `--no-test --no-subprojects` to prevent recursion
4. Environment isolation ensures clean upgrade context for each subproject

**Controlled with:** `--no-parallel` or `--serial`

### Test Directory Discovery
The upgrade process automatically discovers and upgrades test directories:

**Discovery Pattern:**
```bash
# Directories checked (in order)
${MULLE_SDE_TEST_PATH:-test}
# Split by ':' for multiple directories
# Example: "test:tests:unittests:integration"
```

**Upgrade Criteria:**
- Directory must exist
- Must contain `.mulle` or `.mulle-env` subdirectory
- Non-matching directories are skipped with verbose message

### Clean Upgrade Behavior
The `--clean` option triggers a comprehensive cleanup before upgrade:

**Cleanup Sequence:**
1. `tidy` - Remove build artifacts and temporary files
2. `mirror` - Clean dependency mirrors
3. `archive` - Remove cached archives

This ensures upgrade starts with clean state, useful when experiencing build issues.

### Single File Upgrade Precision
The `--project-file` option allows surgical upgrades:

**Use Cases:**
- Update specific CMakeLists.txt files without full project upgrade
- Target individual template files
- Upgrade specific configuration files

**Example:**
```bash
# Upgrade only the root CMakeLists.txt
mulle-sde upgrade --project-file CMakeLists.txt
```

## Practical Examples

### Common Hidden Usage Patterns

#### Safe Upgrade with Cleanup
```bash
# Clean upgrade for troubleshooting
mulle-sde upgrade --clean --no-test

# Upgrade only main project, skip subprojects and tests
mulle-sde upgrade --no-subprojects --no-test
```

#### Development Environment Upgrade
```bash
# Upgrade with verbose logging for debugging
export MULLE_FLAG_LOG_VERBOSE=YES
export MULLE_TECHNICAL_FLAGS="-v"
mulle-sde upgrade --clean
```

#### Large Project Optimization
```bash
# Serial upgrade for large projects to reduce memory usage
mulle-sde upgrade --serial --no-test

# Skip project files, only upgrade extensions
mulle-sde upgrade --no-project --no-subprojects --no-test
```

#### Test Environment Upgrade
```bash
# Upgrade with custom test paths
export MULLE_SDE_TEST_PATH="tests:integration:benchmarks"
mulle-sde upgrade

# Skip test directory upgrade entirely
mulle-sde upgrade --no-test
```

#### Subproject Management
```bash
# Upgrade main project and subprojects serially
mulle-sde upgrade --serial

# Upgrade only subprojects (skip main project)
mulle-sde upgrade --no-project
```

### Environment Variable Overrides

#### Custom Test Discovery
```bash
# Multiple test directories
export MULLE_SDE_TEST_PATH="test:tests:unittests:integration:system-tests"
mulle-sde upgrade

# Single non-standard test directory
export MULLE_SDE_TEST_PATH="mytests"
mulle-sde upgrade --no-subprojects
```

#### Debug Upgrade Issues
```bash
# Enable verbose logging
export MULLE_FLAG_LOG_VERBOSE=YES
export MULLE_TECHNICAL_FLAGS="-v -x"
mulle-sde upgrade --clean --serial
```

#### Force Operations
```bash
# Force subproject upgrades even with potential issues
export MULLE_FLAG_MAGNUM_FORCE=YES
mulle-sde upgrade --no-test
```

## Troubleshooting

### When to Use Hidden Options

#### Upgrade Fails Due to Build Artifacts
**Problem:** Upgrade fails with build-related errors
**Solution:** Use clean upgrade
```bash
mulle-sde upgrade --clean
```

#### Memory Issues with Large Projects
**Problem:** System runs out of memory during parallel subproject upgrades
**Solution:** Use serial processing
```bash
mulle-sde upgrade --serial
```

#### Test Directory Upgrade Issues
**Problem:** Upgrade fails in test directory
**Solution:** Skip test upgrade or customize test path
```bash
# Skip entirely
mulle-sde upgrade --no-test

# Use specific test directory
export MULLE_SDE_TEST_PATH="mytests"
mulle-sde upgrade
```

#### Project File Conflicts
**Problem:** Need to update specific project files without full upgrade
**Solution:** Use targeted file upgrade
```bash
mulle-sde upgrade --project-file CMakeLists.txt
```

#### Debugging Upgrade Process
**Problem:** Need to understand what's happening during upgrade
**Solution:** Enable verbose logging
```bash
export MULLE_FLAG_LOG_VERBOSE=YES
export MULLE_TECHNICAL_FLAGS="-v"
mulle-sde upgrade --clean --serial
```

### Common Edge Cases

#### Non-standard Test Structure
```bash
# Custom test directories
export MULLE_SDE_TEST_PATH="unit:integration:e2e"
mulle-sde upgrade --clean
```

#### Subproject Upgrade Failures
```bash
# Skip problematic subprojects
mulle-sde upgrade --no-subprojects
# Then manually upgrade individual subprojects
cd subproject-dir
mulle-sde upgrade --no-test --no-subprojects
```

#### Mixed Environment Issues
```bash
# Clean environment for upgrade
unset MULLE_SDE_ETC_DIR
unset MULLE_SDE_SHARE_DIR
mulle-sde upgrade --clean --serial
```

### Recovery Strategies

#### Rollback Plan
If upgrade causes issues:
1. Backup current state: `cp -r .mulle .mulle.backup`
2. Run upgrade with specific options: `mulle-sde upgrade --no-project`
3. If issues persist, restore from backup: `rm -rf .mulle && mv .mulle.backup .mulle`

#### Verification Steps
```bash
# Check upgrade completed successfully
mulle-sde status

# Verify project still builds
mulle-sde craft

# Run tests to ensure functionality
mulle-sde test run
```