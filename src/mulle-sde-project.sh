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
MULLE_SDE_PROJECT_SH="included"


sde_project_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} project [options] <command>

   Project related commands.

Options:
   -h     : show this usage

Commands:
   rename : rename the project

EOF
   exit 1
}


sde_rename_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} project rename [options] <newname>

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


set_projectname_variables()
{
   log_entry "set_projectname_variables" "$@"

   PROJECT_NAME="${1:-${PROJECT_NAME}}"

   [ -z "${PROJECT_NAME}" ] && internal_fail "PROJECT_NAME can't be empty.
${C_INFO}Are you running inside a mulle-sde environment ?"

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"      || return 1
   fi

   r_identifier "${PROJECT_NAME}"
   PROJECT_IDENTIFIER="${RVAL}"

   r_tweaked_de_camel_case "${PROJECT_IDENTIFIER}"
   r_lowercase "${RVAL}"
   PROJECT_DOWNCASE_IDENTIFIER="${RVAL}"
   r_uppercase "${PROJECT_DOWNCASE_IDENTIFIER}"
   PROJECT_UPCASE_IDENTIFIER="${RVAL}"
}


set_projectlanguage_variables()
{
   log_entry "set_projectlanguage_variables" "$@"

   PROJECT_LANGUAGE="${1:-${PROJECT_LANGUAGE}}"

   if [ -z "${PROJECT_LANGUAGE}" ]
   then
      # it's OK could be project type "none"
      return
   fi

   r_lowercase "${PROJECT_LANGUAGE}"
   PROJECT_DOWNCASE_LANGUAGE="${RVAL}"
   r_uppercase "${PROJECT_LANGUAGE}"
   PROJECT_UPCASE_LANGUAGE="${RVAL}"

   PROJECT_DIALECT="${PROJECT_DIALECT:-${PROJECT_LANGUAGE}}"
   r_lowercase "${PROJECT_DIALECT}"
   PROJECT_DOWNCASE_DIALECT="${RVAL}"
   r_uppercase "${PROJECT_DIALECT}"
   PROJECT_UPCASE_DIALECT="${RVAL}"

   PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-${PROJECT_DOWNCASE_DIALECT}}"
}


#
# this has to move to templating really...
#
r_add_template_named_file()
{
   local extension="${1:-default}"
   local name="$2"
   local envvar="$3"

   #
   # figure out if we want to add a header
   #
   RVAL="${!envvar}"
   rexekutor [ -f "${RVAL}" ] && return 0

   RVAL="${MULLE_SDE_ETC_DIR}/${name}.${extension}"
   rexekutor [ -f "${RVAL}" ] && return 0

   RVAL="${MULLE_SDE_ETC_DIR}/${name}.default"
   rexekutor [ -f "${RVAL}" ] && return 0

   RVAL="${HOME}/.mulle/etc/sde/${name}.${extension}"
   rexekutor [ -f "${RVAL}" ] && return 0

   RVAL="${HOME}/.mulle/etc/sde/${name}.default"
   rexekutor [ -f "${RVAL}" ] && return 0

   RVAL=""
   return 1
}


r_add_template_header_file()
{
   r_add_template_named_file "$1" "header" "MULLE_SDE_FILE_HEADER"
}


r_add_template_footer_file()
{
   r_add_template_named_file "$1" "footer" "MULLE_SDE_FILE_FOOTER"
}


