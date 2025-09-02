# mulle-sde craftorder - Complete Reference

## Quick Start
The `mulle-sde craftorder` command displays the build order of dependencies for your project, showing which dependencies need to be built and in what sequence. This is essential for understanding the dependency resolution process before running `mulle-sde craft`.

## All Available Options

### Basic Options (in usage)
```
-h                      : show this usage
--cached                : show the cached craftorder contents
--names                 : print only names of craftorder dependencies
--print-craftorder-file : print file path of cached craftorder file
--remaining             : show what remains uncrafted of a craftorder
--remove-cached         : remove cached craftorder contents
```

### Advanced Options (hidden)
```
--create                : force creation of new craftorder file
--uncached              : show live craftorder without caching
--uncached-if-needed    : show uncached only if cached version doesn't exist
--no-cached             : synonym for --uncached
--no-uncached           : never show uncached craftorder
```

### Environment Control
```
- MULLE_SDE_VAR_DIR         : sets the cache directory location
  - Default: .mulle/var
  - Set with: export MULLE_SDE_VAR_DIR=/custom/path
  - Use case: When using custom project layouts

- MULLE_HOSTNAME            : determines hostname-specific craftorder caching
  - Default: system hostname
  - Set with: export MULLE_HOSTNAME=build-server-01
  - Use case: Multi-host build environments

- MULLE_SOURCETREE_CONFIG_NAME : specifies configuration name for craftorder
  - Default: "config"
  - Set with: export MULLE_SOURCETREE_CONFIG_NAME=release
  - Use case: Different build configurations
```

## Hidden Behaviors Explained

### Craftorder File Generation
The craftorder file is automatically generated when:
1. The sourcetree configuration changes (newer than craftorder file)
2. The craftorder file doesn't exist
3. Explicitly requested with `--create`

The file is stored at: `.mulle/var/cache/craftorder` (relative to project root)

### Dependency Resolution Algorithm
The craftorder uses a topological sort algorithm that:
1. Respects dependency relationships defined in sourcetree
2. Handles circular dependencies by breaking cycles at the earliest point
3. Considers marks like `no-dependency`, `no-link` to filter entries
4. Processes local subprojects differently from external dependencies

### Cross-Platform Consistency
Craftorder files are host-specific due to platform differences in:
- Library naming conventions
- Build configuration variations
- Platform-specific dependencies

### Integration with Build System
The craftorder file is consumed by:
- `mulle-sde craft` - to determine build sequence
- `mulle-craft` - as input for dependency building
- IDE integration tools - for project setup

## Practical Examples

### Basic Usage Patterns

```bash
# Show current craftorder
mulle-sde craftorder

# Show only dependency names (useful for scripting)
mulle-sde craftorder --names

# Check if craftorder is up-to-date
mulle-sde craftorder --cached

# Force refresh of craftorder
mulle-sde craftorder --remove-cached && mulle-sde craftorder
```

### Development Workflow Examples

```bash
# Before building, check what will be built
mulle-sde craftorder

# Verify craftorder after adding new dependency
mulle-sde add github:madler/zlib.tar
mulle-sde craftorder --uncached

# Debug dependency issues
mulle-sde craftorder --print-craftorder-file
cat $(mulle-sde craftorder --print-craftorder-file)

# Check remaining dependencies to build after partial build failure
mulle-sde craftorder --remaining
```

### Scripting and Automation

```bash
# Generate build script based on craftorder
mulle-sde craftorder --names | while read dep; do
    echo "Building $dep..."
    mulle-sde craft "$dep"
done

# Verify all dependencies exist
for dep in $(mulle-sde craftorder --names); do
    if [ ! -d "dependency/$dep" ]; then
        echo "Missing: $dep"
    fi
done

# Create dependency graph data
mulle-sde craftorder > deps.txt
```

### Environment Variable Overrides

```bash
# Use custom cache directory
export MULLE_SDE_VAR_DIR=/tmp/mulle-cache
mulle-sde craftorder

# Force specific configuration
export MULLE_SOURCETREE_CONFIG_NAME=release
mulle-sde craftorder --create

# Multi-host build setup
export MULLE_HOSTNAME=$(hostname)
mulle-sde craftorder --cached
```

## Advanced Scenarios

### Circular Dependency Handling

When circular dependencies exist, the craftorder resolves them by:
1. Identifying the cycle in the dependency graph
2. Breaking the cycle at the dependency with the lowest priority
3. Emitting a warning message about the broken cycle
4. Continuing with the modified dependency order

Example:
```
# A depends on B, B depends on C, C depends on A
dependency/A
dependency/B
dependency/C
# Warning: Broken circular dependency: C -> A
```

### Cross-Platform Build Ordering

Different platforms may have different craftorder due to:
- Platform-specific dependencies (Windows vs Unix)
- Different library formats (DLL vs SO vs Dylib)
- Configuration-specific dependencies (Debug vs Release)

```bash
# Linux craftorder
stash/mulle-c11
stash/mulle-thread
stash/mulle-dlfcn

# Windows craftorder  
stash/mulle-c11
stash/mulle-thread
stash/mulle-win32
```

### Managing Complex Dependency Trees

For projects with deep dependency hierarchies:

```bash
# Visualize dependency depth
mulle-sde craftorder | nl -v0

# Filter by specific patterns
mulle-sde craftorder | grep -E "(mulle-|Mulle)"

# Check for problematic dependencies
mulle-sde craftorder --uncached | grep -E "no-import|no-link"
```

### Integration with CI/CD

```bash
# Validate craftorder in CI
if ! mulle-sde craftorder --cached >/dev/null 2>&1; then
    echo "Craftorder validation failed"
    exit 1
fi

# Cache craftorder for faster builds
mulle-sde craftorder --cached || mulle-sde craftorder --create
```

## Troubleshooting

### Common Issues and Solutions

**Issue: Empty craftorder file**
```bash
# Solution: Force regeneration
mulle-sde craftorder --remove-cached
mulle-sde craftorder --create
```

**Issue: Missing dependencies in craftorder**
```bash
# Check sourcetree configuration
mulle-sourcetree list

# Verify dependencies are properly added
mulle-sde dependency list

# Refresh craftorder
mulle-sde craftorder --create
```

**Issue: Circular dependency warnings**
```bash
# Identify the cycle
mulle-sourcetree dot | grep -E "->.*->"

# Review dependency relationships
mulle-sde dependency list --verbose
```

**Issue: Platform-specific craftorder issues**
```bash
# Check platform detection
mulle-env platform

# Verify host-specific settings
mulle-env get MULLE_HOSTNAME
```

### When to Use Hidden Options

Use `--uncached` when:
- Debugging dependency resolution issues
- Working with frequently changing sourcetree configurations
- Needing real-time craftorder information

Use `--create` when:
- Cache corruption is suspected
- After manual sourcetree file modifications
- When switching between branches with different dependencies

Use `--remaining` when:
- Build process was interrupted
- Debugging partial build failures
- Determining what needs to be rebuilt

### Performance Optimization

For large projects:
```bash
# Use cached version for performance
mulle-sde craftorder --cached

# Batch operations to reduce sourcetree parsing
mulle-sde craftorder --names > /tmp/deps.txt
```

### Debugging Integration Issues

```bash
# Check craftorder integration with craft
mulle-sde craft --dry-run

# Verify craftorder file integrity
file $(mulle-sde craftorder --print-craftorder-file)

# Compare craftorder with actual dependencies
mulle-sde craftorder --names | sort > craftorder.txt
find dependency -maxdepth 1 -type d -exec basename {} \; | sort > actual.txt
diff craftorder.txt actual.txt
```