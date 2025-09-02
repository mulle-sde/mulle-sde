# mulle-sde match - Complete Reference

## Quick Start
The `mulle-sde match` command provides file pattern matching and filtering capabilities for mulle-sde projects. It uses the underlying `mulle-match` tool to work with patternfiles that categorize and filter project files.

```bash
# List all files matching project patternfiles
mulle-sde match

# Test which patternfile matches a specific filename
mulle-sde match filename myfile.c

# List only C source files
mulle-sde match list --type-matches source

# List files with detailed information
mulle-sde match list -l
```

## Command Analysis

### Purpose and Architecture
The `mulle-sde match` command serves as a thin wrapper around the `mulle-match` tool, providing access to mulle-sde's sophisticated file pattern matching system. This system uses patternfiles (similar to .gitignore files) to categorize and filter project files based on their types, purposes, and locations.

**Key Components:**
- **Patternfiles**: Configuration files that define file matching rules
- **Types**: Categories like "source", "header", "resource", "cmakefile"
- **Categories**: More specific classifications like "public-headers", "private-headers"
- **Match vs Ignore**: Separate rule sets for what to include vs exclude

### File Pattern System
Patternfiles are stored in `.mulle/share/match/` and consist of:
- `match.d/` - Files defining what to match
- `ignore.d/` - Files defining what to ignore

## All Available Options

### Basic Options (via mulle-match)
- `list`: List files matching patternfiles
- `filename`: Find which patternfile matches a filename
- `patternfile`: Manage patternfiles
- `init`: Setup initial patternfiles
- `clean`: Remove cached patternfiles

### Patternfile Management Commands
All patternfile operations are accessible through `mulle-sde patternfile`:
- `add`: Add new patternfile
- `cat`: Show patternfile contents
- `copy`: Copy patternfile
- `edit`: Edit patternfile
- `ignore`: Create ignore rule
- `match`: Create match rule
- `list`: List patternfiles
- `remove`: Remove patternfile
- `rename`: Rename patternfile
- `status`: Check patternfile status

## Hidden Options and Advanced Features

### Environment Variables
- `MULLE_MATCH`: Override match tool (default: mulle-match)
- `MULLE_MATCH_FLAGS`: Additional flags for mulle-match
- `MULLE_TECHNICAL_FLAGS`: Technical debugging flags

### Advanced Patternfile Usage
- `--qualifier`: Filter by patternfile qualifiers
- `--type-matches`: Filter by file type
- `--category-matches`: Filter by category
- `--format`: Custom output formatting

### Cross-Platform Pattern Matching
Patternfiles support platform-specific rules through:
- Environment-based filtering
- Platform-specific patternfile directories
- Conditional pattern matching based on build configuration

## Integration with Other Commands

### Relationship to `mulle-sde list`
The `list` command uses patternfiles internally to categorize and display project files. It relies on the same patternfile system as `match`.

### Relationship to `mulle-sde craft`
During the craft process, patternfiles are used to:
- Identify source files for compilation
- Determine header file locations
- Find CMake configuration files
- Exclude generated/temporary files

### Relationship to `mulle-sde add`
When adding new files, patternfiles determine:
- Which file types are considered valid
- Where files should be placed based on their type
- How files are categorized in the build system

### Relationship to `mulle-sde reflect`
Reflection uses patternfiles to:
- Generate appropriate CMakeLists.txt entries
- Update build system configurations
- Identify file dependencies

## Practical Examples

### Basic File Discovery

```bash
# List all source files in the project
mulle-sde match list --type-matches source

# List all header files
mulle-sde match list --type-matches header

# List files with their matching patternfiles
mulle-sde match list -f "%f: %m\n"

# List files in long format showing type and category
mulle-sde match list -l
```

### Patternfile Management

```bash
# List all patternfiles
mulle-sde patternfile list

# View contents of a specific patternfile
mulle-sde patternfile cat 85-header--public-headers

# Add a new patternfile for test files
mulle-sde patternfile add test-files "test/**/*.c"

# Create ignore rule for temporary files
mulle-sde patternfile ignore "*.tmp"

# Create specific match rule
mulle-sde patternfile match "src/main.c"
```

### Advanced Filtering

```bash
# List only C source files in src directory
MULLE_MATCH_FILENAMES="*.c" MULLE_MATCH_PATH="src" mulle-sde match list

# Exclude build directories
MULLE_MATCH_IGNORE_PATH="build:tmp" mulle-sde match list

# Find which patternfile matches a specific file
mulle-sde match filename src/myfile.m

# Test pattern matching with verbose output
mulle-sde match list -v --type-matches source
```

### Cross-Platform Usage

```bash
# Use platform-specific patternfiles
MULLE_UNAME=linux mulle-sde match list

# Generate platform-specific file lists
MULLE_UNAME=darwin mulle-sde match list --type-matches source > darwin-sources.txt
MULLE_UNAME=linux mulle-sde match list --type-matches source > linux-sources.txt

# Compare platform differences
diff <(MULLE_UNAME=darwin mulle-sde match list) \
     <(MULLE_UNAME=linux mulle-sde match list)
```

