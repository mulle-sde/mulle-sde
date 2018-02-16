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

   local rval

   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" \
   MULLE_SDE_LIBEXEC_DIR="${MULLE_SDE_LIBEXEC_DIR}" \
   MULLE_MONITOR_DIR="${MULLE_SDE_DIR}" \
   MULLE_SDE_DIR="${MULLE_SDE_DIR}" \
      exekutor mulle-monitor ${MULLE_MONITOR_FLAGS} callback run "${callback}"
}


_task_run()
{
   log_entry "_task_run"

   local taskj="$1"

   local rval

   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" \
   MULLE_SDE_LIBEXEC_DIR="${MULLE_SDE_LIBEXEC_DIR}" \
   MULLE_MONITOR_DIR="${MULLE_SDE_DIR}" \
   MULLE_SDE_DIR="${MULLE_SDE_DIR}" \
      exekutor mulle-monitor ${MULLE_MONITOR_FLAGS} task run "${task}"
}


_task_status()
{
   log_entry "_task_has_run"

   local taskj="$1"

   local rval

   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" \
   MULLE_SDE_LIBEXEC_DIR="${MULLE_SDE_LIBEXEC_DIR}" \
   MULLE_MONITOR_DIR="${MULLE_SDE_DIR}" \
   MULLE_SDE_DIR="${MULLE_SDE_DIR}" \
      exekutor mulle-monitor ${MULLE_MONITOR_FLAGS} task status "${task}"
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
   fi

   case "${status}" in
      success)
         return
      ;;
   esac

   _task_run "${task}"
}


sde_update_main()
{
   log_entry "sde_update_main"

   local task
   local status

   task="`_callback_run "source"`"
   if [ ! -z "${task}" ]
   then
      _task_run_if_needed "${task}"
   fi

   task="`_callback_run "sourcetree"`"
   if [ ! -z "${task}" ]
   then
      _task_run_if_needed "${task}"
   fi

   #
   # this is set by mulle-sde monitor
   #
   if [ "${MULLE_SDE_CRAFT_AFTER_UPDATE}" = "YES" ]
   then
      _task_run_if_needed "craft"
   fi
}
