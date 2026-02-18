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
   crun       : craft and run tests
   crerun     : craft and rerun failed tests
   generate   : generate some simple test files (Objective-C only)
   init       : initialize a test directory
   linkorder  : show library command for linking test executable
   nrun       : run tests without crafting
   nrerun     : rerun failed tests without crafting
   recraft    : re-craft library and dependencies
   recrun     : clean all, craft and run tests
   rerun      : rerun failed tests
   retest     : clean gravetidy and then craft and run tests once more
   run        : run tests (crafts if MULLE_VIBECODING=YES)
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
   ${MULLE_USAGE_NAME} test coverage [options] ...

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


sde::test::generate()
{
   log_entry "sde::test::generate" "$@"

   local cmd="$1"
   local flags
   local OPTION_FULL_TEST='NO'

   while [ $# -ne 0 ]
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

   local rc

   .foreachpath directory in ${MULLE_SDE_TEST_PATH}
   .do
      mkdir_if_missing "${directory}"

      exekutor "${MULLE_TESTGEN}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_TESTGENERATOR_FLAGS} \
                        ${flags} \
                     generate \
                     -d "${directory}/00_noleak" \
                     "$@"
      rc=$?

      if [ $rc -eq 0 -a "${OPTION_FULL_TEST}" = 'YES' ]
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
         rc=$?
      fi

      if [ rc != 0 ]
      then
         return $rc
      fi
   .done
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
            sde::test::usage "Unknown option \"$1\", use -- to pass arguments to mulle-test"
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
         sde::test::forward 'YES' clean all   || exit 1
         OPTION_CRAFT='YES'
      fi

      if [ "${OPTION_CRAFT}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Rebuild selected dependencies with coverage"
         sde::test::forward 'YES' --coverage craft ${CRAFT_RUN_FLAGS} || exit 1
      fi
      if [ "${OPTION_RUN}" = 'YES' ]
      then
         # must run tests serially, otherwise the coverage files may end up
         # inconsistent
         log_info "${C_BR_BLUE}${C_BOLD}* Run tests"
         sde::test::forward 'YES' --coverage "${RUN_CMD}" ${CRAFT_RUN_FLAGS} --serial || exit 1
      fi

      if [ "${OPTION_SHOW}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Produce coverage information"
         sde::test::forward 'YES' coverage "${OPTION_GCOV}" ${GCOV_FLAGS} "$@" || exit 1
      fi

      if [ "${OPTION_JQ}" = 'YES' ]
      then
         exekutor jq ".${JQ_KEY}" "${jsonfile}"
      fi
   ) || exit 1
}


sde::test::r_init()
{
   log_entry "sde::test::r_init" "$@"

   local projecttype
   local options

   projecttype="`rexekutor "${MULLE_ENV:-mulle-env}" get --output-eval PROJECT_TYPE`" || exit 1
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
MULLE_SOURCETREE_RESOLVE_TAG:\
MULLE_CRAFT_PLATFORMS:\
MULLE_SOURCETREE_PLATFORMS"

   .foreachpath key in ${keys}
   .do
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
   .done

   # Move platform loop settings into test environment
   value="`rexekutor "${MULLE_ENV:-mulle-env}" environment get --lenient MULLE_SDE_TEST_PLATFORMS 2>/dev/null`"
   value="${value:-`rexekutor "${MULLE_ENV:-mulle-env}" environment get --lenient MULLE_CRAFT_PLATFORMS 2>/dev/null`}"
   if [ ! -z "${value}" ]
   then
      rexekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} \
                     -d test \
                  environment set MULLE_TEST_PLATFORMS "${value}"
   fi

   # Copy platform-specific variables (toolchain, compiler root, emulator)
   local platforms
   local platform
   local varname

   platforms="`rexekutor "${MULLE_ENV:-mulle-env}" environment get MULLE_CRAFT_PLATFORMS`"

   if [ ! -z "${platforms}" ]
   then
      .foreachpath platform in ${platforms}
      .do
         r_uppercase "${platform}"

         # Copy toolchain variable
         varname="MULLE_CRAFT_TOOLCHAIN__${RVAL}"
         value="`rexekutor "${MULLE_ENV:-mulle-env}" environment get ${varname}`"
         toolchain_file="${value}"  # Save for later
         if [ ! -z "${value}" ]
         then
            rexekutor "${MULLE_ENV:-mulle-env}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                           -d test \
                        environment set ${varname} "${value}"
         fi

         # Copy compiler root variable
         varname="MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}"
         value="`rexekutor "${MULLE_ENV:-mulle-env}" environment get ${varname}`"
         if [ ! -z "${value}" ]
         then
            rexekutor "${MULLE_ENV:-mulle-env}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                           -d test \
                        environment set ${varname} "${value}"
         fi

         # Copy emulator variable
         varname="MULLE_EMULATOR__${RVAL}"
         value="`rexekutor "${MULLE_ENV:-mulle-env}" environment get ${varname}`"
         if [ ! -z "${value}" ]
         then
            rexekutor "${MULLE_ENV:-mulle-env}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                           -d test \
                        environment set ${varname} "${value}"
         fi

         # Copy toolchain file if it exists
         if [ ! -z "${toolchain_file}" ]
         then
            if [ -f "cmake/${toolchain_file}.cmake" ]
            then
               mkdir -p test/cmake
               cp "cmake/${toolchain_file}.cmake" test/cmake/
               log_verbose "Copied toolchain file ${toolchain_file}.cmake to test/cmake/"
            fi
         fi
      .done
   fi

   #
   # disable graveyards on tests
   #
   rexekutor "${MULLE_ENV:-mulle-env}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_ENV_FLAGS} \
                  -d test \
               environment set MULLE_SOURCETREE_GRAVEYARD_ENABLED NO
   # memo: not running in environment there fore no log_vibe
   log_info "Run ${C_RESET_BOLD}mulle-sde howto show testing${C_INFO} for more info (if available)"

   RVAL='DONE'
}




#
# this returns the test directory to use for the given test files
#
sde::test::r_validate_test_run_paths()
{
   log_entry "sde::test::r_validate_test_run_paths" "$@"

   log_setting "MULLE_USER_PWD: ${MULLE_USER_PWD}"
   log_setting "PWD:            ${PWD}"

   local test_env

   test_env=$(
      # Now parse flags
      local OPTION_CONFIGURATION='Debug'
      local OPTION_PLATFORM=''
      local OPTION_PARALLEL=''
      local OPTION_COVERAGE='NO'
      local OPTION_VALGRIND='NO'
      local OPTION_SANITIZER=''
      local OPTION_CLEAN='DEFAULT'

      local shifts
      local remainder

      test::options::r_parse "$@"
      shifts="${RVAL}"

      # Shift away all flags
      shift ${shifts}

      local filename
      local test_dir
      local test_file
      local test_env

      if [ $# -eq  0 ]
      then
         log_debug "No testfiles to run provided"
         RVAL=
         return 0 # is ok
      fi

      while [ $# -ne 0 ]
      do
         filename="$1"

         log_debug "${filename}"

         if ! is_absolutepath "${filename}"
         then
            r_filepath_concat "${MULLE_USER_PWD}" "${filename}"
            filename="${RVAL}"
         fi

         log_debug "${filename}"

         if [ ! -e "${filename}" ]
         then
            # Try adding extensions from PROJECT_EXTENSIONS before failing
            local ext
            local extensions

            sde::test::r_get_test_project_extensions
            extensions="${RVAL}"

            local found='NO'

            case "${extensions}" in
               *:*)
                  # Handle colon-separated extensions
                  local IFS=':'
                  for ext in ${extensions}
                  do
                     if [ -e "${filename}.${ext}" ]
                     then
                        filename="${filename}.${ext}"
                        found='YES'
                        break
                     fi
                  done
               ;;

               *)
                  # Single extension
                  if [ -e "${filename}.${extensions}" ]
                  then
                     filename="${filename}.${extensions}"
                     found='YES'
                  fi
               ;;
            esac

            if [ "${found}" = 'NO' ]
            then
               fail "Could not find test file \"${filename}\" ($PWD)"
            fi
         fi

         test_dir=$(sde::test::get_test_dir "${filename}")
         if [ -z "${test_env}" ]
         then
            test_env="$test_dir"
            test_file="$1"
         else
            if [ "${test_env}" != "${test_dir}" ]
            then
               fail "Test \"${filename}\" is in a different test environment than \"$test_file\""
            fi
         fi

         shift
      done

      printf "%s\n" "${test_env}"
   )  || exit 1

   # Empty test_env is OK - means no specific test files, run all tests
   # test_env now contains the output from the subshell
   RVAL="${test_env}"
   return 0
}



sde::test::r_test_directories()
{
   log_entry "sde::test::r_test_directories" "$@"

   local directory="${1:-}"

   local directories

   directories="$(mulle-env -d "${directory}" get --output-eval MULLE_SDE_TEST_PATH)"
   directories="${directories:-test}"

   local dir

   .foreachpath dir in ${directories}
   .do
      if [ ! -d "${dir}" ]
      then
         fail "Test directory ${C_RESET_BOLD}${dir}${C_ERROR} is missing ($PWD)"
      fi
   .done

   RVAL="${directories}"
}


sde::test::r_test_platforms()
{
   log_entry "sde::test::r_test_platforms" "$@"

   local directory="${1:-}"

   platforms="$(mulle-env -E -d "${directory}" get --output-eval MULLE_TEST_PLATFORMS)"
   log_setting "MULLE_TEST_PLATFORMS: ${platforms}"
   if [ -z "${platforms}" ]
   then
      platforms="$(mulle-env -E -d "${directory}" get --output-eval MULLE_CRAFT_PLATFORMS)"
      log_setting "MULLE_CRAFT_PLATFORMS: ${platforms}"
   fi
   platforms="${platforms:-${MULLE_UNAME}}"

   RVAL="${platforms}"
}


sde::test::get_test_dir()
(
   log_entry "sde::test::get_test_dir" "$@"

   local filename="$1"

   r_dirname "${filename}"
   rexekutor mulle-env -s -d "${RVAL}" project-dir
)


sde::test::r_get_test_project_extensions()
(
   log_entry "sde::test::r_get_test_project_extensions" "$@"

   local extensions="$1"

   extensions="${PROJECT_EXTENSIONS}"
   if [ -z  "${extensions}" ]
   then
      extensions=$(rexekutor mulle-env --style mulle/wild -E -s get --output-eval --lenient PROJECT_EXTENSIONS)
   fi
   extensions="${extensions:-c}"

   log_setting "extensions: ${extensions}"

   RVAL="${extensions}"
)


sde::test::r_determine_project_dir()
{
   local directory="${1:-}"

   # empty dir is ok
   RVAL="$(mulle-env -s -d "${directory}" project-dir)"

   [ ! -z "${RVAL}" ]
}


sde::test::r_is_test_directory()
{
   log_entry "sde::test::r_is_test_directory" "$@"

   local directory="$1"


   if ! sde::test::r_determine_project_dir "${directory}"
   then
      return 1
   fi

   local projectdir

   projectdir="${RVAL}"

   if ! rexekutor [ -d "${projectdir}/.mulle/share/test" ]
   then
      RVAL=
      return 1
   fi

   RVAL="${projectdir}"
   return 0
}


exekutor_mulle_env()
{
   local directory="$1"
   shift

   exekutor "${MULLE_ENV:-mulle-env}" \
                  --style 'mulle/inherit' \
                  -d "${directory}" \
                  -E \
                  ${MULLE_ENV_FLAGS:-} \
                  ${MULLE_FWD_FLAGS:-} \
                  --defines "${MULLE_DEFINE_FLAGS:-}" \
                  exec \
                    "$@"
}


exekutor_mulle_sde()
{
   local directory="$1"
   shift

   exekutor "${MULLE_SDE:-mulle-sde}" \
                  --no-test-check \
                  --style 'mulle/inherit' \
                  -E \
                  -d "${directory}"  \
                  ${MULLE_TECHNICAL_FLAGS:-} \
                  ${MULLE_SDE_FLAGS:-} \
                  ${MULLE_ENV_FLAGS:-} \
                  ${MULLE_FWD_FLAGS:-} \
                  --defines "${MULLE_DEFINE_FLAGS:-}" \
                  "$@"
}


exekutor_mulle_test()
{
   local directory="$1"
   shift

   exekutor_mulle_env "${directory}" mulle-test ${MULLE_TECHNICAL_FLAGS} \
                                                ${MULLE_TEST_FLAGS} \
                                               "$@"
}




# used for 'crun' and friends
sde::test::auto_clean()
{
   log_entry "sde::test::auto_clean" "$@"

   local directory="$1"
   local target="$2"
   shift 2

   (
      test::options::r_parse "$@"

      if [ "${OPTION_CLEAN}" = 'NO' ]
      then
         return
      fi

      # clear remaining

      set --

      if [ ! -z "${OPTION_CONFIGURATION}" ]
      then
         set -- --configuration "${OPTION_CONFIGURATION}" "$@"
      fi

      if [ ! -z "${OPTION_PLATFORM}" ]
      then
         set -- --platform "${OPTION_PLATFORM}" "$@"
      fi

      if [ ! -z "${OPTION_SDK}" ]
      then
         set -- --sdk "${OPTION_SDK}" "$@"
      fi

      log_fluff "Cleaning in ${directory:-${PWD}}"

      exekutor_mulle_sde "${directory}" clean "$@" ${target}
   )
}



sde::test::craft()
{
   log_entry "sde::test::craft" "$@"

   local directory="$1"
   shift

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      test::options::r_parse "$@"

      # Check if cross-compiling without proper toolchain support
      if [ ! -z "${OPTION_PLATFORM}" -a "${OPTION_PLATFORM}" != "${MULLE_UNAME}" ]
      then
         # Check if we have toolchain support for this platform
         local toolchain_dir="/opt/mulle-clang-project-${OPTION_PLATFORM}"
         if [ ! -d "${toolchain_dir}" ]
         then
            fail "Cross-compilation to platform '${OPTION_PLATFORM}' requires a toolchain in ${toolchain_dir}.
${C_INFO}Either install the cross-compilation toolchain or remove the platform from test configuration."
         fi
      fi

      local sde_args

      if [ "${OPTION_PARALLEL}" = 'YES' ]
      then
         r_add_line "${sde_args}" "--parallel"
         sde_args="${RVAL}"
      else
         r_add_line "${sde_args}" "--serial"
         sde_args="${RVAL}"
      fi

      # we handle clean separately
      r_add_line "${sde_args}" "--no-clean"
      sde_args="${RVAL}"

      local craft_args

      craft_args='--mulle-test'

      r_add_line "${craft_args}" "--preferred-library-style"
      craft_args="${RVAL}"
      r_add_line "${craft_args}" "dynamic"
      craft_args="${RVAL}"

      if [ ! -z "${OPTION_SDK}" ]
      then
         r_add_line "${craft_args}" "--sdk"
         craft_args="${RVAL}"
         r_add_line "${craft_args}" "${OPTION_SDK}"
         craft_args="${RVAL}"
      fi

      if [ ! -z "${OPTION_PLATFORM}" ]
      then
         r_add_line "${craft_args}" "--platform"
         craft_args="${RVAL}"
         r_add_line "${craft_args}" "${OPTION_PLATFORM}"
         craft_args="${RVAL}"
      fi

      if [ ! -z "${OPTION_CONFIGURATION}" ]
      then
         r_add_line "${craft_args}" "--configuration"
         craft_args="${RVAL}"
         r_add_line "${craft_args}" "${OPTION_CONFIGURATION}"
         craft_args="${RVAL}"
      fi

      local make_args=""


      if [ "${OPTION_COVERAGE}" = 'YES' ]
      then
         r_add_line "${make_args}" "-DOTHER_CFLAGS+=--coverage"
         make_args="${RVAL}"
         r_add_line "${make_args}" "-DOTHER_CFLAGS+=-fno-inline"
         make_args="${RVAL}"
         r_add_line "${make_args}" "-DOTHER_CFLAGS+=-DNDEBUG"
         make_args="${RVAL}"
         r_add_line "${make_args}" "-DOTHER_CFLAGS+=-DNS_BLOCK_ASSERTIONS"
         make_args="${RVAL}"
      else
         if [ ! -z "${SANITIZER}" ]
         then
            case "${SANITIZER}" in
               undefined)
                  r_add_line "${make_args}" "-DOTHER_CFLAGS+=-fsanitize=undefined"
                  make_args="${RVAL}"
               ;;
               thread)
                  r_add_line "${make_args}" "-DOTHER_CFLAGS+=-fsanitize=thread"
                  make_args="${RVAL}"
               ;;
               address)
                  r_add_line "${make_args}" "-DOTHER_CFLAGS+=-fsanitize=address"
                  make_args="${RVAL}"
               ;;
            esac
         fi
      fi

      log_fluff "Crafting dependencies in ${directory:-${PWD}}"

      local line

      set --

      while IFS= read -r line
      do
         [ -z "${line}" ] && continue
         set -- "$@" "${line}"
      done <<< "${sde_args}"

      # set command for crafting
      set -- "$@" 'craftorder'

      set -- "$@" "--"

      while IFS= read -r line
      do
         [ -z "${line}" ] && continue
         set -- "$@" "${line}"
      done <<< "${craft_args}"

      set -- "$@" "--"

      while IFS= read -r line
      do
         [ -z "${line}" ] && continue
         set -- "$@" "${line}"
      done <<< "${make_args}"

      exekutor_mulle_sde "${directory}" craft "$@"
   )
}


