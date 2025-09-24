# mulle-sde reinit - Reinitialize Environment

## Quick Start
Reinitialize the mulle-sde environment with updated configuration.

## All Available Options

### Basic Usage
```bash
mulle-sde reinit [options]
```

**Arguments:** None

### Visible Options
- `--help`: Show usage information
- `--force`: Force reinitialization without confirmation
- `--keep-config`: Preserve user configuration during reinit

### Hidden Options
- `--style <style>`: Reinitialize with specific style
- `--platform <platform>`: Reinitialize for specific platform
- `--clean`: Clean before reinitializing
- Various reinit-specific options

## Command Behavior

### Core Functionality
- **Environment Reset**: Reset environment to clean state
- **Configuration Reload**: Reload all configuration files
- **Tool Relinking**: Refresh tool symlinks and paths
- **Dependency Update**: Update dependency information

### Conditional Behaviors

**Reinitialization Scope:**
- Default reinit: Preserve user settings, update system config
- Force reinit: Complete reinitialization including user settings
- Clean reinit: Clean environment before reinitializing

**Configuration Handling:**
- User configuration preservation when requested
- Style and platform reconfiguration
- Tool and dependency reconfiguration

## Practical Examples

### Basic Reinitialization
```bash
# Reinitialize environment
mulle-sde reinit

# Force reinitialization
mulle-sde reinit --force

# Reinitialize preserving config
mulle-sde reinit --keep-config
```

### Style-Specific Reinitialization
```bash
# Reinitialize with specific style
mulle-sde reinit --style developer/relax

# Reinitialize for different platform
mulle-sde reinit --platform linux

# Clean reinit with new style
mulle-sde reinit --clean --style production
```

### Workflow Integration
```bash
# Reinitialize after configuration changes
mulle-sde style set developer/strict
mulle-sde reinit

# Reinitialize after tool changes
mulle-sde tool add clang
mulle-sde reinit

# Reinitialize after dependency updates
mulle-sde dependency update
mulle-sde reinit
```

### Recovery Scenarios
```bash
# Recover from environment corruption
mulle-sde reinit --force

# Update environment after system changes
mulle-sde reinit --clean

# Refresh environment after updates
mulle-sde upgrade
mulle-sde reinit
```

## Troubleshooting

### Reinitialization Failures
```bash
# Reinit fails due to locked files
mulle-sde reinit
# Error: Files locked by running processes

# Solution: Stop processes first
pkill -f "mulle-sde"
mulle-sde reinit --force
```

### Configuration Conflicts
```bash
# Configuration conflicts during reinit
mulle-sde reinit
# Error: Configuration conflict detected

# Solution: Use force or clean options
mulle-sde reinit --force
# or
mulle-sde reinit --clean
```

### Permission Issues
```bash
# No permission to reinit environment
mulle-sde reinit
# Error: Permission denied

# Solution: Check environment permissions
ls -la .mulle/
sudo chown -R $USER .mulle/
```

### Incomplete Reinitialization
```bash
# Reinit doesn't update everything
mulle-sde reinit
mulle-sde status  # Still shows old configuration

# Solution: Use clean reinit
mulle-sde reinit --clean
```

## Integration with Other Commands

### Environment Management
```bash
# Reinitialize after style changes
mulle-sde style set production
mulle-sde reinit

# Reinitialize after tool modifications
mulle-sde tool remove gcc
mulle-sde tool add clang
mulle-sde reinit

# Reinitialize after dependency changes
mulle-sde dependency add zlib
mulle-sde reinit
```

### Maintenance Workflows
```bash
# Regular environment maintenance
mulle-sde clean
mulle-sde reinit

# After system updates
mulle-sde reinit --clean

# Before major development
mulle-sde reinit --force
```

### Status Verification
```bash
# Check status after reinit
mulle-sde reinit
mulle-sde status --verbose

# Verify tool availability
mulle-sde reinit
mulle-sde tool list
```

## Technical Details

### Reinitialization Process

**Phase 1: Assessment**
- Analyze current environment state
- Identify configuration changes needed
- Check for running processes that may interfere
- Generate reinit plan

**Phase 2: Preparation**
- Backup current configuration if requested
- Stop dependent services and processes
- Prepare rollback information
- Validate reinit safety

**Phase 3: Execution**
- Reset environment to clean state
- Reload all configuration files
- Refresh tool symlinks and paths
- Update dependency information

**Phase 4: Verification**
- Test environment integrity
- Verify tool availability
- Check configuration consistency
- Provide status report

### Reinitialization Types

**Standard Reinit:**
- Preserves user configuration and settings
- Updates system configuration and tools
- Maintains existing environment structure
- Quick operation with minimal disruption

**Force Reinit:**
- Complete environment reinitialization
- May reset user configurations to defaults
- Ensures clean environment state
- More thorough but potentially disruptive

**Clean Reinit:**
- Performs clean operation before reinitialization
- Removes all caches and temporary files
- Ensures completely fresh environment
- Most thorough but slowest operation

### Configuration Handling

**User Configuration:**
- Preserved during standard reinit
- Reset to defaults in force reinit
- Backed up before major changes
- Migrated between versions when possible

**System Configuration:**
- Always updated during reinit
- Reflects current system state
- Includes platform and tool updates
- Maintains compatibility with new versions

### Backup and Recovery

**Automatic Backups:**
- Configuration files backup
- User settings preservation
- Environment state snapshot
- Rollback capability

**Recovery Options:**
- Rollback to previous state
- Selective configuration restoration
- Incremental reinit options
- Emergency recovery procedures

## Related Commands

- **[`init`](init.md)** - Initial environment setup
- **[`clean`](clean.md)** - Clean environment artifacts
- **[`upgrade`](upgrade.md)** - Upgrade environment components
- **[`status`](status.md)** - Check environment status