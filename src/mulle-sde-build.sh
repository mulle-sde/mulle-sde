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
MULLE_SDE_BUILD_SH="included"


sde_build_main()
{
   log_entry "sde_build_main" "$@"

   local cmd="$1"

   local auxflags
   local touchfile

   case "${cmd}" in
      all|build|onlydependencies|nodependencies|project|sourcetree)
         auxflags="--motd"

         touchfile="${MULLE_SDE_DIR}/run/did-update-src"
         if [ -z "${MULLE_SDE_NO_UPDATE}" ] && [ ! -f "${touchfile}" ]
         then
            log_verbose "Run update once, as it apparently hasn't run yet"

            # shellcheck source=src/mulle-sde-monitor.sh
            . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-monitor.sh" || exit 1

            sde_monitor_main --once --no-craft || return 1

            [ ! -f "${touchfile}" ] && internal_fail "\"${touchfile}\" is missing"
         fi
      ;;

      clean)
         rmdir_safer "${MULLE_SDE_DIR}/run"
      ;;
   esac

   exekutor mulle-craft ${MULLE_CRAFT_FLAGS} ${auxflags} "$@"
}