sde::test::generic()
{
   log_entry "sde::test::generic" "$@"

   local directory="$1"
   local cmd="$2"
   shift 2

   (
      test::options::r_parse "$@"
      shift ${RVAL}

      #
      # preprend known options to argument
      #
      if [ ! -z "${OPTION_CONFIGURATION}" ]
      then
         set -- --configuration "${OPTION_CONFIGURATION}" "$@"
      fi

      if [ ! -z "${OPTION_PLATFORM}" ]
      then
         set -- --platform "${OPTION_PLATFORM}" "$@"
      fi

      if [ ! -z "${OPTION_SDK}" ]
      then
         set -- --sdk "${OPTION_SDK}" "$@"
      fi

      log_fluff "Executing ${cmd} in ${directory}"

      exekutor_mulle_sde "${directory}" "${cmd}" "$@"
   )
}


sde::test::postprocess()
{
   log_entry "sde::test::postprocess" "$@"

   local directory="$1"
   shift

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      test::options::r_parse "$@"

      log_fluff "Postprocessing headers in ${directory:-${PWD}}"

      include "sde::test-postprocess"

      sde::test::postprocess_headers "${directory}" \
                                     "${OPTION_SDK}" \
                                     "${OPTION_PLATFORM}" \
                                     "${OPTION_CONFIGURATION}"
   )
}


