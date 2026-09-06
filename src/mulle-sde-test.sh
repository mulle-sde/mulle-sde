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
   --platform <name> : run tests for this platform only (use 'all' to reset)
   --sdk <name>      : use this SDK
   --configuration   : use this configuration (default: Debug)
   --valgrind        : use valgrind to run
   --sanitize-address   : use address sanitizer
   --sanitize-thread    : use thread sanitizer
   --sanitize-undefined : use undefined sanitizer
   --coverage        : produce coverage information
   --gdb             : use gdb to run
   See \`mulle-test help\` for more options

   Note: --platform, --sdk, --configuration must be placed BEFORE the command.
   e.g.: ${MULLE_USAGE_NAME} test --platform windows craft
   e.g.: ${MULLE_USAGE_NAME} test --valgrind run

Command:
   clean      : clean tests and or dependencies
   config     : run mulle-sde config command in test directories
   craft      : craft library
   craftorder : show order of dependencies being crafted
   coverage   : do a coverage run
   crun       : craft and run tests
   crerun     : craft and rerun failed tests
   dep        : manage test project dependencies (alias: dependency)
   verify     : verify dependency artifacts against stashed sources
   stale-check: alias for verify
   init       : initialize a test directory
   lib        : manage test project libraries (alias: library)
   link-args  : show library command for linking test executable (alias: linkorder)
   nrun       : run tests without crafting
   nrerun     : rerun failed tests without crafting
   recraft    : re-craft library and dependencies
   recrun     : clean all, craft and run tests
   rerun      : rerun failed tests
   retest     : clean tidy, craft and run tests. If --platform given, persists it in MULLE_TEST_PLATFORMS (use 'all' to reset)
   run        : run tests (crafts if MULLE_VIBECODING=YES)
   status     : show test project status
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

   If PROJECT_DIALECT is objc (or --clang is given), all deps are compiled
   with mulle-clang so coverage uses a single compiler. llvm-cov is used
   instead of gcovr in that case.

Options:
      --clang    : force mulle-clang for all deps (default for objc projects)
      --craft    : skips step "clean"
      --gcc      : use system gcc for deps (default for C projects)
      --gcov     : use gcov instead of gcovr
      --json     : output coverage summary as JSON to stdout
      --lines    : run --json and extract lines of code field (needs jq)
      --mulle    : create "coverage.html" with mulle style gcovr options
      --no-run   : stop after "run"
      --output <f>  : write coverage output to file <f>
      --percent  : run --json and extract coverage percentage (needs jq)
      --rerun    : skips steps "clean" and "craft" then reruns failed tests
      --run      : skips steps "clean" and "craft"
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
   local OPTION_GCOV=''
   local OPTION_COMPILER=''
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

         --clang)
            OPTION_COMPILER='mulle-clang'
         ;;

         --gcc)
            OPTION_COMPILER='gcc'
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

         --output|-o)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift
            case "${GCOV_FLAGS}" in
               *" -o "*|*".html"*)
                  fail "Do not combine --output with --mulle"
               ;;
            esac
            r_concat "${GCOV_FLAGS}" "-o $1"
            GCOV_FLAGS="${RVAL}"
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

      local testdir

      sde::test::r_test_directories
      testdir="${RVAL%%:*}"
      testdir="${testdir:-$PWD}"

      # Auto-detect compiler mode from PROJECT_DIALECT if not forced

      local compiler

      compiler="${OPTION_COMPILER}"
      if [ -z "${compiler}" ]
      then
         local dialect
         dialect="`rexekutor "${MULLE_ENV:-mulle-env}" get PROJECT_DIALECT 2>/dev/null`"
         case "${dialect}" in
            objc|m)
               compiler='mulle-clang'
            ;;
         esac
      fi

      # Default gcov tool based on compiler
      local gcov_tool
      gcov_tool="${OPTION_GCOV}"
      if [ -z "${gcov_tool}" ]
      then
         case "${compiler}" in
            mulle-clang|clang)
               gcov_tool='mulle-cov'
            ;;
            *)
               gcov_tool='gcovr'
            ;;
         esac
      fi

      local jsonfile

      if [ "${OPTION_JQ}" = 'YES' ]
      then
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

      # clean recrafts all dependencies as no-coverage
      if [ "${OPTION_CLEAN}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Build dependencies without coverage"
         exekutor_mulle_sde "${testdir}" clean all   || exit 1
         OPTION_CRAFT='YES'
      fi

      if [ "${OPTION_CRAFT}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Rebuild selected dependencies with coverage"
         local compiler_flags
         if [ ! -z "${compiler}" ]
         then
            compiler_flags="--cc ${compiler}"
         fi
         # Coverage builds must be serial: parallel platform builds share the
         # same kitchen dir and the non-coverage platform (windows) would
         # overwrite the coverage-instrumented .so from the linux build.
         sde::test::craft "${testdir}" --coverage --serial ${compiler_flags} || exit 1
         sde::test::postprocess "${testdir}" --coverage ${CRAFT_RUN_FLAGS} || exit 1
         sde::test::update_link_args "${testdir}" --coverage ${CRAFT_RUN_FLAGS} || exit 1
      fi
      if [ "${OPTION_RUN}" = 'YES' ]
      then
         # must run tests serially, otherwise the coverage files may end up
         # inconsistent
         log_info "${C_BR_BLUE}${C_BOLD}* Run tests"
         exekutor_mulle_test "${testdir}" --coverage "${RUN_CMD}" ${CRAFT_RUN_FLAGS} --serial || exit 1
      fi

      if [ "${OPTION_SHOW}" = 'YES' ]
      then
         log_info "${C_BR_BLUE}${C_BOLD}* Produce coverage information"
         exekutor_mulle_test "${testdir}" coverage "${gcov_tool}" ${GCOV_FLAGS} "$@" || exit 1
      fi

      if [ "${OPTION_JQ}" = 'YES' ]
      then
         exekutor jq ".${JQ_KEY}" "${jsonfile}"
      fi

      log_info "Dependencies are now instrumented for coverage. Run ${C_RESET_BOLD}mulle-sde test clean all${C_INFO} before running plain tests."
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

   local test_project_name

   test_project_name="`rexekutor "${MULLE_ENV:-mulle-env}" -d test environment get --output-eval TEST_PROJECT_NAME 2>/dev/null`"
   test_project_name="${test_project_name:-${PROJECT_NAME}}"

   if [ "${projecttype}" = "executable" -a ! -z "${test_project_name}" ]
   then
      rexekutor "${MULLE_SDE:-mulle-sde}" \
                   ${MULLE_TECHNICAL_FLAGS} \
                   ${MULLE_SDE_FLAGS} \
                   -d test \
                dependency mark "${test_project_name}" no-link || exit 1
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
   value="`rexekutor "${MULLE_ENV:-mulle-env}" environment get --lenient MULLE_TEST_PLATFORMS 2>/dev/null`"
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

   # expand shell variables like ${MULLE_UNAME} that may be in the value
   r_expanded_string "${platforms}"
   platforms="${RVAL}"

   if [ ! -z "${platforms}" ]
   then
      local source_path

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
            # Check both cmake/ and cmake/share/ locations
            if [ -f "cmake/${toolchain_file}.cmake" ]
            then
               source_path="../../cmake/${toolchain_file}.cmake"
            elif [ -f "cmake/share/${toolchain_file}.cmake" ]
            then
               source_path="../../cmake/share/${toolchain_file}.cmake"
            fi

            if [ ! -z "${source_path}" ]
            then
               mkdir -p test/cmake
               ln -sf "${source_path}" "test/cmake/${toolchain_file}.cmake"
               log_verbose "Symlinked toolchain file ${toolchain_file}.cmake to test/cmake/"
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

   # make clean, rebuild parent project and do a clean before the craft
   if [ ! -z "${test_project_name}" ]
   then
      rexekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} \
                     -d test \
                  environment set MULLE_SDE_CLEAN_DEFAULT "${test_project_name}"
      rexekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} \
                     -d test \
                  environment set MULLE_SDE_CLEAN_BEFORE_CRAFT YES
   fi

   # memo: not running in environment therefore no log_vibe
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

      include "test::options"

      test::options::r_parse "$@"
      shifts="${RVAL}"

      # Shift away all flags
      shift ${shifts}

      local filename
      local test_dir
      local test_file

      if [ $# -eq  0 ]
      then
         log_debug "No testfiles to run provided"
         RVAL=
         return 0 # is ok
      fi

      local ext
      local extensions
      local found
      local IFS

      IFS="${DEFAULT_IFS}"

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
            sde::test::r_get_test_project_extensions
            extensions="${RVAL}"

            found='NO'

            case "${extensions}" in
               *:*)
                  # Handle colon-separated extensions
                  IFS=':'
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
   local missing="${2:-fail}"   # "fail" or "ignore"

   local directories

   directories="$(mulle-env -d "${directory}" get --output-eval MULLE_SDE_TEST_PATH)"
   directories="${directories:-test}"

   local dir
   local result=""

   .foreachpath dir in ${directories}
   .do
      if [ ! -d "${dir}" ]
      then
         if [ "${missing}" = "ignore" ]
         then
            .continue
         fi
         fail "Test directory ${C_RESET_BOLD}${dir}${C_ERROR} is missing ($PWD)"
      fi
      r_colon_concat "${result}" "${dir}"
      result="${RVAL}"
   .done

   RVAL="${result}"
}


sde::test::r_test_platforms()
{
   log_entry "sde::test::r_test_platforms" "$@"

   local directory="${1:-}"
   local test_platforms
   local craft_platforms
   local platform
   local platforms

   test_platforms="$(mulle-env -E -d "${directory}" get --output-eval MULLE_TEST_PLATFORMS)"
   craft_platforms="$(mulle-env -E -d "${directory}" get --output-eval MULLE_CRAFT_PLATFORMS)"
   craft_platforms="${craft_platforms:-${MULLE_UNAME}}"

   log_setting "MULLE_TEST_PLATFORMS: ${test_platforms}"
   log_setting "MULLE_CRAFT_PLATFORMS: ${craft_platforms}"

   if [ -z "${test_platforms}" ]
   then
      platforms="${craft_platforms}"
   else
      platforms=""
      .foreachpath platform in ${test_platforms}
      .do
         if find_item "${craft_platforms}" "${platform}" ":"
         then
            r_colon_concat_if_missing "${platforms}" "${platform}"
            platforms="${RVAL}"
         fi
      .done
      [ -z "${platforms}" ] && fail "MULLE_TEST_PLATFORMS narrows MULLE_CRAFT_PLATFORMS, but there is no overlap (test='${test_platforms}', craft='${craft_platforms}')."
   fi
   log_setting "EFFECTIVE_TEST_PLATFORMS: ${platforms}"

   RVAL="${platforms}"
}


#
# Explode a cmdchain like "craft:run" with platforms "linux:windows" into
# "craft.Default-linux-Debug:run.Default-linux-Debug:craft.Default-windows-Debug:run.Default-windows-Debug"
# (grouped per platform)
#
sde::test::r_explode_cmdchain()
{
   log_entry "sde::test::r_explode_cmdchain" "$@"

   local cmdchain="$1"
   local platforms="$2"
   local sdk="${3:-Default}"
   local configuration="${4:-Debug}"

   local exploded
   local platform
   local cmd
   local style

   .foreachpath platform in ${platforms}
   .do
      style="${sdk}-${platform}-${configuration}"

      .foreachpath cmd in ${cmdchain}
      .do
         r_colon_concat "${exploded}" "${cmd}.${style}"
         exploded="${RVAL}"
      .done
   .done

   RVAL="${exploded}"
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

   [ -z "${directory}" ] && _internal_fail "directory is empty"

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

   [ -z "${directory}" ] && _internal_fail "directory is empty"

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

   [ -z "${directory}" ] && _internal_fail "directory is empty"

   exekutor_mulle_env "${directory}" mulle-test ${MULLE_TECHNICAL_FLAGS} \
                                                ${MULLE_TEST_FLAGS} \
                                               "$@"
}



sde::test::r_clean_target()
{
   local target="$1"
   local test_dir_for_platform="$2"

   local test_name
   local name
   local clean_default

   # substitute clean_default if target is our project
   clean_default="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'MULLE_SDE_CLEAN_DEFAULT')"
   if [ ! -z "${clean_default}" ]
   then
      test_name="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'TEST_PROJECT_NAME')"

      if [ "${target}" = "${test_name}" ]
      then
         target="${clean_default}"
      else
         name="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'PROJECT_NAME')"
         if [ "${target}" = "${name}" ]
         then
            target="${clean_default}"
         fi
      fi
   fi

   RVAL="${target}"
   [ ! -z "${RVAL}" ]
}


# used for 'crun' and friends
sde::test::auto_clean()
{
   log_entry "sde::test::auto_clean" "$@"

   local directory="$1"
   local target="$2"
   shift 2

   sde::test::r_clean_target "${target}" "${directory}"
   target="${RVAL}"

   (
      include "test::options"

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

      log_fluff "Cleaning in ${directory}"

      exekutor_mulle_sde "${directory}" clean "$@" ${target}
   )
}



sde::test::craft()
{
   log_entry "sde::test::craft" "$@"

   local directory="$1"
   shift

   [ -z "${directory}" ] && _internal_fail "directory is empty"

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='DEFAULT'
      local OPTION_CC=''

      # consume --cc before test::options::r_parse
      local _args=()
      while [ $# -ne 0 ]
      do
         case "$1" in
            --cc)
               [ $# -eq 1 ] && fail "Missing argument to \"$1\""
               shift
               OPTION_CC="$1"
            ;;
            -DCC=*)
               OPTION_CC="${1#-DCC=}"
            ;;
            *)
               _args+=( "$1" )
            ;;
         esac
         shift
      done
      set -- "${_args[@]}"

      include "test::options"

      test::options::r_parse "$@"

      # Check if cross-compiling without proper toolchain support
      if [ ! -z "${OPTION_PLATFORM}" -a "${OPTION_PLATFORM}" != "${MULLE_UNAME}" ]
      then
         # Check if we have toolchain support for this platform
         local toolchain_dir="/opt/mulle-clang-project-${OPTION_PLATFORM}"
         if [ ! -d "${toolchain_dir}" ]
         then
            local test_platforms
            local craft_platforms
            local fix_hint

            test_platforms="`mulle-env -E get --output-eval MULLE_TEST_PLATFORMS 2>/dev/null`"
            craft_platforms="`mulle-env -E get --output-eval MULLE_CRAFT_PLATFORMS 2>/dev/null`"

            fix_hint="${C_RESET_BOLD}mulle-sde platform disable ${OPTION_PLATFORM}"
            if [ ! -z "${test_platforms}" ] && find_item "${test_platforms}" "${OPTION_PLATFORM}" ":"
            then
               fix_hint="${C_RESET_BOLD}mulle-sde test --platform all retest"
            fi

            fail "Cross-compilation to platform '${OPTION_PLATFORM}' requires a toolchain in ${toolchain_dir}.
${C_INFO}Effective test platforms are resolved as MULLE_CRAFT_PLATFORMS, optionally narrowed by MULLE_TEST_PLATFORMS.
MULLE_TEST_PLATFORMS='${test_platforms}'
MULLE_CRAFT_PLATFORMS='${craft_platforms}'
Either install the cross-compilation toolchain or remove '${OPTION_PLATFORM}' from the effective test platform configuration.
   ${fix_hint}"
         fi
      fi

      local sde_args

      case "${OPTION_PARALLEL}" in
         'YES')
            r_add_line "${sde_args}" "--parallel"
            sde_args="${RVAL}"
         ;;
         'NO')
            r_add_line "${sde_args}" "--serial"
            sde_args="${RVAL}"
         ;;
      esac

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

      if [ ! -z "${OPTION_CC}" ]
      then
         r_add_line "${make_args}" "-DCC=${OPTION_CC}"
         make_args="${RVAL}"
      fi

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
         r_add_line "${make_args}" "-DOTHER_LDFLAGS+=--coverage"
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

      log_fluff "Crafting dependencies in ${directory}"

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
      log_fluff "Executing ${cmd} in ${directory}"

      exekutor_mulle_sde "${directory}" "${cmd}" "$@"
   )
}


sde::test::postprocess()
{
   log_entry "sde::test::postprocess" "$@"

   local directory="$1"
   shift

   [ -z "${directory}" ] && _internal_fail "directory is empty"

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      include "test::options"

      test::options::r_parse "$@"

      log_fluff "Postprocessing headers in ${directory}"

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

   [ -z "${directory}" ] && _internal_fail "directory is empty"

   case "${PROJECT_TYPE}" in
      library|framework)
      ;;
      *)
         log_fluff "Skipping link-args for ${PROJECT_TYPE} project"
         return 0
      ;;
   esac

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      include "test::options"

      test::options::r_parse "$@"
      shift $RVAL

      log_fluff "Perform link-args command in ${directory}"

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

   [ -z "${directory}" ] && _internal_fail "directory is empty"

   case "${PROJECT_TYPE}" in
      library|framework|executable)
      ;;
      *)
         log_fluff "Skipping update-link-args for ${PROJECT_TYPE} project"
         return 0
      ;;
   esac

   (
      local OPTION_CLEAN='NO'
      local OPTION_PARALLEL='NO'

      include "test::options"

      test::options::r_parse "$@"
      shift $RVAL

      log_fluff "Perform link-args command in ${directory}"

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

sde::test::persist_platform_setting()
{
   log_entry "sde::test::persist_platform_setting" "$@"

   local state="$1"
   local test_directories="$2"
   local platform="$3"

   case "${state}" in
      proj*)
         local directory

         .foreachpath directory in ${test_directories}
         .do
            if [ "${platform}" = 'all' ]
            then
               rexekutor "${MULLE_ENV:-mulle-env}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_ENV_FLAGS} \
                              -d "${directory}" \
                           environment --scope project \
                              remove MULLE_TEST_PLATFORMS
               log_verbose "Removed MULLE_TEST_PLATFORMS in ${directory}"
            else
               rexekutor "${MULLE_ENV:-mulle-env}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_ENV_FLAGS} \
                              -d "${directory}" \
                           environment --scope project \
                              set MULLE_TEST_PLATFORMS "${platform}"
               log_verbose "Set MULLE_TEST_PLATFORMS=${platform} in ${directory}"
            fi
         .done
      ;;

      test*)
         if [ "${platform}" = 'all' ]
         then
            rexekutor "${MULLE_ENV:-mulle-env}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment --scope project \
                           remove MULLE_TEST_PLATFORMS
            log_verbose "Removed MULLE_TEST_PLATFORMS"
         else
            rexekutor "${MULLE_ENV:-mulle-env}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                        environment --scope project \
                           set MULLE_TEST_PLATFORMS "${platform}"
            log_verbose "Set MULLE_TEST_PLATFORMS=${platform}"
         fi
      ;;
   esac
}


sde::test::verify_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} test verify [<test-environment>]

   Inspect the selected test environment's compiled dependency libraries and
   compare them with source files in the sourcetree stash. The argument may be
   a test environment directory, a test source path, or a test source basename,
   with or without its extension. If there is exactly one test environment,
   the argument may be omitted. Every artifact and newer source is printed with an
   absolute path, modification time and size. The command returns failure when
   an artifact is stale, missing, or cannot be checked completely.

EOF
   exit 1
}


sde::test::r_verify_directory()
{
   log_entry "sde::test::r_verify_directory" "$@"

   local state="$1"
   local test_root="$2"
   local requested="$3"
   local directories
   local directory
   local candidate_name
   local test_project_name
   local candidate
   local filename

   if [ -z "${requested}" ]
   then
      sde::test::verify_usage "Missing test name"
   fi

   case "${state}" in
      test*)
         directories="${test_root}"
      ;;
      *)
         sde::test::r_test_directories "" "fail"
         directories="${RVAL}"
      ;;
   esac

   # An existing test file resolves to its containing test project.
   if [ -f "${requested}" ]
   then
      sde::test::r_validate_test_run_paths "${requested}"
      return $?
   fi

   # A nested test directory also resolves to the enclosing test project.
   if [ -d "${requested}" ]
   then
      candidate="$(rexekutor mulle-env -s -d "${requested}" project-dir 2>/dev/null)"
      if [ -n "${candidate}" ]
      then
         r_absolutepath "${candidate}"
         return 0
      fi
   fi

   # Resolve extensionless paths and basenames anywhere below a test root.
   filename="${requested##*/}"
   .foreachpath directory in ${directories}
   .do
      candidate="$(rexekutor find "${directory}" -type f \
                              \( -name "${filename}" -o \
                                 -name "${filename}.*" \) \
                              -print -quit 2>/dev/null)"
      if [ -n "${candidate}" ]
      then
         sde::test::r_validate_test_run_paths "${candidate}"
         return $?
      fi
   .done

   .foreachpath directory in ${directories}
   .do
      if [ "${directory}" = "${requested}" ]
      then
         r_absolutepath "${directory}"
         return 0
      fi

      r_basename "${directory}"
      candidate_name="${RVAL}"
      if [ "${candidate_name}" = "${requested}" ]
      then
         r_absolutepath "${directory}"
         return 0
      fi

      test_project_name="$(rexekutor mulle-env -s -d "${directory}" get --output-eval TEST_PROJECT_NAME 2>/dev/null)"
      if [ "${test_project_name}" = "${requested}" ]
      then
         r_absolutepath "${directory}"
         return 0
      fi
   .done

   fail "Test environment \"${requested}\" was not found as a directory or source file. Available test environments: ${directories}"
}


sde::test::r_verify_artifact_stem()
{
   log_entry "sde::test::r_verify_artifact_stem" "$@"

   local filename="$1"
   local stem="${filename}"

   case "${stem}" in
      *.dylib.*) stem="${stem%%.dylib.*}" ;;
      *.dylib)   stem="${stem%.dylib}" ;;
      *.so.*)    stem="${stem%%.so.*}" ;;
      *.so)      stem="${stem%.so}" ;;
      *.a)       stem="${stem%.a}" ;;
      *.dll)     stem="${stem%.dll}" ;;
   esac

   stem="${stem#lib}"
   r_lowercase "${stem}"
}


sde::test::r_verify_no_link_marks()
{
   log_entry "sde::test::r_verify_no_link_marks" "$@"

   local marks="$1"
   local platform="$2"

   r_lowercase "${platform}"
   platform="${RVAL}"

   case ",${marks}," in
      *,no-link,*|*,no-${platform}-link,*|*,no-platform-${platform},*|*,no-platform-${platform}-link,*)
         return 0
      ;;

      *,only-platform-${platform},*)
         return 1
      ;;

      *,only-platform-*,*)
         return 0
      ;;
   esac

   return 1
}


sde::test::r_verify_dependency_list_marks()
{
   log_entry "sde::test::r_verify_dependency_list_marks" "$@"

   local dependency_list="$1"
   local source_name="$2"

   RVAL="$(printf '%s\\n' "${dependency_list}" | awk -v name="${source_name}" '
      $2 == name || substr($2, length($2) - length(name)) == "/" name {
         if (marks != "")
            marks=marks ","
         marks=marks $3
      }
      END {
         print marks
      }')"
   [ -n "${RVAL}" ]
}


sde::test::r_verify_expected_missing_artifact()
{
   log_entry "sde::test::r_verify_expected_missing_artifact" "$@"

   local marks="$1"
   local platform="$2"
   local source_count="$3"
   local project_type="$4"

   if [ "${project_type}" = 'executable' ]
   then
      RVAL="executable project has no library artifact"
      return 0
   fi

   if sde::test::r_verify_no_link_marks "${marks}" "${platform}"
   then
      RVAL="no link artifact required for platform ${platform}"
      return 0
   fi

   if [ "${source_count}" -eq 0 ]
   then
      case ",${marks}," in
         *,no-share-shirk,*)
            RVAL="no sources in stash and no-share-shirk is set"
            return 0
         ;;
      esac
   fi

   RVAL=
   return 1
}


sde::test::verify_file_line()
{
   local prefix="$1"
   local filepath="$2"
   local mtime
   local size
   local absolute

   r_absolutepath "${filepath}"
   absolute="${RVAL}"
   mtime="$(modification_timestamp "${filepath}" 2>/dev/null)"
   size="$(file_size_in_bytes "${filepath}" 2>/dev/null)"
   printf "      %s: %s mtime=%s size=%s bytes\n" \
          "${prefix}" "${absolute}" "${mtime:-unknown}" "${size:-unknown}"
}


sde::test::verify()
{
   log_entry "sde::test::verify" "$@"

   local directory="$1"
   local requested="$2"
   local platform="${3:-${MULLE_UNAME}}"
   local sdk="${4:-Default}"
   local configuration="${5:-Debug}"
   local dependency_dir
   local stash_dir
   local dependency_list
   local artifacts
   local artifact
   local artifact_physical
   local unique_artifacts
   local artifact_name
   local artifact_stem
   local source_dir
   local source_name
   local source_project_name
   local source_project_type
   local source_key
   local source_files
   local source_file
   local artifact_mtime
   local source_mtime
   local newest_mtime
   local newest_source
   local artifact_count=0
   local matched_count=0
   local missing_count=0
   local source_count
   local newer_count
   local stale_count=0
   local incomplete_count=0
   local found_artifact
   local source_marks
   local comparison
   local nearby_executables
   local nearby_executable
   local nearby_executable_first
   local nearby_executable_count=0
   local stale_advice

   if [ -z "${directory}" ]
   then
      _internal_fail "verify directory is empty"
   fi

   dependency_dir="$(rexekutor mulle-env -E -d "${directory}" exec \
                              mulle-craft dependency dir \
                                 --sdk "${sdk}" \
                                 --platform "${platform}" \
                                 --configuration "${configuration}" 2>/dev/null)"
   if [ -z "${dependency_dir}" ]
   then
      dependency_dir="$(rexekutor mulle-env -E -d "${directory}" get --output-eval DEPENDENCY_DIR 2>/dev/null)"
   fi

   stash_dir="$(rexekutor mulle-env -E -d "${directory}" exec \
                          mulle-sourcetree stash-dir 2>/dev/null)"

   r_absolutepath "${directory}"
   directory="${RVAL}"
   if [ -n "${dependency_dir}" ]
   then
      r_absolutepath "${dependency_dir}"
      dependency_dir="${RVAL}"
   fi
   if [ -n "${stash_dir}" ]
   then
      r_absolutepath "${stash_dir}"
      stash_dir="${RVAL}"
   fi

   printf "TEST VERIFY: %s\n" "${requested}"
   printf "  test directory: %s\n" "${directory}"
   printf "  dependency directory: %s\n" "${dependency_dir}"
   printf "  source stash: %s\n" "${stash_dir}"
   printf "  style: sdk=%s platform=%s configuration=%s\n" \
          "${sdk}" "${platform}" "${configuration}"

   if [ -z "${dependency_dir}" -o ! -d "${dependency_dir}" ]
   then
      printf "  RESULT: INCOMPLETE -- dependency directory does not exist: %s\n" \
             "${dependency_dir:-<empty>}"
      printf "  OVERALL: INCOMPLETE\n"
      return 1
   fi

   if [ -z "${stash_dir}" -o ! -d "${stash_dir}" ]
   then
      printf "  RESULT: INCOMPLETE -- source stash does not exist: %s\n" \
             "${stash_dir:-<empty>}"
      printf "  OVERALL: INCOMPLETE\n"
      return 1
   fi

   artifacts="$(rexekutor find "${dependency_dir}" \( -type f -o -type l \) \
      \( -name '*.a' -o -name '*.so' -o -name '*.so.*' \
         -o -name '*.dylib' -o -name '*.dylib.*' -o -name '*.dll' \) \
      -print 2>/dev/null)"

   dependency_list="$(rexekutor "${MULLE_SDE:-mulle-sde}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                              -d "${directory}" \
                           dependency list -r -m 2>/dev/null)"

   unique_artifacts=
   while IFS= read -r artifact
   do
      [ -z "${artifact}" ] && continue
      r_resolve_all_path_symlinks "${artifact}"
      artifact_physical="${RVAL}"
      r_add_unique_line "${unique_artifacts}" "${artifact_physical}"
      unique_artifacts="${RVAL}"
   done <<< "${artifacts}"
   artifacts="${unique_artifacts}"

   artifact_count=0
   while IFS= read -r artifact
   do
      [ -z "${artifact}" ] && continue
      artifact_count=$((artifact_count + 1))
   done <<< "${artifacts}"

   source_count=0
   shell_enable_nullglob
   for source_dir in "${stash_dir}"/*
   do
      [ -e "${source_dir}" ] || continue
      [ -d "${source_dir}" ] || continue
      if [ -L "${source_dir}" ]
      then
         r_physicalpath "${source_dir}"
         source_dir="${RVAL}"
      fi

      r_absolutepath "${source_dir}"
      source_dir="${RVAL}"
      source_name="${source_dir##*/}"
      source_project_name="$(rexekutor mulle-env -s -d "${source_dir}" get --output-eval PROJECT_NAME 2>/dev/null)"
      source_project_name="${source_project_name:-${source_name}}"
      source_project_type="$(rexekutor mulle-env -s -d "${source_dir}" get --output-eval PROJECT_TYPE 2>/dev/null)"
      r_lowercase "${source_project_name#lib}"
      source_key="${RVAL}"
      source_marks=
      if sde::test::r_verify_dependency_list_marks "${dependency_list}" "${source_name}"
      then
         source_marks="${RVAL}"
      fi
      if [ -z "${source_marks}" ]
      then
         source_marks="$(rexekutor mulle-env -E -d "${directory}" exec \
                                   mulle-sourcetree --virtual-root \
                                      get "${source_project_name}" marks 2>/dev/null)"
      fi
      if [ -z "${source_marks}" -a "${source_name}" != "${source_project_name}" ]
      then
         source_marks="$(rexekutor mulle-env -E -d "${directory}" exec \
                                   mulle-sourcetree --virtual-root \
                                      get "${source_name}" marks 2>/dev/null)"
      fi
      if [ -z "${source_marks}" -a "${source_dir}" != "${source_name}" ]
      then
         source_marks="$(rexekutor mulle-env -E -d "${directory}" exec \
                                   mulle-sourcetree --virtual-root \
                                      get "${source_dir}" marks 2>/dev/null)"
      fi

      source_files="$(rexekutor find "${source_dir}" -type f \
         \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cxx' \
            -o -name '*.h' -o -name '*.hh' -o -name '*.hpp' -o -name '*.hxx' \
            -o -name '*.m' -o -name '*.mm' -o -name '*.inc' \
            -o -name '*.swift' -o -name '*.s' -o -name '*.S' \) \
         -not -path '*/.git/*' -not -path '*/.mulle/*' \
         -not -path '*/build/*' -not -path '*/cmake/*' \
         -not -path '*/kitchen/*' -print 2>/dev/null)"

      source_count=0
      while IFS= read -r source_file
      do
         [ -z "${source_file}" ] && continue
         source_count=$((source_count + 1))
      done <<< "${source_files}"

      found_artifact='NO'
      while IFS= read -r artifact
      do
         [ -z "${artifact}" ] && continue
         artifact_name="${artifact##*/}"
         sde::test::r_verify_artifact_stem "${artifact_name}"
         artifact_stem="${RVAL}"

         if [ "${artifact_stem}" != "${source_key}" ]
         then
            continue
         fi

         found_artifact='YES'
         matched_count=$((matched_count + 1))
         artifact_mtime="$(modification_timestamp "${artifact}" 2>/dev/null)"
         printf "\n  DEPENDENCY: %s\n" "${source_project_name}"
         sde::test::verify_file_line "artifact" "${artifact}"
         printf "      source root: %s\n" "${source_dir}"

         newer_count=0
         newest_mtime=''
         newest_source=''
         while IFS= read -r source_file
         do
            [ -z "${source_file}" ] && continue
            source_mtime="$(modification_timestamp "${source_file}" 2>/dev/null)"
            if [ -z "${newest_mtime}" ] || [ "${source_mtime:-0}" -gt "${newest_mtime}" ]
            then
               newest_mtime="${source_mtime}"
               newest_source="${source_file}"
            fi
            if [ "${source_mtime:-0}" -gt "${artifact_mtime:-0}" ]
            then
               newer_count=$((newer_count + 1))
               stale_count=$((stale_count + 1))
               sde::test::verify_file_line "NEWER SOURCE" "${source_file}"
            fi
         done <<< "${source_files}"

         if [ "${source_count}" -eq 0 ]
         then
            incomplete_count=$((incomplete_count + 1))
            printf "      conclusion: INCOMPLETE (no source files found)\n"
         else
            if [ -n "${newest_source}" ]
            then
               sde::test::verify_file_line "newest source" "${newest_source}"
            fi

            if [ "${newer_count}" -ne 0 ]
            then
               comparison='>'
            elif [ "${newest_mtime:-0}" -eq "${artifact_mtime:-0}" ]
            then
               comparison='='
            else
               comparison='<'
            fi
            if [ "${newer_count}" -ne 0 ]
            then
               printf "      conclusion: STALE (mtime %s %s mtime %s)\n" \
                      "${newest_mtime:-unknown}" "${comparison}" \
                      "${artifact_mtime:-unknown}"
            else
               printf "      conclusion: UPTODATE (mtime %s %s mtime %s)\n" \
                      "${newest_mtime:-unknown}" "${comparison}" \
                      "${artifact_mtime:-unknown}"
            fi
         fi
      done <<< "${artifacts}"

      if [ "${found_artifact}" != 'YES' ]
      then
         printf "\n  DEPENDENCY: %s\n" "${source_project_name}"
         printf "      source root: %s\n" "${source_dir}"
         if sde::test::r_verify_expected_missing_artifact \
               "${source_marks}" "${platform}" "${source_count}" \
               "${source_project_type}"
         then
            missing_count=$((missing_count + 1))
            printf "      conclusion: MISSING (expected: %s)\n" "${RVAL}"
         else
            missing_count=$((missing_count + 1))
            incomplete_count=$((incomplete_count + 1))
            printf "      conclusion: MISSING (no matching .a/.so/.dylib artifact found)\n"
         fi
      fi
   done
   shell_disable_nullglob

   nearby_executables="$(rexekutor find "${directory}" \
      \( -type f -o -type l \) -name '*.exe' -print 2>/dev/null)"
   if [ "${platform}" != 'windows' -a -n "${nearby_executables}" ]
   then
      while IFS= read -r nearby_executable
      do
         [ -z "${nearby_executable}" ] && continue
         if [ -z "${nearby_executable_first}" ]
         then
            nearby_executable_first="${nearby_executable}"
         fi
         nearby_executable_count=$((nearby_executable_count + 1))
      done <<< "${nearby_executables}"

      r_absolutepath "${nearby_executable_first}"
      log_warning "Found ${nearby_executable_count} .exe executable(s) near the ${platform} test; first: ${RVAL}. This may indicate wrong-platform test artifacts."
   fi

   printf "\nSUMMARY: artifacts=%s matched=%s missing=%s stale=%s incomplete=%s\n" \
          "${artifact_count}" "${matched_count}" "${missing_count}" \
          "${stale_count}" "${incomplete_count}"
   if [ "${stale_count}" -ne 0 ]
   then
      stale_advice="Stale dependencies detected. Run ${C_RESET_BOLD}mulle-sde test craft --all${C_INFO} to rebuild all test dependencies."
      log_vibe "${stale_advice}"
      log_warning "Advice: ${stale_advice}"
      printf "OVERALL: STALE\n"
      return 1
   fi
   if [ "${incomplete_count}" -ne 0 -o \( "${matched_count}" -eq 0 -a "${missing_count}" -eq 0 \) ]
   then
      printf "OVERALL: INCOMPLETE\n"
      return 1
   fi

   printf "OVERALL: UPTODATE\n"
   return 0
}


sde::test::main()
{
   log_entry "sde::test::main" "$@"

   local OPTION_PLATFORM=
   local OPTION_SDK=
   local OPTION_CONFIGURATION=
   local prepend

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::test::usage
         ;;

         --platform)
            [ $# -eq 1 ] && sde::test::usage "Missing argument to \"$1\""
            shift
            OPTION_PLATFORM="$1"
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::test::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::test::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --release)
            OPTION_CONFIGURATION='Release'
         ;;

         --debug)
            OPTION_CONFIGURATION='Debug'
         ;;

         --valgrind|--valgrind-no-leaks|--coverage|--objc-coverage|\
         --gdb|--sanitize-address|--sanitize-thread|--sanitize-undefined|\
         --testallocator|--zombie|--no-sanitizer)
            r_concat "${MULLE_TEST_FLAGS}" "$1"
            MULLE_TEST_FLAGS="${RVAL}"
         ;;

         --add-sanitizer|--sanitizer)
            [ $# -eq 1 ] && sde::test::usage "Missing argument to \"$1\""
            r_concat "${MULLE_TEST_FLAGS}" "$1"
            MULLE_TEST_FLAGS="${RVAL}"
            shift
            r_concat "${MULLE_TEST_FLAGS}" "$1"
            MULLE_TEST_FLAGS="${RVAL}"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-crun}"

   [ $# -ne 0 ] && shift

   # Strip --platform/--sdk/--configuration from $@ - these are managed by
   # mulle-sde-test.sh and must be specified before the command
   local _filtered_args=()
   while [ $# -ne 0 ]
   do
      case "$1" in
         --platform)
            [ $# -lt 2 ] && sde::test::usage "Missing argument to \"$1\""
            shift
            OPTION_PLATFORM="$1"
            shift
         ;;
         --sdk)
            [ $# -lt 2 ] && sde::test::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
            shift
         ;;
         --configuration)
            [ $# -lt 2 ] && sde::test::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
            shift
         ;;
         --release)
            OPTION_CONFIGURATION='Release'
            _filtered_args+=( "$1" )
            shift
         ;;
         --debug)
            OPTION_CONFIGURATION='Debug'
            _filtered_args+=( "$1" )
            shift
         ;;
         -h|--help|help)
            sde::test::usage
         ;;
         *)
            _filtered_args+=( "$1" )
            shift
         ;;
      esac
   done
   set -- "${_filtered_args[@]}"

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

   local PROJECT_TYPE
   case "${state}" in
      test*)
         # read PROJECT_TYPE from parent project, not the test subproject (which is 'none')
         PROJECT_TYPE="$(rexekutor "${MULLE_ENV:-mulle-env}" -d "${test_root}/.." get --output-eval PROJECT_TYPE 2>/dev/null)"
         if [ -z "${PROJECT_TYPE}" ]
         then
            # standalone test checkouts have no parent environment
            PROJECT_TYPE="$(rexekutor "${MULLE_ENV:-mulle-env}" -d "${test_root}" get --output-eval PROJECT_TYPE 2>/dev/null)"
         fi
      ;;
      *)
         PROJECT_TYPE="$(rexekutor "${MULLE_ENV:-mulle-env}" get --output-eval PROJECT_TYPE 2>/dev/null)"
      ;;
   esac

   # we could be running outside of every environment
   if [ -z "${MULLE_UNAME}" ]
   then
      MULLE_UNAME="$(PATH=/bin:/usr/bin uname -s 2> /dev/null | tr '[:upper:]' '[:lower:]')"
   fi

   local cmdchain
   local cleanargs

   #
   # Some commands need to run inside the project environment (platform variables)
   case "${cmd:-crun}" in
      clean)
         if [ "${MULLE_VIBECODING}" = 'YES' ]
         then
            # vibecoding always escalates clean to tidy
            r_colon_concat "${cmdchain}" "auto-clean"
            cmdchain="${RVAL}"
            cleanargs='tidy'
         elif [ $# -eq 0 ]
         then
            # Bare "mulle-sde test clean" should invalidate the tested dependency
            # instead of only cleaning the test project directory.
            r_colon_concat "${cmdchain}" "auto-clean"
            cmdchain="${RVAL}"
            cleanargs='project'
         else
            r_colon_concat "${cmdchain}" "clean"
            cmdchain="${RVAL}"
         fi
      ;;

      recraft|reccrun)
         r_colon_concat "${cmdchain}" "auto-clean"
         cmdchain="${RVAL}"

         cleanargs='all'
      ;;

      retest)
         r_colon_concat "${cmdchain}" "auto-clean"
         cmdchain="${RVAL}"

         cleanargs='tidy'

         # Persist platform setting if specified
         if [ ! -z "${OPTION_PLATFORM}" ]
         then
            sde::test::persist_platform_setting "${state}" "${test_directories}" "${OPTION_PLATFORM}"
         fi
      ;;

      tidy)
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
         log_warning "The 'generate' command has been removed. Use an AI assistant to generate test files."
         return 1
      ;;

      test*|craft|crun|crerun|rec|run|nrun|recrun|rerun)
         # handled later
      ;;

      craftorder|craftstatus|linkorder|link-args|log|status|dep|dependency|lib|library)
         local test_cmd="${cmd}"
         case "${test_cmd}" in
            linkorder) test_cmd='link-args' ;;
            dep)       test_cmd='dependency' ;;
            lib)       test_cmd='library' ;;
         esac
         case "${test_cmd}" in
            link-args|linkorder)
               case "${PROJECT_TYPE}" in
                  library|framework|executable)
                  ;;
                  *)
                     log_warning "link-args/linkorder is not available for ${PROJECT_TYPE} projects"
                     return 0
                  ;;
               esac
            ;;
         esac
         # For 'log' in test context, default to '*' (all projects) since the
         # test project itself has no main cmake build, only craftorder deps
         local log_args=( "$@" )
         if [ "${test_cmd}" = 'log' -a $# -eq 0 ]
         then
            log_args=( '*' )
         fi

         local generic_flags=()
         case "${test_cmd}" in
            craftstatus|status|dependency|library)
               # these don't accept --platform/--configuration
            ;;
            *)
               generic_flags=( --platform "${OPTION_PLATFORM}" \
                               --configuration "${OPTION_CONFIGURATION:-Debug}" )
            ;;
         esac

         case "${state}" in
            proj*)
               sde::test::r_test_directories
               sde::test::generic "${RVAL%%:*}" "${test_cmd}" \
                  "${generic_flags[@]}" \
                  "${log_args[@]}"
            ;;
            test*)
               sde::test::generic "${test_root}" "${test_cmd}" \
                  "${generic_flags[@]}" \
                  "${log_args[@]}"
            ;;
         esac
         return $?
      ;;

      verify|stale-check)
         local verify_directory
         local verify_requested
         local verify_directories

         if [ $# -eq 0 ]
         then
            case "${state}" in
               test*)
                  verify_requested="${test_root}"
               ;;
               *)
                  sde::test::r_test_directories "" "fail"
                  verify_directories="${RVAL}"
                  case "${verify_directories}" in
                     *:*)
                        sde::test::verify_usage "Specify a test environment. Available test environments: ${verify_directories}"
                     ;;
                     *)
                        verify_requested="${verify_directories}"
                     ;;
                  esac
               ;;
            esac
         elif [ $# -eq 1 ]
         then
            verify_requested="$1"
         else
            sde::test::verify_usage "Expected at most one test environment or source file"
         fi

         sde::test::r_verify_directory "${state}" "${test_root}" "${verify_requested}"
         verify_directory="${RVAL}"
         sde::test::verify "${verify_directory}" "${verify_requested}" \
                           "${OPTION_PLATFORM:-${MULLE_UNAME}}" \
                           "${OPTION_SDK:-Default}" \
                           "${OPTION_CONFIGURATION:-Debug}"
         return $?
      ;;

      config)
         local testdirs
         local testdir

         sde::test::r_test_directories "" "ignore"
         testdirs="${RVAL}"
         if [ -z "${testdirs}" ]
         then
            log_warning "No test directories found"
            return 0
         fi

         .foreachpath testdir in ${testdirs}
         .do
            log_info "Running config ${1} in ${C_RESET_BOLD}${testdir}"
            exekutor_mulle_sde "${testdir}" config "$@" || return $?
         .done
         return 0
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


   local test_directories

   case "${state}" in
      proj*)
         local _missing_dir_mode
         case "${cmd}" in
            test-dir) _missing_dir_mode="ignore" ;;
            *)        _missing_dir_mode="fail"   ;;
         esac
         sde::test::r_test_directories "" "${_missing_dir_mode}"
         test_directories="${RVAL}"
      ;;
   esac

   case "${cmd}" in
      test-dir)
         printf "%s\n" "${test_directories}"
         return 0
      ;;
   esac

   local clean_before_run='NO'

   cmdchain="${cmdchain:-${cmd}}"

   case ":${cmdchain}:" in
      *:clean:*|*:auto-clean:*)
      ;;

      *:craft:*|*:run:*)
         local clean_before_craft

         case "${state}" in
            proj*)
               clean_before_craft="$(mulle-env -s -E -d "${test_directories%%:*}" get --output-eval 'MULLE_SDE_CLEAN_BEFORE_CRAFT')"
               clean_before_run="$(mulle-env -s -E -d "${test_directories%%:*}" get --output-eval 'MULLE_TEST_CLEAN_BEFORE_RUN')"
            ;;

            test*)
               clean_before_craft="$(mulle-env -s get --output-eval 'MULLE_SDE_CLEAN_BEFORE_CRAFT')"
               clean_before_run="$(mulle-env -s get --output-eval 'MULLE_TEST_CLEAN_BEFORE_RUN')"
            ;;
         esac

         if [ "${clean_before_craft:-}" = 'YES' ]
         then
            local clean_default

            case "${state}" in
               proj*)
                  clean_default="$(mulle-env -s -E -d "${test_directories%%:*}" get --output-eval 'MULLE_SDE_CLEAN_DEFAULT')"
               ;;
               test*)
                  clean_default="$(mulle-env -s get --output-eval 'MULLE_SDE_CLEAN_DEFAULT')"
               ;;
            esac

            r_colon_concat "auto-clean" "${cmdchain}"
            cmdchain="${RVAL}"

            cleanargs="${clean_default:-project}"
         elif [ "${clean_before_run:-}" = 'YES' ]
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
   local banner
   local cmd_part style_part sdk_part platform_part configuration_part
   local crafted_styles
   local dependency_dir
   local exploded_cmdchain
   local last_banner
   local remaining
   local test_dir_for_platform
   local tidy_done='NO'
   local token
   local run_directory

   case "${state}" in
      proj*)
         # For project state, we'll handle platforms per test directory

         # If specific test directory was identified, use only that one
         if [ ! -z "${specific_test_directory}" ]
         then
            test_directories="${specific_test_directory}"
         fi

         .foreachpath test_dir_for_platform in ${test_directories}
         .do
            tidy_done='NO'
            sde::test::r_test_platforms "${test_dir_for_platform}"
            platforms="${RVAL}"

            if [ ! -z "${OPTION_PLATFORM}" -a "${OPTION_PLATFORM}" != 'all' ]
            then
               platforms="${OPTION_PLATFORM}"
            fi


            #
            # Resolve the *raw* dependency dir (no dispense/config subdir), so
            # that the link-args file check below looks in "<dep>/etc", which is
            # where the link-args writer (sde::test::link_args) and mulle-craft's
            # own donefile logic place their files. Use `mulle-craft tool-env
            # craft` (same source the writer uses); `mulle-craft dependency dir`
            # would append the dispense subdir (e.g. /Debug) and point at a
            # non-existent "<dep>/Debug/etc".
            #
            dependency_dir="$(rexekutor mulle-env -E -d "${test_dir_for_platform}" exec \
                                        mulle-craft tool-env craft 2>/dev/null \
                              | sed -n 's/^DEPENDENCY_DIR=.\(.*\).$/\1/p')"
            if [ -z "${dependency_dir}" ]
            then
               dependency_dir="$(mulle-env -E -d "${test_dir_for_platform}" get --output-eval DEPENDENCY_DIR 2>/dev/null)"
            fi

            sde::test::r_explode_cmdchain "${cmdchain}" \
                                          "${platforms}" \
                                          "${OPTION_SDK:-Default}" \
                                          "${OPTION_CONFIGURATION:-Debug}"
            exploded_cmdchain="${RVAL}"

            remaining="${exploded_cmdchain}"

            while [ ! -z "${remaining}" ]
            do
               token="${remaining%%:*}"
               if [ "${remaining}" = "${token}" ]
               then
                  remaining=""
               else
                  remaining="${remaining#*:}"
               fi

               cmd_part="${token%%.*}"
               style_part="${token#*.}"
               # style is sdk-platform-configuration
               sdk_part="${style_part%%-*-*}"
               configuration_part="${style_part##*-}"
               platform_part="${style_part#*-}"
               platform_part="${platform_part%-*}"

               log_debug "${cmd_part}::${state}::${platform_part}"

               banner="${platform_part}:${test_dir_for_platform}"
               if [ "${banner}" != "${last_banner}" ]
               then
                  last_banner="${banner}"
                  log_info "🔹🔹🔹 Test ${C_MAGENTA}${C_BOLD}${platform_part}${C_INFO} in ${C_RESET_BOLD}${test_dir_for_platform#${MULLE_USER_PWD}/}${C_INFO} 🔸🔸🔸"
               fi

               case "${cmd_part}" in
                  'auto-clean')
                     if [ "${cleanargs}" = 'tidy' -a "${tidy_done}" = 'YES' ]
                     then
                        log_debug "Skipping tidy (already done)"
                     else
                        if [ "${cleanargs}" = 'project' ]
                        then
                           target="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'MULLE_SDE_CLEAN_DEFAULT')"
                           if [ -z "${target}" ]
                           then
                              target="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'TEST_PROJECT_NAME')"
                              if [ -z "${target}" ]
                              then
                                 target="$(mulle-env -d "${test_dir_for_platform}" -s get --output-eval 'PROJECT_NAME')"
                              fi
                           fi
                        else
                           target="${cleanargs}"
                        fi

                        if ! sde::test::auto_clean "${test_dir_for_platform}" "${target:-all}" --platform "${platform_part}" "$@"
                        then
                           if [ "${OPTION_LENIENT}" != 'YES' ]
                           then
                              exit 1
                           fi
                        fi

                        if [ "${cleanargs}" = 'tidy' ]
                        then
                           tidy_done='YES'
                        fi
                     fi
                  ;;

                  'clean')
                     if ! sde::test::generic "${test_dir_for_platform}" "${cmd_part}" --platform "${platform_part}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi
                  ;;

                  'craft'|'postprocess'|'update-link-args'|'link-args')
                     if ! sde::test::${cmd_part//-/_} "${test_dir_for_platform}" --platform "${platform_part}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi
                  ;;

                  'run'|'rerun')
                     # If link file missing, prepend craft steps to remaining chain (once only)
                     include "test::link-args"
                     if case "${PROJECT_TYPE}" in library|framework) true ;; *) false ;; esac && \
                        ! test::link_args::r_linkfile_path "${dependency_dir}" \
                                                           "${platform_part}" \
                                                           "${sdk_part}" \
                                                           "${configuration_part}"
                     then
                        case ":${crafted_styles}:" in
                           *":${style_part}:"*)
                              log_warning "Craft did not produce link file for ${platform_part}, skipping"
                           ;;
                           *)
                              log_debug "Link file missing for ${platform_part}, crafting first..."
                              r_colon_concat "${crafted_styles}" "${style_part}"
                              crafted_styles="${RVAL}"
                              prepend="craft.${style_part}:postprocess.${style_part}:update-link-args.${style_part}:${cmd_part}.${style_part}"
                              remaining="${prepend}${remaining:+:${remaining}}"
                              continue
                           ;;
                        esac
                     else
                        run_directory=""
                        if ! sde::test::r_validate_test_run_paths "$@"
                        then
                           return 1
                        fi
                        run_directory="${RVAL}"

                        if [ ! -z "${run_directory}" ]
                        then
                           exekutor_mulle_test "${run_directory}" --platform "${platform_part}" "${cmd_part}" "$@"
                        else
                           if ! exekutor_mulle_test "${test_dir_for_platform}" --platform "${platform_part}" "${cmd_part}" "$@"
                           then
                              if [ "${OPTION_LENIENT}" != 'YES' ]
                              then
                                 exit 1
                              fi
                           fi
                        fi
                     fi
                  ;;
               esac
            done
         .done
      ;;

      test*)
         sde::test::r_test_platforms "${test_root}"
         platforms="${RVAL}"

         if [ ! -z "${OPTION_PLATFORM}" -a "${OPTION_PLATFORM}" != 'all' ]
         then
            platforms="${OPTION_PLATFORM}"
         fi

         #
         # Resolve the *raw* dependency dir (no dispense/config subdir), matching
         # the link-args writer (sde::test::link_args) so the link-file check
         # below looks in "<dep>/etc" (not the non-existent "<dep>/Debug/etc").
         # See the matching resolution in the 'proj*' branch above.
         #
         dependency_dir="$(rexekutor mulle-env -E -d "${test_root}" exec \
                                     mulle-craft tool-env craft 2>/dev/null \
                           | sed -n 's/^DEPENDENCY_DIR=.\(.*\).$/\1/p')"
         if [ -z "${dependency_dir}" ]
         then
            dependency_dir="$(mulle-env -E -d "${test_root}" get --output-eval DEPENDENCY_DIR 2>/dev/null)"
         fi

         sde::test::r_explode_cmdchain "${cmdchain}" \
                                       "${platforms}" \
                                       "${OPTION_SDK:-Default}" \
                                       "${OPTION_CONFIGURATION:-Debug}"
         exploded_cmdchain="${RVAL}"
         remaining="${exploded_cmdchain}"

         while [ ! -z "${remaining}" ]
         do
            token="${remaining%%:*}"
            if [ "${remaining}" = "${token}" ]
            then
               remaining=""
            else
               remaining="${remaining#*:}"
            fi

            cmd_part="${token%%.*}"
            style_part="${token#*.}"
            sdk_part="${style_part%%-*-*}"
            configuration_part="${style_part##*-}"
            platform_part="${style_part#*-}"
            platform_part="${platform_part%-*}"

            log_debug "${cmd_part}::${state}::${platform_part}"

            if [ "${platform_part}" != "${last_banner}" ]
            then
               last_banner="${platform_part}"
               log_info "🔹🔹🔹 Test ${C_MAGENTA}${C_BOLD}${platform_part}${C_INFO} 🔸🔸🔸"
            fi

            # TODO: this is manual fix in this vibecode.. not really sure...
            directory="${PWD}"

            case "${cmd_part}" in
               'auto-clean')
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

                     if ! sde::test::auto_clean "${directory}" "${target:-all}" --platform "${platform_part}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi

                     if [ "${cleanargs}" = 'tidy' ]
                     then
                        tidy_done='YES'
                     fi
                  fi
               ;;

               'clean')
                  if ! sde::test::generic "${directory}" "${cmd_part}" --platform "${platform_part}" "$@"
                  then
                     if [ "${OPTION_LENIENT}" != 'YES' ]
                     then
                        exit 1
                     fi
                  fi
               ;;

               'craft'|'postprocess'|'update-link-args'|'link-args')
                  if ! sde::test::${cmd_part//-/_} "${directory}" --platform "${platform_part}" "$@"
                  then
                     if [ "${OPTION_LENIENT}" != 'YES' ]
                     then
                        exit 1
                     fi
                  fi
               ;;

               'run'|'rerun')
                  # If link file missing, prepend craft steps to remaining chain (once only)
                  include "test::link-args"
                  if case "${PROJECT_TYPE}" in library|framework) true ;; *) false ;; esac && \
                     ! test::link_args::r_linkfile_path "${dependency_dir}" \
                                                        "${platform_part}" \
                                                        "${sdk_part}" \
                                                        "${configuration_part}"
                  then
                     case ":${crafted_styles}:" in
                        *":${style_part}:"*)
                           log_warning "Craft did not produce link file for ${platform_part}, skipping"
                        ;;
                        *)
                           log_debug "Link file missing for ${platform_part}, crafting first..."
                           r_colon_concat "${crafted_styles}" "${style_part}"
                           crafted_styles="${RVAL}"
                           prepend="craft.${style_part}:postprocess.${style_part}:update-link-args.${style_part}:${cmd_part}.${style_part}"
                           remaining="${prepend}${remaining:+:${remaining}}"
                           continue
                        ;;
                     esac
                  else
                     if ! exekutor_mulle_test "${directory}" --platform "${platform_part}" "${cmd_part}" "$@"
                     then
                        if [ "${OPTION_LENIENT}" != 'YES' ]
                        then
                           exit 1
                        fi
                     fi
                  fi
               ;;
            esac
         done
      ;;
   esac
}
