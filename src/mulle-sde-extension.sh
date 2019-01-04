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
   mulle-sde init.

Commands:
   add        : add an extra extension to your project
   list       : list installed extensions
   meta       : print the installed meta extension
   pimp       : pimp up your your project with a one-shot extension
   searchpath : show locations where extensions are searched
   show       : show available extensions
   upgrade    : upgrade project extensions to the latest version
   usage      : show usage information for an extension
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


sde_extension_show_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension show [options] [type]

   Shows the available mulle-sde extensions of types "meta" and "extra" by
   default. Those are usually the candidates to select.

Options:
   --version     : show version of the extensions
   --output-raw  : show locations and type of extensions as CSV

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

   r_fast_dirname "$0"
   r_fast_dirname "${RVAL}"
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
      linux|freebsd)
         r_colon_concat "${s}" "/usr/share/mulle-sde/extensions"
         s="${RVAL}"
      ;;
   esac

   case "${MULLE_UNAME}" in
      darwin|linux|freebsd)
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

   IFS=":"; set -o noglob
   for i in ${searchpath}
   do
      if [ -d "${i}/${vendor}" ]
      then
         r_colon_concat "${RVAL}" "${i}"
      fi
      # log_debug "Vendor \"${vendor}\" not found in \"${i}\""
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

   IFS=":"; set -o noglob
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
   local s
   local i

   r_extension_get_searchpath
   searchpath="${RVAL}"

   IFS=":"; set -o noglob
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
   IFS="${DEFAULT_IFS}"; set +o noglob
}


extension_list_vendors()
{
   log_entry "extension_list_vendors" "$@"

   _extension_list_vendors "$@" | LC_ALL=C sed -e s'|.*/||' | LC_ALL=C sort -u
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
   eval_exekutor find -H "${searchpaths}" -mindepth 1 -maxdepth 1 '\(' -type d -o -type l '\)' -print
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

   RVAL="`eval_exekutor find -H "${searchpath}" -mindepth 1 -maxdepth 1 '\(' -type d -o -type l '\)' -name "${name}" -print | head -1`"

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

   IFS="
" ; set -o noglob
   for line in ${vendorextensions}
   do
      foundtype="${line#*;}"
      if [ -z "${extensiontype}" -o "${foundtype}" = "${extensiontype}" ]
      then
         directory="${line%%;*}"
         r_fast_basename "${directory}"
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
   IFS="
" ; set -o noglob
   for extensiondir in `eval_exekutor find -H "${searchpath}" -mindepth 1 -maxdepth 1 '\(' -type d -o -type l '\)' -print`
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      foundtype="`LC_ALL=C egrep -v '^#' "${extensiondir}/type" 2> /dev/null `"
      if [ -z "${foundtype}" ]
      then
         log_debug "\"${extensiondir}\" has no type information, skipped"
         continue
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
            fast_basename "$i"
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

   IFS=";"
   while read -r dependency exttype
   do
      if [ -z "${dependency}" ]
      then
         continue
      fi

      echo "${dependency}"
   done <<< "${text}"
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

   versionfile="${directory}/share/version/${vendor}/${name}"

   if [ ! -f "${versionfile}" ]
   then
      log_debug "File \"${versionfile}\" is missing or unreadable"
      log_warning "Extension \"${vendor}/${name}\" is unversioned and therefore not usable"
   fi

   LC_ALL=C egrep -v '^#' < "${versionfile}"
}


extension_get_version()
{
   log_entry "_extension_get_version" "$@"

   local extension="$1"

   _extension_get_version "${extension%%/*}" "${extension##*/}"
}


emit_extension()
{
   log_entry "emit_extension" "$@"

   local result="$1"
   local extensiontype="$2"
   local comment="$3"

   if [ -z "${result}" ]
   then
      return
   fi

   local extension
   local version

   log_info "Available ${extensiontype} extensions ${comment}:"

   IFS="
"
   for extension in `sort -u <<< "${result}"`
   do
      IFS="${DEFAULT_IFS}"

      if [ "${OPTION_VERSION}" = 'YES' ]
      then
         version="`extension_get_version "${extension}"`"
         echo "${extension}" "${version}"
      else
         echo "${extension}"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


sde_extension_show_main()
{
   log_entry "sde_extension_show_main" "$@"

   local OPTION_VERSION='NO'
   local OPTION_OUTPUT_RAW='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_show_usage
         ;;

         --version)
            OPTION_VERSION='YES'
         ;;

         --no-version)
            OPTION_VERSION='NO'
         ;;

         --output-raw)
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

   local cmd

   cmd="$1"
   if [ -z "${cmd}" ]
   then
      if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
      then
         cmd="default"
      else
         cmd="meta"
      fi
   fi

   local runtime_extension
   local buildtool_extension
   local meta_extension
   local extra_extension
   local oneshot_extension
   local vendor

   local all_vendors

   all_vendors="`extension_list_vendors`"

   case "${cmd}" in
      vendor|vendors)
         log_info "Available vendors"
         echo "${all_vendors}"
         return
      ;;
   esac

   log_verbose "Available vendors:"
   log_verbose "`LC_ALL=C sort -u <<< "${all_vendors}" | sed 's/^/  /'`"

   set -o noglob ; IFS="
