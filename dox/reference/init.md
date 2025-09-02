# mulle-sde init - Complete Reference

## Quick Start
Initialize a new mulle-sde project with automatic setup of build system, dependencies, and development environment.

```bash
# Basic initialization
mulle-sde init                    # Interactive project type selection
mulle-sde init library            # Create library project
mulle-sde init executable         # Create executable project
mulle-sde init -n MyProject -m mulle-c/c-developer executable

# Advanced initialization
mulle-sde init -d ./my-project -m mulle-sde/c-developer executable
mulle-sde init --no-demo --existing  # Skip demo files for existing project
mulle-sde init --github-user myorg -n myproject
```

## All Available Options

### Basic Options (in usage)
- `-h|--help`: Show help
- `-d <dir>`: Directory to populate (working directory)
- `-n|--name|--project-name <name>`: Project name
- `-m|--meta <extension>`: Meta extension (language/build system)
- `-r|--runtime <extension>`: Runtime extension
- `-b|--buildtool <extension>`: Build tool extension
- `-e|--extra <extension>`: Extra extension
- `-o|--oneshot <extension>`: Oneshot extension
- `-s|--style <style>`: Environment style
- `-v|--vendor <vendor>`: Extension vendor (default: mulle-sde)
- `--existing`: Skip demo file installation

### Advanced Options (hidden)

#### Extension Control Options
- `--no-extension`: Disable all extension installation
- `--no-extension/<vendor>/<name>`: Disable specific extension
- `--no-inherit`: Disable extension inheritance
- `--no-inherit/<vendor>/<name>`: Disable inheritance for specific extension
- `--no-init`: Skip extension init scripts
- `--no-init/<vendor>/<name>`: Skip init for specific extension
- `--no-share`: Skip share directory installation
- `--no-share/<vendor>/<name>`: Skip share for specific extension
- `--no-sourcetree`: Skip sourcetree setup
- `--no-sourcetree/<vendor>/<name>`: Skip sourcetree for specific extension

#### Project Control Options
- `--no-project`: Skip project template installation
- `--no-project/<vendor>/<name>`: Skip project for specific extension
- `--no-project-oneshot`: Skip oneshot project installation
- `--no-project-oneshot/<vendor>/<name>`: Skip oneshot project for specific extension
- `--no-demo`: Skip demo file installation
- `--no-demo/<vendor>/<name>`: Skip demo for specific extension
- `--no-clobber`: Skip clobber directory (deprecated)
- `--no-clobber/<vendor>/<name>`: Skip clobber for specific extension
- `--no-delete`: Skip delete directory processing

#### Environment Control Options
- `--no-env`: Skip environment setup
- `--no-env/<vendor>/<name>`: Skip environment for specific extension
- `--no-comment-files`: Don't write template comments into generated files
- `--no-motd`: Skip message-of-the-day installation

#### Extension Management Options
- `--allow-<mark>`: Re-enable disabled mark (opposite of --no-<mark>)
- `--extension-file <file>`: Custom extension file path (default: .mulle/share/sde/extension)
- `--add`: Add extensions to existing project
- `--reinit`: Reinitialize project with new settings
- `--upgrade`: Upgrade existing project to new extension versions
- `--project-file <file>`: Upgrade specific project file only
- `--upgrade-project-file`: Alias for --project-file

#### Directory Structure Options
- `--source-dir <dir>`: Project source directory (default: src)
- `--addiction-dir <dir>`: Addiction directory name
- `--dependency-dir <dir>`: Dependency directory name
- `--kitchen-dir <dir>`: Kitchen directory name
- `--stash-dir <dir>`: Stash directory name

#### Template Control Options
- `--template-header-file <file>`: Custom template header
- `--template-footer-file <file>`: Custom template footer
- `--project-dialect <dialect>`: Project dialect (objc, c, cpp)
- `--project-language <language>`: Project language (c, objc, cpp)
- `--project-extensions <extensions>`: Project extensions
- `--project-type <type>`: Project type (executable, library, none)

#### Oneshot Options
- `--oneshot-name <name>`: Oneshot filename
- `--oneshot-class <class>`: Oneshot class name
- `--oneshot-category <category>`: Oneshot category

