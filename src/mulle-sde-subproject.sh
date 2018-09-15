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
MULLE_SDE_SUBPROJECT_SH="included"


SUBPROJECT_MARKS="dependency,no-update,no-delete,no-share"

SUBPROJECT_LIST_MARKS="dependency"
SUBPROJECT_LIST_NODETYPES="local"


sde_subproject_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject [options] [command]

   A subproject is another mulle-sde project of yours, that serves
   as a dependency here. Subprojects are subdirectories. A subproject is
   otherwise the same as a dependency but it can not be build on
   its own.

   The subproject feature is ** EXPERIMENTAL ** and in constant flux.

Options:
   -h              : show this usage
   -s <subproject> : choose subproject to run command in

Commands:
   add             : add an existing subproject
   init            : create a subproject
   remove          : remove a subproject
   move            : change buildorder of subproject
   list            : list subprojects (default)
         (use <command> -h for more help about commands)
EOF
   exit 1
}


sde_subproject_add_usage()
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



sde_subproject_move_usage()
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


sde_subproject_set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject set [options] <name> <key> <value>

   Modify a subproject settings, which is referenced by its name.

   Examples:
      ${MULLE_USAGE_NAME} subproject set src/mylib os-excludes darwin

Options:
   --append    : append value instead of set

Keys:
   os-excludes : names of OSes to exclude, separated by comma
   aliases     : alternative names
EOF
  exit 1
}


sde_subproject_get_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject get <name> <key>

   Retrieve subproject settings by its name.

   Examples:
      ${MULLE_USAGE_NAME} subproject get subproject/mylib os-excludes

