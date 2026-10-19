# shellcheck shell=bash
#
#   Copyright (c) 2022 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
#
# User facing frontend for the opt-in shared dependency store of mulle-craft.
# The store itself lives in mulle-craft (src/mulle-craft-store.sh); this module
# only turns the environment variables it reads into a command.
#
MULLE_SDE_SHARED_SH='included'


sde::shared::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} shared [options] [command] [options]

   Manage the opt-in shared dependency store. It lets several projects reuse
   already crafted dependencies instead of building them again.

   The store is a colon separated list of directories ("layers"), like PATH.
   A node is looked up in every layer and the LAST layer that has it wins.
   Only the LAST layer is ever written to; every layer before it is read-only
   and is only picked from. That way projects of "common fate" (one release,
   one product family, one CI job) share one writable layer while picking from
   sturdier layers that were populated before.

   Marking a layer read-only makes it a pure consumer: it is never written to
   (put a \`.read-only\` file into the layer root to make that explicit).

Commands:
   on [<layer>[:<layer>...]] : enable the store for this project (default)
   off                       : disable it and restore the previous setting
   layers                    : show the layers in read order (alias: list)
   status                    : show whether the store is on and its hit rate
   path                      : print the writable (= last) layer
   clean                     : remove the writable layer
   invalidate <name>...      : forget nodes in every layer, so that the next
                               craft rebuilds them (alias: forget, drop)
                               without names: list the stored nodes

   Without an argument \`on\` uses a single shared layer below
   \`\${MULLE_SDE_SHARED_BASE:-\$HOME/.mulle/var/cache/sde/shared}\`. Pass an
   explicit colon separated list, e.g.
      ${MULLE_USAGE_NAME} shared on /srv/release/base:/srv/release/scratch
   to pick from a base and write into a scratch layer.

Options:
   --flavor <value> : also set MULLE_CRAFT_SHARED_FLAVOR, which forces a
                      global rebuild (use it per release)
   --all-layers     : with clean, also remove read-only layers
   --force          : with clean, remove read-only layers too (dangerous);
                      with invalidate, forget nodes in read-only layers too
   --dry-run        : with invalidate, only show what would be forgotten
   --global         : write to global scope
   --this-os        : write to current OS scope
   --this-host      : write to current host scope
   --this-user      : write to current user scope
   --this-os-user   : write to current user+OS scope
   --this-user-host : write to current user+host scope (default)
   --os <name>      : write to named OS scope
   --host <name>    : write to named host scope
   --user <name>    : write to named user scope
   --scope <name>   : write to an arbitrary named scope

   The default scope is a per-user, per-host one. It lands in an
   "environment-user-*.sh" file that the generated .gitignore already
   excludes, because where a cache lives is machine specific and must not
   be committed.

Environment:
   MULLE_CRAFT_SHARED_DEPENDENCY_PATH : the layer list (what \`on\` sets)
   MULLE_CRAFT_SHARED_DEPENDENCY_DIR  : single layer (older setting, \`on\`
                                        clears it)
   MULLE_CRAFT_SHARED_FLAVOR          : extra key component (see --flavor)
   MULLE_SDE_SHARED_BASE              : default base layer for \`on\`

   The store is a prototype: the key does not yet fold in the revisions of
   transitive dependencies. Use \`--flavor\` per release, \`${MULLE_USAGE_NAME}
   shared clean\` when in doubt, or \`${MULLE_USAGE_NAME} shared invalidate
   <name>\` to force just the nodes you know are stale to be rebuilt.
EOF
   exit 1
}


#
# scope value access, same pattern as sde::vibecoding
#
sde::shared::env_set()
{
   local scope_flags="$1"
   local variable="$2"
   local flag="$3"

   rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS}  \
                        env ${scope_flags}               \
                             set "${variable}" "${flag}"
}


sde::shared::r_env_get()
{
   local scope_flags="$1"
   local variable="$2"

   RVAL="`rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS} \
                              env ${scope_flags}               \
                                  get --lenient "${variable}"`"
}


sde::shared::env_remove()
{
   local scope_flags="$1"
   local variable="$2"

   rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS} \
                       env ${scope_flags}               \
                           remove "${variable}"
}


sde::shared::r_backup_value_variable()
{
   RVAL="MULLE_SDE_SHARED_BACKUP__$1"
}


#
# Save the current settings, so that "off" can put them back exactly as they
# were before the first "on". A backup is only taken when there is none yet,
# otherwise repeated "on" would overwrite it with our own value.
#
sde::shared::backup_scope_values()
{
   local scope_flags="$1"
   shift

   local variable
   local value
   local backup_value_variable

   for variable in "$@"
   do
      sde::shared::r_env_get "${scope_flags}" "${variable}"
      value="${RVAL}"

      sde::shared::r_backup_value_variable "${variable}"
      backup_value_variable="${RVAL}"

      if [ ! -z "${value}" ]
      then
         sde::shared::env_set "${scope_flags}" "${backup_value_variable}" "${value}"
      else
         sde::shared::env_remove "${scope_flags}" "${backup_value_variable}"
      fi
   done
}


sde::shared::restore_scope_values()
{
   local scope_flags="$1"
   shift

   local variable
   local value
   local backup_value_variable

   for variable in "$@"
   do
      sde::shared::r_backup_value_variable "${variable}"
      backup_value_variable="${RVAL}"

      sde::shared::r_env_get "${scope_flags}" "${backup_value_variable}"
      value="${RVAL}"
      sde::shared::env_remove "${scope_flags}" "${backup_value_variable}"

      sde::shared::env_remove "${scope_flags}" "${variable}"

      if [ ! -z "${value}" ]
      then
         sde::shared::env_set "${scope_flags}" "${variable}" "${value}"
      fi
   done
}


#
# the layer list as mulle-craft sees it (PATH wins over the older DIR)
#
sde::shared::r_configured_layers()
{
   if [ ! -z "${MULLE_CRAFT_SHARED_DEPENDENCY_PATH:-}" ]
   then
      RVAL="${MULLE_CRAFT_SHARED_DEPENDENCY_PATH}"
      return 0
   fi

   RVAL="${MULLE_CRAFT_SHARED_DEPENDENCY_DIR:-}"
   return 0
}


#
# The one and only layer that is written to: the last one in the list.
#
sde::shared::r_write_layer()
{
   local entry
   local entries
   local last

   sde::shared::r_configured_layers
   [ -z "${RVAL}" ] && return 1

   r_split "${RVAL}" ':'
   entries=( "${RVAL[@]}" )

   last=""
   for entry in "${entries[@]}"
   do
      [ -z "${entry}" ] && continue
      last="${entry}"
   done

   [ -z "${last}" ] && return 1

   RVAL="${last}"
   return 0
}


sde::shared::r_default_layers()
{
   local base

   base="${MULLE_SDE_SHARED_BASE:-${HOME}/.mulle/var/cache/sde/shared}"

   RVAL="${base}"
   return 0
}


sde::shared::list_layers()
{
   local entry
   local entries
   local index
   local layers
   local last
   local note

   sde::shared::r_configured_layers
   layers="${RVAL}"

   if [ -z "${layers}" ]
   then
      log_info "The shared dependency store is ${C_RESET_BOLD}off"
      return 0
   fi

   r_split "${layers}" ':'
   entries=( "${RVAL[@]}" )

   last="${entries[${#entries[@]}-1]}"

   index=1
   for entry in "${entries[@]}"
   do
      [ -z "${entry}" ] && continue

      note='read-only'
      if [ "${entry}" = "${last}" ]
      then
         note='writable'
      fi

      if [ -f "${entry}/.read-only" ]
      then
         note="${note},.read-only"
      fi

      if [ ! -d "${entry}" ]
      then
         note="${note},not created yet"
      fi

      printf "%d: %s (%s)\\n" "${index}" "${entry}" "${note}"
      index=$(( index + 1 ))
   done
}


sde::shared::status()
{
   local counts
   local events
   local layers

   sde::shared::r_configured_layers
   layers="${RVAL}"

   local here

   r_basename "${PWD}"
   here="${RVAL}"

   if [ -z "${layers}" ]
   then
      log_info "The shared dependency store is ${C_RESET_BOLD}off${C_INFO} in ${C_RESET_BOLD}${here}"
      return 0
   fi

   log_info "The shared dependency store is ${C_RESET_BOLD}on${C_INFO} in ${C_RESET_BOLD}${here}"

   sde::shared::list_layers

   if sde::shared::r_write_layer
   then
      events="${RVAL}/.events"
      if [ -f "${events}" ]
      then
         counts="`awk -F';' '{ count[\$1]++ } END { printf \"hits=%d misses=%d busy=%d readonly=%d skipped=%d\", count[\"HIT\"], count[\"MISS\"], count[\"BUSY\"], count[\"RO\"], count[\"SKIP\"] }' "${events}"`"
         log_info "   ${counts}"
      fi
   fi
}


sde::shared::path()
{
   if ! sde::shared::r_write_layer
   then
      log_warning "No shared dependency store is configured"
      return 0
   fi

   printf "%s\\n" "${RVAL}"
}


sde::shared::enable_in()
{
   local scope_flags="$1"
   local layers="$2"
   local flavor="$3"

   local marker

   #
   # Only take a backup once, otherwise a repeated "on" would store our own
   # value as the "previous" one and "off" could no longer remove it. An
   # empty value can not be told apart from "unset", so a marker is used.
   #
   marker='MULLE_SDE_SHARED_BACKUP__MARKER'

   sde::shared::r_env_get "${scope_flags}" "${marker}"
   if [ "${RVAL}" != 'YES' ]
   then
      sde::shared::backup_scope_values "${scope_flags}" \
         MULLE_CRAFT_SHARED_DEPENDENCY_PATH \
         MULLE_CRAFT_SHARED_DEPENDENCY_DIR \
         MULLE_CRAFT_SHARED_FLAVOR

      sde::shared::env_set "${scope_flags}" "${marker}" 'YES'
   fi

   sde::shared::env_set "${scope_flags}" \
      'MULLE_CRAFT_SHARED_DEPENDENCY_PATH' "${layers}"

   # it would only shadow the layer list and produce a warning
   sde::shared::env_remove "${scope_flags}" \
      'MULLE_CRAFT_SHARED_DEPENDENCY_DIR'

   if [ ! -z "${flavor}" ]
   then
      sde::shared::env_set "${scope_flags}" \
         'MULLE_CRAFT_SHARED_FLAVOR' "${flavor}"

      MULLE_CRAFT_SHARED_FLAVOR="${flavor}"
      export MULLE_CRAFT_SHARED_FLAVOR
   fi

   #
   # mulle-env writes the file for the *next* invocation, the running process
   # is not updated. Update it here, so that "on" can report what it just did
   # (and so that a craft within the same process would already see it).
   #
   MULLE_CRAFT_SHARED_DEPENDENCY_PATH="${layers}"
   export MULLE_CRAFT_SHARED_DEPENDENCY_PATH
}


sde::shared::disable_in()
{
   local scope_flags="$1"

   sde::shared::restore_scope_values "${scope_flags}" \
      MULLE_CRAFT_SHARED_DEPENDENCY_PATH \
      MULLE_CRAFT_SHARED_DEPENDENCY_DIR \
      MULLE_CRAFT_SHARED_FLAVOR

   sde::shared::env_remove "${scope_flags}" 'MULLE_SDE_SHARED_BACKUP__MARKER'

   unset MULLE_CRAFT_SHARED_DEPENDENCY_PATH
   unset MULLE_CRAFT_SHARED_DEPENDENCY_DIR
   unset MULLE_CRAFT_SHARED_FLAVOR
}


#
# Also write the settings into every test directory: a test environment has its
# own scope and would otherwise craft dependencies into a store of its own.
#
sde::shared::on()
{
   local scope_flags="$1"
   local flavor="$2"
   shift 2

   local layers

   #
   # --flavor is accepted here as well, so that both
   #   shared --flavor X on <layers>   and
   #   shared on --flavor X <layers>   work
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         --flavor)
            [ $# -eq 1 ] && sde::shared::usage "Missing argument to --flavor"

            flavor="$2"
            shift
         ;;

         -*)
            sde::shared::usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case $# in
      0)
         sde::shared::r_default_layers
         layers="${RVAL}"
      ;;

      1)
         layers="$1"
      ;;

      *)
         sde::shared::usage "Too many arguments to \"on\""
      ;;
   esac

   [ -z "${layers}" ] && sde::shared::usage "No layer given to \"on\""

   if [ -z "${MULLE_VIRTUAL_ROOT:-}" ]
   then
      fail "There is no mulle-sde project here. Use \\`mulle-sde init\\` or enter one first."
   fi

   log_info "Enabling the shared dependency store"

   sde::shared::enable_in "${scope_flags}" "${layers}" "${flavor}"

   sde::shared::foreach_test_directory "${scope_flags}" 'ON' "${layers}" "${flavor}"

   sde::shared::list_layers
}


sde::shared::off()
{
   local scope_flags="$1"

   log_info "Disabling the shared dependency store"

   sde::shared::disable_in "${scope_flags}"

   sde::shared::foreach_test_directory "${scope_flags}" 'OFF' '' ''
}


sde::shared::foreach_test_directory()
{
   local scope_flags="$1"
   local mode="$2"
   local layers="$3"
   local flavor="$4"

   local dir

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
         (
            cd "${dir}" || exit 1

            case "${mode}" in
               'ON')
                  log_verbose "Enabling the shared dependency store in ${C_RESET_BOLD}${dir}${C_VERBOSE}"
                  sde::shared::enable_in "${scope_flags}" "${layers}" "${flavor}"
               ;;

               *)
                  sde::shared::disable_in "${scope_flags}"
               ;;
            esac
         ) || return 1
      fi
   .done
}


#
# mulle-craft is environment driven here (it has no option for this), so the
# request is passed along as an environment variable, the same way "mulle-sde
# clean shared" already does it.
#
sde::shared::clean()
{
   local all_layers="$1"
   local force="$2"
   shift 2

   #
   # the flags are also accepted behind "clean", so that
   #   shared clean --all-layers --force   works
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         --all-layers|--all)
            all_layers='YES'
         ;;

         --force)
            force='YES'
         ;;

         *)
            sde::shared::usage "Unknown option $1"
         ;;
      esac

      shift
   done

   sde::shared::r_configured_layers
   if [ -z "${RVAL}" ]
   then
      log_warning "No shared dependency store is configured"
      return 0
   fi

   if [ "${all_layers}" = 'YES' ]
   then
      MULLE_CRAFT_SHARED_REMOVE_ALL_LAYERS='YES'
      export MULLE_CRAFT_SHARED_REMOVE_ALL_LAYERS

      log_verbose "Also removing read-only layers"
   fi

   if [ "${force}" = 'YES' ]
   then
      MULLE_CRAFT_SHARED_REMOVE_FORCE='YES'
      export MULLE_CRAFT_SHARED_REMOVE_FORCE

      log_verbose "Removing read-only layers as well"
   fi

   rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean \
                  shared-dependency-store
}


#
# Which nodes does the store hold? One block per layer, so that a name that is
# about to be invalidated can be checked for typos first.
#
sde::shared::list_nodes()
{
   local entry
   local entries
   local nodes

   sde::shared::r_configured_layers
   if [ -z "${RVAL}" ]
   then
      log_warning "No shared dependency store is configured"
      return 0
   fi

   r_split "${RVAL}" ':'
   entries=( "${RVAL[@]}" )

   local found

   found='NO'

   for entry in "${entries[@]}"
   do
      [ -z "${entry}" ] && continue
      [ -d "${entry}" ] || continue

      nodes="`find "${entry}" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | LC_ALL=C sort`"
      if [ -z "${nodes}" ]
      then
         continue
      fi

      found='YES'

      printf "%s\n" "${entry}:"
      printf "%s\n" "${nodes}" | sed -e 's|.*/||' -e 's|^|   |'
   done

   if [ "${found}" = 'NO' ]
   then
      log_info "The shared dependency store holds no nodes yet"
   fi

   return 0
}


#
# Forget nodes in the shared store, so that the next craft rebuilds them. This
# is the manual override for the one thing the key can not know: the revisions
# of a node's dependencies (see the note in the usage text).
#
# mulle-craft owns the store and is environment driven, so the request is
# handed over as an environment variable, the same way "clean" does it.
#
sde::shared::invalidate()
{
   local force="$1"
   local dry_run="$2"
   shift 2

   local names

   names=''

   while [ $# -ne 0 ]
   do
      case "$1" in
         --force)
            force='YES'
         ;;

         --dry-run)
            dry_run='YES'
         ;;

         -*)
            sde::shared::usage "Unknown option $1"
         ;;

         *)
            printf -v names "%s%s:" "${names}" "$1"
         ;;
      esac

      shift
   done

   sde::shared::r_configured_layers
   if [ -z "${RVAL}" ]
   then
      log_warning "No shared dependency store is configured"
      return 0
   fi

   if [ -z "${names}" ]
   then
      sde::shared::list_nodes
      return 0
   fi

   names="${names%:}"

   MULLE_CRAFT_SHARED_REMOVE_NODES="${names}"
   export MULLE_CRAFT_SHARED_REMOVE_NODES

   if [ "${force}" = 'YES' ]
   then
      MULLE_CRAFT_SHARED_REMOVE_FORCE='YES'
      export MULLE_CRAFT_SHARED_REMOVE_FORCE
   fi

   if [ "${dry_run}" = 'YES' ]
   then
      MULLE_CRAFT_SHARED_REMOVE_DRY_RUN='YES'
      export MULLE_CRAFT_SHARED_REMOVE_DRY_RUN
   fi

   log_info "Invalidating \"${names}\" in the shared dependency store"

   rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean \
                  shared-dependency-store
}


sde::shared::main()
{
   log_entry "sde::shared::main" "$@"

   # "shared" itself
   shift

   #
   # deliberately per-user and per-host: the value points at a local cache
   # and must not be committed to the repository
   #
   local OPTION_SCOPE="--this-user-host"
   local OPTION_FLAVOR=''
   local OPTION_ALL_LAYERS='NO'
   local OPTION_FORCE='NO'
   local OPTION_DRY_RUN='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::shared::usage
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            OPTION_SCOPE="$1"
         ;;

         --os|--host|--user|--scope)
            [ $# -eq 1 ] && sde::shared::usage "Missing argument to \"$1\""

            OPTION_SCOPE="$1 $2"
            shift
         ;;

         --flavor)
            [ $# -eq 1 ] && sde::shared::usage "Missing argument to \"$1\""

            OPTION_FLAVOR="$2"
            shift
         ;;

         --all-layers)
            OPTION_ALL_LAYERS='YES'
         ;;

         --force)
            OPTION_FORCE='YES'
         ;;

         --dry-run)
            OPTION_DRY_RUN='YES'
         ;;

         -*)
            sde::shared::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd

   cmd="${1:-status}"

   case "${cmd}" in
      on|enable|start)
         shift
         sde::shared::on "${OPTION_SCOPE}" "${OPTION_FLAVOR}" "$@"
      ;;

      off|disable|stop)
         sde::shared::off "${OPTION_SCOPE}"
      ;;

      layers|list)
         sde::shared::list_layers
      ;;

      status)
         sde::shared::status
      ;;

      path)
         sde::shared::path
      ;;

      clean)
         shift
         sde::shared::clean "${OPTION_ALL_LAYERS}" "${OPTION_FORCE}" "$@"
      ;;

      invalidate|forget|drop)
         shift
         sde::shared::invalidate "${OPTION_FORCE}" "${OPTION_DRY_RUN}" "$@"
      ;;

      *)
         sde::shared::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
