# mulle-sde export - Complete Reference

## Quick Start
Export dependency and library configurations to share build settings across projects or create portable craftinfo scripts.

## All Available Options

### Basic Options (in usage)
```
-h, --help     : show this usage
--write        : write export to ~/.mulle/share/craftinfo
-d, --dir <path> : write to <path> instead of ~/.mulle/share/craftinfo
```

### Advanced Options (hidden)
**Note**: The export command has no hidden options, but integrates with several subsystems:

- **Sourcetree Export**: Automatically extracts dependency/library definitions from sourcetree
- **Craftinfo Export**: Automatically extracts build settings and scripts from craftinfo configurations
- **Cross-platform Support**: Exports settings for specific OS configurations when available

### Environment Control
```
- MULLE_SOURCETREE_CONFIG_NAME : Controls which configuration is used
  - Default: "config"
  - Set with: export MULLE_SOURCETREE_CONFIG_NAME=myconfig
  - Use case: When working with multiple build configurations

- MULLE_SDE_LIBEXEC_DIR : Location of mulle-sde extension scripts
  - Default: /usr/local/libexec/mulle-sde
  - Set with: export MULLE_SDE_LIBEXEC_DIR=/custom/path
  - Use case: When using custom mulle-sde extensions

- MULLE_TECHNICAL_FLAGS : Additional flags passed to sourcetree operations
  - Default: none
  - Set with: export MULLE_TECHNICAL_FLAGS="--verbose"
  - Use case: Debugging sourcetree operations
```

## Hidden Behaviors Explained

### Export Process Flow

The export command performs a two-step process:

1. **Sourcetree Node Export**: Extracts the exact `mulle-sde dependency add` or `mulle-sde library add` command needed to recreate the dependency/library configuration, including:
   - Source URL
   - Branch/tag information
   - Fetch options
   - Node type
   - Marks and user info

2. **Craftinfo Export**: Extracts build settings and scripts from any existing craftinfo configurations, including:
   - Compiler flags (CFLAGS, CPPFLAGS, LDFLAGS)
   - Build scripts
   - CMake configuration
   - Platform-specific settings

### Automatic Detection Logic

**Dependency vs Library Detection**
- First checks if the name exists as a library (sourcetree node without dependency marks)
- Falls back to checking if it's a dependency (sourcetree node with dependency marks)
- Fails with descriptive error if neither is found

**Configuration Discovery**
- Automatically detects `.${config}` suffixes for configuration-specific settings
- Processes both global settings and OS-specific settings
- Handles multiple configurations in craftinfo directories

### File Structure Export

**Generated Script Format**
```bash
#!/bin/sh

# Sourcetree configuration
mulle-sde dependency add --address 'dependency-name' \
   --nodetype 'tar' \
   --branch 'v1.2.3' \
   'https://github.com/user/repo.tar.gz'

# Craftinfo settings
mulle-sde craftinfo --global set dependency-name CPPFLAGS "-DSOME_DEFINE=1"
mulle-sde craftinfo --os linux set dependency-name CFLAGS "-fPIC"
```

## Practical Examples

### Example 1: Basic Export for Sharing
```bash
# Export zlib configuration to stdout
mulle-sde export zlib

# Export and save to default craftinfo directory
mulle-sde export --write zlib

# Export to specific directory
mulle-sde export --dir /tmp/my-craftinfo zlib
```

### Example 2: Cross-Platform Export
```bash
# Export with platform-specific settings
# This will include both global and OS-specific craftinfo settings
mulle-sde export openssl

# Example output includes:
# - Global settings: CPPFLAGS, CFLAGS
# - Linux-specific: linux.CFLAGS = -fPIC
# - macOS-specific: Darwin.CFLAGS = -mmacosx-version-min=10.12
```

### Example 3: Creating Portable Build Scripts
```bash
# Export configuration for offline use
mkdir -p /tmp/portable-build
cd /tmp/portable-build

# Export all dependencies
for dep in $(mulle-sde dependency list --format '%n'); do
    echo "Exporting $dep..."
    mulle-sde export --write "$dep"
done

# Create installation script
cat > install-dependencies.sh << 'EOF'
#!/bin/bash
set -e

# Install all exported dependencies
for script in ~/.mulle/share/craftinfo/*/add; do
    if [ -x "$script" ]; then
        echo "Installing from $script"
        "$script"
    fi
done
EOF

chmod +x install-dependencies.sh
```

### Example 4: Sharing Build Configurations
```bash
# Export custom build configuration for team
export MULLE_SOURCETREE_CONFIG_NAME=production

# Export all dependencies with production settings
for dep in $(mulle-sde dependency list --format '%n'); do
    mulle-sde export --dir ./team-configs "$dep"
done

# Team members can then use:
# cp team-configs/* ~/.mulle/share/craftinfo/
# Then run the exported scripts to recreate the exact build environment
```

### Example 5: Version-Specific Export
```bash
# Export specific version configurations
# Useful for maintaining multiple project versions

PROJECT_NAME=$(basename "$PWD")
EXPORT_DIR="/tmp/${PROJECT_NAME}-export-$(date +%Y%m%d)"

mkdir -p "$EXPORT_DIR"

# Export each dependency with version info
while IFS=$'\t' read -r name address; do
    echo "Exporting $name ($address)..."
    mulle-sde export --dir "$EXPORT_DIR" "$name"
done < <(mulle-sde dependency list --format '%n\t%a')

# Create manifest
cat > "$EXPORT_DIR/MANIFEST" << EOF
# Generated export manifest
# Project: $PROJECT_NAME
# Date: $(date)
# Command: mulle-sde export
EOF
```

