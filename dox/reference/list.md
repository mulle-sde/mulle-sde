# mulle-sde list - Complete Reference

## Quick Start
List project information including files, dependencies, definitions, and environment variables to understand your project's structure and configuration.

## All Available Options

### Basic Options (in usage)
- `--all`: List dependencies, definitions, environment, files, and libraries
- `--dependencies`: List project dependencies
- `--no-dependencies`: Skip dependencies listing
- `--definitions`: List build definitions
- `--no-definitions`: Skip definitions listing
- `--environment`: List environment variables
- `--no-environment`: Skip environment listing
- `--files`: List project files by category
- `--no-files`: Skip files listing

### Hidden/Advanced Options (not in usage)
- `--libraries`: List non-dependency libraries
- `--no-libraries`: Skip libraries listing
  - **When to use**: When you want to focus only on dependencies and skip internal libraries
  - **Example**: `mulle-sde list --dependencies --no-libraries`
  - **Side effects**: Excludes libraries without dependency marks from the output

### Environment Control

#### Core Environment Variables
- `MULLE_MATCH`: Override the match tool used for file discovery
  - **Default**: `mulle-match`
  - **Set with**: `export MULLE_MATCH=/usr/local/bin/mulle-match`
  - **Use case**: When using a custom version of mulle-match or debugging file discovery

- `MULLE_SOURCETREE`: Override the sourcetree tool used for dependency listing
  - **Default**: `mulle-sourcetree`
  - **Set with**: `export MULLE_SOURCETREE=/usr/local/bin/mulle-sourcetree`
  - **Use case**: When using a custom sourcetree implementation

- `MULLE_TECHNICAL_FLAGS`: Pass additional flags to underlying tools
  - **Default**: (empty)
  - **Set with**: `export MULLE_TECHNICAL_FLAGS="--verbose --debug"`
  - **Use case**: For debugging tool interactions and seeing detailed output

- `MULLE_FLAG_LOG_TERSE`: Control output verbosity
  - **Default**: `NO`
  - **Set with**: `export MULLE_FLAG_LOG_TERSE=YES`
  - **Use case**: When scripting or piping output to other tools

- `MULLE_UNAME`: Override platform detection for cross-compilation
  - **Default**: System-detected platform name
  - **Set with**: `export MULLE_UNAME=linux`
  - **Use case**: When cross-compiling or simulating different platforms

#### File Discovery Environment
- `MULLE_MATCH_FILENAMES`: Control file pattern matching
  - **Default**: Project-specific patterns
  - **Set with**: `export MULLE_MATCH_FILENAMES="*.c,*.h,*.m,*.mm"`
  - **Use case**: When customizing which files are included in the project

- `MULLE_MATCH_IGNORE_PATH`: Specify paths to ignore during file discovery
  - **Default**: `.git,build,node_modules`
  - **Set with**: `export MULLE_MATCH_IGNORE_PATH=".git,build,third_party"`
  - **Use case**: When excluding specific directories from file listings

- `MULLE_MATCH_PATH`: Specify search paths for files
  - **Default**: Project root and common source directories
  - **Set with**: `export MULLE_MATCH_PATH="src:include:test"`
  - **Use case**: When files are in non-standard locations

#### Definition Environment Variables
- `PROJECT_TYPE`: Control project type behavior
  - **Default**: Determined during project initialization
  - **Set with**: `export PROJECT_TYPE=library`
  - **Use case**: When working with special project types like 'none'

- `MULLE_FLAG_MAGNUM_FORCE`: Force operations that would normally be skipped
  - **Default**: `NO`
  - **Set with**: `export MULLE_FLAG_MAGNUM_FORCE=YES`
  - **Use case**: When forcing file listing in 'none' type projects

## Hidden Behaviors Explained

### Project Type Filtering
The `PROJECT_TYPE` variable affects file listing behavior:
- **'none' projects**: File listing is skipped unless `MULLE_FLAG_MAGNUM_FORCE=YES`
- **Other projects**: All files are listed normally
- **Detection**: Project type is stored in `.mulle/etc/config/project/type`

### Platform-Specific Definition Resolution
Definitions follow a specific resolution order:
1. Platform-specific: `.mulle/etc/craft/definition.linux` (or current platform)
2. Global: `.mulle/etc/craft/definition/`
3. Shared platform-specific: `.mulle/share/craft/definition.linux`
4. Shared global: `.mulle/share/craft/definition/`

### File Category Discovery
Files are automatically categorized based on extensions and paths:
- **source**: `*.c`, `*.m`, `*.cpp`, `*.cxx`, `*.cc`
- **header**: `*.h`, `*.hpp`, `*.hh`, `*.hxx`
- **resource**: `*.plist`, `*.json`, `*.xml`
- **script**: `*.sh`, `*.py`, `*.pl`, `*.rb`
- **other**: Everything else

