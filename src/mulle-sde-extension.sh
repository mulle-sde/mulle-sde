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
   add       : add an extra extension to your project
   list      : list available and installed extensions
   upgrade   : upgrade project extensions to the latest version
EOF
   exit 1
}


sde_extension_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension list [options] [type]

   List available mulle-sde extensions of types "meta" and "extra". Those are
   usually the candidates to select. The "meta" extension in tells mulle-sde
   to load the required "runtime" and "buildtool" extensions.

Options:
   --version   : show version of the extensions

Types:
   all       : list all available extensions
   buildtool : list available buildtool extensions
   extra     : list available extra extensions
   installed : list extensions installed in your project
   meta      : list available meta extensions
   runtime   : list available runtime extensions
EOF
   exit 1
}


sde_extension_add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} extension add <extension>

   Add an extension to your project. This extension must be of type "extra".
   To reconfigure your project with another runtime or buildtool, use
   \`${MULLE_USAGE_NAME} init\` to setup anew.
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
   --info        : list installable files for .mulle-sde/share
   --recurse     : show usage information of inherited extensions
EOF
   exit 1
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
      if [ ! -z "${vendor}" ]
      then
         i="${i}/${vendor}"
      fi
      s="${s}:${i}"
   done

   IFS="${DEFAULT_IFS}"; set +o noglob

   case "${vendor}" in
      "")
         extensionsdir="${MULLE_SDE_LIBEXEC_DIR}/extensions"
         s="$s:${extensionsdir}"
      ;;

      mulle-sde)
         extensionsdir="${MULLE_SDE_LIBEXEC_DIR}/extensions/${vendor}"
         s="$s:${extensionsdir}"
      ;;

      *)
         case "${MULLE_UNAME}" in
            darwin)
               # or what ?
               homeextensionsdir="${HOME}/Library/Preferences"
            ;;

            *)
               homeextensionsdir="${HOME}/.config"
            ;;
         esac

         homeextensionsdir="${homeextensionsdir}/mulle-sde/extensions/${vendor}"

         s="$s:${homeextensionsdir}"

         extensionsdir="share/mulle-sde/extensions/${vendor}"
         s="$s:/usr/local/${extensionsdir}"
         s="$s:/usr/${extensionsdir}"
      ;;
   esac

   case "$s" in
      :*)
         s="${s:1}"
      ;;
   esac

   log_debug "Extension search path for vendor \"${vendor}\": \"$s\""

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

#     log_debug "$directory: ${directory}"
      IFS="
"
      for extensiondir in `find "${directory}" -mindepth 1 -maxdepth 1 -type d -print`
      do
         IFS="${DEFAULT_IFS}"

#         log_debug "$extensiondir: ${extensiondir}"

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
      IFS=":"; set -o noglob
   done
   IFS="${DEFAULT_IFS}"
}


find_extension()
{
   log_entry "find_extension" "$@"

   local vendor="$1"
   local name="$2"

   case "${name}" in
      */*)
         internal_fail "Inherit \"${name}\" was not correctly parsed"
      ;;

      *:*)
         fail "Inherit \"${name}\" is in obsolete <vendor>:<extension> format. \
Use / separator"
      ;;
   esac

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
      else
         log_fluff "Extension \"${directory}/${name}\" is not there"
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
      echo "${vendor}/`basename -- "${directory}"`"
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


collect_inherit_extensiondirs()
{
   log_entry "collect_inherit_extensiondirs" "$@"

   local inherits="$1"

   local dependency
   local vendor
   local extension

   set -o noglob ; IFS="
"
   for dependency in ${inherits}
   do
      set +o noglob ; IFS="${DEFAULT_IFS}"

      case "${dependency}" in
         "")
            continue
         ;;

         */*)
            vendor="${dependency%%/*}"
            extension="${dependency##*/}"
         ;;

         *)
            fail "Inherit \"${dependency}\" must be fully qualified <vendor>/<extension>"
         ;;
      esac

      if ! find_extension "${vendor}" "${extension}"
      then
         log_warning "Inheriting unknown extension \"${vendor}/${extension}\""
      fi
   done
   set +o noglob ; IFS="${DEFAULT_IFS}"
}


_extension_get_version()
{
   log_entry "_extension_get_version" "$@"

   local vendor="$1"
   local name="$2"

   local directory

   directory="`find_extension "${vendor}" "${name}"`"
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
   local result="$1"
   local extensiontype="$2"
   local comment="$3"

   if [ -z "${result}" ]
   then
      log_fluff "No ${extensiontype} extensions found"
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

      if [ "${OPTION_VERSION}" = "YES" ]
      then
         version="`extension_get_version "${extension}"`"
         echo "${extension}" "${version}"
      else
         echo "${extension}"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


sde_extension_list_main()
{
   log_entry "sde_extension_list_main" "$@"

   local OPTION_VERSION

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_list_usage
         ;;

         --version)
            OPTION_VERSION="YES"
         ;;

         -*)
            sde_extension_list_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd

   cmd="${1:-default}"

   case "${cmd}" in
      installed)
         if [ "${OPTION_VERSION}" = "YES" ]
         then
            sde_extension_list_installed --version "$@"
         else
            sde_extension_list_installed "$@"
         fi
         return
      ;;
   esac

   local runtime_extension
   local buildtool_extension
   local meta_extension
   local extra_extension
   local vendor

   local all_vendors

   all_vendors="`extension_get_vendors`"

   log_verbose "Available vendors:"
   log_verbose "`sort -u <<< "${all_vendors}"`"

   set -o noglob ; IFS="
"
   for vendor in ${all_vendors}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ -z "${vendor}" ]
      then
         continue
      fi

      case "${cmd}" in
         all|default|meta)
            tmp="`collect_extension "${vendor}" meta `"  || return 1
            meta_extension="`add_line "${meta_extension}" "${tmp}" `"  || return 1
         ;;
      esac

      case "${cmd}" in
         all|default|extra)
            tmp="`collect_extension "${vendor}" extra `" || return 1
            extra_extension="`add_line "${extra_extension}" "${tmp}" `"  || return 1
         ;;
      esac

      case "${cmd}" in
         all|runtime)
            tmp="`collect_extension "${vendor}" runtime `"  || return 1
            runtime_extension="`add_line "${runtime_extension}" "${tmp}" `"  || return 1
         ;;
      esac

      case "${cmd}" in
         all|buildtool)
            tmp="`collect_extension "${vendor}" buildtool `" || return 1
            buildtool_extension="`add_line "${buildtool_extension}" "${tmp}" `"  || return 1
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   emit_extension "${meta_extension}" "meta" "[-m <extension>]"
   emit_extension "${runtime_extension}" "runtime" "[-r <extension>]"
   emit_extension "${buildtool_extension}" "buildtool" "[-b <extension>]"
   emit_extension "${extra_extension}" "extra" "[-e <extension>]*"

  :
}


sde_extension_list_installed()
{
   log_entry sde_extension_list_installed "$@"

   local OPTION_VERSION

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_extension_list_usage
         ;;

         --version)
            OPTION_VERSION="YES"
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

   if [ ! -d "${MULLE_SDE_DIR}/share/version" ]
   then
      if [ ! -d "${MULLE_SDE_DIR}/share" ]
      then
         if [ ! -d "${MULLE_SDE_DIR}" ]
         then
            fail "\"${PWD}\" doesn't look like \
a mulle-sde project"
         fi

         if [ -d "${MULLE_SDE_DIR}/share.old" ]
         then
            fail "\"${PWD}\" looks like a borked extension upgrade"
         fi
      fi
      log_warning "No extensions installed"
      return 0
   fi

   log_info "Installed Extensions"

   (
      IFS="
"
      for filename in `find "${MULLE_SDE_DIR}/share/version" -type f -print`
      do
         IFS="${DEFAULT_IFS}"

         extension="`fast_basename "${filename}"`"
         vendor="`fast_dirname "${filename}"`"
         vendor="`fast_basename "${vendor}"`"

         if [ "${OPTION_VERSION}" = "YES" ]
         then
            version="`LC_ALL=C egrep -v '^#' < "${filename}"`"
            echo "${vendor}/${extension}" "${version}"
         else
            echo "${vendor}/${extension}"
         fi
      done
      IFS="${DEFAULT_IFS}"
   ) | sort
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

   extensiondir="`find_extension "${vendor}" "${extension}"`" \
         || fail "Unknown extension \"${vendor}/${extension}\""


   inherits="`collect_extension_inherits "${extensiondir}"`"
}


__emit_extension_list_types()
{
   local extensiondir="$1"
   local regexp="$2"

   local projectdir
   local name

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

      name="`fast_basename "${projectdir}"`"
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

   if [ "${OPTION_LIST_TYPES}" = "YES" ]
   then
       collect_extension_projecttypes "${extensiondir}"
       return
   fi

   local exttype

   exttype="`LC_ALL=C egrep -v '^#' < "${extensiondir}/type"`"

   if [ "${OPTION_USAGE_ONLY}" != "YES" ]
   then
      echo "Usage:"
      echo "   mulle-sde init --${exttype}" "${vendor}/${extension} <type>"
      echo
   fi

   local usagetext

   usagetext="`collect_file_info "${extensiondir}" "usage"`"


   if [ "${OPTION_USAGE_ONLY}" != "YES" ]
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

   if [ "${OPTION_USAGE_ONLY}" = "YES" ]
   then
      if [ ! -z "${usagetext}" ]
      then
         sed 's/^/   /' <<< "${usagetext}"
      fi
      return
   fi

   local text

   text="`collect_extension_projecttypes "${extensiondir}"`"
   text="${text:-none}"

   echo "Types:"
   sed 's/^/   /' <<< "${text}"
   echo

   text="`collect_extension_inherits "${extensiondir}"`"
   text="${text:-none}"

   echo "Inherits:"
   text="${inherit_text:-none}"
   sed 's/^/   /' <<< "${text}"
   echo

   if [ "${OPTION_INFO}" = "YES" ]
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

   if [ "${OPTION_RECURSE}" = "YES" ]
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
         if [ "${OPTION_LIST_TYPES}" = "NO" ]
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
   local OPTION_LIST_TYPES="NO"
   local OPTION_INFO="NO"
   local OPTION_RECURSE="NO"
   local OPTION_USAGE_ONLY="NO"
   local OPTION_NO_USAGE="NO"

   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_extension_usage_usage
         ;;

         -i|--info)
            OPTION_INFO="YES"
         ;;

         -l|--list)
            [ $# -eq 1 ] && sde_extension_usage_usage "missing argument to \"$1\""
            shift

            OPTION_LIST="$1"
         ;;

         -r|--recurse)
            OPTION_RECURSE="YES"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_extension_usage_usage "missing argument to \"$1\""
            shift

            OPTION_VENDOR="$1"
         ;;

         --usage-only)
            OPTION_USAGE_ONLY="YES"
         ;;

         --list-types)
            OPTION_LIST_TYPES="YES"
         ;;

         -*)
            sde_extension_usage_usage "unknown option \"$1\""
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

   if [ "${OPTION_LIST_TYPES}" = "YES" ]
   then
      emit_extension_usage "${extension}" | sort -u
   else
      emit_extension_usage "${extension}"
   fi
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
            sde_extension_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"
   [ $# -ne 0 ] && shift

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

   case "${cmd:-list}" in
      add)
         # shellcheck source=src/mulle-sde-upgrade.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} extension add" \
            sde_init_main --no-blurb --no-env --add --extra "$@"
      ;;

      list)
         sde_extension_list_main "$@"
      ;;

      searchpath)
         extension_get_search_path
      ;;

      upgrade)
         # shellcheck source=src/mulle-sde-upgrade.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-upgrade.sh"

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