#### Development/Debug Options
- `-f`: Force operation (ignore existing files)
- `--if-missing`: Skip if already initialized
- `--no-post-init`: Skip post-init script execution
- `--no-clean`: Skip automatic cleanup
- `--clean`: Force cleanup before initialization
- `--reflect`: Force reflection after initialization
- `--no-reflect`: Skip reflection after initialization
- `--subproject`: Initialize as subproject
- `--github|--github-user <user>`: GitHub username for templates
- `--init-flags <flags>`: Additional init flags
- `-D<key>=<value>`: Define environment variables
- `-c`: Shortcut for meta extension "mulle-c/c-developer"
- `-objc`: Shortcut for meta extension "foundation/objc-developer"

#### Special Environment Options
- `--no-env`: Skip environment initialization
- `--no-blurb`: Skip completion message

### Environment Variables

#### Extension Discovery
- `MULLE_SDE_EXTENSION_PATH`: Overrides search path for extensions
- `MULLE_SDE_EXTENSION_BASE_PATH`: Augments search path for extensions
- `MULLE_SDE_DEFAULT_META_EXTENSION`: Default meta extension

#### Project Configuration
- `PROJECT_NAME`: Project name (auto-detected from directory)
- `PROJECT_TYPE`: Project type (executable, library, none)
- `PROJECT_LANGUAGE`: Programming language (c, objc, cpp)
- `PROJECT_DIALECT`: Language dialect (c, objc, cpp)
- `PROJECT_EXTENSIONS`: Project extensions
- `PROJECT_SOURCE_DIR`: Source directory location
- `PROJECT_IDENTIFIER`: Derived project identifier
- `PROJECT_UPCASE_IDENTIFIER`: Uppercase project identifier
- `PROJECT_DOWNCASE_IDENTIFIER`: Lowercase project identifier
- `PROJECT_PREFIXLESS_NAME`: Name without prefix

#### Template Configuration
- `GITHUB_USER`: GitHub username for template expansion
- `PREFERRED_STARTUP_LIBRARY`: Startup library for templates
- `ONESHOT_FILENAME`: Oneshot filename
- `ONESHOT_CLASS`: Oneshot class name
- `ONESHOT_CATEGORY`: Oneshot category

#### Development Environment
- `MULLE_SDE_GENERATE_FILE_COMMENTS`: Enable/disable file comments (YES/NO)
- `MULLE_USERNAME`: System username for GitHub detection

## Hidden Behaviors & Conditional Logic

### Extension Resolution Order
1. **Meta Extension**: Determines language and build system
2. **Runtime Extension**: Provides runtime libraries and tools
3. **Buildtool Extension**: Provides build system (CMake, Make, etc.)
4. **Extra Extensions**: Additional functionality (git, testing, etc.)
5. **Oneshot Extensions**: Single-file additions

### Template Processing Pipeline
1. **Variable Substitution**: Uses ${VARIABLE} syntax
2. **Environment Variables**: All PROJECT_* variables available
3. **GitHub Detection**: Auto-detects GitHub username from directory structure
4. **Inheritance**: Templates can inherit from "all" project type
5. **Conditional Files**: Files can be specific to project type

### Extension Inheritance System
- **Meta Extensions**: Can inherit other extensions via `inherit` file
- **Inheritance Marks**: Marks propagate to inherited extensions
- **Inheritmarks**: Additional marks for inherited extensions
- **Type Validation**: Prevents cross-type inheritance conflicts

### Mark-Based Installation Control
- **Marks**: Comma-separated list controlling installation behavior
- **Vendor-Specific**: Can target specific extensions with `/<vendor>/<name>`
- **Available Marks**: extension, inherit, env, share, init, sourcetree, project, clobber, demo, motd
- **Negative Marks**: Prefix with `no-` to disable

### Project Type Validation
- **Standard Types**: executable, library, bundle, extension, framework
- **Special Types**: none (no project files), unknown
- **Interactive Selection**: Menu presented for missing meta extension
- **Force Mode**: `-f` bypasses type validation

### Version Compatibility Checking
- **Old Version Detection**: Reads MULLE_SDE_INSTALLED_VERSION
- **Compatibility Check**: Prevents downgrade from newer versions
- **Migration**: Automatic migration between versions
- **Fallback**: Assumes 0.0.0 if version cannot be determined

