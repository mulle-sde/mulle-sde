# mulle-sde environment - Complete Reference

## Quick Start
Manage environment variables and configuration settings for mulle-sde projects across multiple scopes (global, host, user, project).

## All Available Options

### Basic Options (in usage)
- `list`: List environment variables
- `set`: Set an environment variable
- `get`: Get value of an environment variable
- `remove`: Remove an environment variable
- `scope`: Add, remove and list scopes

### Advanced Options (hidden)

#### Scope Targeting Options
- `--host <name>`: Narrow scope to host with name
  - **When to use**: When managing host-specific settings on shared environments
  - **Example**: `mulle-sde environment --host macbook set CFLAGS "-O2"`
  - **Side effects**: Creates/updates `.mulle/etc/env/environment-host-macbook.sh`

- `--os <name>`: Narrow scope to operating system
  - **When to use**: When managing OS-specific settings for cross-platform development
  - **Example**: `mulle-sde environment --os linux set LDFLAGS "-static"`
  - **Side effects**: Creates/updates `.mulle/etc/env/environment-os-linux.sh`

- `--user <name>`: Narrow scope to user with name
  - **When to use**: When managing user-specific settings in shared environments
  - **Example**: `mulle-sde environment --user alice set EDITOR "vim"`
  - **Side effects**: Creates/updates `.mulle/etc/env/environment-user-alice.sh`

- `--scope <name>`: Use an arbitrarily named scope
  - **When to use**: When creating custom environment configurations
  - **Example**: `mulle-sde environment --scope debug set CFLAGS "-g -O0"`
  - **Side effects**: Creates/updates `.mulle/etc/env/environment-debug.sh`

- `--this-host`: Narrow scope to current host
  - **When to use**: Quick targeting of current machine
  - **Example**: `mulle-sde environment --this-host set MULLE_SDE_DEBUG "YES"`
  - **Side effects**: Uses current hostname for scope

- `--this-os`: Narrow scope to current operating system
  - **When to use**: Quick targeting of current OS
  - **Example**: `mulle-sde environment --this-os set MULLE_CRAFT_SHARED_DIR "/opt/mulle"`
  - **Side effects**: Uses current OS name for scope

- `--this-user`: Narrow scope to current user
  - **When to use**: Quick targeting of current user
  - **Example**: `mulle-sde environment --this-user set MULLE_FETCH_SEARCH_PATH "$HOME/src"`
  - **Side effects**: Uses current username for scope

- `--this-os-user`: Narrow scope to current user and OS combination
  - **When to use**: When managing settings specific to user+OS combinations
  - **Example**: `mulle-sde environment --this-os-user set PATH "/usr/local/go/bin:$PATH"`
  - **Side effects**: Creates combined user-OS scope

#### Command-Specific Options

##### For `set` command
- `--append`: Add value to existing values (using separator ':')
  - **When to use**: When building PATH-like variables
  - **Example**: `mulle-sde environment set MULLE_FETCH_SEARCH_PATH --append "/usr/local/src"`
  - **Side effects**: Concatenates with existing values using ':' separator

- `--prepend`: Prepend value to existing values (using separator ':')
  - **When to use**: When adding priority paths
  - **Example**: `mulle-sde environment set PATH --prepend "$HOME/bin"`
  - **Side effects**: Adds to beginning of existing values

- `--concat`: Add value to existing value with space
  - **When to use**: When building space-separated flags
  - **Example**: `mulle-sde environment set CFLAGS --concat "-Wall"`
  - **Side effects**: Concatenates with space separator

- `--concat0`: Add value to existing value without separator
  - **When to use**: When building exact strings
  - **Example**: `mulle-sde environment set VERSION --concat0 "1.2"`
  - **Side effects**: No separator between values

- `--remove`: Remove value from existing values (using separator ':')
  - **When to use**: When cleaning up PATH-like variables
  - **Example**: `mulle-sde environment set PATH --remove "/old/path"`
  - **Side effects**: Removes specified value from list

