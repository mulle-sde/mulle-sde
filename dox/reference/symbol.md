# mulle-sde symbol - Complete Reference

## Quick Start
Extract and analyze symbols from your project's headers and sources using ctags for code navigation, documentation, and analysis.

```bash
mulle-sde symbol                          # List symbols in public headers
mulle-sde symbol --sources                # List symbols in source files
mulle-sde symbol --headers --json         # JSON output for all headers
mulle-sde symbol --ctags-kinds cm         # Objective-C methods only
mulle-sde symbol -- --sort=yes            # Pass options to ctags
```

## All Available Options

### Basic Options (in usage)
- `-f`: Force operation (ignore warnings)
- `--category <name>`: Specify mulle-match category to scan (default: public-headers)
- `--ctags-kinds <s>`: Specify ctags kinds to list (e.g., 'cm' for class/instance methods)
- `--ctags-language <s>`: Override automatic language detection
- `--ctags-output <format>`: Set output format (u-ctags|e-ctags|etags|xref|json|csv)
- `--ctags-xformat <s>`: Custom ctags format string
- `--sources`: Scan source files instead of headers
- `--headers`: Scan all headers (not just public)
- `--public-headers`: Scan public headers (default behavior)
- `--csv-separator <s>`: Separator character for CSV output (default: '|')
- `--keep-tmp`: Keep temporary files for debugging

### Advanced Options (hidden)

#### Language Detection & Override
- `--project-language <language>`: Override project language detection
  - **When to use**: When automatic language detection fails or you want to force a specific language
  - **Example**: `mulle-sde symbol --project-language C++`
  - **Side effects**: Bypasses phonetic matching algorithm for language selection

- `--project-dialect <dialect>`: Override project dialect
  - **When to use**: When working with Objective-C vs C dialects in mixed projects
  - **Example**: `mulle-sde symbol --project-dialect objc`
  - **Side effects**: Affects automatic kind selection and output formatting

#### Symbol Kind Filtering
- `--enumerators`: Include enum constants ('e' kind)
- `--enums`: Include enum definitions ('g' kind)
- `--externs` or `--extern-variables`: Include external variable declarations ('x' kind)
- `--functions`: Include function definitions ('f' kind)
- `--ctag-headers`: Include header files ('h' kind)
- `--labels`: Include goto labels ('L' kind)
- `--locals` or `--local-variables`: Include local variables ('l' kind)
- `--macro-parameters`: Include macro parameters ('D' kind)
- `--macros`: Include macro definitions ('d' kind)
- `--members`: Include struct/class members ('m' kind)
- `--parameters`: Include function parameters ('z' kind)
- `--prototypes`: Include function prototypes ('p' kind)
- `--structs`: Include struct definitions ('s' kind)
- `--typedefs`: Include typedef definitions ('t' kind)
- `--unions`: Include union definitions ('u' kind)
- `--variables` or `--variable-definitions`: Include variable definitions ('v' kind)

#### Objective-C Specific Options
- `--categories`: Include Objective-C categories ('C' kind)
- `--class-methods`: Include Objective-C class methods ('c' kind)
- `--fields`: Include Objective-C fields ('E' kind)
- `--implementations`: Include Objective-C implementations ('I' kind)
- `--instance-methods`: Include Objective-C instance methods ('m' kind)
- `--interfaces`: Include Objective-C interfaces ('i' kind)
- `--methods`: Include both class and instance methods ('mc' kind)
- `--properties`: Include Objective-C properties ('p' kind)
- `--protocols`: Include Objective-C protocols ('P' kind)

#### Output Format Shortcuts
- `--csv`: Shortcut for CSV output format
- `--json`: Shortcut for JSON output format
- `-F <separator>`: Shortcut for custom CSV separator

### Environment Control
- `PROJECT_LANGUAGE`: Project language (auto-detected)
- `PROJECT_DIALECT`: Project dialect (auto-detected)
- Language detection uses phonetic matching against `ctags --list-languages`

## Hidden Behaviors Explained

### Automatic Language Detection
The command uses a sophisticated phonetic matching algorithm to determine the best language match:

1. **Double Metaphone Algorithm**: Converts language names to phonetic codes
2. **Scoring System**: Matches dialect names against available ctags languages
3. **Fallback Logic**: Defaults to 'C' if no good match found
4. **Special Handling**: Objective-C and C++ get special treatment

**Examples**:
```bash
# Automatic detection examples:
mulle-sde symbol                    # Detects from project settings
mulle-sde symbol --project-dialect objc    # Matches "ObjectiveC"
mulle-sde symbol --project-dialect cpp     # Matches "C++"
```

### Preprocessing for C/Objective-C
For C and Objective-C files, the command performs preprocessing:

