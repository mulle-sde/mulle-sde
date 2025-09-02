# mulle-sde status

## Command Overview

The `mulle-sde status` command provides comprehensive diagnostic information about the current mulle-sde project state. It serves as a health check mechanism that reveals project configuration, dependency status, build environment, and potential issues across multiple aspects of the development environment.

### Purpose & Use Cases

**Primary Functions:**
- **Project Discovery**: Identifies if you're in a mulle-sde project and determines the project root directory
- **Dependency Health**: Shows the state of dependencies and whether they need fetching/rebuilding
- **Configuration Validation**: Displays sourcetree configuration and potential mismatches
- **Environment Diagnostics**: Reports on tools, stash, graveyard, and other environmental factors
- **Migration Detection**: Identifies legacy mulle-sde, mulle-env, or mulle-bootstrap projects

**Key Use Cases:**
1. **Initial Setup Verification**: After `mulle-sde init`, verify project structure is correct
2. **Pre-Build Diagnostics**: Before `mulle-sde craft`, check dependency and build readiness
3. **Troubleshooting**: When builds fail, identify configuration issues or missing dependencies
4. **Multi-Project Navigation**: Understand parent/child project relationships and command delegation
5. **Cleanup Planning**: Identify graveyard directories and broken symlinks for cleanup

## Complete Options Reference

### Visible Options

| Option | Description | Default |
|--------|-------------|---------|
| `--all` | Enable all status information types | Disabled |
| `--clear` | Reset to no status types (override defaults) | Disabled |
| `--config` | Show sourcetree configuration information | **Enabled** |
| `--craftstatus` | Show craft/build status information | **Enabled** |
| `--database` | Show sourcetree database information | **Enabled** |
| `--graveyard` | Show sourcetree graveyard information | **Enabled** |
| `--project` | Show project information | **Enabled** |
| `--quickstatus` | Show dependency status information | **Enabled** |
| `--sourcetree` | Show comprehensive sourcetree information | **Enabled** |
| `--stash` | Show sourcetree stash information | **Enabled** |
| `--tool` | Show tool information | **Enabled** |
| `--treestatus` | Show source files information | **Enabled with -vv** |

### Hidden Options & Behaviors

#### 1. **Implicit Treestatus Inclusion**
- **Trigger**: When `MULLE_FLAG_LOG_FLUFF=YES` (verbose verbose mode)
- **Behavior**: Automatically adds `--treestatus` to status types
- **Usage**: `mulle-sde -vv status` or `MULLE_FLAG_LOG_FLUFF=YES mulle-sde status`

#### 2. **Default Status Types**
- **Default Set**: `"config,craftstatus,database,graveyard,project,quickstatus,stash,tool"`
- **Override**: Use `--clear` to start with empty set, then add specific types

#### 3. **Sourcetree Alias**
- **Hidden Behavior**: `--sourcetree` expands to `"database,quickstatus,treestatus"`
- **Purpose**: Provides comprehensive sourcetree overview without individual flags

#### 4. **Indentation Control**
- **Trigger**: `MULLE_FLAG_LOG_VERBOSE=YES` or `MULLE_FLAG_LOG_FLUFF=YES`
- **Effect**: Adds indentation to output for better readability

## Environment Variables

### Core Environment Variables

| Variable | Purpose | Default | Usage Examples |
|----------|---------|---------|----------------|
| `MULLE_SOURCETREE_CONFIG_NAME` | Sourcetree configuration name | `"config"` | Override for multi-config projects: `MULLE_SOURCETREE_CONFIG_NAME=debug mulle-sde status` |
| `MULLE_SOURCETREE_STASH_DIRNAME` | Stash directory name | `"stash"` | Custom stash location: `MULLE_SOURCETREE_STASH_DIRNAME=vendor mulle-sde status` |
| `MULLE_SOURCETREE_ETC_DIR` | Sourcetree etc directory | Auto-detected | Override for non-standard layouts |
| `MULLE_SOURCETREE_SHARE_DIR` | Sourcetree share directory | Auto-detected | Override for non-standard layouts |
| `MULLE_SOURCETREE_VAR_DIR` | Sourcetree var directory | Auto-detected | Override for non-standard layouts |
| `MULLE_SDE_ETC_DIR` | SDE etc directory | Auto-detected | Override for non-standard layouts |
| `MULLE_VIRTUAL_ROOT` | Virtual environment root | Auto-detected | Override for non-standard layouts |

### Logging & Output Control

| Variable | Purpose | Values |
|----------|---------|--------|
| `MULLE_FLAG_LOG_VERBOSE` | Enable verbose output | `YES`/`NO` |
| `MULLE_FLAG_LOG_FLUFF` | Enable very verbose output | `YES`/`NO` |
| `MULLE_TECHNICAL_FLAGS` | Technical flags for internal tools | Passed to subcommands |

