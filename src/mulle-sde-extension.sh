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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_EXTENSION_SH='included'


sde::extension::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension <command>

   Maintain mulle-sde extensions in your project after you ran mulle-sde init.
   Upgrade all extensions with separate \`mulle-sde upgrade\` command.

   Extra extensions that provide environment variables, need a scope
   "extension" to be present. This is setup by all "mulle" style projects, but
   may need manual setup with \`mulle-env scope add --share extension\`

Commands:
   add        : add an extra extension to your project
   find       : find extensions bases on vendor/name or type
   list       : list installed extensions
   meta       : print the installed meta extension
   pimp       : pimp up your your project with a one-shot extension
   freshen    : force adds extra extension, if already installed
   remove     : remove an extension from your project
   searchpath : show locations where extensions are searched
   show       : show available extensions
   usage      : show usage information for an extension
   vendors    : list installed vendors

EOF
   exit 1
}


sde::extension::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension [options] list

   List installed extensions.

Options:
   --no-version  : don't show version of the extensions

EOF
   exit 1
}


sde::extension::find_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension find [vendor/name] [type]

   Outputs the paths of matching extensions.

Options:
   --quiet              : just return a status

Environment:
   MULLE_SDE_EXTENSION_PATH      : Overrides searchpath for extensions
   MULLE_SDE_EXTENSION_BASE_PATH : Augments searchpath for extensions
EOF
   exit 1
}


sde::extension::show_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension show [options] [type]

   Shows the available mulle-sde extensions of types "meta" and "extra" by
   default. Those are usually the candidates to select.

Options:
   --version            : show version of the extensions
   --output-format raw  : show locations and type of extensions as CSV

Types:
   all       : list all available extensions
   buildtool : list available buildtool extensions
   extra     : list available extra extensions
   meta      : list available meta extensions
   oneshot   : list available oneshot extensions
   runtime   : list available runtime extensions


Environment:
   MULLE_SDE_EXTENSION_PATH      : Overrides searchpath for extensions
   MULLE_SDE_EXTENSION_BASE_PATH : Augments searchpath for extensions
EOF
   exit 1
}



sde::extension::add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension add <extension>

   Add an "extra" extension to your project. A project can have as many extra
   extensions as you like. A typical extra extension is "sublime-text",
   which adds a Sublime Text project file to your project.

   To clobber existing extension files use the -f flag:
      ${MULLE_USAGE_NAME} -f extension add idea


Note:
   To reconfigure your project with another runtime or buildtool, use
   \`mulle-sde init\` to setup anew.
   To add a "oneshot" extension use \`mulle-sde add\` not
   \`mulle-sde extension add\`.

EOF

   sde::extension::show_main extra >&2

   exit 1
}


sde::extension::freshen_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension freshen <extension>

   Freshen an "extra" extension to your project. This will overwrite all the
   installed files with new versions. Project files outside of 'share' folders
   are not overwritten during a \`mulle-sde upgrade\`. To get to newer files
   of an extension, use the freshen command. The freshen command will only
   work on already installed extensions.

EOF

   sde::extension::show_main extra >&2

   exit 1
}


sde::extension::remove_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension remove <extension>

   Remove an "extra" extension from the list of installed extension. This means
   the extension will not be upgraded anymore. The files and environment values
   placed into your project by the extension are not removed though.

EOF

   sde::extension::show_main extra >&2

   exit 1
}


sde::extension::pimp_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension pimp [options] <extension>

   Install a "oneshot" extension in your project. A oneshot extensions runs
   "once" and is not upgradable. You can run oneshot extensions as often as
   you want. Use the -f flag to clobber existing files, like so:

      mulle-sde -f extension pimp --oneshot-name Foo mulle-sde/craftinfo

Options:
   --oneshot-name <string> : pass a string to the extension

EOF
   exit 1
}


sde::extension::usage_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension usage [options] <extension>

   Show usage information (and more) of an extension.

Options:
   --list <type> : list installable project files by type
   --info        : list installable files for .mulle/share/sde
   --recurse     : show usage information of inherited extensions
EOF
   exit 1
}


#
# Though libexec can be found tied to the executable, it's kind
# of a fools errand to do the same with "share". At least if
# you want to avoid hardcoding in paths like /usr/local/share
# and I tried...
#
sde::extension::r_get_installdir()
{
   log_entry "sde::extension::r_get_installdir" "$@"

   local dev="${1:-YES}"

   local prefix

   r_dirname "$0"
   r_dirname "${RVAL}"
   prefix="${RVAL}"

   # are we a symlink ?
   if [ "${prefix}/libexec" != "${MULLE_SDE_LIBEXEC_DIR}" ]
   then
      # YES: this  is good
      r_simplified_path "${prefix}/share/mulle-sde/extensions"
      return
   fi

   #
   # not a symlink
   #
   if [ "${dev}" = 'YES' ]
   then
      case "${MULLE_SDE_LIBEXEC_DIR}" in
         */src)
            # stupid hack around for travis
            if [ -z "${MULLE_SDE_EXTENSION_BASE_PATH}" ]
            then
               RVAL="/tmp/share/mulle-sde/extensions"
               log_fluff "Developer environment uses ${RVAL}"
               return
            else
               log_fluff "MULLE_SDE_EXTENSION_BASE_PATH inhibits /tmp"
            fi
         ;;
      esac
   fi

   r_simplified_path "${prefix}/share/mulle-sde/extensions"
}


#
# An extension must be present at init time. Nothing from the project
# exists (there is nothing in MULLE_VIRTUAL_ROOT/dependencies)
#
# Find extensions in:
#
# ${HOME}/.config/mulle-sde/extensions/<vendor> (or elsewhere OS dependent)
# /usr/local/share/mulle_sde/extensions/<vendor> or whereever mulle-sde is
# installed
#
sde::extension::r_get_searchpath()
{
   log_entry "sde::extension::r_get_searchpath" "$@"

   log_setting "MULLE_SDE_EXTENSION_PATH=\"${MULLE_SDE_EXTENSION_PATH}\""
   log_setting "MULLE_SDE_EXTENSION_BASE_PATH=\"${MULLE_SDE_EXTENSION_BASE_PATH}\""

   #
   # allow environment to add more extensions, mostly useful for development
   # where you don't really want to reinstall extensions with every little
   # edit
   #
   if [ ! -z "${MULLE_SDE_EXTENSION_PATH}" ]
   then
      log_debug "Extension search path: \"${MULLE_SDE_EXTENSION_PATH}\""
      RVAL="${MULLE_SDE_EXTENSION_PATH}"
      return
   fi

   local homeprefdir

   case "${MULLE_UNAME}" in
      darwin)
         # or what ?
         homeprefdir="${HOME}/Library/Preferences"
      ;;

      *)
         homeprefdir="${HOME}/.config"
      ;;
   esac

   local s

   r_colon_concat "${MULLE_SDE_EXTENSION_BASE_PATH}" \
                  "${homeprefdir}/mulle-sde/extensions"
   s="${RVAL}"

   sde::extension::r_get_installdir
   r_colon_concat "${s}" "${RVAL}"
   s="${RVAL}"

   case "${MULLE_UNAME}" in
      linux|freebsd|windows)
         r_colon_concat "${s}" "/usr/share/mulle-sde/extensions"
         s="${RVAL}"
      ;;
   esac

   case "${MULLE_UNAME}" in
      darwin|linux|freebsd|windows)
         r_colon_concat "${s}" "/usr/local/share/mulle-sde/extensions"
         s="${RVAL}"
      ;;
   esac

   log_debug "Extension search path: \"${s}\""

   RVAL="${s}"
}


sde::extension::r_get_vendor_path()
{
   log_entry "sde::extension::r_get_vendor_path" "$@"

   local vendor="$1" # can not be empty

   [ -z "${vendor}" ] && fail "Empty vendor name"

   local searchpath

   sde::extension::r_get_searchpath
   searchpath="${RVAL}"

   RVAL=""

   local i

   .foreachpath i in ${searchpath}
   .do
      if [ -d "${i}/${vendor}" ]
      then
         log_debug "Vendor \"${vendor}\" found in \"${i}\""

         r_colon_concat "${RVAL}" "${i}"
      fi
   .done
}


sde::extension::r_get_vendor_dirs()
{
   log_entry "sde::extension::r_get_vendor_dirs" "$@"

   local vendor="$1"

   local vendorpath
   local i

   sde::extension::r_get_vendor_path "${vendor}"
   vendorpath="${RVAL}"

   RVAL=""

   .foreachpath i in ${vendorpath}
   .do
      r_colon_concat "${RVAL}" "${i}/${vendor}"
   .done
}


sde::extension::list_dirs_in_searchpath()
(
   log_entry "sde::extension::list_dirs_in_searchpath" "$@"

   local searchpath="$1"
   local pattern="$2"

   if [ -z "${searchpath}" ]
   then
      return 1
   fi

   local dir
   local escaped_dir

   case "${MULLE_UNAME}" in
      'sunos')
         .foreachpath dir in ${searchpath}
         .do
            if [ -d "${dir}" ]
            then
               r_escaped_sed_replacement "${dir}/"
               escaped_dir="${RVAL}"
               ( rexekutor cd "${dir}" && rexekutor ls -1d * ) \
               | rexekutor grep -E -v "\." \
               | rexekutor grep -E "^${pattern:-.*}\$" \
               | rexekutor sed "s/^/${escaped_dir}/"
            fi
         .done
         return
      ;;
   esac

   local cmdline

   cmdline="find -H"

   .foreachpath dir in ${searchpath}
   .do
      if [ -d "${dir}" ]
      then
         r_concat "${cmdline}" "'${dir}'"
         cmdline="${RVAL}"
      fi
   .done

   cmdline="${cmdline} -mindepth 1 -maxdepth 1"
   if [ ! -z "${pattern}" ]
   then
      cmdline="${cmdline} -name '${pattern}'"
   fi
      cmdline="${cmdline} '(' -type d -o -type l ')' -print"

   eval_rexekutor "${cmdline}"
)


sde::extension::_list_vendors()
{
   log_entry "sde::extension::_list_vendors" "$@"

   local searchpath
   local i

   sde::extension::r_get_searchpath
   searchpath="${RVAL}"

   sde::extension::list_dirs_in_searchpath "${searchpath}"
}


sde::extension::get_installed_version()
{
   log_entry "sde::extension::get_installed_version" "$@"

   local extension="$1"

   rexekutor cat "${MULLE_SDE_SHARE_DIR}/version/${extension}" 2> /dev/null
}


sde::extension::list_vendors()
{
   log_entry "sde::extension::list_vendors" "$@"

   # plugins vendor name is not allowed
   sde::extension::_list_vendors "$@" | LC_ALL=C sed -e s'|.*/||' | sed -e '/plugins/d' | LC_ALL=C sort -u
}


sde::extension::_list_vendor_extensions()
{
   log_entry "sde::extension::_list_vendor_extensions" "$@"

   local vendor="$1"

   local searchpath

   sde::extension::r_get_vendor_dirs "${vendor}"
   searchpath="${RVAL}"

   sde::extension::list_dirs_in_searchpath "${searchpath}"
}


sde::extension::list_vendor_extensions()
{
   log_entry "sde::extension::list_vendor_extensions" "$@"

   sde::extension::_list_vendor_extensions "$@" | LC_ALL=C sed -e s'|.*/||' | LC_ALL=C sort -u
}


sde::extension::r_find_in_searchpath()
{
   log_entry "sde::extension::r_find_in_searchpath" "$@"

   local vendor="$1"
   local name="$2"
   local searchpath="$3"

   case "${name}" in
      */*)
         _internal_fail "Inherit \"${name}\" was not correctly parsed"
      ;;

      *:*)
         fail "Inherit \"${name}\" is in obsolete <vendor>:<extension> format. \
Use / separator"
      ;;
   esac

   RVAL="`sde::extension::list_dirs_in_searchpath "${searchpath}" "${name}" | head -1`"

   if [ -z "${RVAL}" ]
   then
      log_fluff "Extension \"${vendor}/${name}\" is not there."
      return 1
   fi

   log_fluff "Found extension \"${RVAL}\""
}


sde::extension::r_find_get_vendor_searchpath()
{
   log_entry "sde::extension::r_find_get_vendor_searchpath" "$@"

   local vendor="$1"

   local searchpath

   sde::extension::r_get_vendor_dirs "${vendor}"
   searchpath="${RVAL}"

   if [ -z "${searchpath}" ]
   then
      log_fluff "Extension vendor \"${vendor}\" is unknown."
      RVAL=""
      return 1
   fi

   RVAL="${searchpath}"
}


sde::extension::r_find()
{
   log_entry "sde::extension::r_find" "$@"

   local vendor="$1"
   local name="$2"

   local searchpath

   if ! sde::extension::r_find_get_vendor_searchpath "${vendor}"
   then
      return 1
   fi

   searchpath="${RVAL}"

   sde::extension::r_find_in_searchpath "${vendor}" "${name}" "${searchpath}"
}


sde::extension::r_extensionnames_from_vendorextensions()
{
   log_entry "sde::extension::r_extensionnames_from_vendorextensions" "$@"

   local vendorextensions="$1"
   local extensiontype="$2"
   local vendor="$3"

   local line
   local result
   local foundtype
   local directory

   .foreachline line in ${vendorextensions}
   .do
      foundtype="${line#*;}"
      if [ -z "${extensiontype}" -o "${foundtype}" = "${extensiontype}" ]
      then
         directory="${line%%;*}"
         r_basename "${directory}"
         r_add_line "${result}" "${vendor}/${RVAL}"
         result="${RVAL}"
      fi
   .done

   RVAL="${result}"
}


sde::extension::r_collect_vendorextensions()
{
   log_entry "sde::extension::r_collect_vendorextensions" "$@"

   local vendor="$1"
   local searchname="$2"
   local searchtype="$3"

   local directory
   local searchpath
   local extensiondir
   local foundtype

   sde::extension::r_get_vendor_dirs "${vendor}"
   searchpath="${RVAL}"
   if [ -z "${searchpath}" ]
   then
      RVAL=""
      return 1
   fi

   log_fluff "Looking in \"${searchpath#"${MULLE_USER_PWD}/"}\" for \"${vendor}/${searchname}\" type \"${searchtype}\""

   local extensiondirs
   local vendorextensions

   extensiondirs="`sde::extension::list_dirs_in_searchpath "${searchpath}" `"
   .foreachline extensiondir in ${extensiondirs}
   .do
      foundtype="`LC_ALL=C grep -E -v '^#' "${extensiondir}/type" 2> /dev/null `"
      if [ -z "${foundtype}" ]
      then
         log_debug "\"${extensiondir}\" has no type information, skipped"
         .continue
      fi

      if [ ! -z "${searchtype}" -a "${searchtype}" != "${foundtype}" ]
      then
         log_debug "\"${extensiondir}\" type \"${foundtype}\" does not match \"${searchtype}\""
         .continue
      fi

      if [ ! -z "${searchname}" ]
      then
         r_basename "${extensiondir}"
         #r_extensionless_basename "${extensiondir}"
         if [ "${searchname}" != "${RVAL}" ]
         then
            log_debug "\"${extensiondir}\" name \"${RVAL}\" does not match \"${searchname}\""
            .continue
         fi
      fi

      r_add_line "${vendorextensions}" "${extensiondir};${foundtype}"
      vendorextensions="${RVAL}"
   .done

   RVAL="${vendorextensions}"
}


sde::extension::collect_projecttypes()
{
   log_entry "sde::extension::collect_projecttypes" "$@"

   local extensiondir="$1"

   (
      shell_enable_nullglob
      for i in "${extensiondir}/project/"*
      do
         if [ -d "$i" ]
         then
            basename -- "$i"
         fi
      done
   )
}


sde::extension::collect_inherits()
{
   log_entry "sde::extension::collect_inherits" "$@"

   local extensiondir="$1"

   local text

   if [ ! -f "${extensiondir}/inherit" ]
   then
      return
   fi

   text="`LC_ALL=C grep -E -v '^#' "${extensiondir}/inherit"`"

   log_debug "inherit: ${text}"

   local dependency
   local exttype

   while IFS=";" read -r dependency exttype
   do
      if [ -z "${dependency}" ]
      then
         continue
      fi

      printf "%s\n" "${dependency}"
   done <<< "${text}"
}


sde::extension::list_installed_vendors()
{
   log_entry "sde::extension::list_installed_vendors" "$@"

   if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
   then
      rexekutor cut -d/ -f1 "${MULLE_SDE_SHARE_DIR}/extension" | remove_duplicate_lines_stdin
   fi
}


sde::extension::vendors_main()
{
   log_entry "sde::extension::vendors_main" "$@"

   local OPTION_INSTALLED='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_vendors_usage
         ;;

         --installed)
            OPTION_INSTALLED='YES'
         ;;

         -*)
            sde_extension_vendors_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -gt 0 ] && sde_extension_vendors_usage "Superflous arguments \"$*\""

   if [ "${OPTION_INSTALLED}" = 'YES' ]
   then
      sde::extension::list_installed_vendors
   else
      sde::extension::list_vendors
   fi
}


sde::extension::find_main()
{
   log_entry "sde::extension::find_main" "$@"

   local OPTION_QUIET='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::extension::find_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            sde::extension::find_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -lt 1 ] && sde::extension::find_usage "Missing arguments"
   [ $# -gt 2 ] && sde::extension::find_usage "Superflous arguments \"$*\""

   local vendor
   local name

   case "$1" in
      */*)
         vendor="${1%%/*}"
         name="${1##*/}"
      ;;

      *)
         vendor="$1"
      ;;
   esac
   shift

   # this is optional
   local type

   type="$1"

   local extensions

   if [ ! -z "${vendor}" ]
   then
      sde::extension::r_collect_vendorextensions "${vendor}" "${name}" "${type}"
      extensions="${RVAL}"
   else
      local all_vendors

      all_vendors="`sde::extension::list_vendors`" || exit 1

      .foreachline vendor in ${all_vendors}
      .do
         sde::extension::r_collect_vendorextensions "${vendor}" "${name}" "${type}"
         r_add_line "${extensions}" "${RVAL}"
         extensions="${RVAL}"
      .done
   fi

   if [ -z "${extensions}" ]
   then
      log_debug "No matching extensions found"
      return 1
   fi

   if [ "${OPTION_QUIET}" = 'NO' ]
   then
      sed -e 's/;.*//' <<< "${extensions}"
   fi

   return 0
}


sde::extension::_get_usage()
{
   log_entry "sde::extension::_get_usage" "$@"

   local vendor="$1"
   local name="$2"

   local directory

   sde::extension::r_find "${vendor}" "${name}"
   directory="${RVAL}"

   [ -z "${directory}" ] && _internal_fail "invalid extension \"${vendor}/${result}\""

   local usagefile

   usagefile="${directory}/usage"

   if [ ! -f "${usagefile}" ]
   then
      log_debug "File \"${usagefile}\" is missing or unreadable"
      return 1
   fi

   LC_ALL=C grep -E -v '^#' < "${usagefile}"
}


sde::extension::get_usage()
{
   log_entry "sde::extension::get_usage" "$@"

   local extension="$1"

   sde::extension::_get_usage "${extension%%/*}" "${extension##*/}"
}


sde::extension::_get_version()
{
   log_entry "sde::extension::_get_version" "$@"

   local vendor="$1"
   local name="$2"

   local directory
   sde::extension::r_find "${vendor}" "${name}"
   directory="${RVAL}"

   [ -z "${directory}" ] && _internal_fail "invalid extension \"${vendor}/${result}\""

   local versionfile

   versionfile="${directory}/version"

   if [ ! -f "${versionfile}" ]
   then
      log_debug "File \"${versionfile}\" is missing or unreadable"
      log_warning "Extension \"${vendor}/${name}\" is unversioned and therefore not usable"
      return 1
   fi

   LC_ALL=C grep -E -v '^#' < "${versionfile}"
}


sde::extension::get_version()
{
   log_entry "sde::extension::get_version" "$@"

   local extension="$1"

   sde::extension::_get_version "${extension%%/*}" "${extension##*/}"
}


sde::extension::emit()
{
   log_entry "sde::extension::emit" "$@"

   local result="$1"
   local extensiontype="$2"
   local comment="$3"
   local with_version="$4"
   local with_usage="$5"

   if [ -z "${result}" ]
   then
      return
   fi

   local extension
   local version
   local output

   log_info "Available ${extensiontype} extensions ${comment}:"

   (
      lines="`remove_duplicate_lines "${result}" `"
      .foreachline extension in ${lines}
      .do
         output="${extension}"
         if [ "${with_version}" = 'YES' ]
         then
            version="`sde::extension::get_version "${extension}"`"
            r_concat "${output}" "${version}" ";"
            output="${RVAL}"
         fi

         if [ "${with_usage}" = 'YES' ]
         then
            usage="`sde::extension::get_usage "${extension}" | head -1`"
            r_concat "${output}" "${usage}" ";"
            output="${RVAL}"
         fi

         printf "%s\n" "${output}"
      .done
   ) | rexecute_column_table_or_cat ";"
}


sde::extension::show_main()
{
   log_entry "sde::extension::show_main" "$@"

   local OPTION_VERSION='NO'
   local OPTION_OUTPUT_RAW='NO'
   local OPTION_USAGE='YES'
   local OPTION_ALL='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::extension::show_usage
         ;;

         --usage)
            OPTION_USAGE='YES'
         ;;

         --no-usage)
            OPTION_USAGE='NO'
         ;;

         --version)
            OPTION_VERSION='YES'
         ;;

         --no-version)
            OPTION_VERSION='NO'
         ;;

         -a|--all)
            OPTION_ALL='YES'
         ;;

         --output-format)
            shift
            OPTION_OUTPUT_RAW='YES'
         ;;

         -*)
            sde::extension::show_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -gt 1 ] && sde::extension::show_usage "Superflous arguments \"$*\""

   local cmd

   cmd="$1"
   if [ -z "${cmd}" ]
   then
      if [ -z "${MULLE_VIRTUAL_ROOT}" -a ! -d .mulle ]
      then
         cmd="meta"
      else
         cmd="extra"
      fi
   fi

   local runtime_extension
   local buildtool_extension
   local meta_extension
   local extra_extension
   local oneshot_extension
   local vendor

   local all_vendors
   local installed_vendors
   local vendors

   case "${cmd}" in
      vendor|vendors)
         log_info "Available vendors"
         printf "%s\n" "`sde::extension::list_vendors`"
         return
      ;;
   esac

   if [ "${OPTION_ALL}" != 'YES' ]
   then
      vendors="`sde::extension::list_installed_vendors`"
   fi
   if [ -z "${vendors}" -o "${OPTION_ALL}" = 'YES' ]
   then
      vendors="`sde::extension::list_vendors`"
   fi

   if [ -z "${vendors}" ]
   then
      fail "No extension vendors found. Check the extension searchpath MULLE_SDE_EXTENSION_PATH."
   fi

   log_verbose "Vendors:"
   log_verbose "`LC_ALL=C sort -u <<< "${vendors}" | sed 's/^/  /' `"

   .foreachline vendor in ${vendors}
   .do
      if [ -z "${vendor}" ]
      then
         .continue
      fi

      local vendorextensions

      sde::extension::r_collect_vendorextensions "${vendor}"
      vendorextensions="${RVAL}"

      if [ -z "${vendorextensions}" ]
      then
         log_fluff "Vendor ${vendor} provides no extensions"
         .continue
      fi

      if [ "${OPTION_OUTPUT_RAW}" = 'YES' ]
      then
         if ! [ -z "${vendorextensions}" ]
         then
            printf "%s\n" "${vendorextensions}"
         fi
         .continue
      fi

      log_debug "Vendor ${C_RESET}${vendor}${C_DEBUG} extensions: ${vendorextensions}"

      case "${cmd}" in
         all|default|meta)
            sde::extension::r_extensionnames_from_vendorextensions "${vendorextensions}" "meta" "${vendor}"
            r_add_line "${meta_extension}" "${RVAL}"
            meta_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|default|extra)
            sde::extension::r_extensionnames_from_vendorextensions "${vendorextensions}" "extra" "${vendor}"
            r_add_line "${extra_extension}" "${RVAL}"
            extra_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|default|oneshot)
            sde::extension::r_extensionnames_from_vendorextensions "${vendorextensions}" "oneshot" "${vendor}"
            r_add_line "${oneshot_extension}" "${RVAL}"
            oneshot_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|runtime)
            sde::extension::r_extensionnames_from_vendorextensions "${vendorextensions}" "runtime" "${vendor}"
            r_add_line "${runtime_extension}" "${RVAL}"
            runtime_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|buildtool)
            sde::extension::r_extensionnames_from_vendorextensions "${vendorextensions}" "buildtool" "${vendor}"
            r_add_line "${buildtool_extension}" "${RVAL}"
            buildtool_extension="${RVAL}"
         ;;
      esac
   .done

   sde::extension::emit "${meta_extension}"      "meta" "[-m <extension>]"      "${OPTION_VERSION}" "${OPTION_USAGE}"
   sde::extension::emit "${runtime_extension}"   "runtime" "[-r <extension>]"   "${OPTION_VERSION}" "${OPTION_USAGE}"
   sde::extension::emit "${buildtool_extension}" "buildtool" "[-b <extension>]" "${OPTION_VERSION}" "${OPTION_USAGE}"
   sde::extension::emit "${extra_extension}"     "extra" "[-e <extension>]*"    "${OPTION_VERSION}" "${OPTION_USAGE}"
   sde::extension::emit "${oneshot_extension}"   "oneshot" "[-o <extension>]*"  "${OPTION_VERSION}" "${OPTION_USAGE}"

   :
}


sde::extension::list_main()
{
   log_entry "sde::extension::list_main" "$@"

   local OPTION_VERSION='YES'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::extension::list_usage
         ;;

         --version)
            OPTION_VERSION='YES'
         ;;

         --no-version)
            OPTION_VERSION='NO'
         ;;

         -*)
            sde::extension::list_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${MULLE_VIRTUAL_ROOT}" ] && fail "Listing installed extensions \
doesn't work outside of the mulle-sde environment"

   local version
   local vendor
   local extension
   local filename

   if [ ! -d "${MULLE_SDE_SHARE_DIR}/version" ]
   then
      if [ ! -d "${MULLE_SDE_SHARE_DIR}" ]
      then
         if [ -d "${MULLE_SDE_SHARE_DIR}.old" ]
         then
            fail "\"${PWD}\" looks like a borked extension upgrade"
         fi
         fail "\"${PWD}\" doesn't look like \
a mulle-sde project"
      fi
      log_warning "No extensions installed"
      return 0
   fi

   log_info "Installed Extensions"

   (
      filenames="`rexekutor find "${MULLE_SDE_SHARE_DIR}/version" -type f -print`"
      .foreachline filename in ${filenames}
      .do
         log_verbose "Found ${C_RESET_BOLD}${filename}"

         r_basename "${filename}"
         extension="${RVAL}"
         r_dirname "${filename}"
         vendor="${RVAL}"
         r_basename "${vendor}"
         vendor="${RVAL}"

         if [ "${OPTION_VERSION}" = 'YES' ]
         then
            version="`LC_ALL=C grep -E -v '^#' < "${filename}"`"
            printf "%s %s\n" "${vendor}/${extension}" "${version}"
         else
            printf "%s\n" "${vendor}/${extension}"
         fi
      .done
   ) | LC_ALL=C sort
}


sde::extension::collect_file_info()
{
   log_entry "sde::extension::collect_file_info" "$@"

   local extensiondirs="$1"
   local filename="$2"

   local directory

   .foreachline directory in ${extensiondirs}
   .do
      cat "${directory}/${filename}" 2> /dev/null
   .done
}


sde::extension::__set_vars()
{
   log_entry "sde::extension::__set_vars" "$@"

   vendor="${OPTION_VENDOR}"

   case "${extension}" in
      *:*)
         _internal_fail "obsolete extension format"
      ;;

      */*)
         vendor="${extension%%/*}"
         extension="${extension##*/}"
      ;;
   esac

   sde::extension::r_find "${vendor}" "${extension}" || fail "Unknown extension \"${vendor}/${extension}\""
   extensiondir="${RVAL}"

   inherits="`sde::extension::collect_inherits "${extensiondir}"`"
}


sde::extension::emit_list_types()
{
   local extensiondir="$1"
   local regexp="$2"

   local projectdir

   for projectdir in "${extensiondir}/project"/${regexp}
   do
      if [ ! -d "${projectdir}" ]
      then
         continue
      fi
#      local capitalized
#
#      capitalized="`tr a-z A-Z <<< "${OPTION_LIST:0:1}"`"
#      capitalized="${capitalized}${OPTION_LIST:1}"

      (
         cd "${projectdir}" || exit 1
         find ./ -print | sed -e '/^\.*$/d' -e 's|^./||'
      )
   done
}

sde::extension::emit_usage()
{
   log_entry "sde::extension::emit_usage" "$@"

   local extension="$1"

   local inherits
   local extensiondir
   local vendor

   sde::extension::__set_vars

   if [ "${OPTION_LIST_TYPES}" = 'YES' ]
   then
       sde::extension::collect_projecttypes "${extensiondir}"
       return
   fi

   local exttype

   exttype="`LC_ALL=C grep -E -v '^#' < "${extensiondir}/type"`"

   if [ "${OPTION_USAGE_ONLY}" != 'YES' ]
   then
      echo "Usage:"
      echo "   mulle-sde init --${exttype}" "${vendor}/${extension} <type>"
      echo
   fi

   local usagetext

   usagetext="`sde::extension::collect_file_info "${extensiondir}" "usage"`"

   if [ "${OPTION_USAGE_ONLY}" != 'YES' ]
   then
      if [ ! -z "${usagetext}" ]
      then
         sed 's/^/   /' <<< "${usagetext}"
         echo
      fi
   fi

   local inherit_text

   inherit_text="`sde::extension::collect_inherits "${extensiondir}"`"

   if [ ! -z "${inherit_text}" ]
   then
      local dependency

      dependencies="`sed 's/^\([^;]*\).*/\1/' <<< "${inherit_text}"`"
      .foreachline dependency in ${dependencies}
      .do
         mulle-sde extension usage --usage-only "${dependency}" | \
               sed -e 's/^   \[i\]//'g | \
               sed -e 's/^/   [i]/'
      .done

      echo
   fi

   if [ "${OPTION_USAGE_ONLY}" = 'YES' ]
   then
      if [ ! -z "${usagetext}" ]
      then
         sed 's/^/   /' <<< "${usagetext}"
      fi
      return
   fi

   local text

   text="`sde::extension::collect_projecttypes "${extensiondir}"`"
   text="${text:-all}"

   echo "Types:"
   sed 's/^/   /' <<< "${text}"
   echo

   text="`sde::extension::collect_inherits "${extensiondir}"`"
   text="${text:-none}"

   echo "Inherits:"
   text="${inherit_text:-none}"
   sed 's/^/   /' <<< "${text}"
   echo

   if [ "${OPTION_INFO}" = 'YES' ]
   then
      if [ -d "${extensiondir}/share/ignore.d" ]
      then
         echo "Ignore.d:"
         dir_list_files "${extensiondir}/share/ignore.d" "[0-9]*-*--*" \
         | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -d "${extensiondir}/share/match.d" ]
      then
         echo "Match.d:"
         dir_list_files "${extensiondir}/share/match.d" "[0-9]*-*--*" \
         | sed -e '/^[ ]*$/d' -e 's/^/   /'
      fi

      if [ -d "${extensiondir}/share/bin" ]
      then
         echo "Callbacks:"
         dir_list_files "${extensiondir}/share/bin" "*-callback" \
         | sed -e 's/-callback$//' \
         | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -d "${extensiondir}/share/libexec" ]
      then
         echo "Tasks:"
         dir_list_files "${extensiondir}/share/libexec" "*-task.sh" \
         | sed -e 's/-task\.sh//' \
         | sed -e '/^[ ]*$/d' -e 's/^/   /'
      fi

      if [ -f "${extensiondir}/dependency" ]
      then
         echo "Dependencies:"
         grep -E -v '^#' "${extensiondir}/dependency" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/library" ]
      then
         echo "Libraries:"
         grep -E -v '^#' "${extensiondir}/library" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/environment" ]
      then
         echo "Environment:"
         grep -E -v '^#' "${extensiondir}/environment" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/tool" ]
      then
         echo "Tools:"
         grep -E -v '^#' "${extensiondir}/tool" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/optionaltool" ]
      then
         echo "Optional Tools:"
         grep -E -v '^#' "${extensiondir}/optionaltool" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi
   fi

   if [ -z "${OPTION_LIST}" ]
   then
      return
   fi

   echo "Project Types:"
   sde::extension::emit_list_types "${extensiondir}" "${OPTION_LIST}" \
      | sed -e '/^[ ]*$/d' -e 's/^/   /'
   echo
}


sde::extension::do_usage()
{
   log_entry "sde::extension::do_usage" "$@"

   local extension="$1"

   if [ "${OPTION_RECURSE}" = 'YES' ]
   then
      local dependency

      local inherits
      local extensiondir
      local vendor

      sde::extension::__set_vars

      local dependencies

      dependencies="`sde::extension::collect_inherits "${extensiondir}"`"

      .foreachline dependency in ${dependencies}
      .do
         sde::extension::usage "${dependency}"
         if [ "${OPTION_LIST_TYPES}" = 'NO' ]
         then
            echo "------------------------------------------------------------"
            echo
         fi
      .done
   fi
   sde::extension::emit_usage "${extension}"
}


sde::extension::usage_main()
{
   log_entry "sde::extension::usage_main" "$@"

   local OPTION_VENDOR="mulle-sde"
   local OPTION_LIST=
   local OPTION_LIST_TYPES='NO'
   local OPTION_INFO='NO'
   local OPTION_RECURSE='NO'
   local OPTION_USAGE_ONLY='NO'
   local OPTION_NO_USAGE='NO'

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::extension::usage_usage
         ;;

         -i|--info)
            OPTION_INFO='YES'
         ;;

         -l|--list)
            [ $# -eq 1 ] && sde::extension::usage_usage "Missing argument to \"$1\""
            shift

            OPTION_LIST="$1"
         ;;

         -r|--recurse)
            OPTION_RECURSE='YES'
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde::extension::usage_usage "Missing argument to \"$1\""
            shift

            OPTION_VENDOR="$1"
         ;;

         --usage-only)
            OPTION_USAGE_ONLY='YES'
         ;;

         --list-types)
            OPTION_LIST_TYPES='YES'
         ;;

         -*)
            sde::extension::usage_usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local extension="$1"
   [ -z "${extension}" ] && sde::extension::usage_usage "missing extension name"
   shift

   [ "$#" -ne 0 ] && sde::extension::usage_usage "superflous arguments \"$*\""

   if [ "${OPTION_LIST_TYPES}" = 'YES' ]
   then
      sde::extension::do_usage "${extension}" | LC_ALL=C sort -u
   else
      sde::extension::do_usage "${extension}"
   fi
}


sde::extension::hack_option_and_single_quote_everything()
{
   log_entry "sde::extension::hack_option_and_single_quote_everything" "$@"

   local option="$1"; shift

   local i
   local last

   local first='YES'

   for i in "$@"
   do
      if [ "${first}" = 'NO' ]
      then
         echo "'${last}'"
      fi
      last="$i"
      first='NO'
   done

   printf "%s\n" "${option}"
   echo "'${last}'"
}


sde::extension::r_vendor_expanded_extensions()
{
   log_entry "sde::extension::r_vendor_expanded_extensions" "$@"

   local if_installed="${1:-NO}" ; shift

   local extension
   local args
   local installed_vendors
   local found

   installed_vendors="`sde::extension::list_installed_vendors`"

   for extension in "$@"
   do
      case "${extension}" in
         */*)
            if [ "${if_installed}" = 'YES' ]
            then
               if ! sde::extension::get_installed_version "${extension}" > /dev/null
               then
                  log_verbose "Skipping non-installed extension \"${extension}\""
                  continue
               fi
            fi
         ;;

         *)
            found='NO'

            # vendors aren't installed "hierarchically" though
            # so mulle-sde can be found before mulle-foundation (in theory)
            .foreachline installed in ${installed_vendors}
            .do
               if sde::extension::r_find "${installed}" "${extension}"
               then
                  if [ "${if_installed}" = 'YES' ]
                  then
                     if ! sde::extension::get_installed_version "${installed}/${extension}" > /dev/null
                     then
                        log_fluff "\"${installed}/${extension}\" not installed"
                        .continue
                     fi
                  fi

                  extension="${installed}/${extension}"
                  found='YES'
                  break
               else
                  log_fluff "\"${installed}/${extension}\" not found"
               fi
            .done

            if [ "${found}" = 'NO' ]
            then
               if [ "${if_installed}" = 'YES' ]
               then
                  log_verbose "Skipping non-installed extension \"${extension}\""
                  continue
               fi
               fail "You need to prefix extension \"${extension}\" with a vendor"
            fi
         ;;
      esac


      log_info "Selecting \"${extension}\""
      r_add_line "${args}" "${extension}"
      args="${RVAL}"
   done

   RVAL="${args}"
}


sde::extension::add_main()
{
   log_entry "sde::extension::add_main" "$@"

   local args

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::extension::add_usage
         ;;

         --reflect|--no-reflect)
             "${args}" "1"
            args="${RVAL}"
         ;;

         -*)
            sde::extension::add_usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_SDE_INIT_SH}" ]
   then
      # shellcheck source=src/mulle-sde-init.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh" || exit 1
   fi

   local expanded_extensions

   sde::extension::r_vendor_expanded_extensions 'NO' "$@"
   expanded_extensions="${RVAL}"

   r_add_line "${args}" "${expanded_extensions}"
   args="${RVAL}"

   args="`sde::extension::hack_option_and_single_quote_everything "--extra" $args | tr '\012' ' '`"

   # --add must be very first option
   INIT_USAGE_NAME="${MULLE_USAGE_NAME} extension add" \
      eval sde::init::main --add --no-clean --no-blurb --no-env "${args}"
}


sde::extension::freshen_main()
{
   log_entry "sde::extension::freshen_main" "$@"

   local args

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::extension::freshen_usage
         ;;

         --reflect|--no-reflect)
            r_add_line "${args}" "1"
            args="${RVAL}"
         ;;

         -*)
            sde::extension::freshen_usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "sde::init"

   local expanded_extensions

   sde::extension::r_vendor_expanded_extensions 'YES' "$@"
   expanded_extensions="${RVAL}"

   r_add_line "${args}" "${expanded_extensions}"
   args="${RVAL}"
   if [ -z "${args}" ]
   then
      log_info "Nothing to freshen"
      return 0
   fi

   args="`sde::extension::hack_option_and_single_quote_everything "--extra" $args | tr '\012' ' '`"

   # environment variable likely to be lost.. check this
   INIT_USAGE_NAME="${MULLE_USAGE_NAME} extension freshen" \
      eval sde::init::main --add -f --no-blurb --no-env "${args}"
}



sde::extension::r_sane_vendor_name()
{
   # works in bash 3.2
   RVAL="${1//[^a-zA-Z0-9-]/_}"
}


sde::extension::remove_main()
{
   log_entry "sde::extension::remove_main" "$@"

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::extension::remove_usage
         ;;

         -*)
            sde::extension::remove_usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "file"

   local extension
   local installed
   local changed
   local matches

   if [ ! -f "${MULLE_SDE_SHARE_DIR}/extension" ]
   then
      log_verbose "No extensions are installed"
      return 0
   fi

   installed="`rexekutor cat "${MULLE_SDE_SHARE_DIR}/extension"`"
   changed="${installed}"
   removed=""

   local vendor
   local name

   for extension in "$@"
   do
      case "${extension}" in
         */*)
            vendor="${extension%%/*}"
            name="${extension##*/}"
         ;;

         *)
            vendor=""
            name="${extension}"
         ;;
      esac

      # paranoia of user input breaking  grep -E
      vendor="${vendor//[^a-zA-Z0-9-]/_}"
      name="${name//[^a-zA-Z0-9-]/_}"

      matches="`rexekutor grep -E -x "${vendor:-.*}/${name:-.*};extra" <<< "${changed}"`"
      r_add_line "${removed}" "${matches}"
      removed="${RVAL}"
      if [ ! -z "${matches}" ]
      then
         changed="`rexekutor grep -E -v -x "${vendor:-.*}/${name:-.*};extra" <<< "${changed}"`"
      else
         log_warning "Did not find extra extension ${extension}"
      fi
   done

   if [ -z "${removed}" ]
   then
      log_info "Nothing found to remove"
      return
   fi

   # remove from list of extensions
   exekutor find "${MULLE_SDE_SHARE_DIR}" -type f -exec chmod +w {} \;

   redirect_exekutor "${MULLE_SDE_SHARE_DIR}/extension" echo "${changed}" &&

   # remove from installed versions
   local line

   IFS=$'\n'; shell_disable_glob
   for line in ${removed}
   do
      line="${line%%;*}"
      vendor="${line%%/*}"
      name="${line##*/}"

      remove_file_if_present "${MULLE_SDE_SHARE_DIR}/version/${vendor}/${name}"
      rmdir_if_empty "${MULLE_SDE_SHARE_DIR}/version/${vendor}"
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   rmdir_if_empty "${MULLE_SDE_SHARE_DIR}/version"

   exekutor find "${MULLE_SDE_SHARE_DIR}" -type f -exec chmod a-w {} \;
}



###
### parameters and environment variables
###
sde::extension::main()
{
   log_entry "sde::extension::main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::extension::usage
         ;;

         -*)
            sde::extension::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde::extension::usage

   local cmd="$1"
   shift

   local OPTION_DEFINES

   case "$1" in
      -h|--help|help)
         if shell_is_function "sde::extension::${cmd}_usage"
         then
            sde::extension::${cmd}_usage
         else
            sde::extension::usage
         fi
      ;;
   esac

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
   fi

   if [ ! -z "${MULLE_SDE_EXTENSION_PATH}" -a ! -z "${MULLE_SDE_EXTENSION_BASE_PATH}" ]
   then
      log_warning "MULLE_SDE_EXTENSION_BASE_PATH is ignored due to MULLE_SDE_EXTENSION_PATH being set"
   fi

   case "${cmd}" in
      add|remove|freshen)
         [ $# -eq 0 ] && sde_extension_${cmd}_usage

         sde::extension::${cmd}_main "$@"
      ;;

      pimp)
         [ $# -eq 0 ] && sde::extension::pimp_usage

         # shellcheck source=src/mulle-sde-init.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

         local args

         args="`sde::extension::hack_option_and_single_quote_everything "--oneshot" "$@" | tr '\012' ' '`"

         INIT_USAGE_NAME="${MULLE_USAGE_NAME} extension add" \
            eval sde::init::main --add --no-blurb --no-env ${args}
      ;;

      find|show|usage|vendors)
         sde::extension::${cmd}_main "$@"
      ;;

      list)
         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            sde::exec_command_in_subshell "CD" extension ${cmd} "$@"
         fi

         sde::extension::${cmd}_main "$@"
      ;;

      meta|runtime|buildtool)
         local extension

         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exekutor exec mulle-sde run mulle-sde extension "${cmd}"
         fi

         if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
         then
            extension="`grep -E -e ";${cmd}\$" "${MULLE_SDE_SHARE_DIR}/extension" | head -1 | cut -d';' -f 1`"
         fi

         if [ -z "${extension}" ]
         then
            log_warning "Could not figure out installed \"${cmd}\" extension"
            return 1
         fi
         printf "%s\n" "${extension}"
      ;;

      metas|runtimes|buildtools)
         local extensions

         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exekutor exec mulle-sde run mulle-sde extension "${cmd}"
         fi

         [ ! -z "${MULLE_SDE_SHARE_DIR}" ] || _internal_fail "MULLE_SDE_SHARE_DIR undefined"

         if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
         then
            extensions="`rexekutor grep -E -e ";${cmd%s}\$" "${MULLE_SDE_SHARE_DIR}/extension" | cut -d';' -f 1`"
         fi

         if [ -z "${extensions}" ]
         then
            log_warning "Could not figure out installed \"${cmd%s}\" extensions"
            return 1
         fi
         printf "%s\n" "${extensions}"
      ;;

      searchpath)
         log_info "Extension searchpath"

         sde::extension::r_get_searchpath
         printf "%s\n" "${RVAL}"
      ;;

      vendorpath)
         [ $# -eq 0 ] && sde::extension::usage "Missing vendor argument"

         log_info "Extension vendor path"
               sde::extension::r_get_vendor_path "$1"

         printf "%s\n" "${RVAL}"
      ;;

      "")
         sde::extension::usage
      ;;

      *)
         sde::extension::usage "unknown command \"${cmd}\""
      ;;
   esac
}

