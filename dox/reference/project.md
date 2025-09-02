# mulle-sde project - Complete Reference

## Quick Start
The `mulle-sde project` command provides project management functionality including renaming, removal, and inspection of project-level variables. It's essential for managing the identity and configuration of your C/C++ projects.

## All Available Options

### Basic Options (in usage)
- **rename**: Change the project name with comprehensive search/replace
- **remove**: Completely remove a project (dangerous - requires `-f`)
- **variables**: Display all project-related environment variables
- **list**: List project files (aliased to `mulle-sde list --no-files`)

### Advanced Options (hidden)

#### Project Rename Options
```bash
--no-filenames            # Don't rename files containing old project name
--no-contents             # Don't search/replace in file contents  
--save-environment        # Save new name to environment (default)
--no-save-environment     # Don't save to environment variables
--filenames               # Force filename renaming (overrides --no-filenames)
--contents                # Force content replacement (overrides --no-contents)
--tests                   # Also rename test projects (default)
--no-tests                # Skip test project renaming
--project-name <name>     # Override current project name for rename
```

#### Project Remove Options
```bash
-f                        # Force removal (required for safety)
```

### Environment Control

#### Core Project Variables
```bash
# Identity variables (automatically generated)
PROJECT_NAME                    # The canonical project name
PROJECT_IDENTIFIER              # Safe identifier (alphanumeric/underscore)
PROJECT_UPCASE_IDENTIFIER       # UPPERCASE version
PROJECT_DOWNCASE_IDENTIFIER     # lowercase version
PROJECT_PREFIXLESS_NAME         # Name without prefix (e.g., "mylib" from "mulle-mylib")
PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER  # Lowercase prefixless version

# Language configuration
PROJECT_LANGUAGE                # Primary language (c, objc, cpp, etc.)
PROJECT_DIALECT                 # Dialect extension (often same as language)
PROJECT_EXTENSIONS              # File extensions for this language
PROJECT_UPCASE_LANGUAGE         # Uppercase language name
PROJECT_DOWNCASE_LANGUAGE       # Lowercase language name
PROJECT_UPCASE_DIALECT          # Uppercase dialect
PROJECT_DOWNCASE_DIALECT        # Lowercase dialect

# Test project variables
TEST_PROJECT_NAME               # Name for test project
TEST_PROJECT_IDENTIFIER         # Test project identifier
TEST_PROJECT_UPCASE_IDENTIFIER  # Uppercase test identifier
TEST_PROJECT_DOWNCASE_IDENTIFIER # Lowercase test identifier
TEST_PROJECT_PREFIXLESS_NAME    # Test prefixless name
TEST_PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER # Test prefixless lowercase
```

#### Template Variables (One-shot usage)
```bash
# File-specific variables for templating
ONESHOT_FILENAME                # Current file being processed
ONESHOT_BASENAME                # Filename without path
ONESHOT_FILENAME_NO_EXT         # Filename without extension
ONESHOT_NAME                    # Extensionless basename
ONESHOT_IDENTIFIER              # Safe identifier version
ONESHOT_UPCASE_IDENTIFIER       # Uppercase identifier
ONESHOT_DOWNCASE_IDENTIFIER     # Lowercase identifier
ONESHOT_UPCASE_C_IDENTIFIER     # C-style uppercase identifier
ONESHOT_DOWNCASE_C_IDENTIFIER   # C-style lowercase identifier
ONESHOT_PREFIXLESS_NAME         # Name without prefix
ONESHOT_PREFIXLESS_DOWNCASE_IDENTIFIER # Prefixless lowercase
ONESHOT_CLASS                   # Class name for templates
ONESHOT_CATEGORY                # Category for templates
```

#### Environment Configuration
```bash
# Template file locations
MULLE_SDE_FILE_HEADER           # Custom header template path
MULLE_SDE_FILE_FOOTER           # Custom footer template path
MULLE_SDE_ETC_DIR               # Project-local etc directory
MULLE_SDE_SHARE_DIR             # Shared directory for templates

# Search path for templates (fallback order)
# 1. Project-local: ${MULLE_SDE_ETC_DIR}/{name}.{extension}
# 2. Shared: ${MULLE_SDE_SHARE_DIR}/{name}.{extension}
# 3. User-global: ~/.config/mulle/etc/sde/{name}.{extension} (Linux)
# 4. User-global: ~/.mulle/etc/sde/{name}.{extension} (macOS/others)
```

