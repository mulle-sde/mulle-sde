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

   Manage project configurations. A project can have multiple sourcetree
   configurations for different backends (e.g. X11 vs. Wayland, GLFW vs. SDL).
   Do not use configs for different platforms or SDKs — use sourcetree marks.

   If this project is used as a dependency, the consumer can choose between
   available configurations with \`${MULLE_USAGE_NAME} config dependency set\`.

   Multi-config workflow:
      1. Create configs with \`${MULLE_USAGE_NAME} config copy <name>\`
      2. Set active configs: \`${MULLE_USAGE_NAME} config reflect-configs glfw:sdl\`
      3. Build all: \`${MULLE_USAGE_NAME} config craft\`
      4. Switch: \`${MULLE_USAGE_NAME} config set <name>\`
      5. Regular \`reflect\` and \`craft\` work on the active config

Commands:
   get              : print the current active configuration
   set <name>       : change the active configuration
   set <dep> <name> : change a dependency's configuration (clean fetch)
   list             : show project and dependency configs (--all default)
   craft            : reflect and craft all configurations
   dependency       : manage dependency configurations (list, get, set)
   show             : show available project configurations
   copy <name>      : copy a configuration
   remove <name>    : remove a configuration
   reflect-configs  : get/set the list of active build configurations

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
   ${MULLE_USAGE_NAME} config set [options] <name>
   ${MULLE_USAGE_NAME} config set <dependency> <name>

   Changes the active configuration. With a single argument, changes the
   project's own config. With two arguments, changes a dependency's config
   (shorthand for \`${MULLE_USAGE_NAME} config dependency set <dep> <name>\`).

   Changing a dependency config will also run \`clean fetch\` to invalidate
   the stash and kitchen.

Options:
   --this-host     : set in host scope (default)
   --this-os       : set in os scope
   --scope <name>  : set in named scope

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
   ${MULLE_USAGE_NAME} config list [options]

   List configurations. By default (--all) shows both the project's own
   configs and the dependency configs in two sections.

Options:
   --all          : show project and dependency configs (default)
   --project      : show only project configs
   --dependency   : show only dependency configs

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


sde::config::reflect_configs_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config reflect-configs [options] [config1:config2:...]

   Set the colon-separated list of sourcetree configs to reflect. Each config
   gets its own reflect.<name> output directory. Without an argument this
   prints the current value. When empty (default), legacy single-config
   behavior is used with no path rewriting.

   Example: ${MULLE_USAGE_NAME} config reflect-configs config:alt

Options:
   -p              : print current reflect configs
   --scope <scope> : set environment scope (default: --this-os)
   --host          : shorthand for --this-host
   --os            : shorthand for --this-os

EOF
   exit 1
}


sde::config::r_basename_identifier()
{
   include "case"

   r_basename "$1"
   r_smart_file_upcase_identifier "${RVAL}"
}


#
# this function is actually executed inside mulle-sourcetree so
# globals and other functions are not necessarily available.
#
sde::config::walk_config_name_callback()
{
   log_entry "sde::config::walk_config_name_callback" "$@"

   local config

   local identifier

   sde::config::r_basename_identifier "${NODE_FILENAME}"
   identifier="${RVAL}"
   r_concat "MULLE_SOURCETREE_CONFIG_NAME" "${identifier}" "_"
   r_shell_indirect_expand "${RVAL}"
   config="${RVAL:-config}"

   local address

   r_basename "${NODE_ADDRESS}"
   address="${RVAL}"

   printf "%s (%s): %s\n" "${address}" "MULLE_SOURCETREE_CONFIG_NAME_${identifier}" "${config}"
}


sde::config::walk_name_callback_no_default()
{
   log_entry "sde::config::walk_name_callback_no_default" "$@"

   local config
   local identifier

   sde::config::r_basename_identifier "${NODE_FILENAME}"
   identifier="${RVAL}"
   r_concat "MULLE_SOURCETREE_CONFIG_NAME" "${identifier}" "_"
   r_shell_indirect_expand "${RVAL}"
   config="${RVAL:-config}"

   if [ "${config}" != "config" ]
   then
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

   sde::config::r_basename_identifier "${NODE_FILENAME}"
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

      sde::config::r_basename_identifier "${NODE_FILENAME}"
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
                  --declare-function "`declare -f r_smart_file_upcase_identifier `" \
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

   sde::config::r_available_config_names "${MULLE_VIRTUAL_ROOT:-.}"
   names="${RVAL}"
   names="${names// /,}"
   names="${names%,}"
   names="${names:-config}"

   local current

   current="${MULLE_SOURCETREE_CONFIG_NAME:-config}"
   printf "MULLE_SOURCETREE_CONFIG_NAME=%s (available: %s)\n" "${current}" "${names}"

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

   local OPTION_SCOPE="all"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::list_usage
         ;;

         --all|-a)
            OPTION_SCOPE="all"
         ;;

         --project|-p)
            OPTION_SCOPE="project"
         ;;

         --dependency|--dependencies|-d)
            OPTION_SCOPE="dependency"
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
   include "case"

   sde::project::set_name_variables

   if [ "${OPTION_SCOPE}" = "all" -o "${OPTION_SCOPE}" = "project" ]
   then
      sde::config::list_project
   fi

   if [ "${OPTION_SCOPE}" = "all" -o "${OPTION_SCOPE}" = "dependency" ]
   then
      sde::config::list_dependencies
   fi
}


sde::config::list_project()
{
   local project_configs

   project_configs="${MULLE_SDE_REFLECT_CONFIGS}"
   if [ ! -z "${project_configs}" ]
   then
      log_info "Project configs:"
      printf "   %s = %s   (%s)\n" \
         "${PROJECT_NAME}" \
         "${MULLE_SOURCETREE_CONFIG_NAME:-config}" \
         "${project_configs//:/, }"
   else
      log_info "Project config:"
      printf "   %s = %s\n" "${PROJECT_NAME}" "${MULLE_SOURCETREE_CONFIG_NAME:-config}"
   fi
}


sde::config::list_dependencies()
{
   local stash_dir
   local dep_dir
   local dep_name
   local dep_identifier
   local dep_configs
   local current_value
   local env_var
   local found

   stash_dir="${MULLE_SOURCETREE_STASH_DIR}"
   if [ -z "${stash_dir}" ]
   then
      return 0
   fi

   if [ ! -d "${stash_dir}" ]
   then
      log_verbose "Stash dir \"${stash_dir}\" not found (not fetched yet?)"
      return 0
   fi

   found='NO'
   for dep_dir in "${stash_dir}"/*/
   do
      [ -d "${dep_dir}" ] || continue

      # only show deps with reflect-configs marker
      if [ ! -f "${dep_dir}.mulle/etc/sde/reflect-configs" ]
      then
         continue
      fi

      if [ "${found}" = 'NO' ]
      then
         log_info "Dependency configs:"
         found='YES'
      fi

      dep_name="${dep_dir%/}"
      dep_name="${dep_name##*/}"
      dep_configs="`cat "${dep_dir}.mulle/etc/sde/reflect-configs"`"

      # compute the identifier to look up the env var
      r_smart_file_upcase_identifier "${dep_name}"
      dep_identifier="${RVAL}"
      env_var="MULLE_SOURCETREE_CONFIG_NAME_${dep_identifier}"

      r_shell_indirect_expand "${env_var}"
      current_value="${RVAL}"

      if [ ! -z "${current_value}" ]
      then
         printf "   %s = %s   (%s)\n" \
            "${dep_name}" \
            "${current_value}" \
            "${dep_configs//:/, }"
      else
         printf "   %s = <not set>   (%s)\n" \
            "${dep_name}" \
            "${dep_configs//:/, }"
      fi
      log_verbose "${env_var}=${current_value}"
   done
}


sde::config::remove()
{
   log_entry "sde::config::remove" "$@"

   MULLE_USAGE_NAME="mulle-sde" \
   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
   MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
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
   MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
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

sde::config::r_available_config_names()
{
   local directory="$1"   # project root to check

   local etc_dir="${directory}/.mulle/etc/sourcetree"
   local share_dir="${directory}/.mulle/share/sourcetree"
   local names=""
   local file

   # etc takes precedence: if etc exists, only list from etc
   if [ -d "${etc_dir}" ]
   then
      for file in "${etc_dir}"/*
      do
         [ -f "${file}" ] || continue
         r_basename "${file}"
         r_concat "${names}" "${RVAL}" " "
         names="${RVAL}"
      done
   fi

   if [ -z "${names}" -a -d "${share_dir}" ]
   then
      for file in "${share_dir}"/*
      do
         [ -f "${file}" ] || continue
         r_basename "${file}"
         r_concat "${names}" "${RVAL}" " "
         names="${RVAL}"
      done
   fi

   RVAL="${names}"
}


sde::config::assert_valid_config_name()
{
   local name="$1"
   local directory="$2"
   local label="$3"   # e.g. "MulleUIOS" for error message

   # "config" means "remove switch / use default" - always valid
   [ "${name}" = "config" ] && return 0

   sde::config::r_available_config_names "${directory}"
   local available="${RVAL}"

   if [ -z "${available}" ]
   then
      log_warning "No sourcetree configs found in ${label:-${directory}} - cannot validate \"${name}\""
      return 0
   fi

   local n
   for n in ${available}
   do
      [ "${n}" = "${name}" ] && return 0
   done

   local pretty
   pretty="${available// /, }"
   fail "Config \"${name}\" does not exist in ${label:-${directory}}.
${C_INFO}Available configs: ${C_RESET_BOLD}${pretty}"
}


sde::config::switch_local()
{
   local name="$1"
   local args="$2"

   sde::config::assert_valid_config_name "${name}" "${MULLE_VIRTUAL_ROOT:-.}" "${PROJECT_NAME}"

   #
   # when we change the environment with mulle-env
   # it doesn't affect our local environment so we need to
   # also eval it
   #
   if [ "${name}" != "config" ]
   then
      log_info "${C_CYAN}*${C_INFO} Set ${C_RESET_BOLD}MULLE_SOURCETREE_CONFIG_NAME${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} to ${C_RESET_BOLD}${name}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment ${args} set "MULLE_SOURCETREE_CONFIG_NAME" "${name}"
      eval "MULLE_SOURCETREE_CONFIG_NAME='${name}'"
      export MULLE_SOURCETREE_CONFIG_NAME
   else
      log_info "${C_CYAN}*${C_INFO} Remove ${C_RESET_BOLD}MULLE_SOURCETREE_CONFIG_NAME${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment ${args} remove "MULLE_SOURCETREE_CONFIG_NAME"
      unset MULLE_SOURCETREE_CONFIG_NAME
   fi

   log_setting "MULLE_SOURCETREE_CONFIG_NAME : ${MULLE_SOURCETREE_CONFIG_NAME}"
}


sde::config::r_switch_dependency()
{
   log_entry "sde::config::r_switch_dependency" "$@"

   local dependency="$1"
   local args="$2"
   local name="$3"

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

   sde::config::assert_valid_config_name "${name}" "${dependency_dir}" "${dependency}"

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
         #
         # If the dependency has a reflect-configs marker, it already has
         # all configs reflected. No need to re-reflect on switch.
         #
         if [ -f "${dependency_dir}/.mulle/etc/sde/reflect-configs" ]
         then
            log_verbose "Dependency \"${OPTION_DEPENDENCY}\" has multi-config reflection, skip re-reflect"
         else
            # goto dependency_dir and switch there (which will reflect). Then the
            # "config name" for the dependency project reflects the state properly
            (
               log_info "${C_CYAN}*${C_INFO} Switch dependency in ${C_MAGENTA}${C_BOLD}${OPTION_DEPENDENCY}${C_INFO} (${dependency_dir#"${MULLE_USER_PWD}/"})"

               exekutor cd "${dependency_dir}" || return 1
               MULLE_VIRTUAL_ROOT=
               MULLE_VIRTUAL_ROOT_ID=
               rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                                   ${MULLE_SDE_FLAGS} \
                                   config switch ${args} "${name}"
            ) || fail "failed because $?"
         fi
      fi
   fi

   local varname

   include "case"

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
      MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment ${args} set "${varname}" "${name}"
      eval "${varname}='${name}'"
      eval "export ${varname}"
   else
      log_info "${C_CYAN}*${C_INFO} Remove ${C_RESET_BOLD}${varname}${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO}"

      MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment ${args} remove "${varname}"
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

   include "case"

   r_smart_file_upcase_identifier "${dependency}"
   r_concat "MULLE_SOURCETREE_CONFIG_NAME" "${RVAL}" "_"
   varname="${RVAL}"

   ##
   ## GET
   ##

   local value

   value="`MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
           MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
            rexekutor "${MULLE_ENV:-mulle-env}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS:-} \
                     environment get "${varname}" `"

   printf "%s\n" "${value:-config}"
   return 0
}


