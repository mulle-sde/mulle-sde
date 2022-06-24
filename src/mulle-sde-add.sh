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
# Rebuild if files of certain files are modified
#
MULLE_SDE_ADD_SH="included"


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
   -o <extension>          : oneshot extension to use in vendor/extension form
   -t <type>               : type of file to create (file)
   --file-extension <name> : force file extension"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} add [options] <filepath>

   Add an existing file or create a file from a template. The add command
   can be executed without a virtual environment in place. Inside a mulle-sde
   project this command checks if your file can be reflected and will
   \`reflect\`.

   The default type is "file" for C and "class" for Objective-C. Filenames
   that contain a '+' look for a template of type "category" first, before
   falling back on type "file".

   Create a "${MULLE_SDE_ETC_DIR#${MULLE_USER_PWD}/}/header.default" or
   "~/.mulle/etc/sde/header.default" file to prepend copyright information
   to your file. Change "default" to the desired file extension if you want
   to have different contents for different languages.

   Example:
         ${MULLE_USAGE_NAME} add -t protocolclass src/MyProtocolClass.m

Options:
EOF
   (
      printf "%s\n" "${COMMON_OPTIONS}"
   ) | LC_ALL=C sort >&2


   echo >&2

   sde::extension::show_main --all oneshot \
      | sed -n -e 's|^mulle-sde/||' -e '/\.[a-z]*$/p' \
      | sort >&2

   exit 1
}


sde::add::include()
{
   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || _internal_fail "include fail"
   fi

   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || _internal_fail "include fail"
   fi

   if [ -z "${MULLE_SDE_EXTENSION_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh" || _internal_fail "include fail"
   fi

   if [ -z "${MULLE_SDE_INIT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh" || _internal_fail "include fail"
   fi
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
   local name="$3"
   local class="$4"
   local category="$5"
   local genericname="$6"

   local vendor

   #
   # now try to find a oneshot extension in our vendors list that fits
   #

   log_debug "Looking for direct name hit"
   shell_disable_glob; IFS=$'\n'
   for vendor in ${vendors}
   do
      shell_enable_glob; IFS="${DEFAULT_IFS}"

      if sde::extension::find_main -q "${vendor}/${name}" "oneshot"
      then
         sde::add::oneshot_extension "${filepath}" \
                                    "${vendor}/${name}" \
                                    "${class}" \
                                    "${category}"
         return $?
      fi
   done
   shell_enable_glob; IFS="${DEFAULT_IFS}"

   if [ ! -z "${genericname}" -a "${genericname}" != "${name}" ]
   then

      log_debug "Looking for non-specialized files"
      #
      # fall back to non-specialized files
      #
      shell_disable_glob; IFS=$'\n'
      for vendor in ${vendors}
      do
         shell_enable_glob; IFS="${DEFAULT_IFS}"

         if sde::extension::find_main -q "${vendor}/${genericname}" "oneshot"
         then
            sde::add::oneshot_extension "${filepath}" \
                                       "${vendor}/${genericname}" \
                                       "${class}" \
                                       "${category}"
            return $?
         fi
      done
      shell_enable_glob; IFS="${DEFAULT_IFS}"
   fi

   return 4  # not found
}


#
# Output produced:
#   name as RVAL
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
   local type_default="$4"
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

   #
   # If user specified the type, lets use this
   #
   if [ ! -z "${type}" ]
   then
       r_identifier "${filename}"
       _class="${RVAL}"

      name="${type}.${extension}"
      log_debug "Look for extensions named \"${name}\""
   else
      #
      # if file name is like +Foo or -private deal with it in a special way
      #
      case "${filename}" in
         *-*)
            r_lowercase "${filename}"
            name="file-${RVAL##*-}.${extension}"
            _genericname="file.${extension}"

            r_identifier "${filename%-*}"
            _class="${RVAL}"
            log_debug "Look for extensions named \"${name}\" in addition to \"${_genericname}\""
         ;;

         *+*)
            name="category.${extension}"
            _genericname="file.${extension}"

            r_identifier "${filename%%+*}"
            _class="${RVAL}"
            r_identifier "${filename#*+}"
            _category="${RVAL}"
            log_debug "Look for extensions named \"${name}\" in addition to \"${_genericname}\""
         ;;

         *)
            name="${type_default}.${extension}"

            r_identifier "${filename}"
            _class="${RVAL}"
            log_debug "Look for extensions named \"${name}\""
         ;;
      esac
   fi
   RVAL="${name:-${filename}}"
}


sde::add::file_via_oneshot_extension()
{
   log_entry "sde::add::file_via_oneshot_extension" "$@"

   local filename="$1"
   local vendors="$2"
   local name="$3"
   local type="$4"
   local type_default="$5"
   local ext="$6"

   local _genericname
   local _category
   local _class

   sde::add::r_get_class_category_genericname "${filename}" \
                                              "${name}" \
                                              "${type}" \
                                              "${type_default}" \
                                              "${ext}"
   if [ -z "${name}" ]
   then
      name="${RVAL}"
   fi

   log_setting "filename:     ${filename}"
   log_setting "name:         ${name}"
   log_setting "class:        ${_class}"
   log_setting "category:     ${_category}"
   log_setting "genericname:  ${_genericname}"

   sde::add::_file_via_oneshot_extension "${filename}" \
                                         "${vendors}" \
                                         "${name}" \
                                         "${_class}" \
                                         "${_category}" \
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
   local type_default="$5"
   local ext="$6"
   local all="$7"

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
      #
      # get currently installed runtime vendors, theses are the ones we
      # query for the file to produce, if none are given
      #
      if [ -z "${vendors}" -a "${all}" = 'NO' ]
      then
         # it's not terrible if this fails though
         vendors="`sde::extension::main runtimes 2> /dev/null | cut -d'/' -f1,1 `"
      fi

      # otherwise fallback to
      if [ -z "${vendors}" ]
      then
         vendors="`sde::extension::main vendors`"
      fi

      local rval

      sde::add::file_via_oneshot_extension "${filename}" \
                                         "${vendors}" \
                                         "${name}" \
                                         "${type}" \
                                         "${type_default}" \
                                         "${ext}"
      rval=$?
      case $rval in
         4)
            fail "No matching template \"${type:-${type_default}}\" found to create file \"${filename}\""
         ;;

         0)
         ;;

         *)
            exit $rval
         ;;
      esac

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

   found="`rexekutor mulle-match list | fgrep -x "${filename}"`"
   if [ -z "${found}" ]
   then
      r_filepath_concat "${PROJECT_SOURCE_DIR}" "${filename}"

      _log_warning "The new file \"${filename}\" will not be found by \`reflect\`.
${C_INFO}Tip: The PROJECT_SOURCE_DIR environment variable is ${C_RESET_BOLD}${PROJECT_SOURCE_DIR}.
${C_INFO}Maybe remove the generated file and try anew with:
${C_RESET_BOLD}mulle-sde add \"${RVAL#${MULLE_USER_PWD}/}\""
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
   local name="$3"
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
      export TEMPLATE_NO_ENVIRONMENT="YES" # hacky


      sde::add::file_via_oneshot_extension "${filename}" \
                                           "${vendors}" \
                                           "${name}" \
                                           "${type}" \
                                           "${type_default}" \
                                           "${ext}"

      rval=$?
      case $rval in
         4)
            fail "No matching template found to create file \"${filepath#${MULLE_USER_PWD}/}\""
         ;;

         0)
         ;;

         *)
            exit $rval
         ;;
      esac
   ) || exit $?

   log_info "Created \"${filepath#${MULLE_USER_PWD}/}\""
}



###
### parameters and environment variables
###
sde::add::main()
{
   log_entry "sde::add::main" "$@"

   # if we are in a project, but not not really within yet, rexecute
   if [ -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      if rexekutor mulle-sde -s status --clear --project
      then
         sde::exec_command_in_subshell add "$@"
      fi
   fi

   local OPTION_NAME
   local OPTION_VENDOR
   local OPTION_ALL_VENDORS='NO'
   local OPTION_FILE_EXTENSION
   local OPTION_TYPE
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

         -a|--all-vendors)
            OPTION_ALL_VENDORS='YES'
         ;;

         -t|--type)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_TYPE="$1"
         ;;

         -fe|--file-extension)
            [ $# -eq 1 ] && sde::add::usage "Missing argument to \"$1\""
            shift

            OPTION_FILE_EXTENSION="$1"
         ;;

         -o|--oneshot-extension|-e|--extension)
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

   [ $# -ne 1  ] && sde::add::usage


   local filename

   filename="$1"

   local type_default

   if [ "${PROJECT_DIALECT}" = 'objc' ]
   then
      type_default="class"
   else
      type_default="file"
   fi

   #
   # check if destination is within our project, decide on where to go
   #
   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
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
         ;;

         *)
            sde::add::in_project "${filepath#${MULLE_VIRTUAL_ROOT}/}" \
                                 "${OPTION_VENDOR}" \
                                 "${OPTION_NAME}" \
                                 "${OPTION_TYPE}" \
                                 "${type_default}" \
                                 "${OPTION_FILE_EXTENSION}" \
                                 "${OPTION_ALL_VENDORS}"
            return $?
         ;;
      esac
   fi

   sde::add::not_in_project "${filename}" \
                            "${OPTION_VENDOR}" \
                            "${OPTION_NAME}" \
                            "${OPTION_TYPE}" \
                            "${OPTION_FILE_EXTENSION}"
}

