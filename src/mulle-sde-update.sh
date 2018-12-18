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
   \`mulle-monitor callback\` and \`mulle-monitor task\` for more information.

   Typical callbacks for mulle-sde are:

      source     : reflect changes in \"${PROJECT_SOURCE_DIR}\" into makefiles
      sourcetree : reflect library and dependency changes into makefiles and
                   header files
Options:
   --if-needed   : check before update, if it seems unneccessary
   --craft       : craft after update
   --no-recurse  : do not recurse into subprojects

Environment:
   MULLE_SDE_UPDATE_CALLBACKS   : default callbacks used for update
EOF
   exit 1
}



_callback_run()
{
   log_entry "_callback_run" "$@"

   local callback="$1"

   [ -z "${callback}" ] && internal_fail "callback is empty"

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
   MULLE_MONITOR_CALLBACK_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MONITOR_FLAGS} \
                     callback run "${callback}"
}


_task_run()
{
   log_entry "_task_run" "$@"

   local task="$1"

   [ -z "${task}" ] && internal_fail "task is empty"

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
   MULLE_MONITOR_TASK_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MONITOR_FLAGS} \
                  task run "${task}"
}


_task_status()
{
   log_entry "_task_status" "$@"

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MONITOR_FLAGS} \
                   task status "${task}"
}

#
# TODO: shouldn't the monitor be able to do this better ?
#
_task_run_if_needed()
{
   log_entry "_task_run_if_needed"  "$@"

   local task="$1"

   local status

   status="unknown"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
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


_sde_update_task()
{
   log_entry "_sde_update_task" "$@"

   local runner="$1"
   local statusfile="$2"
   local name="$3"

   local task
   local rval

   task="`_callback_run "${name}"`"
   rval=$?

   if [ ! -z "${statusfile}" ]
   then
      redirect_append_exekutor "${statusfile}" echo $rval
   fi

   if [ ! -z "${task}" ]
   then
      "${runner}" "${task}"
      rval=$?
      if [ ! -z "${statusfile}" ]
      then
         redirect_append_exekutor "${statusfile}" echo $rval
      fi
   fi

   return $rval
}


_sde_update_main()
{
   log_entry "_sde_update_main" "$@"

   local runner="$1" ; shift
   local statusfile="$1"; shift

   local task
   local name

   if [ $# -eq 1 ]
   then
      _sde_update_task "${runner}" "${statusfile}" "${name}"
      return $?
   fi

   for name in "$@"
   do
      if [ ! -z "${name}" ]
      then
         _sde_update_task "${runner}" "${statusfile}" "${name}" &
      fi
   done

   wait
}


sde_update_worker()
{
   log_entry "sde_update_worker" "$@"

   local runner="$1" ; shift
   local recurse="$1" ; shift

   log_fluff "Update callbacks: \"${MULLE_SDE_UPDATE_CALLBACKS}\""

   if [ "${recurse}" = 'NO' ]
   then
      _sde_update_main "${runner}" "" "$@"
      return $?
   fi

   #
   # update source of mulle-sde subprojects only
   #
#   case ":${MULLE_SDE_UPDATE_CALLBACKS}:" in
#      *:source:*)
#      ;;
#
#      *)
#         return
#      ;;
#   esac

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || internal_fail "missing file"
   fi
   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || internal_fail "missing file"
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || internal_fail "missing file"
   fi

   local options

   if [ "${runner}" = "_task_run_if_needed" ]
   then
      options="${options} --if-needed"
   fi

   local flags

   flags="${MULLE_SDE_FLAGS} ${MULLE_TECHNICAL_FLAGS}"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="${flags} -f"
   fi

   # can't handle failure here oh well
   local statusfile

   r_make_tmp "mulle-sde"
   statusfile="${RVAL}"

   sde_subproject_map 'Updating' 'NO' 'YES' "${statusfile}" "mulle-sde ${flags} update ${options} $*"
   _sde_update_main "${runner}" "${statusfile}" "$@"

   wait

   local rval

   rval=0
   if rexekutor grep -v 0 -s -q "${statusfile}"
   then
      log_fluff "A project errored out"
      rval=1
   fi

   remove_file_if_present "${statusfile}"

   return $rval
}


sde_update_main()
{
   log_entry "sde_update_main" "$@"

   local OPTION_RECURSE='YES'

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

         --no-recurse)
            OPTION_RECURSE='NO'
         ;;

         -*)
            sde_update_usage "Unknown option \"$1\""
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

   set_projectname_environment

   # gratuitous optimization ?
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_SDE_LIBEXEC_DIR
   export MULLE_SDE_DIR

   if [ $# -ne 0 ]
   then
      sde_update_worker "${runner}" "'${OPTION_RECURSE}'" "$@"
      return $?
   fi

   local tasks

   tasks="${MULLE_SDE_UPDATE_CALLBACKS//:/ }"
   if [ -z "${tasks}" ]
   then
      log_fluff "Nothing to do as no tasks are configured by MULLE_SDE_UPDATE_CALLBACKS"
      return 0
   fi
   eval sde_update_worker "'${runner}'" "'${OPTION_RECURSE}'" "${tasks}"
}
