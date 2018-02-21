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
   ${MULLE_EXECUTABLE_NAME} extension <command>

   Operations for mulle-sde extensions

Options:
   -v vendor : specify a different extension vendor

Commands:
   list      : list available extensions
   status    : list project extensions with version
EOF
   exit 1
}


sde_extension_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} extension [options] list [type]

   List available mulle-sde extension.

Options:
   -v vendor : specify a different extension vendor

Types:
   common    : common extension
   buildtool : buildtool extension
   extra     : extra extension
   meta      : meta extension
   runtime   : runtime extension (default)
EOF
   exit 1
}


sde_extension_status_usage()
{
  [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} extension status

   Show mulle-sde extensions, that are installed in the current project.
EOF
   exit 1
}


extension_get_home_config_dir()
{
   log_entry "extension_get_home_config_dir" "$@"

   case "${UNAME}" in
      darwin)
         # or what ?
         echo "${HOME}/Library/Preferences"
      ;;

      *)
         echo "${HOME}/.config"
      ;;
   esac
}


#
# An extension must be present at init time. Nothing from the project
# exists (there is nothing in MULLE_VIRTUAL_ROOT/dependencies)
#
# Find extensions in:
#
# ${HOME}/.config/mulle-sde/extensions/<vendor> (or elsewhere OS dependent)
# /usr/local/share/mulle_sde/extensions/<vendor>
# /usr/share/mulle_sde/extensions/<vendor>
#
extension_get_search_path()
{
   log_entry "extension_get_search_path" "$@"

   local vendor="$1" # can be empty

   local extensionsdir
   local homeextensionsdir

   local i
   local searchpath

   #
   # allow environment to add more extensions, mostly useful for development
   # where you don't really want to reinstall extensions with every little
   # edit
   #
   IFS=":"; set -o noglob
   for i in ${MULLE_SDE_EXTENSION_PATH}
   do
      i="`filepath_concat "${i}" "${vendor}"`"
      s="`colon_concat "$s" "$i" `"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   case "${vendor}" in
      ""|mulle-sde)
         extensionsdir="`filepath_concat "${MULLE_SDE_LIBEXEC_DIR}/extensions" "${vendor}"`"
         s="`colon_concat "$s" "${extensionsdir}" `"
      ;;

      *)
         homeextensionsdir="`extension_get_home_config_dir`/mulle-sde/extensions"
         homeextensionsdir="`filepath_concat  "${homeextensionsdir}" "${vendor}"`"

         s="`colon_concat "$s" "${homeextensionsdir}" `"

         extensionsdir="share/mulle-sde/extensions"
         extensionsdir="`filepath_concat "${extensionsdir}" "${vendor}"`"
         s="`colon_concat "$s" "/usr/local/${extensionsdir}" `"
         s="`colon_concat "$s" "/usr/${extensionsdir}" `"
      ;;
   esac

   log_fluff "Extension search path for vendor \"${vendor}\": \"$s\""

   echo "$s"
}


_extension_get_vendors()
{
   log_entry "_extension_get_vendors" "$@"

   local path
   local i

   path="`extension_get_search_path ""`"

   set -o noglob ; IFS=":"
   for i in ${path}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ -d "$i" ]
      then
         ( cd "$i" ; find . -mindepth 1 -maxdepth 1 -type d -print )
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


extension_get_vendors()
{
   log_entry "extension_get_vendors" "$@"

   _extension_get_vendors | LC_ALL=C sed s'|^\./||' | sort -u
}


collect_extension_dirs()
{
   log_entry "collect_extension_dirs" "$@"

   local vendor="$1"
   local extensiontype="$2"

   local directory
   local searchpath
   local extensiondir
   local foundtype

   searchpath="`extension_get_search_path "${vendor}" `"

   IFS=":"; set -o noglob
   for directory in ${searchpath}
   do
      if [ -z "${directory}" ] || ! [ -d "${directory}" ]
      then
         continue
      fi

      IFS="
"
      for extensiondir in `find "${directory}" -mindepth 1 -maxdepth 1 -type d -print`
      do
         IFS="${DEFAULT_IFS}"
         if [ ! -z "${extensiontype}" ]
         then
            foundtype="`LC_ALL=C egrep -v '^#' "${extensiondir}/type" 2> /dev/null `"
            log_debug "\"${extensiondir}\" purports to be of type \"${foundtype}\""

            if [ "${foundtype}" != "${extensiontype}" ]
            then
               log_debug "But we are looking for \"${extensiontype}\""
               continue
            fi
         fi
         rexekutor echo "${extensiondir}"
      done
   done
   IFS="${DEFAULT_IFS}"
}


find_extension()
{
   log_entry "find_extension" "$@"

   local vendor="$1"
   local name="$2"

   local searchpath

   searchpath="`extension_get_search_path "${vendor}" `"

   local directory

   IFS=":"; set -o noglob
   for directory in ${searchpath}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ -z "${directory}" ] || ! [ -d "${directory}" ]
      then
         continue
      fi

      if [ -d "${directory}/${name}" ]
      then
         log_fluff "Found extension \"${directory}/${name}\""
         echo "${directory}/${name}"
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"; set +o noglob
   return 1
}


