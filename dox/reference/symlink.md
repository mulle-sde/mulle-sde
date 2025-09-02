# mulle-sde symlink - Complete Reference

## Quick Start
Create symlinks for your built executable products into ~/bin for easy system-wide access.

## All Available Options

### Basic Options (in usage)
```
--hard    : create a hard link instead
--install : install (copy) instead of creating a link
```

### Advanced Options (hidden)
```
--soft    : explicitly create a symbolic link (default behavior)
--symlink : alias for --soft
--symbolic: alias for --soft
--copy    : alias for --install
--hardlink: alias for --hard
--hard-link: alias for --hard
```

### Environment Variables
```
- HOME: determines target directory (~/bin by default)
- MULLE_EXE_EXTENSION: platform-specific executable extension (.exe on Windows)
- MULLE_USER_PWD: used for relative path display in logs
```

## Hidden Behaviors Explained

### Automatic Product Discovery
The symlink command uses sophisticated product discovery:

1. **Kitchen Directory Detection**: Automatically finds the build output directory
2. **.motd File Parsing**: Reads build metadata files to identify executables
3. **Fallback Search Pattern**: Looks for PROJECT_NAME and PROJECT_NAME.exe
4. **Multi-Executable Projects**: Presents interactive menu when multiple executables exist

### Configuration-Aware Building
- **Implicit Crafting**: If no products found, automatically runs `mulle-sde craft`
- **Debug/Release Handling**: Respects build configurations
- **Cross-Platform Executables**: Handles platform-specific executable extensions

### Link Type Selection
- **Symbolic Links**: Default behavior, creates symlinks with `ln -s`
- **Hard Links**: Uses `ln` without flags for hard links
- **File Copying**: Uses `install -m 755` for executable copies

### Target Directory Resolution
- **Default Location**: ~/bin (respects HOME environment variable)
- **Custom Directory**: Accepts any directory path as positional argument
- **Permission Handling**: Creates target directory if it doesn't exist
- **Force Overwrite**: Automatically overwrites existing symlinks with `-f` flag

## Practical Examples

### Common Hidden Usage Patterns

```bash
# Create symlink with explicit mode
mulle-sde symlink --soft                    # Explicit symbolic link

# Install copy for deployment
mulle-sde symlink --install /usr/local/bin  # Copy to system bin

# Hard link for performance
mulle-sde symlink --hard ~/bin              # Hard link to local bin

# Custom target directory
mulle-sde symlink /opt/myapp/bin            # Target specific directory

# Multiple executables - interactive selection
# When project has multiple executables, presents menu:
# Choose executable:
# 1) myapp-server
# 2) myapp-client
# 3) myapp-cli
```

### Environment Variable Overrides

```bash
# Install to custom location via HOME override
HOME=/custom/path mulle-sde symlink         # Creates /custom/path/bin/

# Cross-platform executable handling
export MULLE_EXE_EXTENSION=.bat             # Windows batch file handling
mulle-sde symlink                           # Looks for myapp.bat

# Debug output for troubleshooting
MULLE_TRACE=YES mulle-sde symlink           # Shows detailed discovery process
```

## Troubleshooting

### When to Use Hidden Options

**Use --install when:**
- Deploying to production systems where symlinks are restricted
- Creating standalone executables for distribution
- Working with filesystems that don't support symlinks

**Use --hard when:**
- Working on filesystems with symlink limitations
- Needing better performance (hard links have no dereference overhead)
- Creating links within the same filesystem

**Use --soft when:**
- Development environment where quick updates are needed
- Working across filesystem boundaries
- Needing to track source file changes automatically

### Common Issues and Solutions

**Issue: "Could not figure what product was build"**
```bash
# Solution: Ensure project is built
mulle-sde craft
mulle-sde symlink
```

**Issue: Target directory doesn't exist**
```bash
# Solution: Create directory first
mkdir -p ~/bin
mulle-sde symlink
```

**Issue: Permission denied**
```bash
# Solution: Use custom directory or elevate permissions
mulle-sde symlink ~/.local/bin
# OR
sudo mulle-sde symlink /usr/local/bin
```

**Issue: Multiple executables - need specific one**
```bash
# Solution: Use product command with name specification
mulle-sde product list
mulle-sde symlink ~/bin  # Will prompt for selection
```

### Debugging Product Discovery

```bash
# Enable verbose logging
MULLE_TRACE=YES mulle-sde symlink

# Check product paths
mulle-sde product searchpath binary

# Verify executables
mulle-sde product list

# Manual product verification
mulle-sde kitchen-dir  # Check build directory
```

### Advanced Configuration

**Custom Build Configuration:**
```bash
# Use specific build configuration
mulle-sde symlink --configuration Debug ~/debug-bin
mulle-sde symlink --configuration Release ~/bin
```

**SDK-Specific Products:**
```bash
# Target specific SDK builds
mulle-sde symlink --sdk iphoneos /usr/local/ios-bin
```

**Environment-Based Deployment:**
```bash
# Conditional deployment based on environment
if [ "$ENVIRONMENT" = "development" ]; then
    mulle-sde symlink --soft ~/dev-bin
else
    mulle-sde symlink --install /usr/local/bin
fi
```