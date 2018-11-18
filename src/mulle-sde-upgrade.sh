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
   [ "$#" -ne 0 ] && log_error "$1"

   SHOWN_COMMANDS="\
   project    : upgrade project template content  (rarely useful)
"

    cat <<EOF >&2
Usage:
   ${UPGRADE_USAGE_NAME:-${MULLE_USAGE_NAME}} upgrade [project]

   Upgrade to a newer mulle-sde version. The default is to upgrade the non
   project files only. Upgrading project files is usually not a good idea,
   as you could lose changes. Only environment variables in the "share" scope
   will be affected by an extension upgrade.

Options:
   --no-init     : do not run init again
   --no-recurse  : do not upgrade subprojects
Commands:
EOF

   (
      echo "${SHOWN_COMMANDS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
      then
         echo "${HIDDEN_COMMANDS}"
      fi
   ) | sed '/^$/d' | LC_ALL=C sort >&2

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

   local OPTION_RECURSE='YES'

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_upgrade_usage
         ;;

         --no-recurse)
            OPTION_RECURSE='NO'
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   # shellcheck source=src/mulle-sde-init.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   case "$*" in
      *--upgrade-project-file*)
      ;;

      *)
         log_info "Upgrading ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO}"
      ;;
   esac

   eval_exekutor sde_init_main --upgrade "$@" || return 1

   if [ "${OPTION_RECURSE}" = 'NO' ]
   then
      return 0
   fi

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || internal_fail "missing file"
   fi

   local flags

   flags="${MULLE_SDE_FLAGS} ${MULLE_TECHNICAL_FLAGS}"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="${flags} -f"
   fi

   sde_subproject_map 'Upgrading' 'NO' 'NO' "mulle-sde ${flags} extension upgrade"
}
