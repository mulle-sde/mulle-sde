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
   be run outside of a mulle-sde environment. The URL can be a repository or
   an archive. It can also be an existing project.

   You should never use this command inside an existing project. "install"
   will create a temporary project.

   The command will output the suggested link flags for the current platform
   after the install has finished.

Examples:
   Build a standalone shared Foundation library from the github repository.
   Then install it and all intermediate libraries into \`/tmp/yyy\`:

   mulle-sde install --standalone --prefix /tmp/yyyy \
https://github.com/MulleFoundation/Foundation/archive/latest.zip

   Grab local project. Place all dependency projects into \`/tmp/foo\`
   preferring local projects. Build in \`/tmp/foo\`.
   Tip: Set MULLE_FETCH_SEARCH_PATH so that local dependencies can be found.
   Install into \`/tmp/xxx\`. Keep \`/tmp/foo\`:

   mulle-sde install -d /tmp/foo --prefix /tmp/xxx mulle-objc-compat

Options:
   -k <dir>          : kitchen directory (\$PWD/kitchen)
   -d <dir>          : directory to fetch into (\$PWD)
   --c               : project is C
   --objc            : project is Objective-C
   --branch <name>   : branch to checkout
   --debug           : install as debug instead of release
   --only-project    : install only the main project
   --prefix <prefix> : installation prefix (\$PWD)
   --linkorder       : produce linkorder output
   --keep-tmp        : don't delete temporary directory
   --standalone      : create a whole-archive shared library if supported
   --tag <name>      : tag to checkout

Environment:
   MULLE_FETCH_SEARCH_PATH : specify places to search local dependencies.

EOF
  exit 1
}


do_update_sourcetree()
{
   log_entry "do_update_sourcetree" "$@"

   if [ "${MULLE_SDE_FETCH}" = 'NO' ]
   then
      log_info "Fetching is disabled by environment MULLE_SDE_FETCH"
      return 0
   fi

   eval_exekutor "'${MULLE_SOURCETREE:-mulle-sourcetree}'" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        "${OPTION_MODE}" \
                     "update" \
                        "$@"
}

#
# This method create a new custom project adds everythin as dependencies
# and installs all of them by setting DEPENDENCY_DIR to --prefix
#
install_in_tmp()
{
   log_entry "install_in_tmp" "$@"

   local url="$1"; shift
   local directory="$1"; shift
   local marks="$1"; shift
   local configuration="$1"; shift
   local serial="$1"; shift
   local symlink="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local arguments="$1"; shift
   local environment="$1"; shift

   mkdir_if_missing "${directory}" 2> /dev/null
   exekutor cd "${directory}" || fail "can't change to \"${directory}\""

   if [ "${OPTION_OUTPUT_LINKORDER}" = 'YES' ]
   then
      if [ ! -d .mulle/share/env -a ! -d .mulle/share/sde ]
      then
         # fake an environment for mulle-sde to run afterwards,
         # otherwise we don't need it
         exekutor mulle-sde -s --style none/wild init --no-post-init none
      fi
   fi

   local add

   add='YES'

   if mulle-sourcetree -s --no-defer dbstatus && [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
   then
      log_verbose "Reusing previous .mulle-sourcetree folder unchanged. \
Use -f flag to clobber."
      add='NO'
   else
      rmdir_safer ".mulle-sourcetree"
   fi

   if [ "${add}" = 'YES' ]
   then
      r_simplified_absolutepath "${url}" "${MULLE_EXECUTABLE_PWD}"
      if [ -d "${RVAL}" ]
      then
         #
         # here we are building a local repository, so we'd prefer to
         # also use local repositories
         #
         log_verbose "Build local repositories (with symlinks if possible)"

         url="https://localhost${RVAL}"
         r_dirname "${RVAL}"

         r_colon_concat "${RVAL}" "${MULLE_FETCH_SEARCH_PATH}"
         MULLE_FETCH_SEARCH_PATH="${RVAL}"

         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                         ${MULLE_TECHNICAL_FLAGS}  \
                         --no-defer \
                         -s \
                     add --nodetype git \
                         --marks "${marks}" \
                         "${url}"  || return 1
         eval_exekutor MULLE_FETCH_SEARCH_PATH="'${MULLE_FETCH_SEARCH_PATH}'" \
                           "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                                 ${MULLE_TECHNICAL_FLAGS}  \
                                 --no-defer \
                              update --symlink || return 1
      else
         log_verbose "Build remote repositories"

         local options

         options="--marks '${marks}'"
         if [ ! -z "${branch}" ]
         then
            options="${options} --branch '${branch}'"
         fi
         if [ ! -z "${tag}" ]
         then
            options="${options} --tag '${tag}'"
         fi
         eval_exekutor "'${MULLE_SOURCETREE:-mulle-sourcetree}'" \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              --no-defer \
                              -s \
                           add \
                              "${options}" \
                              "'${url}'"  || return 1
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           --no-defer \
                        update || return 1
      fi
   fi

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  --no-defer \
                  -s \
                craftorder \
                 --no-print-env > craftorder || return 1

   if [ "${serial}" = 'YES' ]
   then
      serial="--serial"
   else
      serial=""
   fi

   eval_exekutor "${environment}" \
      "'${MULLE_CRAFT:-mulle-craft}'" \
         ${MULLE_TECHNICAL_FLAGS} \
         ${MULLE_CRAFT_FLAGS} \
         --craftorder-file craftorder \
      craftorder \
         --no-protect \
         ${serial} \
         --configuration "${configuration}" \
         "${arguments}" || return 1

   if [ "${OPTION_OUTPUT_LINKORDER}" = 'YES' ]
   then
      log_warning "Link Information"
      eval_exekutor "${environment}" \
         "'${MULLE_SDE:-mulle-sde}'" \
               ${MULLE_TECHNICAL_FLAGS} \
            "linkorder" || return 1
   fi
}


#
# This method clones/copies a project. Places all dependencies into a local
# DEPENDENCY_DIR then build project with --prefix and runs make install
#
install_project_only_in_tmp()
{
   log_entry "install_project_only_in_tmp" "$@"

   local url="$1"; shift
   local directory="$1"; shift
   local prefixdir="$1"; shift
   local configuration="$1"; shift
   local serial="$1"; shift
   local symlink="$1"; shift
   local arguments="$1"; shift

   exekutor cd "${directory}" || fail "can't change to \"${directory}\""

   if [ "${serial}" = 'YES' ]
   then
      serial="--serial"
   else
      serial=""
   fi

   eval_exekutor  \
      "'${MULLE_SDE:-mulle-sde}'" \
         ${MULLE_TECHNICAL_FLAGS} \
         ${MULLE_SDE_FLAGS} \
      craft craftorder \
         ${serial} \
         --configuration "'${configuration}'" \
         "${arguments}" || return 1

   local definition_dir

   definition_dir="`mulle-craft search`"

   local build_dir

   build_dir="`make_tmp_directory`" || exit 1

   # just to be sure, in case we are doing an inline build, but the build_dir
   # elsehere
   eval_exekutor \
      "'${MULLE_SDE:-mulle-sde}'" \
            "${MULLE_TECHNICAL_FLAGS}" \
            "${MULLE_SDE_FLAGS}" \
         run \
            "'${MULLE_MAKE:-mulle-make}'" \
               "${MULLE_TECHNICAL_FLAGS}" \
               "${MULLE_MAKE_FLAGS}" \
            install \
               --build-dir "'${build_dir}'" \
               --definition-dir "'${definition_dir}'" \
               --prefix "'${prefixdir}'" \
               --configuration "'${configuration}'" \
               "${arguments}" || return 1

   if [ "${OPTION_OUTPUT_LINKORDER}" = 'YES' ]
   then
      log_warning "Link Information for inferior libraries"
      eval_exekutor "${environment}" \
         "'${MULLE_SDE:-mulle-sde}'" \
               ${MULLE_TECHNICAL_FLAGS} \
            "linkorder" || return 1
   fi

   if [ "${OPTION_KEEP_TMP}" = 'NO' ]
   then
      rmdir_safer "${build_dir}"
   fi
}



sde_install_main()
{
   log_entry "sde_install_main" "$@"

   local OPTION_PROJECT_DIR
   local OPTION_KEEP_TMP='NO'
   local OPTION_SERIAL='NO'
   local OPTION_MARKS=''
   local OPTION_CONFIGURATION='Release'
   local OPTION_BRANCH=
   local OPTION_TAG=
   local OPTION_OUTPUT_LINKORDER='NO'
   local OPTION_ONLY_PROJECT='NO'
   local PREFIX_DIR="/tmp"

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

         -b|--build-dir|-k|--kitchen-dir)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            KITCHEN_DIR="$1"
         ;;

         --branch)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
         ;;

         --c)
            r_colon_concat "${OPTION_MARKS}" 'no-all-load,no-import'
            OPTION_MARKS="${RVAL}"
         ;;

         --objc)
            r_colon_concat "${OPTION_MARKS}" 'no-singlephase'
            OPTION_MARKS="${RVAL}"
         ;;

         --configuration)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="$1"
         ;;

         --debug)
            OPTION_CONFIGURATION='Debug'
         ;;

         --keep-tmp)
            OPTION_KEEP_TMP='YES'
         ;;

         --linkorder)
            OPTION_OUTPUT_LINKORDER='YES'
         ;;

         --no-linkorder)
            OPTION_OUTPUT_LINKORDER='NO'
         ;;

         --prefix)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            PREFIX_DIR="$1"
         ;;

         --only-project)
            OPTION_ONLY_PROJECT='YES'
         ;;

         --release)
            OPTION_CONFIGURATION='Release'
         ;;

         --serial)
            OPTION_SERIAL='YES'
         ;;

         --standalone)
            r_colon_concat "${OPTION_MARKS}" 'only-standalone'
            OPTION_MARKS="${RVAL}"
         ;;

         --tag)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
         ;;

         --test)
            OPTION_CONFIGURATION='Test'
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

   # remaining arguments are passed to mulle-make (and not mulle-craft)
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

   local rval

   if [ "${OPTION_ONLY_PROJECT}" = 'YES' ]
   then
      if [ -z "${OPTION_PROJECT_DIR}" ]
      then
         PROJECT_DIR="`make_tmp_directory`" || exit 1
         if [ "${OPTION_KEEP_TMP}" = 'NO' ]
         then
            delete_tmp="${PROJECT_DIR}"
         fi

         if [ ! -d "${URL}" ]
         then
            exekutor "${MULLE_FETCH:-mulle-fetch}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_FETCH_FLAGS} \
                        fetch \
                           --tag "${OPTION_TAG}" \
                           --branch "${OPTION_BRANCH}" \
                           "${URL}" \
                           "${PROJECT_DIR}"
         else
            PROJECT_DIR="${URL}"
         fi
      else
         r_simplified_absolutepath "${OPTION_PROJECT_DIR}"
         PROJECT_DIR="${RVAL}"

         [ -d "${PROJECT_DIR}/.mulle/sde" ] || fail "Not a mulle-sde project in \"${PROJECT_DIR}\""
      fi

      # project should be ready now
      install_project_only_in_tmp "${URL}" \
                                  "${PROJECT_DIR}" \
                                  "${PREFIX_DIR}" \
                                  "${OPTION_CONFIGURATION}" \
                                  "${OPTION_SERIAL}" \
                                  "${OPTION_SYMLINK}" \
                                  "${arguments}"
   else
      if [ -z "${OPTION_PROJECT_DIR}" ]
      then
         PROJECT_DIR="`make_tmp_directory`" || exit 1
         if [ "${OPTION_KEEP_TMP}" = 'NO' ]
         then
            delete_tmp="${PROJECT_DIR}"
         fi
      else
         r_simplified_absolutepath "${OPTION_PROJECT_DIR}"
         PROJECT_DIR="${RVAL}"
      fi

      log_verbose "Directory: \"${PROJECT_DIR}\""

      DEPENDENCY_DIR="${PREFIX_DIR}"
      KITCHEN_DIR="${KITCHEN_DIR:-${BUILD_DIR}}"
      KITCHEN_DIR="${KITCHEN_DIR:-${PROJECT_DIR}/kitchen}"

      local environment

      environment="DEPENDENCY_DIR='${DEPENDENCY_DIR}'"
      environment="${environment} KITCHEN_DIR='${KITCHEN_DIR}'"
      environment="${environment} PATH='${DEPENDENCY_DIR}/bin:$PATH'"
      environment="${environment} MULLE_VIRTUAL_ROOT='${PROJECT_DIR}'"

      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "KITCHEN_DIR=${KITCHEN_DIR}"
         log_trace2 "DEPENDENCY_DIR=${DEPENDENCY_DIR}"
         log_trace2 "MULLE_VIRTUAL_ROOT=${PROJECT_DIR}"
         log_trace2 "PATH=${DEPENDENCY_DIR}/bin:$PATH"
         log_trace2 "PROJECT_DIR=${PROJECT_DIR}"
      fi

      install_in_tmp "${URL}" \
                     "${PROJECT_DIR}" \
                     "${OPTION_MARKS}" \
                     "${OPTION_CONFIGURATION}" \
                     "${OPTION_SERIAL}" \
                     "${OPTION_SYMLINK}" \
                     "${OPTION_BRANCH}" \
                     "${OPTION_TAG}" \
                     "${arguments}" \
                     "${environment}"
   fi

   rval=$?

   if [ ${rval} -eq 0 ]
   then
      if [ ! -z "${delete_tmp}" ]
      then
         rmdir_safer "${delete_tmp}"
      fi
   fi

   return $rval
}
