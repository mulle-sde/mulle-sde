# mulle-sde remove - Complete Reference

## Quick Start
Remove files, dependencies, or environment variables from your mulle-sde project with automatic cleanup and build system updates.

## All Available Options

### Basic Options (in usage)
```
-h   : show help
-q   : do not reflect and rebuild after dependency removal
```

### Advanced Options (hidden)
```
--is-url : force URL interpretation of argument
  - When to use: When automatic URL detection fails for complex URLs
  - Example: `mulle-sde remove --is-url "custom://host/path/repo"
  - Side effects: Bypasses file existence checks, forces dependency removal flow

--no-is-url : explicitly disable URL interpretation
  - When to use: When you have a local file that contains ':' characters
  - Example: `mulle-sde remove --no-is-url "file:with:colons.txt"
  - Side effects: Forces file removal flow even if argument looks like URL

--is-env : force environment variable interpretation
  - When to use: When removing environment variables that might be ambiguous
  - Example: `mulle-sde remove --is-env "DEBUG"
  - Side effects: Uses mulle-env to remove variable instead of file operations

--no-is-env : explicitly disable environment variable interpretation
  - When to use: When you have files with uppercase names that match env vars
  - Example: `mulle-sde remove --no-is-env "PATH"
  - Side effects: Forces file removal even if name matches environment variable pattern

--no-external-command : skip external craftinfo commands
  - When to use: When you want to bypass custom remove hooks in craftinfo
  - Example: `mulle-sde remove --no-external-command github:user/repo
  - Side effects: Skips ~/.mulle/share/craftinfo remove scripts

--quick : skip automatic reflect/rebuild after dependency removal
  - When to use: When batch removing multiple dependencies
  - Example: `mulle-sde remove --quick github:user/repo1 && mulle-sde remove --quick github:user/repo2
  - Side effects: Requires manual `mulle-sde reflect && mulle-sde craft` afterwards
```

### Environment Control
```
MULLE_SDE_CRAFTINFO_URL: custom craftinfo repository URL
  - Default: https://github.com/craftinfo/craftinfo.git
  - Set with: export MULLE_SDE_CRAFTINFO_URL="https://github.com/myorg/craftinfo.git"
  - Use case: Use organization-specific removal templates and scripts

MULLE_SDE_CRAFTINFO_BRANCH: specific branch for craftinfo repository
  - Default: master/main (auto-detected)
  - Set with: export MULLE_SDE_CRAFTINFO_BRANCH="develop"
  - Use case: Test development versions of removal scripts

MULLE_TECHNICAL_FLAGS: technical flags passed to underlying commands
  - Default: empty
  - Set with: export MULLE_TECHNICAL_FLAGS="-v -x"
  - Use case: Enable verbose/debug output for troubleshooting

MULLE_VIRTUAL_ROOT: project root directory (auto-detected)
  - Default: auto-detected based on .mulle-sde directory
  - Use case: Override project root for testing or unusual directory structures

MULLE_USER_PWD: working directory for relative paths
  - Default: current working directory
  - Use case: Resolve relative paths correctly when running from scripts
```

## Hidden Behaviors Explained

### Automatic Detection Logic
The remove command uses sophisticated heuristics to determine what type of removal to perform:

**URL Detection Patterns:**
- String contains "://" ’ treated as URL
- String contains ":" and parses as valid domain URL ’ treated as URL
- String exists in sourcetree ’ treated as dependency URL
- Examples:
  - `github:user/repo` ’ converted to full URL
  - `gitlab:group/project` ’ converted to full URL
  - `https://github.com/user/repo.git` ’ used as-is

**Environment Variable Detection:**
- All-uppercase names ’ treated as environment variable
- Examples:
  - `DEBUG` ’ environment variable removal
  - `PATH` ’ environment variable removal
  - `src/main.c` ’ file removal (lowercase)

**File Path Resolution:**
- Relative paths ’ resolved against MULLE_USER_PWD
- Absolute paths ’ used as-is
- Symlinks ’ resolved to actual paths
- Must be within project directory ’ fails if outside

### Context-Dependent Execution Flow

**In Project Context (MULLE_VIRTUAL_ROOT set):**
1. Check if argument is dependency URL
2. If dependency: remove via `mulle-sde dependency remove`
3. If file: remove file + run `mulle-sde reflect`
4. If environment variable: remove via `mulle-env`

**Outside Project Context:**
1. Only file removal allowed
2. No automatic reflect/rebuild
3. URLs and environment variables fail

