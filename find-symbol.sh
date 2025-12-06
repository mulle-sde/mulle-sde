#!/usr/bin/env bash
# ------------------------------------------------------------
# find-symbol.sh
#   Search C/Objective-C headers for a symbol (macro, var, func,
#   or Obj-C method).
#
# Usage:
#   ./find-symbol.sh <symbol> [path]
#   <symbol>  – the identifier you are looking for (case-sensitive)
#   [path]    – optional root directory (default: current dir)
#
# Example:
#   ./find-symbol.sh myFunction src/
# ------------------------------------------------------------

set -euo pipefail

SYMBOL="${1:-}"
ROOT="${2:-.}"

if [[ -z "$SYMBOL" ]]; then
    echo "Error: missing symbol name"
    echo "Usage: $0 <symbol> [path]"
    exit 1
fi

# Escape for regex
SYM_REGEX=$(printf '%s' "$SYMBOL" | sed 's/[][\.|$(){}?+*^]/\\&/g')

# Patterns ----------------------------------------------------
# 1) Macro definition
MACRO_PAT="^[ \t]*#define[ \t]+${SYM_REGEX}[ \t]*(\(|[^)]|$)"

# 2) Global variable / extern (very permissive – catches most)
VAR_PAT="^[ \t]*(extern|static)?[ \t]*[^;]*\b${SYM_REGEX}\b[^;]*;"

# 3) C function prototype
FUNC_PAT="^[ \t]*[^;{]*\b${SYM_REGEX}\b[ \t]*\([^;]*\)[ \t]*;"

# 4) Obj-C method (class or instance)
OBJC_PAT="^[ \t]*[-+][ \t]*\([^)]*\)[ \t]*${SYM_REGEX}\b"

# Combine all patterns (grep -E extended regex)
ALL_PAT="${MACRO_PAT}|${VAR_PAT}|${FUNC_PAT}|${OBJC_PAT}"

# Find only header files
find "$ROOT" -type f \( -name "*.h" -o -name "*.hpp" -o -name "*.hxx" \) -print0 |
while IFS= read -r -d '' file; do
    # Grep with context (1 line before/after) and colour
    match=$(grep -E -n -H --color=auto "$ALL_PAT" "$file" || true)
    if [[ -n "$match" ]]; then
        echo "=== $file ==="
        echo "$match"
        echo
    fi
done

exit 0