## Hidden Behaviors Explained

### Project Rename Algorithm

#### Comprehensive Search/Replace Strategy
When renaming a project, the system performs:
1. **Environment variable updates**: Changes PROJECT_NAME and derivatives
2. **Filename renaming**: Recursively renames files matching old patterns
3. **Content replacement**: Updates identifiers in source files
4. **Directory renaming**: Renames directories containing old names
5. **Test project handling**: Optionally renames associated test projects

#### Pattern Matching Rules
```bash
# Exact matches replaced:
- ${OLD_PROJECT_NAME} -> ${PROJECT_NAME}
- ${OLD_PROJECT_IDENTIFIER} -> ${PROJECT_IDENTIFIER}
- ${OLD_PROJECT_DOWNCASE_IDENTIFIER} -> ${PROJECT_DOWNCASE_IDENTIFIER}
- ${OLD_PROJECT_UPCASE_IDENTIFIER} -> ${PROJECT_UPCASE_IDENTIFIER}

# Directory traversal includes:
- Current directory and subdirectories
- .idea directories (CLion/IntelliJ)
- MULLE_MATCH_PATH directories
- Test project directories (when --tests is used)
```

#### Safety Mechanisms
- **Backup recommendation**: Always work on a copy of your project
- **Validation**: Checks for valid identifier characters
- **Force flag required**: For removal operations
- **No-op detection**: Fails if new name equals old name

### Template Resolution Order

#### Header/Footer Discovery
```bash
# Extension-specific templates:
1. etc/header.${extension}
2. etc/header.default
3. share/header.${extension}
4. share/header.default
5. ~/.config/mulle/etc/sde/header.${extension} (Linux)
6. ~/.config/mulle/etc/sde/header.default (Linux)
7. ~/.mulle/etc/sde/header.${extension} (macOS)
8. ~/.mulle/etc/sde/header.default (macOS)
```

#### Project Name Validation
```bash
# Valid characters: A-Z, a-z, 0-9, underscore, hyphen, dot
# Invalid patterns:
- Spaces in project name
- Starting with number or special character
- Containing invalid characters like /, \, $, etc.
```

### Cross-Platform Considerations

#### Directory Structure Differences
```bash
# Linux systems:
~/.config/mulle/etc/sde/

# macOS/BSD systems:
~/.mulle/etc/sde/

# Windows (via WSL/Cygwin):
# Uses Linux-style paths
```

#### Environment Variable Scope
- **Project scope**: Variables stored in project environment
- **User scope**: Global templates and settings
- **System scope**: OS-specific defaults

## Practical Examples

### Common Hidden Usage Patterns

#### Safe Project Renaming
```bash
# Dry run - check what would change
mulle-sde project rename --no-save-environment --no-contents --no-filenames newname

# Rename with full replacement
mulle-sde project rename MyNewProject

# Rename preserving file contents (useful for large projects)
mulle-sde project rename --no-contents NewProjectName

# Rename test projects only
mulle-sde project rename --no-tests MyLibrary
```

#### Project Inspection
```bash
# View all project variables
mulle-sde project variables

# Use in scripts
source <(mulle-sde project variables)
echo "Project: $PROJECT_NAME"
echo "Language: $PROJECT_LANGUAGE"

# Check specific variable
mulle-sde project variables | grep PROJECT_IDENTIFIER
```

#### Template Customization
```bash
# Create custom header for C files
mkdir -p .mulle/etc/sde
cat > .mulle/etc/sde/header.c << 'EOF'
/*
 * ${PROJECT_NAME} - ${ONESHOT_FILENAME}
 * 
 * Copyright (c) $(date +%Y) ${USER}
 */
EOF

# Create custom footer
cat > .mulle/etc/sde/footer.c << 'EOF'
/* ${PROJECT_NAME} footer */
EOF
```

#### Environment Variable Overrides
```bash
# Override language detection
export PROJECT_LANGUAGE=c++
mulle-sde reflect

# Force specific dialect
export PROJECT_DIALECT=objc
export PROJECT_EXTENSIONS=m,mm
mulle-sde reflect

# Custom project prefix handling
export PROJECT_PREFIXLESS_NAME=core
```

