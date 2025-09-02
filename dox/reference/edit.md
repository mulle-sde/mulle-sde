# mulle-sde edit - Complete Reference

## Quick Start
Launch your preferred editor with the current mulle-sde project pre-configured with all necessary environment variables and project context.

```bash
mulle-sde edit                    # Launch editor with current project
mulle-sde edit --select          # Re-select editor from available options
mulle-sde edit --subl            # Force Sublime Text
mulle-sde edit --code            # Force VS Code
```

## All Available Options

### Basic Options (in usage)
- `--select`: Re-select editor from available installed editors
- `--`: Pass remaining arguments to the editor (escape for arguments starting with `--`)

### Advanced Options (hidden)
- `--[editor-name]`: Force specific editor without selection prompt
  - **When to use**: When you want to override the saved preference or skip the selection process
  - **Example**: `mulle-sde edit --clion` forces CLion regardless of saved preference
  - **Side effects**: Skips editor detection and selection menu

- `--squelch`: Suppress editor output (redirect stdout/stderr to /dev/null)
  - **When to use**: When running editors in background or CI environments
  - **Example**: `mulle-sde edit --subl --squelch &` runs Sublime in background silently
  - **Side effects**: No terminal output from editor

- `--no-squelch`: Explicitly enable editor output (opposite of `--squelch`)
  - **When to use**: Override squelching behavior for debugging
  - **Example**: `mulle-sde edit --clion --no-squelch` shows CLion startup messages

- `--json-env`: Output environment variables as JSON instead of launching editor
  - **When to use**: For scripting, debugging, or external tool integration
  - **Example**: `mulle-sde edit --json-env` outputs project paths as JSON
  - **Side effects**: Exits immediately without launching editor

### Environment Control

- **MULLE_SDE_EDITORS**: Colon-separated list of preferred editors in order
  - **Default**: Platform-specific defaults:
    - Linux/Unix: `subl:clion.sh:clion:code:codium:cursor:emacs:micro:vi:windsurf`
    - macOS: `subl:clion:cursor:vscode:windsurf`
    - Windows: `subl.exe:clion.exe:cursor.exe:vscode.exe:windsurf.exe`
  - **Set with**: `export MULLE_SDE_EDITORS="code:subl:vim"
  - **Use case**: Customize editor preference order across all projects

- **MULLE_SDE_EDITOR_CHOICE**: Saved editor preference (set automatically)
  - **Default**: First available editor from MULLE_SDE_EDITORS
  - **Set with**: Automatically saved after editor selection
  - **Use case**: Persistent per-user editor preference

## Hidden Behaviors Explained

### Automatic Editor Detection and Selection
When no editor is specified, the system:
1. Checks installed editors from MULLE_SDE_EDITORS list
2. Presents interactive menu via `mulle-menu` if multiple editors available
3. Saves selection to MULLE_SDE_EDITOR_CHOICE for future use
4. Falls back to first available if only one editor found

### Project Context Detection
- **In mulle-sde project**: Loads full environment including dependency paths
- **Outside mulle-sde project**: Runs editor with basic file/directory arguments
- **Automatic extension installation**: Adds IDE-specific extensions for supported editors

### Editor-Specific Behaviors

#### Sublime Text (`subl`)
- **Auto-detects**: `.sublime-project` files in project root
- **Auto-installs**: `sublime-text` extension if no project file found
- **Arguments**: Uses `--project-file` with detected .sublime-project, or opens project directory
- **Background**: Runs in foreground by default

#### VS Code/Code/Codium/Cursor (`code`, `codium`, `cursor`)
- **Auto-detects**: `.vscode` directory in project root
- **Auto-installs**: `vscode-clang` extension if no .vscode directory
- **Arguments**: Opens project directory if no specific files provided
- **Background**: Runs in foreground by default

#### CLion (`clion`, `clion.sh`)
- **Auto-detects**: `.idea` directory in project root
- **Auto-installs**: `idea` extension if no .idea directory
- **Arguments**: Opens project directory if no specific files provided
- **Background**: Always runs in background with output squelched

#### Other Editors (vim, emacs, micro, vi)
- **Auto-detects**: No IDE-specific features
- **Arguments**: Opens all source files in project if no specific files provided
- **Background**: Runs in foreground by default

### Environment Variable Injection
When running inside a mulle-sde project, automatically exports:
- **ADDICTION_DIR**: Path to addiction directory (dependencies)
- **DEPENDENCY_DIR**: Path to dependency directory
- **KITCHEN_DIR**: Path to kitchen directory (build artifacts)
- **STASH_DIR**: Path to stash directory (source tree)

These variables are available to the editor process for build system integration.

### Cross-Platform Considerations
- **Windows**: Automatically appends `.exe` to editor executables
- **macOS**: Uses macOS-specific editor defaults
- **Linux/Unix**: Uses Unix-specific editor defaults
- **Executable detection**: Uses `command -v` for cross-platform compatibility

## Practical Examples

### Common Hidden Usage Patterns

#### Force Specific Editor
```bash
# Force CLion regardless of saved preference
mulle-sde edit --clion

