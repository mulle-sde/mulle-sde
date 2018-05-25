# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-sde"      # your project/repository name
DESC="🏋🏼 Cross-platform IDE for the command-line"
LANGUAGE="bash"             # c,cpp, objc, bash ...

# LANGUAGE="c"             # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

#
# Specify needed homebrew packages by name as you would when saying
# `brew install`.
#
# Use the ${DEPENDENCY_TAP} prefix for non-official dependencies.
# DEPENDENCIES and BUILD_DEPENDENCIES will be evaled later!
# So keep them single quoted.
#
DEPENDENCIES='${TOOLS_TAP}mulle-bashfunctions
${TOOLS_TAP}mulle-env
${TOOLS_TAP}mulle-craft
${TOOLS_TAP}mulle-monitor
${TOOLS_TAP}mulle-sourcetree
'

DEBIAN_DEPENDENCIES="mulle-bashfunctions, mulle-env, mulle-craft, mulle-monitor, mulle-sourcetree"


