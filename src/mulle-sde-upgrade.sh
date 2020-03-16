#! /usr/bin/env bash
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
MULLE_SDE_UPGRADE_SH="included"


sde_upgrade_usage()
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

   E.g. .mulle/share and cmake/share will be affected, but CMakeLists.txt
        will not.

   To update CMakeLists.txt run upgrade again with --project-file CMakeLists.txt

Options:
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
sde_upgrade_project()
{
   log_entry "sde_upgrade_project" "$@"

   # shellcheck source=src/mulle-sde-init.sh
   [ -z "${MULLE_SDE_INIT_SH}" ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   eval_exekutor sde_init_main --upgrade "$@"
}


###
sde_upgrade_subprojects()
{
   log_entry "sde_upgrade_subprojects" "$@"

   local parallel="$1"

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || internal_fail "missing file"
   fi

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
   sde_subproject_map 'Upgrading' "${mode}" "mulle-sde ${flags} upgrade --no-test --no-subprojects"
}


sde_upgrade_test()
{
   log_entry "sde_upgrade_test" "$@"

   MULLE_SDE_TEST_PATH="`mulle-env ${MULLE_TECHNICAL_FLAGS} \
                           environment \
                              get MULLE_SDE_TEST_PATH`"

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


sde_upgrade_main()
{
   log_entry "sde_upgrade_main" "$@"

   local OPTION_PARALLEL='YES'
   local OPTION_PROJECT='YES'
   local OPTION_SUBPROJECTS='YES'
   local OPTION_TEST='YES'

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_upgrade_usage
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

   if [ "${OPTION_PROJECT}" = 'YES' ]
   then
      (
         sde_upgrade_project "$@"
      ) || exit 1
   fi

   if [ "${OPTION_SUBPROJECTS}" = 'YES' ]
   then
      (
         MULLE_VIRTUAL_ROOT="`pwd -P`"
         export MULLE_VIRTUAL_ROOT

         eval `"${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sde` || exit 1

         # not sure about next two, but its the proper transformation
         # of previous code
         unset MULLE_SDE_ETC_DIR
         unset MULLE_SDE_SHARE_DIR

         # unset MULLE_SDE_VAR_DIR
         unset MULLE_MATCH_ETC_DIR
         unset MULLE_MATCH_SHARE_DIR
         unset MULLE_MATCH_VAR_DIR

         sde_upgrade_subprojects "${OPTION_PARALLEL}"
      ) || exit 1
   fi

   if [ "${OPTION_TEST}" = 'YES' ]
   then
      (
         sde_upgrade_test "$@"
      ) || exit 1
   fi
}


