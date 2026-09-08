# shellcheck shell=bash
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
MULLE_SDE_REFLECT_SH='included'


sde::reflect::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} reflect [options] ...

   Reflect runs the default list of MULLE_SDE_REFLECT_CALLBACKS defined by the
   environment, unless task names have been given. See
   \`mulle-monitor task create\` for information how to create a custom task
   and callback.

   Typical callbacks for mulle-sde are:

      source     : reflect changes in \"${PROJECT_SOURCE_DIR:-src}\" into makefiles
      sourcetree : reflect library and dependency changes into makefiles and
                   header file

   You can force serial execution of a callback by appending a '@' to its name.
   
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
   MULLE_SDE_REFLECT_CALLBACKS   : callbacks used for reflect (NONE to disable)
   MULLE_SDE_REFLECT_CONFIGS     : colon-separated configs to reflect (empty=legacy)
EOF
   exit 1
}


#
# this just gets "source" and "sourcetree" back 
#
sde::reflect::callback_run()
{
   log_entry "sde::reflect::callback_run" "$@"

   local callback="$1"

   [ -z "${callback}" ] && _internal_fail "callback is empty"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
   MULLE_MONITOR_CALLBACK_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} \
                     callback run "${callback}"
}


sde::reflect::task_run()
{
   log_entry "sde::reflect::task_run" "$@"

   local task="$1"

   [ -z "${task}" ] && _internal_fail "task is empty"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} \
                  task run "${task}"
}


sde::reflect::task_status()
{
   log_entry "sde::reflect::task_status" "$@"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MONITOR:-mulle-monitor}" ${MULLE_TECHNICAL_FLAGS} \
                   task status "${task}"
}

#
# TODO: shouldn't the monitor be able to do this better ?
#
sde::reflect::task_run_if_needed()
{
   log_entry "sde::reflect::task_run_if_needed"  "$@"

   local task="$1"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      log_fluff "Forced run of \"${task}\""
   else
      local taskstatus

      taskstatus="`sde::reflect::task_status "${task}"`"
      log_fluff "Last known status of task \"${task}\" is \"${taskstatus}\""

      case "${taskstatus}" in
         "done")
            log_fluff "Skip task"
            return
         ;;
      esac
   fi

   sde::reflect::task_run "${task}"
}


sde::reflect::task()
{
   log_entry "sde::reflect::task" "$@"

   local runner="$1"
   local name="$2"
   local statusfile="$3"

   local task
   local rc

   task="`sde::reflect::callback_run "${name}"`"
   rc=$?

   if [ $rc -ne 0 ]
   then
      log_fluff "Callback \"${name}\" returned error: $rc"
      if [ ! -z "${statusfile}" ]
      then
         redirect_append_exekutor "${statusfile}" printf "%s\n" "${name};$rc"
      fi
      return $rc
   fi

   if [ ! -z "${task}" ]
   then
      "${runner}" "${task}"
      rc=$?

      if [ $rc -ne 0 ]
      then
         log_fluff "Task \"${task}\" returned error: $rc"
         if [ ! -z "${statusfile}" ]
         then
            redirect_append_exekutor "${statusfile}" printf "%s\n" "${name};$rc"
         fi
         return $rc
      fi
   fi

   return $rc
}


sde::reflect::_main()
{
   log_entry "sde::reflect::_main" "$@"

   local parallel="$1"
   local runner="$2"

   shift 2

   local task
   local name
   local forkit

   #
   # A problem I have is that re-amalgamation triggers a reflect in the
   # inferior projects, which might just be reflecting as we speak due to
   # a staged mpa mulle-sde craft
   #
   if [ $# -eq 1 ]
   then
      sde::reflect::task "${runner}" "$1"
      return $?
   fi


   (
      local statusfile

      if [ "${parallel}" = 'YES' ]
      then
         _r_make_tmp_in_dir "${MULLE_SDE_VAR_DIR}" "reflect"
         statusfile="${RVAL}"
      fi

      for name in "$@"
      do
         if [ ! -z "${name}" ]
         then
            background='YES'

            # some want to run ahead or after these got to serialize
            case "${name}" in 
               *@)
                  name="${name%@}"
                  background='NO'
               ;;
            esac

            if [ "${parallel}" = 'YES' ]
            then
               if [ "${background}" = 'YES' ]
               then
                  sde::reflect::task "${runner}" "${name}" "${statusfile}" &
               else 
                  wait
                  sde::reflect::task "${runner}" "${name}" "${statusfile}"
               fi
            else
               sde::reflect::task "${runner}" "${name}" || exit $?
            fi
         fi
      done

      if [ "${parallel}" = 'YES' ]
      then
         wait

         local errors

         if ! errors="`exekutor cat "${statusfile}" 2> /dev/null`"
         then
            log_error "A parallel reflect process interfered with \"${statusfile}\". Status of reflection is unknown".
            exit 1
         fi

         remove_file_if_present "${statusfile}"

         if [ ! -z "${errors}" ]
         then
            log_error "A project errored out: ${errors}"
            exit 1
         fi
      fi
   )
}


sde::reflect::_subprojects()
{
   log_entry "sde::reflect::_subprojects" "$@"

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

   if [ "${runner}" = "sde::reflect::task_run_if_needed" ]
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

   sde::subproject::map 'Reflecting' "${mode}" "mulle-sde ${flags} reflect ${options} $*"
}


sde::reflect::configure_paths_for_config()
{
   log_entry "sde::reflect::configure_paths_for_config" "$@"

   local config_name="$1"

   local reflectdir
   local projectname

   config_name="${config_name:-config}"
   reflectdir="reflect.${config_name}"
   projectname="${PROJECT_NAME:-project}"

   MULLE_SOURCETREE_TO_CMAKE_DEPENDENCIES_FILE="cmake/${reflectdir}/_Dependencies.cmake"
   MULLE_SOURCETREE_TO_CMAKE_LIBRARIES_FILE="cmake/${reflectdir}/_Libraries.cmake"
   MULLE_MATCH_TO_CMAKE_HEADERS_FILE="cmake/${reflectdir}/_Headers.cmake"
   MULLE_MATCH_TO_CMAKE_SOURCES_FILE="cmake/${reflectdir}/_Sources.cmake"
   MULLE_MATCH_TO_CMAKE_RESOURCES_FILE="cmake/${reflectdir}/_Resources.cmake"

   MULLE_SOURCETREE_TO_C_INCLUDE_FILE="src/${reflectdir}/_${projectname}-include.h"
   MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE="src/${reflectdir}/_${projectname}-include-private.h"
   MULLE_SOURCETREE_TO_C_IMPORT_FILE="src/${reflectdir}/_${projectname}-import.h"
   MULLE_SOURCETREE_TO_C_PRIVATEIMPORT_FILE="src/${reflectdir}/_${projectname}-import-private.h"
   MULLE_SOURCETREE_TO_C_OBJC_DEPS_FILE="DISABLE"
   MULLE_MATCH_TO_C_C_HEADERS_FILE="src/${reflectdir}/_${projectname}-provide.h"
   MULLE_MATCH_TO_C_OBJC_HEADERS_FILE="src/${reflectdir}/_${projectname}-export.h"

   export MULLE_SOURCETREE_TO_CMAKE_DEPENDENCIES_FILE
   export MULLE_SOURCETREE_TO_CMAKE_LIBRARIES_FILE
   export MULLE_MATCH_TO_CMAKE_HEADERS_FILE
   export MULLE_MATCH_TO_CMAKE_SOURCES_FILE
   export MULLE_MATCH_TO_CMAKE_RESOURCES_FILE
   export MULLE_SOURCETREE_TO_C_INCLUDE_FILE
   export MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE
   export MULLE_SOURCETREE_TO_C_IMPORT_FILE
   export MULLE_SOURCETREE_TO_C_PRIVATEIMPORT_FILE
   export MULLE_SOURCETREE_TO_C_OBJC_DEPS_FILE
   export MULLE_MATCH_TO_C_C_HEADERS_FILE
   export MULLE_MATCH_TO_C_OBJC_HEADERS_FILE

   MULLE_SOURCETREE_CONFIG_NAME="${config_name}"
   export MULLE_SOURCETREE_CONFIG_NAME

   log_fluff "Reflecting config \"${config_name}\" into \"${reflectdir}\""
}


sde::reflect::worker()
{
   log_entry "sde::reflect::worker" "$@"

   local recurse="$1"
   local if_needed="$2"

   shift 2

   if [ -z "${PROJECT_UPCASE_IDENTIFIER}" ]
   then
      include "case"

      r_smart_upcase_identifier "${PROJECT_NAME:-local}"
      PROJECT_UPCASE_IDENTIFIER="${RVAL}"
   fi

   [ "${if_needed}" = 'YES' ] && log_fluff "if-needed is handled by task status and environment only"

   log_fluff "Reflect callbacks: \"${MULLE_SDE_REFLECT_CALLBACKS:-}\""

   if [ "${recurse}" = 'YES' ]
   then
      if ! sde::reflect::_subprojects "$@"
      then
         return 1
      fi
   fi

   local configs

   configs="${MULLE_SDE_REFLECT_CONFIGS}"

   if [ -z "${configs}" ]
   then
      #
      # Empty means default single-config behavior: just reflect with
      # whatever the current config is, no path rewriting
      #
      if ! sde::reflect::_main "$@"
      then
         return 1
      fi
   else
      #
      # Multi-config: reflect only the active config. Use
      # `mulle-sde config craft` to iterate over all configs.
      #
      local config_name

      config_name="${MULLE_SOURCETREE_CONFIG_NAME}"
      if [ -z "${config_name}" ]
      then
         case "${configs}" in
            *:*)
               fail "MULLE_SOURCETREE_CONFIG_NAME must be set for multi-config projects"
            ;;

            *)
               config_name="${configs}"
            ;;
         esac
      fi

      sde::reflect::configure_paths_for_config "${config_name}"

      if ! sde::reflect::_main "$@"
      then
         return 1
      fi
   fi
}


sde::reflect::main()
{
   log_entry "sde::reflect::main" "$@"

   local OPTION_RECURSIVE='YES'
   local OPTION_PARALLEL='YES'
   local OPTION_IF_NEEDED='NO'

   local runner

   runner="sde::reflect::task_run"

   export MULLE_SDE_REFLECT_CONFIGS
   #
   # handle options
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::reflect::usage
         ;;

         --if-needed)
            OPTION_IF_NEEDED='YES'
         ;;

         --optimistic)
            runner="sde::reflect::task_run_if_needed"
         ;;

         --no-recursive|--no-recurse)
            OPTION_RECURSIVE='NO'
         ;;

         --no-parallel|--serial)
            OPTION_PARALLEL='NO'
         ;;

         -*)
            sde::reflect::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "sde::subproject"
   include "path"
   include "file"

   # gratuitous optimization ?
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_SDE_LIBEXEC_DIR

   if [ $# -ne 0 ]
   then
      sde::reflect::worker "${OPTION_RECURSIVE}" \
                           "${OPTION_IF_NEEDED}" \
                           "${OPTION_PARALLEL}" \
                           "${runner}" \
                           "$@"
      return $?
   fi

   local tasks

   tasks="${MULLE_SDE_REFLECT_CALLBACKS:-}"

   #
   # A literal "NONE" (any case) explicitly disables reflect callbacks. This
   # is useful for projects that ship without the generated
   # .mulle/share/monitor callbacks (e.g. a fresh CI checkout), where running
   # the callbacks would fail with "callback not found".
   #
   case "${tasks}" in
      NONE|none|None)
         log_fluff "Reflect callbacks explicitly disabled by MULLE_SDE_REFLECT_CALLBACKS=NONE"
         return 0
      ;;
   esac

   tasks="${tasks//:/ }"
   if [ -z "${tasks}" ]
   then
      log_fluff "Nothing to do as no tasks are configured by MULLE_SDE_REFLECT_CALLBACKS"
      return 0
   fi

   log_fluff "Running tasks: ${tasks}"

   eval sde::reflect::worker "'${OPTION_RECURSIVE}'" \
                             "'${OPTION_IF_NEEDED}'" \
                             "'${OPTION_PARALLEL}'" \
                             "'${runner}'" \
                             "${tasks}"
}
