# mulle-sde add - Complete Reference

## Quick Start
Add files to your project or create new files from templates, or add dependencies from URLs.

## All Available Options

### Basic Options (in usage)
- `-q`: do not reflect and rebuild
- `-e <extension>`: force file extension
- `-o <vendor/extension>`: oneshot extension to use in vendor/extension form
- `-t <type>`: type of file to create (file)

### Advanced Options (hidden)

#### File Creation Options
- `--directory <path>`: Create files outside of project directory
  - **When to use**: When you need to create template files in a specific location without being in a mulle-sde project
  - **Example**: `mulle-sde add --directory /tmp src/test.c`
  - **Side effects**: Creates a fake project environment with PROJECT_NAME derived from directory name

- `--file-extension <ext>`: Force specific file extension
  - **When to use**: When the template system can't determine the extension from filename
  - **Example**: `mulle-sde add --file-extension hpp src/myfile`

- `--oneshot-extension <vendor/name>`: Use specific extension for file creation
  - **When to use**: When you want to override automatic template selection
  - **Example**: `mulle-sde add --oneshot-extension mulle-c/file src/foo.c`

- `--type <type>`: Force specific template type
  - **When to use**: When automatic type detection fails or you want non-default template
  - **Example**: `mulle-sde add --type protocolclass src/MyProtocol.m`

#### URL/Dependency Options
- `--is-url`: Force treat input as URL
  - **When to use**: When automatic URL detection fails
  - **Example**: `mulle-sde add --is-url custom://host/repo`

- `--no-is-url`: Force treat input as file path
  - **When to use**: When you have a local file that looks like a URL
  - **Example**: `mulle-sde add --no-is-url "git:file"`

- `--embedded`: Add dependency as embedded (in src/)
  - **When to use**: For clibs or when you want dependency source in your project
  - **Example**: `mulle-sde add --embedded clib:user/repo`

- `--amalgamated`: Add dependency as embedded and amalgamated
  - **When to use**: For creating single-header libraries
  - **Example**: `mulle-sde add --amalgamated clib:user/repo`

#### Workflow Control Options
- `--quick`: Skip automatic fetch/reflect/craft after adding
  - **When to use**: When you're adding multiple items and want to defer build
  - **Example**: `mulle-sde add --quick github:user/repo1 github:user/repo2`

- `--no-post-init`: Skip post-init when adding to non-project
  - **When to use**: When adding to directory that isn't a mulle-sde project
  - **Example**: `mulle-sde add --directory /tmp --no-post-init file.c`

- `--no-external-command`: Skip external craftinfo commands
  - **When to use**: When you don't want to run external add commands
  - **Example**: `mulle-sde add --no-external-command src/foo.c`

#### Project Type Options
- `--project-type <type>`: Override project type for non-project mode
  - **When to use**: When creating files outside projects with specific language
  - **Example**: `mulle-sde add --project-type executable src/main.c`

- `--project-dialect <dialect>`: Override project dialect
  - **When to use**: When creating Objective-C vs C++ files outside projects
  - **Example**: `mulle-sde add --project-dialect objc src/MyClass.m`

#### Build Options
- `--debug`: Use debug build type when crafting dependencies
- `--release`: Use release build type when crafting dependencies (default)

### Environment Control
Environment variables are used internally but not typically set by users:
- `PROJECT_NAME`: Derived from directory name in non-project mode
- `PROJECT_LANGUAGE`: Set to "c" in non-project mode
- `PROJECT_DIALECT`: Set based on file extension or --project-dialect
- `TEMPLATE_NO_ENVIRONMENT='YES'`: Prevents environment setup in non-project mode

## Hidden Behaviors Explained

### Automatic URL Detection
The command automatically detects URLs based on these patterns:
- `*://*` - Standard URLs with protocol
- `*:*` - Domain-style URLs (github:user/repo, clib:user/repo)
- `comment:*` - Special comment dependency type

### Template Resolution Order
When creating files:
1. **Direct template match**: Looks for `vendor/specific-type.ext`
2. **Fallback templates**: Uses `vendor/file.ext` if no specific match
3. **Category detection**: Files with `+` (like `NSString+Utils.m`) use category templates
4. **Private detection**: Files with `-` (like `MyClass-private.m`) use private templates

### Context-Dependent Behaviors

#### In Project Mode
- Validates file paths are within project
- Updates build system with `reflect`
- Checks if new files will be found by build system
- Runs `craft` after adding dependencies

#### Non-Project Mode
- Creates fake project environment
- Uses `TEMPLATE_NO_ENVIRONMENT='YES'` to prevent full setup
- Automatically initializes project if needed
- Creates files directly without build system integration

#### Embedded Dependencies
- clib: URLs automatically get `--embedded` flag
- Creates dependencies in `src/` directory
- Sets up embedded build configuration

## Practical Examples

### Common Hidden Usage Patterns
```bash
# Create file in specific directory outside project
mulle-sde add --directory /tmp/test --project-type executable main.c

# Skip automatic build after adding multiple dependencies
mulle-sde add --quick github:user/lib1 github:user/lib2 github:user/lib3

# Use specific template for category files
mulle-sde add --type category NSString+Utils.m

# Force file extension when creating headers
mulle-sde add --file-extension hpp src/MyTemplate.hpp

# Create Objective-C class outside project
mulle-sde add --directory /tmp --project-dialect objc MyClass.m

# Skip external commands for faster file creation
mulle-sde add --no-external-command src/test_file.c
```

### Environment Variable Overrides
```bash
# Create C++ file in non-project mode
PROJECT_DIALECT=cxx mulle-sde add --directory /tmp test.cpp

# Override project name for template generation
PROJECT_NAME=myapp mulle-sde add --directory /tmp main.m
```

## Troubleshooting

### When to Use Hidden Options
- **Path escaping errors**: Use `--directory` to create files outside project
- **Template not found**: Use `--type` to specify exact template type
- **Wrong language detection**: Use `--project-dialect` to force language
- **Build failures after add**: Use `--quick` to skip automatic build, then debug
- **External command issues**: Use `--no-external-command` to skip craftinfo commands

### Common Issues and Solutions
- **"File escapes project"**: Use absolute path with `--directory`
- **"No matching template"**: Check file extension and use `--type` or `--file-extension`
- **"Project not found"**: The command will auto-init, use `--no-post-init` to prevent
- **Build system doesn't see new file**: Ensure file is in `PROJECT_SOURCE_DIR` or update match patterns