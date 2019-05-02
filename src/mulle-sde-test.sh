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
   ${MULLE_USAGE_NAME} test <command>

   Run tests. Use 'init' to get started. Build the library to test with "build"
   and redo this step everytime you change the library. Run tests with "run"
   and everytime you change the tests.

Command:
   init     : initialize a test directory
   generate : generate some simple test files (Objective-C only)
   craft    : craft library
   recraft  : re-craft library and dependencies
   run      : run tests
   rerun    : rerun failed tests

Environment:
   MULLE_SDE_TEST_PATH : test directories to run (test)
EOF
   exit 1
}


sde_test_run()
{
   log_entry "sde_test_run" "$@"

   local cmd="$1"

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-.}"

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   [ -z "${MULLE_FILE_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

   IFS=":"
   for directory in ${MULLE_SDE_TEST_PATH}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -d "${directory}" ]
      then
         fail "Test directory \"${directory}\" is missing"
      fi

      if ! (
         log_info "Tests ${C_MAGENTA}${C_BOLD}${cmd}${C_INFO} (${C_RESET_BOLD}${directory#${MULLE_USER_PWD}/}${C_INFO})"

         #
         # execute with mudo to use regular path and not pickup stuff
         # from parent.
         #
         MULLE_VIRTUAL_ROOT=""
         exekutor cd "${directory}" &&
         exekutor mudo mulle-test ${MULLE_TECHNICAL_FLAGS} \
                                  ${MULLE_TEST_FLAGS} \
                                  "$@"
      )
      then
         return 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


r_sde_test_githubname()
{
   log_entry "r_sde_test_githubname" "$@"

   if [ ! -z "${PROJECT_GITHUB_NAME}" ]
   then
      RVAL="${PROJECT_GITHUB_NAME}"
      return
   fi

   #
   # assume structure is mulle-c/mulle-allocator and we are
   # right in mulle-allocator, use mulle-c as github name,
   # unless its prefixed with "src"
   #
   local name
   local filtered
   local directory

   # clumsy fix if called from test directory
   directory="${PWD}"
   r_fast_basename "${directory}"
   case "${RVAL}" in
      test*)
         r_fast_dirname "${directory}"
         directory="${RVAL}"
      ;;
   esac

   r_fast_dirname "${directory}"
   r_fast_basename "${RVAL}"
   name="${RVAL}"

   # github don't like underscores, so we adapt here
   name="`tr '_' '-' <<< "${name}"`"

   # is it a github identifier (engl.) ?
   filtered="`tr -d -c 'A-Z0-9a-z-' <<< "${name}"`"
   if [ "${filtered}" = "${name}" ]
   then
      case "${name}" in
         ""|src*|-*|*-)
         ;;

         *)
         RVAL="${name}"
         return
      esac
   fi

   RVAL="${LOGNAME:-unknown}"
   return
}

sde_test_generate()
{
   log_entry "sde_test_run" "$@"

   local cmd="$1"
   local flags

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="-f"
   fi

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   IFS=":"
   for directory in ${MULLE_SDE_TEST_PATH}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -d "${directory}" ]
      then
         fail "Test directory \"${directory}\" is missing"
      fi

      exekutor mulle-objc-testgenerator \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_TESTGENERATOR_FLAGS} \
                        ${flags} \
                     -d "${directory}" \
                     "$@"
      return $?
   done
   IFS="${DEFAULT_IFS}"
}


#
# Problem: if you start mulle-sde test inside the project folder
#          it will pickup the environment there including PATH and
#          the tests inherits it. If you start the test in the test
#          folder, it only has its own environment.
#          Need a solution to cleanly exit from one environment and
#          move to next in a script. Or make test environments
#          very restrictive.
#
sde_test_main()
{
   log_entry "sde_test_main" "$@"

   local cmd

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_test_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   cmd="$1"
   case "${cmd}" in
      ""|/*|.*)
         cmd="run"
      ;;

      craft|build|recraft|rebuild|clean|init|run|libexec-dir|test-dir|version)
         shift;
      ;;
      *)
         if [ -e "${MULLE_USER_PWD}/${cmd}" ]
         then
            cmd="run"
         else
            shift
         fi
      ;;
   esac


   case "${cmd}" in
      -*)
         sde_test_run run "${cmd}" "$@"
      ;;

      build|craft|clean|rebuild|recraft|rerun|run|test)
         sde_test_run "${cmd}" "$@"
      ;;

      generate)
         sde_test_generate "$@"
      ;;

      github-name)
         r_sde_test_githubname
         echo "${RVAL}"
      ;;

      init)
         r_sde_test_githubname

         local flag

         if [ -f ${MULLE_VIRTUAL_ROOT}/cmake/share/StandaloneC.cmake ]
         then
            flag="--standalone"
         fi

         exekutor mulle-test \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_TEST_FLAGS} \
                     init \
                        --github-name "${RVAL}" \
                        ${flag} \
                        "$@"
      ;;

      *)
         sde_test_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
