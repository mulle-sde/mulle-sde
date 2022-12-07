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
MULLE_SDE_SUBPROJECT_SH="included"


SUBPROJECT_MARKS="dependency,no-mainproject,no-update,no-delete,no-share"

SUBPROJECT_LIST_MARKS="dependency,no-mainproject,no-delete"
SUBPROJECT_LIST_NODETYPES="local"


sde::subproject::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject [options] [command]

   A subproject is a part of your mulle-sde project. A subproject is contained
   in a subdirectory and has its own environment. It is functionally very
   similiar to a dependency but it can not be build on its own.

   The subproject feature is ** EXPERIMENTAL ** and in constant flux.

   Subprojects will create and clobber an existing user (!) 30-subproject--none
   ignore patternfile.

Options:
   -h              : show this usage
   -s <subproject> : choose subproject to run command in

Commands:
   add             : add an existing subproject
   enter           : open a subshell for subproject
   init            : create a subproject
   remove          : remove a subproject
   move            : change craftorder of subproject
   list            : list subprojects (default)
         (use <command> -h for more help about commands)
EOF
   exit 1
}


sde::subproject::add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject add <name>

   Add a subproject to your project. The name of the subproject
   is its relative file path.

   Example:
      ${MULLE_USAGE_NAME} subproject add subproject/mylib
EOF
  exit 1
}



sde::subproject::move_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject move <name> <up|down|top|bottom>

   Change the buildorde for this subproject. Top builds first. Bottom builds
   last. The name of the subproject is its relative file path.

   Example:
      ${MULLE_USAGE_NAME} subproject move subproject/mylib down
EOF
  exit 1
}


sde::subproject::set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject set [options] <name> <key> <value>

   Modify a subproject settings, which is referenced by its name.

   Examples:
      ${MULLE_USAGE_NAME} subproject set src/mylib platform-excludes darwin

Options:
   --append          : append value instead of set

Keys:
   platform-excludes : names of platforms to exclude, separated by comma
   aliases           : alternative names
EOF
  exit 1
}


sde::subproject::get_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject get <name> <key>

   Retrieve subproject settings by its name.

   Examples:
      ${MULLE_USAGE_NAME} subproject get subproject/mylib platform-excludes

Keys:
   platform-excludes : names of platform to exclude, separated by comma
EOF
  exit 1
}


