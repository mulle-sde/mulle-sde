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
MULLE_SDE_TEST_SH="included"


sde_test_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} test [options] <command>

   Tests are run in their own mulle-sde environment. The library to test
   is just another dependency to the test project.

   Use \`init\` to get started. Build the library to test with \`craft\`.
   Run tests with "run". Rerun failing tests with \`rerun\`.

   Use \`clean tidy\` to get rid of all fetched dependencies. Use \`clean all\`
   to rebuild everything.

Options:
   See \`mulle-test help\` for options

Command:
   clean      : clean tests and or dependencies
   craft      : craft library
   craftorder : show order of dependencies being crafted
   crun       : craft and run
   generate   : generate some simple test files (Objective-C only)
   init       : initialize a test directory
   linkorder  : show library command for linking test executable
   recraft    : re-craft library and dependencies
   rerun      : rerun failed tests
   run        : run tests only
   test-dir   : list test directories

Environment:
   MULLE_SDE_TEST_PATH : test directories to run (test)
EOF
   exit 1
}


sde_test_generate_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} test generate

   Generate tests with mulle-testgen. Look there for more info.
EOF
   exit 1
}


sde_hack_test_environment()
{
   log_entry "sde_hack_test_environment" "$@"

   #
   # hackish undo some stuff, because we are probably entering a
   # wild environment
   #
   local pattern

   r_escaped_grep_pattern "${MULLE_VIRTUAL_ROOT}"
   pattern="${MULLE_VIRTUAL_ROOT}"

   unset MULLE_VIRTUAL_ROOT
   unset ADDICTION_DIR
   unset KITCHEN_DIR
   unset DEPENDENCY_DIR
   unset MULLE_FETCH_SEARCH_PATH

   if [ ! -z "${pattern}" ]
   then
      local problems

      problems="`env | egrep -v '^PATH=|^MULLE_USER_PWD=|^PWD=|^OLDPWD=' | grep -e grep -e "${pattern}"`"
      if [ ! -z "${problems}" ]
      then
         log_warning "These environment variables may or may not be problematic, as this is a \"wild\" environment."
         printf "%s\n" "${problems}" >&2
      fi
   fi
}


sde_test_generate()
{
   log_entry "sde_test_generate" "$@"

   local cmd="$1"
   local flags
   local OPTION_FULL_TEST='NO'


   while :
   do
      case "$1" in
         -h|--help|help)
            sde_test_generate_usage
         ;;

         -f|--full)
            OPTION_FULL_TEST='YES'
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="-f"
   fi


   log_info "Ensure mulle-testgen is accessible in environment"

   if ! rexekutor mulle-env ${MULLE_TECHNICAL_FLAGS} tool get mulle-testgen > /dev/null
   then
      exekutor mulle-env ${MULLE_TECHNICAL_FLAGS} -s tool add --optional mulle-testgen || exit 1
      exekutor mulle-env ${MULLE_TECHNICAL_FLAGS} tool link || exit 1
   fi

   MULLE_TESTGEN="${MULLE_TESTGEN:-`command -v mulle-testgen`}"
   if [ -z "${MULLE_TESTGEN}" ]
   then
      fail "mulle-testgen not found in PATH."
   fi

   log_info "Craft library for test generation"

   exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} craft || exit 1

   local rval

   IFS=':'
   for directory in ${MULLE_SDE_TEST_PATH}
   do
      IFS="${DEFAULT_IFS}"

      mkdir_if_missing "${directory}"

      exekutor "${MULLE_TESTGEN}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_TESTGENERATOR_FLAGS} \
                        ${flags} \
                     generate \
                     -d "${directory}/00_noleak" \
                     "$@"
      rval=$?

      if [ $rval -eq 0 -a "${OPTION_FULL_TEST}" = 'YES' ]
      then
         exekutor "${MULLE_TESTGEN}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_TESTGENERATOR_FLAGS} \
                           ${flags} \
                        generate \
                        -d "${directory}/10_init" \
                        -1 \
                        -i &&
         exekutor "${MULLE_TESTGEN}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_TESTGENERATOR_FLAGS} \
                           ${flags} \
                        generate \
                        -d "${directory}/20_property" \
                        -1 \
                        -p &&
         exekutor "${MULLE_TESTGEN}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_TESTGENERATOR_FLAGS} \
                           ${flags} \
                        generate \
                        -d "${directory}/20_method" \
                        -1 \
                        -m
         rval=$?
      fi

      if [ rval != 0 ]
      then
         return $rval
      fi
   done
   IFS="${DEFAULT_IFS}"
}



#
# Execute command in the test environment
#
_sde_test_run()
{
   log_entry "_sde_test_run" "$@"

   local directory="$1"; shift
   local cmd="$1"; shift

   physdir="`physicalpath "${directory}"`"

   #
   # We need to pass -Ddefine variables to mulle-test
   #
   (
      log_info "Tests ${C_MAGENTA}${C_BOLD}${cmd} $*${C_INFO} (${C_RESET_BOLD}${directory#${MULLE_USER_PWD}/}${C_INFO})"

      exekutor cd "${physdir}" || exit 1

      #
      # Case 1: we are outside the environment
      # Case 2: we are in the wrong environment
      # Case 3: we are in the right environment
      #
      if [ -z "${MULLE_VIRTUAL_ROOT}" -o  "${MULLE_VIRTUAL_ROOT}" != "${physdir}" ]
      then
         local cmdline

         cmdline="mulle-test"
         for arg in ${MULLE_TECHNICAL_FLAGS}
         do
            r_add_line "${cmdline}" "${arg}"
            cmdline="${RVAL}"
         done

         r_add_line "${cmdline}" "${cmd}"
         cmdline="${RVAL}"

         while [ $# -ne 0 ]
         do
            r_add_line "${cmdline}" "$1"
            cmdline="${RVAL}"
            shift
         done

         run_mulle_env -C "${cmdline}"
         return $?
      fi

      mulle-test ${MULLE_TECHNICAL_FLAGS} "${cmd}" "$@"
   )
}


sde_test_run()
{
   log_entry "sde_test_run" "$@"

   local harmeless='$1'; shift
   local cmd="$1"; shift

   local defaultpath
   local projectdir

   projectdir="`mulle-sde project-dir`"
   if [ ! -z "${projectdir}" ]
   then
      exekutor cd "${projectdir}"
   fi

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   [ -z "${MULLE_FILE_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

   (
      sde_hack_test_environment

      if is_test_directory "."
      then
         _sde_test_run "." "${cmd}" "$@"
         exit $?
      fi

      IFS=":"
      for directory in ${MULLE_SDE_TEST_PATH}
      do
         IFS="${DEFAULT_IFS}"

         if [ ! -d "${directory}" ]
         then
            if [ "${harmless}" = 'NO' ]
            then
               fail "Test directory \"${directory}\" is missing"
            fi
            continue
         fi

         if ! is_test_directory "${directory}"
         then
            if [ "${harmless}" = 'NO' ]
            then
               fail "Directory \"${directory}\" is not a test directory"
            fi
            continue
         fi

         if ! _sde_test_run "${directory}" "${cmd}" "$@"
         then
            exit 1
         fi
      done
   )
}


sde_test_path_environment()
{
   log_entry "sde_test_path_environment" "$@"

   MULLE_SDE_TEST_PATH="`rexekutor mulle-env -s environment get MULLE_SDE_TEST_PATH`"
   if is_test_directory "."
   then
      MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-.}"
   else
      MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"
   fi
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "MULLE_SDE_TEST_PATH=${MULLE_SDE_TEST_PATH}"
   fi
}


#
# Problem: if you start mulle-sde test inside the project folder
#          it will pickup the environment there including PATH and
#          the tests inherits it. If you start the test in the test
#          folder, it only has its own environment.
#
#          Need a solution to cleanly exit from one environment and
#          move to next in a script. Or make test environments
#          very restrictive.
#
# This function may or not be running in a subshell! It will not have been
# forced into a subshell.
#
r_sde_test_main()
{
   log_entry "r_sde_test_main" "$@"

   local rval

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_test_usage
         ;;

         -*)
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde_test_path_environment

   RVAL=""
   case "${1}" in
      "")
         RVAL='DEFAULT'
         return 1
      ;;

      /*|.*)
         RVAL='RUN'
         return 1
      ;;

      # build commands
      clean|crun|craft|build|craftorder|linkorder|log|rebuild|recraft|recrun|rerun|run)
         RVAL='DEFAULT'
         return 1;
      ;;

      # introspection, no test dir needed
      env|test-dir)
         RVAL='HARMLESS'
         return 1;
      ;;

      libexec-dir|version)
         rexekutor mulle-test ${MULLE_TECHNICAL_FLAGS} "$1" "$@"
         rval=$?
         RVAL="DONE"
         return $rval
      ;;

      # no environment needed to run these properly
      generate)
         shift
         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exec_command_in_subshell test generate "$@"
         else
            sde_test_generate "$@"
         fi
         rval=$?
         RVAL="DONE"
         return $rval
      ;;


      # no environment needed to run these properly
      init)
         shift
         exekutor mulle-test \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_TEST_FLAGS} \
                     init \
                        "$@"
         rval=$?
         RVAL="DONE"
         return $rval
      ;;

      *)
         RVAL='RUN'
         return 1
      ;;
   esac
}


sde_test_main()
{
   log_entry "sde_test_main" "$@"

   local rval

   r_sde_test_main "$@"
   rval=$?

   if [ $rval -eq 1 ]
   then
      case "${RVAL}" in
         "DONE")
         ;;

         'DEFAULT')
            sde_test_run 'NO' "$@"
            rval=$?
         ;;

         'HARMLESS')
            sde_test_run 'YES' "$@"
            rval=$?
         ;;

         'RUN')
            sde_test_run 'NO' run "$@"
            rval=$?
         ;;
      esac
   fi

   return $rval
}
