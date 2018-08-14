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
MULLE_SDE_MAKEINFO_SH="included"


sde_makeinfo_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} makeinfo [options] [command]

   ** MAKEINFO IS POSSIBLY A MISFEATURE AND IT MIGHT BE REMOVED **

   This command manipulate makeinfo definitions for a project. A common
   makeinfo setting is CC to specify the compiler to use (e.g. mulle-clang).
   By default makeinfo definitions settings are os-specific.

   To change craftinfo settings
   for a dependency use \`mulle-sde dependency craftinfo\`. This command is
   not fully coded yet!

   A commonly manipulated makeinfo setting is \"CFLAGS\".

   See \`mulle-make definition\` for more help about the commands "get", "set"
   and "list"

   Example:
      mulle-sde makeinfo set CFLAGS '--no-remorse'

Options:
   --info-dir <dir> : specify info directory to manipulate explicitly
   --global         : use os specific scope

Commands:
   get    : get value of a setting
   set    : change a setting
   list   : list current settings
   search : locate makeinfo

EOF
   exit 1
}


sde_makeinfo_main()
{
   log_entry "sde_makeinfo_main" "$@"

   local OPTION_INFO_DIR=".mulle-make"
   local OPTION_GLOBAL="DEFAULT"

   local argument
   local flags
   local searchflags

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_makeinfo_usage
         ;;

         --allow-unknown-option)
            flags="`concat "${flags}" "$1"`"
         ;;

         --no-allow-unknown-option)
            flags="`concat "${flags}" "$1"`"
         ;;

         #
         # with shortcuts
         #
         -i|--info-dir)
            [ $# -eq 1 ] && sde_makeinfo_usage "Missing argument to \"$1\""
            shift

            OPTION_INFO_DIR="$1"
         ;;

         --global)
            searchflags="`concat "${searchflags}" "--global"`"
         ;;

         -*)
            sde_makeinfo_usage "Unknown definition option ${argument}"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_makeinfo_usage

   local cmd="$1"; shift

   case "${flags}" in
      *--global*)
      ;;

      *)
         OPTION_INFO_DIR="${OPTION_INFO_DIR}.${MULLE_UNAME}"
      ;;
   esac

   case "${cmd}" in
      search)
         MULLE_USAGE_NAME="mulle-sde" \
            "${MULLE_CRAFT}" search ${searchflags} "$@"
      ;;

      list|get|set|keys)
         MULLE_USAGE_NAME="mulle-sde" \
         MULLE_USAGE_COMMAND="makeinfo" \
            "${MULLE_MAKE}" -i "${OPTION_INFO_DIR}" ${flags} "definition" "$@"
      ;;

      "")
         sde_makeinfo_usage
      ;;

      *)
         sde_makeinfo_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
