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
# no-cmake-inherit: not expected to publish cmake find_library calls
#
LIBRARY_INIT_MARKS="no-fs,no-dependency,no-build,no-update,no-delete"
LIBRARY_MARKS="no-fs,no-dependency,no-build,no-update,no-delete"
LIBRARY_FILTER_MARKS="no-dependency"
LIBRARY_FILTER_NODETYPES="none"

#
# This puts some additional stuff into userinfo of the sourcetree
# which is then queryable
#
sde::library::usage()
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


sde::library::add_usage()
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
   --framework : library is a MacOS framework (does NOT imply --objc)
   --objc      : used for static Objective-C libraries
   --optional  : is not required to exist
   --private   : headers are not visible to API consumers
EOF
  exit 1
}


sde::library::set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library set [options] <name> <key> <value>

   Modify a library's settings.

   Examples:
      ${MULLE_USAGE_NAME} library set -a pthread aliases pthreads

Options:
   --append          : append value instead of set

Keys:
   aliases           : alternate names of library, separated by comma
   include           : alternative include filename instead of <name>.h
   platform-excludes : names of platform to exclude, separated by comma
EOF
  exit 1
}


sde::library::get_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library get <name> <key>

   Retrieve library settings by name.

   Examples:
      ${MULLE_USAGE_NAME} library get pthread aliases

Keys:
   aliases           : alternate names of library, separated by comma
   include           : alternative include filename instead of <name>.h
   platform-excludes : names of platforms to exclude, separated by comma
EOF
  exit 1
}


sde::library::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} library list [options]

   List libraries of this project.

   Use \`mulle-sde library list -- --output-format cmd\` for copying
   single entries between projects.

Options:
   --       : pass remaining arguments to mulle-sourcetree list

EOF
  exit 1
}


sde::library::warn_stupid_name()
{
   log_entry "sde::library::warn_stupid_name" "$@"

   local libname="$1"

   case "${MULLE_UNAME}" in 
      windows|mingw)
         case "${libname}" in
            *.lib|*.dll)
               log_warning "Library name  \"${libname}\" should not end with a library extension."
            ;;
         esac
      ;;
      
      linux|*bsd|darwin) 
         case "${libname}" in 
            *.a|*.so|*.dylib)
               log_warning "Library name \"${libname}\" should not end with a library extension."
            ;;

            lib*)
               log_warning "Library name \"${libname}\" starts with lib prefix, it and its header may not be found."
            ;;
         esac
      ;;
   esac

}


sde::library::add_main()
{
   log_entry "sde::library::add_main" "$@"

   local marks="${LIBRARY_INIT_MARKS}"

   local OPTION_DIALECT="c"
   local OPTION_PRIVATE='NO'
   local OPTION_OPTIONAL='NO'
   local OPTION_IF_MISSING='NO'
   local OPTION_FRAMEWORK='NO'
   local options
   local userinfo

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::library::add_usage
         ;;

         -c|--c)
            OPTION_DIALECT="c"
         ;;

         -m|--objc)
            OPTION_DIALECT="objc"
         ;;

         --framework)
            OPTION_FRAMEWORK="YES"
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

         --marks)
            [ "$#" -eq 1 ] && sde::library::add_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${marks}" "$1"
            marks="${RVAL}"
         ;;

        --userinfo)
            [ "$#" -eq 1 ] && sde::library::add_usage "Missing argument to \"$1\""
            shift

            userinfo="--userinfo '$1'"
         ;;

         --if-missing)
            r_concat "${options}" "--if-missing"
            options="${RVAL}"
         ;;

         -*)
            sde::library::add_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -ne 1 ] && sde::library::add_usage "Missing arguments"

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
         # prepend is better in this case
         r_comma_concat "no-import,no-all-load,no-cmake-inherit" "${marks}"
         marks="${RVAL}"
      ;;

      objc)
      ;;
   esac

   if [  "${OPTION_FRAMEWORK}" = 'YES' ]
   then
      r_comma_concat "only-framework,only-platform-darwin,no-cmake-inherit" "${marks}"
      marks="${RVAL}"
   fi
   
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

   eval_exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_SOURCETREE_FLAGS:-} \
                     ${MULLE_FWD_FLAGS} \
                   add \
                     --nodetype none \
                     --marks "'${marks}'" \
                     "${userinfo}" \
                     "${options}" \
                     "'${libname}'" || return 1

   log_info "${C_VERBOSE}You can change the library search names with:
${C_RESET_BOLD}   mulle-sde library set ${libname} aliases ${libname},${libname#lib}2
${C_VERBOSE}You can change the header include with:
${C_RESET_BOLD}   mulle-sde library set ${libname} include ${libname#lib}/${libname#lib}.h"

   if [ "${OPTION_FRAMEWORK}" = 'YES' ]
   then
      sde::common::_set_userinfo_field "${libname}" \
                                         'include' \
                                         "<${libname}/${libname}.h>" \
                                         'NO'
   fi                     
}


sde::library::set_main()
{
   log_entry "sde::library::set_main" "$@"

   local OPTION_APPEND='NO'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::library::set_usage
         ;;

         -a|--append)
            OPTION_APPEND='YES'
         ;;

         -*)
            sde::library::set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -lt 2 ] && sde::library::add_usage "Missing arguments"

   local address="$1"
   [ -z "${address}" ] && sde::library::set_usage "Missing address"
   shift

   local field="$1"
   [ -z "${field}" ]  && sde::library::set_usage "Missing field"
   shift

   local value="$1"

   # make sure its really a library, less surprising for the user (i.e. me)
   local marks

   if ! marks="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" get "${address}" marks`"
   then
      return 1
   fi

   if ! sde::common::marks_compatible_with_marks "${marks}" "${LIBRARY_MARKS}"
   then
      fail "${address} is not a library.