# Force VS Code
mulle-sde edit --code

# Force Sublime Text
mulle-sde edit --subl
```

#### Background Editor Launch
```bash
# Launch CLion in background (automatic for CLion)
mulle-sde edit --clion &

# Launch VS Code in background with squelched output
mulle-sde edit --code --squelch &
```

#### Editor with Specific Arguments
```bash
# Pass arguments to editor after --
mulle-sde edit -- --new-window                    # VS Code: open in new window
mulle-sde edit -- --add                           # Sublime: add folder to existing window
mulle-sde edit filename.c                         # Open specific file
```

#### Non-Project Mode
```bash
# Use edit command outside mulle-sde project
mkdir /tmp/test && cd /tmp/test
mulle-sde edit                                    # Opens editor with current directory
```

### Environment Variable Overrides

#### Custom Editor Order
```bash
# Prefer VS Code over Sublime
export MULLE_SDE_EDITORS="code:subl:clion"
mulle-sde edit                                    # Will use VS Code if available

# Minimal editor setup for servers
export MULLE_SDE_EDITORS="vi:emacs:micro"
mulle-sde edit                                    # Falls back to vi if others unavailable
```

#### Docker/Container Usage
```bash
# Set editors for container environment
export MULLE_SDE_EDITORS="code"
export MULLE_SDE_EDITOR_CHOICE="code"
mulle-sde edit --json-env                        # Get environment for external editor
```

### Multi-Editor Workflows

#### Different Editors for Different Tasks
```bash
# Use VS Code for main development
export MULLE_SDE_EDITOR_CHOICE="code"

# Temporarily use CLion for debugging
mulle-sde edit --clion                           # Override without changing preference

# Use Sublime for quick edits
mulle-sde edit --subl filename.c                 # Quick edit specific file
```

#### Team Environment Setup
```bash
# Script to standardize editor across team
#!/bin/bash
if command -v code > /dev/null; then
    export MULLE_SDE_EDITOR_CHOICE="code"
elif command -v subl > /dev/null; then
    export MULLE_SDE_EDITOR_CHOICE="subl"
else
    echo "Please install VS Code or Sublime Text"
    exit 1
fi
```

### Advanced Integration Examples

#### External Tool Integration
```bash
# Get project environment as JSON for external tools
mulle-sde edit --json-env > project-env.json

# Use with custom build scripts
export $(mulle-sde edit --json-env | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]')
```

#### CI/CD Pipeline
```bash
# In CI environment, squelch editor output
export MULLE_SDE_EDITORS="code"
mulle-sde edit --code --squelch -- --version     # Check VS Code version silently
```

## Troubleshooting

### When to Use Hidden Options

#### Editor Not Launching
```bash
# Check if editor is in PATH
which code || echo "VS Code not found"

# Force re-selection if editor changed
mulle-sde edit --select

# Override with specific editor path
mulle-sde edit --/usr/local/bin/code
```

#### Extension Installation Issues
```bash
# Manually trigger extension installation
mulle-sde extension add sublime-text              # If Sublime project detection failed
mulle-sde extension add vscode-clang               # If VS Code extension missing
```

#### Environment Variables Not Available
```bash
# Verify environment is loaded
mulle-sde edit --json-env | grep KITCHEN_DIR

# Check if in mulle-sde project
mulle-sde status || echo "Not in mulle-sde project"
```

#### Cross-Platform Issues
```bash
# Windows-specific editor setup
export MULLE_SDE_EDITORS="code.exe:subl.exe"

# macOS app bundles
export MULLE_SDE_EDITORS="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
```

### Debugging Editor Launch
```bash
# Verbose logging for debugging
MULLE_LOG_LEVEL=3 mulle-sde edit --code

# Check what editor would be selected
mulle-sde edit --select                           # Shows menu without launching

# Test editor availability
command -v subl && echo "Sublime available" || echo "Sublime not found"
```

### Common Edge Cases

#### Multiple VS Code Versions
```bash
# Specify exact VS Code binary
mulle-sde edit --/snap/bin/code                    # Snap installation
mulle-sde edit --/usr/share/code/bin/code          # System installation
```

#### Remote Development
```bash
# Use with SSH forwarding
ssh -X user@host "cd project && mulle-sde edit --code"

# Container development
docker exec -it container bash -c "cd /workspace && mulle-sde edit --json-env"
```

#### Headless Environments
```bash
# Detect if running headless
if [ -z "$DISPLAY" ] && [ "$OSTYPE" != "darwin"* ]; then
    echo "No display available, using --json-env"
    mulle-sde edit --json-env
fi
```