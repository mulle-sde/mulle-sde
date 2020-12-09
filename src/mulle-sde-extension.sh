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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_EXTENSION_SH="included"


sde_extension_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension <command>

   Maintain mulle-sde extensions in your project after you ran
   mulle-sde init. Upgrade all extensions with separate
   \`mulle-sde upgrade\` command.

Commands:
   add        : add an extra extension to your project
   find       : find extensions bases on vendor/name or type
   list       : list installed extensions
   meta       : print the installed meta extension
   pimp       : pimp up your your project with a one-shot extension
   remove     : remove an extension from your project
   searchpath : show locations where extensions are searched
   show       : show available extensions
   usage      : show usage information for an extension
   vendors    : list installed vendors
EOF
   exit 1
}


sde_extension_list_usage()
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


sde_extension_find_usage()
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


sde_extension_show_usage()
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



sde_extension_add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension add <extension>

   Add an "extra" extension to your project.
   To reconfigure your project with another runtime or buildtool, use
   \`${MULLE_USAGE_NAME} init\` to setup anew.

EOF

   sde_extension_show_main extra >&2

   exit 1
}


sde_extension_remove_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension remove <extension>

   Remove an "extra" extension from the list of installed extension. This means
   the extension will not be upgraded anymore. The files and environment values
   placed into your project by the extension are not removed though.

EOF

   sde_extension_show_main extra >&2

   exit 1
}



sde_extension_pimp_usage()
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


sde_extension_usage_usage()
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
r_extension_get_installdir()
{
   log_entry "r_extension_get_installdir" "$@"

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
r_extension_get_searchpath()
{
   log_entry "r_extension_get_searchpath" "$@"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "MULLE_SDE_EXTENSION_PATH=\"${MULLE_SDE_EXTENSION_PATH}\""
      log_trace2 "MULLE_SDE_EXTENSION_BASE_PATH=\"${MULLE_SDE_EXTENSION_BASE_PATH}\""
   fi

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

   r_colon_concat "${MULLE_SDE_EXTENSION_BASE_PATH}" "${homeprefdir}/mulle-sde/extensions"
   s="${RVAL}"

   r_extension_get_installdir
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


r_extension_get_vendor_path()
{
   log_entry "r_extension_get_vendor_path" "$@"

   local vendor="$1" # can not be empty

   [ -z "${vendor}" ] && fail "Empty vendor name"

   local searchpath
   local i

   r_extension_get_searchpath
   searchpath="${RVAL}"

   RVAL=""

   IFS=':'; set -o noglob
   for i in ${searchpath}
   do
      if [ -d "${i}/${vendor}" ]
      then
         log_debug "Vendor \"${vendor}\" found in \"${i}\""

         r_colon_concat "${RVAL}" "${i}"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


r_extension_get_quoted_vendor_dirs()
{
   log_entry "r_extension_get_quoted_vendor_dirs" "$@"

   local vendor="$1"
   local s="$2"
   local t="$3"

   local vendorpath
   local i

   r_extension_get_vendor_path "${vendor}"
   vendorpath="${RVAL}"

   RVAL=""

   IFS=':'; set -o noglob
   for i in ${vendorpath}
   do
      r_concat "${RVAL}" "${s}${i}/${vendor}${t}"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


_extension_list_vendors()
{
   log_entry "_extension_list_vendors" "$@"

   local searchpath
   local i

   r_extension_get_searchpath
   searchpath="${RVAL}"

   IFS=':'; shopt -s nullglob
   for i in ${searchpath}
   do
      if [ -d "${i}" ]
      then
         rexekutor find -H "${i}" -mindepth 1 \
                                  -maxdepth 1 \
                                  \( -type d -o -type l \) \
                                  \! -name mulle-env  \
                                  -print
      fi
   done
   IFS="${DEFAULT_IFS}"; shopt -u nullglob
}


extension_list_vendors()
{
   log_entry "extension_list_vendors" "$@"

   # plugins vendor name is not allowed
   _extension_list_vendors "$@" | LC_ALL=C sed -e s'|.*/||' | sed -e '/plugins/d' | LC_ALL=C sort -u
}


_extension_list_vendor_extensions()
{
   log_entry "_extension_list_vendor_extensions" "$@"

   local vendor="$1"

   local searchpaths

   r_extension_get_quoted_vendor_dirs "${vendor}" "'" "'"
   searchpaths="${RVAL}"

   if [ -z "${searchpath}" ]
   then
      return 1
   fi
   eval_rexekutor find -H "${searchpaths}" -mindepth 1 -maxdepth 1 '\(' -type d -o -type l '\)' -print
}


extension_list_vendor_extensions()
{
   log_entry "extension_list_vendor_extensions" "$@"

   _extension_list_vendor_extensions "$@" | LC_ALL=C sed -e s'|.*/||' | LC_ALL=C sort -u
}


r_find_extension_in_searchpath()
{
   log_entry "r_find_extension_in_searchpath" "$@"

   local vendor="$1"
   local name="$2"
   local searchpath="$3"

   case "${name}" in
      */*)
         internal_fail "Inherit \"${name}\" was not correctly parsed"
      ;;

      *:*)
         fail "Inherit \"${name}\" is in obsolete <vendor>:<extension> format. \
Use / separator"
      ;;
   esac

   RVAL="`eval_rexekutor find -H "${searchpath}" \
                                    -mindepth 1 -maxdepth 1 \
                                    '\(' -type d -o -type l '\)' \
                                    -name "${name}" \
                                    -print | head -1`"

   if [ -z "${RVAL}" ]
   then
      log_fluff "Extension \"${vendor}/${name}\" is not there."
      return 1
   fi

   log_fluff "Found extension \"${RVAL}\""
}


r_find_get_quoted_searchpath()
{
   log_entry "r_find_get_quoted_searchpath" "$@"

   local vendor="$1"

   local searchpath

   r_extension_get_quoted_vendor_dirs "${vendor}" "'" "'"
   searchpath="${RVAL}"

   if [ -z "${searchpath}" ]
   then
      log_fluff "Extension vendor \"${vendor}\" is unknown."
      RVAL=""
      return 1
   fi

   RVAL="${searchpath}"
}


r_find_extension()
{
   log_entry "r_find_extension" "$@"

   local vendor="$1"
   local name="$2"

   local searchpath

   if ! r_find_get_quoted_searchpath "${vendor}"
   then
      return 1
   fi

   searchpath="${RVAL}"

   r_find_extension_in_searchpath "${vendor}" "${name}" "${searchpath}"
}


r_extensionnames_from_vendorextensions()
{
   log_entry "r_extensionnames_from_vendorextensions" "$@"

   local vendorextensions="$1"
   local extensiontype="$2"
   local vendor="$3"

   local line
   local result
   local foundtype
   local directory

   IFS=$'\n' ; set -o noglob
   for line in ${vendorextensions}
   do
      foundtype="${line#*;}"
      if [ -z "${extensiontype}" -o "${foundtype}" = "${extensiontype}" ]
      then
         directory="${line%%;*}"
         r_basename "${directory}"
         r_add_line "${result}" "${vendor}/${RVAL}"
         result="${RVAL}"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   RVAL="${result}"
}



r_collect_vendorextensions()
{
   log_entry "r_collect_vendorextensions" "$@"

   local vendor="$1"
   local searchname="$2"
   local searchtype="$3"

   local directory
   local searchpath
   local extensiondir
   local foundtype

   r_extension_get_quoted_vendor_dirs "${vendor}" "'" "'"
   searchpath="${RVAL}"
   if [ -z "${searchpath}" ]
   then
      RVAL=""
      return 1
   fi

   local vendorextensions

#     log_debug "$directory: ${directory}"
   IFS=$'\n' ; set -o noglob
   for extensiondir in `eval_rexekutor find -H "${searchpath}" \
                                            -mindepth 1 \
                                            -maxdepth 1 \
                                            '\(' -type d -o -type l '\)' \
                                            -print`
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      foundtype="`LC_ALL=C egrep -v '^#' "${extensiondir}/type" 2> /dev/null `"
      if [ -z "${foundtype}" ]
      then
         log_debug "\"${extensiondir}\" has no type information, skipped"
         continue
      fi

      if [ ! -z "${searchtype}" -a "${searchtype}" != "${foundtype}" ]
      then
         log_debug "\"${extensiondir}\" type \"${foundtype}\" does not match \"${searchtype}\""
         continue
      fi

      if [ ! -z "${searchname}" ]
      then
         r_basename "${extensiondir}"
         if [ "${searchname}" != "${RVAL}" ]
         then
            log_debug "\"${extensiondir}\" name \"${RVAL}\" does not match \"${searchname}\""
            continue
         fi
      fi

      r_add_line "${vendorextensions}" "${extensiondir};${foundtype}"
      vendorextensions="${RVAL}"
   done

   IFS="${DEFAULT_IFS}"; set +o noglob

   RVAL="${vendorextensions}"
}


collect_extension_projecttypes()
{
   log_entry "collect_extension_projecttypes" "$@"

   local extensiondir="$1"

   (
      shopt -s nullglob
      for i in "${extensiondir}/project/"*
      do
         if [ -d "$i" ]
         then
            basename -- "$i"
         fi
      done
   )
}


collect_extension_inherits()
{
   log_entry "collect_extension_inherits" "$@"

   local extensiondir="$1"

   local text

   text="`LC_ALL=C egrep -s -v '^#' "${extensiondir}/inherit"`"

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


extension_list_installed_vendors()
{
   log_entry "extension_list_installed_vendors" "$@"

   if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
   then
      rexekutor cut -d/ -f1 "${MULLE_SDE_SHARE_DIR}/extension" | remove_duplicate_lines_stdin
   fi
}


sde_extension_vendors_main()
{
   log_entry "sde_extension_vendors_main" "$@"

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
      extension_list_installed_vendors
   else
      extension_list_vendors
   fi
}


sde_extension_find_main()
{
   log_entry "sde_extension_find_main" "$@"

   local OPTION_QUIET='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_find_usage
         ;;

         -q|--quiet)
            OPTION_QUIET='YES'
         ;;

         -*)
            sde_extension_find_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -lt 1 ] && sde_extension_find_usage "Missing arguments"
   [ $# -gt 2 ] && sde_extension_find_usage "Superflous arguments \"$*\""

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
      r_collect_vendorextensions "${vendor}" "${name}" "${type}"
      extensions="${RVAL}"
   else
      local all_vendors

      all_vendors="`extension_list_vendors`" || exit 1

      set -o noglob; IFS=$'\n'
      for vendor in ${all_vendors}
      do
         IFS="${DEFAULT_IFS}"; set +o noglob

         r_collect_vendorextensions "${vendor}" "${name}" "${type}"
         r_add_line "${extensions}" "${RVAL}"
         extensions="${RVAL}"
      done
      IFS="${DEFAULT_IFS}"; set +o noglob
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


_extension_get_usage()
{
   log_entry "_extension_get_usage" "$@"

   local vendor="$1"
   local name="$2"

   local directory

   r_find_extension "${vendor}" "${name}"
   directory="${RVAL}"

   [ -z "${directory}" ] && internal_fail "invalid extension \"${vendor}/${result}\""

   local usagefile

   usagefile="${directory}/usage"

   if [ ! -f "${usagefile}" ]
   then
      log_debug "File \"${usagefile}\" is missing or unreadable"
      return 1
   fi

   LC_ALL=C egrep -v '^#' < "${usagefile}"
}


extension_get_usage()
{
   log_entry "extension_get_usage" "$@"

   local extension="$1"

   _extension_get_usage "${extension%%/*}" "${extension##*/}"
}


_extension_get_version()
{
   log_entry "_extension_get_version" "$@"

   local vendor="$1"
   local name="$2"

   local directory
   r_find_extension "${vendor}" "${name}"
   directory="${RVAL}"

   [ -z "${directory}" ] && internal_fail "invalid extension \"${vendor}/${result}\""

   local versionfile

   versionfile="${directory}/version"

   if [ ! -f "${versionfile}" ]
   then
      log_debug "File \"${versionfile}\" is missing or unreadable"
      log_warning "Extension \"${vendor}/${name}\" is unversioned and therefore not usable"
      return 1
   fi

   LC_ALL=C egrep -v '^#' < "${versionfile}"
}


extension_get_version()
{
   log_entry "extension_get_version" "$@"

   local extension="$1"

   _extension_get_version "${extension%%/*}" "${extension##*/}"
}


emit_extension()
{
   log_entry "emit_extension" "$@"

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
      IFS=$'\n'
      for extension in `remove_duplicate_lines "${result}"`
      do
         IFS="${DEFAULT_IFS}"

         output="${extension}"
         if [ "${with_version}" = 'YES' ]
         then
            version="`extension_get_version "${extension}"`"
            r_concat "${output}" "${version}" ";"
            output="${RVAL}"
         fi

         if [ "${with_usage}" = 'YES' ]
         then
            usage="`extension_get_usage "${extension}" | head -1`"
            r_concat "${output}" "${usage}" ";"
            output="${RVAL}"
         fi

         printf "%s\n" "${output}"
      done
      IFS="${DEFAULT_IFS}"
   ) | column -t -s';'
}



sde_extension_show_main()
{
   log_entry "sde_extension_show_main" "$@"

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
            sde_extension_show_usage
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

         --all)
            OPTION_ALL='YES'
         ;;

         --output-format)
            shift
            OPTION_OUTPUT_RAW='YES'
         ;;

         -*)
            sde_extension_show_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -gt 1 ] && sde_extension_show_usage "Superflous arguments \"$*\""

   local cmd

   cmd="$1"
   if [ -z "${cmd}" ]
   then
      if [ -z "${MULLE_VIRTUAL_ROOT}" ]
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
         printf "%s\n" "`extension_list_vendors`"
         return
      ;;
   esac

   if [ "${OPTION_ALL}" != 'YES' ]
   then
      vendors="`extension_list_installed_vendors`"
   fi
   if [ -z "${vendors}" -o "${OPTION_ALL}" = 'YES' ]
   then
      vendors="`extension_list_vendors`"
   fi

   log_verbose "Vendors:"
   log_verbose "`LC_ALL=C sort -u <<< "${vendors}" | sed 's/^/  /' `"

   set -o noglob; IFS=$'\n'
   for vendor in ${vendors}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ -z "${vendor}" ]
      then
         continue
      fi

      local vendorextensions

      r_collect_vendorextensions "${vendor}"
      vendorextensions="${RVAL}"

      if [ -z "${vendorextensions}" ]
      then
         log_warning "Vendor ${vendor} provides no extensions"
         continue
      fi

      if [ "${OPTION_OUTPUT_RAW}" = 'YES' ]
      then
         if ! [ -z "${vendorextensions}" ]
         then
            printf "%s\n" "${vendorextensions}"
         fi
         continue
      fi

      log_debug "Vendor ${C_RESET}${vendor}${C_DEBUG} extensions: ${vendorextensions}"

      case "${cmd}" in
         all|default|meta)
            r_extensionnames_from_vendorextensions "${vendorextensions}" "meta" "${vendor}"
            r_add_line "${meta_extension}" "${RVAL}"
            meta_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|default|extra)
            r_extensionnames_from_vendorextensions "${vendorextensions}" "extra" "${vendor}"
            r_add_line "${extra_extension}" "${RVAL}"
            extra_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|default|oneshot)
            r_extensionnames_from_vendorextensions "${vendorextensions}" "oneshot" "${vendor}"
            r_add_line "${oneshot_extension}" "${RVAL}"
            oneshot_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|runtime)
            r_extensionnames_from_vendorextensions "${vendorextensions}" "runtime" "${vendor}"
            r_add_line "${runtime_extension}" "${RVAL}"
            runtime_extension="${RVAL}"
         ;;
      esac

      case "${cmd}" in
         all|buildtool)
            r_extensionnames_from_vendorextensions "${vendorextensions}" "buildtool" "${vendor}"
            r_add_line "${buildtool_extension}" "${RVAL}"
            buildtool_extension="${RVAL}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   emit_extension "${meta_extension}"      "meta" "[-m <extension>]"      "${OPTION_VERSION}" "${OPTION_USAGE}"
   emit_extension "${runtime_extension}"   "runtime" "[-r <extension>]"   "${OPTION_VERSION}" "${OPTION_USAGE}"
   emit_extension "${buildtool_extension}" "buildtool" "[-b <extension>]" "${OPTION_VERSION}" "${OPTION_USAGE}"
   emit_extension "${extra_extension}"     "extra" "[-e <extension>]*"    "${OPTION_VERSION}" "${OPTION_USAGE}"
   emit_extension "${oneshot_extension}"   "oneshot" "[-o <extension>]*"  "${OPTION_VERSION}" "${OPTION_USAGE}"

  :
}


sde_extension_list_main()
{
   log_entry "sde_extension_list_main" "$@"

   local OPTION_VERSION='YES'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_extension_list_usage
         ;;

         --version)
            OPTION_VERSION='YES'
         ;;

         --no-version)
            OPTION_VERSION='NO'
         ;;

         -*)
            sde_extension_list_usage
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
      IFS=$'\n'
      for filename in `rexekutor find "${MULLE_SDE_SHARE_DIR}/version" -type f -print`
      do
         IFS="${DEFAULT_IFS}"

         log_verbose "Found ${C_RESET_BOLD}${filename}"

         r_basename "${filename}"
         extension="${RVAL}"
         r_dirname "${filename}"
         vendor="${RVAL}"
         r_basename "${vendor}"
         vendor="${RVAL}"

         if [ "${OPTION_VERSION}" = 'YES' ]
         then
            version="`LC_ALL=C egrep -v '^#' < "${filename}"`"
            printf "%s %s\n" "${vendor}/${extension}" "${version}"
         else
            printf "%s\n" "${vendor}/${extension}"
         fi
      done
      IFS="${DEFAULT_IFS}"
   ) | LC_ALL=C sort
}


collect_file_info()
{
   log_entry "collect_file_info" "$@"

   local extensiondirs="$1"
   local filename="$2"

   local directory

   set -o noglob; IFS=$'\n'
   for directory in ${extensiondirs}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"

      cat "${directory}/${filename}" 2> /dev/null
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
}


__set_extension_vars()
{
   log_entry "__set_extension_vars" "$@"

   vendor="${OPTION_VENDOR}"

   case "${extension}" in
      *:*)
         internal_fail "obsolete extension format"
      ;;

      */*)
         vendor="${extension%%/*}"
         extension="${extension##*/}"
      ;;
   esac

   r_find_extension "${vendor}" "${extension}" || fail "Unknown extension \"${vendor}/${extension}\""
   extensiondir="${RVAL}"

   inherits="`collect_extension_inherits "${extensiondir}"`"
}


__emit_extension_list_types()
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

__emit_extension_usage()
{
   log_entry "__emit_extension_usage" "$@"

   local extension="$1"

   local inherits
   local extensiondir
   local vendor

   __set_extension_vars

   if [ "${OPTION_LIST_TYPES}" = 'YES' ]
   then
       collect_extension_projecttypes "${extensiondir}"
       return
   fi

   local exttype

   exttype="`LC_ALL=C egrep -v '^#' < "${extensiondir}/type"`"

   if [ "${OPTION_USAGE_ONLY}" != 'YES' ]
   then
      echo "Usage:"
      echo "   mulle-sde init --${exttype}" "${vendor}/${extension} <type>"
      echo
   fi

   local usagetext

   usagetext="`collect_file_info "${extensiondir}" "usage"`"

   if [ "${OPTION_USAGE_ONLY}" != 'YES' ]
   then
      if [ ! -z "${usagetext}" ]
      then
         sed 's/^/   /' <<< "${usagetext}"
         echo
      fi
   fi

   local inherit_text

   inherit_text="`collect_extension_inherits "${extensiondir}"`"

   if [ ! -z "${inherit_text}" ]
   then
      local dependency


      IFS=$'\n'
      for dependency in `sed 's/^\([^;]*\).*/\1/' <<< "${inherit_text}"`
      do
         mulle-sde extension usage --usage-only "${dependency}" | \
               sed -e 's/^   \[i\]//'g | \
               sed -e 's/^/   [i]/'
      done
      IFS="${DEFAULT_IFS}"

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

   text="`collect_extension_projecttypes "${extensiondir}"`"
   text="${text:-all}"

   echo "Types:"
   sed 's/^/   /' <<< "${text}"
   echo

   text="`collect_extension_inherits "${extensiondir}"`"
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
         (
            cd "${extensiondir}/share/ignore.d"
            ls -1 [0-9]*-*--* 2> /dev/null
         ) | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -d "${extensiondir}/share/match.d" ]
      then
         echo "Match.d:"
         (
            cd "${extensiondir}/share/match.d"
            ls -1 [0-9]*-*--*  2> /dev/null
         ) | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -d "${extensiondir}/share/bin" ]
      then
         echo "Callbacks:"
         (
            cd "${extensiondir}/share/bin"
            ls -1 *-callback 2> /dev/null | sed -e 's/-callback//'
         ) | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -d "${extensiondir}/share/libexec" ]
      then
         echo "Tasks:"
         (
            cd "${extensiondir}/share/libexec"
            ls -1 *-task.sh 2> /dev/null | sed -e 's/-task\.sh//'
         ) | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/dependency" ]
      then
         echo "Dependencies:"
         egrep -v '^#' "${extensiondir}/dependency" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/library" ]
      then
         echo "Libraries:"
         egrep -v '^#' "${extensiondir}/library" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/environment" ]
      then
         echo "Environment:"
         egrep -v '^#' "${extensiondir}/environment" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/tool" ]
      then
         echo "Tools:"
         egrep -v '^#' "${extensiondir}/tool" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi

      if [ -f "${extensiondir}/optionaltool" ]
      then
         echo "Optional Tools:"
         egrep -v '^#' "${extensiondir}/optionaltool" \
            | sed -e '/^[ ]*$/d' -e 's/^/   /'
         echo
      fi
   fi

   if [ -z "${OPTION_LIST}" ]
   then
      return
   fi

   echo "Project Types:"
   __emit_extension_list_types "${extensiondir}" "${OPTION_LIST}" \
      | sed -e '/^[ ]*$/d' -e 's/^/   /'
   echo
}


emit_extension_usage()
{
   log_entry "emit_extension_usage" "$@"

   local extension="$1"

   if [ "${OPTION_RECURSE}" = 'YES' ]
   then
      local dependency

      local inherits
      local extensiondir
      local vendor

      __set_extension_vars

      local dependencies

      dependencies="`collect_extension_inherits "${extensiondir}"`"
      set -o noglob; IFS=$'\n'
      for dependency in ${dependencies}
      do
         set +o noglob; IFS="${DEFAULT_IFS}"

         emit_extension_usage "${dependency}"
         if [ "${OPTION_LIST_TYPES}" = 'NO' ]
         then
            echo "------------------------------------------------------------"
            echo
         fi
      done
      set +o noglob; IFS="${DEFAULT_IFS}"
   fi
   __emit_extension_usage "${extension}"
}


sde_extension_usage_main()
{
   log_entry "sde_extension_usage_main" "$@"

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
            sde_extension_usage_usage
         ;;

         -i|--info)
            OPTION_INFO='YES'
         ;;

         -l|--list)
            [ $# -eq 1 ] && sde_extension_usage_usage "Missing argument to \"$1\""
            shift

            OPTION_LIST="$1"
         ;;

         -r|--recurse)
            OPTION_RECURSE='YES'
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_extension_usage_usage "Missing argument to \"$1\""
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
            sde_extension_usage_usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local extension="$1"
   [ -z "${extension}" ] && sde_extension_usage_usage "missing extension name"
   shift

   [ "$#" -ne 0 ] && sde_extension_usage_usage "superflous arguments \"$*\""

   if [ "${OPTION_LIST_TYPES}" = 'YES' ]
   then
      emit_extension_usage "${extension}" | LC_ALL=C sort -u
   else
      emit_extension_usage "${extension}"
   fi
}


hack_option_and_single_quote_everything()
{
   log_entry "hack_option_and_single_quote_everything" "$@"

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



sde_extension_add_main()
{
   log_entry "sde_extension_add_main" "$@"

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_add_usage
         ;;

         -*)
            sde_extension_add_usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   # shellcheck source=src/mulle-sde-init.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   local extension
   local args
   local installed_vendors
   local found

   installed_vendors="`extension_list_installed_vendors`"

   for extension in "$@"
   do
      case "${extension}" in
         */*)
            r_add_line "${args}" "${extension}"
            args="${RVAL}"
         ;;

         *)
            found='NO'
            set -o noglob; IFS=$'\n'
            for installed in ${installed_vendors}
            do
               IFS="${DEFAULT_IFS}"; set +o noglob
               if r_find_extension "${installed}" "${extension}"
               then
                  log_info "Selecting \"${installed}/${extension}\""

                  r_add_line "${args}" "${installed}/${extension}"
                  args="${RVAL}"
                  found='YES'
                  break
               fi
            done
            IFS="${DEFAULT_IFS}"; set +o noglob

            if [ "${found}" = 'NO' ]
            then
               fail "You need to prefix extension \"${extension}\" with a vendor"
            fi
         ;;
      esac
   done

   args="`hack_option_and_single_quote_everything "--extra" $args | tr '\012' ' '`"

   INIT_USAGE_NAME="${MULLE_USAGE_NAME} extension add" \
      eval sde_init_main --no-blurb --no-env --add "${args}"
}


sde_extension_remove_main()
{
   log_entry "sde_extension_remove_main" "$@"

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_remove_usage
         ;;

         -*)
            sde_extension_remove_usage "Unknown option \"$1\""
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
   fi

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

      # paranoia of user input breaking  egrep
      r_identifier "${vendor}"
      vendor="${RVAL}"

      r_identifier "${name}"
      name="${name}"

      matches="`rexekutor egrep -x "${vendor:-.*}/${name:-.*};extra" <<< "${changed}"`"
      r_add_line "${removed}" "${matches}"
      removed="${RVAL}"
      if [ ! -z "${matches}" ]
      then
         changed="`rexekutor egrep -v -x "${vendor:-.*}/${name:-.*};extra" <<< "${changed}"`"
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
   exekutor chmod -R +w "${MULLE_SDE_SHARE_DIR}" || exit 1

   redirect_exekutor "${MULLE_SDE_SHARE_DIR}/extension" echo "${changed}" &&

   # remove from installed versions
   local line

   IFS=$'\n'; set -f
   for line in ${removed}
   do
      line="${line%%;*}"
      vendor="${line%%/*}"
      name="${line##*/}"

      remove_file_if_present "${MULLE_SDE_SHARE_DIR}/version/${vendor}/${name}"
      rmdir_if_empty "${MULLE_SDE_SHARE_DIR}/version/${vendor}"
   done
   IFS="${DEFAULT_IFS}"; set +f

   rmdir_if_empty "${MULLE_SDE_SHARE_DIR}/version"

   exekutor chmod -R -w "${MULLE_SDE_SHARE_DIR}"
}



###
### parameters and environment variables
###
sde_extension_main()
{
   log_entry "sde_extension_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_extension_usage
         ;;

         -*)
            sde_extension_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_extension_usage

   local cmd="$1"
   shift

   local OPTION_DEFINES

   case "$1" in
      -h|--help|help)
         if [ "`type -t "sde_extension_${cmd}_usage"`" = "function" ]
         then
            sde_extension_${cmd}_usage
         else
            sde_extension_usage
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
      add|remove)
         [ $# -eq 0 ] && sde_extension_${cmd}_usage

         sde_extension_${cmd}_main "$@"
      ;;

      pimp)
         [ $# -eq 0 ] && sde_extension_pimp_usage

         # shellcheck source=src/mulle-sde-init.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

         local args

         args="`hack_option_and_single_quote_everything "--oneshot" "$@" | tr '\012' ' '`"

         INIT_USAGE_NAME="${MULLE_USAGE_NAME} extension add" \
            eval sde_init_main --no-blurb --no-env --add "${args}"
      ;;

      find|show|usage|vendors)
         sde_extension_${cmd}_main "$@"
      ;;

      list)
         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exec_command_in_subshell extension ${cmd} "$@"
         fi

         sde_extension_${cmd}_main "$@"
      ;;

      meta|runtime|buildtool)
         local extension

         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exekutor exec mulle-sde run mulle-sde extension "${cmd}"
         fi

         if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
         then
            extension="`egrep -e ";${cmd}\$" "${MULLE_SDE_SHARE_DIR}/extension" | head -1 | cut -d';' -f 1`"
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

         [ ! -z "${MULLE_SDE_SHARE_DIR}" ] || internal_fail "MULLE_SDE_SHARE_DIR undefined"

         if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
         then
            extensions="`rexekutor egrep -e ";${cmd%s}\$" "${MULLE_SDE_SHARE_DIR}/extension" | cut -d';' -f 1`"
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

         r_extension_get_searchpath
         printf "%s\n" "${RVAL}"
      ;;

      vendorpath)
         [ $# -eq 0 ] && sde_extension_usage "Missing vendor argument"

         log_info "Extension vendor path"
               r_extension_get_vendor_path "$1"

         printf "%s\n" "${RVAL}"
      ;;

      "")
         sde_extension_usage
      ;;

      *)
         sde_extension_usage "unknown command \"${cmd}\""
      ;;
   esac
}