**Automatic Command Sequences:**
- After dependency removal: `reflect` + `craft` (unless --quick)
- After file removal: `reflect` only
- In test directories: uses `test craft` instead of regular craft
- Embedded mode: uses `reflect` + `fetch` instead of full craft

### External Command Integration
When not using `--no-external-command`, the remove command:
1. Updates craftinfo repository from MULLE_SDE_CRAFTINFO_URL
2. Searches for matching remove scripts in ~/.mulle/share/craftinfo
3. Executes external remove commands with project context
4. Falls back to built-in behavior if no external command found

## Practical Examples

### Common Hidden Usage Patterns

**Batch Dependency Removal:**
```bash
# Remove multiple dependencies without rebuilding between each
mulle-sde remove --quick github:user/repo1
cd dependencies && mulle-sde remove --quick github:user/repo2
mulle-sde remove --quick github:user/repo3

# Then rebuild once
mulle-sde reflect && mulle-sde craft
```

**Removing Files with Special Characters:**
```bash
# Remove file with colons in name
mulle-sde remove --no-is-url "config:debug.yaml"

# Remove file with uppercase name that's not an env var
mulle-sde remove --no-is-env "README"
```

**Working Outside Project Context:**
```bash
# Remove file from arbitrary location
mkdir /tmp/test && touch /tmp/test/file.c
cd /tmp/test
mulle-sde remove file.c  # Works without project context
```

**Custom Craftinfo Integration:**
```bash
# Use custom removal scripts
export MULLE_SDE_CRAFTINFO_URL="https://github.com/myorg/custom-craftinfo.git"
mulle-sde remove github:myorg/special-dependency

# Skip external scripts for debugging
mulle-sde remove --no-external-command github:user/repo
```

### Environment Variable Overrides

**Debug Removal Issues:**
```bash
# Enable verbose output
export MULLE_TECHNICAL_FLAGS="-v"
mulle-sde remove github:user/repo

# Use specific craftinfo branch
export MULLE_SDE_CRAFTINFO_BRANCH="develop"
mulle-sde remove github:user/repo

# Override project detection
export MULLE_VIRTUAL_ROOT="/path/to/project"
mulle-sde remove src/file.c
```

**Cross-Platform Path Handling:**
```bash
# Handle paths correctly in scripts
export MULLE_USER_PWD="$(pwd)"
mulle-sde remove "../shared/src/file.c"
```

## Troubleshooting

### When to Use Hidden Options

**"File not found" errors with URLs:**
```bash
# Problem: File with colon in name being treated as URL
mulle-sde remove my:file.txt  # Fails: treats as URL

# Solution: Force file interpretation
mulle-sde remove --no-is-url "my:file.txt"
```

**"Unknown URL" errors:**
```bash
# Problem: Custom URL scheme not recognized
mulle-sde remove custom://host/repo  # Fails

# Solution: Force URL interpretation
mulle-sde remove --is-url "custom://host/repo"
```

**Environment variable confusion:**
```bash
# Problem: Uppercase filename treated as environment variable
mulle-sde remove MAKEFILE  # Fails: tries to remove env var

# Solution: Force file interpretation
mulle-sde remove --no-is-env MAKEFILE
```

**Slow removal operations:**
```bash
# Problem: Each dependency removal triggers full rebuild
mulle-sde remove github:user/repo1  # Slow
mulle-sde remove github:user/repo2  # Slow again

# Solution: Use --quick for batch operations
mulle-sde remove --quick github:user/repo1
cd dependencies && mulle-sde remove --quick github:user/repo2
mulle-sde reflect && mulle-sde craft  # Single rebuild
```

### Debugging Unexpected Behavior

**Enable verbose logging:**
```bash
export MULLE_TECHNICAL_FLAGS="-v"
mulle-sde remove github:user/repo
```

**Check external command execution:**
```bash
# Skip external commands to isolate issues
mulle-sde remove --no-external-command github:user/repo

# Verify craftinfo repository
ls -la ~/.mulle/share/craftinfo/remove/
```

**Verify project context:**
```bash
# Check if in project context
mulle-sde status --clear --project

# Override project root if needed
export MULLE_VIRTUAL_ROOT="/correct/project/path"
```

**Test path resolution:**
```bash
# Check how paths are resolved
export MULLE_TECHNICAL_FLAGS="-v"
mulle-sde remove src/file.c  # Shows resolved paths
```