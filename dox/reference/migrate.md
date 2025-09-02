# mulle-sde migrate

## Command Analysis

The `mulle-sde migrate` command is a specialized utility for migrating mulle-sde projects between different versions of the mulle-sde toolchain. It performs automated project structure and configuration updates when upgrading from older mulle-sde versions to newer ones.

### Purpose

The migrate command exists to:
- **Automate version upgrades**: Convert project structures between mulle-sde versions
- **Maintain compatibility**: Update build configurations, directory structures, and metadata formats
- **Preserve project state**: Ensure existing dependencies and configurations remain functional after upgrades
- **Handle breaking changes**: Manage transitions when mulle-sde introduces incompatible changes

### Architecture

The migrate command implements a **version-based migration system** with discrete migration functions for each version boundary. It follows a sequential migration path, applying transformations in chronological order from the detected old version to the target new version.

## Usage Patterns

### Basic Usage

```bash
# Migrate from detected old version to current version
mulle-sde migrate

# Migrate from specific old version to current version
mulle-sde migrate <old-version>

# Migrate between specific versions
mulle-sde migrate <old-version> <new-version>
```

### Command Forms

| Form | Description |
|------|-------------|
| `mulle-sde migrate` | Auto-detect old version, migrate to current |
| `mulle-sde migrate <version>` | Migrate from specified version to current |
| `mulle-sde migrate <from> <to>` | Migrate between specific versions |

### Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show usage information |
| `-N` | Technical flags passed through to underlying tools |

## Migration Pathways

### Version History

The migrate command handles transitions across these version boundaries:

#### v0.41 → v0.42
- **Header management**: Removes duplicate headers in project root after reflection
- **CMake restructuring**: Reorganizes CMake configuration files
- **File cleanup**: Removes old objc-loader.inc files

#### v0.46 → v0.47
- **Sourcetree mark renaming**: Renames cmake-related sourcetree marks to use hyphenated format
- **Configuration updates**: Updates sourcetree configuration naming conventions

#### v0.47 → v1.14
- **Environment scope updates**: Updates auxscope configuration from project;10 to project;20
- **Metadata alignment**: Ensures compatibility with v1.x environment handling

#### v1.14 → v2.2
- **CMake variable changes**: Updates CMAKE_INCLUDES to INSTALL_CMAKE_INCLUDES
- **Installation paths**: Fixes private header installation paths in CMake configs

#### v2.2 → v3.2
- **Craftinfo restructuring**: Renames craftinfo directories to follow new naming convention
- **Directory migration**: Moves from `craftinfo/<name>` to `craftinfo/<name>-craftinfo`
- **Sourcetree updates**: Updates sourcetree references to new craftinfo paths

### Migration Process

1. **Version Detection**: Automatically detects current project version from `.mulle/share/env/version`
2. **Sequential Application**: Applies migrations in chronological order
3. **Error Handling**: Fails fast on any migration step with detailed logging
4. **Cleanup**: Removes redundant configuration files and directories

## Practical Examples

### Example 1: Basic Project Migration

```bash
# After upgrading mulle-sde to a new version
$ cd my-project
$ mulle-sde migrate

# Output:
# [INFO] Migrating from v0.46.0 to v3.4.3
# [INFO] Running migration v0.46 -> v0.47
# [INFO] Running migration v0.47 -> v1.14
# [INFO] Running migration v1.14 -> v2.2
# [INFO] Running migration v2.2 -> v3.2
# [INFO] Removing .mulle/etc/craft as it's not different from .mulle/share/craft
```

### Example 2: Specific Version Migration

```bash
# Migrate from a known old version
$ mulle-sde migrate 0.41.0 3.4.3

# This applies:
# 1. v0.41 -> v0.42 migration
# 2. v0.42 -> v0.47 migration (if needed)
# 3. v0.47 -> v1.14 migration
# 4. v1.14 -> v2.2 migration
# 5. v2.2 -> v3.2 migration
```

### Example 3: Migration After Failed Upgrade

```bash
# Project shows version compatibility issues
$ mulle-sde status
# [WARNING] Project version mismatch

# Run migration to fix
$ mulle-sde migrate
# [INFO] Detected old version: 2.1.0
# [INFO] Migrating to v3.4.3...
# [INFO] Running migration v2.2 -> v3.2
```

## Hidden Options and Advanced Features

### Development Mode

The migrate command includes a warning indicating it's primarily for mulle-sde development:

```bash
$ mulle-sde migrate
[WARNING] Command only to be used for development of mulle-sde
```

### Technical Details

#### File Transformations

Each migration step performs specific file transformations:

**v0.41 → v0.42**:
- Removes headers from project root that are now in `reflect/` directory
- Renames old CMake files to `.orig` backups
- Updates `CMAKE_MODULE_PATH` in CMakeLists.txt

**v0.46 → v0.47**:
- Renames sourcetree marks from `cmakeall-load` → `cmake-all-load`
- Updates all cmake-related sourcetree mark names to use hyphens

**v2.2 → v3.2**:
- Renames craftinfo directories to include `-craftinfo` suffix
- Updates all sourcetree references to new craftinfo paths

#### Environment Handling

The migrate command:
- **Preserves environment**: Maintains environment variables and configuration
- **Runs in subshell**: Each migration step runs in a clean subshell
- **Protects/unprotects**: Temporarily changes file permissions during migration
- **Re-reads settings**: Reloads environment configuration after each step

## Integration Points

### Relationship to Other Commands

#### migrate ↔ reflect
- **Before migration**: Run `mulle-sde reflect` to ensure consistent state
- **After migration**: Run `mulle-sde reflect` to apply new configurations

#### migrate ↔ craft
- **Post-migration**: Run `mulle-sde craft` to rebuild with new configurations
- **Dependency handling**: Migration preserves craft order and dependencies

#### migrate ↔ dependency
- **Version compatibility**: Migration ensures dependency configurations remain valid
- **Path updates**: Updates dependency paths if directory structures change

### Workflow Integration

```bash
# Complete upgrade workflow
$ mulle-sde upgrade          # Upgrade mulle-sde itself
$ mulle-sde migrate          # Migrate project structure
$ mulle-sde reflect          # Update build files
$ mulle-sde craft            # Rebuild with new configurations
$ mulle-sde test craft       # Verify tests still pass
```

## Advanced Usage Scenarios

### Cross-Platform Migration

When migrating projects across platforms:

```bash
# Linux -> macOS migration considerations
$ mulle-sde migrate
$ mulle-sde config switch darwin  # Switch to darwin configuration
$ mulle-sde reflect               # Regenerate platform-specific files
$ mulle-sde craft                 # Build for new platform
```

### Build System Conversion

Migration can facilitate build system changes:

```bash
# Example: Migrating from legacy build to CMake
$ mulle-sde migrate  # Updates to new CMake structure
$ mulle-sde extension add cmake/modern  # Add modern CMake extension
$ mulle-sde reflect                    # Regenerate CMake files
```

### Batch Migration

For multiple projects:

```bash
#!/bin/bash
# migrate-all.sh - Batch migrate multiple projects

for project in */.mulle; do
    project_dir=$(dirname "$project")
    echo "Migrating $project_dir..."
    (cd "$project_dir" && mulle-sde migrate)
done
```

### Troubleshooting Migration Issues

#### Common Problems and Solutions

**Version Detection Failure**:
```bash
# Manually specify versions
mulle-sde migrate 0.41.0 3.4.3
```

**Permission Errors**:
```bash
# Ensure proper permissions
chmod -R u+w .mulle/
mulle-sde migrate
```

**Migration Partial Failure**:
```bash
# Check migration state
mulle-sde status
# Review migration logs
find .mulle -name "*.log" -exec tail -n 20 {} \;
# Manual cleanup if needed
mulle-sde clean tidy
mulle-sde migrate
```

### Migration Verification

```bash
# Verify migration success
$ mulle-sde status
$ mulle-sde dependency list
$ mulle-sde craftinfo
$ mulle-sde test run

# Check for deprecated files
find . -name "*.orig" -o -name "*.backup"
```

## Best Practices

### Pre-Migration Checklist

1. **Backup project**: Create full backup before migration
2. **Check version**: Verify current mulle-sde version
3. **Clean state**: Ensure project is clean (`mulle-sde clean tidy`)
4. **Commit changes**: Commit any pending changes to version control
5. **Test current state**: Verify project builds and tests pass

### Post-Migration Checklist

1. **Verify structure**: Check new directory layout
2. **Update extensions**: Ensure extensions are compatible
3. **Rebuild dependencies**: Run `mulle-sde craft` to rebuild
4. **Run tests**: Execute full test suite
5. **Update documentation**: Update any project documentation

### Version Control Integration

```bash
# Recommended workflow with git
git add .
git commit -m "Pre-migration checkpoint"
mulle-sde migrate
git add .
git commit -m "Post-migration: updated to mulle-sde v3.4.3"
```

## Technical Implementation Details

### Migration Functions

Each migration is implemented as a discrete function:

```bash
# Migration function structure
sde::migrate::from_vX_Y_to_vA_B()
{
    log_entry "sde::migrate::from_vX_Y_to_vA_B" "$@"
    
    # File transformations
    # Configuration updates
    # Directory reorganization
    # Cleanup operations
}
```

### Error Handling

- **Subshell execution**: Each migration runs in isolated subshell
- **Exit on failure**: Any step failure aborts entire migration
- **Logging**: Detailed logging via `log_entry`, `log_info`, `log_fluff`
- **Rollback**: Manual rollback may be required for complex failures

### Configuration Preservation

The migrate command preserves:
- Environment variables and settings
- Dependency configurations
- Build flags and options
- Custom craftinfo settings
- Source tree configurations
