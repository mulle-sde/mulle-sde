# mulle-sde clean - Complete Reference

## Quick Start
Clean build artifacts, dependencies, and caches to force rebuilds and resolve build issues.

```bash
# Basic project clean
mulle-sde clean

# Clean everything including dependencies
mulle-sde clean all

# Clean specific dependency
mulle-sde clean zlib

# Preview what will be cleaned
mulle-sde -v -n -lx clean
```

## All Available Options

### Basic Options (in usage)
```
--gui          : on participating platforms use a GUI menu
--interactive  : choose dependency to clean from a menu
--no-graveyard : do not create backups in graveyard
--no-test      : do not check, if a dependecy exists
-h, --help     : show help
```

### Advanced Options (hidden)
```
--domain [domain]        : specify exact domain to clean
--clean-domain [domain]  : alias for --domain
--from [domain]          : alias for --domain
--lenient                : ignore unknown targets instead of failing
--no-default             : disable MULLE_SDE_CLEAN_DEFAULT environment variable
-a, -C, --all            : shortcut for 'all' domain
-g, --gravetidy          : shortcut for 'gravetidy' domain
-i                       : shortcut for --interactive
```

### Environment Control
```
- MULLE_SDE_CLEAN_DEFAULT
  - What it controls: Default domains to clean when no domain specified
  - Default: "project:subproject:var"
  - Set with: export MULLE_SDE_CLEAN_DEFAULT="project:subproject"
  - Use case: Customize default clean behavior for your workflow

- MULLE_SOURCETREE_GRAVEYARD_ENABLED
  - What it controls: Whether to create backup copies in graveyard
  - Default: YES (enabled)
  - Set with: export MULLE_SOURCETREE_GRAVEYARD_ENABLED="NO"
  - Use case: Disable graveyard to save disk space during large cleans

- MULLE_FETCH_ARCHIVE_DIR
  - What it controls: Location of downloaded archive cache
  - Default: .mulle/var/cache/archives
  - Use case: Custom archive cache location for CI/CD

- MULLE_FETCH_MIRROR_DIR
  - What it controls: Location of git repository mirrors
  - Default: .mulle/var/cache/mirrors
  - Use case: Shared mirror cache across projects

- MULLE_SDE_VAR_DIR
  - What it controls: Base directory for mulle-sde state
  - Default: .mulle/var/<hostname>/<username>/sde
  - Use case: Custom state directory for multiple projects

- MULLE_VIRTUAL_ROOT
  - What it controls: Root directory for build artifacts
  - Default: Project root
  - Use case: Separate build artifacts from source tree

- DEPENDENCY_DIR
  - What it controls: Directory containing built dependencies
  - Default: ${MULLE_VIRTUAL_ROOT}/dependency
  - Use case: Custom dependency location for shared libraries

- KITCHEN_DIR
  - What it controls: Directory for intermediate build files
  - Default: ${MULLE_VIRTUAL_ROOT}/kitchen
  - Use case: Custom build directory for disk space management
```

## Hidden Behaviors Explained

### Domain Resolution System
The clean command uses a sophisticated domain resolution system that maps user-friendly names to actual cleanup operations:

**Domain Mapping Table:**
```
all         ’ kitchendir:dependencydir:varcaches
alltestall  ’ kitchendir:dependencydir:varcaches:testall
archive     ’ archive
craftinfos  ’ craftinfo
craftorder  ’ var (via mulle-craft) + var manually
default     ’ project:subproject:var (or interactive selection)
dependency  ’ dependencydir
fetch       ’ sourcetree:varcaches:output:var:db:monitor:patternfile:archive
graveyard   ’ graveyard
gravetidy   ’ graveyard:sourcetree_share:varcaches:output:var:db:monitor:patternfile
mirror      ’ mirror
project     ’ project
subprojects ’ subproject
test        ’ test
tidy        ’ sourcetree_share:varcaches:output:var:db:monitor:patternfile
tmp         ’ tmp
varcaches   ’ varcaches
```

### Automatic Target Detection
When you specify a target name instead of a domain, the system:
1. Reads the craftorder cache from `.mulle/var/cache/targets`
2. Validates the target exists in the cache
3. Falls back to lenient mode if `--lenient` is used
4. Executes `mulle-craft clean [target]` followed by `project:subproject`

### Cache Management
**Targets Cache:**
- Location: `.mulle/var/cache/targets`
- Auto-generated when missing via `mulle-sourcetree craftorder`
- Strips stash directory prefixes from target names
- Ignores craftinfo/ entries

**Cache Cleaning Patterns:**
- **varcaches**: Cleans `.mulle/var/*/cache` directories across all tools
- **archive**: Removes `.mulle/var/cache/archives`
- **mirror**: Removes `.mulle/var/cache/mirrors` (requires -f flag)

### Graveyard System
The graveyard creates backups of removed directories:
- **Default behavior**: Enabled (MULLE_SOURCETREE_GRAVEYARD_ENABLED=YES)
- **gravetidy**: Automatically disables graveyard to prevent backup loops
- **--no-graveyard**: Disables graveyard for specific clean operations