"
   for vendor in ${all_vendors}
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
            echo "${vendorextensions}"
         fi
         continue
      fi

      log_debug "vendorextensions: ${vendorextensions}"

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

   emit_extension "${meta_extension}" "meta" "[-m <extension>]"
   emit_extension "${runtime_extension}" "runtime" "[-r <extension>]"
   emit_extension "${buildtool_extension}" "buildtool" "[-b <extension>]"
   emit_extension "${extra_extension}" "extra" "[-e <extension>]*"
   emit_extension "${oneshot_extension}" "oneshot" "[-o <extension>]*"

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
      IFS="
"
      for filename in `rexekutor find "${MULLE_SDE_SHARE_DIR}/version" -type f -print`
      do
         IFS="${DEFAULT_IFS}"

         log_verbose "Found ${C_RESET_BOLD}${filename}"

         r_fast_basename "${filename}"
         extension="${RVAL}"
         r_fast_dirname "${filename}"
         vendor="${RVAL}"
         r_fast_basename "${vendor}"
         vendor="${RVAL}"

         if [ "${OPTION_VERSION}" = 'YES' ]
         then
            version="`LC_ALL=C egrep -v '^#' < "${filename}"`"
            echo "${vendor}/${extension}" "${version}"
         else
            echo "${vendor}/${extension}"
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

   set -o noglob ; IFS="
"
   for directory in ${extensiondirs}
   do
      set +o noglob ; IFS="${DEFAULT_IFS}"

      cat "${directory}/${filename}" 2> /dev/null
   done
   set +o noglob ; IFS="${DEFAULT_IFS}"
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


      IFS="
"
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

      set -o noglob ; IFS="
"
      for dependency in `collect_extension_inherits "${extensiondir}"`
      do
         set +o noglob ; IFS="${DEFAULT_IFS}"

         emit_extension_usage "${dependency}"
         if [ "${OPTION_LIST_TYPES}" = 'NO' ]
         then
            echo "------------------------------------------------------------"
            echo
         fi
      done
      set +o noglob ; IFS="${DEFAULT_IFS}"
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

   echo "${option}"
   echo "'${last}'"
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

   case "${cmd}" in
      add|pimp)
         [ $# -eq 0 ] && sde_extension_${cmd}_usage

         # shellcheck source=src/mulle-sde-upgrade.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

         local option
         local args

         option="--extra"
         if [ "${cmd}" = "pimp" ]
         then
            option="--oneshot"
         fi

         args="`hack_option_and_single_quote_everything "${option}" "$@" | tr '\012' ' '`"

         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} extension add" \
            eval sde_init_main --no-blurb --no-env --add "${args}"
      ;;

      show)
         sde_extension_${cmd}_main "$@"
      ;;

      list)
         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exec_command_in_subshell extension ${cmd} "$@"
         fi

         sde_extension_${cmd}_main "$@"
      ;;

      meta|installed-meta)
         local meta

         [ -z "${MULLE_VIRTUAL_ROOT}" ] && fail "Command must be run from inside subshell"

         if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
         then
            meta="`egrep ';meta$' "${MULLE_SDE_SHARE_DIR}/extension" | head -1 | cut -d';' -f 1`"
         fi

         if [ -z "${meta}" ]
         then
            log_warning "Could not figure out installed meta extension"
            return 1
         fi
         echo "${meta}"
      ;;

      searchpath)
         log_info "Extension searchpath"

               r_extension_get_searchpath
         echo "${RVAL}"
      ;;

      vendorpath)
         [ $# -eq 0 ] && sde_extension_usage "Missing vendor argument"

         log_info "Extension vendor path"
               r_extension_get_vendor_path "$1"

         echo "${RVAL}"
      ;;

      upgrade)
         # shellcheck source=src/mulle-sde-upgrade.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-upgrade.sh"

         if [ -z "${MULLE_VIRTUAL_ROOT}" ]
         then
            exec_command_in_subshell extension upgrade "$@"
         fi

         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} add" \
            sde_upgrade_main "$@"
      ;;

      usage)
         sde_extension_usage_main "$@"
      ;;

      "")
         sde_extension_usage
      ;;

      *)
         sde_extension_usage "unknown command \"${cmd}\""
      ;;
   esac
}

