# shellcheck shell=bash
#
#   Copyright (c) 2019 Nat! - Mulle kybernetiK
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
MULLE_SDE_product_SH='included'


sde::product::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} product [options] <list|run|searchpath>

   Find product of mulle-sde craft (list) or run it if it's an executable.
   Searchpath shows the expected places products of a certain type can
   show up. See \`${MULLE_USAGE_NAME} product searchpath help\` for more info.

Options:
   -h                  : show this usage
   --configuration <c> : set configuration, like "Debug"
   --debug             : shortcut for --configuration Debug
   --release           : shortcut for --configuration Release
   --restrict          : run product with restricted environment
   --sdk <sdk>         : set sdk
EOF
   exit 1
}


sde::product::r_search_path()
{
   log_entry "sde::product::r_search_path" "$@"

   local type="$1"

   local cmdline

   cmdline="mulle-craft ${MULLE_TECHNICAL_FLAGS} searchpath"

   if [ "${OPTION_IF_MISSING}" = 'YES' ]
   then
      r_concat "${cmdline}" "--if-missing"
      cmdline="${RVAL}"
   fi

   local sdks

   sdks="${OPTION_SDK:-${MULLE_CRAFT_SDKS}}"

   if [ ! -z "${sdks}" ]
   then
      r_concat "${cmdline}" "--sdks '${sdks}'"
      cmdline="${RVAL}"
   fi

   r_concat "${cmdline}" "--configurations '${OPTION_CONFIGURATION:-Release:Debug}'"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "--kitchen"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "'${type}'"
   cmdline="${RVAL}"

   RVAL="`eval_rexekutor ${cmdline}`"
}


sde::product::r_product_path()
{
   log_entry "sde::product::r_product_path" "$@"

   local MULLE_PLATFORM_EXECUTABLE_SUFFIX
   local MULLE_PLATFORM_FRAMEWORK_PATH_LDFLAG
   local MULLE_PLATFORM_FRAMEWORK_PREFIX
   local MULLE_PLATFORM_FRAMEWORK_SUFFIX
   local MULLE_PLATFORM_LIBRARY_LDFLAG
   local MULLE_PLATFORM_LIBRARY_PATH_LDFLAG
   local MULLE_PLATFORM_LIBRARY_PREFIX
   local MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC
   local MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC
   local MULLE_PLATFORM_LINK_MODE
   local MULLE_PLATFORM_OBJECT_SUFFIX
   local MULLE_PLATFORM_RPATH_LDFLAG
   local MULLE_PLATFORM_RPATH_VALUE_PREFIX
   local MULLE_PLATFORM_WHOLE_ARCHIVE_LDFLAG_DEFAULT
   local MULLE_PLATFORM_WHOLE_ARCHIVE_LDFLAG_STATIC

   eval_rexekutor `mulle-platform environment`

   local type
   local filename

   case "${PROJECT_TYPE}" in
      library)
         type="library"
         filename=${MULLE_PLATFORM_LIBRARY_PREFIX}"${PROJECT_NAME}${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}"
      ;;

      executable)
         type="binary"
         filename="${PROJECT_NAME}${MULLE_PLATFORM_EXECUTABLE_SUFFIX}"
      ;;

      none)
         log_info "Project type \"none\" builds no product"
         return
      ;;

      *)
         fail "Project type \"${PROJECT_TYPE}\" is unsupported by this command"
      ;;
   esac

   if ! sde::product::r_search_path "${type}"
   then
      fail "Product ${C_RESET_BOLD}${filename}${C_ERROR} not found. Maybe not build yet ?"
   fi

   local searchpath

   searchpath="${RVAL}"
   log_debug "searchpath: ${searchpath}"

   local candidates

   .foreachpath filepath in ${searchpath}
   .do
      r_filepath_concat "${filepath}" "${filename}"
      if [ -e "${RVAL}" ]
      then
         r_add_line "${candidates}" "${RVAL}"
         candidates="${RVAL}"
      fi
   .done

   if [ -z "${candidates}" ]
   then
      fail "Product ${C_RESET_BOLD}${filename}${C_ERROR} not found."
   fi

   local candidate
   local latest_timestamp
   local timestamp

   .foreachline candidate in ${candidates}
   .do
      timestamp="`modification_timestamp "${candidate}" `"
      if [ -z "${latest_timestamp}" ] || [ ${timestamp} -gt ${latest_timestamp} ]
      then
         filepath="${candidate}"
         latest_timestamp="${timestamp}"
      fi
   .done

   RVAL="${filepath}"
}


sde::product::searchpath()
{
   log_entry "sde::product::searchpath" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            MULLE_USAGE_NAME=mulle-sde \
               rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS} searchpath -h
            exit 0
         ;;

         -*)
            sde::product::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::product::r_search_path "$@"
   printf "%s\n" "${RVAL}"
}


sde::product::run()
{
   log_entry "sde::product::run" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::product::usage
         ;;

         --)
            shift
            break
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::product::r_product_path
   log_info "${RVAL#${MULLE_USER_PWD}/}"
   exekutor mudo -f ${MUDO_FLAGS} "${RVAL}" "$@"
}



sde::product::list()
{
   log_entry "sde::product::list" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::product::usage
         ;;

         -*)
            sde::product::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::product::r_product_path
   printf "%s\n" "${RVAL}"
}



sde::product::main()
{
   log_entry "sde::product::main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_SDK
   local OPTION_EXISTS
   local MUDO_FLAGS="-e"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::product::usage
         ;;

         --if-exists)
            OPTION_EXISTS='YES'
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::product::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::product::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
         ;;

         --restrict)
            MUDO_FLAGS=""
         ;;

         --release)
            OPTION_CONFIGURATION="Release"
         ;;

         --debug)
            OPTION_CONFIGURATION="Debug"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::product::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      list)
         sde::product::list "$@"
      ;;

      run)
         sde::product::run "$@"
      ;;

      searchpath)
         sde::product::searchpath "$@"
      ;;

      *)
         sde::product::usage
   esac
}