### GitHub Username Auto-Detection
1. **GITHUB_USER Environment**: Uses if set
2. **Directory Structure**: Assumes `username/project` structure
3. **Validation**: Checks for valid GitHub identifier format
4. **Fallback**: Uses system username if detection fails
5. **Sanitization**: Converts underscores to hyphens

### Directory Structure Creation
- **Share Directory**: `.mulle/share/` for extension data
- **Environment Directory**: `.mulle/share/env/` for environment variables
- **Version Directory**: `.mulle/share/sde/version/` for extension versions
- **Extension File**: `.mulle/share/sde/extension` tracks installed extensions

### Template Variable Expansion
- **PROJECT_NAME**: Project name
- **PROJECT_IDENTIFIER**: Sanitized project identifier
- **PROJECT_UPCASE_IDENTIFIER**: Uppercase identifier
- **PROJECT_DOWNCASE_IDENTIFIER**: Lowercase identifier
- **PROJECT_PREFIXLESS_NAME**: Name without prefix
- **GITHUB_USER**: GitHub username
- **PROJECT_LANGUAGE**: Programming language
- **PROJECT_DIALECT**: Language dialect
- **PROJECT_EXTENSIONS**: Project extensions
- **INCLUDE_COMMAND**: Include/import command based on dialect

### Post-Init Script Execution
- **Location**: `~/bin/post-mulle-sde-init` or `post-mulle-sde-init` in PATH
- **Execution**: Runs automatically unless `--no-post-init` specified
- **Arguments**: Receives PROJECT_LANGUAGE, PROJECT_DIALECT, PROJECT_TYPE
- **Error Handling**: Fails init if script exits with error

### Environment Cleanup
- **Old Directory**: `.mulle.old/` created during reinit/upgrade
- **Selective Cleanup**: Preserves extension file during upgrades
- **Rollback**: Restores `.mulle.old/` on failure
- **Cleanup**: Removes `.mulle.old/` on success

## Practical Examples

### Common Hidden Usage Patterns

#### Advanced Project Setup
```bash
# Initialize with specific extensions
mulle-sde init -m mulle-c/c-developer -r mulle-c/c-runtime -b mulle-c/cmake executable

# Initialize without demo files (for existing projects)
mulle-sde init --no-demo --existing library

# Initialize with custom source directory
mulle-sde init --source-dir mysrc -m mulle-c/c-developer executable

# Initialize with specific vendor extensions
mulle-sde init -m mycompany/c-developer -v mycompany executable
```

#### Extension Management
```bash
# Add extensions to existing project
mulle-sde init --add -e git -e testing

# Reinitialize with new meta extension
mulle-sde init --reinit -m foundation/objc-developer

# Upgrade specific project file only
mulle-sde init --upgrade-project-file CMakeLists.txt

# Force reinitialization
mulle-sde init --reinit -f
```

#### Development Environment Setup
```bash
# Initialize with custom environment variables
mulle-sde init -D CMAKE_BUILD_TYPE=Debug -D CMAKE_VERBOSE_MAKEFILE=ON executable

# Initialize with custom directory structure
mulle-sde init --addiction-dir deps --kitchen-dir build --stash-dir vendor library

# Initialize as subproject
mulle-sde init --subproject -m mulle-c/c-developer library

# Skip environment setup (manual control)
mulle-sde init --no-env executable
```

#### Template Customization
```bash
# Initialize with custom GitHub username
mulle-sde init --github-user myorg -n myproject executable

# Initialize with custom template files
mulle-sde init --template-header-file my-header.h.in --template-footer-file my-footer.h.in library

# Initialize with specific project dialect
mulle-sde init --project-dialect objc --project-language c executable
```

#### CI/CD Pipeline
```bash
# Non-interactive initialization
export GITHUB_USER=myorg
mulle-sde init --no-motd --no-post-init --no-demo -m mulle-c/c-developer executable

# Initialize with specific version control
mulle-sde init --no-motd -e git -e github executable

# Initialize with testing framework
mulle-sde init --no-motd -e testing -e coverage library
```

#### Advanced Extension Control
```bash
# Initialize with selective extension installation
mulle-sde init --no-demo --no-sourcetree -m mulle-c/c-developer executable

# Initialize with custom extension file
mulle-sde init --extension-file /tmp/my-extensions.txt library

# Initialize skipping specific extension components
mulle-sde init --no-demo/mulle-sde/cmake --no-share/mulle-sde/cmake library
```