Keys:
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_subproject_init_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject init <name> ...

   Intitialize a subproject for mulle-sde and add it to the list of
   subprojects. The remainder of the arguments is passed to
   \`mulle-sde init\`.

   If no arguments are given, the subproject inherits the extensions and
   style from the main project.

   Examples:
      ${MULLE_USAGE_NAME} subproject init src/Base

EOF
  exit 1
}



sde_subproject_set_main()
{
   log_entry "sde_subproject_set_main" "$@"

   local OPTION_APPEND="NO"

   while :
   do
      case "$1" in
         -a|--append)
            OPTION_APPEND="YES"
         ;;

         -*)
            log_error "Unknown option \"$1\""
            sde_subproject_set_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde_subproject_set_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde_subproject_set_usage
   shift

   local value="$1"

   case "${field}" in
      os-excludes)
         _sourcetree_set_os_excludes "${address}" \
                                     "${value}" \
                                     "${SUBPROJECT_MARKS}" \
                                     "${OPTION_APPEND}"
      ;;

      aliases|include)
         _sourcetree_set_userinfo_field "${address}" \
                                        "${field}" \
                                        "${value}" \
                                        "${OPTION_APPEND}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_subproject_set_usage
      ;;
   esac
}


sde_subproject_get_main()
{
   log_entry "sde_subproject_get_main" "$@"

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde_subproject_get_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde_subproject_get_usage
   shift

   case "${field}" in
      os-excludes)
         sourcetree_get_os_excludes "${address}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_subproject_get_usage
      ;;
   esac
}


emit_ignore_patternfile()
{
   local subprojects="$1"

   local subproject

   set -o noglob;  IFS="
"
   for subproject in ${subprojects}
   do
      echo "${subproject}/"
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
}


update_ignore_patternfile()
{
   log_entry "sde_subproject_main" "$@"

   local subprojects
   local contents

   subprojects="`sde_subproject_main list --format '%a\n' --no-output-header`"
   contents="`emit_ignore_patternfile "${subprojects}"`"

   local sharefile
   local etcfile

   sharefile="${MULLE_SDE_DIR}/share/ignore.d/30-subproject--none"
   etcfile="${MULLE_SDE_ETC_DIR}/ignore.d/30-subproject--none"

   if [ -e "${sharefile}" ]
   then
      oldcontents="`cat "${sharefile}"`"
      if [ "${oldcontents}" = "${contents}" ]
      then
         return
      fi
      exekutor chmod ug+w "${sharefile}"
   fi

   redirect_exekutor "${sharefile}" echo "${contents}"
   exekutor chmod ug-w "${sharefile}"

   local etcfile

   #
   # Overwrite etc, user should NOT dick with this file
   #
   if [ ! -e "${etcfile}" ]
   then
      return
   fi

   oldetccontents="`cat "${etcfile}"`"
   if [ "${oldetccontents}" != "${oldcontents}" ]
   then
      fail "User edits in \"${etcfile}\" are not allowed"
   fi

   redirect_exekutor "${etcfile}" echo "${contents}"
}


sde_subproject_init_main()
{
   log_entry "sde_subproject_init_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_subproject_init_usage
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde_subproject_init_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local directory

   [ $# -eq 0 ] && sde_subproject_init_usage

   directory="$1"; shift

   if [ -d "${directory}/.mulle-sde" ]
   then
      fail "\"${directory}\" is already present and initialized"
   fi

   local args

   if [ $# -eq 0 ]
   then
      if [ -z "${MULLE_SDE_EXTENSION_SH}" ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh" || internal_fail "missing file"
      fi

      local meta

      meta="`sde_extension_main installed-meta`"
      if [ -z "${meta}" ]
      then
         fail "Unknown installed meta extension. Specify it yourself"
         exit 1
      fi

      args="--style `mulle-env style` -m '${meta}' library"
   fi

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || internal_fail "missing file"
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || internal_fail "missing file"
   fi

   mkdir_if_missing "${directory}"
   (
      cd "${directory}"

      # shellcheck source=src/mulle-sde-init.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

      MULLE_VIRTUAL_ROOT="" \
      MULLE_FLAG_MAGNUM_FORCE="YES" \
      PROJECT_NAME="" \
         eval_exekutor sde_init_main --no-motd --no-blurb --project-source-dir "." "$@" "${args}"
   ) || exit 1

   sde_subproject_main "add" "${directory}"
}


sde_subproject_get_names()
{
   log_entry "sde_subproject_get_names" "$@"

   sde_subproject_main list --format '%a\n' --no-output-header
}


sde_subproject_map()
{
   log_entry "sde_subproject_map" "$@"

   local verb="${1:-Updating}" ; shift
   local lenient="${1:-NO}" ; shift

   local subprojects

   subprojects="`sde_subproject_get_names`"
   if [ -z "${subprojects}" ]
   then
      log_fluff "No subprojects, so done"
      return
   fi

   local subproject
   local command
   local rval

   command="$*"

   set -o noglob;  IFS="
"
   for subproject in ${subprojects}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"

      if [ -d "${MULLE_VIRTUAL_ROOT}/${subproject}/.mulle-sde" ]
      then
         log_verbose "${verb} subproject ${C_MAGENTA}${C_BOLD}${subproject}${C_VERBOSE}"
         exekutor mulle-env -c "${command}" subenv "${MULLE_VIRTUAL_ROOT}/${subproject}"
         rval=$?
         if [ ${rval} -ne 0 ]
         then
            if [ "${lenient}" = "NO" ]
            then
               return ${rval}
            fi
            log_fluff "Ignoring rval $rval coz we're lenient"
         fi
      else
         log_fluff "Don't update subproject \"${subproject}\" as it has no .mulle-sde folder"
      fi
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
}



###
### parameters and environment variables
###
sde_subproject_main()
{
   log_entry "sde_subproject_main" "$@"

   local SUBPROJECT

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -s|--subproject)
            [ $# -eq 1 ] && sde_subproject_usage "Missing argument to \"$1\""
            shift

            SUBPROJECT="$1"
         ;;

         -*)
            sde_subproject_usage "Unknown option \"$1\""
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
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V ${MULLE_SOURCETREE_FLAGS} add \
            --marks "${SUBPROJECT_MARKS}" "$@"
         update_ignore_patternfile "$@"
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

         log_fluff "Run command with mulle-env: -C \"${cmdline}\""
         exekutor exec "${MULLE_ENV}" ${MULLE_ENV_FLAGS} -C "${cmdline}" subenv "${SUBPROJECT}"
      ;;

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde_subproject_get_main "$@"
      ;;

      enter)
         "${MULLE_ENV}" ${MULLE_ENV_FLAGS} subenv "$1"
      ;;

      init)
         sde_subproject_init_main "$@"
      ;;

      mark|unmark)
         local flags

         case "$2" in
            no-os-*|only-os-*)
               flags="-e"
            ;;
         esac

         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V ${MULLE_SOURCETREE_FLAGS} ${cmd} ${flags} "$@"
      ;;

      move)
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V ${MULLE_SOURCETREE_FLAGS} move "$@"
      ;;

      remove)
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V ${MULLE_SOURCETREE_FLAGS} remove "$@"
         update_ignore_patternfile "$@"
      ;;

      map)
         sde_subproject_map "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde_subproject_set_main "$@"
      ;;

      #
      # future: retrieve list as CSV and interpret it
      # for now stay layme
      #
      list)
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V ${MULLE_SOURCETREE_FLAGS} list \
            --marks "${SUBPROJECT_LIST_MARKS}" \
            --nodetypes "${SUBPROJECT_LIST_NODETYPES}" \
            --output-no-url \
            --output-no-marks "${SUBPROJECT_MARKS}" \
            "$@"
      ;;

      update-patternfile)
         update_ignore_patternfile "$@"
      ;;

      "")
         sde_subproject_usage
      ;;

      *)
         sde_subproject_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