### Tool Configuration

| Variable | Purpose | Example |
|----------|---------|---------|
| `MULLE_ENV` | mulle-env executable path | `MULLE_ENV=/opt/mulle-env/bin/mulle-env` |
| `MULLE_SOURCETREE` | mulle-sourcetree executable path | `MULLE_SOURCETREE=/usr/local/bin/mulle-sourcetree` |
| `MULLE_CRAFT` | mulle-craft executable path | `MULLE_CRAFT=/usr/local/bin/mulle-craft` |

## Hidden Behaviors & Conditional Logic

### 1. **Project Discovery Algorithm**

**Multi-level Project Detection:**
1. **Current Directory Check**: First checks if current directory is a project
2. **Parent Directory Search**: Recursively searches parent directories for project root
3. **Legacy Project Detection**: Identifies old project types:
   - `.mulle-sde/` - Upgradeable mulle-sde project
   - `.mulle-env/` - Upgradeable mulle-env environment  
   - `.mulle-bootstrap/` - Non-upgradeable mulle-bootstrap project

**Project Mode Determination:**
- **indir**: Commands execute in project directory
- **inproject**: Commands execute in project directory (explicit)
- **inparent**: Commands deferred to parent project (when `.mulle/share/env/defer` exists)

### 2. **Sourcetree Configuration Validation**

**Configuration Sync Detection:**
- Checks `repository/etc/mulle-sde/reflect` files for configuration mismatches
- Compares current config name with previously reflected config
- Reports repositories needing re-reflection

**Database Status Interpretation:**
- **Exit Code 2**: Dependencies need fetching/refreshing
- **Exit Code 0**: Database is up-to-date
- **Missing Database**: Reports "Nothing needs to be fetched"

### 3. **Stash Directory Analysis**

**Symlink Health Check:**
- **broken**: Symlink points to non-existent target
- **symlink**: Healthy symbolic link
- **directory**: Directory exists instead of expected symlink
- **file**: Regular file exists instead of expected symlink
- **missing**: Expected entry doesn't exist

**Color Coding:**
- **Red (C_RED)**: Broken or missing (FAIL)
- **Green (C_GREEN)**: Healthy symlink (OK)
- **Blue (C_BLUE)**: Directory (OK)
- **Magenta (C_MAGENTA)**: File (OK)

### 4. **Graveyard Detection**

**Automatic Cleanup Detection:**
- Checks `${MULLE_SOURCETREE_VAR_DIR}/graveyard` directory
- Uses `du` command to calculate size if available
- Provides cleanup command: `mulle-sde clean graveyard`

### 5. **Dependency Quick Status**

**State Detection:**
- **complete**: All dependencies built successfully
- **other states**: Triggers recommendation to run `mulle-sde craft`

## Practical Examples

### 1. **Basic Project Health Check**
```bash
# Standard status overview
mulle-sde status

# Verbose status with indentation
mulle-sde -v status

# Ultra-verbose with treestatus
mulle-sde -vv status
```

### 2. **Focused Diagnostics**

```bash
# Check only project configuration
mulle-sde status --clear --project --config

# Check only dependency status
mulle-sde status --clear --sourcetree

# Check build environment
mulle-sde status --clear --tool --craftstatus
```

### 3. **Migration Scenarios**

```bash
# Detect legacy projects in current directory
mulle-sde status
# Output: "There is an old possibly upgradable mulle-sde project..."

# Detect legacy environment
mulle-sde status
# Output: "There is an old possibly upgradable mulle-env environment..."

# Detect non-upgradeable bootstrap project
mulle-sde status  
# Output: "There is an old non-upgradable mulle-bootstrap project..."
```

### 4. **Multi-Project Navigation**

```bash
# In a subdirectory of a project
mulle-sde status
# Output: "mulle-sde commands are executed in /path/to/project (not /current/dir)"

# In a project with parent project
mulle-sde status
# Output: "mulle-sde commands are executed in child, but there is a parent project..."

# Commands deferred to parent (defer file exists)
mulle-sde status  
# Output: "mulle-sde commands are deferred to the parent project directory..."
```

### 5. **Dependency Troubleshooting**

```bash
# Check if dependencies need fetching
mulle-sde status --clear --database
# Output: "Dependencies will be fetched/refreshed according to database status"

# Check if dependencies are built
mulle-sde status --clear --quickstatus
# Output: "The dependency directory is complete" OR triggers craft recommendation

# Check configuration mismatches
mulle-sde status --clear --config
# Output: Lists repositories needing re-reflection with format "repo;oldconfig"
```

### 6. **Cleanup Scenarios**

