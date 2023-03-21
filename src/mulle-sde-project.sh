# shellcheck shell=bash
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
MULLE_SDE_PROJECT_SH='included'


sde::project::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} project [options] <command>

   Project related commands.

Options:
   -h     : show this usage

Commands:
   rename    : rename the project
   remove    : remove the project
   variables : show project related variable values
EOF
   exit 1
}


sde::project::rename_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} project rename [options] <newname>

   Rename an existing project. This will change environment variables in
   the project domain. It will also search/replace file names and file
   contents unless options are set to the contrary.

   This is therefore dangerous! Use it on a copy of your project only.

Options:
   --no-filenames : don't search/replace project identifiers in filenames
   --no-contents  : don't search/replace project identifiers in file contents
   -h             : show this usage
EOF
   exit 1
}


sde::project::clear_variables()
{
   unset PROJECT_NAME
   unset PROJECT_IDENTIFIER
   unset PROJECT_DOWNCASE_IDENTIFIER
   unset PROJECT_UPCASE_IDENTIFIER
   unset PROJECT_LANGUAGE
   unset PROJECT_DOWNCASE_LANGUAGE
   unset PROJECT_UPCASE_LANGUAGE
   unset PROJECT_DIALECT
   unset PROJECT_DOWNCASE_DIALECT
   unset PROJECT_UPCASE_DIALECT
   unset PROJECT_EXTENSIONS
   unset PROJECT_PREFIXLESS_NAME
   unset PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER
}


sde::project::set_name_variables()
{
   log_entry "sde::project::set_name_variables" "$@"

   PROJECT_NAME="${1:-${PROJECT_NAME}}"

   [ -z "${PROJECT_NAME}" ] && _internal_fail "PROJECT_NAME can't be empty.
${C_INFO}Are you running inside a mulle-sde environment ?"

   r_identifier "${PROJECT_NAME}"
   PROJECT_IDENTIFIER="${RVAL}"

   # hack for shell scripts
   PROJECT_PREFIXLESS_NAME="${ONESHOT_NAME#*-}"

   r_identifier "${PROJECT_PREFIXLESS_NAME}"
   r_lowercase "${RVAL}"
   PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER="${RVAL}"

   include "case"

   r_smart_file_upcase_identifier "${PROJECT_NAME}"
   PROJECT_UPCASE_IDENTIFIER="${RVAL}"

   r_lowercase "${RVAL}"
   PROJECT_DOWNCASE_IDENTIFIER="${RVAL}"
}


sde::project::set_language_variables()
{
   log_entry "sde::project::set_language_variables" "$@"

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
sde::project::r_add_template_named_file()
{
   local extension="${1:-default}"
   local name="$2"
   local envvar="$3"

   #
   # figure out if we want to add a header
   #
   r_shell_indirect_expand "${envvar}"
   rexekutor [ -f "${RVAL}" ] && return 0

   RVAL="${MULLE_SDE_ETC_DIR}/${name}.${extension}"
   rexekutor [ -f "${RVAL}" ] && return 0

   if [ "${extension}" != "default" ]
   then
      RVAL="${MULLE_SDE_ETC_DIR}/${name}.default"
      rexekutor [ -f "${RVAL}" ] && return 0
   fi

   RVAL="${MULLE_SDE_SHARE_DIR}/${name}.${extension}"
   rexekutor [ -f "${RVAL}" ] && return 0

   if [ "${extension}" != "default" ]
   then
      RVAL="${MULLE_SDE_SHARE_DIR}/${name}.default"
      rexekutor [ -f "${RVAL}" ] && return 0
   fi

   case "${MULLE_UNAME}" in 
      linux)
         RVAL="${HOME}/.config/mulle/etc/sde/${name}.${extension}"
         rexekutor [ -f "${RVAL}" ] && return 0

         if [ "${extension}" != "default" ]
         then
            RVAL="${HOME}/.config/mulle/etc/sde/${name}.default"
            rexekutor [ -f "${RVAL}" ] && return 0
         fi
      ;;

      *)
         RVAL="${HOME}/.mulle/etc/sde/${name}.${extension}"
         rexekutor [ -f "${RVAL}" ] && return 0

         if [ "${extension}" != "default" ]
         then
            RVAL="${HOME}/.mulle/etc/sde/${name}.default"
            rexekutor [ -f "${RVAL}" ] && return 0
         fi
      ;;
   esac

   RVAL=""
   return 1
}


