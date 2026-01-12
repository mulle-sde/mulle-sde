# mulle-sde ignore - Complete Reference

## Quick Start
The `ignore` command manages file exclusion patterns for the mulle-sde build system. When you mark files or directories as ignored, they are excluded from file discovery operations used by `craft`, `reflect`, `list`, and other commands. This is essential for excluding build artifacts, temporary files, and content you don't want processed during development.

```bash
# Ignore build output directory
mulle-sde ignore build/

# Ignore temporary files by extension
mulle-sde ignore "*.tmp"

# View current ignore patterns
mulle-sde ignore --cat

# Find where user ignore patterns are stored
mulle-sde ignore --list
```

## Command Purpose and Architecture

### What It Actually Does
The `ignore` command is a thin wrapper around `mulle-match patternfile ignore`. It:

1. **Appends patterns** to the user ignore patternfile `00-user--none`
2. **Uses priority 00** to ensure user patterns override system defaults
3. **Stores patterns** in `.mulle/share/match/ignore.d/`
4. **Integrates with mulle-match** for file discovery filtering

Unlike `.gitignore` (which affects version control), mulle-sde ignore patterns affect:
- **File discovery** during `mulle-sde list` operations
- **Build system generation** during `mulle-sde reflect`
- **Source file collection** during `mulle-sde craft`
- **Dependency scanning** during operations that walk the file tree

### The Patternfile System
Ignore patterns are stored in **patternfiles** - text files similar to `.gitignore`:

```
# Directory structure
.mulle/share/match/
├── ignore.d/          # Patterns for files to ignore
│   ├── 00-user--none  # User patterns (highest priority)
│   ├── 20-source--none # System defaults
│   └── 30-subproject--none # Auto-managed subproject ignores
└── match.d/           # Patterns for files to match
    ├── 10-header--public
    └── 95-source--sources
```

**Priority ordering**: Lower numbers = higher priority. `00-user--none` overrides all other ignore patterns.

## All Available Options

### Command Syntax
```bash
mulle-sde ignore [options] <pattern>
```

### Options

#### `<pattern>` (required when adding)
File or directory pattern to ignore. Supports shell glob patterns and gitignore-style syntax.

**Pattern types:**
- **Literal paths**: `build/`, `src/debug.c`
- **Wildcards**: `*.o`, `*.tmp`, `test_*`
- **Recursive globs**: `**/build/`, `**/*.bak`
- **Character classes**: `[Bb]uild/`, `*.[ch]`

**Important**: Always use forward slashes `/` for paths, even on Windows.

#### `--list` or `-l`
Display the filesystem path to the user ignore patternfile.

```bash
mulle-sde ignore --list
# Output: .mulle/share/match/ignore.d/00-user--none
```

**Use case**: Find where patterns are stored to manually edit or version control.

#### `--cat` or `--print`
Show the contents of the user ignore patternfile.

```bash
mulle-sde ignore --cat
# Output:
# build/
# *.tmp
# .DS_Store
```

**Use case**: Review current ignore patterns without knowing file location.

#### `--help` or `-h`
Display usage information and exit.

## Hidden Behaviors Explained

### 1. Pattern Appending (Not Replacement)
Each call to `ignore` **appends** a new line to the patternfile - it never removes existing patterns.

```bash
mulle-sde ignore "*.tmp"
mulle-sde ignore "*.bak"
# Result: Both patterns are now in the file
```

**Implication**: To remove patterns, you must manually edit the patternfile:
```bash
# Get patternfile location
filepath=$(mulle-sde ignore --list)
# Edit with your preferred editor
${EDITOR} "${filepath}"
```

### 2. Priority 00 Always Used
User patterns are **always** stored with priority `00`, making them highest priority. You cannot override this.

**Why this matters**: User ignore patterns override all system-level ignores, including those from extensions. If you accidentally ignore a critical pattern, it will take precedence over everything.

### 3. Patternfile Creation
If the `00-user--none` patternfile doesn't exist, it's created automatically on first use.

```bash
# First ignore command creates the file
mulle-sde ignore "build/"
# Creates: .mulle/share/match/ignore.d/00-user--none
```

### 4. Category Is Always "none"
The patternfile naming convention is `NN-category--type`. For user ignores:
- Priority: `00`
- Category: `user`
- Type: `none`

This hardcoded choice means user ignores apply globally without type-specific filtering.

### 5. Integration with mulle-match
Behind the scenes, `mulle-sde ignore` calls:
```bash
mulle-match patternfile ignore <pattern>
```

This means:
- Environment variables like `MULLE_TECHNICAL_FLAGS` and `MULLE_MATCH_FLAGS` affect behavior
- You can use `mulle-match` directly for advanced operations
- Patternfile changes affect all mulle-sde commands immediately

### 6. Automatic Subproject Ignore Management
When you work with subprojects, mulle-sde **automatically manages** a separate patternfile:

**File**: `30-subproject--none` (priority 30)  
**Contents**: Auto-generated list of subproject directories

```bash
mulle-sde subproject init -d src/mylib library
# Automatically adds to 30-subproject--none:
# src/mylib/
```

**Warning**: The subproject command **clobbers** this file completely on each update. Never manually edit `30-subproject--none`.

### 7. Environment Variable Integration
While `ignore` doesn't have its own environment variables, it inherits from mulle-match:

- `MULLE_MATCH`: Override the match tool (`mulle-match`)
- `MULLE_TECHNICAL_FLAGS`: Pass debugging flags (`--verbose`, `--debug`)
- `MULLE_MATCH_FLAGS`: Additional flags to mulle-match
- `MULLE_USER_PWD`: Used for relative path calculations

## Practical Examples

### Basic Usage Patterns

```bash
# Ignore build output directories
mulle-sde ignore build/
mulle-sde ignore .build/
mulle-sde ignore cmake-build-debug/

# Ignore temporary and backup files
mulle-sde ignore "*.tmp"
mulle-sde ignore "*.bak"
mulle-sde ignore "*~"
mulle-sde ignore "*.swp"
mulle-sde ignore "*.swo"

# Ignore OS-specific files
mulle-sde ignore ".DS_Store"      # macOS
mulle-sde ignore "Thumbs.db"      # Windows
mulle-sde ignore "desktop.ini"    # Windows

# Ignore IDE configuration
mulle-sde ignore ".vscode/"
mulle-sde ignore ".idea/"
mulle-sde ignore "*.sublime-project"
mulle-sde ignore "*.sublime-workspace"
```

### Platform-Specific Ignores

```bash
# Ignore Windows build artifacts
mulle-sde ignore "*.exe"
mulle-sde ignore "*.dll"
mulle-sde ignore "*.lib"
mulle-sde ignore "*.obj"

# Ignore Unix/Linux artifacts
mulle-sde ignore "*.so"
mulle-sde ignore "*.a"
mulle-sde ignore "*.o"
mulle-sde ignore "*.dylib"

# Ignore platform-specific build directories
mulle-sde ignore "build-linux/"
mulle-sde ignore "build-darwin/"
mulle-sde ignore "build-windows/"
```

### Development Workflow Integration

```bash
# Ignore test output
mulle-sde ignore "test/output/"
mulle-sde ignore "test/results/"
mulle-sde ignore "*.test.log"

# Ignore generated documentation
mulle-sde ignore "docs/html/"
mulle-sde ignore "docs/latex/"
mulle-sde ignore "doxygen/output/"

# Ignore package manager artifacts
mulle-sde ignore "node_modules/"
mulle-sde ignore "__pycache__/"
mulle-sde ignore "vendor/bundle/"

# Ignore debug/profiling output
mulle-sde ignore "*.dSYM/"
mulle-sde ignore "*.pdb"
mulle-sde ignore "callgrind.out.*"
mulle-sde ignore "gmon.out"
```

### Viewing and Managing Patterns

```bash
# View current ignore patterns
mulle-sde ignore --cat

# Find where patterns are stored
mulle-sde ignore --list

# View patterns with line numbers (for editing)
cat -n "$(mulle-sde ignore --list)"

# Manually edit ignore patterns
${EDITOR:-vi} "$(mulle-sde ignore --list)"

# Compare user vs system ignores
mulle-match patternfile -i cat        # All ignore patterns
mulle-sde ignore --cat                # Just user patterns
```

### Advanced Pattern Techniques

```bash
# Ignore specific subdirectories in multiple locations
mulle-sde ignore "**/build/"
mulle-sde ignore "**/tmp/"

# Ignore files with multiple extensions
mulle-sde ignore "*.{tmp,bak,old}"

# Ignore numbered build directories
mulle-sde ignore "build-[0-9]*/"

# Case-insensitive ignore (use character classes)
mulle-sde ignore "[Bb]uild/"
mulle-sde ignore "[Tt]emp/"

# Ignore everything in a directory except specific files
# (Requires manual patternfile editing for negation patterns)
filepath=$(mulle-sde ignore --list)
cat >> "${filepath}" << 'EOF'
logs/*
!logs/important.log
EOF
```

## Environment Variables

### Direct Environment Variables
None. The `ignore` command doesn't define its own environment variables.

### Inherited from mulle-match

#### `MULLE_MATCH`
**Default**: `mulle-match`  
**Purpose**: Override the match tool executable  
**Example**:
```bash
export MULLE_MATCH=/usr/local/bin/mulle-match-dev
mulle-sde ignore "test/"
```

