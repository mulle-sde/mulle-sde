# mulle-sde extension - Complete Reference

## Quick Start
Manage mulle-sde extensions (meta, extra, oneshot, runtime, buildtool) for customizing your C/C++ development environment.

## All Available Options

### Basic Options (in usage)
- `add <extension>`: Add an "extra" extension to your project
- `find [vendor/name] [type]`: Find extensions by vendor/name or type
- `list`: List installed extensions
- `meta`: Print the installed meta extension
- `pimp`: Install a one-shot extension
- `freshen`: Force update existing extensions
- `remove <extension>`: Remove an extension from your project
- `searchpath`: Show extension search locations
- `show`: Show available extensions
- `usage`: Show usage information for an extension
- `vendors`: List installed vendors

### Advanced Options (hidden)

#### Extension Type Filtering
- `--all`: Show all extension types (meta, extra, oneshot, runtime, buildtool)
- `--meta`: Show only meta extensions (project templates)
- `--extra`: Show only extra extensions (IDE integrations)
- `--oneshot`: Show only oneshot extensions (single-run tools)
- `--runtime`: Show only runtime extensions (language runtimes)
- `--buildtool`: Show only buildtool extensions (build system integrations)

#### Output Control
- `--quiet`: Suppress output (just return status)
- `--no-version`: Hide version information in lists
- `--output-format raw`: Show CSV format with locations and types
- `--usage-only`: Show only usage information (skip type/inherits info)
- `--no-usage`: Skip usage information in show output

#### Extension Discovery
- `--installed`: List only installed vendors/extensions
- `--recurse`: Show usage info for inherited extensions
- `--info`: Show detailed extension metadata (ignore.d, match.d, dependencies)
- `--list-types`: List supported project types for an extension
- `--vendor <name>`: Specify vendor when using extension without vendor prefix

#### Installation Control
- `--if-missing`: Only install if extension is not already installed
- `--reflect`: Trigger automatic reflect after extension changes
- `--no-reflect`: Skip automatic reflect after extension changes
- `--oneshot-name <string>`: Pass custom name to oneshot extension

### Environment Variables

#### Extension Discovery
- **MULLE_SDE_EXTENSION_PATH**: Override complete extension search path
  - **Default**: Auto-generated based on OS and installation
  - **Set with**: `export MULLE_SDE_EXTENSION_PATH="/custom/path1:/custom/path2"`
  - **Use case**: Development/testing with custom extension locations

- **MULLE_SDE_EXTENSION_BASE_PATH**: Augment extension search path
  - **Default**: Empty (uses system defaults)
  - **Set with**: `export MULLE_SDE_EXTENSION_BASE_PATH="/my/extensions"`
  - **Use case**: Add personal extension directories without overriding system

#### Platform-Specific Paths
The extension search path varies by platform:

**Linux/FreeBSD/Windows:**
- `${HOME}/.config/mulle-sde/extensions`
- `/usr/share/mulle-sde/extensions`
- `/usr/local/share/mulle-sde/extensions`

**macOS:**
- `${HOME}/Library/Preferences/mulle-sde/extensions`
- `/usr/local/share/mulle-sde/extensions`

**Developer Mode:**
- When running from source: `/tmp/share/mulle-sde/extensions` (unless overridden)

## Hidden Behaviors Explained

### Extension Resolution Order
Extensions are resolved in this exact sequence:

1. **Explicit vendor/name**: When specified as `vendor/extension`
2. **Installed extensions**: Check what's already installed via `.mulle/share/sde/extension`
3. **Best match**: For bare names, search across all vendors (hierarchical priority)
4. **Vendor directories**: Search in vendor-specific directories in order

### Extension Type Detection
Each extension directory contains a `type` file that determines its classification:
- **meta**: Project templates (used during `mulle-sde init`)
- **extra**: IDE integrations, additional tools (post-init installation)
- **oneshot**: Single-run tools (via `extension pimp`)
- **runtime**: Language runtime configurations
- **buildtool**: Build system integrations

### Inheritance System
Extensions can inherit from other extensions via an `inherit` file:
- Format: `vendor/name;type` (one per line)
- Dependencies are resolved recursively
- Usage information is shown for inherited extensions with `--recurse`

### Version Tracking
Extensions maintain version information in:
- `.mulle/share/sde/extension`: Lists all installed extensions with types
- `.mulle/share/sde/version/vendor/name`: Contains version strings per extension
- Extension directories contain `version` files with current version

