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
MULLE_SDE_TEST_SH='included'


sde::test::usage()
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

   mulle-test can generate coverage information and supports various sanitizers
   such as valgrind. Try for example:

   ${MULLE_USAGE_NAME} test coverage --mulle cov.html

Options:
   See \`mulle-test help\` for options

Command:
   clean      : clean tests and or dependencies
   craft      : craft library
   craftorder : show order of dependencies being crafted
   coverage   : do a coverage run
   crun       : craft and run
   generate   : generate some simple test files (Objective-C only)
   init       : initialize a test directory
   linkorder  : show library command for linking test executable
   recraft    : re-craft library and dependencies
   rerun      : rerun failed tests
   retest     : clean gravetidy and then craft and run tests once more
   run        : run tests only
   test-dir   : list test directories

Environment:
   MULLE_TEST_DIR          : tests directory (test)
   MULLE_TEST_OBJC_DIALECT : use mulle-objc for mulle-clang
   PROJECT_DIALECT         : dialect of the tests, can be objc
   PROJECT_EXTENSIONS      : file extensions of the test files
   PROJECT_LANGUAGE        : language of the tests (c)

EOF
   exit 1
}


sde::test::generate_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} test generate

   Generate tests with mulle-testgen. Look there for more info.
EOF
   exit 1
}


sde::test::coverage_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} coverage [options] ...

   Generate coverage output. By default gcovr is used. Unknown options and all
   remaining arguments are forwarded to the coverage tool.

  The coverage command performs four steps in sequence:

      * clean   rebuild dependencies (without coverage information)
      * craft   rebuild library with coverage information
      * run     run tests with coverage information
      * show    show coverage results

   You need to \`mulle-sde test clean all\` before running tests without
   coverage information again.

Options:
      --craft    : skips step "clean"
      --gcov     : use gcov instead of gcovr
      --lines    : run --json and extract lines of code field (needs jq)
      --mulle    : create "coverage.html" with mulle style gcovr options
      --no-run   : stop after "run"
      --percent  : run --json and extract coverage percentage (needs jq)
      --rerun    : skips steps "clean" and "craft" then reruns failed tests
      --run      : skips steps "clean" and "craft"
      --run      : skips steps "clean" and "craft" then runs all tests
      --show     : skips steps "clean" to "run"
      --tool <t> : use tool t instead of gcovr
      --         : pass remaining options to gcovr

EOF
   exit 1
}


sde::test::hack_environment()
{
   log_entry "sde::test::hack_environment" "$@"

   #
   # hackish undo some stuff, because we are probably entering a
   # wild environment
   #
   local pattern

   r_escaped_grep_pattern "${MULLE_VIRTUAL_ROOT}"
   pattern="${MULLE_VIRTUAL_ROOT}"

   unset ADDICTION_DIR
   unset DEPENDENCY_DIR
   unset KITCHEN_DIR
   unset MULLE_FETCH_SEARCH_PATH
   unset MULLE_VIRTUAL_ROOT
   #  unset MULLE_TECHNICAL_FLAGS

   #
   # if terse, we don't get the warning and just the printf and it's
   # confusing
   #
   if [ ! -z "${pattern}" -a "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
   then
      local problems

      problems="`env \
                 | grep -E -v '^PATH=|^MULLE_USER_PWD=|^PWD=|^OLDPWD=' \
                 | grep -e "${pattern}" `"
      if [ ! -z "${problems}" ]
      then
         _log_warning "These environment variables may or may not be \
problematic, as this is a \"wild\" environment."
         printf "%s\n" "${problems}" >&2
      fi
   fi
}


sde::test::generate()
{
   log_entry "sde::test::generate" "$@"

   local cmd="$1"
   local flags
   local OPTION_FULL_TEST='NO'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::test::generate_usage
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
sde::test::_run()
{
   log_entry "sde::test::_run" "$@"

   local directory="$1"
   local cmd="$2"

   shift 2

   r_physicalpath "${directory}"
   physdir="${RVAL}"

   #
   # We need to pass -Ddefine variables to mulle-test
   #
   (
      r_concat "${cmd}" "$*"
      r_concat "Tests" "${RVAL}"
      r_concat "${RVAL}" "(${C_RESET_BOLD}${directory#"${MULLE_USER_PWD}/"}${C_INFO})"

      log_info "${RVAL}"

      exekutor cd "${physdir}" || exit 1

      #
      # Case 1: we are outside the environment
      # Case 2: we are in the wrong environment
      # Case 3: we are in the right environment
      #
      if [ ! -z "${MULLE_VIRTUAL_ROOT}" -a "${MULLE_VIRTUAL_ROOT}" = "${physdir}" ]
      then
         rexekutor "${MULLE_TEST:-mulle-test}" ${MULLE_TECHNICAL_FLAGS} "${cmd}" "$@"
         exit $?
      fi

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

      sde::run_mulle_env -C "${cmdline}"
   )
}


sde::test::run()
{
   log_entry "sde::test::run" "$@"

   local harmless="$1"
   shift 1

   local cmd

   if [ $# -ne 0 ]
   then
      cmd="$1"
      shift
   fi

   local defaultpath
   local projectdir

   projectdir="`"${MULLE_SDE:-mulle-sde}" project-dir 2> /dev/null`"
   if [ ! -z "${projectdir}" ]
   then
      exekutor cd "${projectdir}"
   fi

   include "path"
   include "file"

   (
      sde::test::hack_environment

      if sde::is_test_directory "."
      then
         sde::test::_run "." "${cmd}" "$@"
         exit $?
      fi

      .foreachpath directory in ${MULLE_SDE_TEST_PATH}
      .do
         if [ ! -d "${directory}" ]
         then
            if [ "${harmless}" = 'NO' ]
            then
               fail "Test directory \"${directory}\" is missing"
            fi
            .continue
         fi

         if ! sde::is_test_directory "${directory}"
         then
            if [ "${harmless}" = 'NO' ]
            then
               fail "Directory \"${directory}\" is not a test directory"
            fi
            .continue
         fi

         if ! sde::test::_run "${directory}" "${cmd}" "$@"
         then
            exit 1
         fi
      .done
   )
}


sde::test::coverage()
{
   log_entry "sde::test::coverage" "$@"

   local OPTION_CLEAN='YES'
   local OPTION_CRAFT='YES'
   local OPTION_RUN='YES'
   local OPTION_SHOW='YES'
   local OPTION_JQ='NO'
   local OPTION_GCOV='gcovr'
   local RUN_CMD="run"

   local CRAFT_RUN_FLAGS
   local GCOV_FLAGS
   local JQ_KEY

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|help|--help)
            sde::test::coverage_usage
         ;;

         --craft|--recraft|--no-clean)
            OPTION_CLEAN='NO'
         ;;

         --gcov|--gcovr)
            OPTION_GCOV="${1#--}"
         ;;

         --json)
            GCOV_FLAGS="--json-summary-pretty"
         ;;

         --lines|--loc|--lines-of-code)
            GCOV_FLAGS="--json-summary-pretty"
            JQ_KEY="line_total"
            OPTION_JQ='YES'
         ;;

         --mulle)
            GCOV_FLAGS="--html-self-contained --html-details coverage.html"
         ;;

         --serial|--no-parallel|--parallel)
            r_concat "${CRAFT_RUN_FLAGS}" "$1"
            CRAFT_RUN_FLAGS="${RVAL}"
         ;;

         --no-clean)
            OPTION_CLEAN='NO'
         ;;

         --no-craft)
            OPTION_CRAFT='NO'
         ;;

         --no-run)
            OPTION_RUN='NO'
         ;;

         --no-show)
            OPTION_SHOW='NO'
         ;;

         --no-jq)
            OPTION_JQ='NO'
         ;;

         --percent|--percentage)
            GCOV_FLAGS="--json-summary-pretty"
            JQ_KEY="line_percent"
            OPTION_JQ='YES'
         ;;

         --run|--no-craft)
            OPTION_CLEAN='NO'
            OPTION_CRAFT='NO'
         ;;

         --rerun)
            OPTION_CLEAN='NO'
            OPTION_CRAFT='NO'
            RUN_CMD="rerun"
         ;;

         --show)
            OPTION_CLEAN='NO'
            OPTION_CRAFT='NO'
            OPTION_RUN='NO'
         ;;

         --tool)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift
            OPTION_GCOV="$1"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::craft::usage "Unknown option \"$1\", use -- to pass arguments to mulle-test"
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   (
      local projectdir

      projectdir="`"${MULLE_SDE:-mulle-sde}" project-dir 2> /dev/null`"
      if [ ! -z "${projectdir}" ]
      then
         exekutor cd "${projectdir}"
      fi

      local jsonfile

      if [ "${OPTION_JQ}" = 'YES' ]
      then
         local testdir

         testdir="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} -s test test-dir | head -1`"
         r_filepath_concat "${testdir}" "coverage.json"
         jsonfile="${RVAL}"

         GCOV_FLAGS="${GCOV_FLAGS} -o coverage.json"
         if [ -e "${jsonfile}" ]
         then
            OPTION_CLEAN='NO'
            OPTION_CRAFT='NO'
            OPTION_RUN='NO'
            OPTION_SHOW='NO'
         fi
      fi

      # true && true || echo 1 -> nothing
      # clean recrafts all dependencies as no-coverage
      if [ "${OPTION_CLEAN}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Build dependencies without coverage"
         sde::test::run 'YES' clean all   || exit 1
         sde::test::run 'YES' craft       || exit 1
      fi

      if [ "${OPTION_CRAFT}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Rebuild selected dependencies with coverage"
         sde::test::run 'YES' --coverage craft ${CRAFT_RUN_FLAGS} || exit 1
      fi
      if [ "${OPTION_RUN}" = 'YES' ]
      then
         # must run tests serially, otherwise the coverage files may end up
         # inconsistent
         log_info "${C_BR_BLUE}${C_BOLD}* Run tests"
         sde::test::run 'YES' --coverage "${RUN_CMD}" ${CRAFT_RUN_FLAGS} --serial || exit 1
      fi

      if [ "${OPTION_SHOW}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Produce coverage information"
         sde::test::run 'YES' coverage "${OPTION_GCOV}" ${GCOV_FLAGS} "$@" || exit 1
      fi

      if [ "${OPTION_JQ}" = 'YES' ]
      then
         exekutor jq ".${JQ_KEY}" "${jsonfile}"
      fi
   ) || exit 1
}


sde::test::path_environment()
{
   log_entry "sde::test::path_environment" "$@"

   MULLE_SDE_TEST_PATH="`rexekutor mulle-env -s environment get --lenient MULLE_SDE_TEST_PATH`" || exit 1
   if sde::is_test_directory "."
   then
      MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-.}"
   else
      MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"
   fi

   log_setting "MULLE_SDE_TEST_PATH=${MULLE_SDE_TEST_PATH}"
}


