#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
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
MULLE_SDE_CONFIG_SH="included"


sde::config::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} sourcetree [options] [command]

   This command manipulates mulle-sourcetree configs for a project. Usually
   your project only has one sourcetree configuration named "config", but
   sometimes it can be useful to have multiple sourcetree configurations.

Commands:
   copy   : copy a sourcetree configuration
   list   : list current sourcetree configurations
   name   : get name of current sourcetree configuratioon
   switch : change to a different sourcetree configuration
   remove : remove a sourcetree configuration
   show   : show available configurations of the current sourcetree

EOF
   exit 1
}



sde::config::name_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config name [options]

   List the currently active sourcetree configuration name. You can also see
   the available sourcetree configuration names.

Options:
   -a                  : list all sourcetree config names

EOF
   exit 1
}



sde::config::switch_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config switch [options] <name>

   Changes the sourcetree configuration for the current project. Only the
   current project is affected and not the dependencies. Also: the current
   project will not be affected, if compiled by another project _as_ a
   dependency.

   To change the sourcetree configuration of a dependency use the -d option.
   The actual change is perfomed by setting a global environment variable
   MULLE_SOURCETREE_CONFIG_NAMES_\${PROJECT_UPCASE_IDENTIFIER}. To figure
   out the proper identifier for a given project, use the
   "mulle-sde env-identifier" command.

   It is necessary to "clean tidy" and "reflect" the project after the
   change.

Options:
   -d <dependency> : change configuration of a dependency instead
   -p              : print current configuration name

EOF
   exit 1
}


sde::config::list_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config list

   List the currently active sourcetree configuration overrides. There will
   be always a line for the current project, though there may not be an
   actual environment entry.

EOF
   exit 1
}




sde::config::show_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config show

   Show the currently available sourcetree configuration names.

EOF
   exit 1
}


#
# this function is actually executed inside mulle-sourcetree so
# globals and other functions are not necessarily available.
#
sde::config::walk_config_name_callback()
{
   local reflectfile
   local config

   reflectfile=".mulle/etc/sde/reflect"
   if [ -f "${reflectfile}" ]
   then
      config="`egrep -v '^#' "${reflectfile}" `"
   fi
   config="${config:-config}"

   local identifier

   r_basename "${NODE_FILENAME}"
   r_smart_upcase_identifier "${RVAL}"
   identifier="${RVAL}"

   local address

   r_basename "${NODE_ADDRESS}"
   address="${RVAL}"

   printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAMES_${identifier}" "${config}"
}


sde::config::walk_name_callback_no_default()
{
   local reflectfile
   local config

   reflectfile=".mulle/etc/sde/reflect"
   if [ -f "${reflectfile}" ]
   then
      config="`egrep -v '^#' "${reflectfile}" `"
   fi
   config="${config:-config}"

   if [ "${config}" != "config" ]
   then
      local identifier

      r_basename "${NODE_FILENAME}"
      r_smart_upcase_identifier "${RVAL}"
      identifier="${RVAL}"

      local address

      r_basename "${NODE_ADDRESS}"
      address="${RVAL}"

      printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAMES_${identifier}" "${config}"
   fi
}


