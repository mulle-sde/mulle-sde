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
   -d <directory> : project directory to monitor (`pwd -P`)
   -t             : run tests after successful build
   -s <seconds>   : postpone tests amount of seconds (${TEST_DELAY_S}s)
   --install      : install prerequisites
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
         echo "$@" | sed 's,^[^/]*/,,'
         ;;
      *)
         echo "$@"
         ;;
   esac
}


path_without_extension()
{
   echo "$@" | sed 's/\(.*\)\..*/\1/'
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

   local pid_file

   pid_file="${1}"

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

   exekutor mulle-test "${filename}"

   log_fluff "==> Ended test"
}


run_all_tests()
{
   log_entry "run_all_tests" "$@"

   log_fluff "==> Starting tests"

   exekutor mulle-test

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


source_build()
{
   log_entry "source_build" "$@"

   log_fluff "==> Build"

   if [ ! -e "${PROJECT_MAKEFILE}" ]
   then
      log_fail "${PROJECT_MAKEFILE} vanished, nothing to build."
   fi

   remove_old_test_job

   local rval

   if ! exekutor mulle-craft
   then
      return 1
   fi

   if [ "${RUN_TESTS}" = "YES" ]
   then
      if [ -x "${TESTS_DIR}/${TEST_SH}" ]
      then
          add_new_all_tests_job
      fi
   fi
}


source_file_created()
{
   log_entry "source_file_created" "$@"

   if [ ! -z "${MULLE_SDE_DID_UPDATE_SRC}" ]
   then
      log_verbose "==> Update ${MULLE_SDE_FILES_FILE}"

      (
         cd "${PROJECT_DIR}" &&
         exekutor "${MULLE_SDE_DID_UPDATE_SRC}" "${MULLE_SDE_FILES_FILE}" "$@"
      )

      if [ $? -ne 0 ]
      then
         fail "\"${MULLE_SDE_DID_UPDATE_SRC}\" update failed"
      fi
   else
      log_fluff "No update script configured, build will not reflect file additions and removals"
   fi

   source_build
}


source_file_deleted()
{
   log_entry "source_file_deleted" "$@"

   source_file_created "$@"
}


source_file_modified()
{
   log_entry "source_file_modified" "$@"

   local filename

   filename="`basename "$1"`"

   if [ ! -f "${PROJECT_MAKEFILE}" -o "${filename}" = "`basename "${MULLE_SDE_FILES_FILE}"`" ]
   then
      source_file_created "$@"
      return
   fi

   source_build
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


is_source_filename()
{
   log_entry "is_source_filename" "$@"

   local filename="$1"

   case "${filename}" in
      *.c|*.m|*.aam|*.cpp|*.h|*.hpp|*.cpp|${projectfilename}|*.sh)
         return 0
      ;;
   esac

   return 1
}


#
# watch
#
watch_sources()
{
   log_entry "watch_sources" "$@"

   local directory="$1"
   local filename="$2"
   local cmd="$3"

   local projectfilename

   projectfilename="`basename -- "${PROJECT_MAKEFILE}"`"

   if ! is_source_filename "${filename}" && \
      [ "${filename}" != "${projectfilename}" ]
   then
      return
   fi

   local filepath

   filepath="${directory}/${filename}"

   log_fluff "${filepath} changed"

   case "${cmd}" in
      *CREATE*|*MOVED_TO*|*RENAMED*)
         source_file_created "${filepath}"
      ;;
      *DELETE*|*MOVED_FROM*)
         source_file_deleted "${filepath}"
      ;;
      # PLATFORMSPECIFIC:ISFILE is touch apparently (at least on OS X)
      *CLOSE_WRITE*|PLATFORMSPECIFIC:ISFILE|*UPDATED*)
         source_file_modified "${filepath}"
      ;;
   esac
}


watch_tests()
{
   log_entry "watch_tests" "$@"

   local directory="$1"
   local filename="$2"
   local cmd="$3"

   case "${filename}" in
      *.stdout|*.ccdiag|*.stderr|*.m|*.h|*.c|Makefile|*.sh)
         log_verbose "${filepath}"

         case "${cmd}" in
            *CREATE*|*MOVED_TO*|*RENAMED*)
               test_file_created "${directory}/${file}"
            ;;
            *DELETE*|*MOVED_FROM*)
               test_file_deleted "${directory}/${file}"
            ;;
            *CLOSE_WRITE*)
               test_file_modified "${directory}/${file}"
            ;;
         esac
         ;;
   esac
}


