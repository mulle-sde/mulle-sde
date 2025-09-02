# mulle-sde test - Complete Reference

## Quick Start
Run tests for your mulle-sde project with automatic test environment management and dependency handling.

```bash
# Initialize test environment
mulle-sde test init

# Build and run tests
mulle-sde test run

# Generate coverage report
mulle-sde test coverage --mulle

# Generate test files for Objective-C classes
mulle-sde test generate
```

## All Available Options

### Basic Options (in usage)
- `clean`: Clean tests and/or dependencies
- `craft`: Craft library
- `craftorder`: Show order of dependencies being crafted
- `coverage`: Do a coverage run
- `crun`: Craft and run
- `generate`: Generate simple test files (Objective-C only)
- `init`: Initialize a test directory
- `linkorder`: Show library command for linking test executable
- `recraft`: Re-craft library and dependencies
- `rerun`: Rerun failed tests
- `retest`: Clean gravetidy and run tests again
- `run`: Run tests only
- `test-dir`: List test directories

### Advanced Options (hidden)

#### Coverage Command Options
These options are only available with the `coverage` subcommand:

- `--craft`: Skip the "clean" step and proceed directly to crafting
  - **When to use**: When you want to skip rebuilding dependencies without coverage
  - **Example**: `mulle-sde test coverage --craft`
  - **Side effects**: Dependencies won't be rebuilt without coverage information

- `--no-clean`: Alias for `--craft`, skips dependency cleaning
  - **When to use**: Same as `--craft`
  - **Example**: `mulle-sde test coverage --no-clean`

- `--recraft`: Skip both "clean" and "craft" steps, assumes coverage builds exist
  - **When to use**: When you've already built with coverage and just need to rerun
  - **Example**: `mulle-sde test coverage --recraft`

- `--no-craft`: Skip the craft step entirely
  - **When to use**: When your library is already built with coverage
  - **Example**: `mulle-sde test coverage --no-craft`

- `--run`: Skip both "clean" and "craft", run all tests
  - **When to use**: For quick test runs on existing coverage builds
  - **Example**: `mulle-sde test coverage --run`

- `--rerun`: Skip clean/craft and rerun only failed tests
  - **When to use**: After fixing specific test failures
  - **Example**: `mulle-sde test coverage --rerun`

- `--show`: Skip all steps and just show coverage results
  - **When to use**: To view existing coverage data without rebuilding
  - **Example**: `mulle-sde test coverage --show`

- `--no-run`: Stop after building, don't actually run tests
  - **When to use**: When you want coverage-enabled builds but will run tests separately
  - **Example**: `mulle-sde test coverage --no-run`

- `--no-show`: Run tests but skip displaying coverage results
  - **When to use**: For CI systems or automated testing
  - **Example**: `mulle-sde test coverage --no-show`

- `--gcov`: Use gcov instead of gcovr for coverage
  - **When to use**: When you need raw gcov output instead of gcovr reports
  - **Example**: `mulle-sde test coverage --gcov`

- `--gcovr`: Explicitly use gcovr (default)
  - **When to use**: To be explicit about coverage tool choice
  - **Example**: `mulle-sde test coverage --gcovr`

- `--tool <toolname>`: Use a custom coverage tool
  - **When to use**: When you have a custom coverage analysis tool
  - **Example**: `mulle-sde test coverage --tool llvm-cov`

- `--mulle`: Generate HTML coverage report with mulle styling
  - **When to use**: For human-readable coverage reports
  - **Example**: `mulle-sde test coverage --mulle`
  - **Side effects**: Creates `coverage.html` with detailed HTML coverage

- `--json`: Output coverage data in JSON format
  - **When to use**: For automated processing or CI integration
  - **Example**: `mulle-sde test coverage --json`

- `--lines` or `--loc`: Extract lines of code count using jq
  - **When to use**: For metrics collection and reporting
  - **Example**: `mulle-sde test coverage --lines`
  - **Requirements**: Requires `jq` to be installed

- `--percent`: Extract coverage percentage using jq
  - **When to use**: For pass/fail thresholds in CI
  - **Example**: `mulle-sde test coverage --percent`
  - **Requirements**: Requires `jq` to be installed

- `--no-jq`: Disable jq processing even with --lines or --percent
  - **When to use**: When jq is unavailable or you want raw JSON
  - **Example**: `mulle-sde test coverage --percent --no-jq`

#### Generate Command Options
These options are only available with the `generate` subcommand:

- `-f` or `--full`: Generate comprehensive test suites (full test generation)
  - **When to use**: When you want complete test coverage for all class methods/properties
  - **Example**: `mulle-sde test generate --full`
  - **Side effects**: Creates multiple test directories (00_noleak, 10_init, 20_property, 20_method)

#### Test Execution Options
These options are available during test runs:

- `--serial`, `--no-parallel`, `--parallel`: Control parallel test execution
  - **When to use**: `--serial` for debugging race conditions, `--parallel` for speed
  - **Example**: `mulle-sde test run --serial`

- `--coverage`: Enable coverage instrumentation during builds
  - **When to use**: When running tests that need coverage data
  - **Example**: `mulle-sde test craft --coverage`

### Environment Control

#### Direct Environment Variables

- `MULLE_TEST_DIR`: Specifies the tests directory location
  - **Default**: "test"
  - **Set with**: `export MULLE_TEST_DIR=mytests`
  - **Use case**: When you want to use a non-standard test directory name

- `MULLE_TEST_OBJC_DIALECT`: Forces mulle-objc dialect for Objective-C tests
  - **Default**: Not set (uses system default)
  - **Set with**: `export MULLE_TEST_OBJC_DIALECT=mulle-objc`
  - **Use case**: When testing with mulle-clang specifically

- `PROJECT_DIALECT`: Controls the dialect used for tests
  - **Default**: Based on project configuration
  - **Set with**: `export PROJECT_DIALECT=objc`
  - **Use case**: Override automatic dialect detection

- `PROJECT_EXTENSIONS`: File extensions for test files
  - **Default**: Based on language (e.g., ".c", ".m", ".cpp")
  - **Set with**: `export PROJECT_EXTENSIONS="c:m:mm"
  - **Use case**: Custom file extension handling

- `PROJECT_LANGUAGE`: Programming language for tests
  - **Default**: "c"
  - **Set with**: `export PROJECT_LANGUAGE=objc`
  - **Use case**: Explicitly set test language

#### Path and Configuration Variables

- `MULLE_SDE_TEST_PATH`: Colon-separated list of test directories
  - **Default**: "test" (or "." if already in test directory)
  - **Set with**: `export MULLE_SDE_TEST_PATH="test:integration_tests:unit_tests"`
  - **Use case**: Multiple test suites in different directories

- `MULLE_TESTGENERATOR_FLAGS`: Additional flags for test generator
  - **Default**: Not set
  - **Set with**: `export MULLE_TESTGENERATOR_FLAGS="--verbose"`
  - **Use case**: Pass custom options to mulle-testgen

- `MULLE_TEST_FLAGS`: Additional flags for mulle-test
  - **Default**: Not set
  - **Set with**: `export MULLE_TEST_FLAGS="--verbose"`
  - **Use case**: Custom test runner behavior

- `MULLE_TEST`: Override the test executable
  - **Default**: "mulle-test"
  - **Set with**: `export MULLE_TEST=/usr/local/bin/mulle-test-custom`
  - **Use case**: Use a custom test runner or debug build

- `MULLE_TESTGEN`: Override the test generator executable
  - **Default**: auto-detected from PATH
  - **Set with**: `export MULLE_TESTGEN=/opt/mulle-testgen/bin/mulle-testgen`
  - **Use case**: Use a specific version or custom build

## Hidden Behaviors Explained

### Test Directory Discovery

**Automatic Detection**: The system automatically detects test directories based on:
1. Presence of `.mulle-env` directory
2. Proper project structure with test files
3. Environment variable overrides

**Fallback Sequence**:
1. Check if current directory is a test directory
2. Use `MULLE_SDE_TEST_PATH` if set
3. Default to "test" directory
4. Create directory if it doesn't exist

### Environment Isolation

**Test Environment Reset**: When entering test environments, the system:
- Unsets `ADDICTION_DIR`, `DEPENDENCY_DIR`, `KITCHEN_DIR`
- Clears `MULLE_FETCH_SEARCH_PATH` and `MULLE_VIRTUAL_ROOT`
- Creates a clean environment for consistent testing

**Warning System**: If environment variables from the parent project are detected, warnings are shown unless `MULLE_FLAG_LOG_TERSE=YES` is set.

### Coverage Workflow

**Four-Step Process**: The coverage command performs:
1. **Clean**: Rebuild dependencies without coverage
2. **Craft**: Rebuild library with coverage instrumentation
3. **Run**: Execute tests with coverage collection
4. **Show**: Generate coverage reports

**Automatic Serial Execution**: Coverage tests always run serially (`--serial`) to prevent race conditions in coverage file collection.

### Test Generation Flow

**Automatic Tool Installation**: When using `generate`:
1. Checks if `mulle-testgen` is available
2. Automatically installs it via `mulle-env` if missing
3. Links it into the environment

**Directory Structure**: With `--full` flag generates:
- `00_noleak`: Basic memory leak tests
- `10_init`: Initialization tests
- `20_property`: Property access tests
- `20_method`: Method call tests

### Path Validation

**Cross-Environment Validation**: When running tests with specific file paths:
1. Validates all files are in the same test environment
2. Prevents mixing test environments
3. Uses absolute path resolution
4. Provides clear error messages for mismatched environments

## Practical Examples

### Common Hidden Usage Patterns

```bash
# Skip dependency rebuild for faster coverage runs
mulle-sde test coverage --craft --mulle