sde::test::r_init()
{
   log_entry "sde::test::r_init" "$@"

   local projecttype
   local options

   projecttype="`rexekutor "${MULLE_ENV:-mulle-env}" environment get PROJECT_TYPE`" || exit 1
   case "${projecttype}" in
      executable)
         options="--executable"
      ;;
   esac

   RVAL=
   if ! exekutor "mulle-test" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_TEST_FLAGS} \
                  init \
                     ${options} \
                     "$@"
   then
      return 1
   fi

   log_info "Added ${C_RESET_BOLD}test${C_INFO} folder"

   local value
   local keys 
   local key 
   
   keys="MULLE_SOURCETREE_USE_PLATFORM_MARKS_FOR_FETCH:\
MULLE_SOURCETREE_RESOLVE_TAG"

   IFS=":"
   for key in ${keys}
   do
      IFS="${DEFAULT_IFS}"
      # copy some basic settings if init was successful
      value="`rexekutor "${MULLE_ENV:-mulle-env}" environment get ${key}`"
      # load current project settings
      if [ ! -z "${value}" ]
      then
         rexekutor "${MULLE_ENV:-mulle-env}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS} \
                        -d test \
                     environment set ${key} "${value}"
      fi
   done
   IFS="${DEFAULT_IFS}"

   #
   # disable graveyards on tests
   #
   rexekutor "${MULLE_ENV:-mulle-env}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_ENV_FLAGS} \
                  -d test \
               environment set MULLE_SOURCETREE_GRAVEYARD_ENABLED NO

   RVAL='DONE'
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
sde::test::r_main()
{
   log_entry "sde::test::r_main" "$@"

   local rval

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::test::usage
         ;;

         -*)
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::test::path_environment

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
      clean|crun|craft|build|craftorder|fetch|linkorder|log|rebuild|recraft|\
