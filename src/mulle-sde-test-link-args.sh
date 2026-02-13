# shellcheck shell=bash
#
#   Copyright (c) 2026 Nat! - Mulle kybernetiK
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
MULLE_SDE_TEST_LINK_ARGS_SH='included'


sde::test::link_args_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} link-args [options] <command>

   Produce the link_args required for test executables to link. This can
   be useful, if you are using external test scripts.

   There are two caches for the link_args. One with the startup code and
   one without. To update both, run both commands:

   ${MULLE_USAGE_NAME} link-args update
   ${MULLE_USAGE_NAME} link-args update --startup

Options:
   --startup       : include startup libraries
   --no-startup    : exclude startup libraries
   --platform <p>  : specify platform (default: current platform)

Command:
   paths           : show link-args file paths
   cat             : show linker arguments
   update          : update link-args files

EOF
   exit 1
}


sde::test::link_args_get_link_command()
{
   log_entry "sde::test::link_args_get_link_command" "$@"

   local directory="$1"

   local platform_args

   if [ ! -z "${MULLE_PLATFORM}" ]
   then
      platform_args="--platform ${MULLE_PLATFORM}"
   fi

   exekutor mulle-sde \
               --no-test-check \
               -d "${directory}" \
               -E \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_ENV_FLAGS:-} \
               ${MULLE_SDE_FLAGS:-} \
               ${MULLE_FWD_FLAGS:-} \
               --defines "${MULLE_DEFINE_FLAGS:-}" \
            link-args \
               --output-format ld \
               --output-no-final-lf \
               --preferred-library-style dynamic \
               --whole-archive-format 'DEFAULT' \
               --configuration "${OPTION_CONFIGURATION:-Debug}" \
               ${platform_args} \
               "$@"  # shared libs only ATM
}


sde::test::link_args_update()
{
   log_entry "sde::test::link_args_update" "$@"

   local directory="$1"
   local withstartup="${2:-YES}"

   local link_args_filename
   local args  
   local prefix

   link_args_filename="${LINK_ARGS_FILE}"
   prefix="Link"

   if [ "${withstartup}" = 'YES' ]
   then
      args='--startup'
      prefix="Startup link"
      link_args_filename="${LINK_ARGS_FILE}--startup"
   fi

   log_verbose "Compiling link_args"

   local command

   command="`sde::test::link_args_get_link_command "${directory}" ${args}`" || exit 1

   r_mkdir_parent_if_missing "${link_args_filename}"
   redirect_exekutor "${link_args_filename}" printf "%s\n" "${command}"

   log_verbose "${prefix} arguments are available in ${C_RESET_BOLD}${link_args_filename#${MULLE_USER_PWD}/}${C_VERBOSE}"
}


sde::test::link_args_main()
{
   log_entry "sde::test::link_args_main" "$@"

   local OPTION_STARTUP='DEFAULT'
   local OPTION_CACHED='YES'
   local OPTION_PLATFORM="${MULLE_UNAME}"
   local OPTION_SDK='Default'
   local OPTION_CONFIGURATION='Debug'
   local OPTION_DEPENDENCY_DIR
   local OPTION_DIRECTORY="${PWD}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::test::link_args_usage
         ;;

         --startup)
            OPTION_STARTUP='YES'
         ;;

         --no-startup)
            OPTION_STARTUP='NO'
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde::test::link_args_usage "Missing argument to \"$1\""
            shift

            OPTION_DIRECTORY="${1:-${OPTION_DIRECTORY}}"
         ;;

         --dependency-dir)
            [ $# -eq 1 ] && sde::test::link_args_usage "Missing argument to \"$1\""
            shift

            OPTION_DEPENDENCY_DIR="${1:-${OPTION_DEPENDENCY_DIR}}"
         ;;

         --platform)
            [ $# -eq 1 ] && sde::test::link_args_usage "Missing argument to \"$1\""
            shift

            OPTION_PLATFORM="${1:-${OPTION_PLATFORM}}"
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::test::link_args_usage "Missing argument to \"$1\""
            shift

            OPTION_SDK="${1:-${OPTION_SDK}}"
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::test::link_args_usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="${1:-${OPTION_CONFIGURATION}}"
         ;;

         -*)
            sde::test::link_args_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde::test::link_args_usage "Missing command"


   [ -z "${OPTION_SDK}" ] && _internal_fail "OPTION_SDK is empty"
   [ -z "${OPTION_PLATFORM}" ] && _internal_fail "OPTION_PLATFORM is empty"
   [ -z "${OPTION_CONFIGURATION}" ] && _internal_fail "OPTION_CONFIGURATION is empty"

   local style  

   style="${OPTION_SDK}-${OPTION_PLATFORM}-${OPTION_CONFIGURATION}"

   local LINK_ARGS_FILE 

   if [ -z "${OPTION_DEPENDENCY_DIR}" ]
   then
      OPTION_DEPENDENCY_DIR=$(rexekutor mulle-env -E -d "${OPTION_DIRECTORY}" exec mulle-craft dependency-dir) || exit 1
   fi

   [ -z "${OPTION_DEPENDENCY_DIR}" ] && _fail "dependency dir is still empty"

   r_filepath_concat "${OPTION_DEPENDENCY_DIR}" 'etc' "link--${style}"
   LINK_ARGS_FILE="${RVAL}"

   # Set MULLE_PLATFORM if --platform was specified
   MULLE_PLATFORM="${OPTION_PLATFORM}"

   local rc 

   case "${1:-list}" in
      'paths')
         if [ "${OPTION_STARTUP}" != 'NO' ]
         then
            printf "STARTUP_LINK_ARGS_FILE=\"%q\"\n" "${LINK_ARGS_FILE}--startup"
         fi

         if [ "${OPTION_STARTUP}" != 'YES' ]
         then
            printf "LINK_ARGS_FILE=\"%q\"\n"         "${LINK_ARGS_FILE}"
         fi
      ;;

      'update')
         exekutor mulle-env -E -d "${OPTION_DIRECTORY}" exec mulle-craft dependency begin
         (
            if [ "${OPTION_STARTUP}" != 'NO' ]
            then
               sde::test::link_args_update "${OPTION_DIRECTORY}" 'YES'
            fi

            if [ "${OPTION_STARTUP}" != 'YES' ]
            then
               sde::test::link_args_update "${OPTION_DIRECTORY}" 'NO'
            fi
         )
         rc=$?

         if [ $rc -eq 0 ]
         then
            exekutor mulle-env -E -d "${OPTION_DIRECTORY}" exec mulle-craft dependency end
         else
            exekutor mulle-env -E -d "${OPTION_DIRECTORY}" exec mulle-craft dependency fail
         fi
         return $rc
      ;;

      'cat')
         if [ "${OPTION_STARTUP}" != 'NO' ]
         then
            log_info "Startup"
            sde::test::link_args_get_link_command "${OPTION_DIRECTORY}" 'NO'
            printf "%s\n\n" "${RVAL}"
         fi

         if [ "${OPTION_STARTUP}" != 'YES' ]
         then
            log_info "No Startup"
            sde::test::link_args_get_link_command "${OPTION_DIRECTORY}" 'YES'
            printf "%s\n" "${RVAL}"
         fi
      ;;

      *)
         fail "Unknown link_args command \"$1\""
      ;;
   esac
}
