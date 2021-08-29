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
MULLE_SDE_FETCH_SH="included"


sde_fetch_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} fetch [options]

   Fetch all dependencies and ensure the already fetched dependencies are the
   the correct versions (else refetch them).
   This is the like calling \`mulle-sourcetree sync\`, with a quick check
   if a sync is required.

   Options are passed through to \`mulle-sourcetree sync\`.

Options:
   --serial                     : don't fetch dependencies in parallel

Environment:
   MULLE_FETCH_ARCHIVE_DIR      : local cache of archives
   MULLE_FETCH_MIRROR_DIR       : local mirror of git repositories
   MULLE_FETCH_SEARCH_PATH      : specify local search directories, : separated
   MULLE_SOURCETREE_RESOLVE_TAG : inhibit tags resolver before fetch with NO

EOF
  exit 1
}


do_sync_sourcetree()
{
   log_entry "do_sync_sourcetree" "$@"

   if [ "${MULLE_SDE_FETCH}" = 'NO' ]
   then
      log_info "Fetching is disabled by environment MULLE_SDE_FETCH"
      return 0
   fi

   eval_exekutor "'${MULLE_SOURCETREE:-mulle-sourcetree}'" \
                        "${MULLE_TECHNICAL_FLAGS}" \
                        "${OPTION_MODE}" \
                     "sync" \
                        "$@"
}


sde_fetch_main()
{
   log_entry "sde_fetch_main" "$@"

   local OPTION_MODE

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_fetch_usage
         ;;

         -r|--recurse|--flat|--share)
            OPTION_MODE="$1"
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

   local do_update
   local rval

   do_update="${MULLE_FLAG_MAGNUM_FORCE}"
   if [ "${do_update}" != 'YES' ]
   then
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS} \
                    status \
                     --is-uptodate
      rval=$?
      log_fluff "Sourcetree status --is-uptodate returned with $rval"

      if [ ${rval} -ne 0 ]
      then
         do_update='YES'
      fi
   fi

   if [ "${do_update}" = 'YES' ]
   then
      do_sync_sourcetree "$@"
      return $?
   else
      log_verbose "Nothing to do"
   fi
}