set_oneshot_variables()
{
   log_entry "set_oneshot_variables" "$@"

   local filename="$1"
   local class="$2"
   local category="$3"

   if [ ! -z "${class}" ]
   then
      ONESHOT_CLASS="${class}"
   fi
   if [ ! -z "${category}" ]
   then
      ONESHOT_CATEGORY="${category}"
   fi

   if [ -z "${filename}" ]
   then
      return
   fi

   if is_absolutepath "${filename}"
   then
      internal_fail "filename \"${filename}\" must be relative"
   fi

   ONESHOT_FILENAME="${filename}"

   ONESHOT_FILENAME_NO_EXT="${filename%.*}"
   r_extensionless_basename "${ONESHOT_FILENAME}"
   ONESHOT_NAME="${RVAL}"

   r_identifier "${ONESHOT_NAME}"
   ONESHOT_IDENTIFIER="${RVAL}"
   r_lowercase "${ONESHOT_IDENTIFIER}"
   ONESHOT_DOWNCASE_IDENTIFIER="${RVAL}"
   r_uppercase "${ONESHOT_IDENTIFIER}"
   ONESHOT_UPCASE_IDENTIFIER="${RVAL}"

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh" || return 1
   fi

   r_de_camel_case_upcase_identifier "${ONESHOT_NAME}"
   ONESHOT_UPCASE_C_IDENTIFIER="${RVAL}"
   r_lowercase "${ONESHOT_UPCASE_C_IDENTIFIER}"
   ONESHOT_DOWNCASE_C_IDENTIFIER="${RVAL}"

   r_basename "${ONESHOT_FILENAME}"
   ONESHOT_BASENAME="${RVAL}"

   # hack!!

   local ext
   local headerfile
   local footerfile

   ext="${filename##*.}"

   r_add_template_header_file "${ext}"
   headerfile="${RVAL}"

   r_add_template_footer_file "${ext}"
   footerfile="${RVAL}"

   TEMPLATE_HEADER_FILE="${headerfile}"
   TEMPLATE_FOOTER_FILE="${footerfile}"
}


export_oneshot_environment()
{
   log_entry "export_oneshot_environment" "$@"

   local filepath="$1"
   local class="$2"
   local category="$3"


   if [ ! -z "${class}" ]
   then
      export ONESHOT_CLASS
   fi
   if [ ! -z "${category}" ]
   then
      export ONESHOT_CATEGORY
   fi

   if [ -z "${filepath}" ]
   then
      return
   fi

   export ONESHOT_FILENAME \
          ONESHOT_FILENAME_NO_EXT \
          ONESHOT_NAME \
          ONESHOT_IDENTIFIER \
          ONESHOT_DOWNCASE_IDENTIFIER \
          ONESHOT_UPCASE_IDENTIFIER \
          ONESHOT_UPCASE_C_IDENTIFIER \
          ONESHOT_DOWNCASE_C_IDENTIFIER \
          ONESHOT_BASENAME

#   export TEMPLATE_HEADER_FILE \
#          TEMPLATE_FOOTER_FILE
}


export_projectname_environment()
{
   log_entry "export_projectname_environment" "$@"

   export PROJECT_NAME  \
          PROJECT_IDENTIFIER \
          PROJECT_DOWNCASE_IDENTIFIER \
          PROJECT_UPCASE_IDENTIFIER
}


export_projectlanguage_environment()
{
   log_entry "export_projectlanguage_environment" "$@"

   if [ -z "${PROJECT_LANGUAGE}" ]
   then
      return
   fi

   export PROJECT_LANGUAGE \
          PROJECT_UPCASE_LANGUAGE \
          PROJECT_DOWNCASE_LANGUAGE \
 \
          PROJECT_DIALECT \
          PROJECT_UPCASE_DIALECT \
          PROJECT_DOWNCASE_DIALECT
}



project_add_envscope_if_missing()
{
   log_entry "save_projectname_variables" "$@"

   #
   # save it into /etc now, use -f flag to create the project scope
   # see mulle-env-scope for the meaning of 20
   #
   exekutor "${MULLE_ENV:-mulle-env}" \
                     --search-as-is \
                     -s \
                     ${MULLE_TECHNICAL_FLAGS} \
                  scope \
                     add --if-missing --priority 20 project
}

project_env_set_var()
{
   local key="$1"; shift
   local value="$1"; shift

   log_verbose "Environment: ${key}=\"${value}\""
   exekutor "${MULLE_ENV:-mulle-env}" \
                     --search-as-is \
                     -s \
                     ${MULLE_TECHNICAL_FLAGS} \
                     "$@" \
                  environment \
                     --scope project \
                     set "${key}" "${value}" || internal_fail "failed env set"
}


# those affected by renames
save_projectname_variables()
{
  log_entry "save_projectname_variables" "$@"

  project_env_set_var PROJECT_NAME                "${PROJECT_NAME}"  "$@"
  project_env_set_var PROJECT_IDENTIFIER          "${PROJECT_IDENTIFIER}" "$@"
  project_env_set_var PROJECT_DOWNCASE_IDENTIFIER "${PROJECT_DOWNCASE_IDENTIFIER}" "$@"
  project_env_set_var PROJECT_UPCASE_IDENTIFIER   "${PROJECT_UPCASE_IDENTIFIER}" "$@"
}


