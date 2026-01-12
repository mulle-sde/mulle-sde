#!/bin/bash
# Compare existing vs generated documentation

echo "=== Documentation Comparison ==="
echo

echo "Existing documentation (dox/reference):"
existing_count=$(ls -1 dox/reference/*.md 2>/dev/null | wc -l)
echo "  Files: $existing_count"

echo
echo "Generated documentation (dox/reference.generated):"
generated_count=$(ls -1 dox/reference.generated/*.md 2>/dev/null | wc -l)
echo "  Files: $generated_count"

echo
echo "Commands only in generated (missing from existing):"
comm -23 \
  <(ls -1 dox/reference.generated/*.md | xargs -n1 basename | sort) \
  <(ls -1 dox/reference/*.md 2>/dev/null | xargs -n1 basename | sort) \
  | head -20

echo
echo "Commands only in existing (not auto-generated):"
comm -13 \
  <(ls -1 dox/reference.generated/*.md | xargs -n1 basename | sort) \
  <(ls -1 dox/reference/*.md 2>/dev/null | xargs -n1 basename | sort) \
  | head -20

echo
echo "Sample generated file sizes:"
ls -lh dox/reference.generated/*.md | head -10
