#! /usr/bin/env bash
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_MONITOR_SH="included"


sde_monitor_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} monitor [options]

Options:
   -d <dir>       : directory to monitor
   -s <seconds>   : postpone tests amount of seconds (${TEST_DELAY_S}s)
   -t             : run tests after successful build
EOF
   exit 1
}



sde_update_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} update [options]

Options:
   -d <dir>       : directory to monitor
EOF
   exit 1
}


#
# misc handling
#
is_binary_missing()
{
   if which "$1" > /dev/null 2> /dev/null
   then
      return 1
   fi
   return 0
}


# obscure
# this works, when you execute
# get_current_pid in back ticks
#
get_current_pid()
{
   sh -c 'echo $PPID'
}


#
# path handling
#
path_without_first_directory()
{
   case "$@" in
      /*)
         path_without_first_directory `echo "$@" | cut -c2-`
         ;;

      */*)
         echo "$@" | LC_ALL=C sed 's,^[^/]*/,,'
         ;;
      *)
         echo "$@"
         ;;
   esac
}


path_without_extension()
{
   echo "$@" | LC_ALL=C sed 's/\(.*\)\..*/\1/'
}


#
# pid handling
#
get_pid()
{
   log_entry "get_pid" "$@"

   local pid_file="$1"

   cat "${pid_file}" 2> /dev/null
}


does_pid_exist()
{
   log_entry "does_pid_exist" "$@"

   local pid="$1"

   local found

   case "${UNAME}" in
      *)
         found="`ps -xef | grep "${pid}" | grep -v grep`"
      ;;
   esac

   [ ! -z "${found}" ]
}



done_pid()
{
   log_entry "done_pid" "$@"

   local pid_file="$1"

   rm "${pid_file}" 2> /dev/null
}


kill_pid()
{
   log_entry "kill_pid" "$@"

   local pid_file="$1"

   local old_pid

   old_pid="`get_pid "${pid_file}"`"
   if [ ! -z "${old_pid}" ]
   then
      log_verbose "Killing tests with pid: ${old_pid}"
      kill "${old_pid}" 2> /dev/null
   fi

   done_pid "${pid_file}"
}


announce_pid()
{
   log_entry "announce_pid" "$@"

   local pid="$1"
   local pid_file="$2"

   log_verbose "Scheduled tests with pid: ${pid}"
   redirect_exekutor "${pid_file}" echo "${pid}" || exit 1
}


check_pid()
{
   log_entry "check_pid" "$@"

   local pid_file="$1"

   local old_pid

   old_pid="`get_pid "${pid_file}"`"
   if [ -z "$old_pid" ]
   then
      return 1
   fi
   does_pid_exist "${old_pid}"
}


#
# test handling
#
run_test()
{
   log_entry "run_test" "$@"

   local name="$1"
   local filename="$2"

   log_fluff "==> Starting test " "${name}"

   exekutor "${MULLE_SDE_TEST}" "${filename}"

   log_fluff "==> Ended test"
}


run_all_tests()
{
   log_entry "run_all_tests" "$@"

   log_fluff "==> Starting tests"

   exekutor "${MULLE_SDE_TEST}"

   log_fluff "==> Ended tests"
}


remove_old_test_job()
{
   log_entry "remove_old_test_job" "$@"

   kill_pid "${TEST_JOB_PIDFILE}"
}


add_new_all_tests_job()
{
   log_entry "add_new_all_tests_job" "$@"

   remove_old_test_job

   local timestamp

   timestamp=`date +"%s"`
   timestamp=`expr $timestamp + ${TEST_DELAY_S}`

   log_fluff "==> Scheduled tests for" `date -r ${timestamp} "+%H:%M:%S"`
   ( announce_pid `sh -c 'echo $PPID'` "${TEST_JOB_PIDFILE}" ; sleep "${TEST_DELAY_S}" ; run_all_tests "$@" ; done_pid "${TEST_JOB_PIDFILE}" ) &
}