sde::config::cleanup_reflect_directories_for_configs()
{
   log_entry "sde::config::cleanup_reflect_directories_for_configs" "$@"

   local configs="$1"
   local directory

   if [ -z "${configs}" ]
   then
      # switching to empty (legacy): remove all reflect.* dirs
      for directory in cmake/reflect.* src/reflect.*
      do
         [ -d "${directory}" ] || continue
         log_info "${C_CYAN}*${C_INFO} Remove stale ${C_RESET_BOLD}${directory}${C_INFO}"
         rmdir_safer "${directory}"
      done
   else
      # switching to multi: remove plain reflect dirs
      for directory in cmake/reflect src/reflect
      do
         [ -d "${directory}" ] || continue
         log_info "${C_CYAN}*${C_INFO} Remove stale ${C_RESET_BOLD}${directory}${C_INFO}"
         rmdir_safer "${directory}"
      done
   fi
}


sde::config::reflect_configs()
{
   log_entry "sde::config::reflect_configs" "$@"

   local OPTION_PRINT='NO'
   local OPTION_ENV_SCOPE_ARGS="--this-os"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::reflect_configs_usage
         ;;

         -p|--print)
            OPTION_PRINT='YES'
         ;;

         --scope)
            [ $# -eq 1 ] && sde::config::reflect_configs_usage "Missing argument to \"$1\""
            shift
            OPTION_ENV_SCOPE_ARGS="--scope $1"
         ;;

         --host|--this-host)
            OPTION_ENV_SCOPE_ARGS="--this-host"
         ;;

         --os|--this-os)
            OPTION_ENV_SCOPE_ARGS="--this-os"
         ;;

         -*)
            sde::config::reflect_configs_usage "Unknown config reflect-configs option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local configs

   if [ "${OPTION_PRINT}" = 'YES' -o "$#" -eq 0 ]
   then
      [ "$#" -ne 0 ] && sde::config::reflect_configs_usage "Superflous arguments $*"

      configs="`MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
              MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
              rexekutor "${MULLE_ENV:-mulle-env}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS:-} \
                     environment get MULLE_SDE_REFLECT_CONFIGS`"
      printf "%s\n" "${configs}"
      return 0
   fi

   configs="$1"
   shift
   [ "$#" -ne 0 ] && sde::config::reflect_configs_usage "Superflous arguments $*"

   log_info "${C_CYAN}*${C_INFO} Set ${C_RESET_BOLD}MULLE_SDE_REFLECT_CONFIGS${C_INFO} in ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} to ${C_RESET_BOLD}${configs:-<empty>}${C_INFO}"
   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
   MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
      rexekutor "${MULLE_ENV:-mulle-env}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS} \
                     environment ${OPTION_ENV_SCOPE_ARGS} set MULLE_SDE_REFLECT_CONFIGS "${configs}"
   MULLE_SDE_REFLECT_CONFIGS="${configs}"
   export MULLE_SDE_REFLECT_CONFIGS

   #
   # Write/remove marker file so dependencies can be detected as multi-config
   # without needing to enter their mulle-sde environment
   #
   local markerfile

   markerfile=".mulle/etc/sde/reflect-configs"
   if [ ! -z "${configs}" ]
   then
      mkdir_if_missing "${markerfile%/*}"
      redirect_exekutor "${markerfile}" printf "%s\n" "${configs}"
   else
      remove_file_if_present "${markerfile}"
   fi

   sde::config::cleanup_reflect_directories_for_configs "${configs}"
}