# Generate only failed test coverage
mulle-sde test coverage --rerun --percent

# Get line count metrics for CI
LINES=$(mulle-sde test coverage --lines)
echo "Total lines: $LINES"

# Use custom coverage tool
mulle-sde test coverage --tool lcov --html

# Run tests from specific directory with serial execution
mulle-sde test run --serial /path/to/specific/test

# Generate comprehensive tests for all classes
mulle-sde test generate --full

# Quick coverage without rebuilding everything
mulle-sde test coverage --run --show

# Clean test environment only
mulle-sde test clean all

# Rebuild with coverage without cleaning
mulle-sde test coverage --recraft --mulle
```

### Environment Variable Overrides

```bash
# Use multiple test directories
export MULLE_SDE_TEST_PATH="test:integration:performance"
mulle-sde test run

# Custom test directory name
export MULLE_TEST_DIR="mytests"
mulle-sde test init

# Force mulle-objc dialect
export MULLE_TEST_OBJC_DIALECT=mulle-objc
mulle-sde test generate

# Use custom test generator
export MULLE_TESTGEN=/opt/custom/mulle-testgen
mulle-sde test generate --full

# Verbose test output
export MULLE_TEST_FLAGS="--verbose --trace"
mulle-sde test run
```

### Advanced CI/CD Integration

```bash
#!/bin/bash
# CI script with coverage thresholds

# Set up environment
export MULLE_SDE_TEST_PATH="test"
export MULLE_TEST_FLAGS="--quiet"

# Run tests with coverage
if mulle-sde test coverage --percent > coverage.json; then
    PERCENTAGE=$(jq -r '.line_percent' coverage.json)
    echo "Coverage: ${PERCENTAGE}%"
    
    if (( $(echo "$PERCENTAGE < 80" | bc -l) )); then
        echo "Coverage below threshold"
        exit 1
    fi
else
    echo "Tests failed"
    exit 1
fi
```

## Troubleshooting

### When to Use Hidden Options

**Performance Issues**: Use `--craft` or `--run` to skip unnecessary rebuilds when iterating on tests.

**Coverage Problems**: Use `--serial` to prevent race conditions in coverage collection.

**Environment Conflicts**: Use `MULLE_SDE_TEST_PATH` to isolate test environments when working with multiple test suites.

**Debug Mode**: Set `MULLE_TEST_FLAGS="--verbose --trace"` for detailed debugging information.

### Common Issues and Solutions

**Missing Test Generator**:
```bash
# Install automatically
mulle-sde test generate
# Or manually
mulle-env tool add mulle-testgen
```

**Coverage Not Updating**:
```bash
# Clean and rebuild with coverage
mulle-sde test coverage --mulle
# Or skip clean for faster iteration
mulle-sde test coverage --craft --mulle
```

**Test Directory Not Found**:
```bash
# Check current test path
mulle-sde test test-dir
# Set custom path
export MULLE_SDE_TEST_PATH="./tests"
```

**Environment Variable Warnings**:
```bash
# Suppress warnings
export MULLE_FLAG_LOG_TERSE=YES
mulle-sde test run
```

**Parallel Test Failures**:
```bash
# Force serial execution
mulle-sde test run --serial
```

### Debugging Test Environment Issues

```bash
# Check test environment
mulle-sde test env

# Validate test directories
mulle-sde test test-dir

# Check current configuration
mulle-env environment list | grep -E "(TEST|PROJECT)"

# Debug coverage generation
mulle-sde test coverage --show --verbose
```