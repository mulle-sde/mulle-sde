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

#
# no-fs,,no-dependency,no-build: not in the project tree and it's not built
# and will end up in dependency/
# no-update,no-delete: does not participate in mulle-sourcetree update
# no-all-load: not expected to contain ObjC code
# no-cmakeinherit: not expected to publish cmake find_library calls
#
LIBRARY_INIT_MARKS="no-fs,no-dependency,no-build,no-update,no-delete,no-cmakeinherit"
LIBRARY_MARKS="no-fs,no-dependency,no-build,no-update,no-delete"
LIBRARY_FILTER_MARKS="no-dependency"
LIBRARY_FILTER_NODETYPES="none"

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

   A library is a usually a globally installed C library. Like -lm for
   example. They are added into the sourcetree so that the appropriate link
   statements can be generated.

   The link statements can be conditionalized according to platform.

   Occasionally, you may want to link explicitly the dependency of a
   dependency and not the dependency itself. In this case "library" is the
   right choice as well.

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

   Add a sytem library to your project. The name of the library is
   without prefix or suffix. E.g. "libm.a" is just "m"

   Example:
      ${MULLE_USAGE_NAME} libraries add pthread

Options:
   --objc          : used for static Objective-C libraries
   --optional      : is not required to exist
   --private       : headers are not visible to API consumers
EOF
  exit 1
}


sde_library_set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library set [options] <name> <key> <value>

   Modify a library's settings.

   Examples:
      ${MULLE_USAGE_NAME} library set -a pthread aliases pthreads

Options:
   --append    : append value instead of set

Keys:
   aliases     : alternate names of library, separated by comma
   include     : alternative include filename instead of <name>.h
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

   Retrieve library settings by name.

   Examples:
      ${MULLE_USAGE_NAME} library get pthread aliases

Keys:
   aliases     : alternate names of library, separated by comma
   include     : alternative include filename instead of <name>.h
   os-excludes : names of OSes to exclude, separated by comma
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

   local marks="${LIBRARY_INIT_MARKS}"

   local OPTION_DIALECT="c"
   local OPTION_PRIVATE='NO'
   local OPTION_OPTIONAL='NO'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_add_usage
         ;;

         -c|--c)
            OPTION_DIALECT="c"
         ;;

         -m|--objc)
            OPTION_DIALECT="objc"
         ;;

         --plain)
            OPTION_ENHANCE='NO'
         ;;

         --private)
            OPTION_PRIVATE='YES'
         ;;

         --public)
            OPTION_PRIVATE='NO'
         ;;

         --optional)
            OPTION_OPTIONAL='YES'
         ;;

         -*)
            log_error "Unknown option \"$1\""
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

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
   then
      case "${libname}" in
         ""|-*|*.*|lib*)
            fail "Invalid library name \"${libname}\" (use name w/o extension \
 and prefix)"
         ;;
      esac
   fi

   case "${OPTION_DIALECT}" in
      c)
         r_comma_concat "${marks}" "no-import,no-all-load,no-cmakeinherit"
         marks="${RVAL}"
      ;;
   esac

   if [ "${OPTION_PRIVATE}" = 'YES' ]
   then
      r_comma_concat "${marks}" "no-public"
      marks="${RVAL}"
   fi

   if [ "${OPTION_OPTIONAL}" = 'YES' ]
   then
      r_comma_concat "${marks}" "no-require"
      marks="${RVAL}"
   fi

   log_verbose "Adding \"${libname}\" to libraries"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V add \
                                       --nodetype none \
                                       --marks "${marks}" \
                                       "${libname}"
}


sde_library_set_main()
{
   log_entry "sde_library_set_main" "$@"

   local OPTION_APPEND='NO'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_set_usage
         ;;

         -a|--append)
            OPTION_APPEND='YES'
         ;;

         -*)
            sde_library_set_usage "Unknown option \"$1\""
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
                                     "${LIBRARY_INIT_MARKS}" \
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
            sde_library_get_usage "Unknown option \"$1\""
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

   marks="${LIBRARY_FILTER_MARKS}"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_library_list_usage
         ;;

         --marks)
            [ "$#" -eq 1 ] && usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${marks}" "$1"
            marks="${RVAL}"
         ;;

         --)
            # pass rest to mulle-sourcetree
            shift
            break
         ;;

         -*)
            sde_library_list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   log_fluff "Just pass through to mulle-sourcetree"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                -V -s \
                ${MULLE_TECHNICAL_FLAGS} \
                ${MULLE_SOURCETREE_FLAGS} \
               list \
                  --format "%a;%m;%i={aliases,,-------};%i={include,,-------}\\n" \
                  --marks "${marks}" \
                  --nodetypes "${LIBRARY_FILTER_NODETYPES}" \
                  --output-no-marks "${LIBRARY_MARKS}" \
                  "$@"
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
            sde_library_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

   # shellcheck source=src/mulle-sde-common.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

   case "${cmd}" in
      add|get|list|set)
         sde_library_${cmd}_main "$@"
      ;;


      mark|move|remove|unmark)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V -s ${MULLE_SOURCETREE_FLAGS} ${cmd} "$@"
      ;;

      "")
         sde_library_usage
      ;;

      *)
         sde_library_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