sde::config::craft_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config craft [options]

   Reflect and craft all configurations listed in MULLE_SDE_REFLECT_CONFIGS.
   This iterates over each config, sets MULLE_SOURCETREE_CONFIG_NAME, and
   runs reflect + craft for each. Use this to populate all reflect.<config>
   directories initially, so that switching configs later is instantaneous.

Options:
   -f            : force craft (passed to mulle-sde craft)

EOF
   exit 1
}


sde::config::craft()
{
   log_entry "sde::config::craft" "$@"

   local OPTION_FORCE

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::craft_usage
         ;;

         -f|--force)
            OPTION_FORCE="-f"
         ;;

         -*)
            sde::config::craft_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local configs

   configs="${MULLE_SDE_REFLECT_CONFIGS}"
   if [ -z "${configs}" ]
   then
      fail "MULLE_SDE_REFLECT_CONFIGS is not set. Use \`mulle-sde config reflect-configs\` to set it."
   fi

   local config_name
   local rval

   rval=0
   IFS=':'
   for config_name in ${configs}
   do
      IFS="${DEFAULT_IFS}"

      [ -z "${config_name}" ] && continue

      log_info "Crafting config ${C_RESET_BOLD}${config_name}"

      MULLE_SOURCETREE_CONFIG_NAME="${config_name}" \
         rexekutor mulle-sde ${OPTION_FORCE} ${MULLE_TECHNICAL_FLAGS} \
            -DMULLE_SOURCETREE_CONFIG_NAME="${config_name}" \
            craft "$@"
      rval=$?

      if [ $rval -ne 0 ]
      then
         log_error "Craft failed for config \"${config_name}\""
         break
      fi
   done
   IFS="${DEFAULT_IFS}"

   return $rval
}