sde::project::r_add_template_header_file()
{
   sde::project::r_add_template_named_file "$1" "header" "MULLE_SDE_FILE_HEADER"
}


sde::project::r_add_template_footer_file()
{
   sde::project::r_add_template_named_file "$1" "footer" "MULLE_SDE_FILE_FOOTER"
}


sde::project::clear_oneshot_variables()
{
   unset ONESHOT_CLASS
   unset ONESHOT_CATEGORY
   unset ONESHOT_FILENAME
   unset ONESHOT_FILENAME_NO_EXT
   unset ONESHOT_NAME
   unset ONESHOT_IDENTIFIER
   unset ONESHOT_DOWNCASE_IDENTIFIER
   unset ONESHOT_UPCASE_IDENTIFIER
   unset ONESHOT_UPCASE_C_IDENTIFIER
   unset ONESHOT_DOWNCASE_C_IDENTIFIER
   unset ONESHOT_BASENAME
   unset ONESHOT_PREFIXLESS_NAME
   unset ONESHOT_PREFIXLESS_DOWNCASE_IDENTIFIER
   unset TEMPLATE_HEADER_FILE
   unset TEMPLATE_FOOTER_FILE
}


sde::project::set_oneshot_variables()
{
   log_entry "sde::project::set_oneshot_variables" "$@"

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
      _internal_fail "filename \"${filename}\" must be relative"
   fi

   ONESHOT_FILENAME="${filename}"

   ONESHOT_FILENAME_NO_EXT="${filename%.*}"

   r_extensionless_basename "${ONESHOT_FILENAME}"
   ONESHOT_NAME="${RVAL}"

   # hack for shell scripts
   ONESHOT_PREFIXLESS_NAME="${ONESHOT_NAME#*-}"

   r_identifier "${ONESHOT_PREFIXLESS_NAME}"
   r_lowercase "${RVAL}"
   ONESHOT_PREFIXLESS_DOWNCASE_IDENTIFIER="${RVAL}"

   r_identifier "${ONESHOT_NAME}"
   ONESHOT_IDENTIFIER="${RVAL}"
   r_lowercase "${ONESHOT_IDENTIFIER}"
   ONESHOT_DOWNCASE_IDENTIFIER="${RVAL}"
   r_uppercase "${ONESHOT_IDENTIFIER}"
   ONESHOT_UPCASE_IDENTIFIER="${RVAL}"

   include "case"

   r_smart_upcase_identifier "${ONESHOT_NAME}"
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

   sde::project::r_add_template_header_file "${ext}"
   headerfile="${RVAL}"

   sde::project::r_add_template_footer_file "${ext}"
   footerfile="${RVAL}"

   TEMPLATE_HEADER_FILE="${headerfile}"
   TEMPLATE_FOOTER_FILE="${footerfile}"
}


sde::project::export_oneshot_environment()
{
   log_entry "sde::project::export_oneshot_environment" "$@"

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
          ONESHOT_BASENAME \
          ONESHOT_PREFIXLESS_NAME \
          ONESHOT_PREFIXLESS_DOWNCASE_IDENTIFIER

#   export TEMPLATE_HEADER_FILE \
#          TEMPLATE_FOOTER_FILE
}


sde::project::export_name_environment()
{
   log_entry "sde::project::export_name_environment" "$@"

   [ -z "${PROJECT_IDENTIFIER}" ]          && _internal_fail "PROJECT_IDENTIFIER not set"
   [ -z "${PROJECT_DOWNCASE_IDENTIFIER}" ] && _internal_fail "PROJECT_DOWNCASE_IDENTIFIER not set"
   [ -z "${PROJECT_UPCASE_IDENTIFIER}" ]   && _internal_fail "PROJECT_UPCASE_IDENTIFIER not set"

   export PROJECT_NAME  \
          PROJECT_IDENTIFIER \
          PROJECT_DOWNCASE_IDENTIFIER \
          PROJECT_UPCASE_IDENTIFIER
}


sde::project::export_language_environment()
{
   log_entry "sde::project::export_language_environment" "$@"

   if [ -z "${PROJECT_LANGUAGE}" ]
   then
      return
   fi

   export PROJECT_LANGUAGE \
          PROJECT_UPCASE_LANGUAGE \
          PROJECT_DOWNCASE_LANGUAGE \
          PROJECT_DIALECT \
          PROJECT_UPCASE_DIALECT \
          PROJECT_DOWNCASE_DIALECT
}



