# shellcheck shell=bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_SDE_UPGRADE_SH='included'


sde::upgrade::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   SHOWN_COMMANDS="\
   project    : upgrade project template content  (rarely useful)
"

    cat <<EOF >&2
Usage:
   ${UPGRADE_USAGE_NAME:-${MULLE_USAGE_NAME}} upgrade [project]

   Upgrade to a newer mulle-sde version. The default is to upgrade the non-
   project files only. Upgrading project files is usually not a good idea,
   as you could lose changes. Only environment variables in the "share" scope
   will be affected by an extension upgrade.

   Assume that .mulle/share and cmake/share will be completely deleted and
   loaded with new content. Files like CMakeLists.txt will not be touched.

   To upgrade CMakeLists.txt run another upgrade with
   --project-file CMakeLists.txt

Options:
   --clean               : clean tidy, mirrors, archives before upgrading
   --project-file <file> : update a single project file to newest verion
   --no-parallel         : do not upgrade projects in parallel
   --no-project          : do not upgrade the project
   --no-subprojects      : do not upgrade subprojects
   --no-test             : do not upgrade a test folder if it exists

Commands:
EOF

   (
      printf "%s\n" "${SHOWN_COMMANDS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
      then
         printf "%s\n" "${HIDDEN_COMMANDS}"
      fi
   ) | sed '/^$/d' | LC_ALL=C sort >&2

   cat <<EOF >&2
         (use -v for more commands)
EOF
   exit 1
}


###
### parameters and environment variables
###
sde::upgrade::project()
{
   log_entry "sde::upgrade::project" "$@"

   # shellcheck source=src/mulle-sde-init.sh
   include "sde::init"

   eval_exekutor sde::init::main --upgrade "$@"
}


###
sde::upgrade::subprojects()
{
   log_entry "sde::upgrade::subprojects" "$@"

   local parallel="$1"

   include "sde::subproject"

   local flags

   flags="${MULLE_TECHNICAL_FLAGS}"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="${flags} -f"
   fi

   # a subproject when upgraded "feels" like a main project
   # unfortunately we can't pass parameters down ards
   local mode

   mode="no-env"
   if [ "${parallel}" = "mode" ]
   then
      mode="${mode},parallel"
   fi
   sde::subproject::map 'Upgrading' "${mode}" "mulle-sde ${flags} upgrade --no-test --no-subprojects"
}


sde::upgrade::test()
{
   log_entry "sde::upgrade::test" "$@"

   # this can fail on projects, which older. ignore
   MULLE_SDE_TEST_PATH="`mulle-env \
                              ${MULLE_TECHNICAL_FLAGS} \
                              -s \
                           environment \
                              get MULLE_SDE_TEST_PATH 2> /dev/null`"

   IFS=':'
   for i in ${MULLE_SDE_TEST_PATH:-test}
   do
      IFS="${DEFAULT_IFS}"
      if [ -d "${i}" ]
      then
         if [ -d "${i}/.mulle" -o -d "${i}/.mulle-env" ]
         then
            log_info "Upgrade test ${C_RESET_BOLD}${i}"
            ( cd "${i}"; mulle-sde ${MULLE_TECHNICAL_FLAGS} upgrade ) || exit 1
         else
            log_verbose "Test directory \"$i\" doesn't look like a mulle-sde project"
         fi
      fi
   done
   IFS="${DEFAULT_IFS}"
}


sde::upgrade::main()
{
   log_entry "sde::upgrade::main" "$@"

   local OPTION_PARALLEL='YES'
   local OPTION_PROJECT='YES'
   local OPTION_SUBPROJECTS='YES'
   local OPTION_TEST='YES'
   local OPTION_CLEAN='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::upgrade::usage
         ;;

         --clean)
            OPTION_CLEAN='YES'
         ;;

         --serial|--no-parallel)
            OPTION_PARALLEL='NO'
         ;;

         --no-project)
            OPTION_PROJECT='NO'
         ;;

         --no-recurse|--no-subprojects)
            OPTION_SUBPROJECTS='NO'
         ;;

         --no-test)
            OPTION_TEST='NO'
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_CLEAN}" = 'YES' ]
   then
      (
         include "sde::clean"

         sde::clean::main tidy mirror archive
      ) || exit 1
   fi

   if [ "${OPTION_PROJECT}" = 'YES' ]
   then
      (
         sde::upgrade::project "$@"
      ) || exit 1
   fi

   if [ "${OPTION_SUBPROJECTS}" = 'YES' ]
   then
      (
         MULLE_VIRTUAL_ROOT="`pwd -P`"
         export MULLE_VIRTUAL_ROOT

         MULLE_VIRTUAL_ROOT_ID="$(PATH='/bin:/usr/bin:/usr/local/bin' shasum -a 256 <<< "${MULLE_VIRTUAL_ROOT}")"
         MULLE_VIRTUAL_ROOT_ID="${MULLE_VIRTUAL_ROOT_ID:1:12}"
         export MULLE_VIRTUAL_ROOT_ID

         eval `"${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sde` || exit 1

         # Preserve MULLE_SOURCETREE_CONFIG_NAME for projects with multiple
         # sourcetree configs (e.g. x11/wayland/macos). mulle-tool-env only
         # loads tool dirs, not the full project environment, so we need to
         # read it explicitly here so that subproject::get_addresses can call
         # mulle-sourcetree list with the correct config.
         if [ -z "${MULLE_SOURCETREE_CONFIG_NAME}" ]
         then
            MULLE_SOURCETREE_CONFIG_NAME="`"${MULLE_ENV:-mulle-env}" \
                                               --search-as-is \
                                               -s \
                                            environment \
                                               get MULLE_SOURCETREE_CONFIG_NAME 2>/dev/null`"
            [ -n "${MULLE_SOURCETREE_CONFIG_NAME}" ] && \
               export MULLE_SOURCETREE_CONFIG_NAME
         fi

         # not sure about next two, but its the proper transformation
         # of previous code
         unset MULLE_SDE_ETC_DIR
         unset MULLE_SDE_SHARE_DIR

         # unset MULLE_SDE_VAR_DIR
         unset MULLE_MATCH_ETC_DIR
         unset MULLE_MATCH_SHARE_DIR
         unset MULLE_MATCH_VAR_DIR

         sde::upgrade::subprojects "${OPTION_PARALLEL}"
      ) || exit 1
   fi

   if [ "${OPTION_TEST}" = 'YES' ]
   then
      (
         sde::upgrade::test "$@"
      ) || exit 1
   fi
}