source_craft()
{
   log_entry "source_craft" "$@"

   if [ "${OPTION_TEST}" = "NO" -a "${OPTION_CRAFT}" = "NO" ]
   then
      return
   fi

   log_fluff "==> Craft"

   remove_old_test_job

   local rval

   if [ "${OPTION_CRAFT}" = "YES" ]
   then
      if ! exekutor "${MULLE_SDE_CRAFT}"
      then
         return 1
      fi
      redirect_exekutor "${PROJECT_DIR}/.mulle-sde/run/did_craft" echo "# empty"
   fi

   if [ "${OPTION_TEST}" = "YES" ]
   then
      if [ -x "${TESTS_DIR}/${TEST_SH}" ]
      then
          add_new_all_tests_job
      fi
   fi
}


#
# if sourcetree_config_modified (and by extension MULLE_SDE_DID_UPDATE_SOURCETREE)
# return non-zero, it means that nothing was modified
#
sourcetree_config_modified()
{
   log_entry "sourcetree_config_modified" "$@"

   if [ -z "${MULLE_SDE_DID_UPDATE_SOURCETREE}" ]
   then
      log_fluff "No update script configured, build will not reflect file additions and removals"
      return 1
   fi
   log_verbose "==> Update dependencies"

   (
      cd "${PROJECT_DIR}" &&
      exekutor "${MULLE_SDE_DID_UPDATE_SOURCETREE}" ${MULLE_SDE_DID_UPDATE_SOURCETREE_FLAGS} "$@" &&
      redirect_exekutor "${PROJECT_DIR}/.mulle-sde/run/did-update-sourcetree" echo "# empty"
   )
}


#
# if source_file_created (and by extension MULLE_SDE_DID_UPDATE_SRC)
# return non-zero, it means that nothing was modified
#
source_file_created()
{
   log_entry "source_file_created" "$@"

   if [ -z "${MULLE_SDE_DID_UPDATE_SRC}" ]
   then
      log_fluff "No update script configured, build will not reflect file additions and removals"
      return 1
   fi

   log_verbose "==> Update sources and headers"

   (
      cd "${PROJECT_DIR}" &&
      exekutor "${MULLE_SDE_DID_UPDATE_SRC}" ${MULLE_SDE_DID_UPDATE_SRC_FLAGS} "$@" &&
      redirect_exekutor "${PROJECT_DIR}/.mulle-sde/run/did-update-src" echo "# empty"
   )

   source_craft
}


update()
{
   log_entry "update" "$@"

   log_verbose "Update cmake files"

   sourcetree_config_modified &&
   source_file_created
}


source_file_deleted()
{
   log_entry "source_file_deleted" "$@"

   source_file_created "$@"
}


source_file_modified()
{
   log_entry "source_file_modified" "$@"

   # just rebuild
   source_craft
}


#
# test watch handling
#
test_file_created()
{
   log_entry "test_file_created" "$@"

   local directory="$1"
   local filename="$2"

   local name

   case "${filename}" in
      *.stdout|*.ccdiag|*.stderr|*.h|*.m|*.c)
         name="`path_without_first_directory "${directory}/${filename}"`"
         log_fluff "==> Run test ${name}"
         run_test "${name}" "${directory}/${filename}"
      ;;

      *)
         run_all_tests
      ;;
   esac
}


test_file_deleted()
{
   log_entry "test_file_deleted" "$@"

   test_file_created "$@"
}


test_file_modified()
{
   log_entry "test_file_modified" "$@"

   test_file_created "$@"
}




#
# watch
#
file_action_of_command()
{
   log_entry "file_action_of_command" "$@"

   local cmd="$1"

   case "${cmd}" in
      *CREATE*|*MOVED_TO*|*RENAMED*)
         echo created
      ;;


      *DELETE*|*MOVED_FROM*)
         echo deleted
      ;;

      # PLATFORMSPECIFIC:ISFILE is touch apparently (at least on OS X)
      *CLOSE_WRITE*|PLATFORMSPECIFIC:ISFILE|*UPDATED*|*MODIFY*)
         echo modified
      ;;

      *)
         log_debug "\"${cmd}\" is boring"
         return 1
      ;;
   esac
}