sde::config::switch()
{
   log_entry "sde::config::switch" "$@"

   local OPTION_PRINT='NO'
   local OPTION_DEPENDENCY
   local OPTION_ENV_SCOPE_ARGS="--this-os"

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

         -d|--dependency)
            [ $# -eq 1 ] && sde::craft::switch_usage "Missing argument to \"$1\""
            shift

            OPTION_DEPENDENCY="$1"
         ;;

         -p|--print)
            OPTION_PRINT='YES'
         ;;

         --scope)
            [ $# -eq 1 ] && sde::craft::switch_usage "Missing argument to \"$1\""
            shift

            OPTION_ENV_SCOPE_ARGS="--scope $1"
         ;;

         --host|--this-host)
            OPTION_ENV_SCOPE_ARGS="--this-host"
         ;;

         --os|--this-os)
            OPTION_ENV_SCOPE_ARGS="--this-os"
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
      sde::config::r_switch_dependency "${OPTION_DEPENDENCY}" \
                                       "${OPTION_ENV_SCOPE_ARGS}" \
                                       "${name}"
      dependency_dir="${RVAL}"
   else
      sde::config::switch_local "${name}" \
                                "${OPTION_ENV_SCOPE_ARGS}"
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


sde::config::dependency_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config dependency [command]

   Manage configurations of dependencies.

