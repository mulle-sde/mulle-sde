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
MULLE_SDE_LIBRARY_SH="included"


LIBRARY_MARKS="no-fs,no-dependency,no-build,no-update,no-delete"

#
# This puts some additional stuff into userinfo of the sourcetree
# which is then queryable
#
sde_library_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library [options] [command]

   A library is a OS (Operating System) supplied library. Like -lm for example.
   It's usually not useful to build these yourself (like a dependency).
   They are place into the sourcetree so that the approriat link statements
   can be generated on a per platform and buildtool basis.

Options:
   -h     : show this usage

Commands:
   add    : add a library
   get    : retrieve library settings
   list   : list libraries (default)
   remove : remove a library
   set    : change library settings
      (use <command> -h for more help about commands)
EOF
   exit 1
}


sde_library_add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library add <name>

   Add a OS supplied library to your project. The name of the library is
   without prefix or suffix. E.g. "libm.a" is just "m"

   Example:
      ${MULLE_USAGE_NAME} libraries add pthread
EOF
  exit 1
}


sde_library_set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library set [options] <name> <key> <value>

   Modify library settings by its name.

   Examples:
      ${MULLE_USAGE_NAME} library set -a pthread aliases pthreads

Options:
   --append    : append value instead of set

Keys:
   aliases     : alternate names of library, separated by comma
   include     : alternative include filename instead of <name>/<name>.h
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_library_get_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library get <name> <key>

   Retrieve library settings by its name.

   Examples:
      ${MULLE_USAGE_NAME} library get pthread aliases

Keys:
   aliases     : alternate names of library, separated by comma
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_library_remove_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library remove <name>

   Remove a library by its name from the project.
EOF
  exit 1
}



sde_library_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library list

   List libraries of this project.
EOF
  exit 1
}


sde_library_add_main()
{
   log_entry "sde_library_add_main" "$@"

   local OPTION_OS_EXCLUDES
   local OPTION_ALIASES

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_add_usage
         ;;

         -*)
            log_error "unknown option \"$1\""
            sde_library_add_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 1 ] && sde_library_add_usage

   local libname="$1"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
   then
      case "${libname}" in
         ""|-*|*.*|lib*)
            fail "Invalid library name \"${libname}\" (use name w/o extension \
 and prefix)"
         ;;
      esac
   fi

   log_verbose "Adding \"${libname}\" to libraries"

   exekutor "${MULLE_SOURCETREE}" add --nodetype none \
                                      --marks "${LIBRARY_MARKS}" \
                                    "${libname}"
}



sde_library_set_main()
{
   log_entry "sde_library_set_main" "$@"

   local OPTION_APPEND="NO"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_set_usage
         ;;

         -a|--append)
            OPTION_APPEND="YES"
         ;;

         -*)
            sde_library_set_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -lt 2 ] && sde_library_add_usage

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde_library_set_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde_library_set_usage
   shift

   local value="$1"

   case "${field}" in
      aliases|include)
         _sourcetree_set_userinfo_field "${address}" \
                                        "${field}" \
                                        "${value}" \
                                        "${OPTION_APPEND}"
      ;;

      os-excludes)
         _sourcetree_set_os_excludes "${address}" \
                                     "${value}" \
                                     "${LIBRARY_MARKS}" \
                                     "${OPTION_APPEND}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_library_set_usage
      ;;
   esac
}


sde_library_get_main()
{
   log_entry "sde_library_get_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_get_usage
         ;;

         -*)
            sde_library_get_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde_library_get_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde_library_get_usage
   shift

   case "${field}" in
      # can be easily extended with more fields,
      aliases|include)
         sourcetree_get_userinfo_field "${address}" "${field}"
      ;;

      os-excludes)
         sourcetree_get_os_excludes "${address}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_library_get_usage
      ;;
   esac
}


sde_library_list_main()
{
   log_entry "sde_library_list_main" "$@"

   local marks

   marks="${LIBRARY_MARKS}"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_list_usage
         ;;

         --marks)
            [ "$#" -eq 1 ] && usage "missing argument to \"$1\""
            shift

            marks="`comma_concat "${marks}" "$1"`"
         ;;

         --)
            # pass rest to mulle-sourcetree
            shift
            break
         ;;

         -*)
            sde_library_list_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   log_fluff "Just pass through to mulle-sourcetree"

   exekutor "${MULLE_SOURCETREE}" -s ${MULLE_SOURCETREE_FLAGS} list \
      --format "%a;%m;%i={aliases,,-------};%i={include,,-------}\\n" \
      --nodetypes "none" \
      --marks "${marks}" \
      --no-output-marks "${LIBRARY_MARKS}" \
       "$@"
}


sde_library_remove_main()
{
   log_entry "sde_library_remove_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_remove_usage
         ;;

         -*)
            sde_library_list_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   log_fluff "Just pass through to mulle-sourcetree"
   export MULLE_EXECUTABLE_NAME

   MULLE_USAGE_NAME="${MULLE_EXECUTABLE_NAME}" \
      exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} remove "$@"
}


###
### parameters and environment variables
###
sde_library_main()
{
   log_entry "sde_library_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_usage
         ;;

         -*)
            sde_library_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ne 0 ] && shift

   # shellcheck source=src/mulle-sde-common.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

   case "${cmd}" in
      add|get|list|remove|set)
         sde_library_${cmd}_main "$@"
      ;;

      "")
         sde_library_usage
      ;;

      *)
         log_error "Unknown command \"${cmd}\""
         sde_library_usage
      ;;
   esac
}