- `--separator <sep>`: Specify custom separator for --append/--prepend/--remove
  - **When to use**: When working with non-standard separators
  - **Example**: `mulle-sde environment set CFLAGS --separator " " --append "-O2"`
  - **Side effects**: Uses specified separator instead of ':'

- `--comment-out-empty`: Comment out instead of removing empty values
  - **When to use**: When preserving variable structure
  - **Example**: `mulle-sde environment set DEBUG --comment-out-empty ""`
  - **Side effects**: Comments out the line instead of removing it

- `--no-add-empty`: Don't add empty values
  - **When to use**: When avoiding empty variable assignments
  - **Example**: `mulle-sde environment set VAR --no-add-empty ""`
  - **Side effects**: Skips setting if value is empty

##### For `get` command
- `--lenient`: Return 0 on not found instead of 4
  - **When to use**: When scripting and need consistent return codes
  - **Example**: `mulle-sde environment get NONEXISTENT --lenient`
  - **Side effects**: Returns 0 instead of 4 for missing keys

- `--output-eval`: Resolve value with other environment variables
  - **When to use**: When you need fully evaluated values
  - **Example**: `mulle-sde environment get PATH --output-eval`
  - **Side effects**: Expands variables like $HOME in output

- `--output-sed`: Emit as sed replacement pattern
  - **When to use**: When scripting file modifications
  - **Example**: `mulle-sde environment get VERSION --output-sed`
  - **Side effects**: Outputs sed-compatible replacement patterns

##### For `list` command
- `--output-eval`: Resolve values with environment variables
  - **When to use**: When you need to see actual values
  - **Example**: `mulle-sde environment list --output-eval`
  - **Side effects**: Shows fully expanded values

- `--output-command`: Emit as mulle-env commands
  - **When to use**: When exporting configurations
  - **Example**: `mulle-sde environment list --output-command`
  - **Side effects**: Outputs commands to recreate environment

- `--output-sed`: Emit as sed replacement patterns
  - **When to use**: When bulk editing files
  - **Example**: `mulle-sde environment list --output-sed`
  - **Side effects**: Outputs sed patterns for mass replacement

- `--cat`: Unsorted output
  - **When to use**: When preserving original order
  - **Example**: `mulle-sde environment list --cat`
  - **Side effects**: Disables alphabetical sorting

### Environment Variables

#### MULLE_ENV_DEFAULT_STYLE
- **What it controls**: Default environment style when initializing new environments
- **Default**: `"developer/relax"`
- **Set with**: `export MULLE_ENV_DEFAULT_STYLE="developer/strict"`
- **Use case**: When you want stricter environment isolation by default

#### MULLE_ENV_ETC_DIR
- **What it controls**: Location of environment configuration files
- **Default**: `.mulle/etc/env`
- **Set with**: `export MULLE_ENV_ETC_DIR="/custom/path/etc"`
- **Use case**: When relocating environment configurations

#### MULLE_ENV_SHARE_DIR
- **What it controls**: Location of shared environment files
- **Default**: `.mulle/share/env`
- **Set with**: `export MULLE_ENV_SHARE_DIR="/custom/path/share"`
- **Use case**: When sharing configurations across projects

#### MULLE_ENV_VAR_DIR
- **What it controls**: Location of variable environment files
- **Default**: `.mulle/var/env`
- **Set with**: `export MULLE_ENV_VAR_DIR="/custom/path/var"`
- **Use case**: When separating variable from static configurations

#### MULLE_ENV_CONTENT_SORT
- **What it controls**: Sorting behavior for environment listings
- **Default**: `"sort"`
- **Set with**: `export MULLE_ENV_CONTENT_SORT="cat"`
- **Use case**: When preserving configuration file order

#### MULLE_ENVIRONMENT_KEYS
- **What it controls**: Variables preserved in restricted environments
- **Default**: Comprehensive list including MULLE_UNAME, MULLE_HOSTNAME, MULLE_USERNAME, etc.
- **Set with**: `export MULLE_ENVIRONMENT_KEYS="CUSTOM_VAR1 CUSTOM_VAR2"`
- **Use case**: When extending preserved variables beyond defaults