directory_content_type()
{
   log_entry "directory_content_type" "$@"

   local directory="$1"

   case "${directory}" in
      .*|_*)
      ;;

      *build|*build/*|*build.d|*build.d/*)
      ;;

      *tests/include|*tests/include/*)
      ;;

      *tests/lib|*tests/lib/*)
      ;;

      *tests/share|*tests/share/*)
      ;;

      *tests/libexec|*tests/libexec/*)
      ;;

      *tests*)
         echo "test"
      ;;

      *)
         echo "source"
      ;;
   esac
}


_is_source_file()
{
   log_entry "_is_source_file" "$@"

   local filename="$1"

   if [ ! -z "${MULLE_SDE_IS_HEADER_OR_SOURCE}" ]
   then
      if [ "`exekutor "${MULLE_SDE_IS_HEADER_OR_SOURCE}" "${filename}" `" != "YES" ]
      then
         log_debug "\"${filename}\" is not a source or header, so it's boring."
         return 1
      fi
   else
      log_debug "MULLE_SDE_IS_HEADER_OR_SOURCE is not configured. Everything is exciting"
   fi
}


_is_test_file()
{
   log_entry "_is_test_file" "$@"

   local filename="$1"

   if [ ! -z "${MULLE_SDE_IS_TEST_FILE}" ]
   then
      if [ "`exekutor "${MULLE_SDE_IS_TEST_FILE}" "${filename}" `" != "YES" ]
      then
         log_debug "\"${filename}\" is not a test file, so it's boring."
         return 1
      fi
   else
      log_debug "MULLE_SDE_IS_TEST_FILE is not configured. Everything is exciting"
   fi

}


source_changed()
{
   log_entry "source_changed" "$@"

   local directory="$1"
   local filename="$2"
   local cmd="$3"

   local action

   if ! action="`file_action_of_command "${cmd}" `"
   then
      return 1
   fi

   if ! _is_source_file "${filename}"
   then
      return 1
   fi

   echo "source_file_${action}"
}


test_changed()
{
   log_entry "test_changed" "$@"

   local directory="$1"
   local filename="$2"
   local cmd="$3"

   local action

   if ! action="`file_action_of_command "${cmd}" `"
   then
      return 1
   fi

   if ! _is_source_file "${filename}" && ! _is_test_file "${filename}"
   then
      return 1
   fi

   echo "test_file_${action}"
}


check_fswatch()
{
   log_entry "check_fswatch" "$@"

   if ! is_binary_missing fswatch
   then
      return
   fi

   local info

   case "${MULLE_UNAME}" in
      darwin)
         info="brew install fswatch"
      ;;

      linux)
         info="sudo apt-get install inotify-tools"
      ;;

      *)
         info="You have to install
       https://emcrisostomo.github.io/fswatch/
   yourself on this platform"
      ;;
   esac

   fail "To use monitor you have to install the prerequisite \"fswatch\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_EXECUTABLE_NAME} and reenter it."
}


check_inotifywait()
{
   log_entry "check_inotifywait" "$@"

   if ! is_binary_missing inotifywait
   then
      return
   fi

   local info

   case "${MULLE_UNAME}" in
      linux)
         info="sudo apt-get install inotify-tools"
      ;;

      *)
         info="I have no idea where you can get it from."
      ;;
   esac

   fail "To use monitor you have to install the prerequisite \"inotifywait\":
${C_BOLD}${C_RESET}   ${info}
${C_INFO}You then need to exit ${MULLE_EXECUTABLE_NAME} and reenter it."
}


_watch_using_fswatch()
{
   log_entry "_watch_using_fswatch" "$@"

   #
   # Why monitoring stops, when executing a build.
   #
   # This used to be like `fswatch | read -> craft`
   #
   # A general problem was that events are queing up during a build
   # These are filtered out eventually, but it still can be quite a
   # bit of load. Also the pipe in fswatch will fill up and then
   # block. I suspect, that then we are missing all events until the
   # pipe has been drained.
   #
   # Because the craft is run in the reading pipe, there were no
   # parallel builds.
   #
   # Since events are probably lost anyway, it shouldn't matter if we
   # turn off monitoring during a build. If this ever becomes a problem
   # we can memorize the time of the last watch. Then do a find if
   # anything interesting has changed (timestamp), and if yes run an update
   # before monitoring again.
   #
   local filepath
   local cmd
   local contenttype
   local directory
   local filename

   IFS="
"
   while read line
   do
      IFS="${DEFAULT_IFS}"

      filepath="`LC_ALL=C sed 's/^\(.*\) \(.*\)$/\1/' <<< "${line}" `"
      directory="`dirname -- "${filepath}"`"
      contenttype="`directory_content_type "${directory}" `"
      if [ -z "${contenttype}" ]
      then
         continue
      fi

      cmd="`echo "${line}" | LC_ALL=C sed 's/^\(.*\) \(.*\)$/\2/' | tr '[a-z]' '[A-Z]'`"
      filename="`basename -- "${filepath}"`"

      if ! action="`"${contenttype}_changed" "${directory}" "${filename}" "${cmd}" `"
      then
         continue
      fi

      echo "${action}" "'${filepath}'"
      return
   done < <( fswatch -r -x --event-flag-separator : "$@" )  # bashism
   IFS="${DEFAULT_IFS}"
}


watch_using_fswatch()
{
   log_entry "_watch_using_fswatch" "$@"

   local cmd

   while :
   do
      cmd="`_watch_using_fswatch "$@" `"
      log_debug "execute:" "${cmd}"
      eval "${cmd}"
   done
}


_remove_quotes()
{
   LC_ALL=C sed 's/^\"\([^"]*\)\"/\1/' <<< "${1}"
}


_extract_first_field_from_line()
{
   case "${_line}" in
      \"*)
         _field="`LC_ALL=C sed 's/^\"\([^"]*\)\",\(.*\)/\1/' <<< "${_line}" `"
         _line="` LC_ALL=C sed 's/^\"\([^"]*\)\",\(.*\)/\2/' <<< "${_line}" `"
      ;;

      *)
         _field="`LC_ALL=C sed 's/^\([^,]*\),\(.*\)/\1/' <<< "${_line}" `"
         _line="` LC_ALL=C sed 's/^\([^,]*\),\(.*\)/\2/' <<< "${_line}" `"
      ;;
   esac
}


_watch_using_inotifywait()
{
   log_entry "_watch_using_inotifywait" "$@"

   # see watch_using_fswatch comment
   local directory
   local filename
   local contenttype
   local cmd
   local _line
   local _field

   #
   # https://unix.stackexchange.com/questions/166546/bash-cannot-break-out-of-piped-while-read-loop-process-substitution-works
   #
   IFS="
"
   while read _line # directory cmd filename
   do
      IFS="${DEFAULT_IFS}"

      log_debug "${_line}"

      _extract_first_field_from_line
      directory="${_field}"

      contenttype="`directory_content_type "${directory}" `"
      if [ -z "${contenttype}" ]
      then
         continue
      fi

      _extract_first_field_from_line
      cmd="${_field}"
      filename="`_remove_quotes "${_line}" `"

      if ! action="`"${contenttype}_changed" "${directory}" "${filename}" "${cmd}" `"
      then
         continue
      fi

      local filepath

      filepath="` filepath_concat "${directory}" "${filename}" `"
      echo "${action}" "'${filepath}'"
      return
   done < <( inotifywait -q -r -m -c "$@" )  # bashism

   IFS="${DEFAULT_IFS}"
}


watch_using_inotifywait()
{
   log_entry "watch_using_inotifywait" "$@"

   local cmd

   while :
   do
      cmd="`_watch_using_inotifywait "$@" `"
      log_debug "execute:" "${cmd}"
      eval "${cmd}"
   done
}


cleanup()
{
   log_entry "cleanup" "$@"

   if [ -f "${MONITOR_PIDFILE}" ]
   then
      log_fluff "==> Cleanup"

      remove_old_test_job
      rm "${MONITOR_PIDFILE}" 2> /dev/null
   fi

   log_fluff "==> Exit"
   exit 1
}


prevent_superflous_monitor()
{
   log_entry "prevent_superflous_monitor" "$@"

   if check_pid "${MONITOR_PIDFILE}"
   then
      log_error "Another monitor seems to be already running in ${PROJECT_DIR}" >&2
      log_info  "If this is not the case:" >&2
      log_info  "   rm \"${MONITOR_PIDFILE}\"" >&2
      exit 1
   fi

   #
   # unconditionally remove this
   #
   if [ "${RUN_TESTS}" = "YES" ]
   then
      rm "${TEST_JOB_PIDFILE}" 2> /dev/null
   fi

   trap cleanup 2 3
   announce_pid $$ "${MONITOR_PIDFILE}"
}


check_mulle_sde_tool()
{
   local variable="$1"
   local filename="$2"
   local scripttype="$3"

   local value
   local filepath

   #
   # Scripts to run when files change
   # Could make this configurable in the future, but for now just hardcode
   # it
   #
   value="` eval "echo \\$${variable}" `"
   if [ -z "${value}" ]
   then
      filepath="${MULLE_VIRTUAL_ROOT}/.mulle-sde/bin/${filename}"
      if [ -x "${filepath}" ]
      then
         value="${filepath}"
      else
         log_warning "No executable ${scripttype} \"${filename}\" found."
         return 1
      fi
   fi

   if [ -z "`command -v "${value}"`" ]
   then
      fail "\"${value}\" for \"${variable}\" is missing."
   fi

   echo "${value}"
}


setup_script_environment()
{
   log_entry "setup_script_environment" "$@"

   if [ ! -d "${PROJECT_DIR}/.mulle-sde" ]
   then
      fail "There is no \".mulle-sde\" directory here ($PROJECT_DIR).
You must run ${C_RESET}${C_BOLD}${MULLE_EXECUTABLE_NAME} init${C_ERROR} first"
   fi

   #
   # mulle-craft and mulle-test can be substituted with something else if so
   # desired (make make ?)
   #
   local filepath

   if [ "${OPTION_CRAFT}" = "YES" ]
   then
      MULLE_SDE_CRAFT="${MULLE_SDE_CRAFT:-mulle-craft}"
      filepath="`command -v "${MULLE_SDE_CRAFT}" `"
      [ -z "${filepath}" ] && fail "Desired crafter \"${MULLE_SDE_CRAFT}\" not in PATH"
      MULLE_SDE_CRAFT="${filepath}"
   fi

   if [ "${OPTION_TEST}" = "YES" ]
   then
      MULLE_SDE_TEST="${MULLE_SDE_TEST:-mulle-test}"
      filepath="`command -v "${MULLE_SDE_TEST}" `"
      [ -z "${filepath}" ] && fail "Desired tester \"${MULLE_SDE_TEST}\" not in PATH"
      MULLE_SDE_TEST="${filepath}"
   fi

   #
   # Scripts to run when files change
   # Could make this configurable in the future, but for now just hardcode
   # it
   #
   MULLE_SDE_DID_UPDATE_SRC="`check_mulle_sde_tool MULLE_SDE_DID_UPDATE_SRC  \
                                                   "did-update-src" \
                                                   "source update"`" || exit 1

   MULLE_SDE_DID_UPDATE_SOURCETREE="`check_mulle_sde_tool MULLE_SDE_DID_UPDATE_SOURCETREE  \
                                                          "did-update-sourcetree" \
                                                          "sourcetree update" `" || exit 1

   MULLE_SDE_IS_HEADER_OR_SOURCE="`check_mulle_sde_tool MULLE_SDE_IS_HEADER_OR_SOURCE \
                                                        "is-header-or-source" \
                                                        "filetype recognizer" `" || exit 1

   MULLE_SDE_IS_TEST_FILE="`check_mulle_sde_tool MULLE_SDE_IS_TEST_FILE \
                                                 "is-test-file" \
                                                 "test-file recognizer" `" || exit 1

   # export as benefit to these scripts, that may want to use our libraries
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_SDE_LIBEXEC_DIR
}


###

###  MAIN

###
sde_monitor_main()
{
   log_entry "sde_monitor_main" "$@"

   local TEST_DELAY_S=30
   local RUN_TESTS=
   local OPTION_ONCE="NO"

   local OPTION_TEST="NO"
   local OPTION_CRAFT="YES"
   local OPTION_INITIAL_UPDATE="YES"
   local OPTION_INITIAL_CRAFT="YES"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_monitor_usage
         ;;

         -1|--once)
            OPTION_ONCE="YES"
         ;;

         --craft)
            OPTION_CRAFT="YES"
            OPTION_INITIAL_CRAFT="YES"
         ;;

         --no-craft)
            OPTION_CRAFT="NO"
            OPTION_INITIAL_CRAFT="NO"
         ;;

         -t|--test)
            OPTION_TEST="YES"
         ;;

         --no-test)
            OPTION_TEST="NO"
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_monitor_usage
            shift

            PROJECT_DIR="$1"
         ;;

         --src-script)
            [ $# -eq 1 ] && sde_monitor_usage
            shift

            MULLE_SDE_DID_UPDATE_SRC="$1"
         ;;

         --sourcetree-script)
            [ $# -eq 1 ] && sde_monitor_usage
            shift

            MULLE_SDE_DID_UPDATE_SOURCETREE="$1"
         ;;

         -s|--sleep)
            shift
            [ $# -eq 0 ] && sde_monitor_usage

            TEST_DELAY_S="$1"
         ;;

         -*)
            sde_monitor_usage
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   PROJECT_DIR="${PROJECT_DIR:-`mulle-sourcetree path`}"
   PROJECT_DIR="${PROJECT_DIR:-`pwd -P`}"
   TESTS_DIR="${PROJECT_DIR}/tests"

   mkdir_if_missing "${PROJECT_DIR}/.mulle-sde/run"

   MONITOR_PIDFILE="${PROJECT_DIR}/.mulle-sde/run/monitor-pid"
   TEST_JOB_PIDFILE="${PROJECT_DIR}/.mulle-sde/run/monitor-test-pid"


   #
   # TODO: when mulle-build emits info what it is building
   #       this should drive what is being monitored
   #
   setup_script_environment

   #
   # kick off the process
   #
   local rval

   rval=0
   log_verbose "==> Kick off with a project update"

   if [ "${OPTION_INITIAL_UPDATE}" = "YES" ]
   then
      log_fluff "Run an initial update of cmake files"
      update "${PROJECT_DIR}" || return 1
   fi

   if [ "${OPTION_INITIAL_CRAFT}" = "YES" ]
   then
      log_fluff "Run an initial craft step"
      source_craft
      rval=$?
   fi

   if [ "${OPTION_ONCE}" = "YES" ]
   then
      return $rval
   fi

   #
   # Memo: Changes between update and  watch_using_fswatch
   # will not be registered. Can't imagine this to ever become a problem.
   #
   case "${MULLE_UNAME}" in
      linux)
         check_inotifywait
      ;;

      *)
         check_fswatch
      ;;
   esac

   prevent_superflous_monitor

   log_verbose "==> Start monitoring"
   log_fluff "Edits to your src directory are now monitored."

   log_info "Press [CTRL]-[C] to quit"

   case "${MULLE_UNAME}" in
      linux)
         watch_using_inotifywait "${PROJECT_DIR}" "$@"
      ;;

      *)
         watch_using_fswatch "${PROJECT_DIR}" "$@"
      ;;
   esac
}
