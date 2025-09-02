# mulle-sde fetch - Complete Reference

## Quick Start
Sync and fetch all project dependencies, ensuring correct versions are installed and up-to-date.

```bash
mulle-sde fetch                    # Fetch all dependencies
mulle-sde fetch --serial           # Fetch without parallel processing
mulle-sde fetch --no-reflect       # Skip automatic reflect after fetch
```

## Command Overview

**Purpose**: The `fetch` command synchronizes your project's dependency tree by fetching missing dependencies and ensuring existing ones match their specified versions. It serves as a wrapper around `mulle-sourcetree sync` with additional project-specific intelligence.

**Primary use cases**:
- Initial project setup after cloning
- Updating dependencies after version changes
- Ensuring consistency across team environments
- Resolving dependency conflicts
- Preparing for builds in CI/CD pipelines

## All Available Options

### Basic Options (in usage)
```
--serial                     : don't fetch dependencies in parallel
--no-reflect                 : does not run a reflect after a sync
```

### Hidden/Advanced Options

**Pass-through Options to mulle-sourcetree**: The fetch command transparently passes all unrecognized arguments to `mulle-sourcetree sync`, enabling advanced usage patterns:

```bash
mulle-sde fetch --share              # Share repositories between projects
mulle-sde fetch --recurse            # Recursively fetch sub-dependencies
mulle-sde fetch --branch master      # Fetch specific branch
mulle-sde fetch --tag v1.0.0         # Fetch specific tag
mulle-sde fetch --depth 1            # Shallow clone for faster fetch
```

### Environment Control

**Core Environment Variables**:
```bash
# Disable fetching entirely
MULLE_SDE_FETCH=NO
# Usage: export MULLE_SDE_FETCH=NO  # Skip all dependency fetching

# Local archive cache for faster repeated fetches
MULLE_FETCH_ARCHIVE_DIR=/path/to/cache
# Usage: export MULLE_FETCH_ARCHIVE_DIR="$HOME/.mulle/cache"

# Local git mirror for faster repository access
MULLE_FETCH_MIRROR_DIR=/path/to/mirror
# Usage: export MULLE_FETCH_MIRROR_DIR="$HOME/.mulle/mirror"

# Additional search paths for local dependencies
MULLE_FETCH_SEARCH_PATH=/path1:/path2:/path3
# Usage: export MULLE_FETCH_SEARCH_PATH="$HOME/projects:/opt/dependencies"

# Control tag resolution behavior
MULLE_SOURCETREE_RESOLVE_TAG=NO
# Usage: export MULLE_SOURCETREE_RESOLVE_TAG=NO  # Skip automatic tag resolution
```

## Hidden Behaviors Explained

### Smart Update Detection

**Conditional Fetch Logic**: The fetch command performs intelligent checks before initiating a sync:

1. **Up-to-date Check**: Uses `mulle-sourcetree status --is-uptodate` to determine if sync is needed
2. **Database Integrity**: Checks database status with `mulle-sourcetree dbstatus`
3. **Skip Conditions**: Will skip fetching if:
   - All dependencies are current
   - No configuration changes detected
   - Database integrity is verified

**Return Code Analysis**:
- `0`: Dependencies are current, no action taken
- `non-zero`: Will proceed with sync operation
- `2`: Database needs cleanup, will trigger sync

### Automatic Reflect Integration

**Post-Fetch Reflect**: After successful fetch operations, the command automatically triggers `mulle-sde reflect` to:
- Update build system files (CMakeLists.txt)
- Regenerate header search paths
- Update dependency metadata
- Rebuild craftorder files

**Skip Reflect Behavior**: Use `--no-reflect` to prevent automatic reflection when:
- Performing bulk operations
- Debugging dependency issues
- Manual reflect control needed

### Parallel vs Serial Execution

**Default Parallel Processing**: Uses multiple processes for faster fetching across dependencies with independent repositories.

**Serial Mode Benefits**: Use `--serial` when:
- Network bandwidth is limited
- Repository servers have rate limits
- Debugging individual dependency issues
- Working with shared filesystems

## Practical Examples

### Common Hidden Usage Patterns

```bash
# Skip fetch during development (useful for offline work)
export MULLE_SDE_FETCH=NO
mulle-sde craft

# Use local cache for repeated fetches
export MULLE_FETCH_ARCHIVE_DIR="$HOME/.mulle/cache"
mulle-sde fetch

# Mirror all dependencies locally for team sharing
export MULLE_FETCH_MIRROR_DIR="/shared/mirror"
mulle-sde fetch

# Search local paths before remote fetching
export MULLE_FETCH_SEARCH_PATH="$HOME/projects/vendor:$HOME/oss"
mulle-sde fetch

# Skip tag resolution for development branches
export MULLE_SOURCETREE_RESOLVE_TAG=NO
mulle-sde fetch --branch develop
```

