#! /usr/bin/env bash
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
MULLE_SDE_IGNORE_SH="included"


sde_ignore_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} ignore <pattern>

   Ignore a file or a directory for crafts.

Examples:
      mulle-sde ignore src/foo
      mulle-sde ignore "*.js"

EOF
   exit 1
}


sde_ignore_main()
{
   log_entry "sde_ignore_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_ignore_usage
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde_ignore_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] && sde_ignore_usage "Missing argument"
   [ "$#" -ne 1 ] && sde_ignore_usage "superflous arguments \"$*\""

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   [ -z "${MULLE_FILE_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

   local filepath

   #
   # we just happen to know that 00 is not used by any extensions
   #
   filepath="`rexekutor "${MULLE_MATCH:-mulle-match}" -s patternfile -i path -p 00 'user'`"
   if [ ! -z "${filepath}" ]
   then
      merge_line_into_file "${filepath}" "$1"
   else
      echo "$1" | exekutor "${MULLE_MATCH:-mulle-match}" \
                                    ${MULLE_TECHNICAL_FLAGS} \
                                    ${MULLE_MATCH_FLAGS} \
                                 patternfile -i add -p 00 'user' -
   fi

}
