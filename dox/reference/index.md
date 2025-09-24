# mulle-sde Command Reference

## Overview

**mulle-sde** is a cross-platform command-line IDE and dependency manager for C languages (C, Objective-C, C++). This reference documents all available commands organized by category.

## Command Categories

### Project Management
- **[`init`](init.md)** - Initialize new projects with various templates
- **[`reinit`](reinit.md)** - Reinitialize environment with updated configuration
- **[`status`](status.md)** - Display comprehensive project status information
- **[`clean`](clean.md)** - Clean build artifacts and caches

### Build System
- **[`craft`](craft.md)** - Build project and fetch/manage dependencies
- **[`reflect`](reflect.md)** - Update build system files after source changes
- **[`test`](test.md)** - Run test suites with various options
- **[`debug`](debug.md)** - Debug executables with integrated debugger

### Dependency Management
- **[`dependency`](dependency.md)** - Manage project dependencies
- **[`add`](add.md)** - Add source files, dependencies, or components
- **[`remove`](remove.md)** - Remove files, dependencies, or components
- **[`update`](update.md)** - Update dependencies and components

### Environment Configuration
- **[`environment`](environment.md)** - Manage environment variables and settings
- **[`style`](style.md)** - Configure development environment styles
- **[`tool`](tool.md)** - Manage development tools and toolchains
- **[`config`](config.md)** - Configure mulle-sde settings

### System Integration
- **[`run`](run.md)** - Execute built executables
- **[`uname`](uname.md)** - Display system information
- **[`common-unames`](common-unames.md)** - Display common system information
- **[`patternenv`](patternenv.md)** - Display environment pattern information

### Advanced Operations
- **[`extension`](extension.md)** - Manage mulle-sde extensions
- **[`upgrade`](upgrade.md)** - Upgrade mulle-sde and components
- **[`migrate`](migrate.md)** - Migrate projects between versions
- **[`export`](export.md)** - Export project configurations

### Utility Commands
- **[`list`](list.md)** - List various project components
- **[`find`](find.md)** - Find files and components
- **[`symlink`](symlink.md)** - Manage symbolic links
- **[`headerorder`](headerorder.md)** - Manage header file ordering

### Specialized Commands
- **[`subproject`](subproject.md)** - Manage subprojects
- **[`library`](library.md)** - Manage libraries
- **[`steal`](steal.md)** - Steal components from other projects
- **[`supermarks`](supermarks.md)** - Manage supermarks

## Quick Start Examples

### New Project Setup
```bash
# Initialize new executable project
mulle-sde init -d myproject -m foundation/objc-developer executable

# Add source files
mulle-sde add src/main.m
mulle-sde add src/MyClass.m

# Build project
mulle-sde craft
```

### Development Workflow
```bash
# Edit source files
# ... make changes ...

# Update build system
mulle-sde reflect

# Build and test
mulle-sde craft
mulle-sde test run

# Run executable
mulle-sde run
```

### Dependency Management
```bash
# Add third-party dependency
mulle-sde add github:madler/zlib.tar

# Add local dependency
mulle-sde dependency add ../other-project

# Update all dependencies
mulle-sde dependency update
```

### Environment Configuration
```bash
# Set development style
mulle-sde style set developer/relax

# Configure tools
mulle-sde tool add clang gdb cmake

# Set environment variables
mulle-sde environment set CC clang
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `init` | Project | Initialize new projects |
| `reinit` | Project | Reinitialize environment |
| `status` | Project | Show project status |
| `clean` | Project | Clean artifacts |
| `craft` | Build | Build project |
| `reflect` | Build | Update build files |
| `test` | Build | Run tests |
| `debug` | Build | Debug executables |
| `dependency` | Dependencies | Manage dependencies |
| `add` | Dependencies | Add components |
| `remove` | Dependencies | Remove components |
| `update` | Dependencies | Update components |
| `environment` | Environment | Manage variables |
| `style` | Environment | Configure styles |
| `tool` | Environment | Manage tools |
| `config` | Environment | Configure settings |
| `run` | System | Execute programs |
| `uname` | System | System information |
| `common-unames` | System | Common system info |
| `patternenv` | System | Pattern information |
| `extension` | Advanced | Manage extensions |
| `upgrade` | Advanced | Upgrade components |
| `migrate` | Advanced | Migrate projects |
| `export` | Advanced | Export configurations |
| `list` | Utility | List components |
| `find` | Utility | Find files |
| `symlink` | Utility | Manage symlinks |
| `headerorder` | Utility | Header ordering |
| `subproject` | Specialized | Subproject management |
| `library` | Specialized | Library management |
| `steal` | Specialized | Component stealing |
| `supermarks` | Specialized | Supermarks management |

## Getting Help

### Command Help
```bash
# Get help for specific command
mulle-sde <command> --help

# List all available commands
mulle-sde commands

# Get detailed command information
mulle-sde <command> --help --verbose
```

### Documentation
- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check `mulle-sde status` for project-specific information

## Common Workflows

### Daily Development
1. **Edit** source files in your preferred editor
2. **Reflect** to update build system: `mulle-sde reflect`
3. **Craft** to build: `mulle-sde craft`
4. **Test** your changes: `mulle-sde test run`
5. **Run** to verify: `mulle-sde run`

### Adding Dependencies
1. **Add** dependency: `mulle-sde add <dependency>`
2. **Reflect** build system: `mulle-sde reflect`
3. **Craft** to build with new dependency: `mulle-sde craft`
4. **Test** integration: `mulle-sde test run`

### Environment Setup
1. **Initialize** project: `mulle-sde init`
2. **Configure** style: `mulle-sde style set <style>`
3. **Setup** tools: `mulle-sde tool add <tools>`
4. **Configure** environment: `mulle-sde environment set <vars>`

## Troubleshooting

### Build Issues
```bash
# Clean and rebuild
mulle-sde clean
mulle-sde craft

# Check status
mulle-sde status --verbose

# Debug build process
mulle-sde craft --verbose
```

### Dependency Problems
```bash
# Update dependencies
mulle-sde dependency update

# Clean dependency cache
mulle-sde clean --cache

# Reinitialize environment
mulle-sde reinit
```

### Environment Issues
```bash
# Check environment status
mulle-sde status

# Reset environment
mulle-sde clean --all
mulle-sde init

# Update mulle-sde
mulle-sde upgrade
```

## Advanced Usage

### Custom Build Configurations
```bash
# Use custom CMake options
mulle-sde craft -- --DCMAKE_BUILD_TYPE=Debug

# Build specific targets
mulle-sde craft -- --target mytarget

# Parallel builds
mulle-sde craft -- --parallel 8
```

### Environment Customization
```bash
# Custom environment variables
mulle-sde environment set MY_VAR value

# Custom tool configurations
mulle-sde tool set clang --version 14

# Custom build settings
mulle-sde config set build.parallel 4
```

### Extension Development
```bash
# List available extensions
mulle-sde extension list

# Install extension
mulle-sde extension install myextension

# Create custom extension
mulle-sde extension create myextension
```

## Related Documentation

- **[CLAUDE.md](../CLAUDE.md)** - AI assistant guidance for mulle-sde
- **[TODO.md](../TODO.md)** - Current development status
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines
