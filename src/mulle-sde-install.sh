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
MULLE_SDE_INSTALL_SH='included'


sde::install::usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} install [options] <url> [-- [mulle-make options]]

   Fetch, build and install a mulle-sde project. The URL can point to a git 
   repository or a repository archive. It can also be the path to an existing 
   local project. The install destination is set by the --prefix option. It 
   defaults to TMPDIR (${TMPDIR:-/tmp}).

   ${MULLE_USAGE_NAME} install uses a custom environment to shield the build 
   process from inadvertant environment settings.

   The command can output the suggested linker flags for the current platform
   after the install has finished (--linkorder).

Example:
   Build the mulle-fprintf library from the github repository.
   Then install it and all intermediate libraries into \`/tmp/yyy\`:

   mulle-sde install --linkorder --prefix /tmp/yyyy \
https://github.com/mulle-core/mulle-sprintf/archive/latest.zip

   To build a local project, set MULLE_FETCH_SEARCH_PATH so that all local
   dependencies can be found.

   mulle-sde -DMULLE_FETCH_SEARCH_PATH=~/src install --prefix /tmp/xxx .

Options:
   --branch <name>   : branch to checkout
   --c               : project is C
   --debug           : install as debug instead of release
   --keep-tmp        : don't delete temporary directory
   --linkorder       : produce linkorder output
   --objc            : project is Objective-C (default)
   --only-project    : install only the main project
   --post-init       : run post-init on temporary project
   --prefix <prefix> : installation prefix (\$PWD)
   --standalone      : create a whole-archive shared library if supported
   --static          : produce shared libraries
   --tag <name>      : tag to checkout
   -d <dir>          : directory to fetch into (/tmp/...)
   -k <dir>          : kitchen directory (\$PWD/kitchen)

Environment:
   MULLE_FETCH_SEARCH_PATH : specify places to search local dependencies.

EOF
   exit 1
}


sde::install::do_update_sourcetree()
{
   log_entry "sde::install::do_update_sourcetree" "$@"

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
# This method create a new custom project adds everything as dependencies
# and installs all of them by setting DEPENDENCY_DIR to --prefix
#
sde::install::in_tmp()
{
   log_entry "sde::install::in_tmp" "$@"

   local url="$1"
   local directory="$2" 
   local marks="$3" 
   local configuration="$4" 
   local serial="$5"
   local symlink="$6" 
   local libstyle="$7"
   local branch="$8" 
   local tag="$9"
   shift 9

   local postinit="$1" 
   local arguments="$2"
   local environment="$3"
   shift 3

   mkdir_if_missing "${directory}" 2> /dev/null
   exekutor cd "${directory}" || fail "can't change to \"${directory}\""

   # post-init can be convenient to pick up local repos
   if [ "${OPTION_OUTPUT_LINKORDER}" = 'YES' -o "${postinit}" = 'YES' ]
   then
      if [ ! -d .mulle/share/env -a ! -d .mulle/share/sde ]
      then
         # fake an environment for mulle-sde to run afterwards,
         # otherwise we don't need it
         if [ "${postinit}" = 'YES' ]
         then
            exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                               -s \
                               --style none/wild \
                               init \
                                 none || return 1
         else
            exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                               -s \
                               --style none/wild \
                               init \
                                 --no-post-init \
                                 none || return 1
         fi
      fi
   fi

   local update_options

   if [ "${symlink}" = 'YES' ]
   then
      update_options=--symlink
   fi

   local add

   add='YES'

   if rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS:-}  \
                     -s --no-defer \
                     dbstatus && [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
   then
      _log_verbose "Reusing previous sourcetree folder unchanged. \
Use -f flag to clobber."
      add='NO'
   else
      rmdir_safer ".mulle/etc/sourcetree"
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

         local searchpath 

         url="file://${RVAL}"
         r_dirname "${RVAL}"
         r_colon_concat "${RVAL}" "${MULLE_FETCH_SEARCH_PATH}"
         searchpath="${RVAL}"

         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                         ${MULLE_TECHNICAL_FLAGS}  \
                         ${MULLE_SOURCETREE_FLAGS:-}  \
                         --no-defer \
                         -s \
                     add --nodetype git \
                         --marks "${marks}" \
                         "${url}"  || return 1

         eval_exekutor MULLE_FETCH_SEARCH_PATH="'${searchpath}'" \
                           "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                                 "${MULLE_TECHNICAL_FLAGS}"  \
                                 "${MULLE_SOURCETREE_FLAGS:-}"  \
                                 --no-defer \
                              update ${update_options} || return 1
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
                              "${MULLE_SOURCETREE_FLAGS:-}"  \
                              --no-defer \
                              -s \
                           add \
                              "${options}" \
                              "'${url}'"  || return 1

         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_SOURCETREE_FLAGS:-} \
                           --no-defer \
                        update ${update_options} || return 1
      fi
   fi

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS:-} \
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
         "${MULLE_TECHNICAL_FLAGS}" \
         "${MULLE_CRAFT_FLAGS}" \
         --craftorder-file craftorder \
      craftorder \
         --no-donefiles \
         --no-protect \
         ${serial} \
         --no-keep-dependency-state \
         --configuration "${configuration}" \
         "${arguments}" || return 1

   if [ "${OPTION_OUTPUT_LINKORDER}" = 'YES' ]
   then
      log_warning "Link Information"
      eval_exekutor "${environment}" \
         "'${MULLE_SDE:-mulle-sde}'" \
               "${MULLE_TECHNICAL_FLAGS}" \
            "linkorder" || return 1
   fi
}


#
# This method clones/copies a project. Places all dependencies into a local
# DEPENDENCY_DIR then build project with --prefix and runs make install
#
sde::install::project_only_in_tmp()
{
   log_entry "sde::install::project_only_in_tmp" "$@"

   local url="$1"
   local directory="$2"
   local prefixdir="$3"
   local configuration="$4"
   local serial="$5"
   local symlink="$6"
   local libstyle="$7"
   local arguments="$8"

   shift 8

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
         --no-keep-dependency-state \
         "${arguments}" || return 1

   local definition_dir

   definition_dir="`mulle-craft search`"

   local build_dir

   r_make_tmp_directory || exit 1
   build_dir="${RVAL}"

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
               --configuration "'${configuration}'" \
               --definition-dir "'${definition_dir}'" \
               --prefix "'${prefixdir}'" \
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


sde::install::main()
{
   log_entry "sde::install::main" "$@"

   local OPTION_BRANCH=
   local OPTION_CONFIGURATION='Release'
   local OPTION_KEEP_TMP='NO'
   local OPTION_MARKS=''
   local OPTION_ONLY_PROJECT='NO'
   local OPTION_OUTPUT_LINKORDER='NO'
   local OPTION_POST_INIT
   local OPTION_PROJECT_DIR
   local OPTION_SERIAL='NO'
   local OPTION_SYMLINK='NO'
   local OPTION_TAG=
   local PREFIX_DIR="/tmp"
   local OPTION_LANGUAGE='DEFAULT'
   local OPTION_PREFERRED_LIBRARY_STYLE="static"
   local URL 

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::install::usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            OPTION_PROJECT_DIR="$1"
         ;;

         -b|--build-dir|-k|--kitchen-dir)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            KITCHEN_DIR="$1"
         ;;

         --branch)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
         ;;

         --c)
            OPTION_LANGUAGE=c
         ;;


         --objc)
            OPTION_LANGUAGE=objc
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="$1"
         ;;

         --language)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            OPTION_LANGUAGE="$1"
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

         --marks)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"         
         ;;

         --post-init)
            OPTION_POST_INIT='YES'
         ;;

         --prefix)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            PREFIX_DIR="$1"
         ;;

         --preferred-library-style|--library-style)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            OPTION_PREFERRED_LIBRARY_STYLE="$1"
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

         --shared|--dynamic)
            OPTION_PREFERRED_LIBRARY_STYLE="dynamic"
         ;;

         --standalone)
            OPTION_PREFERRED_LIBRARY_STYLE="standalone"

            r_comma_concat "${OPTION_MARKS}" 'only-standalone'
            OPTION_MARKS="${RVAL}"
         ;;

         --static)
            OPTION_PREFERRED_LIBRARY_STYLE="static"
         ;;

         --symlink)
            OPTION_SYMLINK='YES'
         ;;

         --tag)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
         ;;

         --test)
            OPTION_CONFIGURATION='Test'
         ;;

         --url)
            [ $# -eq 1 ] && sde::install::usage "Missing argument to \"$1\""
            shift

            URL="$1"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::install::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${URL}" ]
   then
      [ "$#" -eq 0 ] && sde::install::usage "Missing url argument"

      URL="$1"
      shift
   fi 

   [ -z "${MULLE_STRING_SH}" ]    && _internal_fail "need MULLE_FILE"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] \
   || log_warning "MULLE_VIRTUAL_ROOT should not be defined at this point ever!"

   local delete_tmp
   local arguments

   #
   # remaining arguments are passed to mulle-make (and not mulle-craft)
   # if separated by '--'
   #
   arguments="-- --preferred-library-style "${OPTION_PREFERRED_LIBRARY_STYLE}""

   if [ $# -ne 0  ] 
   then
      if [ "$1" != "--"  ]
      then
         sde::install::usage "Superflous argument \"$1\" (use -- for mulle-make \
pass through)"
      fi

      shift # get rid off --

      while [ $# -ne 0  ]
      do
         arguments="${arguments} '$1'"
         shift
      done
   fi



   #
   # What we want to achieve is running in a "clean" room environment
   #
   sde::set_custom_environment "${MULLE_DEFINE_FLAGS}"

   if [ "${OPTION_LANGUAGE}" = 'DEFAULT' ]
   then
      local name

      name="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" nameguess "${URL}" `"
      r_lowercase "${name}"
      if [ "${name}" = "${RVAL}" ]
      then
         log_info "Guessed C as the project language"
         OPTION_LANGUAGE="c"
      else
         log_info "Guessed Objective-C as the project language"
         OPTION_LANGUAGE="objc"
      fi
   fi

   case "${OPTION_LANGUAGE}" in
      c)
         r_comma_concat "${OPTION_MARKS}" 'no-all-load,no-import'
         OPTION_MARKS="${RVAL}"
      ;;

      objc)
         r_comma_concat "${OPTION_MARKS}" 'no-singlephase'
         OPTION_MARKS="${RVAL}"
      ;;
   esac


   local rval

   if [ "${OPTION_ONLY_PROJECT}" = 'YES' ]
   then

      log_info "Installing project only to ${C_RESET_BOLD}${PREFIX_DIR}"

      if [ -z "${OPTION_PROJECT_DIR}" ]
      then
         r_make_tmp "$1" "-d" || exit 1
         PROJECT_DIR="${RVAL}" 

         if [ "${OPTION_KEEP_TMP}" = 'NO' ]
         then
            delete_tmp="${PROJECT_DIR}"
         fi

         log_verbose "Temporary directory is ${C_RESET_BOLD}${PROJECT_DIR}"

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

         [ -d "${PROJECT_DIR}/.mulle/sde" ] \
         || fail "Not a mulle-sde project in \"${PROJECT_DIR}\""
      fi

      # project should be ready now
      sde::install::project_only_in_tmp "${URL}" \
                                        "${PROJECT_DIR}" \
                                        "${PREFIX_DIR}" \
                                        "${OPTION_CONFIGURATION}" \
                                        "${OPTION_SERIAL}" \
                                        "${OPTION_SYMLINK}" \
                                        "${OPTION_PREFERRED_LIBRARY_STYLE}" \
                                        "${arguments}"
   else
      if [ -z "${OPTION_PROJECT_DIR}" ]
      then
         r_make_tmp "$1" "-d" || exit 1
         PROJECT_DIR="${RVAL}" 

         if [ "${OPTION_KEEP_TMP}" = 'NO' ]
         then
            delete_tmp="${PROJECT_DIR}"
         fi
      else
         r_simplified_absolutepath "${OPTION_PROJECT_DIR}"
         PROJECT_DIR="${RVAL}"
      fi

      log_info "Installing to ${C_RESET_BOLD}${PREFIX_DIR}"

      #
      # MEMO: one problem we have when using DEPENDENCY_DIR as the install
      # directory is, that we are automatically picking up binaries from
      # the destination into our path.
      #
      log_verbose "Temporary build directory is ${C_RESET_BOLD}${PROJECT_DIR}"

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
         log_setting "KITCHEN_DIR=${KITCHEN_DIR}"
         log_setting "DEPENDENCY_DIR=${DEPENDENCY_DIR}"
         log_setting "MULLE_VIRTUAL_ROOT=${PROJECT_DIR}"
         log_setting "PATH=${DEPENDENCY_DIR}/bin:$PATH"
         log_setting "PROJECT_DIR=${PROJECT_DIR}"
      fi

      sde::install::in_tmp "${URL}" \
                     "${PROJECT_DIR}" \
                     "${OPTION_MARKS}" \
                     "${OPTION_CONFIGURATION}" \
                     "${OPTION_SERIAL}" \
                     "${OPTION_SYMLINK}" \
                     "${OPTION_PREFERRED_LIBRARY_STYLE}" \
                     "${OPTION_BRANCH}" \
                     "${OPTION_TAG}" \
                     "${OPTION_POST_INIT}" \
                     "${arguments}" \
                     "${environment}" 
   fi

   rval=$?

   if [ ${rval} -eq 0 ]
   then
      if [ ! -z "${delete_tmp}" ]
      then
         cd /
         rmdir_safer "${delete_tmp}"
      fi
   fi

   return $rval
}
