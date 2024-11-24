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
# Rebuild if files of certain files are modified
#
MULLE_SDE_ADD_SH='included'


sde::add::filetypes()
{
   local extensions

   extensions="`sde::extension::show_main "$@" --no-usage --all oneshot `"

   log_debug "extensions: ${extensions}"

   # remove craftinfo from list
   rexekutor sed -n -e 's|^mulle-sde/||' \
                    -e '/\.[a-z]*$/p' <<< "${extensions}" \
      | sort
}

#
# TODO: make it add src/foo.m
#
# Use the file extension to figure out which one-shot extension to use
# Use current language extensions as a starting point and drill down
# unless a vendor/extension has been specified.
#
# .m -> mulle-foundation/file_m
# .h -> mulle-foundation/file_h ??
#
sde::add::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   FILE_USAGE_NAME="${FILE_USAGE_NAME:-${MULLE_USAGE_NAME} add}"

   COMMON_OPTIONS="\
   -q                      : do not reflect and rebuild
   -e <extension>          : force file extension
   -o <vendor/extension>   : oneshot extension to use in vendor/extension form
   -t <type>               : type of file to create (file)"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} add [options] [file|url]

   Add an existing file or create a file from a template. If an URL is given,
   it is used to create a dependency instead. This is a convenience command
   that will \`reflect\` or \`craft\`, when it seems appropriate. For a
   dependency, this command will create a new project with \`init\`, if none
   exists so far.

   For file creation a type can specified. The default type is "file" for C
   and "class" for Objective-C. Filenames that contain a '+' look for a
   template of type "category" first, before falling back on type "file".

   Create a "${MULLE_SDE_ETC_DIR#"${MULLE_USER_PWD}/"}/header.default" or
   "~/.mulle/etc/sde/header.default" file to prepend copyright information
   to your file. Change "default" to the desired file extension if you want
   to have different contents for different languages.

   The add command can be executed without a virtual environment in place.
   Without an argument, you will be prompted for a file type and file name.

Examples:
      ${MULLE_USAGE_NAME} add src/foo.c
      ${MULLE_USAGE_NAME} add -t protocolclass src/MyProtocolClass.m
      ${MULLE_USAGE_NAME} add github:madler/zlib
      ${MULLE_USAGE_NAME} add -a src clib:clibs/ms

Options:
EOF
   (
      printf "%s\n" "${COMMON_OPTIONS}"
   ) | LC_ALL=C sort >&2


   echo >&2

   sde::add::filetypes >&2

   echo >&2

   exit 1
}


sde::add::include()
{
   include "path"
   include "file"
   include "sde::extension"
   include "sde::init"
}


sde::add::oneshot_extension()
{
   log_entry "sde::add::oneshot_extension" "$@"

   local filepath="$1"
   local extension="$2"
   local class="$3"
   local category="$4"

   if [ -z "${MULLE_SDE_PROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-project.sh" || _internal_fail "missing file"
   fi

   (
      OPTION_ADD='YES'

      sde::project::clear_oneshot_variables
      #
      # Use this hacky way, so we can add oneshot extensions without
      # the need for a project to exist already
      #
      sde::project::set_oneshot_variables "${filepath}" "${class}" "${category}"
      sde::project::export_oneshot_environment "${filepath}" "${class}" "${category}"

      export VENDOR_NAME="${extension%%/*}"

      sde::init::install_oneshot_extensions "${extension}"
   )
}


sde::add::_file_via_oneshot_extension()
{
   log_entry "sde::add::_file_via_oneshot_extension" "$@"

   local filepath="$1"
   local vendors="$2"
   local names="$3"
   local class="$4"
   local category="$5"
   local genericname="$6"

   local vendor
   local name
   #
   # now try to find a oneshot extension in our vendors list that fits
   #

   log_debug "Looking for direct name hit"

   .foreachpath name in ${names}
   .do
      .foreachline vendor in ${vendors}
      .do
         if sde::extension::find_main -q "${vendor}/${name}" "oneshot"
         then
            sde::add::oneshot_extension "${filepath}" \
                                       "${vendor}/${name}" \
                                       "${class}" \
                                       "${category}"
            return $?
         fi
      .done

      if [ ! -z "${genericname}" -a "${genericname}" != "${name}" ]
      then

         log_debug "Looking for non-specialized files"
         #
         # fall back to non-specialized files
         #
         .foreachline vendor in ${vendors}
         .do
            if sde::extension::find_main -q "${vendor}/${genericname}" "oneshot"
            then
               sde::add::oneshot_extension "${filepath}" \
                                           "${vendor}/${genericname}" \
                                           "${class}" \
                                           "${category}"
               return $?
            fi
         .done
      fi
   .done

   return 4  # not found
}


#
# Output produced:
#   name as RVAL (can be multiple separated by ':')
#   local _genericname
#   local _category
#   local _class
#
sde::add::r_get_class_category_genericname()
{
   log_entry "sde::add::r_get_class_category_genericname" "$@"

   local filepath="$1"
   local name="$2"
   local type="$3"
   local type_defaults="$4"
   local extension="$5"

   _genericname="${name}"
   _category=""
   _class=""

   if [ -z "${type}" -a ! -z "${name}" ]
   then
      RVAL="${name}"
      return
   fi

   if [ -z "${extension}" ]
   then
      r_path_extension "${filepath}"
      extension="${RVAL}"
   fi

   local filename

   r_extensionless_basename "${filepath}"
   filename="${RVAL}"

   if [ -z "${extension}" ]
   then
      log_verbose "Can not determine file type because of missing extension"
      RVAL="${name:-${filename}}"
      return
   fi

   log_setting "extension: ${extension}"
   log_setting "filename : ${filename}"
   log_setting "type     : ${type}"

   #
   # If user specified the type, lets use this
   #
   if [ ! -z "${type}" ]
   then
       r_identifier "${filename}"
       _class="${RVAL}"

      name="${type}.${extension}"
   else
      #
      # if file name is like +Foo or -private deal with it in a special way
      #
      _genericname="file.${extension}"

      case "${filename}" in
         *-*)
            r_lowercase "${filename}"
            name="file-${RVAL##*-}.${extension}"

            r_identifier "${filename%-*}"
            _class="${RVAL}"
         ;;

         *+*)
            name="category.${extension}"

            r_identifier "${filename%%+*}"
            _class="${RVAL}"
            r_identifier "${filename#*+}"
            _category="${RVAL}"
         ;;

         *)
            name=
            local type_default

            .foreachpath type_default in ${type_defaults}
            .do
               r_colon_concat "${name}" "${type_default}.${extension}"
               name="${RVAL}"
            .done

            r_identifier "${filename}"
            _class="${RVAL}"
         ;;
      esac
   fi
   name="${name:-${filename}}"
   if [ -z "${_genericname}" ]
   then
      log_debug "Look for extensions named \"${name}\""
   else
      log_debug "Look for extensions named \"${name}\" in addition to \"${_genericname}\""
   fi
   RVAL="${name}"
}


sde::add::file_via_oneshot_extension()
{
   log_entry "sde::add::file_via_oneshot_extension" "$@"

   local filename="$1"
   local vendors="$2"
   local name="$3"
   local type="$4"
   local type_defaults="$5"
   local ext="$6"

   local _genericname
   local _category
   local _class

   local names

   names="${name}"
   sde::add::r_get_class_category_genericname "${filename}"      \
                                              "${name}"          \
                                              "${type}"          \
                                              "${type_defaults}" \
                                              "${ext}"
   if [ -z "${names}" ]
   then
      names="${RVAL}"
   fi

   log_setting "filename:     ${filename}"
   log_setting "names:        ${names}"
   log_setting "class:        ${_class}"
   log_setting "category:     ${_category}"
   log_setting "genericname:  ${_genericname}"

   sde::add::_file_via_oneshot_extension "${filename}"     \
                                         "${vendors}"      \
                                         "${names}"        \
                                         "${_class}"       \
                                         "${_category}"    \
                                         "${_genericname}"
}


#
# filepath is relative
#
sde::add::in_project()
{
   log_entry "sde::add::in_project" "$@"

   local filename="$1"
   local vendors="$2"
   local name="$3"
   local type="$4"
   local type_defaults="$5"
   local ext="$6"

   if is_absolutepath "${filename}"
   then
      fail "filename \"${filename}\" must be relative"
   fi

   #
   # if it's there already just run update
   # TODO: check that extension is handled in patternfiles and optionally
   #       generate a new rule for it
   #
   if [ -e "${filename}" ]
   then
      log_verbose "File already exists"
   else
      local query_vendors
      #
      # get currently installed runtime vendors, theses are the ones we
      # query for the file to produce, if none are given
      #
      query_vendors="${vendors}"
      if [ -z "${vendors}" ]
      then
         # it's not terrible if this fails though
         query_vendors="`sde::extension::main runtimes 2> /dev/null | cut -d'/' -f1,1 `"
      fi

      local rval

      rval=4
      if [ ! -z "${query_vendors}" ]
      then
         sde::add::file_via_oneshot_extension "${filename}"      \
                                              "${query_vendors}" \
                                              "${name}"          \
                                              "${type}"          \
                                              "${type_defaults}" \
                                              "${ext}"
         rval=$?
         case $rval in
            4|0)
            ;;

            *)
               exit $rval
            ;;
         esac
      fi

      if [ $rval -eq 4 ]
      then
         # fallback to all
         query_vendors="`sde::extension::main vendors`"

         sde::add::file_via_oneshot_extension "${filename}"      \
                                              "${query_vendors}" \
                                              "${done_names}"    \
                                              "${type}"          \
                                              "${type_defaults}" \
                                              "${ext}"
         rval=$?
         case $rval in
            4)
               fail "No matching template \"${type:-${type_defaults}}\" found to create file \"${filename}\" with extension \"${ext}\""
            ;;

            0)
            ;;

            *)
               exit $rval
            ;;
         esac
      fi

      #
      # we don't check for actual file if its like NONE.m or something,
      # where an add command adds a predefined filename
      #
      r_extensionless_basename "${filename}"

      if [ ! -z "${RVAL}" -a "${RVAL}" != "NONE" ]
      then
         if [ -e "${filename}" ]
         then
            log_info "Added \"${filename}\""
         else
            log_warning "${filename} wasn't produced by the extension as expected"
            return 0
         fi
      fi
   fi

   # this warning fails on projects with subprojects
   local found

   found="`rexekutor mulle-match list | grep -F -x "${filename}"`"
   if [ -z "${found}" ]
   then
      r_filepath_concat "${PROJECT_SOURCE_DIR}" "${filename}"

      _log_warning "The new file \"${filename}\" will not be found by \`reflect\`.
${C_INFO}Tip: The PROJECT_SOURCE_DIR environment variable is ${C_RESET_BOLD}${PROJECT_SOURCE_DIR}.
${C_INFO}Maybe remove the generated file and try anew with:
${C_RESET_BOLD}   mulle-sde add \"${RVAL#"${MULLE_USER_PWD}/"}\""
      return
   fi

   exekutor mulle-sde reflect || exit 1
}


#
# It's sometimes nice to produce quick source files outside of a mulle-sde
# project. We facilitate this
#
sde::add::not_in_project()
{
   log_entry "sde::add::not_in_project" "$@"

   local filepath="$1"
   local vendors="$2"
   local names="$3"
   local type="$4"
   local ext="$5"

   if [ -e "${filepath}" ]
   then
      log_verbose "File already exists"
      return
   fi

   if [ -z "${vendors}" ]
   then
      vendors="`sde::extension::list_vendors`" || exit 1
   fi

   local directory
   local filename

   r_dirname "${filepath}"
   directory="${RVAL}"

   r_basename "${filepath}"
   filename="${RVAL}"

   mkdir_if_missing "${directory}"

   # fake some variables to make it happen
   (
      cd "${directory}" || fail "Could not enter \"${directory}\""

      r_extensionless_basename "${directory}"
      export PROJECT_NAME="${RVAL}"
      export PROJECT_LANGUAGE="c"
      export PROJECT_DIALECT="objc"
      export TEMPLATE_NO_ENVIRONMENT='YES' # hacky

      sde::add::file_via_oneshot_extension "${filename}" \
                                           "${vendors}" \
                                           "${names}" \
                                           "${type}" \
                                           "" \
                                           "${ext}"
      rval=$?
      case $rval in
         4)
            if [ -z "${ext}" ]
            then
               fail "No matching template found to create file \"${filepath#"${MULLE_USER_PWD}/"}\" (no extension)"
            else
              fail "No matching template found to create file \"${filepath#"${MULLE_USER_PWD}/"}\" with extension \"${ext}\""
           fi
         ;;

         0)
         ;;

         *)
            exit $rval
         ;;
      esac
   ) || exit $?

   log_info "Created \"${filepath#"${MULLE_USER_PWD}/"}\""
}


###
### parameters and environment variables
###
sde::add::main()
{
   log_entry "sde::add::main" "$@"

   # if we are in a project, but not really within yet, rexecute
   if [ -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      if rexekutor mulle-sde -s status --clear --project
      then
         sde::exec_command_in_subshell "mulle-sde" add "$@"
      fi
   fi

   local OPTION_ALMAGAMATED
   local OPTION_BUILD_TYPE="--release"
   local OPTION_DIRECTORY
   local OPTION_EMBEDDED
   local OPTION_EXTERNAL_COMMAND='YES'
   local OPTION_FILE_EXTENSION
   local OPTION_IS_URL='DEFAULT'
   local OPTION_NAME
   local OPTION_POST_INIT='YES'
   local OPTION_TYPE
   local OPTION_VENDOR

   # need includes for usage

   sde::add::include

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::add::usage
         ;;

         --debug|--release)
            OPTION_BUILD_TYPE="$1"
         ;;

         --amalgamated)
            OPTION_EMBEDDED='YES'
            OPTION_ALMAGAMATED='YES'
         ;;

         --embedded)
            OPTION_EMBEDDED='YES'
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_DIRECTORY="$1"
         ;;

         -t|--type)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_TYPE="$1"
         ;;

         -e|-fe|--file-extension)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_FILE_EXTENSION="$1"
         ;;

         -o|--oneshot-extension|--extension)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_NAME=
            OPTION_VENDOR=

            case "$1" in
               */*)
                  OPTION_VENDOR="${1%%/*}"
                  OPTION_NAME="${1##*/}"
               ;;

               *)
                  OPTION_VENDOR="$1"
               ;;
            esac
         ;;

         -n|--name)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_NAME="$1"
         ;;

         # only used for one-shotting none project types
         --project-type)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            PROJECT_TYPE="$1"
         ;;

         --project-dialect)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            PROJECT_DIALECT="$1"
         ;;

         -q|--quick)
            OPTION_QUICK='YES'
         ;;

         --is-url)
            OPTION_IS_URL='YES'
         ;;

         --no-is-url|--no-url|--is-no-url)
            OPTION_IS_URL='NO'
         ;;

         --no-post-init)
            OPTION_POST_INIT='NO'
         ;;

         --no-external-command)
            OPTION_EXTERNAL_COMMAND='NO'
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            r_add_line "${OPTION_VENDOR}" "$1"
            OPTION_VENDOR="${RVAL}"
         ;;

         -*)
            sde::add::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local filename

   if [ $# -eq 0 ]
   then
      local vendors
      local row

      vendors="`sde::add::filetypes --quiet`"
      rexekutor mudo -f mulle-menu --title "Choose file type:" \
                                   --final-title "${C_GREEN}File type:${C_RESET} " \
                                   --options "${vendors}"

      row=$?
      log_debug "row=${row}"

      r_line_at_index "${vendors}" $row
      [ -z "${RVAL}" ] && return 1
      OPTION_VENDOR="$RVAL"

      printf "${C_GREEN}File name:${C_RESET} "
      if ! read filename
      then
         return 1
      fi

      r_filepath_concat "${OPTION_DIRECTORY:-${PROJECT_SOURCE_DIR}}" "${filename}"
      filename="${RVAL}"

      OPTION_IS_URL='NO'
      set -- "${filename}"
   fi

   # empty string no good
   [ $# -eq 0 ] && sde::add::usage "Missing file to add"

   local has_run_init
   local filepath
   local scheme domain host user repo branch tag scm
   local flag

   if [ $# -eq 1 -a "${OPTION_EXTERNAL_COMMAND}" = 'YES' ]
   then
      include "sde::common"

      sde::common::update_git_if_needed "${HOME}/.mulle/share/craftinfo" \
                                        "${MULLE_SDE_CRAFTINFO_URL:-https://github.com/craftinfo/craftinfo.git}" \
                                        "${MULLE_SDE_CRAFTINFO_BRANCH}"

      sde::common::maybe_exec_external_command 'add' \
                                               "$1"  \
                                               "${HOME}/.mulle/share/craftinfo" \
                                               'YES'
      # if no external command happened, just continue
   fi

   for filename in "$@"
   do
      r_filepath_concat "${OPTION_DIRECTORY}" "${filename}"
      filename="${RVAL}"

      if [ "${OPTION_IS_URL}" = 'DEFAULT' ]
      then
         scm="git"
         r_basename "${filename}"
         repo="${RVAL}"

         case "${filename}" in
            *://*)
               OPTION_IS_URL='YES'
            ;;

            comment:*)
               scm="comment"
               filename="${filename#*:}"
               OPTION_IS_URL='YES'
            ;;

            *:*)
               eval `rexekutor mulle-domain parse-url "${filename}"`

               if [ ! -z "${user}" -a ! -z "${repo}" ]
               then
                  case "${domain}" in
                     clib)
                        r_filepath_concat "${user}" "${repo}"
                        filename="clib:${RVAL}"
                        scm="${domain}"
                        OPTION_EMBEDDED='YES'
                     ;;

                     *)
                        if [ ! -z "${host}" ]
                        then
                           filename="`mulle-domain compose-url --domain "${domain}" \
                                                               --scm "${scm}"       \
                                                               --host "${host}"     \
                                                               --user "${user}"     \
                                                               --repo "${repo}"  `"
                           # if somehow unprintable use original again
                           filename="${filename:-$1}"
                        fi
                     ;;
                  esac
               fi
               OPTION_IS_URL='YES'
            ;;
         esac
      fi

      #
      # check if destination is within our project, decide on where to go
      #
      if [ -z "${MULLE_VIRTUAL_ROOT}" ]
      then
         if [ "${OPTION_IS_URL}" != 'YES' ]
         then
            sde::add::not_in_project "${filename}"      \
                                     "${OPTION_VENDOR}" \
                                     "${OPTION_NAME}"   \
                                     "${OPTION_TYPE}"   \
                                     "${OPTION_FILE_EXTENSION}" || return $?

            continue
         fi

         # don't use post-init here, or otherwise we need to be able to allow
         # the user to turn it off, which complicates things and this is more
         # of a noob interface anyway
         local flags

         if [ "${OPTION_POST_INIT}" = 'NO' ]
         then
            flags=--no-post-init
         fi

         rexekutor "${MULLE_SDE:-mulle-sde}" \
                        ${MULLE_TECHNICAL_FLAGS} init ${flags}  \
                                                      -e sde    \
                                                      --no-demo \
                                                      --if-missing || return 1
         has_run_init='YES'
      fi

      if [ "${OPTION_IS_URL}" = 'YES' ]
      then
         if [ "${OPTION_EMBEDDED}" = 'YES' ]
         then
            # set flag
            [ "${OPTION_ALMAGAMATED}" = 'YES' ] \
               && flag="--amalgamated" \
               || flag="--embedded"

             rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS}      \
                        dependency add --scm "${scm}"          \
                                       --address "src/${repo}" \
                                       ${flag}                 \
                                       "${filename}" &&
            if [ "${OPTION_QUICK}" != 'YES' ]
            then
               if ! rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} fetch
               then
                  rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} -s \
                               dependency remove "src/${repo}"
                  return 1
               fi
               rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} reflect || return $?
               continue
            fi
         else
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} \
                         dependency add --scm "${scm}" "${filename}" &&
            if [ "${OPTION_QUICK}" != 'YES' ]
            then
               rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} reflect || return $?
               if sde::is_test_directory "$PWD"
               then
                  rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} test craft || return $?
               else
                  rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} craft ${OPTION_BUILD_TYPE} craftorder || return $?
               fi
            fi
         fi
         continue
      fi

      filepath="${filename}"
      if ! is_absolutepath "${filepath}"
      then
         r_filepath_concat "${MULLE_USER_PWD}" "${filename}"
         filepath="${RVAL}"
      fi

      # make comparable
      r_resolve_all_path_symlinks "${filepath}"
      filepath="${RVAL}"

      r_relative_path_between "${filepath}" "${MULLE_VIRTUAL_ROOT}"
      log_debug "${C_RED}${filepath} - ${MULLE_VIRTUAL_ROOT} = relative=${RVAL}"

      case "${RVAL}" in
         ../*)
            fail "File path \"${RVAL}\" escapes the project"
            return
         ;;
      esac

      local type_defaults

      if [ "${PROJECT_DIALECT}" = 'objc' ]
      then
         type_defaults="class:file"
      else
         type_defaults="file"
      fi

      if ! sde::add::in_project "${filepath#"${MULLE_VIRTUAL_ROOT}/"}" \
                                "${OPTION_VENDOR}"                     \
                                "${OPTION_NAME}"                       \
                                "${OPTION_TYPE}"                       \
                                "${type_defaults}"                     \
                                "${OPTION_FILE_EXTENSION}"
      then
         return 1
      fi
   done
}