#### `MULLE_TECHNICAL_FLAGS`
**Default**: (empty)  
**Purpose**: Pass debugging/technical flags to underlying tools  
**Example**:
```bash
export MULLE_TECHNICAL_FLAGS="--verbose --debug"
mulle-sde ignore "build/"  # See detailed execution
```

#### `MULLE_MATCH_FLAGS`
**Default**: (empty)  
**Purpose**: Additional flags passed to mulle-match  
**Example**:
```bash
export MULLE_MATCH_FLAGS="--force"
mulle-sde ignore "critical/"
```

### Environment Variables Affecting Behavior

#### `MULLE_USER_PWD`
**Purpose**: Base directory for relative path calculations  
**Set by**: mulle-sde environment  
**Effect**: When `--list` shows paths, they're relative to this directory

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Pattern not working - files still appear in list"

**Diagnosis**:
```bash
# Check if pattern exists
mulle-sde ignore --cat | grep "your-pattern"

# Test file matching
mulle-sde match filename path/to/file
# Should show: (ignored)

# Verify environment
mulle-match list | grep "problem-file"
```

**Causes**:
1. **Match patterns override ignore**: Files explicitly matched by `match.d/` patterns may still appear
2. **Pattern syntax error**: Glob patterns not escaped properly
3. **Path separator issues**: Used backslashes instead of forward slashes
4. **Cached results**: mulle-match cache not invalidated

**Solutions**:
```bash
# Clear mulle-match cache
mulle-match clean

# Test pattern syntax
mulle-match patternfile -i cat | grep "your-pattern"

# Check match priority
mulle-match patternfile list
mulle-match patternfile -i list

# Debug with verbose output
MULLE_TECHNICAL_FLAGS="--verbose" mulle-sde list --files
```

#### Issue: "Ignore patternfile doesn't exist after using --list"

**Diagnosis**:
```bash
mulle-sde ignore --list
# Output: (nothing)
```

**Cause**: No patterns have been added yet, so the patternfile hasn't been created.

**Solution**:
```bash
# Add your first pattern to create the file
mulle-sde ignore "build/"
mulle-sde ignore --list  # Now shows the path
```

#### Issue: "Subproject patterns keep getting overwritten"

**Diagnosis**:
```bash
mulle-sde ignore --cat
# Shows subproject patterns you manually added
mulle-sde subproject list
# Subproject patterns disappear or change
```

**Cause**: Subproject management **clobbers** the `30-subproject--none` file.

**Solution**:
```bash
# Don't put subproject patterns in 30-subproject--none
# Put them in user patterns instead:
mulle-sde ignore "my-subproject/unwanted/"

# Or use a custom patternfile:
mulle-match patternfile add -i -p 10 custom-ignore "pattern"
```

#### Issue: "Pattern contains spaces - not working"

**Diagnosis**:
```bash
mulle-sde ignore my file.txt  # Wrong!
```

**Cause**: Shell word splitting breaks the pattern.

**Solution**:
```bash
# Quote patterns with spaces
mulle-sde ignore "my file.txt"

# Or escape spaces
mulle-sde ignore my\ file.txt
```

#### Issue: "Patterns work in one project but not another"

**Diagnosis**:
```bash
# Check patternfile existence in both projects
ls -la .mulle/share/match/ignore.d/
```

**Cause**: Patternfiles are per-project, not global.

**Solution**:
```bash
# Copy patterns between projects
project1_patterns=$(cd project1 && mulle-sde ignore --cat)
cd project2
echo "${project1_patterns}" | while read pattern; do
    [ -n "${pattern}" ] && mulle-sde ignore "${pattern}"
done

# Or copy the file directly
cp project1/.mulle/share/match/ignore.d/00-user--none \
   project2/.mulle/share/match/ignore.d/00-user--none
```

### Debugging Commands

```bash
# Show all ignore patternfiles with priority
mulle-match patternfile -i list

# Show contents of all ignore patternfiles
mulle-match patternfile -i cat

# Test if a specific file is ignored
mulle-match filename -i path/to/test.c

# Show verbose matching process
MULLE_TECHNICAL_FLAGS="--verbose" mulle-match list

# Check patternfile status
mulle-match patternfile -i status

# List files being found (shows what's NOT ignored)
mulle-match list

# Check environment configuration
env | grep MULLE_MATCH
```

### Performance Issues

#### Symptom: "File operations are slow"

**Causes**:
1. Too many ignore patterns (hundreds)
2. Complex glob patterns with `**`
3. Inefficient ignore patterns

**Solutions**:
```bash
# Prefer directory ignores over file globs
# Bad: mulle-sde ignore "build/**/*"
# Good: mulle-sde ignore "build/"

# Use environment variables for broad exclusions
mulle-sde env set MULLE_MATCH_IGNORE_PATH "build:tmp:old:.git"

# Clear cache if patterns changed frequently
mulle-match clean
```