#### MULLE_ENVIRONMENT_RELAX_KEYS
- **What it controls**: Additional variables preserved in relaxed environments
- **Default**: Includes USER, LOGNAME, HOME, etc.
- **Set with**: `export MULLE_ENVIRONMENT_RELAX_KEYS="SSH_AUTH_SOCK DISPLAY"`
- **Use case**: When specific system variables must be available

#### MULLE_SDE_SANDBOX
- **What it controls**: External sandboxing tool (like lljail) for environment isolation
- **Default**: Not set
- **Set with**: `export MULLE_SDE_SANDBOX="lljail"`
- **Use case**: When additional security/isolation is required

#### MULLE_SDE_SANDBOX_FLAGS
- **What it controls**: Flags passed to sandboxing tool
- **Default**: Not set
- **Set with**: `export MULLE_SDE_SANDBOX_FLAGS="--network=none"`
- **Use case**: When customizing sandbox behavior

## Hidden Behaviors Explained

### Environment Scope Resolution Order
When using DEFAULT scope, variables are resolved in this exact order:
1. **user-<username>-os-<osname>** (most specific)
2. **user-<username>** (user-specific)
3. **host-<hostname>** (host-specific)
4. **os-<osname>** (OS-specific)
5. **global** (project-wide)
6. **extension** (extension defaults)
7. **project** (project defaults)
8. **plugin** (plugin defaults)

### Variable Expansion Behavior
- **Quoted values**: Double-quoted values are preserved exactly
- **Shell variables**: `$VAR` and `${VAR}` are expanded during evaluation
- **Command substitution**: Backticks and `$(command)` are evaluated
- **Path expansion**: `~` is expanded to user's home directory

### File Protection Mechanism
- **Automatic protection**: Files are created as read-only by default
- **Temporary unprotection**: Files are unprotected during modifications
- **Directory protection**: Parent directories are also protected/unprotected as needed
- **Git compatibility**: Protection settings are compatible with version control

### Cross-Scope Interactions
- **Global scope cleanup**: Setting in global scope removes conflicting values from sub-scopes
- **Scope inheritance**: Lower scopes inherit from higher scopes unless overridden
- **Value merging**: List variables (like PATH) can be merged across scopes
- **Precedence rules**: Later scopes override earlier ones in resolution order

### Hidden Commands and Features
- **clobber**: Internal command to remove all variables from a scope
  - **Usage**: `mulle-sde environment --scope debug clobber`
  - **Effect**: Removes entire scope configuration file

- **mset**: Internal command for mass setting with specific formatting
  - **Usage**: `mulle-sde environment --scope global mset "VAR1=\"value1\"##comment1" "VAR2=\"value2\"##comment2"`
  - **Effect**: Sets multiple variables with comments efficiently

## Practical Examples

### Common Hidden Usage Patterns

#### Managing Compiler Flags Across Platforms
```bash
# Set Linux-specific flags
mulle-sde environment --os linux set CFLAGS "-O2 -Wall -D_GNU_SOURCE"

# Set macOS-specific flags
mulle-sde environment --os darwin set CFLAGS "-O2 -Wall -mmacosx-version-min=10.15"

# Set host-specific optimization flags
mulle-sde environment --this-host set CFLAGS "-O3 -march=native"
```

#### Managing Build Paths
```bash
# Add custom include path globally
mulle-sde environment --global set MULLE_CRAFT_INCLUDE_PATH --append "/opt/local/include"

# Add library path for specific host
mulle-sde environment --host buildserver set MULLE_CRAFT_LIBRARY_PATH --append "/opt/local/lib"

# Prepend local bin directory for current user
mulle-sde environment --this-user set PATH --prepend "$HOME/.local/bin"
```

#### Configuration Management
```bash
# Set debug configuration
mulle-sde environment --scope debug set CFLAGS "-g -O0 -DDEBUG=1"

# Set release configuration
mulle-sde environment --scope release set CFLAGS "-O3 -DNDEBUG"

# Switch between configurations
mulle-sde environment --scope debug list
```