### Dependency vs Library Distinction
- **Dependencies**: Marked with both `dependency` and `fs` flags in sourcetree
- **Libraries**: Marked with `no-dependency` and `no-fs` flags
- **Internal**: Dependencies are external projects, libraries are local/static

### Output Format Control
- **Terse mode** (`MULLE_FLAG_LOG_TERSE=YES`): Raw output without headers or indentation
- **Normal mode**: Color-coded headers with hierarchical indentation
- **cmake mode**: Additional formatting for CMake variable names

## Practical Examples

### Common Hidden Usage Patterns

```bash
# List only specific categories
mulle-sde list --dependencies --definitions
mulle-sde list --files --environment

# Skip specific categories
mulle-sde list --all --no-libraries
mulle-sde list --all --no-definitions

# Force listing in special project types
PROJECT_TYPE=none MULLE_FLAG_MAGNUM_FORCE=YES mulle-sde list --files

# Use terse output for scripting
MULLE_FLAG_LOG_TERSE=YES mulle-sde list --dependencies > deps.txt

# Cross-platform definition viewing
MULLE_UNAME=darwin mulle-sde list --definitions
```

### Environment Variable Overrides

```bash
# Debug file discovery with custom ignore patterns
MULLE_MATCH_IGNORE_PATH=".git,build,third_party,generated" mulle-sde list --files

# Use custom match tool for special file types
MULLE_MATCH="mulle-match --format json" mulle-sde list --files

# Focus on specific file extensions
MULLE_MATCH_FILENAMES="*.c,*.h" mulle-sde list --files

# Search in non-standard locations
MULLE_MATCH_PATH="src:lib:test:include" mulle-sde list --files
```

### Integration Examples

```bash
# Get dependency list for CI
MULLE_FLAG_LOG_TERSE=YES mulle-sde list --dependencies | while read dep; do
    echo "Processing: $dep"
done

# Check for platform-specific definitions
if MULLE_UNAME=linux mulle-sde list --definitions | grep -q "LINUX_SPECIFIC"; then
    echo "Linux-specific configuration detected"
fi

# Generate file manifest
MULLE_FLAG_LOG_TERSE=YES mulle-sde list --files > project-files.txt

# Compare dependencies across platforms
diff <(MULLE_UNAME=linux mulle-sde list --dependencies) \
     <(MULLE_UNAME=darwin mulle-sde list --dependencies)
```

## Troubleshooting

### When to Use Hidden Options

**Files not appearing in list:**
- Check `MULLE_MATCH_IGNORE_PATH` for overly broad patterns
- Verify `MULLE_MATCH_PATH` includes your source directories
- Use `MULLE_FLAG_MAGNUM_FORCE=YES` for 'none' type projects

**Dependencies missing from output:**
- Ensure sourcetree is properly configured with `dependency` marks
- Check if dependencies are marked as `fs` (filesystem) dependencies
- Use `MULLE_SOURCETREE=mulle-sourcetree mulle-sourcetree list` to debug

**Definitions not showing platform-specific values:**
- Verify `.mulle/etc/craft/definition.${MULLE_UNAME}` exists
- Check if global definitions are overriding platform-specific ones
- Use `mulle-sde definition list --platform ${MULLE_UNAME}` to debug

**Environment variables not appearing:**
- Check if `mulle-env` is available in PATH
- Verify `.mulle/var/env/environment` exists
- Use `mulle-env environment list` to debug environment configuration

### Debugging Commands

```bash
# Verbose file discovery
MULLE_TECHNICAL_FLAGS="--verbose" mulle-sde list --files

# Check underlying tool paths
which mulle-match
which mulle-sourcetree
which mulle-env

# Inspect configuration directories
ls -la .mulle/etc/craft/definition*
ls -la .mulle/share/craft/definition*

# Test platform detection
echo "Platform: $MULLE_UNAME"
MULLE_UNAME=test mulle-sde list --definitions
```

### Common Issues and Solutions

**Issue**: "No files listed in 'none' projects"
- **Solution**: Use `MULLE_FLAG_MAGNUM_FORCE=YES` to override project type restriction

**Issue**: Empty dependency list despite having dependencies
- **Solution**: Ensure dependencies are properly marked with both `dependency` and `fs` flags

**Issue**: Platform-specific definitions not taking effect
- **Solution**: Check if global definitions exist and use `--platform` flag to force specific platform view

**Issue**: File categories not matching expectations
- **Solution**: Customize `MULLE_MATCH_FILENAMES` and `MULLE_MATCH_IGNORE_PATH` environment variables