## Environment Variable Overrides

### Custom Export Location
```bash
# Override default export directory
export OPTION_DIRECTORY="/opt/shared/craftinfo"
mulle-sde export --write zlib
# File will be written to /opt/shared/craftinfo/github.com/madler/zlib.tar/add
```

### Debug Export Process
```bash
# Enable verbose logging for export operations
export MULLE_TECHNICAL_FLAGS="--verbose"
mulle-sde export zlib
# Shows detailed information about sourcetree and craftinfo extraction
```

### Configuration-Specific Export
```bash
# Export settings for specific build configuration
export MULLE_SOURCETREE_CONFIG_NAME=ios
mulle-sde export openssl
# Exports iOS-specific build settings if they exist
```

## Troubleshooting

### When to Use Hidden Behaviors

**Scenario 1: Missing Craftinfo**
```bash
# Error: "There is nothing to export for 'dependency-name'"
# Solution: Create craftinfo first
mulle-sde dependency craftinfo create dependency-name
mulle-sde dependency craftinfo set dependency-name CPPFLAGS "-DNEEDED_DEFINE"
mulle-sde export dependency-name
```

**Scenario 2: Permission Errors**
```bash
# Error: Cannot write to ~/.mulle/share/craftinfo
# Solution: Use custom directory or fix permissions
mulle-sde export --dir /tmp/export dependency-name
# Or: sudo chown -R $USER ~/.mulle/share/craftinfo
```

**Scenario 3: Existing Export Conflict**
```bash
# Error: File already exists
# Solution: Use -f flag (not directly available, but work around)
rm ~/.mulle/share/craftinfo/github.com/user/repo/add
mulle-sde export --write dependency-name
```

### Debugging Export Issues

**Verbose Export Analysis**
```bash
# Check what would be exported without creating files
mulle-sde export zlib

# Validate sourcetree configuration
mulle-sourcetree get zlib all

# Check craftinfo settings
mulle-sde dependency craftinfo list zlib
```

**Cross-Reference Validation**
```bash
# Verify export matches actual configuration
mulle-sde export zlib > exported.sh
source exported.sh  # Dry run - check for errors
```

### Integration with Build Systems

**CMake Integration**
```bash
# Export and integrate with CMake
mkdir -p cmake/craftinfo
mulle-sde export --dir cmake/craftinfo zlib

# In CMakeLists.txt:
# include(cmake/craftinfo/github.com/madler/zlib.tar/add)
```

**CI/CD Pipeline Usage**
```bash
# Export for CI/CD
EXPORT_DIR="${CI_PROJECT_DIR}/craftinfo-exports"
mulle-sde export --dir "$EXPORT_DIR" --write zlib

# Cache between builds
cache:
  paths:
    - craftinfo-exports/
```

## Advanced Integration Examples

### Batch Export Script
```bash
#!/bin/bash
# batch-export.sh - Export all project dependencies

PROJECT_ROOT="${1:-.}"
EXPORT_DIR="${2:-/tmp/project-export}"

mkdir -p "$EXPORT_DIR"

cd "$PROJECT_ROOT"

# Export project metadata
cat > "$EXPORT_DIR/project-info" << EOF
Project: $(basename "$PWD")
Date: $(date)
Dependencies: $(mulle-sde dependency list --count)
EOF

# Export each dependency
while IFS=$'\t' read -r name address; do
    echo "Exporting: $name"
    
    # Create directory structure
    SAFE_NAME=$(echo "$address" | tr '/' '_')
    DEP_DIR="$EXPORT_DIR/$SAFE_NAME"
    mkdir -p "$DEP_DIR"
    
    # Export configuration
    mulle-sde export "$name" > "$DEP_DIR/add.sh"
    chmod +x "$DEP_DIR/add.sh"
    
    # Export version info
    mulle-sourcetree get "$name" tag branch > "$DEP_DIR/version-info"
    
done < <(mulle-sde dependency list --format '%n\t%a')

echo "Export complete in: $EXPORT_DIR"
```

### Version-Locked Export
```bash
#!/bin/bash
# lock-versions.sh - Create reproducible build configuration

LOCK_FILE=".build-lock"
EXPORT_DIR="build-lock-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$EXPORT_DIR"

# Export current versions
echo "# Build Lock Configuration" > "$LOCK_FILE"
echo "# Generated: $(date)" >> "$LOCK_FILE"
echo "" >> "$LOCK_FILE"

while IFS=$'\t' read -r name address; do
    # Get exact version
    version=$(mulle-sourcetree get "$name" tag)
    if [ -z "$version" ]; then
        version=$(mulle-sourcetree get "$name" branch)
    fi
    
    # Export with version lock
    echo "Exporting $name@$version"
    mulle-sde export --dir "$EXPORT_DIR" "$name"
    
    echo "$name=$version" >> "$LOCK_FILE"
done < <(mulle-sde dependency list --format '%n\t%a')

echo "Build lock created: $EXPORT_DIR"
echo "Version lock file: $LOCK_FILE"
```