# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-sde"      # your project/repository name
DESC="💠 Cross-platform IDE for the command-line"
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
DEPENDENCIES='${MULLE_NAT_TAP}mulle-bashfunctions
${MULLE_SDE_TAP}mulle-env
${MULLE_SDE_TAP}mulle-craft
${MULLE_SDE_TAP}mulle-menu
${MULLE_SDE_TAP}mulle-monitor
${MULLE_SDE_TAP}mulle-platform
${MULLE_SDE_TAP}mulle-sourcetree
${MULLE_SDE_TAP}mulle-template
${MULLE_SDE_TAP}mulle-test
'

DEBIAN_DEPENDENCIES="mulle-bashfunctions (>= 6.0.0), mulle-env, mulle-craft, mulle-menu, mulle-monitor, mulle-platform, mulle-sourcetree, mulle-template, mulle-test"