sde::subproject::init_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject init [options] <arguments>

   ** BEWARE: SUBPROJECTS ARE HARD TO CONFIGURE CORRECTLY **

   Initialize a subproject for mulle-sde and add it to the list of
   subprojects. Arguments are passed to \`mulle-sde init\`.

   By default the subproject inherits the extensions and the environment
   style from the main project.

   Example:
      ${MULLE_USAGE_NAME} subproject init -d src/Base library

Options:
   --existing : project already exists, don't clobber
   -d <dir>   : subproject directory to use (required)
   -m <meta>  : meta extension to use
   -s <style> : style to use
EOF
  exit 1
}


sde::subproject::set_main()
{
   log_entry "sde::subproject::set_main" "$@"

   local OPTION_APPEND='NO'

   while :
   do
      case "$1" in
         -a|--append)
            OPTION_APPEND='YES'
         ;;

         -*)
            log_error "Unknown option \"$1\""
            sde::subproject::set_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde::subproject::set_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde::subproject::set_usage
   shift

   local value="$1"

   case "${field}" in
      platform-excludes)
         sde::common::_set_platform_excludes "${address}" \
                                             "${value}" \
                                             "${SUBPROJECT_MARKS}" \
                                             "${OPTION_APPEND}"
      ;;

      aliases|include)
         sde::common::_set_userinfo_field "${address}" \
                                          "${field}" \
                                          "${value}" \
                                          "${OPTION_APPEND}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde::subproject::set_usage
      ;;
   esac
}


sde::subproject::get_main()
{
   log_entry "sde::subproject::get_main" "$@"

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde::subproject::get_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde::subproject::get_usage
   shift

   case "${field}" in
      platform-excludes)
         sde::common::get_platform_excludes "${address}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde::subproject::get_usage
      ;;
   esac
}


sde::subproject::emit_ignore_patternfile()
{
   local subprojects="$1"

   local subproject

   .foreachline subproject in ${subprojects}
   .do
      printf "%s\n" "${subproject}/"
   .done
}


sde::subproject::update_ignore_patternfile()
{
   log_entry "sde::subproject::update_ignore_patternfile" "$@"

   local subprojects
   local contents

   subprojects="`sde::subproject::get_addresses`" || exit 1

   contents="`sde::subproject::emit_ignore_patternfile "${subprojects}"`" || exit 1

   # TODO: would be better to massage a env variable, so we don't
   # disturb user space
   exekutor "${MULLE_MATCH:-mulle-match}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_MATCH_FLAGS} \
               patternfile add -i \
                               -p 30 \
                               -c none \
                               subproject - <<< "${contents}"
}


sde::subproject::init_main()
{
   log_entry "sde::subproject::init_main" "$@"

   local directory
   local meta
   local style

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::subproject::init_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde::subproject::init_usage "Missing option to \"$1\""
            shift

            directory="$1"
         ;;

         -m|--meta)
            [ $# -eq 1 ] && sde::subproject::init_usage "Missing option to \"$1\""
            shift

            meta="$1"
         ;;

         -s|--style)
            [ $# -eq 1 ] && sde::subproject::init_usage "Missing option to \"$1\""
            shift

            style="$1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${directory}" ] && sde::subproject::init_usage "directory is empty"

   if [ -d "${directory}/.mulle/share/sde" ]
   then
      fail "\"${directory}\" is already present and initialized"
   fi

   [ -z "${MULLE_PATH_SH}" ] && . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   [ -z "${MULLE_FILE_SH}" ] && . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

   mkdir_if_missing "${directory}"

   if [ -z "${meta}" ]
   then
      include "sde::extension"

      meta="`sde::extension::main meta`"
      if [ -z "${meta}" ]
      then
         fail "Unknown installed meta extension. Specify it yourself"
      fi
   fi

   if [ -z "${style}" ]
   then
      style="`rexekutor "${MULLE_ENV:-mulle-env}" style`"
   fi

   # get this error early
   sde::subproject::main "add" "${directory}" || exit 1

   (
      # shellcheck source=src/mulle-sde-init.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

      #
      # pass some information to init scripts via environment
      #
      PARENT_PROJECT_DIALECT="${PROJECT_DIALECT}" \
      PARENT_PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS}" \
      PARENT_PROJECT_LANGUAGE="${PROJECT_LANGUAGE}" \
      PARENT_PROJECT_NAME="${PROJECT_NAME}" \
      PARENT_PROJECT_TYPE="${PROJECT_TYPE}" \
      PARENT_DIR="${MULLE_VIRTUAL_ROOT}" \
      MULLE_VIRTUAL_ROOT="" \
         eval_exekutor sde::init::main -d "${directory}" \
                                       -m "${meta}" \
                                       ${flags} \
                                       --style "${style}" \
                                       --subproject \
                                       --no-post-init \
                                       --no-motd \
                                       --no-blurb \
                                       -f \
                                       --project-source-dir "." \
                                       "$@"
   )

   if [ $? -ne 0 ]
   then
      (
         sde::subproject::main "remove" "${directory}" > /dev/null 2>&1
      )
      exit 1
   fi
}


sde::subproject::list()
{
   log_entry "sde::subproject::list" "$@"

   include "sde::common"

   sde::common::rexekutor_sourcetree_nofail list \
     --marks "${SUBPROJECT_LIST_MARKS}" \
      --nodetypes "${SUBPROJECT_LIST_NODETYPES}" \
      --output-no-url \
      --output-no-marks "${SUBPROJECT_MARKS}" \
      --format '%a;%m;%i={aliases,,-------};%i={include,,-------}\n' \
      "$@"
}


sde::subproject::get_addresses()
{
   log_entry "sde::subproject::get_addresses" "$@"

   include "sde::common"

   sde::common::rexekutor_sourcetree_nofail list \
        --marks "${SUBPROJECT_LIST_MARKS}" \
        --nodetypes "${SUBPROJECT_LIST_NODETYPES}" \
        --no-output-header \
        --output-format raw \
        --format '%a\n'
}


sde::subproject::map()
{
   log_entry "sde::subproject::map" "$@"

   local verb="${1:-Reflecting}" ; shift
   local mode="$1" ; shift

   local lenient='NO'
   local parallel='NO'
   local env='YES'

   case ",${mode}," in
      *,lenient,*)
         lenient='YES';
      ;;
   esac

   case ",${mode}," in
      *,parallel,*)
         parallel='YES';
      ;;
   esac

   case ",${mode}," in
      *,no-env,*)
         env='NO';
      ;;
   esac


   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "MULLE_VIRTUAL_ROOT undefined"
   [ -z "${MULLE_SDE_VAR_DIR}" ]  && _internal_fail "MULLE_SDE_VAR_DIR undefined"

   local subprojects

   [ $# -eq 0 ] && _internal_fail "missing commandline"

   subprojects="`sde::subproject::get_addresses`"  || exit 1
   if [ -z "${subprojects}" ]
   then
      log_fluff "No subprojects, so done"
      return
   fi

   local statusfile

   if [ "${parallel}" = 'YES' ]
   then
      if [ "${lenient}" = "YES" ]
      then
         _internal_fail "Can't have parallel and lenient together"
      fi

      [ -z "${MULLE_PATH_SH}" ] && . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
      [ -z "${MULLE_FILE_SH}" ] && . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

      _r_make_tmp_in_dir "${MULLE_SDE_VAR_DIR}" "up-sub" || exit 1
      statusfile="${RVAL}"
   fi

   (
      local command

      command="$*"

      local rval
      local subproject

      rval=0

      local expanded_subproject
      local sdefolder

      .foreachline subproject in ${subprojects}
      .do
         r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${subproject}"
         expanded_subproject="${RVAL}"

         sdefolder="${expanded_subproject}/.mulle/share/sde"
         if [ ! -d "${sdefolder}" ]
         then
            _log_fluff "${verb} subproject \"${subproject}\" skipped, as it \
has no \"${sdefolder}\" folder"
            .continue
         fi

         log_verbose "${verb} subproject ${C_MAGENTA}${C_BOLD}${subproject} (parallel:$parallel env:$env)"

         if [ "${parallel}" = 'YES' ]
         then
            (
               if [ "${env}" = 'YES' ]
               then
                  exekutor mulle-env -c "${command}" subenv "${expanded_subproject}"
                  rval=$?
                  exit 0
               else
                  (
                     rexekutor cd "${expanded_subproject}" &&
                     MULLE_VIRTUAL_ROOT="" eval_exekutor exec "${command}"
                  )
                  rval=$?
               fi

               log_info "$expanded_subproject: $rval"
               if [ $rval -ne 0 ]
               then
                  redirect_append_exekutor "${statusfile}" printf "%s\n" "${subproject};$rval"
               fi
            ) &
         else
            if [ "${env}" = 'YES' ]
            then
               exekutor mulle-env -c "${command}" subenv "${expanded_subproject}"
               rval=$?
            else
               (
                  rexekutor cd "${expanded_subproject}" &&
                  MULLE_VIRTUAL_ROOT="" eval_exekutor exec "${command}"
               )
               rval=$?
            fi

            log_fluff "${expanded_subproject}: $rval"
            if [ ${rval} -ne 0 ]
            then
               if [ "${lenient}" = 'NO' ]
               then
                  exit $rval
               fi
               log_fluff "Ignoring rval ${rval} coz we're lenient"
            fi
         fi
      .done

      if [ "${parallel}" = 'YES' ]
      then
         wait

         local errors

         errors="`cat "${statusfile}"`"
         remove_file_if_present "${statusfile}"

         if [ ! -z "${errors}" ]
         then
            log_error "Subproject errored out: ${errors}"

            exit 1
         fi
      fi

      :
   ) || exit 1

   return 0
}


###
### parameters and environment variables
### this is still pretty hacky and needs a rework
###
sde::subproject::main()
{
   log_entry "sde::subproject::main" "$@"

   local SUBPROJECT

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -s|--subproject)
            [ $# -eq 1 ] && sde::subproject::usage "Missing argument to \"$1\""
            shift

            SUBPROJECT="$1"
         ;;

         -*)
            sde::subproject::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      add)
         [ -z "${MULLE_SDE_DEPENDENCY_SH}" ] && \
            . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-dependency.sh"

         sde::dependency::add_main --address "$1" \
                                   --marks "${SUBPROJECT_MARKS}" \
                                   --nodetype local \
                                   "$1"  || exit 1
         # hide subproject from main project
         sde::subproject::update_ignore_patternfile
      ;;

      commands)
         echo "\
add
enter
get
init
list
makeinfo
map
mark
move
remove
set
unmark
update-patternfile"
      ;;

      subcommands)
         echo "\
dependency
environment
find
match
patternfile
library
update"
      ;;

      infcommands)
         case "$1" in
            "makeinfo")
               echo "\
get
set
list"
               return 0
            ;;
         esac
         return 1
      ;;

      dependency|environment|find|makeinfo|match|patternfile|library|update)
         local subproject

         [ -z "${SUBPROJECT}" ] && fail "Command \"${cmd}\" requires -s <subproject> option"

         local cmdline
         local arg

         cmdline="mulle-sde"

         for arg in ${MULLE_TECHNICAL_FLAGS}
         do
            cmdline="${cmdline}
${arg}"
         done

         cmdline="${cmdline}
${cmd}"

         while [ $# -ne 0 ]
         do
            cmdline="${cmdline}
$1"
            shift
         done

         log_fluff "Run command with ${MULLE_ENV:-mulle-env}: -C \"${cmdline}\""
         exekutor exec "${MULLE_ENV:-mulle-env}" -C "${cmdline}" subenv "${SUBPROJECT}"
      ;;

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde::subproject::get_main "$@"
      ;;

      enter)
         exekutor exec "${MULLE_ENV:-mulle-env}" subenv "$@"
      ;;

      init)
         sde::subproject::init_main "$@"
      ;;

      #
      # future: retrieve list as CSV and interpret it
      # for now stay layme
      #
      list)
         sde::subproject::list "$@"
      ;;

      mark|unmark)
         local flags

         case "$2" in
            no-platform-*|only-platform-*)
               flags="-e"
            ;;
         esac

         include "sde::common"

         sde::common::exekutor_sourcetree_nofail ${cmd} ${flags} "$@"
      ;;

      move)
         include "sde::common"

         sde::common::exekutor_sourcetree_nofail move "$@"
      ;;

      remove)
         include "sde::common"

         sde::common::exekutor_sourcetree_nofail remove "$@" &&
         # unhide subproject directory from main project
         sde::subproject::update_ignore_patternfile "$@"
      ;;

      map)
         sde::subproject::map 'Executing' 'default' "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde::subproject::set_main "$@"
      ;;

      update-patternfile)
         sde::subproject::update_ignore_patternfile "$@"
      ;;

      "")
         sde::subproject::usage
      ;;

      *)
         sde::subproject::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
