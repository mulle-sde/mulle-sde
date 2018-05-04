#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_SDE_UPGRADE_SH="included"


sde_upgrade_usage()
{
   SHOWN_COMMANDS="\
   project    : upgrade project template content  (rarely useful)
"

    cat <<EOF >&2
Usage:
   ${UPGRADE_USAGE_NAME:-${MULLE_USAGE_NAME} upgrade [project]

   Upgrade to a newer mulle-sde version. The default is to upgrade the non
   project files only. Upgrading project files is usally also not recommended,
   as you could lose changes.

Options:
   --no-init   : do not run init again

Commands:
EOF

   (
      echo "${SHOWN_COMMANDS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
      then
         echo "${HIDDEN_COMMANDS}"
      fi
   ) | sed '/^$/d' | sort >&2

   cat <<EOF >&2
         (use -v for more commands)
EOF
   exit 1
}


###
### parameters and environment variables
###
sde_upgrade_main()
{
   log_entry "sde_upgrade_main" "$@"

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_upgrade_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   # shellcheck source=src/mulle-sde-init.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   eval_exekutor sde_init_main --upgrade "$@"
}