### Advanced Fetch Scenarios

```bash
# Fetch with specific branch and shallow clone
mulle-sde fetch --branch feature/new-api --depth 1

# Force re-fetch of all dependencies
MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde fetch

# Fetch with custom sourcetree flags
mulle-sde fetch --serial --share --recurse

# Skip reflect for debugging
mulle-sde fetch --no-reflect
mulle-sde status  # Check status without automatic reflect
```

### Integration with Other Commands

**Dependency Management Workflow**:
```bash
# Add new dependency and fetch immediately
mulle-sde add github:user/repo
mulle-sde fetch

# Update specific dependency
mulle-sde dependency set user/repo --tag v2.0.0
mulle-sde fetch

# Clean and re-fetch all dependencies
mulle-sde clean cache
mulle-sde fetch
```

**Build Integration**:
```bash
# Ensure dependencies are current before build
mulle-sde fetch && mulle-sde craft

# Skip fetch during build (if already fetched)
MULLE_SDE_FETCH=NO mulle-sde craft
```

## Troubleshooting

### Common Fetch Issues

**Problem**: Fetch hangs or times out
```bash
# Solution: Use serial mode for slower networks
mulle-sde fetch --serial
```

**Problem**: Dependencies not updating to new versions
```bash
# Solution: Force re-fetch
MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde fetch
```

**Problem**: Archive corruption or incomplete downloads
```bash
# Solution: Clear cache and re-fetch
mulle-sde clean cache
mulle-sde fetch
```

**Problem**: Local development dependencies not found
```bash
# Solution: Add local search path
export MULLE_FETCH_SEARCH_PATH="/path/to/local/dependencies"
mulle-sde fetch
```

### Debugging Fetch Behavior

**Verbose Output**:
```bash
# Enable verbose logging
mulle-sde -v fetch

# Check what would be fetched (dry run)
mulle-sourcetree sync --dry-run
```

**Status Investigation**:
```bash
# Check current dependency status
mulle-sde status
mulle-sourcetree dbstatus

# List all dependencies with versions
mulle-sde dependency list
```

### Environment Variable Overrides for Specific Scenarios

**Corporate Proxy Environment**:
```bash
export MULLE_FETCH_ARCHIVE_DIR="/shared/cache"
export MULLE_FETCH_MIRROR_DIR="/shared/mirror"
export MULLE_SOURCETREE_RESOLVE_TAG=NO  # Skip external resolution
```

**CI/CD Optimization**:
```bash
# Cache dependencies between builds
export MULLE_FETCH_ARCHIVE_DIR="$CI_CACHE_DIR/archives"
export MULLE_FETCH_MIRROR_DIR="$CI_CACHE_DIR/mirrors"

# Skip fetch if dependencies cached
if [ -d "$CI_CACHE_DIR/archives" ]; then
    export MULLE_SDE_FETCH=NO
fi
```

**Offline Development**:
```bash
# Use only local resources
export MULLE_SDE_FETCH=NO
export MULLE_FETCH_SEARCH_PATH="/local/dependencies"
```

## Cross-Platform Considerations

**Platform-Specific Paths**:
- **Linux/macOS**: Use standard Unix paths
- **Windows**: Use Git Bash or WSL paths
- **Docker**: Mount volumes for persistent caches

**Network Configuration**:
- **Corporate firewalls**: May require serial mode
- **VPN connections**: Consider local mirrors
- **Slow links**: Use archive caching extensively

## Integration Architecture

**How fetch relates to other commands**:

```
mulle-sde add ’ Updates sourcetree ’ mulle-sde fetch ’ Updates dependencies
                                     “
                              mulle-sde reflect ’ Updates build files
                                     “
                              mulle-sde craft ’ Builds project
```

**Internal Dependencies**:
- **mulle-sourcetree**: Core synchronization engine
- **mulle-fetch**: Individual dependency fetching
- **mulle-sde reflect**: Build system updates
- **mulle-craft**: Build orchestration

**Configuration Files Affected**:
- `.mulle/etc/sourcetree/config`: Dependency definitions
- `.mulle/share/sourcetree/config`: Shared configurations
- `CMakeLists.txt`: Build system (via reflect)
- `craftorder`: Build order (via craft)