1. **Macro Removal**: Strips MULLE_OBJC_* macros that confuse ctags
2. **Protocol Class Conversion**: Converts PROTOCOLCLASS macros to standard syntax
3. **Pragma Removal**: Removes #pragma directives that trip up ctags
4. **Temporary Directory**: Creates clean copy in /tmp for processing

**Example**:
```bash
# Shows preprocessing in action:
mulle-sde symbol --keep-tmp --sources
# Will show temp directory with preprocessed files
```

### Output Format Defaults
Automatic format selection based on language:

- **Objective-C**: Defaults to 'xref' format with methods/classes
- **C**: Defaults to 'xref' format, but uses C++ language mode to avoid ctags bug
- **Other Languages**: Defaults to 'json' format

### Cross-Platform Symbol Handling
The command handles platform differences:

1. **Windows Paths**: Properly handles backslashes in paths
2. **Case Sensitivity**: Preserves original case in symbol names
3. **Line Endings**: Handles CRLF vs LF transparently
4. **Compiler Extensions**: Recognizes platform-specific keywords

## Practical Examples

### Basic Symbol Extraction
```bash
# List all symbols in public headers
mulle-sde symbol

# List symbols in all headers
mulle-sde symbol --headers

# List symbols in source files
mulle-sde symbol --sources
```

### Format-Specific Output
```bash
# JSON output for programmatic processing
mulle-sde symbol --json

# CSV output with custom separator
mulle-sde symbol --csv --csv-separator ","

# Traditional ctags format
mulle-sde symbol --ctags-output u-ctags
```

### Language-Specific Filtering
```bash
# Objective-C methods only
mulle-sde symbol --ctags-kinds cm

# C functions and prototypes
mulle-sde symbol --ctags-kinds fp --ctags-language C

# All struct definitions
mulle-sde symbol --structs

# Combined filtering
mulle-sde symbol --functions --variables --enums
```

### Advanced Filtering
```bash
# Objective-C class and instance methods
mulle-sde symbol --class-methods --instance-methods

# All typedefs and structs in headers
mulle-sde symbol --headers --typedefs --structs

# Custom format for integration
mulle-sde symbol --ctags-xformat "%N:%k:%F:%n"
```

### Integration Examples
```bash
# Generate tags file for vim
mulle-sde symbol --ctags-output u-ctags > tags

# Generate TAGS for emacs
mulle-sde symbol --ctags-output etags > TAGS

# JSON output for IDE integration
mulle-sde symbol --json > symbols.json

# CSV for spreadsheet analysis
mulle-sde symbol --csv > symbols.csv
```

### Debugging Symbol Issues
```bash
# Keep temp files to inspect preprocessing
mulle-sde symbol --keep-tmp --sources

# Force specific language
mulle-sde symbol --ctags-language C++ --sources

# Verbose output for debugging
mulle-sde -v symbol --ctags-kinds f --sources
```

### Cross-Platform Usage
```bash
# Windows (PowerShell)
mulle-sde symbol --json | ConvertFrom-Json

# macOS with Xcode
mulle-sde symbol --project-dialect objc --ctags-kinds mc

# Linux with GCC
mulle-sde symbol --ctags-language C --functions
```

## Troubleshooting

### Common Issues and Solutions

#### "No symbols found"
```bash
# Check if files exist in category
mulle-match list --category-matches public-headers

# Try different scope
mulle-sde symbol --headers
mulle-sde symbol --sources

# Force language detection
mulle-sde symbol --ctags-language C
```

#### "ctags: no language found"
```bash
# List supported languages
ctags --list-languages

# Force specific language
mulle-sde symbol --ctags-language C++

# Check file extensions
mulle-match list --type-matches header
```

#### Incorrect Objective-C method detection
```bash
# Use Objective-C specific kinds
mulle-sde symbol --ctags-kinds mc --ctags-language ObjectiveC

# Check preprocessing
mulle-sde symbol --keep-tmp --sources
```

#### Performance issues with large projects
```bash
# Limit scope
mulle-sde symbol --public-headers --ctags-kinds f

# Use specific category
mulle-sde symbol --category public-headers

# Skip preprocessing with --quick (if available)
```

### Environment Variable Debugging
```bash
# Check current language detection
mulle-sde symbol --project-language C
mulle-sde symbol --project-dialect objc

# Override for testing
PROJECT_LANGUAGE=C++ mulle-sde symbol --sources
```

### Integration with Other Commands

#### With reflect
```bash
# After reflect, symbols are updated
mulle-sde reflect
mulle-sde symbol --public-headers --json > current-symbols.json
```

#### With craft
```bash
# Check symbols after building
mulle-sde craft
mulle-sde symbol --sources --functions
```

#### With dependency
```bash
# Analyze dependency symbols
mulle-sde dependency list
mulle-sde symbol --category dependency-headers --ctags-kinds f
```