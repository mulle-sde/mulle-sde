# shellcheck shell=bash
#
#   Copyright (c) 2022 Nat! - Mulle kybernetiK
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
MULLE_SDE_VIBECODING_SH='included'


#
# Check if craft should be redirected to test craft in vibecoding mode
# This is called from the PROJECT directory (not test directory)
#
sde::vibecoding::check_craft_vs_test_craft()
{
   log_entry "sde::vibecoding::check_craft_vs_test_craft" "$@"

   [ "${MULLE_VIBECODING}" != 'YES' ] && return 0

   # Check if --mulle-test is already in the arguments
   local arg

   for arg in "$@"
   do
      case "${arg}" in
         --mulle-test)
            return 0
         ;;
      esac
   done

   # Check if test directories exist
   local test_directories

   test_directories="$(mulle-env environment get MULLE_SDE_TEST_PATH 2>/dev/null)"
   test_directories="${test_directories:-test}"

   local dir

   .foreachpath dir in ${test_directories}
   .do
      if [ -d "${dir}" -a "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "Crafting disabled as ${C_MAGENTA}${C_BOLD}vibecoding${C_ERROR} is enabled and a test folder exists.
${C_INFO}Vibecoding is test-driven development. So use this instead:
   ${C_RESET_BOLD}mulle-sde test craft"
      fi
   .done
}


