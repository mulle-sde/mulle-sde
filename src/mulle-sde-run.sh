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
   --  : pass remaining options as arguments
   -e  : run the main executable outside of the mulle-sde environment.
   -b  : run the executable in the background (&)

Environment:
   MULLE_SDE_RUN      : command line to use, use \${EXECUTABLE} as variable
   MULLE_SDE_PRE_RUN  : command line before executable starts
   MULLE_SDE_POST_RUN : command line after executable has started, implies -b

EOF
   exit 1
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


   local EXECUTABLE

   # shellcheck source=src/mulle-sde-product.sh
   include "sde::product"

   if [ -x "${OPTION_NAME}" ]
   then
      EXECUTABLE="${OPTION_NAME}"
   else
      if ! sde::product::r_executable "${OPTION_NAME}"
      then
         return 1
      fi
      EXECUTABLE="${RVAL}"
   fi

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

   if [ ! -z "${pre_commandline}" ]
   then
      r_expanded_string "${pre_commandline}"
      pre_commandline="${RVAL}"

      # we don't push "$@" unto the post run though, if this is a problem
      # pass it as an environment variable (and a wrapper shell script)
      log_verbose "Use MULLE_SDE_PRE_RUN '${pre_commandline}' as command line"
      eval_exekutor mudo ${MUDO_FLAGS} -f "${pre_commandline}"
   fi

   if [ ! -z "${commandline}" ]
   then
      r_expanded_string "${commandline}"
      commandline="${RVAL}"

      log_verbose "Use MULLE_SDE_RUN '${commandline}' as command line"
      if [ "${OPTION_BACKGROUND}" = 'YES' ]
      then
         eval_exekutor mudo ${MUDO_FLAGS} -f ${environment} "${commandline}" "$@" &
      else
         eval_exekutor mudo ${MUDO_FLAGS} -f ${environment} "${commandline}" "$@"
      fi
   else
      if [ "${OPTION_BACKGROUND}" = 'YES' ]
      then
         exekutor mudo ${MUDO_FLAGS} -f ${environment} "${EXECUTABLE}" "$@" &
      else
         exekutor mudo ${MUDO_FLAGS} -f ${environment} "${EXECUTABLE}" "$@"
      fi
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