Commands:
   list                    : list multi-config dependencies and their settings
   get <dependency>        : get the current config of a dependency
   set <dependency> <name> : set the config of a dependency

EOF
   exit 1
}


sde::config::dependency_list()
{
   log_entry "sde::config::dependency_list" "$@"

   include "sde::project"
   include "case"

   sde::project::set_name_variables

   sde::config::list_dependencies
}


sde::config::dependency_get()
{
   log_entry "sde::config::dependency_get" "$@"

   local dependency="$1"

   [ -z "${dependency}" ] && sde::config::dependency_usage "Missing dependency name"

   include "case"

   r_smart_file_upcase_identifier "${dependency}"
   local env_var="MULLE_SOURCETREE_CONFIG_NAME_${RVAL}"

   r_shell_indirect_expand "${env_var}"
   if [ ! -z "${RVAL}" ]
   then
      printf "%s\n" "${RVAL}"
   else
      printf "%s\n" "config"
   fi
}


sde::config::dependency_set()
{
   log_entry "sde::config::dependency_set" "$@"

   local OPTION_ENV_SCOPE_ARGS="--this-host"

   while :
   do
      case "$1" in
         --scope)
            shift
            OPTION_ENV_SCOPE_ARGS="--scope $1"
            shift
         ;;

         --this-host|--this-os|--global)
            OPTION_ENV_SCOPE_ARGS="$1"
            shift
         ;;

         *)
            break
         ;;
      esac
   done

   local dependency="$1"
   local name="$2"

   [ -z "${dependency}" ] && sde::config::dependency_usage "Missing dependency name"
   [ -z "${name}" ] && sde::config::dependency_usage "Missing config name"

   include "case"

   r_smart_file_upcase_identifier "${dependency}"
   local env_var="MULLE_SOURCETREE_CONFIG_NAME_${RVAL}"

   log_info "Set ${C_RESET_BOLD}${env_var}${C_INFO} to ${C_RESET_BOLD}${name}${C_INFO} for dependency ${C_MAGENTA}${C_BOLD}${dependency}"

   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
   MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID}" \
      rexekutor "${MULLE_ENV:-mulle-env}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS:-} \
                     environment ${OPTION_ENV_SCOPE_ARGS} set "${env_var}" "${name}"

   #
   # Changing a dependency config invalidates the stash (different transitive
   # deps) and the kitchen (built against old config). Clean fetch handles both.
   #
   include "sde::clean"

   log_info "Clean fetch to pick up new dependency configuration"
   sde::clean::main "fetch"
}