# Check if log should be redirected to test log in vibecoding mode
# This is called from the PROJECT directory (not test directory)
#
sde::vibecoding::check_log_vs_test_log()
{
   log_entry "sde::vibecoding::check_log_vs_test_log" "$@"

   [ "${MULLE_VIBECODING}" != 'YES' ] && return 0

   # Check if test directories exist
   local test_directories

   test_directories="$(mulle-env environment get MULLE_SDE_TEST_PATH 2>/dev/null)"
   test_directories="${test_directories:-test}"

   local dir

   .foreachpath dir in ${test_directories}
   .do
      if [ -d "${dir}" -a "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "Log disabled as ${C_MAGENTA}${C_BOLD}vibecoding${C_ERROR} is enabled and a test folder exists.
${C_INFO}Vibecoding is test-driven development. So use this instead:
   ${C_RESET_BOLD}mulle-sde test log"
      fi
   .done
}


sde::vibecoding::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} vibecoding [options] [on|off]

   Set some project default so forgetful AIs get automatic reflection and
   craft clean setups. You can use 'sweatcoding' instead of 'vibecoding'
   to invert the meaning.

   With the \`--test\` option you can enforce running tests after each craft,
   which is probably not a good idea, because it slows the AI down massively
   and will impede progressive ideas. This only applies to mulle-test
   style tests.

Options:
   --test : run tests after craft (if a "test" folder is available)

Environment:
   MULLE_SDE_CLEAN_BEFORE_CRAFT   : set to ON for vibecoding
   MULLE_SDE_REFLECT_BEFORE_CRAFT : set to ON for vibecoding
   MULLE_SDE_TEST_AFTER_CRAFT'    : set to ON with --test always
   MULLE_TEST_CLEAN_BEFORE_RUN    : set to ON for vibecoding
EOF
   exit 1
}


sde::vibecoding::env_set()
{
   local scope="$1"
   local variable="$2"
   local flag="$3"

   rexekutor mulle-env --search-here ${MULLE_TECHNICAL_FLAGS}  \
                       env --scope "${scope}"           \
                           set "${variable}" "${flag}"
}


sde::vibecoding::list_info()
{
   log_entry "sde::vibecoding::list_info" "$@"

   local here

   r_basename "${PWD}"
   here="${RVAL}"

   local flag

   flag=$(rexekutor mulle-env --search-here get MULLE_VIBECODING)
   if [ "${flag}" = 'YES' ]
   then
      log_info "Vibecoding is enabled in ${C_RESET_BOLD}${here}"
   else
      log_info "Vibecoding is disabled in ${C_RESET_BOLD}${here}"
   fi
}


sde::vibecoding::list()
{
   log_entry "sde::vibecoding::list" "$@"

   sde::vibecoding::list_info

   local dir

   .foreachpath dir in ${MULLE_SDE_DEMO_PATH:-demo}
   .do
      if [ -d "${dir}" ]
      then
      (
         printf " ${C_INFO}* "
         cd "${dir}" &&
         sde::vibecoding::list_info
      )
      fi
   .done

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         printf " ${C_INFO}* "
         cd "${dir}" &&
         sde::vibecoding::list_info
      )
      fi
   .done
}


sde::vibecoding::main()
{
   log_entry "sde::vibecoding::main" "$@"

   local cmd="$1" # vibecoding or sweatcoding

   local OPTION_SCOPE="user-${MULLE_USERNAME}"
   local OPTION_TEST='NO'

   shift 

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::vibecoding::usage
         ;;

         --global)
            OPTION_SCOPE="${1#--}"
         ;;

         --test)
            OPTION_TEST='YES'
         ;;

         --scope)
            [ $# -eq 1 ] && sde::product::usage "Missing argument to \"$1\""
            shift

            OPTION_SCOPE="$1"
         ;;

         -*)
            sde::vibecoding::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local flag 

   flag='YES'
   case $# in 
      0) 
         if [ "${cmd}" != 'sweatcoding' ]
         then
            sde::vibecoding::list
            return
         fi
      ;;

      1)
         case "$1" in
            'y'*|'Y'*|on|ON)
            ;;

            'n'*|'N'*|off|OFF)
               flag='NO'
            ;;

            'list')
               sde::vibecoding::list
               return
            ;;

            *)
               sde::vibecoding::usage "Need on/off got $1"
            ;;
         esac
      ;;

      *)
         shift
         sde::vibecoding::usage "Superflous arguments $*"
      ;;
   esac


   if [ "${cmd}" = 'sweatcoding' ]
   then
      if [ "${flag}" = 'YES' ]
      then
         flag='NO'
      else 
         flag='YES'
      fi
   fi

   local timeout
   local verb

   case "${flag}" in
      'YES')
         verb="vibecoding"
         timeout=5
      ;;

      'NO')
         verb="sweatcoding"
         timeout=0
      ;;
   esac

   log_info "Set ${C_RESET_BOLD}${PROJECT_NAME}${C_INFO} to ${C_MAGENTA}${C_BOLD}${verb}"

   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_VIBECODING'               "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CLEAN_BEFORE_CRAFT'   "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_REFLECT_BEFORE_CRAFT' "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CRAFT_BEFORE_RUN'     "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_RUN_TIMEOUT'          "${timeout}"

   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_TEST_AFTER_CRAFT'     "${OPTION_TEST}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_TEST_CLEAN_BEFORE_RUN'    "${flag}"

   local dir

   MULLE_SDE_DEMO_PATH="${MULLE_SDE_DEMO_PATH:-demo}"

   .foreachpath dir in ${MULLE_SDE_DEMO_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         rexekutor cd "${dir}"

         log_info "Set ${C_RESET_BOLD}${dir}${C_INFO} to ${C_MAGENTA}${C_BOLD}${verb}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_VIBECODING'               "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CLEAN_BEFORE_CRAFT'   "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CRAFT_BEFORE_RUN'     "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_REFLECT_BEFORE_CRAFT' "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_RUN_TIMEOUT'          "${timeout}"

         # ok demos have no tests
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_TEST_AFTER_CRAFT'     'NO'
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_TEST_CLEAN_BEFORE_RUN'    'NO'
      )
      fi
   .done

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         rexekutor cd "${dir}"

         log_info "Set ${C_RESET_BOLD}${dir}${C_INFO} to ${C_MAGENTA}${C_BOLD}${verb}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_VIBECODING'               "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CLEAN_BEFORE_CRAFT'   "${flag}"
         # test does this differently
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CRAFT_BEFORE_RUN'     'YES'
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_REFLECT_BEFORE_CRAFT' 'NO'
         # test does this differently too,
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_RUN_TIMEOUT'           $(( timeout * 20 ))

         # tests have no tests
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_TEST_AFTER_CRAFT'     'NO'
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_TEST_CLEAN_BEFORE_RUN'    "${flag}"
      )
      fi
   .done
}
