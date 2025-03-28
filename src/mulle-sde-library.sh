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
MULLE_SDE_LIBRARY_SH='included'

#
# no-fs,,no-dependency,no-build: not in the project tree and it's not built
# and will end up in dependency/
# no-update,no-delete: does not participate in mulle-sourcetree update
# no-all-load: not expected to contain ObjC code
# no-cmake-inherit: not expected to publish cmake find_library calls
#
LIBRARY_INIT_MARKS="no-fs,no-dependency,no-build,no-update,no-delete"
LIBRARY_MARKS="no-fs,no-dependency,no-build,no-update,no-delete"
LIBRARY_LIST_MARKS="no-dependency"
LIBRARY_LIST_NODETYPES="none"
LIBRARY_NODETYPE="none"

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
   example. Libraries are added to the sourcetree so that the
   appropriate link statements can be generated.

   The link statements can be conditionalized according to platform.

   Occasionally, you may want to link explicitly the dependency of a
   dependency and not the dependency itself. In this case "library" is the
   right choice as well.

Options:
   -h     : show this usage

Commands:
   add    : add a library or multiple libraries
   export : export library entry as script
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
   ${MULLE_USAGE_NAME} library add [options] [name]

   Add a sytem library to your project. The name of the library is
   without prefix or suffix. E.g. "libm.a" is just "m".

Examples:
      ${MULLE_USAGE_NAME} library add pthread
      ${MULLE_USAGE_NAME} library add -lpthread -lm
      ${MULLE_USAGE_NAME} library add \$(pkg-config --static --libs-only-l glfw3)

