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
MULLE_SDE_EXTENSIONS_SH="included"


sde_extensions_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} extensions [options] <type>

   List available mulle-sde extensions.

Options:
   -v vendor : specify a different extension vendor

Types:
   buildtool : buildtool extensions
   runtime   : runtime extensions (default)
EOF
   exit 1
}


extension_get_vendor_pathcomponent()
{
   log_entry "extension_get_vendor_pathcomponent" "$@"

   local vendor="$1"

   case "${vendor}" in
      ""|"mulle"|"mulle-sde")
         echo "mulle-sde"
      ;;

      *)
         echo "${vendor}/mulle-sde"
      ;;
   esac
}


extensions_get_home_config_dir()
{
   log_entry "extensions_get_home_config_dir" "$@"

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


# find extensions in
# ${MULLE_VIRTUAL_ROOT}/dependencies/libexec/mulle_sde/extensions
# ${MULLE_VIRTUAL_ROOT}/addictions/libexec/mulle_sde/extensions
# ${MULLE_VIRTUAL_ROOT}/libexec/mulle_sde/extensions
# ${HOME}/.config/mulle-sde/extensions (or elsewhere OS dependent)
# /usr/local/libexec/mulle_sde/extensions
# /usr/libexec/mulle_sde/extensions
#
extension_get_search_path()
{
   log_entry "extension_get_search_path" "$@"

   local vendor="$1"

   local vendorcomponent
   local extensionsdir
   local homeextensionsdir

   vendorcomponent="`extension_get_vendor_pathcomponent "${vendor}" `"
   extensionsdir="libexec/${vendorcomponent}/extensions"
   homeextensionsdir="`extensions_get_home_config_dir`/${vendorcomponent}/extensions"

   local s

   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      s="`colon_concat "$s" "${MULLE_VIRTUAL_ROOT}/dependencies/${extensionsdir}" `"
      s="`colon_concat "$s" "${MULLE_VIRTUAL_ROOT}/addictions/${extensionsdir}" `"
      s="`colon_concat "$s" "${MULLE_VIRTUAL_ROOT}/${extensionsdir}" `"
      s="`colon_concat "$s" "${homeextensionsdir}" `"
   else
      s="`colon_concat "$s" "${homeextensionsdir}" `"
      s="`colon_concat "$s" "/usr/local/${extensionsdir}" `"
      s="`colon_concat "$s" "/usr/${extensionsdir}" `"
   fi

   case "${vendor}" in
      ""|"mulle"|"mulle-sde")
         s="`colon_concat "$s" "${MULLE_SDE_LIBEXEC_DIR}/extensions" `"
      ;;
   esac

   log_fluff "extension search path: \"$s\""

   echo "$s"
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

   IFS=":"
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
            foundtype="`cat "${extensiondir}/type" 2> /dev/null `"
            log_debug "\"${extensiondir}\" purports to be of type \"${foundtype}\""

            if [ "${foundtype}" != "${extensiontype}" ]
            then
               log_debug "But we are looking for \"${extensiontype}\""
               continue
            fi
         fi
         rexekutor echo "${extensiondir}"
      done
      IFS="${DEFAULT_IFS}"

   done
   IFS="${DEFAULT_IFS}"
}


find_extension()
{
   log_entry "find_extension" "$@"

   local name="$1"
   local vendor="$2"

   local searchpath

   searchpath="`extension_get_search_path "${vendor}" `"

   local directory

   IFS=":"
   for directory in ${searchpath}
   do
      IFS="${DEFAULT_IFS}"
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

   IFS="${DEFAULT_IFS}"
   return 1
}


extensionnames_from_extension_dirs()
{
   log_entry "extensionnames_from_extension_dirs" "$@"

   local vendor="$1"
   local extensiondirs="$2"

   local directory

   IFS="
"
   for directory in ${extensiondirs}
   do
      echo "${vendor}:`basename -- "${directory}"`"
   done
   IFS="${DEFAULT_IFS}"
}


collect_extensions()
{
   log_entry "collect_extensions" "$@"

   local vendor="$1"
   local extensiontype="$2"

   local result

   result="`collect_extension_dirs "${vendor}" "${extensiontype}"`"
   result="`extensionnames_from_extension_dirs "${vendor}" "${result}" | sort -u`"

   if [ -z "${result}" ]
   then
      log_warning "No ${extensiontype} extensions found"
   else
      log_info "Available ${extensiontype} extensions:"
      echo "${result}"
   fi
}



###
### parameters and environment variables
###
sde_extensions_main()
{
   log_entry "sde_extensions_main" "$@"

   local OPTION_VENDOR="mulle"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_extensions_usage
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_extensions_usage
            shift

            OPTION_VENDOR="$1"
         ;;

         -*)
            sde_extensions_usage
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -gt 1 ] && sde_extensions_usage

   collect_extensions "${OPTION_VENDOR}" common
   collect_extensions "${OPTION_VENDOR}" runtime
   collect_extensions "${OPTION_VENDOR}" buildtool
}