## Integration with Other Commands

### With `mulle-sde list`
The `list` command uses ignore patterns to filter displayed files:

```bash
# Files matching ignore patterns won't appear
mulle-sde ignore "test/"
mulle-sde list --files  # No test/ files shown
```

### With `mulle-sde reflect`
Reflection uses ignore patterns to determine which files to include in build system generation:

```bash
# Ignore example code before reflection
mulle-sde ignore "examples/"
mulle-sde reflect  # examples/ not added to CMakeLists.txt
```

### With `mulle-sde craft`
Build operations skip ignored files during source collection:

```bash
# Ignore experimental code
mulle-sde ignore "src/experimental/"
mulle-sde craft  # experimental/ not compiled
```

### With `mulle-sde subproject`
Subproject operations automatically manage ignore patterns:

```bash
# Adding subproject automatically ignores its directory
mulle-sde subproject init -d libs/mylib library
# Automatically creates ignore pattern: libs/mylib/

# Verify it was ignored
mulle-sde ignore --cat  # Won't show it (wrong file)
mulle-match patternfile -i cat | grep "30-subproject"  # Shows it
```

### With `mulle-sde match`
The match command respects ignore patterns during file discovery:

```bash
mulle-sde ignore "*.bak"
mulle-sde match list  # No .bak files shown
```

### With patternfile commands
Direct patternfile manipulation provides more control:

```bash
# View all patternfiles including ignores
mulle-sde patternfile list

# Edit ignore patternfile directly  
mulle-sde patternfile edit -i -p 00 user

# Add ignore with specific template
mulle-sde patternfile ignore -t custom-template "pattern"
```

## Advanced Topics

### Pattern Syntax Reference

The ignore command uses mulle-match patternfile syntax, which is similar to `.gitignore`:

| Pattern | Matches | Example |
|---------|---------|---------|
| `literal` | Exact filename/directory | `build/` |
| `*.ext` | Extension match | `*.tmp` |
| `**/path` | Any depth | `**/build/` |
| `path/**` | All contents | `logs/**` |
| `?` | Single character | `test?.c` |
| `[abc]` | Character class | `[Bb]uild/` |
| `[a-z]` | Character range | `file[0-9].txt` |
| `!pattern` | Negation (manual edit) | `!important.log` |

**Note**: Negation patterns (`!pattern`) require manual patternfile editing - they cannot be added via `mulle-sde ignore`.

### Priority System Deep Dive

Patternfiles use a two-digit priority prefix:

| Priority | Purpose | Example | Mutability |
|----------|---------|---------|------------|
| 00-09 | User overrides | `00-user--none` | User-managed |
| 10-19 | High priority | `10-custom--none` | Manual |
| 20-29 | System defaults | `20-source--none` | Extension-provided |
| 30-39 | Auto-generated | `30-subproject--none` | Auto-managed |
| 40-89 | Extensions | `50-cmake--none` | Extension-provided |
| 90-99 | Fallbacks | `99-default--none` | System-wide |

**Practical implications**:
- User patterns (`00`) always win
- You can create custom priorities 01-09 or 10-19 manually
- Never manually edit priorities 30-39 (auto-managed)

### Creating Custom Ignore Patternfiles

For complex scenarios, create additional patternfiles:

```bash
# Create custom patternfile with priority 10
mulle-match patternfile add -i -p 10 -c custom build-temp "tmp-build/"

# Edit the new patternfile
mulle-match patternfile edit -i -p 10 build-temp

# List to verify
mulle-match patternfile -i list
```

### Sharing Ignore Patterns Across Projects

**Via version control**:
```bash
# Add patternfile to git
git add .mulle/share/match/ignore.d/00-user--none
git commit -m "Add ignore patterns"

# Team members get patterns on clone/pull
```

**Via templates**:
```bash
# Export patterns as template
mulle-match patternfile -i cat > /tmp/ignore-template.txt

# Apply in another project
cd other-project
while read pattern; do
    [ -n "${pattern}" ] && mulle-sde ignore "${pattern}"
done < /tmp/ignore-template.txt
```

**Via environment**:
```bash
# Use shared patternfile directory
export MULLE_MATCH_IGNORE_DIR=/shared/patterns/ignore.d
mulle-sde list  # Uses shared patterns
```

## See Also

- **[mulle-sde match](match.md)** - File pattern matching and discovery
- **[mulle-sde patternfile](patternfile.md)** - Advanced patternfile management
- **[mulle-sde list](list.md)** - List project files (respects ignore patterns)
- **[mulle-sde reflect](reflect.md)** - Build generation (uses ignore patterns)
- **[mulle-sde subproject](subproject.md)** - Subproject management (auto-manages ignores)
- **mulle-match documentation** - Underlying pattern matching tool
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