```bash
# Check for graveyard cleanup needed
mulle-sde status --clear --graveyard
# Output: "There is a sourcetree graveyard of 45M size here"

# Check stash health
mulle-sde status --clear --stash
# Output: Lists stash contents with color-coded status
# stash/zlib-1.2.11;OK (green)
# stash/openssl;FAIL (red - broken symlink)
```

### 7. **Environment Debugging**

```bash
# Check tool availability
mulle-sde status --clear --tool
# Output: Runs "mulle-env tool doctor"

# Debug non-standard directory layout
MULLE_SOURCETREE_ETC_DIR=/custom/etc mulle-sde status --clear --sourcetree
MULLE_SOURCETREE_VAR_DIR=/custom/var mulle-sde status --clear --graveyard
```

## Troubleshooting Guide

### 1. **"No mulle-sde project" Error**

**Symptoms:**
```
There is no mulle-sde project in "/current/directory"
```

**Diagnosis:**
- Check if you're in the correct directory
- Look for `.mulle/share/env` directory
- Check for legacy project indicators: `.mulle-sde/`, `.mulle-env/`, `.mulle-bootstrap/`

**Solutions:**
```bash
# Navigate to project root
cd /path/to/project

# Initialize new project if needed
mulle-sde init

# Upgrade legacy project
mulle-sde upgrade
```

### 2. **Configuration Mismatch Issues**

**Symptoms:**
```
repo-name;old-config-name
```

**Diagnosis:**
- Configuration changed but not reflected
- Repository was moved or renamed

**Solutions:**
```bash
# Force re-reflection
mulle-sde reflect

# Check specific repository config
mulle-sde sourcetree list --config
```

### 3. **Dependency Build Issues**

**Symptoms:**
```
The dependency directory is not complete
```

**Diagnosis:**
- Missing dependencies
- Build failures in dependencies
- Incorrect build configuration

**Solutions:**
```bash
# Fetch and build dependencies
mulle-sde craft

# Check specific dependency issues
mulle-sde craftstatus --verbose

# Clean and rebuild
mulle-sde clean craftorder && mulle-sde craft
```

### 4. **Broken Symlinks in Stash**

**Symptoms:**
```
stash/library-name;FAIL (red)
```

**Diagnosis:**
- Target directory moved or deleted
- Incorrect fetch operation created directory instead of symlink

**Solutions:**
```bash
# Remove broken stash entry
rm -rf stash/library-name

# Re-fetch dependency
mulle-sde fetch library-name

# Or fix symlink manually
ln -s /correct/path stash/library-name
```

### 5. **Graveyard Accumulation**

**Symptoms:**
```
There is a sourcetree graveyard of 2.3G size here
```

**Diagnosis:**
- Old dependency versions accumulated
- Clean operations not removing graveyard

**Solutions:**
```bash
# Clean graveyard
mulle-sde clean graveyard

# Check what's in graveyard
ls -la .mulle/var/sourcetree/graveyard/

# Manual cleanup if needed
rm -rf .mulle/var/sourcetree/graveyard/*
```

### 6. **Tool Environment Issues**

**Symptoms:**
- Tool doctor reports missing tools
- Environment variables not set correctly

**Solutions:**
```bash
# Check tool environment
mulle-sde status --clear --tool

# Re-initialize environment
mulle-env tool install

# Check specific tool availability
which mulle-craft
which mulle-sourcetree
```

### 7. **Cross-Platform Issues**

**Symptoms:**
- Different behavior on different platforms
- Path or directory issues

**Solutions:**
```bash
# Check platform-specific variables
mulle-sde status --clear --tool

# Override platform defaults
MULLE_SOURCETREE_ETC_DIR=/custom/path mulle-sde status

# Check environment detection
mulle-env --search-as-is mulle-tool-env sourcetree
```

## Advanced Usage Patterns

### 1. **Automated Health Checks**
```bash
#!/bin/bash
# health-check.sh
if ! mulle-sde status --clear --project --quickstatus > /dev/null 2>&1; then
    echo "Project health check failed"
    mulle-sde status --clear --project --quickstatus
    exit 1
fi
echo "Project health: OK"
```

### 2. **Configuration Audit Script**
```bash
#!/bin/bash
# audit-config.sh
echo "=== Project Configuration Audit ==="
mulle-sde status --clear --config --database
echo "=== Build Environment ==="
mulle-sde status --clear --tool --craftstatus
echo "=== Cleanup Opportunities ==="
mulle-sde status --clear --graveyard --stash
```

### 3. **CI/CD Integration**
```bash
#!/bin/bash
# ci-check.sh
set -e

# Ensure we're in a project
mulle-sde status --clear --project

# Check dependencies are ready
if mulle-sde status --clear --quickstatus | grep -q "not complete"; then
    echo "Dependencies need building"
    mulle-sde craft
fi

# Final verification
mulle-sde status --all
```