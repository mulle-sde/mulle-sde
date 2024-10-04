# shellcheck shell=bash
#
#   Copyright (c) 2020 Nat! - Mulle kybernetiK
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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_IGNORE_SH='included'


sde::ignore::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} ignore [options] <pattern>

   Ignore a file or a directory for crafts.

Examples:
      mulle-sde ignore src/foo
      mulle-sde ignore "*.js"

Options:
   --list : list user ignore file (if one exists)
   --cat  : show contents of user ignore file
EOF
   exit 1
}


sde::ignore::main()
{
   log_entry "sde::ignore::main" "$@"

   local cmd="ignore"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::ignore::usage
         ;;

         --cat|--print)
            cmd="cat"
         ;;

         -l|--list)
            cmd="list"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::ignore::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "path"
   include "file"

   local filepath

   filepath="`rexekutor "${MULLE_MATCH:-mulle-match}" -s patternfile -i path -p 00 'user'`"

   case "${cmd}" in
      list)
         [ "$#" -ne 0 ] && sde::ignore::usage "superfluous arguments \"$*\""
         if [ ! -z "${filepath}" ]
         then
            printf "%s\n" "${filepath#"${MULLE_USER_PWD}/"}"
         fi
         return
      ;;

      cat)
         [ "$#" -ne 0 ] && sde::ignore::usage "superfluous arguments \"$*\""
         if [ ! -z "${filepath}" ]
         then
            cat "${filepath}"
         fi
         return
      ;;
   esac

   [ "$#" -eq 0 ] && sde::ignore::usage "Missing argument"
   [ "$#" -ne 1 ] && sde::ignore::usage "superfluous arguments \"$*\""

   exekutor "${MULLE_MATCH:-mulle-match}" \
                                    ${MULLE_TECHNICAL_FLAGS} \
                                    ${MULLE_MATCH_FLAGS} \
                                 patternfile \
                                    ignore "$@"
}
