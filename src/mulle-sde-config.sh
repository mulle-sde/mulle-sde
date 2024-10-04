# shellcheck shell=bash
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
MULLE_SDE_CONFIG_SH='included'


sde::config::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config [options] [command]

   This command manipulates the configuration of a project. Usually
   your project only has one configuration named "config". But sometimes it can
   be useful to have multiple configurations. A case for a separate config
   is a differnent backend like X11 vs. Wayland. Do not use a separate config
   for different platforms (linux, windows) or SDKs (glibc, musl). Use
   sourcetree "marks" instead.

   If the project is used as a dependency of another project, that project can
   also choose between the sourcetree configurations.

Commands:
   copy   : copy a configuration
   list   : list currently active configurations
   name   : get name of current configuration
   switch : change to a different configuration
   remove : remove a configuration
   show   : show available configurations

EOF
   exit 1
}


sde::config::name_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config name [options]

   List the currently active configuration name. You can also see
   the available configuration names.

Options:
   -a   : list all sourcetree config names

EOF
   exit 1
}


sde::config::switch_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config switch [options] <name>

   Changes the configuration for the current project or for a dependency. To
   change the configuration of a dependency use the -d option. The actual
   change is perfomed by setting a global environment variable
   MULLE_SOURCETREE_CONFIG_NAME_<identifier>. To figure out the proper
   identifier for a given project, use the "mulle-sde env-identifier" command.

   It is necessary to "clean tidy" and "reflect" the project after the
   change.

Options:
   -d <dependency> : change configuration of a dependency instead
   -p              : print current configuration name

EOF
   exit 1
}


sde::config::copy_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config copy [options] [src] <destination>

   Copy a configuration of the current project to a new configuration
   <destination>. This will create a new sourcetree config file named
   <destination> and a new definition.<destination> to store build variables.

   It is necessary to "clean tidy" and "reflect" the project after the change.

EOF
   exit 1
}



sde::config::list_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config list

   List the currently active configuration overrides. There will always be a
   line for the current project, though there may not be an actual environment
   entry.

EOF
   exit 1
}


sde::config::show_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config show

   Show the currently available configuration names.

EOF
   exit 1
}


#
# this function is actually executed inside mulle-sourcetree so
# globals and other functions are not necessarily available.
#
sde::config::walk_config_name_callback()
{
   log_entry "sde::config::walk_config_name_callback" "$@"

   local reflectfile
   local config

   reflectfile=".mulle/etc/sde/reflect"
   if [ -f "${reflectfile}" ]
   then
      config="`grep -E -v '^#' "${reflectfile}" `"
   fi
   config="${config:-config}"

   local identifier

   r_basename "${NODE_FILENAME}"
   r_smart_file_upcase_identifier "${RVAL}"
   identifier="${RVAL}"

   local address

   r_basename "${NODE_ADDRESS}"
   address="${RVAL}"

   printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAME_${identifier}" "${config}"
}


sde::config::walk_name_callback_no_default()
{
   log_entry "sde::config::walk_name_callback_no_default" "$@"

   local reflectfile
   local config

   reflectfile=".mulle/etc/sde/reflect"
   config="`grep -E -v '^#' "${reflectfile}" 2>/dev/null`"
   config="${config:-config}"

   if [ "${config}" != "config" ]
   then
      local identifier

      r_basename "${NODE_FILENAME}"
      r_smart_file_upcase_identifier "${RVAL}"
      identifier="${RVAL}"

      local address

      r_basename "${NODE_ADDRESS}"
      address="${RVAL}"

      printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAME_${identifier}" "${config}"
   fi
}


sde::config::walk_callback()
{
   log_entry "sde::config::walk_callback" "$@"

   include "sourcetree::config"

   local names

   names="`(
      eval $(mulle-env --search-here mulle-tool-env sourcetree) ;
      log_setting "MULLE_SOURCETREE_ETC_DIR   : ${MULLE_SOURCETREE_ETC_DIR}"
      log_setting "MULLE_SOURCETREE_SHARE_DIR : ${MULLE_SOURCETREE_SHARE_DIR}"
      sourcetree::config::list_main --no-warn --name-only --separator ','
      )`"

   local identifier

   r_basename "${NODE_FILENAME}"
   r_smart_file_upcase_identifier "${RVAL}"
   identifier="${RVAL}"

   local address

   r_basename "${NODE_ADDRESS}"
   address="${RVAL}"

   printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAME_${identifier}" "${names}"
}


sde::config::walk_callback_no_default()
{
   log_entry "sde::config::walk_callback_no_default" "$@"

   include "sourcetree::config"

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
      r_smart_file_upcase_identifier "${RVAL}"
      identifier="${RVAL}"

      local address

      r_basename "${NODE_ADDRESS}"
      address="${RVAL}"

      printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAME_${identifier}" "${names}"
   fi
}


sde::config::dependency_walk()
{
   log_entry "sde::config::dependency_walk" "$@"

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


   [ -z "${MULLE_ENV_ETC_DIR}" ] && _internal_fail "MULLE_ENV_ETC_DIR is not set"

   #
   # project configs
   #
   local names

   if [ -f "${MULLE_ENV_ETC_DIR}/environment-global.sh" ]
   then
      names="default"
   fi

   local filename

   shell_enable_nullglob
   for filename in ${MULLE_ENV_ETC_DIR}/*/environment-global.sh
   do
      r_dirname "${filename}"
      r_basename "${RVAL}"
      r_comma_concat "${names}" "${RVAL}"
      names="${RVAL}"
   done
   shell_disable_nullglob

   printf "%s (%s): %s\n" "${PROJECT_NAME}" "MULLE_SOURCETREE_CONFIG_NAME" "${names}"

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
                        environment \
                           list --output-eval  \
   | grep -E '^MULLE_SOURCETREE_CONFIG_NAME[^=]*=' \
   | sort `"

   if [ -z "${MULLE_SOURCETREE_CONFIG_NAME}" ]
   then
      r_add_line "MULLE_SOURCETREE_CONFIG_NAME=config" "${result}"
      result="${RVAL}"
   else
      r_add_line "MULLE_SOURCETREE_CONFIG_NAME=${MULLE_SOURCETREE_CONFIG_NAME}" "${result}"
      result="${RVAL}"
   fi

   printf "%s\n" "${result}"
}


