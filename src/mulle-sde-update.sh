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
MULLE_SDE_UPDATE_SH="included"


sde_update_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} update [options] ...

   Update runs the default list of MULLE_SDE_UPDATE_CALLBACKS defined by the
   environment, unless task names have been given. See
   `mulle-monitor callback` and `mulle-monitor task` for more information.

   Typical callbacks for mulle-sde are:

      source     : update makefiles
      sourcetree : update dependencies, subprojects and libraries

Options:
   --if-needed   : check before update if it seems unneccessary
   --craft       : craft after update
   --no-craft    : do not craft after update

Environment:
   MULLE_SDE_UPDATE_CALLBACKS   : default callbacks used for update
   MULLE_SDE_CRAFT_AFTER_UPDATE : run \`mulle-sde craft\' after update [YES/NO]
EOF
   exit 1
}



_callback_run()
{
   log_entry "_callback_run"

   local callback="$1"

   [ -z "${callback}" ] && internal_fail "callback is empty"

   local rval

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
   MULLE_CALLBACK_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${MULLE_MONITOR}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MONITOR_FLAGS} \
                     callback run "${callback}"
}


_task_run()
{
   log_entry "_task_run"

   local task="$1"

   [ -z "${task}" ] && internal_fail "task is empty"

   local rval

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
   MULLE_TASK_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${MULLE_MONITOR}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MONITOR_FLAGS} \
                  task run "${task}"
}


_task_status()
{
   log_entry "_task_status"

   local task="$1"

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MONITOR_FLAGS} \
                   task status "${task}"
}


_task_run_if_needed()
{
   log_entry "_task_run_if_needed"

   local task="$1"

   local status

   status="unknown"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
   then
      status="`_task_status "${task}"`"
      log_fluff "Last known status of task \"${task}\" is \"${status}\""

      case "${status}" in
         "done")
            log_fluff "Skip task"
            return
         ;;
      esac
   else
      log_fluff "Forced run of \"${task}\""
   fi

   _task_run "${task}"
}


_sde_update_main()
{
   log_entry "_sde_update_main"

   local runner="$1"

   set_projectname_environment "read"

   local task
   local name

   # call backs are actually comma separated
   set -o noglob; IFS=":"
   for name in ${MULLE_SDE_UPDATE_CALLBACKS}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"

      if [ -z "${name}" ]
      then
         continue
      fi

      task="`_callback_run "${name}"`"
      if [ ! -z "${task}" ]
      then
         "${runner}" "${task}"
      fi
   done
   set +o noglob; IFS="${DEFAULT_IFS}"

   #
   # this is set by mulle-sde monitor
   #
   if [ "${MULLE_SDE_CRAFT_AFTER_UPDATE}" != "YES" ]
   then
      return
   fi
   "${runner}" "craft"
}



sde_update_worker()
{
   log_entry "sde_update_worker"

   local filename="$1"

   log_fluff "Update callbacks: \"${MULLE_SDE_UPDATE_CALLBACKS}\""

   _sde_update_main "${filename}" || exit 1

   #
   # update source of mulle-sde subprojects only
   #

   case ":${MULLE_SDE_UPDATE_CALLBACKS}:" in
      *:source:*)
      ;;

      *)
         return
      ;;
   esac

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || internal_fail "missing file"
   fi

   sde_subproject_map "Updating" "NO" "mulle-sde ${MULLE_TECHNICAL_FLAGS} update --if-needed --no-craft source"
}


sde_update_main()
{
   log_entry "sde_update_main"

   log_entry "sde_extension_main" "$@"

   local runner

   runner="_task_run"
   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_update_usage
         ;;

         --if-needed)
            runner="_task_run_if_needed"
         ;;

         --craft)
            MULLE_SDE_CRAFT_AFTER_UPDATE="YES"
            export MULLE_SDE_CRAFT_AFTER_UPDATE
         ;;

         --no-craft)
            MULLE_SDE_CRAFT_AFTER_UPDATE="NO"
            export MULLE_SDE_CRAFT_AFTER_UPDATE
         ;;

         -*)
            sde_update_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   if [ $# -ne 0 ]
   then
      MULLE_SDE_UPDATE_CALLBACKS="`tr ' ' ':' <<< "$*"`"
      export MULLE_SDE_UPDATE_CALLBACKS
   fi

   sde_update_worker "${runner}"
}
