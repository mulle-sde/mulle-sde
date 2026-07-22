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
MULLE_SDE_VIBECODING_SH='included'


#
# Check if craft should be redirected to test craft in vibecoding mode
# This is called from the PROJECT directory (not test directory)
#
sde::vibecoding::check_craft_vs_test_craft()
{
   log_entry "sde::vibecoding::check_craft_vs_test_craft" "$@"

   [ "${MULLE_VIBECODING}" != 'YES' ] && return 0

   # Relax for executables: they have no independently testable library API,
   # so blocking craft is too painful. Enforce for libraries etc.
   local project_type

   project_type="$(mulle-env environment get PROJECT_TYPE 2>/dev/null)"
   [ "${project_type}" = 'executable' ] && return 0

   # Check if --mulle-test is already in the arguments
   local arg

   for arg in "$@"
   do
      case "${arg}" in
         --mulle-test)
            return 0
         ;;
      esac
   done

   # Check if test directories exist
   local test_directories

   test_directories="$(mulle-env environment get MULLE_SDE_TEST_PATH 2>/dev/null)"
   test_directories="${test_directories:-test}"

   local dir

   .foreachpath dir in ${test_directories}
   .do
      if [ -d "${dir}" -a "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "Crafting disabled as ${C_MAGENTA}${C_BOLD}vibecoding${C_ERROR} is enabled and a test folder exists.
${C_INFO}Vibecoding is test-driven development. So use this instead:
   ${C_RESET_BOLD}mulle-sde test craft"
      fi
   .done
}