sde::config::remove()
{
   log_entry "sde::config::remove" "$@"

   MULLE_USAGE_NAME="mulle-sde" \
   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS:-} \
                        ${flags} \
                     config remove "$@" || exit 1


   local name

   #
   # memo: newer zsh support this bashism and we don't care about older zsh
   #       we just care about older bash :)
   #
   name="${@: -1}" ; shift
   case "${name}" in
      [cC][oO][nN][fF][iI][gG]|[dD][eE][fF][aA][uU][lL][tT])
         name=""
      ;;
   esac

   [ -z "${MULLE_ENV_ETC_DIR}" ] && _internal_fail "MULLE_ENV_ETC_DIR is not set"

   from="${MULLE_ENV_ETC_DIR}/${name}"

   rmdir_safer "${from}"
}


sde::config::copy()
{
   log_entry "sde::config::copy" "$@"

   # let sourcetree do error handling

   MULLE_USAGE_NAME="mulle-sde" \
   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS:-} \
                        ${flags} \
                     config copy "$@" || exit 1


#   local name
#
#   #
#   # memo: newer zsh support this bashism and we don't care about older zsh
#   #       we just care about older bash :)
#   #
#   name="${@: -1}" ; shift
#   case "${name}" in
#      [cC][oO][nN][fF][iI][gG]|[dD][eE][fF][aA][uU][lL][tT])
#         name=""
#      ;;
#   esac
#
#   local from
#   local to
#
#   [ -z "${MULLE_ENV_ETC_DIR}" ] && _internal_fail "MULLE_ENV_ETC_DIR is not set"
#
#   from="${MULLE_ENV_ETC_DIR}/${PROJECT_CONFIG}"
#   to="${MULLE_ENV_ETC_DIR}/${name}"
#
#   mkdir_if_missing "${to}"
#
#   ( exekutor cd "${from}" ; exekutor tar cf - environment-*.sh ) \
#   | ( exekutor cd "${to}" ; exekutor tar xf - )
}

sde::config::switch_local()
{
   local name="$1"

   #
   # when we change the environment with mulle-env
   # it doesn't affect our local environment so we need to
   # also eval it
   #
   if [ "${name}" != "config" ]
   then
      log_info "${C_CYAN}*${C_INFO} Set ${C_RESET_BOLD}MULLE_SOURCETREE_CONFIG_NAME${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} to ${C_RESET_BOLD}${name}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment --this-host set "MULLE_SOURCETREE_CONFIG_NAME" "${name}"
      eval "MULLE_SOURCETREE_CONFIG_NAME='${name}'"
      export MULLE_SOURCETREE_CONFIG_NAME
   else
      log_info "${C_CYAN}*${C_INFO} Remove ${C_RESET_BOLD}MULLE_SOURCETREE_CONFIG_NAME${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment --this-host remove "MULLE_SOURCETREE_CONFIG_NAME"
      unset MULLE_SOURCETREE_CONFIG_NAME
   fi

   log_setting "MULLE_SOURCETREE_CONFIG_NAME : ${MULLE_SOURCETREE_CONFIG_NAME}"
}