recrun|rerun|retest|run)
         RVAL='DEFAULT'
         return 1;
      ;;

      coverage)
         shift
         sde::test::coverage "$@"
         RVAL='DONE'
         rval=$?
         return $rval
      ;;

      # introspection, no test dir needed
      env|test-dir)
         RVAL='HARMLESS'
         return 1;
      ;;

      libexec-dir|version)
         rexekutor mulle-test ${MULLE_TECHNICAL_FLAGS} "$1" "$@"
         rval=$?
         RVAL='DONE'
         return $rval
      ;;

      # no environment needed to run these properly
      generate)
         shift
         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            sde::exec_command_in_subshell "CD" test generate "$@"
         else
            sde::test::generate "$@"
         fi
         rval=$?
         RVAL='DONE'
         return $rval
      ;;

      # no environment needed to run these properly
      init)
         shift
         sde::test::r_init "$@"
      ;;

      # layme, other known commands that don't work in test
      # rerun them with mulle-sde
      config)
         RVAL='DONE'
         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} "$@"
         return $?
      ;;

      *)
         RVAL='RUN'
         return 1
      ;;
   esac
}


sde::test::main()
{
   log_entry "sde::test::main" "$@"

   local rval

   sde::test::r_main "$@"
   rval=$?

   if [ $rval -eq 1 ]
   then
      case "${RVAL}" in
         "DONE")
         ;;

         'DEFAULT')
            sde::test::run 'NO' "$@"
            rval=$?
         ;;

         'HARMLESS')
            sde::test::run 'YES' "$@"
            rval=$?
         ;;

         'RUN')
            sde::test::run 'NO' run "$@"
            rval=$?
         ;;
      esac
   fi

   return $rval
}
