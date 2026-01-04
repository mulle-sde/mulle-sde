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


sde::run::r_emulator_for_platform()
{
   log_entry "sde::run::r_emulator_for_platform" "$@"

   local platform="$1"
   
   # Native platform needs no emulator
   if [ "${platform}" = "${MULLE_UNAME}" ]
   then
      RVAL=""
      return 0
   fi
   
   # Look up MULLE_EMULATOR_<PLATFORM> (uppercase)
   local varname
   
   r_uppercase "${platform}"
   varname="MULLE_EMULATOR_${RVAL}"
   
   RVAL="${!varname}"
   
   if [ -z "${RVAL}" ]
   then
      log_warning "Executable is for ${platform} but no emulator configured (set ${varname})"
      return 1
   fi
   
   # Check if emulator command exists
   local emulator_cmd="${RVAL%% *}"  # Get first word
   
   if ! command -v "${emulator_cmd}" >/dev/null 2>&1
   then
      log_warning "Emulator '${emulator_cmd}' not found in PATH"
      return 1
   fi
   
   log_verbose "Using emulator '${RVAL}' for ${platform} executable"
   return 0
}


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
   --                   : pass remaining options as arguments
   -e                   : run executable outside of the mulle-sde environment.
   --background         : run executable in the background, ignore timeout (&)
   --timeout <s>        : run executable but stop after 's' seconds
   --mulleui-frames <n> : run mulleui executable for <n> frames from start (0)
   --mulleui-trace <nr> : trace drawing calls starting at frame <nr>

Environment:
   MULLE_SDE_RUN         : command to run: use \${EXECUTABLE} as variable
   MULLE_SDE_PRE_RUN     : command before executable starts
   MULLE_SDE_POST_RUN    : command after executable has started, implies -b
   MULLE_SDE_RUN_TIMEOUT : run the executable with a timeout value by default
   MULLE_SDE_CRAFT_BEFORE_RUN : \`mulle-sde craft\` before running, if YES
   MULLE_EMULATOR_<PLATFORM> : emulator for cross-platform executables
                               (e.g. MULLE_EMULATOR_WINDOWS=wine)
   MULLEUI_VIBECODE      : YES sets --mulleui-frames 1 and --mulleui-trace-draw
EOF
   exit 1
}


sde::run::vibecodehelp()
{
   log_entry "sde::run::vibecodehelp" "$@"

   local executablename="$1"

   r_extensionless_basename "${executablename#main-}"
   executablename="${RVAL}"

   local directory

   r_basename "${MULLE_USER_PWD}"
   directory="${RVAL}"

   if [ "${RVAL}" = 'demo' ]
   then
      directory="${MULLE_USER_PWD}/src"
   else
      directory="${MULLE_USER_PWD}/demo/src"
   fi

   if [ ! -z "$(dir_list_files "${directory}"  "main-${executablename}.*" 'f' 2> /dev/null)"  ]
   then
      r_dirname "${directory}"
      log_info "Did you mean ${C_RESET_BOLD}${executablename}${C_INFO} ? Run this instead:
${C_RESET_BOLD}   (cd \"${RVAL}\" && mulle-sde run ${executablename})"
      return
   fi

   if [ ! -d test ]
   then
      log_info "Hint: to run tests use
${C_RESET_BOLD}mulle-sde test run ${executablename}.${PROJECT_EXTENSIONS%%:*}"
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
   local OPTION_MULLEUI_FRAMES
   local OPTION_MULLEUI_START
   local OPTION_MULLEUI_DEBUG

   if [ "${MULLEUI_VIBECODE}" = 'YES' ]
   then
      log_verbose "MULLEUI_VIBECODE enabled draw tracing and exit after single frame"

      OPTION_MULLEUI_FRAMES=1
      OPTION_MULLEUI_TRACE=0
   fi

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

         --mulleui-frames|--mulle-ui-frames)
            [ $# -eq 1 ] && sde::run::usage "Missing argument to \"$1\""
            shift
            OPTION_MULLEUI_FRAMES="$1"
         ;;

         --mulleui-trace|--mulle-ui-trace)
            [ $# -eq 1 ] && sde::run::usage "Missing argument to \"$1\""
            shift
            OPTION_MULLEUI_START="$1"
         ;;

         --mulleui-debug|--mulle-ui-debug)
            [ $# -eq 1 ] && sde::run::usage "Missing argument to \"$1\""
            shift
            OPTION_MULLEUI_DEBUG="$1"
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

   if [ ! -z "${OPTION_MULLEUI_FRAMES}" ]
   then
      r_concat "${OPTION_ENVIRONMENT}" "UIPureWindowMaxRenderedFrames=${OPTION_MULLEUI_FRAMES}"
      OPTION_ENVIRONMENT="${RVAL}"
   fi

   if [ ! -z "${OPTION_MULLEUI_START}" ]
   then
      r_concat "${OPTION_ENVIRONMENT}" "UIPureWindowStartTraceAtFrame=${OPTION_MULLEUI_START}"
      OPTION_ENVIRONMENT="${RVAL}"
   fi

   if [ "${OPTION_MULLEUI_DEBUG}" = 'YES' ]
   then
      r_concat "${OPTION_ENVIRONMENT}" "UIWindowDebuggingFlags=0x8008"
      r_concat "${RVAL}" "CGContextDebuggingFlags=08008"
      OPTION_ENVIRONMENT="${RVAL}"
   fi


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
         if [ -z "${OPTION_NAME}" ]
         then
            log_error "Could not find an executable product"
            return 1
         fi

         log_error "Could not find a product named \"${OPTION_NAME}\""
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
      if [ ! -z "${OPTION_TIMEOUT}" ]
      then
         log_vibe "Timeout set to ${OPTION_TIMEOUT} seconds from MULLE_SDE_RUN_TIMEOUT"
      fi
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
         if [ "${MULLE_FLAG_LOG_VERBOSE:-}" = 'YES' ]
         then
            timeout="mulle-timeout -v ${OPTION_TIMEOUT}"
         else
            timeout="mulle-timeout ${OPTION_TIMEOUT}"
         fi
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

   # Detect platform and get emulator if needed
   local platform
   local emulator

   sde::product::r_platform_from_executable_path "${EXECUTABLE}"
   platform="${RVAL}"
   
   log_setting "EXECUTABLE_PLATFORM: ${platform}"
   
   if sde::run::r_emulator_for_platform "${platform}"
   then
      emulator="${RVAL}"
   else
      emulator=""
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
         exekutor mudo ${MUDO_FLAGS} -f ${environment} ${emulator} "${EXECUTABLE}" "$@" &
      else
         exekutor ${timeout} mudo ${MUDO_FLAGS} -f ${environment} ${debugger} ${emulator} "${EXECUTABLE}" "$@"
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
