#! /usr/bin/env bash
#
#   Copyright (c) 2019 Nat! - Mulle kybernetiK
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
MULLE_SDE_RENAME_SH="included"


sde_rename_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} rename [options] <newname>

   Rename an existing project. This will change environment variables in
   the project domain. It will alsosearch/replace file names and file
   contents unless options are set to the contrary.

   This can be dangerous!

Options:
   --no-filenames : don't search/replace project identifiers in filenames
   --no-contents  : don't search/replace project identifiers in file contents
   -h             : show this usage
EOF
   exit 1
}


rename_old_to_new_filename()
{
   log_entry "rename_old_to_new_filename" "$@"

   local filename="$1"

   local renamed

   renamed="${filename//${old}/${name}}"
   log_verbose "Rename \"${filename}\" to \"${renamed}\""
   exekutor mv "${filename}" "${renamed}" || exit 1
}


_local_search_and_replace_filenames()
{
   log_entry "_local_search_and_replace_filenames" "$@"

   local old="$1"
   local name="$2"

   local filename

   IFS=$'\n' ; set -f
   for filename in `eval_rexekutor find . -mindepth 1 -maxdepth 1 -type f -name "*${old}*" -print`
   do
      set +f; IFS="${DEFAULT_IFS}"

      rename_old_to_new_filename "${filename}"
   done
   set +f; IFS="${DEFAULT_IFS}"
}


search_and_replace_filenames()
{
   log_entry "search_and_replace_filenames" "$@"

   local dir="$1"
   local old="$2"
   local name="$3"
   local type="$4"

   if [ -e "${dir}" ]
   then
      local filename
      local renamed

      IFS=$'\n' ; set -f
      for filename in  `eval_rexekutor find "${dir}" -type "${type}" -name "*${old}*" -print`
      do
         set +f; IFS="${DEFAULT_IFS}"

         rename_old_to_new_filename "${filename}"
      done
      set +f; IFS="${DEFAULT_IFS}"
   fi
}



###
###

edit_old_to_new_content()
{
   log_entry "edit_old_to_new_content" "$@"

   local filename="$1"
   local grep_statement="$2"
   local sed_statement="$3"

   local permissions

   if eval_rexekutor "${grep_statement}" "${filename}"
   then
      log_verbose "Editing \"${filename}\""

      permissions="`lso "${filename}"`"
      rexekutor chmod +w "${filename}"

      eval_exekutor "$sed_statement" "${filename}" || exit 1

      rexekutor chmod "${permissions}" "${filename}"
   fi
}


_local_search_and_replace_contents()
{
   log_entry "_local_search_and_replace_contents" "$@"

   local filename

   IFS=$'\n' ; set -f
   for filename in `eval_rexekutor find . -mindepth 1 -maxdepth 1 -type f -print`
   do
      set +f; IFS="${DEFAULT_IFS}"

      edit_old_to_new_content "${filename}" "$@"
   done
   set +f; IFS="${DEFAULT_IFS}"
}


search_and_replace_contents()
{
   log_entry "search_and_replace_contents" "$@"

   local dir="$1" ; shift

   if [ -e "${dir}" ]
   then
      local filename

      IFS=$'\n' ; set -f
      for filename in  `eval_rexekutor find "${dir}" -type f -print`
      do
         set +f; IFS="${DEFAULT_IFS}"

         edit_old_to_new_content "${filename}" "$@"
      done
      set +f; IFS="${DEFAULT_IFS}"
   fi
}


walk_over_mulle_match_path()
{
   log_entry "walk_over_mulle_match_path" "$@" "($MULLE_MATCH_PATH)"

   local callback="$1" ; shift

   local dir

   IFS=':' ; set -f
   for dir in ${MULLE_MATCH_PATH}
   do
      set +f; IFS="${DEFAULT_IFS}"
      case "${dir}" in
         .*)
         ;;

         *)
            "${callback}" "${dir}" "$@"
         ;;
      esac
   done
   set +f; IFS="${DEFAULT_IFS}"
}


walk_over_test_paths()
{
   log_entry "walk_over_test_paths" "$@"

   local callback="$1" ; shift

   local dir

   IFS=':' ; set -f
   for dir in *
   do
      if [ -d "${dir}" ]
      then
         set +f; IFS="${DEFAULT_IFS}"
         case "${dir}" in
            .*)
            ;;

            *)
               "${callback}" "${dir}" "$@"
            ;;
         esac
      fi
   done
   set +f; IFS="${DEFAULT_IFS}"
}


