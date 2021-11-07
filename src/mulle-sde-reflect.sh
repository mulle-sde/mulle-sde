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
                   header file

Options:
   --craft       : craft after reflect
   --if-needed   : reflect if there was a change in the sourcetree name
   --no-recurse  : do not recurse into subprojects
   --optimistic  : run only those tasks that are needed
   --serial      : don't reflect subprojects in parallel

Return value:
   0 : OK
   1 : Failure
   2 : OK, but sourcetree has changed

Environment:
   MULLE_SDE_REFLECT_CALLBACKS   : default callbacks used for reflect
EOF
   exit 1
}


#
# this just gets "source" and "sourcetree" back 
#
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

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      log_fluff "Forced run of \"${task}\""
   else
      local taskstatus

      taskstatus="`_task_status "${task}"`"
      log_fluff "Last known status of task \"${task}\" is \"${taskstatus}\""

      case "${taskstatus}" in
         "done")
            log_fluff "Skip task"
            return
         ;;
      esac
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

   local parallel="$1"
   local runner="$2"

   shift 2

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
            log_error "A project errored out: ${errors}"
            exit 1
         fi
      fi
   )
}


_sde_reflect_subprojects()
{
   log_entry "_sde_reflect_subprojects" "$@"

   local parallel="$1"
   local runner="$2"

   shift 2

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

   local recurse="$1"
   local if_needed="$2"

   shift 2

   local donefile
   local previous

   # If we have multiple sourcetrees, we want to remember for what sourcetree
   # we reflected. If the sourcetree is "config", which is the default we
   # don't have to remember it. (That means absence of the reflect file
   # indicates a repository with only a single "config" sourcetree!)
   #
   # We persist the reflection and therefore also what the current reflection
   # is, so don't place in var.
   #
   donefile="${MULLE_SDE_ETC_DIR}/reflect"
   previous="`egrep -v '^#' "${donefile}" 2> /dev/null`"

   # remember what we reflected
   #
   # we keep all names, so we can quickly decide if a match happens
   # we don't want to look for sourcetrees individually
   #
   local names

   names="${MULLE_SOURCETREE_CONFIG_NAMES:-config}"
   if [ "${if_needed}" = 'YES' ]
   then
      if [ -z "${previous}" ]
      then
         log_fluff "Nothing needs to be reflected"
         return
      fi

      # if its the same as top pick of names, then we are happy too
      # in a foo:bar:baz scenario, bar loses out and will affect a
      # reflect

      if [ "${previous}" = "${names%%:*}" ]
      then
         log_fluff "Already reflected for \"${previous}\""
         return
      fi
   fi

   log_fluff "Reflect callbacks: \"${MULLE_SDE_REFLECT_CALLBACKS}\""

   if [ "${recurse}" = 'YES' ]
   then
      if ! _sde_reflect_subprojects "$@"
      then
         return 1
      fi
   fi

   if ! _sde_reflect_main "$@"
   then
      return 1
   fi

   #
   # If there is only "config" possible, we don't save anything. Subprojects
   # can't go crazy here! They will have to have the same configs.
   #
   local current_name
   local names

   names="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" config name -a`"
   if [ "${names}" = "config" ]
   then
      remove_file_if_present "${donefile}"
      return 0
   fi

   # this extra call, pains a little
   current_name="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" config name`"

   log_verbose "Remembering \"${current_name}\" as sourcetree"

   # It's also inconvenient for git, if this file timestamp fluctuates.
   # So try to keep it stable.
   #
   if [ "${current_name}" != "${previous}" ]
   then
      r_mkdir_parent_if_missing "${donefile}"

      redirect_exekutor "${donefile}" cat <<EOF
# This file is produced during reflection, when multiple sourcetrees are
# available. You should put it into git.
${current_name}
EOF
      return 2
   fi
}


sde_reflect_main()
{
   log_entry "sde_reflect_main" "$@"

   local OPTION_RECURSE='YES'
   local OPTION_PARALLEL='YES'
   local OPTION_IF_NEEDED='NO'

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
            OPTION_IF_NEEDED='YES'
         ;;

         --optimistic)
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
      sde_reflect_worker "${OPTION_RECURSE}" \
                         "${OPTION_IF_NEEDED}" \
                         "${OPTION_PARALLEL}" \
                         "${runner}" \
                         "$@"
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

   eval sde_reflect_worker "'${OPTION_RECURSE}'" \
                           "'${OPTION_IF_NEEDED}'" \
                           "'${OPTION_PARALLEL}'" \
                           "'${runner}'" \
                           "${tasks}"
}
