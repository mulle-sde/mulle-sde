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

Examples:
   mulle-sde install --prefix /tmp/yyyy \
      https://github.com/MulleFoundation/Foundation/archive/latest.zip

   Grab project from github and place it into a temporary folder. Fetch all
   dependencies also into this temporary folder. Build in /tmp/bar.
   Install into /tmp/yyy. Remove the temporary folder.

   MULLE_FETCH_SEARCH_PATH="/home/src/srcO/mulle-c" \
      mulle-sde install -d /tmp/foo --prefix /tmp/xxx mulle-objc-compat

   Grab local project. Places all dependency projects into
   /tmp/foo preferring local projects. Build in /tmp/foo.
   Install into /tmp/xxx. Keep /tmp/foo.

Options:
   -d <dir>          : directory to fetch into (\$PWD)
   --prefix <prefix> : installation prefix (\$PWD)
   -b <dir>          : build directory (\$PWD/build)

Environment:
   MULLE_FETCH_SEARCH_PATH : specify places to search local projects

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

   local OPTION_PROJECT_DIR

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_install_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_PROJECT_DIR="$1"
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

   local delete_tmp
   local PROJECT_DIR
   local RVAL

   if [ -z "${OPTION_PROJECT_DIR}" ]
   then
      PROJECT_DIR="`make_tmp_directory`" || exit 1
      delete_tmp="${PROJECT_DIR}"
   else
      r_simplified_absolutepath "${OPTION_PROJECT_DIR}"
      PROJECT_DIR="${RVAL}"
   fi

   log_verbose "Directory: \"${PROJECT_DIR}\""

   DEPENDENCY_DIR="${DEPENDENCY_DIR:-${PROJECT_DIR}/dependency}"
   BUILD_DIR="${BUILD_DIR:-${PROJECT_DIR}/build}"

   local environment

   environment="DEPENDENCY_DIR='${DEPENDENCY_DIR}'"
   environment="${environment} BUILD_DIR='${BUILD_DIR}'"
   environment="${environment} PATH='${DEPENDENCY_DIR}/bin:$PATH'"
   environment="${environment} MULLE_VIRTUAL_ROOT='${PROJECT_DIR}'"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_trace2 "BUILD_DIR=${BUILD_DIR}"
      log_trace2 "DEPENDENCY_DIR=${DEPENDENCY_DIR}"
      log_trace2 "MULLE_VIRTUAL_ROOT=${PROJECT_DIR}"
      log_trace2 "PATH=${DEPENDENCY_DIR}/bin:$PATH"
      log_trace2 "PROJECT_DIR=${PROJECT_DIR}"
   fi

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

   exekutor mkdir -p "${PROJECT_DIR}" 2> /dev/null
   exekutor cd "${PROJECT_DIR}" || fail "can't change to \"${PROJECT_DIR}\""

   local add

   add="YES"

   if mulle-sourcetree -s -e -N dbstatus && [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
   then
      log_verbose "Reusing previous .mulle-sourcetree folder unchanged. \
Use -f flag to clobber."
      add="NO"
   else
      rmdir_safer ".mulle-sourcetree"
   fi

   if [ "${add}" = "YES" ]
   then
      r_simplified_absolutepath "${URL}" "${MULLE_EXECUTABLE_PWD}"
      if [ -d "${RVAL}" ]
      then
         URL="https://localhost${RVAL}"
         r_fast_dirname "${RVAL}"

         MULLE_FETCH_SEARCH_PATH="`colon_concat "${RVAL}" "${MULLE_FETCH_SEARCH_PATH}"`"

         exekutor  mulle-sourcetree -e ${MULLE_SOURCETREE_FLAGS} \
                                    -N ${MULLE_TECHNICAL_FLAGS}  \
                                    add --nodetype git "${URL}"  || exit 1
         eval_exekutor MULLE_FETCH_SEARCH_PATH="'${MULLE_FETCH_SEARCH_PATH}'" \
                           mulle-sourcetree -e ${MULLE_SOURCETREE_FLAGS} \
                                            -N ${MULLE_TECHNICAL_FLAGS}  \
                                            update --symlink || exit 1
      else
         exekutor mulle-sourcetree -e ${MULLE_SOURCETREE_FLAGS} \
                                   -N ${MULLE_TECHNICAL_FLAGS} \
                                   add "${URL}"  || exit 1

         exekutor mulle-sourcetree -e ${MULLE_SOURCETREE_FLAGS} \
                                   -N ${MULLE_TECHNICAL_FLAGS} \
                                   update || exit 1
      fi
   fi

   exekutor mulle-sourcetree -e ${MULLE_SOURCETREE_FLAGS} \
                             -N ${MULLE_TECHNICAL_FLAGS} \
                             buildorder --output-marks > buildorder || exit 1
   eval_exekutor "${environment}" mulle-craft \
         -e ${MULLE_CRAFT_FLAGS} ${MULLE_TECHNICAL_FLAGS} \
         buildorder \
            --no-protect \
            -f buildorder \
            "${arguments}" || exit 1

   if [ ! -z "${delete_tmp}" ]
   then
      _rmdir_safer "${delete_tmp}"
   fi
}