sde::project::add_envscope_if_missing()
{
   log_entry "sde::project::add_envscope_if_missing" "$@"

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


sde::project::env_set_var()
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
                     set "${key}" "${value}" || _internal_fail "failed env set"
}


#
# we allow foo-xxx_a10 but not 0x/s!2
#
sde::project::assert_name()
{
   # check that PROJECT_NAME looks usable as an identifier
   case "$1" in
      *\ *)
         fail "Project name \"$1\" contains spaces"
      ;;

      ""|*[^a-zA-Z0-9_-]*|[^a-zA-Z_]*)
         fail "Project name \"$1\" must be an identifier (may have -)"
      ;;
   esac
}

# those affected by renames
sde::project::save_name_variables()
{
  log_entry "sde::project::save_name_variables" "$@"

  sde::project::assert_name "${PROJECT_NAME}"

  sde::project::env_set_var PROJECT_NAME        "${PROJECT_NAME}"  "$@"
#  sde::project::env_set_var PROJECT_IDENTIFIER  "${PROJECT_IDENTIFIER}" "$@"
}


#
# not saving case conversions here
#
sde::project::save_language_variables()
{
   log_entry "sde::project::save_language_variables" "$@"

   if [ ! -z "${PROJECT_LANGUAGE}" ]
   then
      sde::project::env_set_var PROJECT_LANGUAGE   "${PROJECT_LANGUAGE}"  "$@"
      sde::project::env_set_var PROJECT_DIALECT    "${PROJECT_DIALECT}" "$@"
      sde::project::env_set_var PROJECT_EXTENSIONS "${PROJECT_EXTENSIONS}" "$@"
   fi
}


sde::project::rename_old_to_new_filename()
{
   log_entry "sde::project::rename_old_to_new_filename" "$@"

   local filename="$1"
   local old="$2"
   local name="$3"

   local renamed

   renamed="${filename/${old}/${name}}"
   if [ "${filename}" != "${renamed}" ]
   then
      log_verbose "Rename \"${filename}\" to \"${renamed}\""
      exekutor mv -f "${filename}" "${renamed}" || exit 1
   fi
}


sde::project::_local_search_and_replace_filenames()
{
   log_entry "sde::project::_local_search_and_replace_filenames" "$@"

   local old="$1"
   local name="$2"

   local files

   files="`dir_list_files "." "*${old}*" "f" `"

   local filename

   .foreachline filename in ${files}
   .do
      sde::project::rename_old_to_new_filename "${filename}" "${old}" "${name}"
   .done
}


sde::project::search_and_replace_filenames()
{
   log_entry "sde::project::search_and_replace_filenames" "$@"

   local dir="$1"
   local old="$2"
   local name="$3"
   local type="$4"

   [ -z "${dir}" ]  && _internal_fail "dir is empty"
   [ -z "${old}" ]  && _internal_fail "old is empty"
   [ -z "${name}" ] && _internal_fail "name is empty"
   [ -z "${type}" ] && _internal_fail "type is empty"

   if [ ! -e "${dir}" ]
   then
      return
   fi

   local files

   files="`eval_rexekutor find "${dir}" -type "${type}" -name "*${old}*" -print `"

   local filename

   .foreachline filename in ${files}
   .do
      sde::project::rename_old_to_new_filename "${filename}" "${old}" "${name}"
   .done
}



###
###

sde::project::edit_old_to_new_content()
{
   log_entry "sde::project::edit_old_to_new_content" "$@"

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


sde::project::_local_search_and_replace_contents()
{
   log_entry "sde::project::_local_search_and_replace_contents" "$@"

   local grep_statement="$1"
   local sed_statement="$2"

   local files

   files="`dir_list_files "." "*" "f" `"

   local filename

   .foreachline filename in ${files}
   .do
      sde::project::edit_old_to_new_content "${filename}" \
                                            "${grep_statement}" \
                                            "${sed_statement}"
   .done
}


sde::project::search_and_replace_contents()
{
   log_entry "sde::project::search_and_replace_contents" "$@"

   local dir="$1" ; shift

   local grep_statement="$1"
   local sed_statement="$2"

   if [ ! -e "${dir}" ]
   then
      return
   fi

   local files

   files="`eval_rexekutor find "${dir}" -type f -print`"

   local filename

   .foreachfile filename in ${files}
   .do
      sde::project::edit_old_to_new_content "${filename}" \
                                            "${grep_statement}" \
                                            "${sed_statement}"
   .done
}


sde::project::walk_over_mulle_match_path()
{
   log_entry "sde::project::walk_over_mulle_match_path" "$@" "($MULLE_MATCH_PATH)"

   local callback="$1" ; shift

   local dir

   .foreachpath dir in ${MULLE_MATCH_PATH}
   .do
      case "${dir}" in
         .*)
         ;;

         *)
            "${callback}" "${dir}" "$@"
         ;;
      esac
   .done
}


