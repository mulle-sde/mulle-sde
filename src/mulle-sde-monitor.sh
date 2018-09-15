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
MULLE_SDE_MONITOR_SH="included"

sde_monitor_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} monitor

   Run the mulle-monitor on the current project.

Options:
   -h     : show this usage
EOF
   exit 1
}


sde_monitor_main()
{
   log_entry "sde_monitor_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_monitor_usage
         ;;

         -*)
            sde_monitor_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   if [ -z "${MULLE_SDE_NO_UPDATE}" ]
   then
      if [ -z "${MULLE_SDE_UPDATE_SH}" ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-update.sh"
      fi

      MULLE_SDE_CRAFT_AFTER_UPDATE="YES" sde_update_main
   fi

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi
   set_projectname_environment "read"

   #
   # environment can specify a different set of patternfiles to match against
   #
   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_MONITOR_FLAGS} run --ignore "$@"
}