# Check if log should be redirected to test log in vibecoding mode
# This is called from the PROJECT directory (not test directory)
#
sde::vibecoding::check_log_vs_test_log()
{
   log_entry "sde::vibecoding::check_log_vs_test_log" "$@"

   [ "${MULLE_VIBECODING}" != 'YES' ] && return 0

   # Relax for executables: they have no independently testable library API,
   # so blocking log is too painful. Enforce for libraries etc.
   local project_type

   project_type="$(mulle-env environment get PROJECT_TYPE 2>/dev/null)"
   [ "${project_type}" = 'executable' ] && return 0

   # Check if test directories exist
   local test_directories

   test_directories="$(mulle-env environment get MULLE_SDE_TEST_PATH 2>/dev/null)"
   test_directories="${test_directories:-test}"

   local dir

   .foreachpath dir in ${test_directories}
   .do
      if [ -d "${dir}" -a "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "Log disabled as ${C_MAGENTA}${C_BOLD}vibecoding${C_ERROR} is enabled and a test folder exists.
${C_INFO}Vibecoding is test-driven development. So use this instead:
   ${C_RESET_BOLD}mulle-sde test log"
      fi
   .done
}


sde::vibecoding::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} vibecoding [options] [on|off]

   Set some project default so forgetful AIs get automatic reflection and
   craft clean setups. You can use 'sweatcoding' instead of 'vibecoding'
   to invert the meaning.

   With the \`--test\` option you can enforce running tests after each craft,
   which is probably not a good idea, because it slows the AI down massively
   and will impede progressive ideas. This only applies to mulle-test
   style tests.

Options:
   --test           : run tests after craft (if a "test" folder is available)
   --global         : write to global scope
   --this-os        : write to current OS scope
   --this-host      : write to current host scope
   --this-user      : write to current user scope
   --this-os-user   : write to current user+OS scope (default)
   --os <name>      : write to named OS scope
   --host <name>    : write to named host scope
   --user <name>    : write to named user scope
   --scope <name>   : write to an arbitrary named scope

Environment:
   MULLE_SDE_CLEAN_BEFORE_CRAFT   : set to ON for vibecoding
   MULLE_SDE_REFLECT_BEFORE_CRAFT : set to ON for vibecoding
   MULLE_SDE_TEST_AFTER_CRAFT'    : set to ON with --test always
   MULLE_TEST_CLEAN_BEFORE_RUN    : set to ON for vibecoding
EOF
   exit 1
}


sde::vibecoding::env_set()
{
   local scope_flags="$1"
   local variable="$2"
   local flag="$3"

   rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS}  \
                        env ${scope_flags}               \
                             set "${variable}" "${flag}"
}


sde::vibecoding::r_env_get()
{
   local scope_flags="$1"
   local variable="$2"

   RVAL="`rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS} \
                              env ${scope_flags}               \
                                  get --lenient "${variable}"`"
}


sde::vibecoding::env_remove()
{
   local scope_flags="$1"
   local variable="$2"

   sde::vibecoding::r_env_get "${scope_flags}" "${variable}"
   [ -z "${RVAL}" ] && return 0

   rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS} \
                       env ${scope_flags}               \
                           remove "${variable}"
}


sde::vibecoding::r_backup_value_variable()
{
   local variable="$1"

   RVAL="MULLE_SDE_VIBECODING_BACKUP__${variable}"
}


sde::vibecoding::backup_scope_values()
{
   local scope_flags="$1"
   shift

   local variable
   local value
   local backup_value_variable

   for variable in "$@"
   do
      sde::vibecoding::r_env_get "${scope_flags}" "${variable}"
      value="${RVAL}"

      sde::vibecoding::r_backup_value_variable "${variable}"
      backup_value_variable="${RVAL}"

      if [ ! -z "${value}" ]
      then
         sde::vibecoding::env_set "${scope_flags}" "${backup_value_variable}" "${value}"
      else
         sde::vibecoding::env_remove "${scope_flags}" "${backup_value_variable}"
      fi
   done
}


sde::vibecoding::restore_scope_values()
{
   local scope_flags="$1"
   shift

   local variable
   local value
   local current
   local backup_value_variable
   local do_restore='NO'

   for variable in "$@"
   do
      sde::vibecoding::r_backup_value_variable "${variable}"
      backup_value_variable="${RVAL}"

      sde::vibecoding::r_env_get "${scope_flags}" "${backup_value_variable}"
      value="${RVAL}"
      [ -z "${value}" ] && continue

      sde::vibecoding::r_env_get "${scope_flags}" "${variable}"
      current="${RVAL}"
      if [ "${value}" != "${current}" ]
      then
         do_restore='YES'
         break
      fi
   done

   for variable in "$@"
   do
      sde::vibecoding::env_remove "${scope_flags}" "${variable}"
   done

   for variable in "$@"
   do
      sde::vibecoding::r_backup_value_variable "${variable}"
      backup_value_variable="${RVAL}"

      sde::vibecoding::r_env_get "${scope_flags}" "${backup_value_variable}"
      value="${RVAL}"

      if [ ! -z "${value}" -a "${do_restore}" = 'YES' ]
      then
         sde::vibecoding::env_set "${scope_flags}" "${variable}" "${value}"
      fi
      sde::vibecoding::env_remove "${scope_flags}" "${backup_value_variable}"
   done
}


sde::vibecoding::apply_values()
{
   local scope_flags="$1"
   local flag="$2"
   shift 2

   local assignments="$*"
   local assignment
   local variable
   local value
   local variables

   for assignment in ${assignments}
   do
      variable="${assignment%%=*}"
      r_concat "${variables}" "${variable}"
      variables="${RVAL}"
   done

   case "${flag}" in
      YES)
         sde::vibecoding::r_env_get "${scope_flags}" "MULLE_VIBECODING"
         if [ "${RVAL}" != 'YES' ]
         then
            sde::vibecoding::backup_scope_values "${scope_flags}" ${variables}
         fi

         for assignment in ${assignments}
         do
            variable="${assignment%%=*}"
            value="${assignment#*=}"
            sde::vibecoding::env_set "${scope_flags}" "${variable}" "${value}"
         done
      ;;

      NO)
         sde::vibecoding::restore_scope_values "${scope_flags}" ${variables}
      ;;
   esac

   #
   # migrate: remove stale values from legacy --this-user scope if we are
   # now using --this-os-user (scope changed from user to user+os)
   #
   if [ "${scope_flags}" = "--this-os-user" ]
   then
      local backup_value_variable

      for assignment in ${assignments}
      do
         variable="${assignment%%=*}"
         sde::vibecoding::env_remove "--this-user" "${variable}"
         sde::vibecoding::r_backup_value_variable "${variable}"
         sde::vibecoding::env_remove "--this-user" "${RVAL}"
      done
   fi
}


sde::vibecoding::list_info()
{
   log_entry "sde::vibecoding::list_info" "$@"

   local here

   r_basename "${PWD}"
   here="${RVAL}"

   local flag

   flag=$(rexekutor mulle-env --search-here get MULLE_VIBECODING)
   if [ "${flag}" = 'YES' ]
   then
      log_info "Vibecoding is enabled in ${C_RESET_BOLD}${here}"
   else
      log_info "Vibecoding is disabled in ${C_RESET_BOLD}${here}"
   fi
}


sde::vibecoding::list()
{
   log_entry "sde::vibecoding::list" "$@"

   sde::vibecoding::list_info

   local dir

   .foreachpath dir in ${MULLE_SDE_DEMO_PATH:-demo}
   .do
      if [ -d "${dir}" ]
      then
      (
         printf " ${C_INFO}* "
         cd "${dir}" &&
         sde::vibecoding::list_info
      )
      fi
   .done

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         printf " ${C_INFO}* "
         cd "${dir}" &&
         sde::vibecoding::list_info
      )
      fi
   .done
}


sde::vibecoding::main()
{
   log_entry "sde::vibecoding::main" "$@"

   local cmd="$1" # vibecoding or sweatcoding

   local OPTION_SCOPE="--this-os-user"
   local OPTION_TEST='NO'

   shift 

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::vibecoding::usage
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            OPTION_SCOPE="$1"
          ;;

         --test)
            OPTION_TEST='YES'
         ;;

         --os|--host|--user|--scope)
            [ $# -eq 1 ] && sde::vibecoding::usage "Missing argument to \"$1\""

            OPTION_SCOPE="$1 $2"
            shift
          ;;

         -*)
            sde::vibecoding::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local flag 

   flag='YES'
   case $# in 
      0) 
         if [ "${cmd}" != 'sweatcoding' ]
         then
            sde::vibecoding::list
            return
         fi
      ;;

      1)
         case "$1" in
            'y'*|'Y'*|on|ON)
            ;;

            'n'*|'N'*|off|OFF)
               flag='NO'
            ;;

            'list')
               sde::vibecoding::list
               return
            ;;

            *)
               sde::vibecoding::usage "Need on/off got $1"
            ;;
         esac
      ;;

      *)
         shift
         sde::vibecoding::usage "Superflous arguments $*"
      ;;
   esac


   if [ "${cmd}" = 'sweatcoding' ]
   then
      if [ "${flag}" = 'YES' ]
      then
         flag='NO'
      else 
         flag='YES'
      fi
   fi

   local timeout
   local verb

   case "${flag}" in
      'YES')
         verb="vibecoding"
         timeout=10
      ;;

      'NO')
         verb="sweatcoding"
         timeout=0
      ;;
   esac

   log_info "Set ${C_RESET_BOLD}${PROJECT_NAME}${C_INFO} to ${C_MAGENTA}${C_BOLD}${verb}"

   sde::vibecoding::apply_values "${OPTION_SCOPE}" "${flag}" \
      "MULLE_VIBECODING=${flag}" \
      "MULLE_SDE_CLEAN_BEFORE_CRAFT=${flag}" \
      "MULLE_SDE_REFLECT_BEFORE_CRAFT=${flag}" \
      "MULLE_SDE_CRAFT_BEFORE_RUN=${flag}" \
      "MULLE_SDE_RUN_TIMEOUT=${timeout}" \
      "MULLE_SDE_TEST_AFTER_CRAFT=${OPTION_TEST}" \
      "MULLE_TEST_CLEAN_BEFORE_RUN=${flag}"

   local dir

   MULLE_SDE_DEMO_PATH="${MULLE_SDE_DEMO_PATH:-demo}"

   .foreachpath dir in ${MULLE_SDE_DEMO_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
          rexekutor cd "${dir}"

          log_info "Set ${C_RESET_BOLD}${dir}${C_INFO} to ${C_MAGENTA}${C_BOLD}${verb}"
         # demos have no tests
         sde::vibecoding::apply_values "${OPTION_SCOPE}" "${flag}" \
            "MULLE_VIBECODING=${flag}" \
            "MULLE_SDE_CLEAN_BEFORE_CRAFT=${flag}" \
            "MULLE_SDE_CRAFT_BEFORE_RUN=${flag}" \
            "MULLE_SDE_REFLECT_BEFORE_CRAFT=${flag}" \
            "MULLE_SDE_RUN_TIMEOUT=${timeout}" \
            "MULLE_SDE_TEST_AFTER_CRAFT=NO" \
            "MULLE_TEST_CLEAN_BEFORE_RUN=NO"
      )
      fi
   .done

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
          rexekutor cd "${dir}"

          log_info "Set ${C_RESET_BOLD}${dir}${C_INFO} to ${C_MAGENTA}${C_BOLD}${verb}"
         # tests have fixed defaults for some values
         sde::vibecoding::apply_values "${OPTION_SCOPE}" "${flag}" \
            "MULLE_VIBECODING=${flag}" \
            "MULLE_SDE_CLEAN_BEFORE_CRAFT=${flag}" \
            "MULLE_SDE_CRAFT_BEFORE_RUN=YES" \
            "MULLE_SDE_REFLECT_BEFORE_CRAFT=NO" \
            "MULLE_SDE_RUN_TIMEOUT=$(( timeout * 20 ))" \
            "MULLE_SDE_TEST_AFTER_CRAFT=NO" \
            "MULLE_TEST_CLEAN_BEFORE_RUN=${flag}"
      )
      fi
   .done
}


#
# Shared helper for api/howto/code commands that need dependencies crafted.
# Waits if another craft is already running (parallel AI command safety).
#
sde::vibecoding::ensure_dependencies_crafted()
{
   log_entry "sde::vibecoding::ensure_dependencies_crafted" "$@"

   local purpose="${1:-dependencies}"

   local state

   state="$(rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS:--s} quickstatus -p 2>/dev/null)" || state=""
   [ "${state}" = "complete" ] && return 0

   # If another process is already crafting, just wait for it
   local _lockdir

   _lockdir="${MULLE_VIRTUAL_ROOT}/.mulle/var/craft.lock"
   if [ -d "${_lockdir}" ]
   then
      log_verbose "Another craft is running, waiting for ${purpose}..."
      include "lock"
      lock::acquire "${_lockdir}" 300
      lock::release "${_lockdir}"

      state="$(rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS:--s} quickstatus -p 2>/dev/null)" || state=""
      [ "${state}" = "complete" ] && return 0
   fi

   log_verbose "Crafting dependencies to get ${purpose}..."
   rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS:--s} -DMULLE_VIBECODING=NO craft --no-clean craftorder
   return 0
}
