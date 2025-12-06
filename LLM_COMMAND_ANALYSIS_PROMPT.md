# LLM Command Analysis Prompt for mulle-sde

## Purpose
Create user-focused documentation that reveals **all** available options and behaviors for mulle-sde commands, including hidden/undocumented ones, with clear explanations of what each does and when to use them.

## Analysis Requirements

### 1. Exhaustive Source Analysis
Analyze the source code systematically to extract:

**Primary Analysis Targets:**
- All argument parsing in `case "$1" in` statements
- All `--[a-zA-Z-]*` patterns in argument handling
- All `${VARIABLE:-default}` environment variable references
- All conditional behaviors based on flags/variables
- All function calls with hidden side effects

**Key Search Patterns:**
```bash
# Extract argument parsing
grep -n "case.*in" src/mulle-sde-[command].sh

# Extract all flags
grep -n "--[a-zA-Z-]*" src/mulle-sde-[command].sh | grep -v "echo\|printf"

# Extract environment variables
grep -n "MULLE_[A-Z_]*\|PROJECT_[A-Z_]*\|TEMPLATE_[A-Z_]*" src/mulle-sde-[command].sh

# Extract usage text for comparison
grep -A50 "sde::.*::usage()" src/mulle-sde-[command].sh
```

### 2. User-Focused Documentation Format

For each command, create comprehensive documentation with:

#### Command Overview
- **Purpose**: What the command does
- **Primary use cases**: When users typically need this

#### Complete Options Reference

**Visible Options (from usage)**
```
- [flag]: [brief description]
```

**Hidden/Advanced Options** (with detailed explanations)
```
- [flag]: [what it does]
  - **When to use**: [specific scenarios]
  - **Example**: `mulle-sde [command] [flag] [example]`
  - **Side effects**: [what happens internally]
```

**Environment Variables** (with practical usage)
```
- [VARIABLE]: [what it controls]
  - **Default**: [default value/behavior]
  - **Set with**: `export VARIABLE=value`
  - **Use case**: [when this is useful]
```

#### Hidden Behaviors & Conditional Logic

**URL/Pattern Detection**
- List all automatic pattern recognition
- Show exact conversion rules
- Provide examples for each pattern

**Template Resolution Order**
- Show exact fallback sequence
- List template naming conventions
- Explain extension discovery process

**Context-Dependent Behaviors**
- Project vs. non-project mode differences
- Automatic command execution sequences
- File location and validation rules

### 3. Practical Examples Section

For each hidden option, provide working examples:

```bash
# Hidden option usage examples
mulle-sde add --no-external-command src/foo.c    # Skip external craftinfo commands
mulle-sde add --quick github:user/repo          # Skip automatic fetch/reflect
mulle-sde add --directory /tmp --vendor mulle-c src/test.c  # Create outside project
```

### 4. Troubleshooting Guide

**Common edge cases and solutions:**
- When hidden options are needed
- How to debug unexpected behavior
- Environment variable overrides for specific scenarios

## Final Documentation Structure

```markdown
# mulle-sde [command] - Complete Reference

## Quick Start
[One-line summary of what the command does]

## All Available Options

### Basic Options (in usage)
[visible options]

### Advanced Options (hidden)
[hidden options with detailed explanations]

### Environment Control
[environment variables with practical usage]

## Hidden Behaviors Explained

### [Behavior Category 1]
[detailed explanation with examples]

### [Behavior Category 2]
[detailed explanation with examples]

## Practical Examples

### Common Hidden Usage Patterns
[specific examples for each hidden option]

### Environment Variable Overrides
[examples showing env var usage]

## Troubleshooting

### When to Use Hidden Options
[specific scenarios and solutions]
```

## Quality Checklist

Before finalizing documentation:
- [ ] Every option has a practical use case explanation
- [ ] Every environment variable has a default value and usage example
- [ ] Every hidden behavior has a concrete example
- [ ] Examples are tested or verifiable
- [ ] Documentation is organized for easy reference
- [ ] Cross-references to other commands are included where relevant