sde::config::r_switch_dependency()
{
   log_entry "sde::config::r_switch_dependency" "$@"

   local dependency="$1"
   local name="$2"

   [ "${dependency}" = "${PROJECT_NAME}" ] && fail "Dependency is the actual project. Omit -d <dependency> from command"

   local dependency_dir

   # get the destination folder for the dependency
   # check if its a symlink, if yes warn/bail
   include "sde::dependency"

   dependency_dir="`sde::dependency::source_dir_main "${dependency}" `" || return 1
   if [ ! -e "${dependency_dir}" ]
   then
      fail "Dependency \"${dependency}\" hasn't been fetched yet"
   fi

   if [ -L "${dependency_dir}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         log_warning "${dependency_dir#"${MULLE_USER_PWD}/"} is a symlink. Only changing the environment variable!"
      else
         fail "${dependency_dir#"${MULLE_USER_PWD}/"} is a symlink. The change could affect other projects.
${C_INFO}Use -f to force the switch"
      fi
   else
      #
      # need to reflect before clean tidy for the dependency
      #
      if [ ! -z "${dependency_dir}" ]
      then
         # goto dependency_dir and switch there (which will reflect). Then the
         # "config name" for the dependency project reflects the state properly
         (
            log_info "${C_CYAN}*${C_INFO} Switch dependency in ${C_MAGENTA}${C_BOLD}${OPTION_DEPENDENCY}${C_INFO} (${dependency_dir#"${MULLE_USER_PWD}/"})"

            exekutor cd "${dependency_dir}" || return 1
            MULLE_VIRTUAL_ROOT=
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                                ${MULLE_SDE_FLAGS} \
                                config switch "${name}"
         ) || fail "failed because $?"
      fi
   fi

   local varname

   r_smart_file_upcase_identifier "${dependency}"
   r_concat "MULLE_SOURCETREE_CONFIG_NAME" "${RVAL}" "_"
   varname="${RVAL}"

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
                        environment --this-host set "${varname}" "${name}"
      eval "${varname}='${name}'"
      eval "export ${varname}"
   else
      log_info "${C_CYAN}*${C_INFO} Remove ${C_RESET_BOLD}${varname}${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment --this-host remove "${varname}"
      eval unset "${varname}"
   fi

   r_shell_indirect_expand "${varname}"
   log_setting "${varname} : ${RVAL}"
}


sde::config::print()
{
   log_entry "sde::config::print" "$@"

   local dependency="$1"

   local varname

   r_smart_file_upcase_identifier "${dependency}"
   r_concat "MULLE_SOURCETREE_CONFIG_NAME" "${RVAL}" "_"
   varname="${RVAL}"

   ##
   ## GET
   ##

   local value

   value="`MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
            rexekutor "${MULLE_ENV:-mulle-env}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS:-} \
                     environment get "${varname}" `"

   printf "%s\n" "${value:-config}"
   return 0
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
            OPTION_PRINT='YES'
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

   include "case"

   if [ "${OPTION_PRINT}" = 'YES' ]
   then
      [ "$#" -ne 0 ] && sde::config::switch_usage "Superflous arguments $*"

      sde::config::print "${OPTION_DEPENDENCY}"
      return $?
   fi

   local name

   [ "$#" -eq 0 ] && sde::config::switch_usage "Missing config name"

   name="$1"
   shift

   [ "$#" -ne 0 ] && sde::config::switch_usage "Superflous arguments $*"

   case "${name}" in
      [dD][eE][fF][aA][uU][lL][tT])
         name="config"
      ;;
   esac

   local dependency_dir

   if [ ! -z "${OPTION_DEPENDENCY}" ]
   then
      sde::config::r_switch_dependency "${OPTION_DEPENDENCY}" "${name}"
      dependency_dir="${RVAL}"
   else
      sde::config::switch_local "${name}"
   fi

   #
   # need to get rid of old stuff in share
   #
   include "sde::clean"

   log_info "${C_CYAN}*${C_INFO} Clean tidy ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} (${PWD#"${MULLE_USER_PWD}/"})"

   sde::clean::main "tidy"

   #
   # need to refetch stuff into share
   #

   include "sde::fetch"

   log_info "${C_CYAN}*${C_INFO} Fetch ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} (${PWD#"${MULLE_USER_PWD}/"})"

   sde::fetch::main || return 1

   if [ ! -z "${dependency_dir}" ]
   then
      return 0
   fi

   include "sde::reflect"

   log_info "${C_CYAN}*${C_INFO} Reflect ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} (${PWD#"${MULLE_USER_PWD}/"})"
   sde::reflect::main
   [ $? -eq 1 ] && return 1

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

         --config-name|--config-scope|--config-scopes)
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

   # sanity check
   case "${MULLE_SOURCETREE_CONFIG_NAME}" in
      [dD][eE][fF][aA][uU][lL][tT]|[cC][oO][nN][fF][iI][gG])
         fail "MULLE_SOURCETREE_CONFIG_NAME should not be \"config\" or \"default\", just unset it"
      ;;
   esac

   eval `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env env` || exit 1

   local cmd="$1"

   [ $# -ge 1 ] && shift

   case "${cmd:-name}" in
      get)
         MULLE_USAGE_NAME="mulle-sde" \
         MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS:-} \
                        environment get "$@"  || exit 1
      ;;

      copy|remove|list|show|switch)
         sde::config::${cmd} "$@"
      ;;

      name)
         sde::config::switch -p "$@"
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