#### Subproject Integration
```bash
# Rename affects subprojects when --tests is used
mulle-sde project rename --tests NewProjectName

# Skip subproject renaming
mulle-sde project rename --no-tests NewProjectName
```

### Environment Variable Overrides

#### Development Scenarios
```bash
# Multi-config setup
export PROJECT_NAME=MyLib-dev
export PROJECT_LANGUAGE=c
export PROJECT_DIALECT=c
mulle-sde project variables

# Cross-compilation setup
export PROJECT_NAME=MyLib-arm64
export PROJECT_DIALECT=c
mulle-sde reflect

# Test project configuration
export TEST_PROJECT_NAME=MyLib-tests
export TEST_PROJECT_LANGUAGE=c++
```

#### CI/CD Integration
```bash
# Pipeline configuration
export PROJECT_NAME=${CI_PROJECT_NAME}
export PROJECT_LANGUAGE=${TARGET_LANGUAGE:-c}
mulle-sde project variables > project.env
echo "Building ${PROJECT_NAME} (${PROJECT_LANGUAGE})"
```

## Troubleshooting

### When to Use Hidden Options

#### Performance Issues
```bash
# Large project rename - skip content scanning
mulle-sde project rename --no-contents NewName

# Skip filename renaming for external dependencies
mulle-sde project rename --no-filenames NewName
```

#### Integration Problems
```bash
# Preserve existing environment
mulle-sde project rename --no-save-environment TempName

# Handle directory conflicts
mulle-sde project rename --no-filenames --no-contents NewName
```

#### Template Issues
```bash
# Debug template resolution
export MULLE_FLAG_LOG_SETTINGS=YES
mulle-sde project variables

# Force template refresh
rm -rf .mulle/share/sde/templates
mulle-sde reflect
```

### Common Edge Cases

#### Invalid Project Names
```bash
# These will fail:
mulle-sde project rename "My Project"      # Contains space
mulle-sde project rename "123project"      # Starts with number
mulle-sde project rename "project@home"    # Invalid character

# Use valid names:
mulle-sde project rename MyProject
mulle-sde project rename my_project
mulle-sde project rename project-123
```

#### Test Project Conflicts
```bash
# When test project has different name
mulle-sde project rename --no-tests CoreLib
# Then manually rename test project:
cd tests && mulle-sde project rename CoreLib-tests
```

#### Cross-Platform Path Issues
```bash
# Windows path separators
# Use forward slashes or escape backslashes
mulle-sde project rename MyProject
# Avoid: mulle-sde project rename My\Project
```

### Recovery Strategies

#### Failed Rename Recovery
```bash
# Check what changed
git status                    # If using git
find . -name "*OldName*"      # Find renamed files
grep -r "OldName" .           # Find content references

# Manual recovery steps
1. Revert environment: mulle-sde project rename OriginalName
2. Restore from backup if available
3. Use --no-contents/--no-filenames flags for safer retry
```

#### Project Removal Safety
```bash
# Always use -f flag explicitly
mulle-sde project remove -f

# Better: move to backup location
mv . /tmp/myproject-backup
# Then create new project
mulle-sde init -d . -m foundation/objc-developer
```

### Integration with Development Tools

#### IDE Integration
```bash
# CLion/IntelliJ IDEA support
# Renames .idea directory contents automatically
mulle-sde project rename NewProjectName

# VS Code integration
# Updates .vscode/settings.json if present
```

#### Build System Integration
```bash
# CMake integration
# Updates CMakeLists.txt variables automatically
mulle-sde project rename MyLib
# CMake variables updated: PROJECT_NAME, CMAKE_PROJECT_NAME

# Makefile integration
# Updates Makefile variables
# PROJECT_NAME, PROJECT_IDENTIFIER updated in build files
```

#### Git Integration
```bash
# Best practices for renaming
1. Commit current state
2. Create branch for rename
3. Perform rename
4. Review changes
5. Commit with descriptive message

# Example workflow
git checkout -b rename-to-newlib
mulle-sde project rename NewLib
git add .
git commit -m "Rename project to NewLib"
```