sde::test::link_args()
{
   log_entry "sde::test::link_args" "$@"

   local directory="$1"
   shift

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      test::options::r_parse "$@"
      shift $RVAL

      log_fluff "Perform link-args command in ${directory:-${PWD}}"

      include "sde::test-link-args"

      sde::test::link_args_main -d "${directory}" \
                                --sdk "${OPTION_SDK}" \
                                --platform "${OPTION_PLATFORM}" \
                                --configuration "${OPTION_CONFIGURATION}" \
                                "$@"
   )
}


sde::test::update_link_args()
{
   log_entry "sde::test::update_link_args" "$@"

   local directory="$1"
   shift

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      test::options::r_parse "$@"
      shift $RVAL

      log_fluff "Perform link-args command in ${directory:-${PWD}}"

      include "sde::test-link-args"

      sde::test::link_args_main -d "${directory}" \
                                --sdk "${OPTION_SDK}" \
                                --platform "${OPTION_PLATFORM}" \
                                --configuration "${OPTION_CONFIGURATION}" \
                                update \
                                "$@"
   )
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
sde::test::main()
{
   log_entry "sde::test::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::test::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-}"

   [ $# -ne 0 ] && shift

   #
   #
   # sde command | PWD  | ENV  || Platforms | Testdirs || What should happen
   # ------------|------|------||----------------------||--------------------------------------------------
   #
   #
   # init        | test |  NO  ||  N/A      |    N/A   || **FAIL**
   # init        | test |  YES ||  N/A      |    N/A   || **FAIL**
   # init        | proj |  NO  ||  N/A      |    N/A   || OK
   # init        | proj |  YES ||  N/A      |    N/A   || OK


   local state
   local test_root

   state='proj'
   if sde::test::r_is_test_directory
   then
      state='test'
      test_root="${RVAL}"
   fi

   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      state="${state}-env"
   fi

   # we could be running outside of every environment
   if [ -z "${MULLE_UNAME}" ]
   then
      MULLE_UNAME="$(PATH=/bin:/usr/bin uname -s 2> /dev/null | tr '[:upper:]' '[:lower:]')"
   fi

   local cmdchain
   local cleanargs

   #
   # Some commands need to run inside the project environment (platform variables)
   case "${cmd}" in
      clean)
         r_colon_concat "${cmdchain}" "clean"
         cmdchain="${RVAL}"
      ;;

      recraft|reccrun)
         r_colon_concat "${cmdchain}" "auto-clean"
         cmdchain="${RVAL}"

         cleanargs='all'
      ;;

      retest|tidy)
         r_colon_concat "${cmdchain}" "auto-clean"
         cmdchain="${RVAL}"

         cleanargs='tidy'
      ;;


      coverage)
         sde::test::coverage "$@"
         return $?
      ;;

      init)
         sde::test::r_init "$@"
         return $?
      ;;

      generate)
         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            sde::exec_command_in_subshell "CD" test generate "$@"
         else
            sde::test::generate "$@"
         fi
         return $?
      ;;

      test*|craft|crun|crerun|rec|run|nrun|recrun|rerun)
         # handled later
      ;;

      *)
         sde::test::usage "Unknown command \"${cmd}\""
      ;;
   esac

   case "${cmd}" in
      craft|crun|crerun|recraft|recrun|retest)
         r_colon_concat "${cmdchain}" 'craft'
         r_colon_concat "${RVAL}" 'postprocess'
         r_colon_concat "${RVAL}" 'update-link-args'
         cmdchain="${RVAL}"
      ;;
   esac

   case "${cmd}" in
      run|crun|nrun|recrun|retest)
         r_colon_concat "${cmdchain}" 'run'
         cmdchain="${RVAL}"
      ;;

      rerun|crerun|nrerun)
         r_colon_concat "${cmdchain}" 'rerun'
         cmdchain="${RVAL}"
      ;;
   esac

   include "test::options"

   cmdchain="${cmdchain:-${cmd}}"

   local test_directories
   local clean_before_run='NO'

   case "${state}" in
      proj*)
         sde::test::r_test_directories
         test_directories="${RVAL}"
      ;;
   esac

   case ":${cmdchain}:" in
      *:clean:*|*:auto-clean:*)
      ;;

      *:craft:*|*:run:*)
         case "${state}" in
            proj*)
               clean_before_run="$(mulle-env -s -E -d "${test_directories%%:*}" get --output-eval 'MULLE_TEST_CLEAN_BEFORE_RUN')"
            ;;

            test*)
               clean_before_run="$(mulle-env -s get --output-eval 'MULLE_TEST_CLEAN_BEFORE_RUN')"
            ;;
         esac

         if [ "${clean_before_run:-}" = 'YES' ]
         then
            r_colon_concat "auto-clean" "${cmdchain}"
            cmdchain="${RVAL}"

            cleanargs='project'
         fi
      ;;
   esac

   case ":${cmdchain}:" in
      *:auto-clean:*craft:*run:*)
      ;;

      *:auto-clean:*run:*)
         cmdchain="${cmdchain/auto-clean:/auto-clean:craft:postprocess:update-link-args:}"
      ;;
   esac

   local directory
   local platforms
   local platform
   local target

   log_debug "cmdchain: ${cmdchain}"

   # Check if specific test files were provided (only relevant for run/rerun)
   local specific_test_directory
   
   case ":${cmdchain}:" in
      *:run:*|*:rerun:*)
         case "${state}" in
            proj*)
               if ! sde::test::r_validate_test_run_paths "$@"
               then
                  return 1
               fi
               specific_test_directory="${RVAL}"
               
               # Don't skip platform loop - let specific tests run for all configured platforms
            ;;
         esac
      ;;
   esac

   # Determine platforms once at the top level
   case "${state}" in
      proj*)
         # For project state, we'll handle platforms per test directory

         # If specific test directory was identified, use only that one
         if [ ! -z "${specific_test_directory}" ]
         then
            test_directories="${specific_test_directory}"
         fi

         local test_dir_for_platform
         local tidy_done='NO'
         
         .foreachpath test_dir_for_platform in ${test_directories}
         .do
            sde::test::r_test_platforms "${test_dir_for_platform}"
            platforms=${RVAL}
            
            log_setting "r_test_platforms ($test_dir_for_platform): ${platforms}"
            
            local platform_for_cmdchain
            
            .foreachpath platform_for_cmdchain in ${platforms}
            .do
               log_info "🔹🔹🔹 Test ${C_MAGENTA}${C_BOLD}${platform_for_cmdchain}${C_INFO} in ${C_RESET_BOLD}${test_dir_for_platform#${MULLE_USER_PWD}/}${C_INFO} 🔸🔸🔸"
               
               .foreachpath cmd in ${cmdchain}
               .do
                  log_debug "${cmd}::${state}::${platform_for_cmdchain}"

                  case "${cmd}" in
                     'auto-clean')
                        # Skip tidy if already done
                        if [ "${cleanargs}" = 'tidy' -a "${tidy_done}" = 'YES' ]
                        then
                           log_debug "Skipping tidy (already done)"
                        else
                           if [ "${cleanargs}" = 'project' ]
                           then
                              target="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'TEST_PROJECT_NAME')"
                              if [ -z "${target}" ]
                              then
                                 target="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'PROJECT_NAME')"
                              fi
                           else
                              target="${cleanargs}"
                           fi

                           if ! sde::test::auto_clean "${test_dir_for_platform}" "${target:-all}" --platform "${platform_for_cmdchain}" "$@"
                           then
                              if [ "${OPTION_LENIENT}" != 'YES' ]
                              then
                                 exit 1
                              fi
                           fi

                           # Mark tidy as done
                           if [ "${cleanargs}" = 'tidy' ]
                           then
                              tidy_done='YES'
                           fi
                        fi
                     ;;

                     'clean'|'craftorder'|'log')
                        if ! sde::test::generic "${test_dir_for_platform}" "${cmd}" --platform "${platform_for_cmdchain}" "$@"
                        then
                           if [ "${OPTION_LENIENT}" != 'YES' ]
                           then
                              exit 1
                           fi
                        fi
                     ;;

                     'craft'|'postprocess'|'update-link-args'|'link-args')
                        if ! sde::test::${cmd//-/_} "${test_dir_for_platform}" --platform "${platform_for_cmdchain}" "$@"
                        then
                           if [ "${OPTION_LENIENT}" != 'YES' ]
                           then
                              exit 1
                           fi
                        fi
                     ;;

                     'run'|'rerun')
                        local run_directory
                        
                        if ! sde::test::r_validate_test_run_paths "$@"
                        then
                           return 1
                        fi
                        run_directory="${RVAL}"

                        if [ ! -z "${run_directory}" ]
                        then
                           exekutor_mulle_test "${run_directory}" --platform "${platform_for_cmdchain}" "${cmd}" "$@"
                        else
                           if ! exekutor_mulle_test "${test_dir_for_platform}" --platform "${platform_for_cmdchain}" "${cmd}" "$@"
                           then
                              if [ "${OPTION_LENIENT}" != 'YES' ]
                              then
                                 exit 1
                              fi
                           fi
                        fi
                     ;;
                  esac
               .done
            .done
         .done
      ;;

      test*)
         sde::test::r_test_platforms "${test_root}"
         platforms=${RVAL}
         
         log_setting "r_test_platforms ($test_root): ${platforms}"
         
         local platform_for_cmdchain
         local tidy_done='NO'
         
         .foreachpath platform_for_cmdchain in ${platforms}
         .do
            log_info "🔹🔹🔹 Test ${C_MAGENTA}${C_BOLD}${platform_for_cmdchain}${C_INFO} 🔸🔸🔸"
            
            .foreachpath cmd in ${cmdchain}
            .do
               log_debug "${cmd}::${state}::${platform_for_cmdchain}"

               case "${cmd}" in
                  'auto-clean')
                     # Skip tidy if already done
                     if [ "${cleanargs}" = 'tidy' -a "${tidy_done}" = 'YES' ]
                     then
                        log_debug "Skipping tidy (already done)"
                     else
                        if [ "${cleanargs}" = 'project' ]
                        then
                           target="$(mulle-env -d "${directory}" -s get --output-eval 'TEST_PROJECT_NAME')"
                           if [ -z "${target}" ]
                           then
                              target="$(mulle-env -d "${directory}" -s get --output-eval 'PROJECT_NAME')"
                           fi
                        else
                           target="${cleanargs}"
                        fi

                        if ! sde::test::auto_clean "" "${target:-all}" --platform "${platform_for_cmdchain}" "$@"
                        then
                           if [ "${OPTION_LENIENT}" != 'YES' ]
                           then
                              exit 1
                           fi
                        fi
                        
                        # Mark tidy as done
                        if [ "${cleanargs}" = 'tidy' ]
                        then
                           tidy_done='YES'
                        fi
                     fi
                  ;;

                  'clean'|'craftorder'|'log')
                     if ! sde::test::generic "" "${cmd}" --platform "${platform_for_cmdchain}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi
                  ;;

                  'craft'|'postprocess'|'update-link-args'|'link-args')
                     if ! sde::test::${cmd//-/_} "" --platform "${platform_for_cmdchain}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi
                  ;;

                  'run'|'rerun')
                     if ! exekutor_mulle_test "${directory}" --platform "${platform_for_cmdchain}" "${cmd}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi
                  ;;
               esac
            .done
         .done
      ;;
   esac
}