#### Scripting and Automation
```bash
# Get evaluated value for scripting
CC=$(mulle-sde environment get CC --output-eval)

# Generate sed patterns for bulk editing
mulle-sde environment list --output-sed > patterns.sed

# Export current environment as commands
mulle-sde environment list --output-command > restore-env.sh
```

#### Cross-User Development Setup
```bash
# Set project-wide defaults
mulle-sde environment --global set PROJECT_NAME "MyApp"

# Set user-specific editor
mulle-sde environment --this-user set EDITOR "vim"

# Set host-specific paths
mulle-sde environment --this-host set MULLE_CRAFT_SHARED_DIR "/shared/mulle"
```

### Environment Variable Overrides

#### Temporary Override for Single Command
```bash
# Run with custom environment
MULLE_ENV_DEFAULT_STYLE="developer/strict" mulle-sde craft

# Override environment file location
MULLE_ENV_ETC_DIR="/tmp/config" mulle-sde environment list
```

#### Project-Specific Configuration
```bash
# Create project-specific environment
cd myproject
mulle-sde environment --scope project set MULLE_CRAFT_BUILD_DIR "build"

# Override for specific build
cd myproject
MULLE_ENV_ETC_DIR="$(pwd)/custom-env" mulle-sde craft
```

## Troubleshooting

### When to Use Hidden Options

#### Scope Resolution Issues
**Problem**: Variable values not taking effect
**Solution**: Check scope precedence with `mulle-sde environment scope --output-filename`
```bash
# See which files are being used
mulle-sde environment scope --output-filename | xargs ls -la

# Check variable in specific scope
mulle-sde environment --scope user-$(whoami) get VARNAME
```

#### Variable Expansion Problems
**Problem**: Variables not expanding correctly
**Solution**: Use --output-eval to debug
```bash
# Check evaluated value
mulle-sde environment get PATH --output-eval

# Compare with raw value
mulle-sde environment get PATH
```

#### Multi-Environment Conflicts
**Problem**: Settings from different environments conflicting
**Solution**: Use specific scopes and cleanup
```bash
# Remove conflicting global setting
mulle-sde environment --global remove CONFLICTING_VAR

# Set in more specific scope
mulle-sde environment --this-host set CONFLICTING_VAR "correct_value"
```

#### Permission Issues
**Problem**: Cannot modify environment files
**Solution**: Check protection status and use --protect-flag
```bash
# Temporarily disable protection
mulle-sde environment --protect-flag NO set VAR value

# Or use force flag
MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde environment set VAR value
```

#### Path Separator Issues
**Problem**: PATH-like variables with wrong separators
**Solution**: Use custom separators
```bash
# Use space separator for flags
mulle-sde environment set CFLAGS --separator " " --append "-Wall"

# Use semicolon for Windows paths
mulle-sde environment set INCLUDE --separator ";" --append "C:\include"
```

### Debugging Environment Issues
```bash
# List all scopes with files
mulle-sde environment scope --all

# Check exact file locations
mulle-sde environment scope --output-filename

# See evaluated environment
mulle-sde environment list --output-eval

# Export current environment for debugging
mulle-sde environment list --output-command > debug-env.sh
```

### Common Edge Cases

#### Empty vs. Undefined Variables
```bash
# Empty string (variable exists but empty)
mulle-sde environment set VAR ""

# Undefined (variable doesn't exist)
mulle-sde environment remove VAR

# Check difference
mulle-sde environment get VAR --lenient; echo $?  # 0 for empty, 1 for undefined
```

#### Special Characters in Values
```bash
# Handle quotes
mulle-sde environment set MESSAGE '"Hello World"'

# Handle dollar signs
mulle-sde environment set PROMPT '\$ '

# Handle backslashes
mulle-sde environment set ESCAPED 'C:\\Program Files'
```

#### Cross-Platform Path Handling
```bash
# Platform-specific paths
mulle-sde environment --os linux set MULLE_CRAFT_SHARED_DIR "/opt/mulle"
mulle-sde environment --os darwin set MULLE_CRAFT_SHARED_DIR "/usr/local/mulle"
mulle-sde environment --os windows set MULLE_CRAFT_SHARED_DIR "C:\\mulle"
```