sde::project::r_rename_current_project()
{
   log_entry "sde::project::r_rename_current_project" "$@"

   local newname="$1"

   local changes

   OLD_PROJECT_NAME="${PROJECT_NAME}"
   OLD_PROJECT_IDENTIFIER="${PROJECT_IDENTIFIER}"
   OLD_PROJECT_DOWNCASE_IDENTIFIER="${PROJECT_DOWNCASE_IDENTIFIER}"
   OLD_PROJECT_UPCASE_IDENTIFIER="${PROJECT_UPCASE_IDENTIFIER}"

   if [ -z "${OLD_PROJECT_IDENTIFIER}" ]
   then
      r_identifier "${OLD_PROJECT_NAME}"
      OLD_PROJECT_IDENTIFIER="${RVAL}"
   fi

   # used to be different so only do it on demand
   if [ -z "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" ]
   then
      include "case"

      r_smart_downcase_identifier "${OLD_PROJECT_IDENTIFIER}"
      OLD_PROJECT_DOWNCASE_IDENTIFIER="${RVAL}"
   fi
   if [ -z "${OLD_PROJECT_UPCASE_IDENTIFIER}" ]
   then
      include "case"

      r_smart_upcase_identifier "${OLD_PROJECT_IDENTIFIER}"
      OLD_PROJECT_UPCASE_IDENTIFIER="${RVAL}"
   fi

   unset PROJECT_UPCASE_IDENTIFIER
   unset PROJECT_DOWNCASE_IDENTIFIER
   unset PROJECT_IDENTIFIER

   if [ -z "${MULLE_SDE_PROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-project.sh" || _internal_fail "missing file"
   fi

   sde::project::set_name_variables "${newname}"
   if [ "${OPTION_SAVE_ENV}" != 'NO' ]
   then
      log_verbose "Changing Environment variables"

      sde::project::save_name_variables
      changes="${changes}changes"
   fi

   [ "${PROJECT_NAME}" != "${newname}" ] && _internal_fail "Did not set PROJECT_NAME"

   if [ "${OPTION_SEARCH_REPLACE_FILENAMES}" != 'NO' ]
   then
      log_verbose "Changing filenames"

      sde::project::_local_search_and_replace_filenames "${OLD_PROJECT_NAME}" "${PROJECT_NAME}"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_NAME}" "${PROJECT_NAME}" "f"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_NAME}" "${PROJECT_NAME}" "d"
      sde::project::search_and_replace_filenames .idea "${OLD_PROJECT_NAME}" "${PROJECT_NAME}" "f"

      sde::project::_local_search_and_replace_filenames "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}" "f"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}" "d"
      sde::project::search_and_replace_filenames .idea "${OLD_PROJECT_IDENTIFIER}" "${PROJECT_IDENTIFIER}" "f"

      sde::project::_local_search_and_replace_filenames "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}" "f"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}" "d"
      sde::project::search_and_replace_filenames .idea "${OLD_PROJECT_DOWNCASE_IDENTIFIER}" "${PROJECT_DOWNCASE_IDENTIFIER}" "f"

      sde::project::_local_search_and_replace_filenames "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}" "f"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_filenames "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}" "d"
      sde::project::search_and_replace_filenames .idea "${OLD_PROJECT_UPCASE_IDENTIFIER}" "${PROJECT_UPCASE_IDENTIFIER}" "f"

      changes="${changes}changes"
   fi

   if [ "${OPTION_SEARCH_REPLACE_CONTENTS}" != 'NO' ]
   then
      log_verbose "Changing file contents"

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
         sed_cmdline="${sed_cmdline} -e 's/${OLD_PROJECT_UPCASE_IDENTIFIER}/${PROJECT_UPCASE_IDENTIFIER}/g'"
      fi

      local grep_cmdline

      grep_cmdline="grep -q -s -n"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_NAME}'"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_IDENTIFIER}'"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_DOWNCASE_IDENTIFIER}'"
      grep_cmdline="${grep_cmdline} -e '${OLD_PROJECT_UPCASE_IDENTIFIER}'"

      sde::project::_local_search_and_replace_contents "${grep_cmdline}" "${sed_cmdline}"
      sde::project::walk_over_mulle_match_path sde::project::search_and_replace_contents "${grep_cmdline}" "${sed_cmdline}"
      sde::project::search_and_replace_contents .idea "${grep_cmdline}" "${sed_cmdline}"

      changes="${changes}changes"
   fi

   RVAL="${changes}"
}

