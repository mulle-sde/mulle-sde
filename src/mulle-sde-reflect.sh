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
MULLE_SDE_REFLECT_SH="included"


sde_reflect_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} reflect [options] ...

   Reflect runs the default list of MULLE_SDE_REFLECT_CALLBACKS defined by the
   environment, unless task names have been given. See
   \`mulle-monitor callback\` and \`mulle-monitor task\` for more information.

   Typical callbacks for mulle-sde are:

      source     : reflect changes in \"${PROJECT_SOURCE_DIR}\" into makefiles
      sourcetree : reflect library and dependency changes into makefiles and
                   header files
Options:
   --craft       : craft after reflect
   --if-needed   : check before reflect, if reflection seems unneccessary
   --no-recurse  : do not recurse into subprojects
   --serial      : don't reflect subprojects in parallel

Environment:
   MULLE_SDE_REFLECT_CALLBACKS   : default callbacks used for reflect
EOF
   exit 1
}



_callback_run()
{
   log_entry "_callback_run" "$@"

   local callback="$1"

   [ -z "${callback}" ] && internal_fail "callback is empty"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
   MULLE_MONITOR_CALLBACK_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} \
                     callback run "${callback}"
}


_task_run()
{
   log_entry "_task_run" "$@"

   local task="$1"

   [ -z "${task}" ] && internal_fail "task is empty"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} \
                  task run "${task}"
}


_task_status()
{
   log_entry "_task_status" "$@"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} \
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


_sde_reflect_task()
{
   log_entry "_sde_reflect_task" "$@"

   local runner="$1"
   local name="$2"
   local statusfile="$3"

   local task
   local rval

   task="`_callback_run "${name}"`"
   rval=$?

   if [ $rval -ne 0 ]
   then
      log_fluff "Callback \"${name}\" returned error: $rval"
      if [ ! -z "${statusfile}" ]
      then
         redirect_append_exekutor "${statusfile}" printf "%s\n" "${name};$rval"
      fi
      return $rval
   fi

   if [ ! -z "${task}" ]
   then
      "${runner}" "${task}"
      rval=$?

      if [ $rval -ne 0 ]
      then
         log_fluff "Task \"${task}\" returned error: $rval"
         if [ ! -z "${statusfile}" ]
         then
            redirect_append_exekutor "${statusfile}" printf "%s\n" "${name};$rval"
         fi
         return $rval
      fi
   fi

   return $rval
}


_sde_reflect_main()
{
   log_entry "_sde_reflect_main" "$@"

   local runner="$1" ; shift
   local parallel="$1" ; shift

   local task
   local name

   if [ $# -eq 1 ]
   then
      _sde_reflect_task "${runner}" "$1"
      return $?
   fi

   local statusfile

   (
      if [ "${parallel}" = 'YES' ]
      then
         _r_make_tmp_in_dir "${MULLE_SDE_VAR_DIR}" "up-main"
         statusfile="${RVAL}"
      fi

      for name in "$@"
      do
         if [ ! -z "${name}" ]
         then
            if [ "${parallel}" = 'YES' ]
            then
               _sde_reflect_task "${runner}" "${name}" "${statusfile}"  &
            else
               _sde_reflect_task "${runner}" "${name}" || exit $?
            fi
         fi
      done

      if [ "${parallel}" = 'YES' ]
      then
         wait

         local errors

         errors="`cat "${statusfile}"`" || exit 1
         # remove_file_if_present "${statusfile}"

         if [ ! -z "${errors}" ]
         then
            log_error "A project errored out: `cat "${statusfile}"` "
            exit 1
         fi
      fi
   )
}


_sde_reflect_subprojects()
{
   log_entry "_sde_reflect_subprojects" "$@"

   local runner="$1" ; shift
   local parallel="$1" ; shift

   #
   # reflect source of mulle-sde subprojects only
   #
#   case ":${MULLE_SDE_REFLECT_CALLBACKS}:" in
#      *:source:*)
#      ;;
#
#      *)
#         return
#      ;;
#   esac

   local options

   if [ "${runner}" = "_task_run_if_needed" ]
   then
      options="${options} --if-needed"
   fi

   local flags

   flags="${MULLE_TECHNICAL_FLAGS}"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="${flags} -f"
   fi

   local mode

   mode=""
   if [ "${parallel}" = 'YES' ]
   then
      mode="parallel"
   fi

   sde_subproject_map 'Reflecting' "${mode}" "mulle-sde ${flags} reflect ${options} $*"
}


sde_reflect_worker()
{
   log_entry "sde_reflect_worker" "$@"

   local runner="$1" ; shift
   local recurse="$1" ; shift
   local parallel="$1" ; shift

   log_fluff "Reflect callbacks: \"${MULLE_SDE_REFLECT_CALLBACKS}\""

   if [ "${recurse}" = 'YES' ]
   then
      if ! _sde_reflect_subprojects "${runner}" "${parallel}" "$@"
      then
         return 1
      fi
   fi

   _sde_reflect_main "${runner}" "${parallel}" "$@"
}


sde_reflect_main()
{
   log_entry "sde_reflect_main" "$@"

   local OPTION_RECURSE='YES'
   local OPTION_PARALLEL='YES'

   local runner

   runner="_task_run"
   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_reflect_usage
         ;;

         --if-needed)
            runner="_task_run_if_needed"
         ;;

         --no-recurse)
            OPTION_RECURSE='NO'
         ;;

         --no-parallel|--serial)
            OPTION_PARALLEL='NO'
         ;;

         -*)
            sde_reflect_usage "Unknown option \"$1\""
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

   # gratuitous optimization ?
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_SDE_LIBEXEC_DIR

   if [ $# -ne 0 ]
   then
      sde_reflect_worker "${runner}" "${OPTION_RECURSE}" "${OPTION_PARALLEL}" "$@"
      return $?
   fi

   local tasks

   tasks="${MULLE_SDE_REFLECT_CALLBACKS//:/ }"
   if [ -z "${tasks}" ]
   then
      log_fluff "Nothing to do as no tasks are configured by MULLE_SDE_REFLECT_CALLBACKS"
      return 0
   fi

   log_fluff "Running tasks: ${tasks}"

   eval sde_reflect_worker "'${runner}'" "'${OPTION_RECURSE}'" "'${OPTION_PARALLEL}'" "${tasks}"
}