sde::config::walk_callback()
{
   if [ -z "${MULLE_SOURCETREE_CONFIG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-config.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-config.sh" || exit 1
   fi


   local names

   names="`(
      eval $(mulle-env --search-here mulle-tool-env sourcetree) ;
      log_setting "MULLE_SOURCETREE_ETC_DIR   : ${MULLE_SOURCETREE_ETC_DIR}"
      log_setting "MULLE_SOURCETREE_SHARE_DIR : ${MULLE_SOURCETREE_SHARE_DIR}"
      sourcetree::config::list_main --no-warn --name-only --separator ','
      )`"

   local identifier

   r_basename "${NODE_FILENAME}"
   r_smart_upcase_identifier "${RVAL}"
   identifier="${RVAL}"

   local address

   r_basename "${NODE_ADDRESS}"
   address="${RVAL}"

   printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAMES_${identifier}" "${names}"
}


sde::config::walk_callback_no_default()
{
   if [ -z "${MULLE_SOURCETREE_CONFIG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-config.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-config.sh" || exit 1
   fi

   local names

   names="`(
      eval $(mulle-env --search-here mulle-tool-env sourcetree) ;
      log_setting "MULLE_SOURCETREE_ETC_DIR   : ${MULLE_SOURCETREE_ETC_DIR}"
      log_setting "MULLE_SOURCETREE_SHARE_DIR : ${MULLE_SOURCETREE_SHARE_DIR}"
      sourcetree::config::list_main --no-warn --name-only --separator ','
      )`"


   if [ ! -z "${names}" -a "${names}" != "config" ]
   then
      local identifier

      r_basename "${NODE_FILENAME}"
      r_smart_upcase_identifier "${RVAL}"
      identifier="${RVAL}"

      local address

      r_basename "${NODE_ADDRESS}"
      address="${RVAL}"

      printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAMES_${identifier}" "${names}"
   fi
}


sde::config::dependency_walk()
{
   local functionname="$1"

   # get "source" of function into callback
   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -N \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS:-} \
               walk \
                  --cd \
                  --marks dependency,mainproject \
                  --declare-function "`declare -f "${functionname}" `" \
                  "${functionname}"
   return $?
}


sde::config::show()
{
   log_entry "sde::config::show" "$@"

   local OPTION_IGNORE_DEFAULT='YES'
   local OPTION_LIST_NAMES='NO'
   local OPTION_LIST_ALL='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::show_usage
         ;;

         --ignore-default)
            OPTION_IGNORE_DEFAULT='YES'
         ;;

         --no-ignore-default)
            OPTION_IGNORE_DEFAULT='NO'
         ;;

         --name|--names)
            OPTION_LIST_NAMES='YES'
         ;;

         -*)
            sde::config::show_usage "Unknown config list option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 0 ] && sde::config::show_usage "Superflous arguments $*"

   local identifier

   include "case"

   r_smart_upcase_identifier "${PROJECT_NAME:-local}"
   identifier="${RVAL}"

   local names

   names="`MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -N \
                           -s \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_SOURCETREE_FLAGS:-} \
                        config list --separator ',' --name-only `"

   if [ ! -z "${names}" -a "${names}" != "config" ]
   then
      printf "%s (%s): %s\n" "${PROJECT_NAME}" "MULLE_SOURCETREE_CONFIG_NAMES_${identifier}" "${names}"
   fi

   if [ "${OPTION_LIST_NAMES}" = 'YES' ]
   then
      if [ "${OPTION_IGNORE_DEFAULT}" = 'YES' ]
      then
         sde::config::dependency_walk sde::config::walk_name_callback_no_default
      else
         sde::config::dependency_walk sde::config::walk_config_name_callback
      fi
   else
      if [ "${OPTION_IGNORE_DEFAULT}" = 'YES' ]
      then
         sde::config::dependency_walk sde::config::walk_callback_no_default
      else
         sde::config::dependency_walk sde::config::walk_callback
      fi
   fi
   return $?
}


sde::config::list()
{
   log_entry "sde::config::list" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::list_usage
         ;;

         -*)
            sde::config::list_usage "Unknown config list option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "sde::project"

   sde::project::set_name_variables

   result="`MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
   rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           -s \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS:-} \
                        environment list --output-eval  \
   | egrep '^MULLE_SOURCETREE_CONFIG_NAMES_' \
   | sort `"

   local key

   key="MULLE_SOURCETREE_CONFIG_NAMES_${PROJECT_UPCASE_IDENTIFIER}"

   if [ -z "`egrep "^${key}=" <<< "${result}" > /dev/null `" ]
   then
      r_add_line "${key}=config" "${result}"
      result="${RVAL}"
   fi

   printf "%s\n" "${result}"
}



sde::config::switch()
{
   log_entry "sde::config::switch" "$@"

   local OPTION_PRINT='NO'
   local OPTION_DEPENDENCY

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::switch_usage
         ;;

         -a)
            MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
               rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                                 -N \
                                 ${MULLE_TECHNICAL_FLAGS} \
                                 ${MULLE_SOURCETREE_FLAGS:-} \
                              "$@" || exit 1
         ;;

         -p|--print)
            OPTION_PRINT="YES"
         ;;

         -d|--dependency)
            [ $# -eq 1 ] && sde::craft::switch_usage "Missing argument to \"$1\""
            shift

            OPTION_DEPENDENCY="$1"
         ;;

         -*)
            sde::config::switch_usage "Unknown config switch option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   local project_name

   project_name="${OPTION_DEPENDENCY:-${PROJECT_NAME}}"

   local identifier

   include "case"

   r_smart_upcase_identifier "${project_name}"
   identifier="${RVAL}"

   local varname

   varname="MULLE_SOURCETREE_CONFIG_NAMES_${identifier}"

   if [ "${OPTION_PRINT}" = 'YES' ]
   then
      ##
      ## GET
      ##
      [ "$#" -ne 0 ] && sde::config::switch_usage "Superflous arguments $*"

      local value

      value="`MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
               rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS:-} \
                        environment get "${varname}" `"

      printf "%s\n" "${value:-config}"
      return 0
   fi

   ##
   ## SET
   ##

   [ "$#" -eq 0 ] && sde::config::switch_usage "Missing config name"

   local name

   name="$1" ; shift

   [ "$#" -ne 0 ] && sde::config::switch_usage "Superflous arguments $*"

   local dependency_dir

   if [ ! -z "${OPTION_DEPENDENCY}" ]
   then
      [ "${OPTION_DEPENDENCY}" = "${PROJECT_NAME}" ] && fail "Dependency is the actual project. Omit -d <dependency> from command"

      # get the destination folder for the dependency
      # check if its a symlink, if yes warn/bail
      include "sde::dependency"

      dependency_dir="`sde::dependency::source_dir_main "${OPTION_DEPENDENCY}" `" || exit 1
      if [ ! -e "${dependency_dir}" ]
      then
         fail "Dependency \"${name}\" hasn't been fetched yet"
      fi

      if [ -L "${dependency_dir}" ]
      then
         if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
         then
            log_warning "${dependency_dir#${MULLE_USER_PWD}/} is a symlink. The change may affect other projects."
         else
            fail "${dependency_dir#${MULLE_USER_PWD}/} is a symlink. The change could affect other projects.
${C_INFO}Use -f to force the switch"
         fi
      fi
   fi

   #
   # need to reflect before clean tidy for the dependency
   #
   if [ ! -z "${dependency_dir}" ]
   then
      # goto dependency_dir and switch there (which will reflect). Then the
      # "config name" for the dependency project reflects the state properly
      (
         log_info "${C_CYAN}*${C_INFO} Switch dependency in ${C_MAGENTA}${C_BOLD}${OPTION_DEPENDENCY}${C_INFO} (${dependency_dir#${MULLE_USER_PWD}/})"

         cd "${dependency_dir}" || exit 1
         MULLE_VIRTUAL_ROOT=
         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                             ${MULLE_SDE_FLAGS} \
                             config switch "${name}"
      ) || fail "failed because $?"
   fi

   #
   # when we change the environment with mulle-env
   # it doesn't affect our local environment so we need to
   # also eval it
   #
   if [ "${name}" != "config" ]
   then
      log_info "${C_CYAN}*${C_INFO} Set ${C_RESET_BOLD}${varname}${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} to ${C_RESET_BOLD}${name}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment set "${varname}" "${name}" || exit 1
      eval "${varname}='${name}'"
      eval "export ${varname}"
   else
      log_info "${C_CYAN}*${C_INFO} Remove ${C_RESET_BOLD}${varname}${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment remove "${varname}"  || exit 1
      eval unset "${varname}"
   fi

   log_setting "${varname} : ${!varname}"


   #
   # need to get rid of old stuff in share
   #
   include "sde::clean"

   log_info "${C_CYAN}*${C_INFO} Clean tidy ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} (${PWD#${MULLE_USER_PWD}/})"

   sde::clean::main "tidy"

   #
   # need to refetch stuff into share
   #

   include "sde::fetch"

   log_info "${C_CYAN}*${C_INFO} Fetch ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} (${PWD#${MULLE_USER_PWD}/})"

   sde::fetch::main

   if [ ! -z "${dependency_dir}" ]
   then
      return 0
   fi

   include "sde::reflect"

   log_info "${C_CYAN}*${C_INFO} Reflect ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} (${PWD#${MULLE_USER_PWD}/})"
   sde::reflect::main

   return 0
}



sde::config::main()
{
   log_entry "sde::config::main" "$@"


   local flags

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::usage
         ;;

         --config-names|--config-scope)
            r_concat "${flags}" "$1"
            flags="${RVAL}"

            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            r_concat "${flags}" "$1"
            flags="${RVAL}"
         ;;

         -*)
            sde::config::usage "Unknown config option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ge 1 ] && shift

   case "${cmd:-name}" in
      name)
         sde::config::switch -p "$@"
      ;;

      list)
         sde::config::list "$@"
      ;;

      copy|remove)
         MULLE_USAGE_NAME="mulle-sde" \
         MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
            rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                              -N \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_SOURCETREE_FLAGS:-} \
                              ${flags} \
                           config "${cmd}" "$@" || exit 1
      ;;

      switch)
         sde::config::switch "$@"
      ;;

      show)
         sde::config::show "$@"
      ;;

      get)
         MULLE_USAGE_NAME="mulle-sde" \
         MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS:-} \
                        environment get "$@"  || exit 1
      ;;

      set)
         sde::config::switch --env-name "$@"
      ;;

      '')
         sde::config::usage
      ;;

      *)
         sde::config::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