#### Cross-platform Development
```bash
# Initialize for cross-compilation
mulle-sde init -D CMAKE_TOOLCHAIN_FILE=/path/to/toolchain.cmake executable

# Initialize with specific build configuration
mulle-sde init -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/opt/myapp executable

# Initialize with custom compiler settings
mulle-sde init -D CC=clang -D CXX=clang++ library
```

#### Troubleshooting Examples
```bash
# Debug extension loading issues
MULLE_FLAG_LOG_VERBOSE=YES mulle-sde init -m mulle-c/c-developer executable

# Check what would be installed (dry run)
mulle-sde init --no-env --no-project -m mulle-c/c-developer executable

# Force initialization over existing project
mulle-sde init -f -m mulle-c/c-developer executable

# Initialize with minimal setup
mulle-sde init --no-demo --no-env --no-motd --no-post-init library
```

### Environment Variable Overrides

#### Custom Extension Discovery
```bash
# Add custom extension locations
export MULLE_SDE_EXTENSION_PATH="/opt/mulle-extensions:$HOME/mulle-extensions"
export MULLE_SDE_EXTENSION_BASE_PATH="/usr/local/share/mulle-sde/extensions"

# Use custom default meta extension
export MULLE_SDE_DEFAULT_META_EXTENSION="mycompany/cpp-developer"

# Initialize with custom settings
mulle-sde init executable
```

#### Project Configuration
```bash
# Set up for specific project type
export PROJECT_NAME="MyProject"
export PROJECT_TYPE="library"
export PROJECT_LANGUAGE="c"
export PROJECT_DIALECT="c"
export PROJECT_EXTENSIONS="c:cmake"

# Initialize with custom GitHub user
export GITHUB_USER="mycompany"
mulle-sde init
```

#### Template Customization
```bash
# Custom template variables
export PREFERRED_STARTUP_LIBRARY="MyCompanyFoundation"
export MULLE_SDE_GENERATE_FILE_COMMENTS="NO"

# Initialize with custom settings
mulle-sde init -m mycompany/c-developer executable
```

### Advanced Extension Management

#### Multi-Extension Setup
```bash
# Initialize with multiple extensions
mulle-sde init \
  -m mulle-c/c-developer \
  -r mulle-c/c-runtime \
  -b mulle-c/cmake \
  -e git \
  -e github \
  -e testing \
  -e coverage \
  executable

# Initialize with specific versions
mulle-sde init \
  -m mulle-c/c-developer@1.2.3 \
  -r mulle-c/c-runtime@2.1.0 \
  library
```

#### Extension Inheritance Debugging
```bash
# See what extensions would be installed
mulle-sde extension show --all meta
mulle-sde extension show --all runtime
mulle-sde extension show --all buildtool

# Initialize with verbose extension loading
MULLE_FLAG_LOG_VERBOSE=YES mulle-sde init -m mulle-c/c-developer executable
```

## Troubleshooting

### When to Use Hidden Options

#### Extension Loading Issues
- **Issue**: Extension not found
- **Solution**: Check extension path and use `--extension-file` or set `MULLE_SDE_EXTENSION_PATH`
- **Debug**: `MULLE_FLAG_LOG_VERBOSE=YES mulle-sde init ...`

#### Project Type Issues
- **Issue**: Unknown project type error
- **Solution**: Use `-f` to force unknown types or select from: executable, library, bundle, extension, framework, none
- **Debug**: `mulle-sde extension show --all meta`

#### Template Variable Issues
- **Issue**: Template variables not expanding correctly
- **Solution**: Check `GITHUB_USER` and project name validity
- **Debug**: Use `--dump-env` equivalent by checking environment variables

#### Environment Setup Issues
- **Issue**: Environment not initializing correctly
- **Solution**: Use `--no-env` and run `mulle-env init` manually
- **Debug**: Check `.mulle/share/env/environment.sh` contents

#### Extension Conflicts
- **Issue**: Extension version conflicts during upgrade
- **Solution**: Use `--upgrade` to update extensions
- **Debug**: Check `.mulle/share/sde/extension` file for installed extensions

### Common Error Messages

#### "Could not find extension"
```bash
# Check available extensions
mulle-sde extension show --all

# Check extension search path
echo $MULLE_SDE_EXTENSION_PATH
echo $MULLE_SDE_EXTENSION_BASE_PATH

# Install missing extension
mulle-sde extension install vendor/extension
```