#
# not saving case conversions here
#
save_projectlanguage_variables()
{
   log_entry "save_projectlanguage_variables" "$@"

   if [ ! -z "${PROJECT_LANGUAGE}" ]
   then
      project_env_set_var PROJECT_LANGUAGE   "${PROJECT_LANGUAGE}"  "$@"
      project_env_set_var PROJECT_DIALECT    "${PROJECT_DIALECT}" "$@"
      project_env_set_var PROJECT_EXTENSIONS "${PROJECT_EXTENSIONS}" "$@"
   fi
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
      set +o noglob; IFS="${DEFAULT_IFS}"

      rename_old_to_new_filename "${filename}"
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
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
         set +o noglob; IFS="${DEFAULT_IFS}"

         rename_old_to_new_filename "${filename}"
      done
      set +o noglob; IFS="${DEFAULT_IFS}"
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

   if file_is_binary "${filename}"
   then
      return
   fi

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
      set +o noglob; IFS="${DEFAULT_IFS}"

      edit_old_to_new_content "${filename}" "$@"
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
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
         set +o noglob; IFS="${DEFAULT_IFS}"

         edit_old_to_new_content "${filename}" "$@"
      done
      set +o noglob; IFS="${DEFAULT_IFS}"
   fi
}


walk_over_mulle_match_path()
{
   log_entry "walk_over_mulle_match_path" "$@" "($MULLE_MATCH_PATH)"

   local callback="$1" ; shift

   local dir

   set -o noglob; IFS=':'
   for dir in ${MULLE_MATCH_PATH}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"
      case "${dir}" in
         .*)
         ;;

         *)
            "${callback}" "${dir}" "$@"
         ;;
      esac
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
}


walk_over_test_paths()
{
   log_entry "walk_over_test_paths" "$@"

   local callback="$1" ; shift

   local dir

   set -o noglob; IFS=':'
   for dir in *
   do
      if [ -d "${dir}" ]
      then
         set +o noglob; IFS="${DEFAULT_IFS}"
         case "${dir}" in
            .*)
            ;;

            *)
               "${callback}" "${dir}" "$@"
            ;;
         esac
      fi
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
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

   if [ -z "${MULLE_SDE_PROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-project.sh" || internal_fail "missing file"
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
      if [ "${PROJECT_NAME}" != "${OLD_PROJECT_IDENTIFIER}" ]
      then
         sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_IDENTIFIER}/${PROJECT_IDENTIFIER}/g'"
      fi
      if [ "${PROJECT_NAME}" != "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" -a \
           "${PROJECT_IDENTIFIER}" != "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" ]
      then
         sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_DOWNCASE_IDENTIFIER}/${PROJECT_DOWNCASE_IDENTIFIER}/g'"
      fi
      if [ "${PROJECT_NAME}" != "${OLD_PROJECT_UPCASE_IDENTIFIER}" -a \
           "${PROJECT_IDENTIFIER}" != "${OLD_PROJECT_UPCASE_IDENTIFIER}" ]
      then
         sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_UPCASE_IDENTIFIER}/${OLD_PROJECT_UPCASE_IDENTIFIER}/g'"
      fi

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
            export PROJECT_NAME
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

      set -o noglob; IFS=$'\n'
      for testdir in ${test_path}
      do
         set +o noglob; IFS="${DEFAULT_IFS}"
         (
            MULLE_VIRTUAL_ROOT=
            PROJECT_NAME=

            log_verbose "$testdir"

            rexekutor cd "${testdir}" && \
            exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} project rename ${cmdline} "${newname}"
         )
      done
      set +o noglob; IFS="${DEFAULT_IFS}"
   fi

   log_verbose "Done"
}



sde_project_main()
{
   log_entry "sde_project_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_rename_usage
         ;;

         -*)
            sde_project_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "$1" in
      rename)
         shift
         sde_rename_main "$@"
      ;;

      *)
         sde_project_usage "Unknown command \"$1\""
      ;;
   esac
}
