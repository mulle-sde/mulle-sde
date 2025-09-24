# mulle-sde patternenv - Display Environment Pattern Information

## Quick Start
Display environment pattern and configuration information for the mulle-sde environment.

## All Available Options

### Basic Usage
```bash
mulle-sde patternenv [options]
```

**Arguments:** None

### Visible Options
- `--help`: Show usage information
- `--verbose`: Show detailed pattern information
- `--short`: Show only essential information

### Hidden Options
- `--all`: Show all available pattern information
- `--platform`: Show platform-specific patterns
- `--list`: List all available patterns
- Various pattern-specific display options

## Command Behavior

### Core Functionality
- **Pattern Display**: Show current environment patterns
- **Configuration Info**: Display pattern-based configuration
- **Platform Patterns**: Show platform-specific pattern settings
- **Environment Context**: Show mulle-sde specific pattern information

### Conditional Behaviors

**Output Format:**
- Normal mode: Standard pattern information
- Verbose mode: Detailed pattern configuration
- Short mode: Minimal essential information
- All mode: Comprehensive pattern report

**Pattern Detection:**
- Automatically detects environment patterns
- Shows pattern compatibility information
- Displays pattern inheritance and overrides

## Practical Examples

### Basic Pattern Information
```bash
# Show current environment patterns
mulle-sde patternenv

# Detailed pattern information
mulle-sde patternenv --verbose

# Short pattern info
mulle-sde patternenv --short
```

### Platform-Specific Patterns
```bash
# Show platform patterns
mulle-sde patternenv --platform

# List all available patterns
mulle-sde patternenv --list

# All pattern information
mulle-sde patternenv --all
```

### Environment Context
```bash
# Pattern info with environment context
mulle-sde patternenv --verbose

# Check pattern compatibility
mulle-sde patternenv --platform
```

### Script Integration
```bash
# Get pattern name for scripts
PATTERN_NAME=$(mulle-sde patternenv | cut -d' ' -f1)

# Check pattern type
PATTERN_TYPE=$(mulle-sde patternenv --short | cut -d' ' -f2)

# Pattern-specific logic
case "$(mulle-sde patternenv --platform)" in
    "developer")
        echo "Developer pattern setup"
        ;;
    "production")
        echo "Production pattern setup"
        ;;
    "minimal")
        echo "Minimal pattern setup"
        ;;
esac
```

## Troubleshooting

### No Pattern Information
```bash
# No pattern information shown
mulle-sde patternenv
# Shows empty or default information

# Solution: Ensure in mulle-sde environment
mulle-sde init
mulle-sde patternenv --verbose
```

### Incorrect Pattern Detection
```bash
# Wrong pattern detected
mulle-sde patternenv --platform
# Shows incorrect pattern

# Solution: Check environment configuration
mulle-sde status --verbose
mulle-sde patternenv --all
```

### Pattern Compatibility Issues
```bash
# Pattern compatibility problems
mulle-sde patternenv --verbose
# Shows compatibility warnings

# Solution: Update pattern configuration
mulle-sde style set developer/relax
mulle-sde patternenv --verbose
```

## Integration with Other Commands

### Environment Setup
```bash
# Check patterns before initialization
mulle-sde patternenv --verbose
mulle-sde init

# Pattern-specific initialization
case "$(mulle-sde patternenv --platform)" in
    "linux")
        mulle-sde init --style developer/linux
        ;;
    "darwin")
        mulle-sde init --style developer/macos
        ;;
esac
```

### Tool Configuration
```bash
# Configure tools based on pattern
PATTERN=$(mulle-sde patternenv --platform)
case "$PATTERN" in
    "developer")
        mulle-sde tool add clang gdb
        ;;
    "production")
        mulle-sde tool add gcc
        ;;
    "minimal")
        mulle-sde tool add basic-tools
        ;;
esac
```

### Style Selection
```bash
# Choose style based on pattern
PATTERN_INFO=$(mulle-sde patternenv --all)
if echo "$PATTERN_INFO" | grep -q "developer"; then
    mulle-sde style set developer/relax
else
    mulle-sde style set production
fi
```

## Technical Details

### Pattern Information Sources

**Environment Patterns:**
- Pattern name and type from environment configuration
- Platform-specific pattern settings
- Pattern inheritance and overrides

**Configuration Patterns:**
- Tool configuration patterns
- Build system patterns
- Dependency management patterns

**Platform Patterns:**
- Operating system specific patterns
- Architecture-specific patterns
- Hardware capability patterns

**Environment Context:**
- mulle-sde environment pattern status
- Pattern compatibility flags
- Environment-specific pattern details

### Output Formats

**Standard Output:**
```
developer/relax linux/x86_64
```

**Verbose Output:**
```
Pattern: developer/relax
Platform: linux/x86_64
Architecture: x86_64
OS: Linux
Tools: clang, cmake, gdb
Style: developer
Inheritance: base -> developer -> developer/relax
```

**Short Output:**
```
developer/relax
```

**All Output:**
```
Pattern Information:
  Name: developer/relax
  Type: developer
  Platform: linux/x86_64
  Architecture: x86_64
  OS: Linux Ubuntu 22.04.3 LTS
  Tools: clang-14, cmake-3.22, gdb-12
  Style: developer/relax
  Inheritance: base -> developer -> developer/relax
  Compatibility: full
  Features: debugging, development, testing
```

### Pattern Detection Process
1. **Environment Analysis**: Check current environment configuration
2. **Pattern Matching**: Identify applicable patterns
3. **Platform Detection**: Determine platform-specific patterns
4. **Compatibility Check**: Verify pattern compatibility
5. **Configuration Generation**: Generate pattern-based configuration

### Pattern Types

**Development Patterns:**
- `developer/relax`: Full development environment
- `developer/strict`: Strict development rules
- `developer/minimal`: Minimal development setup

**Production Patterns:**
- `production`: Optimized for production
- `production/debug`: Production with debugging
- `production/minimal`: Minimal production setup

**Specialized Patterns:**
- `testing`: Optimized for testing
- `ci`: Continuous integration setup
- `minimal`: Basic functionality only

## Related Commands

- **[`init`](init.md)** - Initialize with pattern
- **[`style`](style.md)** - Style based on pattern
- **[`tool`](tool.md)** - Tools for pattern
- **[`status`](status.md)** - Status including pattern info