### Integration with Build Systems

```bash
# Generate CMake include file lists
mulle-sde match list --type-matches header -f "%f\n" > headers.txt

# Create source file manifest for custom build
mulle-sde match list --type-matches source -f "%f\n" > sources.txt

# Find all CMake-related files
mulle-sde match list --type-matches cmakefile

# Check for resource files
mulle-sde match list --type-matches resource
```

## Patternfile Structure and Format

### Naming Conventions
Patternfiles follow a specific naming scheme:
- `NN-category--type` (e.g., `85-header--public-headers`)
- Lower numbers have higher priority
- `--` separates category from type
- Files are processed in numerical order

### Pattern Syntax
- **Wildcards**: `*` matches any characters, `**` matches directories recursively
- **Negation**: `!pattern` excludes files that would otherwise match
- **Comments**: Lines starting with `#` are ignored
- **Empty lines**: Ignored for readability

### Example Patternfile
```
# Public headers
*.h
include/**/*.h
!*_private.h

# Exclude generated files
!generated/*.h
```

## Troubleshooting

### Common Issues

**Files not appearing in matches:**
- Check if patternfiles exist in `.mulle/share/match/match.d/`
- Verify `MULLE_MATCH_PATH` includes your directories
- Ensure files aren't excluded by ignore rules

**Patternfiles not found:**
- Initialize patternfiles: `mulle-sde patternfile init`
- Check if `.mulle/share/match/` directory exists
- Verify mulle-match is in PATH

**Incorrect file categorization:**
- Check patternfile priority (lower numbers = higher priority)
- Verify patternfile syntax
- Use `mulle-sde match filename` to debug specific files

### Debugging Commands

```bash
# Check patternfile configuration
mulle-sde patternfile status

# Verbose output for debugging
MULLE_TECHNICAL_FLAGS="--verbose" mulle-sde match list

# Test specific patternfile
mulle-sde patternfile cat 95-source--sources

# Check environment variables
env | grep MULLE_MATCH

# List all patternfiles with contents
mulle-sde patternfile list -c
```

### Environment Debugging

```bash
# Check current match configuration
echo "Match tool: ${MULLE_MATCH:-mulle-match}"
echo "Match path: ${MULLE_MATCH_PATH:-default}"
echo "Match ignore: ${MULLE_MATCH_IGNORE_PATH:-default}"
echo "Match filenames: ${MULLE_MATCH_FILENAMES:-default}"

# Test with custom configuration
MULLE_MATCH_PATH="src:test:include" \
MULLE_MATCH_IGNORE_PATH="build:tmp" \
mulle-sde match list -l
```

## Advanced Integration Examples

### CI/CD Pipeline Integration

```bash
# Generate source file list for CI
mulle-sde match list --type-matches source -f "%f\n" > ci-sources.txt

# Verify all required files exist
if ! mulle-sde match filename src/main.c; then
    echo "Missing main.c file"
    exit 1
fi

# Check for test files
if mulle-sde match list --type-matches source | grep -q "test/"; then
    echo "Test files found"
fi
```

### Custom Build System Integration

```bash
# Generate build file lists
SOURCES=$(mulle-sde match list --type-matches source -f "%f\n")
HEADERS=$(mulle-sde match list --type-matches header -f "%f\n")
RESOURCES=$(mulle-sde match list --type-matches resource -f "%f\n")

# Create Makefile variables
echo "SOURCES = $SOURCES" > filelist.mk
echo "HEADERS = $HEADERS" >> filelist.mk
echo "RESOURCES = $RESOURCES" >> filelist.mk
```

### IDE Integration

```bash
# Generate project file lists
mulle-sde match list --type-matches source -f "%f\n" > .vscode/sources.txt
mulle-sde match list --type-matches header -f "%f\n" > .vscode/headers.txt

# Create include path list
mulle-sde match list --type-matches header | sed 's|/[^/]*$||' | sort -u > .vscode/include-paths.txt
```

### Cross-Compilation Setup

```bash
# Platform-specific file selection
if [ "$PLATFORM" = "ios" ]; then
    MULLE_MATCH_FILENAMES="*.m:*.mm" mulle-sde match list > ios-sources.txt
else
    MULLE_MATCH_FILENAMES="*.c:*.cpp" mulle-sde match list > generic-sources.txt
fi
```

## Performance Considerations

### Optimizing File Discovery
- Use specific `MULLE_MATCH_PATH` to limit search scope
- Set appropriate `MULLE_MATCH_IGNORE_PATH` to exclude large directories
- Use specific file patterns in `MULLE_MATCH_FILENAMES`

### Cache Management
- Patternfiles are cached by mulle-match
- Use `mulle-sde match clean` to clear cache when needed
- Cache invalidation happens automatically when patternfiles change