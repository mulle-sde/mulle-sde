# mulle-sde ignore - Complete Reference

## Quick Start
The `ignore` command manages file exclusion patterns for the mulle-sde build system, preventing specific files and directories from being processed during crafts, reflections, and dependency operations.

## All Available Options

### Basic Options (in usage)
```bash
mulle-sde ignore [options] <pattern>
```

- **--list, -l**: Display the path to the user ignore patternfile
- **--cat, --print**: Show the contents of the user ignore patternfile
- **--help, -h**: Show basic usage information

### Pattern Arguments
- **`<pattern>`**: File or directory pattern to ignore (supports glob patterns)
  - Examples: `src/temp/*`, `*.tmp`, `build/`
  - Supports gitignore-style patterns
  - Directory patterns should end with `/`

### Hidden Options (Advanced)
- **Implicit subproject management**: When using subprojects, mulle-sde automatically manages ignore patterns
  - **When to use**: Automatically triggered when adding/removing subprojects
  - **Side effects**: Creates/updates `30-subproject--none` patternfile
  - **Integration**: Works with `mulle-sde subproject` commands

## Hidden Behaviors Explained

### Patternfile System Integration
The ignore command interfaces with mulle-match's patternfile system to manage exclusions:

1. **User ignore patterns** are stored in patternfiles with priority `00`
2. **Subproject ignore patterns** are stored in patternfiles with priority `30`
3. **Pattern precedence** follows numerical order (lower numbers = higher priority)

### Automatic Subproject Ignore Management
When subprojects are added or removed:
- **Automatic generation**: Creates patterns like `subproject-name/` for each subproject
- **Precedence level**: Uses priority `30` to avoid conflicts with user patterns
- **File location**: Stored in `.mulle/share/sde/patternfile/30-subproject--none`

### Cross-Platform Pattern Support
- **Directory patterns**: Always use forward slashes (`/`) regardless of platform
- **Case sensitivity**: Follows underlying filesystem case sensitivity
- **Glob patterns**: Supports standard shell globbing (`*`, `?`, `[...]`)

## Practical Examples

### Basic Ignore Usage
```bash
# Ignore a specific directory
mulle-sde ignore build/

# Ignore files by extension
mulle-sde ignore "*.o"
mulle-sde ignore "*.tmp"

# Ignore specific files
mulle-sde ignore "src/debug.c"

# Ignore directories recursively
mulle-sde ignore "test-data/"
```

### Viewing Ignore Patterns
```bash
# List the user ignore patternfile location
mulle-sde ignore --list

# Display current ignore patterns
mulle-sde ignore --cat

# Check all patternfiles
mulle-sde patternfile list
```

### Working with Subprojects
```bash
# When adding a subproject, it's automatically ignored
mulle-sde subproject add mylib

# Check the generated ignore patterns
mulle-sde ignore --cat
# Output will include patterns like: mylib/

# Remove subproject (patterns are automatically updated)
mulle-sde subproject remove mylib
```

### Advanced Pattern Examples
```bash
# Ignore multiple extensions
mulle-sde ignore "*.bak"
mulle-sde ignore "*.swp"
mulle-sde ignore "*~"

# Ignore build artifacts by platform
mulle-sde ignore "build-*/"
mulle-sde ignore "*.exe"
mulle-sde ignore "*.dll"

# Ignore IDE files
mulle-sde ignore ".vscode/"
mulle-sde ignore ".idea/"
mulle-sde ignore "*.user"

# Ignore documentation build artifacts
mulle-sde ignore "docs/build/"
mulle-sde ignore "man/*.1"
```

### Integration with Other Commands
```bash
# After adding dependencies, ignore unwanted files
mulle-sde dependency add github:user/project
cd dependency/project
mulle-sde ignore "examples/"
mulle-sde ignore "tests/"

# Ignore files before reflection to prevent build issues
mulle-sde ignore "src/legacy/*"
mulle-sde reflect

# Use ignore to clean up craft results
mulle-sde ignore "build/"
mulle-sde clean
```

## Environment Variables

### MULLE_MATCH_PATH
- **Purpose**: Controls where patternfiles are searched
- **Default**: `.mulle/share/sde/patternfile`
- **Set with**: `export MULLE_MATCH_PATH="/custom/path"`
- **Use case**: Custom project structures or shared ignore patterns

### MULLE_MATCH_FILENAMES
- **Purpose**: Controls which patternfiles are processed
- **Default**: Auto-generated based on available patternfiles
- **Set with**: `mulle-sde env set MULLE_MATCH_FILENAMES="user:subproject:system"`
- **Use case**: Selective patternfile processing for debugging

## Troubleshooting

### When to Use Hidden Options

**Subproject Conflicts**
```bash
# If subproject ignore patterns are interfering
mulle-sde ignore --cat
# Check if 30-subproject--none contains unwanted patterns
# Manually edit if necessary: 
mulle-match patternfile edit -p 30 subproject
```

**Pattern Not Working**
```bash
# Verify pattern syntax
mulle-match patternfile check

# Test pattern matching
mulle-sde list | grep pattern-to-test

# Check pattern precedence
mulle-match patternfile list
```

**Cross-Platform Issues**
```bash
# Ensure consistent path separators
# Use forward slashes even on Windows
mulle-sde ignore "path/to/ignore/"

# Case sensitivity issues on macOS
mulle-sde ignore "[Tt]emp/"
```

### Environment Variable Overrides
```bash
# Debug pattern matching
export MULLE_MATCH_TRACE=YES
mulle-sde list

# Use custom patternfile directory
export MULLE_MATCH_PATH="/tmp/test-patterns"
mulle-sde ignore "test-pattern"

# Reset to defaults
unset MULLE_MATCH_PATH
```

### Common Edge Cases and Solutions

**Large Ignore Lists**
- **Issue**: Performance impact with many patterns
- **Solution**: Group related patterns, use directory-level ignores instead of individual files

**Source Control Integration**
- **Issue**: .gitignore vs mulle-sde ignore conflicts
- **Solution**: Use mulle-sde ignore for build-related files, .gitignore for source control

**Nested Project Structures**
- **Issue**: Subprojects need different ignore patterns
- **Solution**: Use subproject-specific patternfiles or environment overrides

**Pattern Precedence Issues**
- **Issue**: Later patterns override earlier ones unexpectedly
- **Solution**: Use `mulle-match patternfile list` to check order, adjust priority with `-p` flag

## Integration Examples

### CI/CD Pipeline Setup
```bash
# Ignore CI artifacts
mulle-sde ignore ".ci/"
mulle-sde ignore "*.log"

# Ignore platform-specific build outputs
mulle-sde ignore "build-linux/"
mulle-sde ignore "build-windows/"
mulle-sde ignore "build-macos/"
```

### IDE Integration
```bash
# Ignore common IDE files
mulle-sde ignore ".vscode/"
mulle-sde ignore ".idea/"
mulle-sde ignore "*.workspace"
mulle-sde ignore "*.project"
```

### Documentation Projects
```bash
# Ignore documentation build artifacts
mulle-sde ignore "docs/_build/"
mulle-sde ignore "docs/api/"
mulle-sde ignore "*.html"
mulle-sde ignore "*.pdf"
```

## See Also
- [patternfile](patternfile.md) - Advanced patternfile management
- [subproject](subproject.md) - Subproject management with automatic ignore patterns
- [list](list.md) - List project files with pattern matching
- [reflect](reflect.md) - Build system generation affected by ignore patterns