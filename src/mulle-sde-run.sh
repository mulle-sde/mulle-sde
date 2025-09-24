# shellcheck shell=bash
#
#   Copyright (c) 2025 Nat! - Mulle kybernetiK
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
MULLE_SDE_RUN_SH='included'


sde::run::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options] [arguments] ...

   Run the main executable of the given project, with the arguments given.
   The executable will run within the mulle-sde environment unless -e is
   given.

Options:
   --     : pass remaining options as arguments
   -e     : run the main executable outside of the mulle-sde environment.
   -b     : run the executable in the background, ignores timeout (&)
   -t <s> : run the executable within timeout, stopping after 's' seconds

Environment:
   MULLE_SDE_RUN         : command to use, use \${EXECUTABLE} as variable
   MULLE_SDE_PRE_RUN     : command before executable starts
   MULLE_SDE_POST_RUN    : command after executable has started, implies -b
   MULLE_SDE_RUN_TIMEOUT : run the executable with a timeout value by default
   MULLE_SDE_CRAFT_BEFORE_RUN : always do a \`mulle-sde craft\` before running if YES

EOF
   exit 1
}


sde::run::vibecodehelp()
{
   local executablename="$1"

   if [ ! -z $(dir_list_files demo/src 'main-executable.*' 'f')  ]
   then
      log_info "There is a demo of the same name though:
${C_RESET_BOLD}cd demo && mulle-sde run ${executablename}"
      return
   fi

   if [ ! -d test ]
   then
      log_info "Hint: to run tests use
${C_RESET_BOLD}mulle-sde test run ${executablename}.${PROJECT_EXTENSIONS}"
   fi
}


sde::run::main()
{
   log_entry "sde::run::main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_SDK
   local OPTION_EXISTS
   local OPTION_NAME
   local OPTION_SDE_RUN_ENV='YES'
   local MUDO_FLAGS="-E"
   local OPTION_BACKGROUND='DEFAULT'
   local OPTION_SDE_RUN_ENV='YES'
   local OPTION_DEBUG_ENV='DEFAULT'
   local OPTION_TIMEOUT='DEFAULT'
   local OPTION_CRAFT='DEFAULT'
   local OPTION_STACKTRACE

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::run::usage
         ;;

         --if-exists)
            OPTION_EXISTS='YES'
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::run::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --craft)
            OPTION_CRAFT='YES'
         ;;

         --no-craft)
            OPTION_CRAFT='NO'
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::run::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
         ;;

         --select)
            OPTION_SELECT='YES'
         ;;

         --release)
            OPTION_CONFIGURATION="Release"
         ;;

         --debug)
            OPTION_CONFIGURATION="Debug"
         ;;

         --no-run-env)
            OPTION_SDE_RUN_ENV='NO'
         ;;

         -e|-E)
            MUDO_FLAGS="$1"
            shift
         ;;

         --restrict|--restrict-environment)
            MUDO_FLAGS=''
         ;;

         -b|--background)
            OPTION_BACKGROUND='YES'
            shift
         ;;

         --no-background|--foreground)
            OPTION_BACKGROUND='NO'
            shift
         ;;

         --objc-trace-leak|--leak|--trace-leak)
            OPTION_DEBUG_ENV='LEAK'
         ;;

         --objc-trace-zombie|--zombie|--trace-zombie)
            OPTION_DEBUG_ENV='ZOMBIE'
         ;;

         --no-objc-trace-zombie|--no-zombie|--no-trace-zombie)
            OPTION_DEBUG_ENV='NONE'
         ;;

         --objc-stacktrace)
            OPTION_STACKTRACE='mulle-gdb'
         ;;

         --stacktrace)
            OPTION_STACKTRACE='gdb'
         ;;

         -t|--timeout)
            [ $# -eq 1 ] && sde::run::usage "Missing argument to \"$1\""
            shift

            OPTION_TIMEOUT="$1"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::run::usage "Unknown option \"$1\""
         ;;

         *)
            OPTION_NAME="$1"
            shift
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_CRAFT}" = 'DEFAULT' ]
   then
      OPTION_CRAFT="${MULLE_SDE_CRAFT_BEFORE_RUN:-NO}"
   fi

   if [ "${OPTION_CRAFT}" = 'YES' ]
   then
      rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} craft || exit 1
   fi

   case "${OPTION_DEBUG_ENV}" in
      'DEFAULT')
         r_concat "${OPTION_ENVIRONMENT}" "NSZombieEnabled=YES"
         r_concat "${RVAL}" "NSDeallocateZombies=YES"
         OPTION_ENVIRONMENT="${RVAL}"
      ;;

      'ZOMBIE')
         r_concat "${OPTION_ENVIRONMENT}" "MULLE_OBJC_TRACE_ZOMBIE='YES'"
         OPTION_ENVIRONMENT="${RVAL}"
      ;;

      'LEAK')
         r_concat "${OPTION_ENVIRONMENT}" "MULLE_TESTALLOCATOR='3'"
         r_concat "${RVAL}" "MULLE_OBJC_TRACE_LEAK='YES'"
         OPTION_ENVIRONMENT="${RVAL}"
      ;;
   esac

   local debugger 

   case "${OPTION_STACKTRACE}" in
      'gdb'|'mulle-gdb')
         if [ "${OPTION_BACKGROUND}" = 'YES' ]
         then
            fail "You can't mix --timout with --background"
         fi

         debugger="${OPTION_STACKTRACE} --batch \
-ex run \
-ex bt \
-ex 'set confirm off' \
-ex quit \
--args "
      ;;
   esac

   local EXECUTABLE

   # shellcheck source=src/mulle-sde-product.sh
   include "sde::product"

   local EXECUTABLE_NAME

   if [ -x "${OPTION_NAME}" ]
   then
      EXECUTABLE="${OPTION_NAME}"
   else
      if ! sde::product::r_executable "${OPTION_NAME}"
      then
         sde::run::vibecodehelp "${OPTION_NAME}"
         return 1
      fi
      EXECUTABLE="${RVAL}"
   fi
   r_basename "${EXECUTABLE}"
   EXECUTABLE_NAME="${RVAL}"

   local commandline
   local post_commandline
   local pre_commandline

   if [ "${OPTION_RUN_ENV}" = 'YES' ]
   then
      commandline="`mulle-sde env get MULLE_SDE_RUN`"
      pre_commandline="`mulle-sde env get MULLE_SDE_PRE_RUN`"
      post_commandline="`mulle-sde env get MULLE_SDE_POST_RUN`"
   fi


   if [ ! -z "${post_commandline}" -a "${OPTION_BACKGROUND}" = 'DEFAULT' ]
   then
      OPTION_BACKGROUND='YES'
   fi

   local environment

   environment="${OPTION_ENVIRONMENT}"

   log_setting "MULLE_SDE_RUN      : ${commandline}"
   log_setting "MULLE_SDE_PRE_RUN  : ${pre_commandline}"
   log_setting "MULLE_SDE_POST_RUN : ${post_commandline}"
   log_setting "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"

   if [ "${OPTION_TIMEOUT}" = 'DEFAULT' ]
   then
      OPTION_TIMEOUT="${MULLE_SDE_RUN_TIMEOUT}"
   fi

   log_setting "OPTION_TIMEOUT     : ${OPTION_TIMEOUT}"

   local timeout

   if [ "${OPTION_TIMEOUT:-0}" -gt 0 ]
   then
      local timeout_exe

      if [ "${OPTION_BACKGROUND}" = 'YES' ]
      then
         fail "You can't mix --timeout with --background"
      fi

      if ! timeout_exe="`command -v 'mulle-timeout'`"
      then
         log_warning "mulle-timeout command not available"
      else
         timeout="mulle-timeout ${OPTION_TIMEOUT}"
      fi
   fi

   if [ ! -z "${pre_commandline}" ]
   then
      r_expanded_string "${pre_commandline}"
      pre_commandline="${RVAL}"

      # we don't push "$@" unto the post run though, if this is a problem
      # pass it as an environment variable (and a wrapper shell script)
      log_verbose "Use MULLE_SDE_PRE_RUN '${pre_commandline}' as command line"
      eval_exekutor mudo ${MUDO_FLAGS} -f "${pre_commandline}"
   fi

   local rval

   if [ ! -z "${commandline}" ]
   then
      r_expanded_string "${commandline}"
      commandline="${RVAL}"

      log_verbose "Use MULLE_SDE_RUN '${commandline}' as command line"
      if [ "${OPTION_BACKGROUND}" = 'YES' ]
      then
         eval_exekutor mudo ${MUDO_FLAGS} -f ${environment} "${commandline}" "$@" &
      else
         eval_exekutor ${timeout} mudo ${MUDO_FLAGS} -f ${environment} ${debugger} "${commandline}" "$@"
         rval=$?
      fi
   else
      if [ "${OPTION_BACKGROUND}" = 'YES' ]
      then
         exekutor mudo ${MUDO_FLAGS} -f ${environment} "${EXECUTABLE}" "$@" &
      else
         exekutor ${timeout} mudo ${MUDO_FLAGS} -f ${environment} ${debugger} "${EXECUTABLE}" "$@"
         rval=$?
      fi
   fi

   if [ $rval -eq 124 -a ! -z "${timeout}" ]
   then
      _log_error "${C_RESET_BOLD}${EXECUTABLE_NAME}${C_ERROR} has reached the ${OPTION_TIMEOUT} second timeout
${C_VERBOSE}To run indefinitely:
${C_RESET_BOLD}mulle-sde run -t 0 ${EXECUTABLE_NAME}"
   fi

   if [ ! -z "${post_commandline}" ]
   then
      r_expanded_string "${post_commandline}"
      post_commandline="${RVAL}"

      # we don't push "$@" unto the post run though, if this is a problem
      # pass it as an environment variable (and a wrapper shell script)
      log_verbose "Use MULLE_SDE_POST_RUN '${post_commandline}' as command line"
      eval_exekutor mudo ${MUDO_FLAGS} -f "${post_commandline}"
   fi
}