r_rename_current_project()
{
   log_entry "r_rename_current_project" "$@"

   local changes

   OLD_PROJECT_NAME="${PROJECT_NAME}"
   OLD_PROJECT_DOWNCASE_IDENTIFIER="${PROJECT_DOWNCASE_IDENTIFIER}"
   OLD_PROJECT_IDENTIFIER="${PROJECT_IDENTIFIER}"
   OLD_PROJECT_UPCASE_IDENTIFIER="${PROJECT_UPCASE_IDENTIFIER}"

   unset PROJECT_UPCASE_IDENTIFIER
   unset PROJECT_DOWNCASE_IDENTIFIER
   unset PROJECT_IDENTIFIER

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   set_projectname_variables "${newname}"
   if [ "${OPTION_SAVE_ENV}" != 'NO' ]
   then
      log_verbose "Changing Environment variables"

      save_projectname_variables
      changes="${changes}changes"
   fi

   [ "${PROJECT_NAME}" != "${newname}" ] && internal_fail "Did not set PROJECT_NAME"

   if [ "${OPTION_SEARCH_REPLACE_FILENAMES}" != 'NO' ]
   then
      log_verbose "Changing filenames"

      _local_search_and_replace_filenames "${OLD_PROJECT_NAME}" "${PROJECT_NAME}"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_NAME}" "${PROJECT_NAME}" "f"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_NAME}" "${PROJECT_NAME}" "d"

      _local_search_and_replace_filenames "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}" "f"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}" "d"

      _local_search_and_replace_filenames "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}" "f"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}" "d"

      _local_search_and_replace_filenames "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}" "f"
      walk_over_mulle_match_path search_and_replace_filenames "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}" "d"

      changes="${changes}changes"
   fi

   if [ "${OPTION_SEARCH_REPLACE_CONTENTS}" != 'NO' ]
   then
      log_verbose "Changing file contents"

      if [ -z "${MULLE_PATH_SH}" ]
      then
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || internal_fail "missing file"
      fi
      if [ -z "${MULLE_FILE_SH}" ]
      then
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || internal_fail "missing file"
      fi
      # create inline sed expression command
      local sed_cmdline

      sed_cmdline="inplace_sed"

      sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_NAME}/${PROJECT_NAME}/g'"
      sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_IDENTIFIER}/${PROJECT_IDENTIFIER}/g'"
      sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_DOWNCASE_IDENTIFIER}/${PROJECT_DOWNCASE_IDENTIFIER}/g'"
      sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_UPCASE_IDENTIFIER}/${OLD_PROJECT_UPCASE_IDENTIFIER}/g'"

      local grep_cmdline

      grep_cmdline="grep -q -s -n"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_NAME}'"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_IDENTIFIER}'"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_DOWNCASE_IDENTIFIER}'"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_UPCASE_IDENTIFIER}'"

      _local_search_and_replace_contents "${grep_cmdline}" "${sed_cmdline}"
      walk_over_mulle_match_path search_and_replace_contents "${grep_cmdline}" "${sed_cmdline}"

      changes="${changes}changes"
   fi

   RVAL="${changes}"
}

#
# TODO: remove test and subprojects from renaming
#       rename them individually ?
#
sde_rename_main()
{
   log_entry "sde_rename_main" "$@"

   local OPTION_SEARCH_REPLACE_FILENAMES='DEFAULT'
   local OPTION_SEARCH_REPLACE_CONTENTS='DEFAULT'
   local OPTION_SAVE_ENV='DEFAULT'
   local OPTION_TESTS='DEFAULT'

   local newname

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_rename_usage
         ;;

         --project-name)
            [ $# -eq 1 ] && sde_rename_usage "Missing argument to \"$1\""
            shift

            PROJECT_NAME="$1"
         ;;

         --save-environment)
            OPTION_SAVE_ENV='NO'
         ;;

         --no-save-environment)
            OPTION_SAVE_ENV='NO'
         ;;

         --filenames)
            OPTION_SEARCH_REPLACE_FILENAMES='YES'
         ;;

         --contents)
            OPTION_SEARCH_REPLACE_CONTENTS='YES'
         ;;

         --no-filenames)
            OPTION_SEARCH_REPLACE_FILENAMES='NO'
         ;;

         --no-contents)
            OPTION_SEARCH_REPLACE_CONTENTS='NO'
         ;;

         --tests)
            OPTION_TESTS='YES'
         ;;

         --no-tests)
            OPTION_TESTS='NO'
         ;;

         -*)
            sde_rename_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${PROJECT_NAME}" ]
   then
      fail "Could not figure out old project name"
   fi

   newname="$1"
   if [ -z "${newname}" ]
   then
      sde_rename_usage "Missing name argument"
   fi
   shift

   [ $# -ne 0 ] && sde_rename_usage "Superflous arguments \"$*\""

   case "${newname}" in
      *[^A-Za-z0-9_-]*)
         fail "Only identifier characters and - are allowed for project name"
      ;;
   esac

   if [ "${PROJECT_NAME}" = "${newname}" ]
   then
      fail "No change in name \"${newname}\" (${PWD#${MULLE_USER_PWD}/})"
   fi

   (
      r_rename_current_project "${newname}"
   ) || exit 1


   if [ "${OPTION_TESTS}" != 'NO' ]
   then
      local test_path
      local testdir

      log_verbose "Renaming test directories (if present)"

      test_path="`rexekutor mulle-sde -s test test-dir`"

      local cmdline

      cmdline="--no-tests"

      case "${OPTION_SEARCH_REPLACE_FILENAMES}" in
         'YES')
            cmdline="${cmdline} --filenames"
         ;;

         'NO')
            cmdline="${cmdline} --no-filenames"
         ;;
      esac

      case "${OPTION_SEARCH_REPLACE_CONTENTS}" in
         'YES')
            cmdline="${cmdline} --contents"
         ;;

         'NO')
            cmdline="${cmdline} --no-contents"
         ;;
      esac

      case "${OPTION_SAVE_ENV}" in
         'YES')
            cmdline="${cmdline} --save-env"
         ;;

         'NO')
            cmdline="${cmdline} --no-save-env"
         ;;
      esac

      IFS=$'\n'; set -f
      for testdir in ${test_path}
      do
         IFS="${DEFAULT_IFS}"; set +f
         (
            MULLE_VIRTUAL_ROOT=
            PROJECT_NAME=

            log_verbose "$testdir"

            rexekutor cd "${testdir}" && \
            exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} rename ${cmdline} "${newname}"
         )
      done
      IFS="${DEFAULT_IFS}"; set +f
   fi

   log_verbose "Done"
}