#### "Extension is unversioned"
```bash
# Check extension version file
ls -la .mulle/share/sde/version/vendor/extension/

# Update extension
mulle-sde extension update vendor/extension
```

#### "Missing vendor for extension"
```bash
# Use full vendor/extension format
mulle-sde init -m vendor/extension executable

# Check available vendors
mulle-sde extension show --all | cut -d'/' -f1 | sort -u
```

#### "Project name is empty"
```bash
# Specify project name explicitly
mulle-sde init -n MyProject executable

# Or use directory name
mulle-sde init executable  # uses current directory name
```

### Environment Debugging

#### Check Current Configuration
```bash
# Check extension search paths
for path in $(echo $MULLE_SDE_EXTENSION_PATH | tr ':' '\n'); do
  echo "Extension path: $path"
done

# Check available extensions
mulle-sde extension show --all

# Check project settings
cat .mulle/share/env/environment-project.sh 2>/dev/null || echo "No environment yet"

# Check installed extensions
cat .mulle/share/sde/extension 2>/dev/null || echo "No extensions installed"
```

#### Debug Template Processing
```bash
# Enable verbose logging
export MULLE_FLAG_LOG_VERBOSE=YES
mulle-sde init -m mulle-c/c-developer executable

# Check template variables
echo "GITHUB_USER: $GITHUB_USER"
echo "PROJECT_NAME: $PROJECT_NAME"
echo "PROJECT_TYPE: $PROJECT_TYPE"
```

#### Extension Inheritance Debugging
```bash
# Check extension dependencies
mulle-sde extension show --dependencies mulle-c/c-developer

# Check inheritance chain
find .mulle/share/sde/extensions/ -name "inherit" -exec echo "=== {} ===" \; -exec cat {} \;
```

### Recovery Procedures

#### Failed Initialization Recovery
```bash
# Manual cleanup after failed init
rm -rf .mulle
rm -rf .mulle.old

# Reinitialize
mulle-sde init -f -m mulle-c/c-developer executable
```

#### Partial Initialization Recovery
```bash
# Check what was installed
ls -la .mulle/share/sde/extensions/
cat .mulle/share/sde/extension

# Complete missing extensions
mulle-sde init --add -e missing-extension

# Reinitialize if needed
mulle-sde init --reinit -m mulle-c/c-developer
```

#### Extension Path Issues
```bash
# Reset extension paths
unset MULLE_SDE_EXTENSION_PATH
unset MULLE_SDE_EXTENSION_BASE_PATH

# Test with default paths
mulle-sde extension show --all

# Add specific extension location
export MULLE_SDE_EXTENSION_BASE_PATH="/usr/share/mulle-sde/extensions"
mulle-sde init -m mulle-c/c-developer executable
```

### Performance Optimization

#### Fast Initialization for Development
```bash
# Skip all optional components
mulle-sde init \
  --no-demo \
  --no-motd \
  --no-post-init \
  --no-reflect \
  -m mulle-c/c-developer \
  executable
```

#### CI/CD Optimization
```bash
# Non-interactive with custom settings
export MULLE_SDE_GENERATE_FILE_COMMENTS=NO
export GITHUB_USER=ci-bot
mulle-sde init \
  --no-motd \
  --no-post-init \
  --no-demo \
  --github-user ci-bot \
  -m mulle-c/c-developer \
  library
```

### Cross-Platform Considerations

#### Windows-Specific Issues
```bash
# Use forward slashes in paths
mulle-sde init --source-dir src/subdir executable

# Handle drive letters
mulle-sde init -d "C:/projects/myproject" -m mulle-c/c-developer executable
```

#### macOS-Specific Issues
```bash
# Handle case-sensitive filesystem
export GITHUB_USER=$(whoami)
mulle-sde init -m foundation/objc-developer executable

# Use Homebrew extensions
export MULLE_SDE_EXTENSION_BASE_PATH="/usr/local/share/mulle-sde/extensions"
```

#### Linux-Specific Issues
```bash
# Handle different installation paths
export MULLE_SDE_EXTENSION_BASE_PATH="/usr/share/mulle-sde/extensions"
mulle-sde init -m mulle-c/c-developer executable
```