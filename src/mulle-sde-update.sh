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


_callback_run()
{
   log_entry "_callback_run"

   local callback="$1"

   [ -z "${callback}" ]      && internal_fail "callback is empty"
   [ -z "${MULLE_MONITOR}" ] && internal_fail "MULLE_MONITOR is empty"

   local rval

   exekutor "${MULLE_MONITOR}" ${MULLE_MONITOR_FLAGS} callback run "${callback}"
}


_task_run()
{
   log_entry "_task_run"

   local task="$1"

   [ -z "${task}" ]          && internal_fail "task is empty"
   [ -z "${MULLE_MONITOR}" ] && internal_fail "MULLE_MONITOR is empty"

   local rval

   exekutor "${MULLE_MONITOR}" ${MULLE_MONITOR_FLAGS} task run "${task}"
}


_task_status()
{
   log_entry "_task_has_run"

   local task="$1"

   local rval

   exekutor "${MULLE_MONITOR}" ${MULLE_MONITOR_FLAGS} task status "${task}"
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
   else
      log_fluff "Forced run of \"${task}\""
   fi

   case "${status}" in
      "done")
         log_fluff "Skip task"
         return
      ;;
   esac

   _task_run "${task}"
}


_sde_update_main()
{
   log_entry "_sde_update_main"

   local runner="$1" ; shift

   local status

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi
   set_projectname_environment "read"

   local callbacks

   # default by preference
   callbacks="${MULLE_SDE_UPDATE_CALLBACKS}"
   if [ -z "${callbacks}" ]
   then
      log_verbose "MULLE_SDE_UPDATE_CALLBACKS is not defined, doing nothing."
      return
   fi

   local task
   local name

   # call backs are actually comma separated
   set -o noglob; IFS=":"
   for name in ${callbacks}
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
   if [ "${MULLE_SDE_CRAFT_AFTER_UPDATE}" = "YES" ]
   then
      "${runner}" "craft"
   fi
}


sde_update_main()
{
   log_entry "sde_update_main"

   _sde_update_main "_task_run" "$@"
}


sde_update_if_needed_main()
{
   log_entry "sde_update_if_needed_main"

   _sde_update_main "_task_run_if_needed" "$@"
}