### File Installation Patterns
Extensions install files to specific locations:
- **share/mulle-sde/extensions/vendor/name/**: Extension source files
- **share/ignore.d/**: File ignore patterns
- **share/match.d/**: File matching patterns
- **share/bin/**: Extension callbacks
- **share/libexec/**: Extension tasks

## Practical Examples

### Common Hidden Usage Patterns

#### Extension Discovery and Analysis
```bash
# Find all extensions from a specific vendor
mulle-sde extension find mulle-sde/ --quiet

# Show all available extensions as CSV for scripting
mulle-sde extension show --all --output-format raw

# List only runtime extensions with versions
mulle-sde extension show --runtime --version

# Show detailed extension metadata
mulle-sde extension usage --info mulle-sde/foundation-developer

# Recursively show usage for inherited extensions
mulle-sde extension usage --recurse mulle-c/c-developer
```

#### Extension Installation Strategies
```bash
# Install extension only if missing (idempotent)
mulle-sde extension add --if-missing sublime-text

# Force refresh extension files
mulle-sde extension freshen sublime-text

# Install with custom reflect control
mulle-sde extension add --no-reflect sublime-text

# Install oneshot extension with custom name
mulle-sde extension pimp --oneshot-name "MyProject" mulle-sde/craftinfo
```

#### Vendor-Specific Workflows
```bash
# List all available vendors
mulle-sde extension vendors

# Show vendor-specific search path
mulle-sde extension vendorpath mulle-sde

# Find extensions by type across vendors
mulle-sde extension find --type extra

# List installed extensions from specific vendor
mulle-sde extension vendors --installed
```

#### Development and Testing
```bash
# Use custom extension path for development
export MULLE_SDE_EXTENSION_PATH="/home/dev/my-extensions"

# Add development extension path without override
export MULLE_SDE_EXTENSION_BASE_PATH="/home/dev/my-extensions"

# Check extension search path resolution
mulle-sde extension searchpath

# Test extension discovery without installing
mulle-sde extension find my-extension --quiet && echo "Found"
```

### Environment Variable Overrides

#### Cross-Platform Development
```bash
# Linux development with Windows extensions
export MULLE_SDE_EXTENSION_PATH="/mnt/windows/share/mulle-sde/extensions"

# macOS with custom vendor extensions
export MULLE_SDE_EXTENSION_BASE_PATH="${HOME}/my-mulle-extensions"

# Container development with volume mounts
export MULLE_SDE_EXTENSION_PATH="/opt/extensions:/usr/local/share/mulle-sde/extensions"
```

#### CI/CD Integration
```bash
# Use specific extension versions in CI
export MULLE_SDE_EXTENSION_BASE_PATH="/ci/extensions"

# Skip system extensions for reproducible builds
export MULLE_SDE_EXTENSION_PATH="/ci/extensions"

# Validate extension availability
mulle-sde extension find required-extension --quiet || exit 1
```

## Troubleshooting

### When to Use Hidden Options

#### Extension Not Found
```bash
# Check if extension exists in search path
mulle-sde extension find my-extension --quiet || echo "Extension not found"

# Verify extension search path
mulle-sde extension searchpath

# Check specific vendor path
mulle-sde extension vendorpath mulle-sde
```

#### Extension Installation Issues
```bash
# Check if extension is already installed
mulle-sde extension list --no-version | grep my-extension

# Force reinstall if files are corrupted
mulle-sde extension freshen my-extension

# Remove and re-add problematic extension
mulle-sde extension remove my-extension
mulle-sde extension add my-extension
```

#### Version Conflicts
```bash
# Check installed versions
mulle-sde extension list --version

# Show specific extension version
mulle-sde extension usage --info mulle-sde/my-extension | grep -A5 "Version"

# Compare with available versions
mulle-sde extension show --version | grep my-extension
```

#### Platform-Specific Issues
```bash
# Check platform-specific extension paths
uname -a
echo "Extension path: $(mulle-sde extension searchpath)"

# Debug extension discovery
export MULLE_TRACE=1
mulle-sde extension show --all
```

#### Common Error Messages and Solutions

**"No extension vendors found"**
- Check `MULLE_SDE_EXTENSION_PATH` and `MULLE_SDE_EXTENSION_BASE_PATH`
- Verify extensions are installed in expected locations
- Use `mulle-sde extension searchpath` to verify paths

**"Unknown extension"**
- Use full vendor/name format: `mulle-sde/extension-name`
- Check available extensions: `mulle-sde extension show`
- Verify vendor exists: `mulle-sde extension vendors`

**"Extension is unversioned"**
- Extension missing `version` file
- Check extension source: `mulle-sde extension usage --info extension-name`
- Contact extension vendor for versioned release

**"Could not figure out installed extension"**
- Extension metadata corrupted
- Check `.mulle/share/sde/extension` file integrity
- Reinstall extension: remove then add

### Extension Development Debugging
```bash
# Test extension discovery in dev environment
export MULLE_SDE_EXTENSION_PATH="/path/to/dev/extensions"
mulle-sde extension show --all --output-format raw

# Verify extension structure
find /path/to/dev/extensions/vendor/extension -type f | sort

# Test extension installation
mulle-sde extension add --if-missing vendor/extension
```