sde::config::dependency()
{
   log_entry "sde::config::dependency" "$@"

   local cmd="$1"

   [ $# -ge 1 ] && shift

   case "${cmd}" in
      -h*|--help|help)
         sde::config::dependency_usage
      ;;

      list)
         sde::config::dependency_list "$@"
      ;;

      get)
         sde::config::dependency_get "$@"
      ;;

      set)
         sde::config::dependency_set "$@"
      ;;

      '')
         sde::config::dependency_usage
      ;;

      *)
         sde::config::dependency_usage "Unknown dependency command \"${cmd}\""
      ;;
   esac
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

   case "${cmd:-get}" in
      copy|craft|dependency|remove|list|show)
         sde::config::${cmd} "$@"
      ;;

      reflect-mode|reflect-configs)
         sde::config::reflect_configs "$@"
      ;;

      name|get)
         sde::config::print "$@"
      ;;

      set|switch)
         #
         # If two positional args given, treat as dependency set shorthand:
         #    config set <dep> <name>  ->  config dependency set <dep> <name>
         # If one arg, treat as project config set:
         #    config set <name>        ->  config switch <name>
         #
         if [ $# -ge 2 ] && [ "${1:0:1}" != "-" ] && [ "${2:0:1}" != "-" ]
         then
            sde::config::dependency_set "$@"
         else
            sde::config::switch "$@"
         fi
      ;;

      '')
         sde::config::usage
      ;;

      *)
         sde::config::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
