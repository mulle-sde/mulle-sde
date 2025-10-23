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

sde::vibecoding::main()
{
   log_entry "sde::vibecoding::main" "$@"

   local cmd="$1"

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
      ;;

      1)
         case "$1" in
            'y'*|'Y'*|on|ON)
            ;;

            'n'*|'N'*|off|OFF)
               flag='NO'
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

   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CLEAN_BEFORE_CRAFT'   "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_REFLECT_BEFORE_CRAFT' "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_TEST_AFTER_CRAFT'     "${OPTION_TEST}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_TEST_CLEAN_BEFORE_RUN'    "${flag}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_RUN_TIMEOUT'          "${timeout}"
   sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CRAFT_BEFORE_RUN'     "${flag}"

   local dir

   MULLE_SDE_DEMO_PATH="${MULLE_SDE_DEMO_PATH:-demo}"

   .foreachpath dir in ${MULLE_SDE_DEMO_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         cd "${dir}"


         log_verbose "Set ${C_RESET_BOLD}$dir${C_VERBOSE} to ${C_MAGENTA}${C_BOLD}${verb}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CLEAN_BEFORE_CRAFT'   "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_REFLECT_BEFORE_CRAFT' "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_RUN_TIMEOUT'          "${timeout}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CRAFT_BEFORE_RUN'     "${flag}"
      )
      fi
   .done

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         log_verbose "Set ${C_RESET_BOLD}$dir${C_VERBOSE} to ${C_MAGENTA}${C_BOLD}${verb}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_CLEAN_BEFORE_CRAFT'   "${flag}"
         sde::vibecoding::env_set "${OPTION_SCOPE}" 'MULLE_SDE_REFLECT_BEFORE_CRAFT' "${flag}"
      )
      fi
   .done
}