watch_directories()
{
   log_entry "watch_directories" "$@"

   local directory="$1"
   local filename="$2"
   local cmd="$3"

   case "${directory}" in
      .*|_*)
      ;;

      *build|*build/*|*build.d|*build.d/*)
      ;;

      *tests/include|*tests/include/*)
      ;;

      *tests*)
         watch_tests "${directory}" "${filename}" "${cmd}"
      ;;
      *)
         watch_sources "${directory}" "${filename}" "${cmd}"
      ;;
   esac
}


check_fswatch()
{
   log_entry "check_fswatch" "$@"

   if is_binary_missing fswatch
   then
      fail "install prerequisite fswatch with mulle-sde-monitor.sh --install"
   fi
}


watch_darwin()
{
   log_entry "watch_darwin" "$@"

   local filepath
   local cmd
   local directory
   local filename

   check_fswatch

   IFS="
"  fswatch -r -x --event-flag-separator : "$@" |
   while read line
   do
      filepath="`echo "${line}" | sed 's/^\(.*\) \(.*\)$/\1/'`"
      cmd="`echo "${line}" | sed 's/^\(.*\) \(.*\)$/\2/' | tr '[a-z]' '[A-Z]'`"

      directory="`dirname "${filepath}"`"
      filename="`basename "${filepath}"`"

      watch_directories "${directory}" "${filename}" "${cmd}"
   done
}


watch_linux()
{
   log_entry "watch_linux" "$@"

   local directory
   local filename
   local cmd
   local owd

   check_fswatch

   owd="`pwd -P`"
   IFS="," inotifywait -r -m -c "$@" |
   while read directory cmd filename
   do
      case "${directory}" in
         ./*)
            remainder="`echo "${directory}" | cut -c2-`"
            directory="${owd}${remainder}"
         ;;
      esac
      watch_directories "${directory}" "${filename}" "${cmd}"
   done
}


watch_other()
{
   log_entry "watch_other" "$@"

   watch_darwin "$@"
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


install_darwin()
{
   log_entry "install_darwin" "$@"

   brew install fswatch
}


install_linux()
{
   log_entry "install_linux" "$@"

   sudo apt-get install inotify-tools
}


install_freebsd()
{
   log_entry "install_freebsd" "$@"

   echo "You have to install
   https://emcrisostomo.github.io/fswatch/
   https://www.mulle-kybernetik.com/software/git/mulle-bootstrap
   (and possibly https://brew.sh)
yourself on this platform" >&2
}


install_other()
{
   log_entry "install_other" "$@"

   install_freebsd
}


setup_script_environment()
{
   log_entry "setup_script_environment" "$@"

   MULLE_SDE_FILES_FILE="${MULLE_SDE_FILES_FILE:-CMakeSourcesAndHeaders.txt}"

   if [ ! -d "${PROJECT_DIR}/.mulle-sde" ]
   then
      fail "There is no .mulle-sde directory here ($PROJECT_DIR)."
   fi

   if [ -z "${MULLE_SDE_DID_UPDATE_SRC}" ]
   then
      filename="${PROJECT_DIR}/.mulle-sde/did-update-src"
      if [ -x "${filename}" ]
      then
         MULLE_SDE_DID_UPDATE_SRC="${filename}"
      fi
   fi

   if [ -z "${MULLE_SDE_DID_UPDATE_SRC}" ]
   then
      log_warning "No update script \"${filename}\" configured.
Will not update \"${MULLE_SDE_FILES_FILE}\""
   else
      if [ -z "`command -v "${MULLE_SDE_DID_UPDATE_SRC}"`" ]
      then
         fail "\${MULLE_SDE_DID_UPDATE_SRC}\" not found."
      fi
   fi
}


###

###  MAIN

###
### parameters and environment variables
###
sde_monitor_main()
{
   log_entry "sde_monitor_main" "$@"

   local TEST_DELAY_S=30
   local RUN_TESTS=

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_monitor_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_monitor_usage
            shift

            cd "$1" || fail "can't change to \"$1\""
         ;;

         -t|--test)
            RUN_TESTS="YES"
         ;;

         --script)
            [ $# -eq 1 ] && sde_monitor_usage
            shift

            MULLE_SDE_DID_UPDATE_SRC="$1"
         ;;

         -s|--sleep)
            shift
            [ $# -eq 0 ] && sde_monitor_usage

            TEST_DELAY_S="$1"
         ;;

         --install)
            shift
            case "`uname`" in
               Darwin)
                  install_darwin
               ;;

               Linux)
                  install_linux
               ;;

               FreeBSD)
                  install_freebsd
               ;;

               *)
               ;;
            esac
            exit $?
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

   PROJECT_DIR="`mulle-sourcetree path`"
   PROJECT_DIR="${PROJECT_DIR:-`pwd -P`}"
   TESTS_DIR="${PROJECT_DIR}/tests"

   MONITOR_PIDFILE="${PROJECT_DIR}/.mulle-sde/.monitor-pid"
   TEST_JOB_PIDFILE="${PROJECT_DIR}/.mulle-sde/.test-pid"


   #
   # TODO: when mulle-build emits info what it is building
   #       this should drive what is being monitored
   #
   setup_script_environment


   prevent_superflous_monitor

   case "${UNAME}" in
      Darwin)
         check_fswatch
      ;;

      Linux)
         check_fswatch
      ;;

      *)
         check_fswatch
      ;;
   esac

   #
   # kick off the process
   #

   log_verbose "==> Kick off with a project update"
   source_file_created "${PROJECT_DIR}"

   log_verbose "==> Start monitoring"
   log_fluff "Edits to your src directory are now monitored."

   log_info "Press [CTRL]-[C] to quit"

   case "${UNAME}" in
      Darwin)
         watch_darwin "${PROJECT_DIR}" "$@"
         ;;

      Linux)
         watch_linux "${PROJECT_DIR}" "$@"
         ;;

      *)
         watch_other "${PROJECT_DIR}" "$@"
         ;;
   esac
}