extensionnames_from_extension_dirs()
{
   log_entry "extensionnames_from_extension_dirs" "$@"

   local vendor="$1"
   local extensiondirs="$2"

   local directory

   IFS="
" ; set -o noglob
   for directory in ${extensiondirs}
   do
      echo "${vendor}:`basename -- "${directory}"`"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


collect_extension()
{
   log_entry "collect_extension" "$@"

   local vendor="$1"
   local extensiontype="$2"

   local result

   result="`collect_extension_dirs "${vendor}" "${extensiontype}"`"
   extensionnames_from_extension_dirs "${vendor}" "${result}"
}


collect_extension_projecttypes()
{
   log_entry "collect_extension" "$@"

   local extensiondir="$1"

   (
      shopt -s nullglob
      for i in ${extensiondir}/project/*
      do
         if [ -d "$i" ]
         then
            fast_basename "$i"
         fi
      done
   )
}


emit_extension()
{
   local result="$1"
   local extensiontype="$2"
   local comment="$3"

   if [ -z "${result}" ]
   then
      log_verbose "No ${extensiontype} extensions found"
   else
      log_info "Available ${extensiontype} extensions ${comment}:"
      sort -u <<< "${result}"
   fi
}


sde_extension_list_main()
{
   log_entry "sde_extension_list_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_extension_list_usage
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_extension_list_usage "missing argument for \"$1\""
            shift

            OPTION_VENDOR="$1"
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

   local common_extension
   local runtime_extension
   local buildtool_extension
   local meta_extension
   local extra_extension
   local vendor

   if [ ! -z "${OPTION_VENDOR}" ]
   then
      common_extension="`collect_extension "${OPTION_VENDOR}" common `"  || return 1
      runtime_extension="`collect_extension "${OPTION_VENDOR}" runtime `"  || return 1
      meta_extension="`collect_extension "${OPTION_VENDOR}" meta `"  || return 1
      buildtool_extension="`collect_extension "${OPTION_VENDOR}" buildtool `"  || return 1
      extra_extension="`collect_extension "${OPTION_VENDOR}" extra `"  || return 1
   else
      local all_vendors

      all_vendors="`extension_get_vendors`"

      log_verbose "Available vendors:"
      log_verbose "`sort -u <<< "${all_vendors}"`"

      IFS="
"; set -o noglob
      for vendor in ${all_vendors}
      do
         if [ -z "${vendor}" ]
         then
            continue
         fi

         IFS="${DEFAULT_IFS}"; set +o noglob

         tmp="`collect_extension "${vendor}" common `"  || return 1
         common_extension="`add_line "${common_extension}" "${tmp}" `"  || return 1

         tmp="`collect_extension "${vendor}" runtime `"  || return 1
         runtime_extension="`add_line "${runtime_extension}" "${tmp}" `"  || return 1

         tmp="`collect_extension "${vendor}" meta `"  || return 1
         meta_extension="`add_line "${meta_extension}" "${tmp}" `"  || return 1

         tmp="`collect_extension "${vendor}" buildtool `" || return 1
         buildtool_extension="`add_line "${buildtool_extension}" "${tmp}" `"  || return 1

         tmp="`collect_extension "${vendor}" extra `" || return 1
         extra_extension="`add_line "${extra_extension}" "${tmp}" `"  || return 1
      done
      IFS="${DEFAULT_IFS}"; set +o noglob
   fi

   emit_extension "${meta_extension}" "meta" "[-m <extension>]" &&
   emit_extension "${common_extension}" "common" "[-c <extension>]" &&
   emit_extension "${runtime_extension}" "runtime" "[-r <extension>" &&
   emit_extension "${buildtool_extension}" "buildtool" "[-b <extension>]" &&
   emit_extension "${extra_extension}" "extra" "[-e <extension>]*"
}


sde_extension_status_main()
{
   log_entry "sde_extension_status_main" "$@"


   while :
   do
      case "$1" in
         -h|--help)
            sde_extension_status_usage
         ;;

         -*)
            sde_extension_status_usage
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ ! -d "${MULLE_SDE_DIR}" ] && fail "This doesn't look like a mulle-sde project"

   local version
   local vendor
   local extension
   local filename

   log_info "Installed Extensions"

   (
      IFS="
"
      for filename in `find "${MULLE_SDE_DIR}/etc/version" -type f -print`
      do
         IFS="${DEFAULT_IFS}"

         version="`egrep -v '^#' < "${filename}"`"

         extension="`fast_basename "${filename}"`"
         vendor="`fast_dirname "${filename}"`"
         vendor="`fast_basename "${vendor}"`"

         echo "${vendor}:${extension}" "${version}"
      done
      IFS="${DEFAULT_IFS}"
   ) | sort
}


sde_extension_usage_main()
{
   log_entry "sde_extension_usage_main" "$@"

   while :
   do
      case "$1" in
         -h|--help)
            sde_extension_status_usage
         ;;

         -*)
            sde_extension_status_usage
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local extension="$1"

   local vendor

   vendor="${OPTION_VENDOR}"

   local extensiondir

   case "${extension}" in
      *:*)
         IFS=":" read vendor extension <<< "${extension}"
      ;;
   esac

   extensiondir="`find_extension "${vendor}" "${extension}"`" \
         || fail "Unknown extension \"${vendor}:${extension}\""


   local exttype
   local usagetext

   exttype="`egrep -v '^#' < "${extensiondir}/type"`"

   echo "Usage:"
   echo "   mulle-sde init --${exttype}" "${vendor}:${extension} <type>"
   echo

   usagetext="`cat "${extensiondir}/usage" 2> /dev/null`"
   if [ ! -z "${usagetext}" ]
   then
      sed 's/^/   /' <<< "${usagetext}"
      echo
   fi
   echo "Types:"

   collect_extension_projecttypes "${extensiondir}" | sed 's/^/   /'

}


###
### parameters and environment variables
###
sde_extension_main()
{
   log_entry "sde_extension_main" "$@"

   local OPTION_VENDOR=""

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_extension_usage
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_extension_usage
            shift

            OPTION_VENDOR="$1"
         ;;

         -*)
            sde_extension_usage
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"
   [ $# -ne 0 ] && shift

   case "${cmd}" in
      list)
         sde_extension_list_main "$@"
      ;;

      status)
         sde_extension_status_main "$@"
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