${C_INFO}Tip: Check for marks and duplicates with
${C_RESET_BOLD}   mulle-sourcetree list -l -_"
   fi

   case "${field}" in
      aliases|include)
         sde::common::_set_userinfo_field "${address}" \
                                            "${field}" \
                                            "${value}" \
                                            "${OPTION_APPEND}"
      ;;

      platform-excludes)
         sde::common::_set_platform_excludes "${address}" \
                                     "${value}" \
                                     "${LIBRARY_INIT_MARKS}" \
                                     "${OPTION_APPEND}"
      ;;

      *)
         sde::library::set_usage "Unknown field name \"${field}\""
      ;;
   esac
}


sde::library::get_main()
{
   log_entry "sde::library::get_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::library::get_usage
         ;;

         -*)
            sde::library::get_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && sde::library::get_usage "Missing address"
   shift

   local field="$1"
   [ -z "${field}" ] && sde::library::get_usage "Missing field"
   shift

   case "${field}" in
      # can be easily extended with more fields,
      aliases|include)
         sde::common::get_sourcetree_userinfo_field "${address}" "${field}"
      ;;

      platform-excludes)
         sde::common::get_platform_excludes "${address}"
      ;;

      *)
         sde::library::get_usage "Unknown field name \"${field}\""
      ;;
   esac
}


sde::library::list_main()
{
   log_entry "sde::library::list_main" "$@"

   local marks
   local qualifier

   marks="${LIBRARY_FILTER_MARKS}"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::library::list_usage
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde::library::list_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${marks}" "$1"
            marks="${RVAL}"
         ;;

         --qualifier)
            [ "$#" -eq 1 ] && sde::library::list_usage "Missing argument to \"$1\""
            shift

            qualifier="${RVAL}"
         ;;

         --)
            # pass rest to mulle-sourcetree
            shift
            break
         ;;

         -*)
            sde::library::list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   log_fluff "Just pass through to mulle-sourcetree"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                --virtual-root -s \
                ${MULLE_TECHNICAL_FLAGS} \
                ${MULLE_SOURCETREE_FLAGS:-} \
               list \
                  --format "%a;%m;%i={aliases,,-------};%i={include,,-------}\\n" \
                  --marks "${marks}" \
                  --qualifier "${qualifier}" \
                  --nodetypes "${LIBRARY_FILTER_NODETYPES}" \
                  --output-no-marks "${LIBRARY_MARKS}" \
                  "$@"
}


###
### parameters and environment variables
###
sde::library::main()
{
   log_entry "sde::library::main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::library::usage
         ;;

         -*)
            sde::library::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

   if [ -z "${MULLE_SDE_COMMON_SH}" ]
   then
      # shellcheck source=src/mulle-sde-common.sh

      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
   fi

   case "${cmd}" in
      add|get|list|set)
         sde::library::${cmd}_main "$@"
      ;;


      mark|move|remove|unmark)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           -s  \
                           ${MULLE_TECHNICAL_FLAGS} \
                        ${cmd} \
                           "$@"
      ;;

      "")
         sde::library::usage
      ;;

      *)
         sde::library::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