#
# TODO: remove test and subprojects from renaming
#       rename them individually ?
#
sde::project::rename_main()
{
   log_entry "sde::project::rename_main" "$@"

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
            sde::project::rename_usage
         ;;

         --project-name)
            [ $# -eq 1 ] && sde::project::rename_usage "Missing argument to \"$1\""
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
            sde::project::rename_usage "Unknown option \"$1\""
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
      sde::project::rename_usage "Missing name argument"
   fi
   shift

   [ $# -ne 0 ] && sde::project::rename_usage "Superflous arguments \"$*\""

   case "${newname}" in
      *[^A-Za-z0-9_-]*)
         fail "Only identifier characters and - are allowed for project name"
      ;;
   esac

   if [ "${PROJECT_NAME}" = "${newname}" ]
   then
      fail "No change in name \"${newname}\" (${PWD#"${MULLE_USER_PWD}/"})"
   fi

   (
      sde::project::r_rename_current_project "${newname}"
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

      .foreachline testdir in ${test_path}
      .do
         (
            MULLE_VIRTUAL_ROOT=
            PROJECT_NAME=

            log_verbose "$testdir"

            rexekutor cd "${testdir}" && \
            exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                           project \
                              rename \
                                 ${cmdline} "${newname}"
         )
      .done
   fi

   log_verbose "Done"
}


sde::project::remove_main()
{
   log_entry "sde::project::remove_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::project::remove_usage
         ;;

         -*)
            sde::project::remove_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] || sde::project::remove_usage "Superflous arguments \$*\""

   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "MULLE_VIRTUAL_ROOT not set"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
   then
      fail "You need to use the -f flag for wiping the whole project"
   fi
   rmdir_safer "${MULLE_VIRTUAL_ROOT}"
}



sde::project::main()
{
   log_entry "sde::project::main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::project::usage
         ;;

         -*)
            sde::project::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   case "$1" in
      list)
         # shellcheck source=src/mulle-sde-list.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-list.sh"

         shift
         sde::list::main --no-files "$@"
      ;;

      rename)
         shift
         sde::project::rename_main "$@"
      ;;

      remove)
         shift
         sde::project::remove_main "$@"
      ;;

      variables)
         sde::project::set_name_variables "${PROJECT_NAME}"
         sde::project::set_language_variables "${PROJECT_LANGUAGE}"
         cat <<EOF
PROJECT_NAME="${PROJECT_NAME}"
PROJECT_IDENTIFIER="${PROJECT_IDENTIFIER}"
PROJECT_DOWNCASE_IDENTIFIER="${PROJECT_DOWNCASE_IDENTIFIER}"
PROJECT_UPCASE_IDENTIFIER="${PROJECT_UPCASE_IDENTIFIER}"
PROJECT_LANGUAGE="${PROJECT_LANGUAGE}"
PROJECT_DOWNCASE_LANGUAGE="${PROJECT_DOWNCASE_LANGUAGE}"
PROJECT_UPCASE_LANGUAGE="${PROJECT_UPCASE_LANGUAGE}"
PROJECT_DIALECT="${PROJECT_DIALECT}"
PROJECT_DOWNCASE_DIALECT="${PROJECT_DOWNCASE_DIALECT}"
PROJECT_UPCASE_DIALECT="${PROJECT_UPCASE_DIALECT}"
PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS}"
PROJECT_PREFIXLESS_NAME="${PROJECT_PREFIXLESS_NAME}"
PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER="${PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER}"
EOF
      ;;

      *)
         sde::project::usage "Unknown command \"$1\""
      ;;
   esac
}


sde::project::initialize()
{
   include "case"
   include "path"
   include "file"
}

sde::project::initialize

:

