# mulle-sde find - Complete Reference

## Quick Start
Search for installed extensions and dependencies within your mulle-sde project using the `extension find` command.

## All Available Options

### Basic Options (in usage)
```bash
mulle-sde extension find [vendor/name] [type]
```

**Arguments:**
- `vendor/name`: Extension identifier in format `vendor/extension-name`
- `type`: Filter by extension type (meta, extra, oneshot, runtime, buildtool)

**Visible Options:**
- `--quiet`: Just return status without outputting paths
- `--help`: Show usage information

### Advanced Options (hidden)

**Search Path Control:**
- **Environment variables** that control extension discovery:
  - `MULLE_SDE_EXTENSION_PATH`: Overrides the entire search path for extensions
  - `MULLE_SDE_EXTENSION_BASE_PATH`: Augments the search path for extensions

**Cross-platform Search:**
- Automatic platform-specific search paths:
  - **Linux/FreeBSD/Windows**: `/usr/share/mulle-sde/extensions`, `/usr/local/share/mulle-sde/extensions`
  - **macOS**: `~/Library/Preferences/mulle-sde/extensions`
  - **Other Unix**: `~/.config/mulle-sde/extensions`

### Environment Control

**Extension Discovery Variables:**
- `MULLE_SDE_EXTENSION_PATH`: Complete override of extension search locations
  - **Default**: Platform-dependent search paths
  - **Set with**: `export MULLE_SDE_EXTENSION_PATH="/custom/path:/another/path"`
  - **Use case**: Development with custom extensions, testing new extensions

- `MULLE_SDE_EXTENSION_BASE_PATH`: Add additional search locations
  - **Default**: Empty (uses standard paths)
  - **Set with**: `export MULLE_SDE_EXTENSION_BASE_PATH="/my/extensions"`
  - **Use case**: Adding personal extension collections

## Hidden Behaviors Explained

### Extension Discovery Algorithm

**Search Order:**
1. `MULLE_SDE_EXTENSION_PATH` (if set)
2. `MULLE_SDE_EXTENSION_BASE_PATH` (if set)
3. User configuration directory:
   - Linux/Unix: `~/.config/mulle-sde/extensions`
   - macOS: `~/Library/Preferences/mulle-sde/extensions`
4. Installation directory: `<install-prefix>/share/mulle-sde/extensions`
5. System directories:
   - Linux/FreeBSD: `/usr/share/mulle-sde/extensions`
   - macOS/Linux/FreeBSD: `/usr/local/share/mulle-sde/extensions`

**Pattern Matching:**
- **Vendor matching**: Case-sensitive directory names
- **Extension matching**: Case-sensitive directory names
- **Type filtering**: Based on `type` file content in extension directory

### Conditional Behaviors

**Vendor-only Search:**
When only vendor is specified, returns all extensions from that vendor:
```bash
mulle-sde extension find mulle-sde
# Returns: mulle-sde/c-developer, mulle-sde/objc-developer, etc.
```

**Name-only Search:**
When only extension name is specified, searches across all vendors:
```bash
mulle-sde extension find developer
# Returns: mulle-sde/c-developer, foundation/objc-developer, etc.
```

**Full Specification:**
When both vendor and name are specified:
```bash
mulle-sde extension find mulle-sde/c-developer
# Returns exact match path or nothing
```

**Type Filtering:**
Additional type filter narrows results:
```bash
mulle-sde extension find mulle-sde meta
# Returns only meta extensions from mulle-sde
```

## Practical Examples

### Common Hidden Usage Patterns

**Find All Extensions by Vendor:**
```bash
# Find all extensions from a specific vendor
mulle-sde extension find mulle-sde

# Output example:
# /usr/local/share/mulle-sde/extensions/mulle-sde/c-developer
# /usr/local/share/mulle-sde/extensions/mulle-sde/objc-developer
# /usr/local/share/mulle-sde/extensions/mulle-sde/cmake
```

**Find Extensions by Type:**
```bash
# Find all buildtool extensions
mulle-sde extension find "" buildtool

# Find all extra extensions
mulle-sde extension find "" extra
```

**Development Extension Testing:**
```bash
# Use custom extension path for development
export MULLE_SDE_EXTENSION_PATH="/home/user/mulle-extensions"
mulle-sde extension find myvendor/myextension
```

**Cross-platform Extension Location:**
```bash
# Find where extensions are located on current system
mulle-sde extension searchpath

# Output example on Linux:
# /home/user/.config/mulle-sde/extensions:/usr/local/share/mulle-sde/extensions:/usr/share/mulle-sde/extensions
```

**Silent Status Checking:**
```bash
# Check if extension exists without output (useful in scripts)
if mulle-sde extension find --quiet mulle-sde/c-developer; then
    echo "Extension found"
else
    echo "Extension not found"
fi
```

### Environment Variable Overrides

**Custom Extension Development:**
```bash
# Set up for extension development
export MULLE_SDE_EXTENSION_BASE_PATH="$HOME/mulle-sde-dev/extensions"
mkdir -p "$HOME/mulle-sde-dev/extensions/myvendor/myextension"
echo "extra" > "$HOME/mulle-sde-dev/extensions/myvendor/myextension/type"

# Test the extension
mulle-sde extension find myvendor/myextension
# Should return: /home/user/mulle-sde-dev/extensions/myvendor/myextension
```

**Isolated Extension Environment:**
```bash
# Completely isolate extension search for testing
export MULLE_SDE_EXTENSION_PATH="/tmp/test-extensions"
mkdir -p "/tmp/test-extensions/testvendor/testext"
echo "meta" > "/tmp/test-extensions/testvendor/testext/type"

# Only finds extensions in test directory
mulle-sde extension find testvendor
```

## Troubleshooting

### When to Use Hidden Options

**Debugging Extension Discovery:**
```bash
# When extensions aren't found, check search path
mulle-sde extension searchpath

# Verify extension directory structure
ls -la /usr/local/share/mulle-sde/extensions/
```

**Extension Not Found Issues:**
```bash
# Check if type file exists and is correct
ls -la /path/to/extension/type
cat /path/to/extension/type  # Should contain: meta|extra|oneshot|runtime|buildtool
```

**Cross-platform Compatibility:**
```bash
# Platform-specific paths
uname_output=$(uname)
case $uname_output in
    Darwin)
        echo "macOS extensions in ~/Library/Preferences/mulle-sde/extensions"
        ;;
    Linux)
        echo "Linux extensions in ~/.config/mulle-sde/extensions"
        ;;
esac
```

**Script Integration:**
```bash
#!/bin/bash
# Find and use extension in script

EXTENSION_PATH=$(mulle-sde extension find mulle-sde/c-developer)
if [ -n "$EXTENSION_PATH" ]; then
    echo "Using extension at: $EXTENSION_PATH"
    # Do something with extension
else
    echo "Extension not found, installing..."
    mulle-sde extension add mulle-sde/c-developer
fi
```

### Common Issues and Solutions

**Permission Issues:**
```bash
# Check permissions on extension directories
ls -la /usr/local/share/mulle-sde/extensions/
sudo chmod -R a+r /usr/local/share/mulle-sde/extensions/
```

**Cache Issues:**
```bash
# Refresh extension discovery
unset MULLE_SDE_EXTENSION_PATH
unset MULLE_SDE_EXTENSION_BASE_PATH
mulle-sde extension find mulle-sde/c-developer
```

**Extension Validation:**
```bash
# Validate extension structure
extension_dir=$(mulle-sde extension find mulle-sde/c-developer)
if [ -f "$extension_dir/type" ]; then
    echo "Valid extension structure"
else
    echo "Invalid extension - missing type file"
fi
```

## Integration with Other Commands

### Extension Usage After Finding
```bash
# Find and show extension details
EXT=$(mulle-sde extension find mulle-sde/c-developer)
if [ -n "$EXT" ]; then
    mulle-sde extension usage mulle-sde/c-developer
fi
```

### Project Initialization with Found Extensions
```bash
# Find available extensions and use for project init
mulle-sde extension show meta
# Then use one of the found extensions:
mulle-sde init -d myproject -m mulle-sde/c-developer executable
```

### Extension Management Workflow
```bash
# Complete workflow: find, validate, add
if mulle-sde extension find --quiet myvendor/myextension; then
    echo "Extension exists"
    mulle-sde extension usage myvendor/myextension
else
    echo "Extension not found - checking available..."
    mulle-sde extension show
fi
```