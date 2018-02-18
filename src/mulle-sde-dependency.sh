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
MULLE_SDE_DEPENDENCY_SH="included"


DEPENDENCY_MARKS=""  # no-cmake-include"


sde_dependency_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dependency [options] [command]

   A dependency is a third party package, that is fetched via an URL.
   I will be built along with your project.

Options:
   -h           : show this usage

Commands:
   add <url>    : add a dependency
   remove <url> : remove a dependency
   list         : list dependencies (default)
         (use <command> -h for more help about commands)
EOF
   exit 1
}


sde_dependency_set_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dependency set [options] <url> <key> <value>

   Modify a dependency's settings, which is referenced by its url.

   Examples:
      ${MULLE_EXECUTABLE_NAME} dependency set --append pthreads aliases pthread

Options:
   --append    : append value instead of set

Keys:
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_dependency_get_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dependency get <url> <key>

   Retrieve dependency settings by its url.

   Examples:
      ${MULLE_EXECUTABLE_NAME} dependency get pthreads aliases

Keys:
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_dependency_set_main()
{
   log_entry "sde_dependency_set_main" "$@"

   local OPTION_APPEND="NO"

   while :
   do
      case "$1" in
         -a|--append)
            OPTION_APPEND="YES"
         ;;

         -*)
            log_error "unknown option \"$1\""
            sde_dependency_set_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && log_error "missing address" && sde_dependency_set_usage
   shift

   local field="$1"
   [ -z "${field}" ] && log_error "missing field" && sde_dependency_set_usage
   shift

   local value="$1"

   case "${field}" in
      os-excludes)
         _sourcetree_set_os_excludes "${address}" \
                                     "${value}" \
                                     "${LIBRARY_MARKS}" \
                                     "${OPTION_APPEND}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_dependency_set_usage
      ;;
   esac
}


sde_dependency_get_main()
{
   log_entry "sde_dependency_get_main" "$@"

   local url="$1"
   [ -z "${address}" ] && log_error "missing address" && sde_dependency_get_usage
   shift

   local url="$1"
   [ -z "${field}" ] && log_error "missing field" && sde_dependency_get_usage
   shift

   case "${field}" in
      os-excludes)
         sourcetree_get_os_excludes "${url}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_dependency_get_usage
      ;;
   esac
}


###
### parameters and environment variables
###
sde_dependency_main()
{
   log_entry "sde_dependency_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help)
            sde_dependency_usage
         ;;

         -*)
            fail "unknown option \"$1\""
            sde_dependency_usage
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
         export MULLE_EXECUTABLE_NAME

         exekutor mulle-sourcetree -s ${MULLE_SOURCETREE_FLAGS} add "$@"
      ;;

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde_dependency_get_main "$@"
         return $?
      ;;

      remove)
         export MULLE_EXECUTABLE_NAME

         exekutor mulle-sourcetree -s ${MULLE_SOURCETREE_FLAGS} remove "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde_dependency_set_main "$@"
         return $?
      ;;

      list)
         export MULLE_EXECUTABLE_NAME

         exekutor mulle-sourcetree -s ${MULLE_SOURCETREE_FLAGS} list \
            --format "um" \
            --no-output-header \
            --output-raw \
            --marks "dependency" \
             "$@"
      ;;

      *)
         log_error "Unknown command \"${cmd}\""
         sde_dependency_usage
      ;;
   esac
}