### Cross-Platform Tool Integration
The clean command orchestrates multiple mulle tools:
- **mulle-craft**: Handles build artifact cleaning
- **mulle-sourcetree**: Manages source tree state
- **mulle-monitor**: Cleans monitoring files
- **mulle-match**: Cleans pattern files
- **mulle-test**: Cleans test artifacts

## Practical Examples

### Common Hidden Usage Patterns

```bash
# Clean specific domains with --domain
mulle-sde clean --domain graveyard          # Clean only graveyard
mulle-sde clean --domain archive:mirror     # Clean both caches

# Clean with environment overrides
MULLE_SDE_CLEAN_DEFAULT="project" mulle-sde clean  # Clean only project
MULLE_SOURCETREE_GRAVEYARD_ENABLED=NO mulle-sde clean tidy  # No backups

# Interactive selection
mulle-sde clean --interactive               # Choose from menu
mulle-sde clean --gui                       # GUI selection (macOS)

# Lenient cleaning (ignore unknown targets)
mulle-sde clean --lenient nonexistent-target  # No error

# Clean specific dependency by name
mulle-sde clean zlib                        # Clean zlib dependency
mulle-sde clean --no-test unknown-lib       # Skip existence check

# Preview cleaning operations
mulle-sde -v -n -lx clean all               # See what would be cleaned
mulle-sde -v clean tidy                     # Verbose output with cleanup

# Clean without affecting graveyard
mulle-sde clean --no-graveyard all          # Clean without backups
```

### Environment Variable Overrides

```bash
# Custom clean defaults for development
export MULLE_SDE_CLEAN_DEFAULT="project:subproject"
mulle-sde clean                             # Only cleans project and subprojects

# Shared cache location
export MULLE_FETCH_ARCHIVE_DIR="/opt/mulle/cache/archives"
export MULLE_FETCH_MIRROR_DIR="/opt/mulle/cache/mirrors"
mulle-sde clean archive                     # Clean shared archives

# Custom build directory
export KITCHEN_DIR="/tmp/myproject-build"
mulle-sde clean                             # Clean custom build directory

# Separate dependency storage
export DEPENDENCY_DIR="/opt/mulle/deps/myproject"
mulle-sde clean dependency                  # Clean custom dependency dir
```

### Advanced Domain Combinations

```bash
# Clean for complete rebuild
mulle-sde clean gravetidy                   # Everything including graveyard

# Clean for dependency updates
mulle-sde clean fetch                       # Force refetch from remotes

# Clean for CI/CD
mulle-sde clean alltestall                  # Clean all including tests

# Clean specific components
mulle-sde clean craftinfos                  # Regenerate craftinfos
mulle-sde clean craftorder                  # Rebuild dependency order
```

## Troubleshooting

### When to Use Hidden Options

**Clean not working as expected:**
```bash
# Check what will be cleaned first
mulle-sde -v -n -lx clean [domain]

# Clean specific target when generic clean fails
mulle-sde clean [specific-dependency-name]

# Force mirror clean (requires -f flag)
mulle-sde -f clean mirror
```

**Disk space issues:**
```bash
# Clean graveyard to free space
mulle-sde clean graveyard

# Clean without creating new backups
mulle-sde clean --no-graveyard all

# Clean all caches
mulle-sde clean archive:mirror
```

**Build system inconsistencies:**
```bash
# Complete clean rebuild
mulle-sde clean gravetidy && mulle-sde craft

# Clean and rebuild dependency cache
mulle-sde clean fetch && mulle-sde craft

# Clean test artifacts
mulle-sde clean testall
```

**Debugging clean failures:**
```bash
# Verbose output to see what's happening
mulle-sde -v clean [domain]

# Check if target exists
mulle-sde clean --no-test [target]

# Ignore unknown targets during debugging
mulle-sde clean --lenient [target]
```

### Environment Debugging

```bash
# Check current environment variables
env | grep -E "(MULLE_|DEPENDENCY_|KITCHEN_)"

# Override specific directories for testing
MULLE_SDE_VAR_DIR="/tmp/test-var" mulle-sde clean

# Test with different graveyard settings
MULLE_SOURCETREE_GRAVEYARD_ENABLED=YES mulle-sde clean tidy
```

### Common Error Messages

**"Unknown clean target"**
- Use `mulle-sde clean --lenient [target]` to ignore
- Check available targets with `mulle-sourcetree craftorder`

**"Need -f flag for mirror cleaning"**
- Use `mulle-sde -f clean mirror` to force mirror clean

**"MULLE_FETCH_ARCHIVE_DIR is not defined"**
- Usually indicates missing project initialization
- Run `mulle-sde reflect` to regenerate environment

**"DEPENDENCY_DIR unknown"**
- Check if project is properly initialized
- Verify MULLE_VIRTUAL_ROOT is set correctly