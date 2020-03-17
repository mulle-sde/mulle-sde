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
sde_add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   FILE_USAGE_NAME="${FILE_USAGE_NAME:-${MULLE_USAGE_NAME} add}"

   COMMON_OPTIONS="\
   -d <dir>                : directory to populate (${PROJECT_SOURCE_DIR})
   -e <extension>          : oneshot extension to use
   --file-extension <name> : force file extension to name"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} add [options] <filepath>

   Add an existing file or create a file from a template. The add command
   can be executed without a virtual environment in place. Inside a mulle-sde
   project this command checks if your file can be reflected and will
   \`reflect\`.

   Create a "${MULLE_SDE_ETC_DIR#${MULLE_USER_PWD}/}/header.default" or
   "~/.mulle/etc/sde/header.default" file to prepend copyright information
   to your file. Change "default" to the desired file extension if you want
   to have different contents for different languages.

   Example:
         ${MULLE_USAGE_NAME} add src/MyClass.m

Options:
EOF
   (
      printf "%s\n" "${COMMON_OPTIONS}"
   ) | LC_ALL=C sort

   exit 1
}


sde_add_include()
{
   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || internal_fail "include fail"
   fi

   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || internal_fail "include fail"
   fi

   if [ -z "${MULLE_SDE_TEMPLATE_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-template.sh" || internal_fail "include fail"
   fi

   if [ -z "${MULLE_SDE_EXTENSION_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh" || internal_fail "include fail"
   fi

   if [ -z "${MULLE_SDE_INIT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh" || internal_fail "include fail"
   fi
}


r_add_template_header_footer_file()
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
   r_add_template_header_footer_file "$1" "header" "MULLE_SDE_FILE_HEADER"
}


r_add_template_footer_file()
{
   r_add_template_header_footer_file "$1" "footer" "MULLE_SDE_FILE_FOOTER"
}


_sde_add_oneshot_extension()
{
   log_entry "_sde_add_oneshot_extension" "$@"

   local filepath="$1"
   local extension="$2"
   local class="$3"
   local category="$4"

   local headerfile
   local ext

   ext="${filepath##*.}"

   r_add_template_header_file "${ext}"
   headerfile="${RVAL}"

   r_add_template_footer_file "${ext}"
   footerfile="${RVAL}"

   #
   # We use this hacky way, so we can add oneshot extensions without
   # the need for a project to exist already
   #
   (
      export ONESHOT_FILENAME="${filepath}"
      export ONESHOT_FILENAME_NO_EXT="${filepath%.*}"
      r_extensionless_basename "${ONESHOT_FILENAME}"
      export ONESHOT_NAME="${RVAL}"

      r_identifier "${ONESHOT_NAME}"
      export ONESHOT_IDENTIFIER="${RVAL}"
      r_lowercase "${ONESHOT_IDENTIFIER}"
      export ONESHOT_DOWNCASE_IDENTIFIER="${RVAL}"
      r_uppercase "${ONESHOT_IDENTIFIER}"
      export ONESHOT_UPCASE_IDENTIFIER="${RVAL}"

      r_basename "${ONESHOT_FILENAME}"
      export ONESHOT_BASENAME="${RVAL}"
      export ONESHOT_CLASS="${class}"
      export ONESHOT_CATEGORY="${category}"
      # hack!!
      export OPTION_TEMPLATE_HEADER_FILE="${headerfile}"
      export OPTION_TEMPLATE_FOOTER_FILE="${footerfile}"
      export VENDOR_NAME="${extension%%/*}"

      install_oneshot_extensions "${extension}"
   )
}


_sde_add_file_via_oneshot_extension()
{
   log_entry "_sde_add_file_via_oneshot_extension" "$@"

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
   IFS=$'\n'; set -f
   for vendor in ${vendors}
   do
      IFS=${DEFAULT_IFS}; set +f

      if sde_extension_find_main -q "${vendor}/${name}" "oneshot"
      then
         _sde_add_oneshot_extension "${filepath}" "${vendor}/${name}" "${class}" "${category}"
         return $?
      fi
   done
   IFS=${DEFAULT_IFS}; set +f

   if [ ! -z "${genericname}" -a "${genericname}" != "${name}" ]
   then
      #
      # fall back to non-specialized files
      #
      IFS=$'\n'; set -f
      for vendor in ${vendors}
      do
         IFS=${DEFAULT_IFS}; set +f

         if sde_extension_find_main -q "${vendor}/${genericname}" "oneshot"
         then
            _sde_add_oneshot_extension "${filepath}" "${vendor}/${genericname}" "${class}" "${category}"
            return $?
         fi
      done
      IFS=${DEFAULT_IFS}; set +f
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
_r_sde_get_class_category_genericname()
{
   log_entry "_r_sde_get_class_category_genericname" "$@"

   local filepath="$1"
   local name="$2"
   local extension="$3"

   _genericname="${name}"
   _category=""
   _class=""

   if [ ! -z "${name}" ]
   then
      RVAL="${name}"
      return
   fi

   if [ -z "${extension}" ]
   then
      r_path_extension "${filepath}"
      extension="${RVAL}"
      if [ -z "${extension}" ]
      then
         fail "Can not determine file type because of missing extension"
      fi
   fi

   local filename

   r_extensionless_basename "${filepath}"
   filename="${RVAL}"

   #
   # if file name is like +Foo or -private deal with it in a special way
   #
   case "${filename}" in
      *-*)
         r_lowercase "${filename}"
         name="file-${RVAL#*-}.${extension}"
         _genericname="file.${extension}"

         r_identifier "${filename#*-}"
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
         name="file.${extension}"

         r_identifier "${filename}"
         _class="${RVAL}"
         log_debug "Look for extensions named \"${name}\""
      ;;
   esac

   RVAL="${name}"
}


sde_add_file_via_oneshot_extension()
{
   log_entry "sde_add_file_via_oneshot_extension" "$@"

   local filepath="$1"
   local vendors="$2"
   local name="$3"
   local ext="$4"

   local _genericname
   local _category
   local _class

   _r_sde_get_class_category_genericname "${filepath}" "${name}" "${ext}"
   name="${RVAL}"

   _sde_add_file_via_oneshot_extension "${filepath}" \
                                       "${vendors}" \
                                       "${name}" \
                                       "${_class}" \
                                       "${_category}" \
                                       "${_genericname}"
}


sde_add_in_project()
{
   log_entry "sde_add_in_project" "$@"

   local filepath="$1"
   local vendors="$2"
   local name="$3"
   local ext="$4"

   if ! mulle-match match --quiet "${filepath}"
   then
      log_warning "\"${filepath}\" does not match any patternfiles"
   fi

   local  absfilepath

   absfilepath="${filepath}"
   if ! is_absolutepath "${filepath}"
   then
      r_filepath_concat "${MULLE_USER_PWD}" "${filepath}"
      absfilepath="${RVAL}"
   fi

   #
   # if it's there already just run update
   # TODO: check that extension is handled in patternfiles and optionally
   #       generate a new rule for it
   #
   if [ -e "${absfilepath}" ]
   then
      log_verbose "File already exists, just updating"
   else
      #
      # get currently installed runtime vendors, theses are the ones we
      # query for the file to produce, if none are given
      #
      if [ -z "${vendors}" ]
      then
         # it's not terrible if this fails though
         vendors="`sde_extension_main runtimes 2> /dev/null | cut -d'/' -f1,1 `"
      fi

      local rval

      sde_add_file_via_oneshot_extension "${absfilepath#${MULLE_USER_PWD}/}" \
                                         "${vendors}" \
                                         "${name}" \
                                         "${ext}"
      rval=$?
      case $rval in
         4)
            fail "No matching template found to create \"${absfilepath#${MULLE_USER_PWD}/}\""
         ;;

         0)
         ;;

         *)
            exit $rval
         ;;
      esac
   fi

   exekutor mulle-sde reflect || exit 1

   local found

   found="`rexekutor mulle-match list | fgrep -x "${filepath}" `"
   if [ -z "${found}" ]
   then
      log_warning "The file is not in a place to be found by the patternfiles"
      return
   fi

   log_info "Added \"${filepath#${MULLE_USER_PWD/}}\""
}


#
# It's sometimes nice to produce quick source files outside of a mulle-sde
# project. We facilitate this
#
sde_add_no_project()
{
   log_entry "sde_add_no_project" "$@"

   local filepath="$1"
   local vendors="$2"
   local name="$3"
   local ext="$4"

   if [ -e "${filepath}" ]
   then
      log_verbose "File already exists"
      return
   fi

   if [ -z "${vendors}" ]
   then
      vendors="`extension_list_vendors`" || exit 1
   fi

   # fake some variables to make it happen
   (
      r_extensionless_basename "${PWD}"
      export PROJECT_NAME="${RVAL}"
      export PROJECT_LANGUAGE="c"
      export PROJECT_DIALECT="objc"
      export TEMPLATE_NO_ENVIRONMENT="YES" # hacky

      sde_add_file_via_oneshot_extension "${filepath}" \
                                         "${vendors}" \
                                         "${name}" \
                                         "${ext}"

      rval=$?
      case $rval in
         4)
            fail "No matching template found to create \"${absfilepath#${MULLE_USER_PWD}/}\""
         ;;

         0)
         ;;

         *)
            exit $rval
         ;;
      esac
   ) || exit $?

   log_info "Created \"${filepath#${MULLE_USER_PWD/}}\""
}



###
### parameters and environment variables
###
sde_add_main()
{
   log_entry "sde_add_main" "$@"

   local OPTION_NAME
   local OPTION_VENDOR
   local OPTION_FILE_EXTENSION

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_add_usage
         ;;

         -fe|--file-extension)
            [ $# -eq 1 ] && sde_add_usage "Missing argument to \"$1\""
            shift

            OPTION_FILE_EXTENSION="$1"
         ;;

         -e|--extension)
            [ $# -eq 1 ] && sde_add_usage "Missing argument to \"$1\""
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
            [ $# -eq 1 ] && sde_add_usage "Missing argument to \"$1\""
            shift

            OPTION_NAME="$1"
         ;;

         # only used for one-shotting none project types
         --project-type)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            PROJECT_TYPE="$1"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_add_usage "Missing argument to \"$1\""
            shift

            r_add_line "${OPTION_VENDOR}" "$1"
            OPTION_VENDOR="${RVAL}"
         ;;

         -*)
            sde_add_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde_add_include

   [ $# -ne 1  ] && sde_add_usage

   if rexekutor mulle-sde -s status --clear --project
   then
      if [ -z "${MULLE_VIRTUAL_ROOT}" ]
      then
         exec_command_in_subshell add --vendor "${OPTION_VENDOR}" \
                                      --name "${OPTION_NAME}" \
                                      --file-extension "${OPTION_FILE_EXTENSION}" \
                                      "$@" || exit 1
      else
         sde_add_in_project "$1" "${OPTION_VENDOR}" "${OPTION_NAME}" "${OPTION_FILE_EXTENSION}"
      fi
   else
      sde_add_no_project "$1" "${OPTION_VENDOR}" "${OPTION_NAME}" "${OPTION_FILE_EXTENSION}"
   fi
}

