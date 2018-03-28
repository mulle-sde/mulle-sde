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


SUBPROJECT_MARKS="no-update,no-delete"


sde_subproject_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject [options] [command]

   A subproject is another mulle-sde project of yours, that serves
   as a dependency here. Subprojects are subdirectories.

Options:
   -h            : show this usage

Commands:
   add <name>    : add a subproject
   remove <name> : remove a subproject
   list          : list subprojects (default)
         (use <command> -h for more help about commands)
EOF
   exit 1
}


sde_subproject_add_usage()
{
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


sde_subproject_set_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} subproject set [options] <name> <key> <value>

   Modify a subproject settings, which is referenced by its name.

   Examples:
      ${MULLE_USAGE_NAME} subproject set subproject/mylib \
                                                   os-excludes darwin

Options:
   --append    : append value instead of set

Keys:
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_subproject_get_usage()
{
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
            log_error "unknown option \"$1\""
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


###
### parameters and environment variables
###
sde_subproject_main()
{
   log_entry "sde_subproject_main" "$@"


   #
   # handle options
   #
   while :
   do
      case "$1" in
         -*)
            sde_subproject_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ne 0 ] && shift

   case "${cmd:-list}" in
      add)
         log_fluff "Just pass through to mulle-sourcetree"

         exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} add "$@"
      ;;

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde_subproject_get_main "$@"
         return $?
      ;;

      remove)
         log_fluff "Just pass through to mulle-sourcetree"

         exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} remove "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
         sde_subproject_set_main "$@"
         return $?
      ;;

      #
      # future: retrieve list as CSV and interpret it
      # for now stay layme
      #
      list)
         log_fluff "Just pass through to mulle-sourcetree"

         exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} list \
            --marks "dependency,no-delete" \
             "$@"
      ;;

      *)
         sde_subproject_usage
      ;;
   esac
}
