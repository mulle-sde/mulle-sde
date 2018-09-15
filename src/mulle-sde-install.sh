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
MULLE_SDE_INSTALL_SH="included"


sde_install_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} install [options] <url>

   Install a remote mulle-sde project, pointed at by URL. This command must
   be run outside of a mulle-sde environment.

   The URL can be a repository or an archive.

Options:
   -d <dir>          : directory to fetch into (\$PWD)
   --prefix <prefix> : installation prefix (\$PWD)
   -b <dir>          : build directory (\$PWD/build)

EOF
  exit 1
}


do_update_sourcetree()
{
   log_entry "do_update_sourcetree" "$@"

   if [ "${MULLE_SDE_FETCH}" = "NO" ]
   then
      log_info "Fetching is disabled by environment MULLE_SDE_FETCH"
      return 0
   fi

   eval_exekutor "'${MULLE_SOURCETREE:-mulle-sourcetree}'" \
                     "${MULLE_SOURCETREE_FLAGS}" ${MULLE_TECHNICAL_FLAGS} "${OPTION_MODE}" \
                     "update" "$@"
}


sde_install_main()
{
   log_entry "sde_install_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_install_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            exekutor mkdir -p "$1" 2> /dev/null
            exekutor cd "$1" || fail "can't change to \"$1\""
         ;;

         -b|--build-dir)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            BUILD_DIR="$1"
         ;;

         --prefix)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            DEPENDENCY_DIR="$1"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde_install_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] && sde_install_usage "Missing url argument"
   URL="$1"
   shift

   [ "$#" -eq 0 ] || sde_install_usage "Superflous arguments \"$*\""

   DEPENDENCY_DIR="${DEPENDENCY_DIR:-${PWD}/dependency}"
   BUILD_DIR="${BUILD_DIR:-${PWD}/build}"


   local add

   add="YES"

   if [ -d .mulle-sourcetree ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "YES" ]
      then
         if [ -z "${MULLE_STRING_SH}" ]
         then
            . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh" || return 1
         fi
         if [ -z "${MULLE_PATH_SH}" ]
         then
            . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
         fi
         if [ -z "${MULLE_FILE_SH}" ]
         then
            . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
         fi
         rmdir_safer .mulle-sourcetree
      else
         log_verbose "Reusing previous .mulle-sourcetree folder unchanged. \
Use -f flag to clobber."
         add="NO"
      fi
   fi

   local environment

   environment="DEPENDENCY_DIR='${DEPENDENCY_DIR}'"
   environment="${environment} BUILD_DIR='${BUILD_DIR}'"
   environment="${environment} PATH='${DEPENDENCY_DIR}/bin:$PATH'"
   environment="${environment} MULLE_VIRTUAL_ROOT='${PWD}'"

   local arguments

   while [ $# -ne 0  ]
   do
      arguments="${arguments} '$1'"
      shift
   done

   if [ ! -z "${arguments}" ]
   then
      arguments="-- ${arguments}"
   fi

   if [ "${add}" = "YES" ]
   then
      exekutor mulle-sourcetree -e -N add "${URL}"  &&
      exekutor mulle-sourcetree -e update || exit 1
   fi
   exekutor mulle-sourcetree -e buildorder --output-marks > buildorder &&
   eval_exekutor "${environment}" mulle-craft \
         -e ${MULLE_CRAFT_FLAGS} ${MULLE_TECHNICAL_FLAGS} \
         buildorder \
            --no-protect \
            -f buildorder \
            "${arguments}"
}