Options:
   -l<name>    : add a system library, multiple use possible
   -f<name>    : add a system framework, multiple use possible
   --framework : library is a MacOS framework (does NOT imply --objc)
   --objc      : used for static Objective-C libraries
   --optional  : library is not required to exist
   --<os>      : use library only on platform <os> (\`mulle-sde common-unames\`)
   --no-header : do not generate include statements
   --no-<os>   : library will be ignored on platform <os>
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
   -c       : use columnar output
   --json   : output in JSON format (default)
   --       : pass remaining arguments to mulle-sourcetree list

EOF
  exit 1
}


sde::library::warn_stupid_name()
{
   log_entry "sde::library::warn_stupid_name" "$@"

   local libname="$1"

   case "${MULLE_UNAME}" in 
      'windows'|'mingw'|'msys')
         case "${libname}" in
            *.lib|*.dll)
               log_warning "Library name  \"${libname}\" should not end with a library extension."
            ;;
         esac
      ;;
      
      'linux'|*'bsd'|'dragonfly'|'darwin')
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


sde::library::add_framework()
{
   log_entry "sde::library::add_framework" "$@"

   local libname="$1"
   local marks="$2"
   local options="$3"
   local userinfo="$4"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
   then
      case "${libname}" in
         ""|-*|*.*|lib*)
            fail "Invalid library name \"${libname}\" (use name w/o extension \
 and prefix)"
         ;;
      esac
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

   _log_info "${C_VERBOSE}You can change the library search names with:
${C_RESET_BOLD}   mulle-sde library set ${libname} aliases ${libname},${libname#lib}2
${C_VERBOSE}You can change the header include with:
${C_RESET_BOLD}   mulle-sde library set ${libname} include ${libname#lib}/${libname#lib}.h"

   sde::common::_set_userinfo_field "${libname}" \
                                      'include' \
                                      "<${libname}/${libname}.h>" \
                                      'NO'
}


sde::library::add_library()
{
   log_entry "sde::library::add_library" "$@"

   local libname="$1"
   local marks="$2"
   local options="$3"
   local userinfo="$4"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
   then
      case "${libname}" in
         ""|-*|*.*|lib*)
            fail "Invalid library name \"${libname}\" (use name w/o extension and prefix)"
         ;;
      esac
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

   _log_info "${C_VERBOSE}You can change the library search names with:
${C_RESET_BOLD}   mulle-sde library set ${libname} aliases ${libname},${libname#lib}2
${C_VERBOSE}You can change the header include with:
${C_RESET_BOLD}   mulle-sde library set ${libname} include ${libname#lib}/${libname#lib}.h"
}


# let add run multiple times over input
sde::library::add_main()
{
   log_entry "sde::library::add_main" "$@"

   local options
   local userinfo
   local names
   local added
   local OPTION_FRAMEWORK='NO'
   local s
   local included_platforms
   local excluded_platforms

   # default is
   local marks
   local defaultmarks

   defaultmarks="${LIBRARY_INIT_MARKS},no-import,no-import,no-cmake-inherit"
   marks="${defaultmarks}"

   include "mulle-sourcetree::marks"

   local known_platforms

   known_platforms="`mulle-bashfunctions common-unames`"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::library::add_usage
         ;;

         -c|--c)
            sourcetree::marks::r_add "${marks}" "no-import"
            sourcetree::marks::r_add "${RVAL}"  "no-all-load"
            sourcetree::marks::r_add "${RVAL}"  "no-cmake-inherit"
            marks="${RVAL}"
         ;;

         -m|--objc)
            sourcetree::marks::r_remove "${marks}" "no-import"
            sourcetree::marks::r_remove "${RVAL}"  "no-all-load"
            sourcetree::marks::r_remove "${RVAL}"  "no-cmake-inherit"
            marks="${RVAL}"
         ;;

         -f*)
            if [ "${#1}" -eq 2 ]
            then
               [ "$#" -eq 1 ] && sde::library::add_usage "Missing argument to \"$1\""
               shift
               s="$1"
            else
               s="${1:2}"
            fi

            sde::library::add_framework "$s" \
                                        "${marks},only-framework,only-platform-darwin,no-cmake-inherit" \
                                        "${options}" \
                                        "${userinfo}"

            added='YES'
         ;;

         --framework)
            OPTION_FRAMEWORK='YES'
         ;;

         # backwards compatibility
         --library|--no-framework)
            OPTION_FRAMEWORK='NO'
         ;;

         --private)
            sourcetree::marks::r_add "${marks}" "no-public"
            marks="${RVAL}"
         ;;

         --public)
            sourcetree::marks::r_add "${marks}" "public"
            marks="${RVAL}"
         ;;

         --optional)
            sourcetree::marks::r_add "${marks}" "no-require"
            marks="${RVAL}"
         ;;

         --no-header)
            sourcetree::marks::r_add "${marks}" "no-header"
            marks="${RVAL}"
         ;;

         --required|--require)
            sourcetree::marks::r_add "${marks}" "require"
            marks="${RVAL}"
         ;;

         --reset-marks)
            marks="${LIBRARY_INIT_MARKS}"
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde::library::add_usage "Missing argument to \"$1\""
            shift

            sourcetree::marks::r_add "${marks}" "$1"
            marks="${RVAL}"
         ;;

         --userinfo)
            [ "$#" -eq 1 ] && sde::library::add_usage "Missing argument to \"$1\""
            shift

            userinfo="--userinfo '$1'"
         ;;

         --reset-options|--unconditonally)
            options=""
         ;;

         --if-missing)
            options="--if-missing"
         ;;

         -l*)
            if [ "${#1}" -eq 2 ]
            then
               [ "$#" -eq 1 ] && sde::library::add_usage "Missing argument to \"$1\""
               shift
               s="$1"
            else
               s="${1:2}"
            fi

            sde::library::add_library "$s" \
                                      "${marks}" \
                                      "${options}" \
                                      "${userinfo}"
            added='YES'
         ;;

         --no-*)
            platform="${1:5}"
            case "${platform}" in
               macos)
                  platform="${platform}"
               ;;
            esac

            if ! find_line "${known_platforms}" "${platform}"
            then
               sde::library::add_usage "Unknown option \"$1\""
            fi

            r_remove_line "${included_platforms}" "${platform}"
            included_platforms="${RVAL}"
            r_add_unique_line "${excluded_platforms}" "${platform}"
            excluded_platforms="${RVAL}"
         ;;

         --*)
            platform="${1:2}"
            case "${platform}" in
               macos)
                  platform="${platform}"
               ;;
            esac

            if ! find_line "${known_platforms}" "${platform}"
            then
               sde::library::add_usage "Unknown option \"$1\""
            fi

            r_remove_line "${excluded_platforms}" "${platform}"
            included_platforms="${RVAL}"
            r_add_unique_line "${included_platforms}" "${platform}"
            included_platforms="${RVAL}"
         ;;

         -*)
            sde::library::add_usage "Unknown option \"$1\""
         ;;

         "")
            sde::library::add_usage "Empty argument"
         ;;

         *)
            local line

            .foreachline line in ${included_platforms}
            .do
               sourcetree::marks::r_add "${marks}" "only-platform-${line}"
               marks="${RVAL}"
            .done

            .foreachline line in ${excluded_platforms}
            .do
               sourcetree::marks::r_add "${marks}" "no-platform-${line}"
               marks="${RVAL}"
            .done

            if [ "${OPTION_FRAMEWORK}" = 'YES' ]
            then
               sourcetree::marks::r_add "${marks}" "only-framework"
               sourcetree::marks::r_add "${RVAL}"  "only-platform-darwin"
               sourcetree::marks::r_add "${RVAL}"  "no-cmake-inherit"

               sde::library::add_framework "$1" "${RVAL}" "${options}" "${userinfo}"
            else
               sde::library::add_library "$1" "${marks}" "${options}" "${userinfo}"
            fi

            added='YES'
         ;;
      esac

      shift
   done

   if [ -z "${added}" ]
   then
      sde::library::add_usage "Missing arguments"
   fi
}


sde::library::set_main()
{
   log_entry "sde::library::set_main" "$@"

   local OPTION_APPEND='NO'

   while [ $# -ne 0 ]
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

   if ! marks="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}"  \
                              get --marks "${LIBRARY_MARKS}" "${address}" marks`"
   then
      return 1
   fi

   # superflous now
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

   while [ $# -ne 0 ]
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

   [ $# -ne 0 ] && sde::library::get_usage "Superflous arguments $*"

   case "${field}" in
      # can be easily extended with more fields,
      aliases|include)
         sde::common::get_sourcetree_userinfo_field "${address}" "${field}"
      ;;

      platform-excludes)
         sde::common::get_platform_excludes "${address}"
      ;;

      *)
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS:-} \
                     get --marks "${LIBRARY_MARKS}" \
                         --nodetype "${LIBRARY_NODETYPE}" \
                     "${address}" \
                     "${field}"
      ;;
   esac
}


sde::library::export_main()
{
   log_entry "sde::library::export_main" "$@"

   local address="$1"

   [ -z "${address}" ] && sde::dependency::export_usage "missing address"
   shift

   include "sde::common"

   sde::common::export_sourcetree_node 'library' "${address}" "${LIBRARY_MARKS}"
}


sde::library::list_main()
{
   log_entry "sde::library::list_main" "$@"

   local no_marks
   local qualifier
   local OPTIONS
   local formatstring
   local OPTION_JSON

   formatstring="%v={NODE_INDEX,#,-};%a;%s;%i={aliases,,-------};%i={include,,-------}"
   # with supermarks we don't filter stuff out anymore a priori
   no_marks=

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::library::list_usage
         ;;

         -m)
            formatstring="%v={NODE_INDEX,#,-};%a;%m;%i={aliases,,-------};%i={include,,-------}"
         ;;

         --no-marks|--no-mark)
            [ "$#" -eq 1 ] && sde::library::list_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${no_marks}" "$1"
            no_marks="${RVAL}"
         ;;

         --qualifier)
            [ "$#" -eq 1 ] && sde::library::list_usage "Missing argument to \"$1\""
            shift

            qualifier="${RVAL}"
         ;;

         -l|-ll|-r|-g|-u|-G|-U)
            r_concat "${OPTIONS}" "$1"
            OPTIONS="${RVAL}"
         ;;

         --json)
            OPTION_JSON='YES'
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

   if [ "${OPTION_JSON}" = 'YES' ]
   then
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
                   --silent-but-warn \
               json \
                  --marks "${LIBRARY_LIST_MARKS}" \
                  --nodetypes "${LIBRARY_LIST_NODETYPES}" \
                  --qualifier "${qualifier}" \
               "$@"
      return $?
   fi

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                --virtual-root \
                ${MULLE_TECHNICAL_FLAGS} \
                --silent-but-warn \
                ${MULLE_SOURCETREE_FLAGS:-} \
               list \
                  --format "${formatstring}\\n" \
                  --marks "${LIBRARY_LIST_MARKS}" \
                  --qualifier "${qualifier}" \
                  --nodetypes "${LIBRARY_LIST_NODETYPES}" \
                  --output-no-marks "${no_marks}" \
                  --verbatim \
                  ${OPTIONS} \
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
   local cmd

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::library::usage
         ;;

         -*)
            cmd="list" # assume its for list
            break
         ;;

         --)
            # pass rest to mulle-sourcetree
            shift
            break
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${cmd}" ]
   then
      cmd="${1:-list}"

      [ $# -ne 0 ] && shift
   fi

   include "sde::common"

   case "${cmd}" in
      add|export|get|list|set)
         sde::library::${cmd}_main "$@"
      ;;

      move)
         include "sde::dependency"

         if sde::dependency::contains_numeric_arguments "$@"
         then
            fail "Only move libraries by name, as the sourcetree is shared with dependencies"
         fi
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           ${MULLE_TECHNICAL_FLAGS} \
                           --silent-but-warn \
                        'move' \
                           "$@"
      ;;


      mark|remove|unmark|rcopy|rm)
         cmd="${cmd/#rm/remove}"
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           ${MULLE_TECHNICAL_FLAGS} \
                           --silent-but-warn \
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
