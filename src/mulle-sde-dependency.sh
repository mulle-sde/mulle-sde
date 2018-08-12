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
MULLE_SDE_DEPENDENCY_SH="included"


DEPENDENCY_MARKS="dependency,delete"  # with delete we filter out subprojects
DEPENDENCY_LIST_MARKS="dependency"
DEPENDENCY_LIST_NODETYPES="no-none,no-local,ALL"


sde_dependency_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency [command]

   A dependency is a third party package, that is fetched via an URL.
   It will be built along with your project. Dependencies are managed with
   mulle-sourcetree. The build definitions for a dependency are managed with
   mulle-make.

Commands:
   add        : add a dependency to the sourcetree
   craftinfo  : change build options for the dependency
   get        : retrieve dependency sourcetree settings
   list       : list dependencies (default)
   mark       : add marks to a dependency
   move       : reorder dependencies
   remove     : remove a dependency
   set        : change dependency settings
   unmark     : remove marks from a dependency
         (use <command> -h for more help about commands)
EOF
   exit 1
}



sde_dependency_add_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency add [options] <url>

   Add a dependency to your project. A dependency is a git repository or
   a tar or zip archive (more options may be available if
   additional mulle-fetch plugins have been installed).

   The default dependency is a library with a headerfile.

   Example:
      ${MULLE_USAGE_NAME} dependency add https://github.com/mulle-c/mulle-allocator.git

Options:
   --embedded      : the dependency becomes part of the local project
   --headerless    : has no headerfile
   --headeronly    : has no library
   --if-missing    : if a node with the same address is present, do nothing
   --objc          : used for Objective-C dependencies
   --optional      : is not required to exist
   --plain         : do not enhance URLs with environment variables
   --private       : headers are not visible to API consumers
      (see: mulle-sourcetree -e -v add -h for more add options)
EOF
  exit 1
}


sde_dependency_set_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency set [options] <dep> <key> <value>

   Modify a dependency's settings. The dependency is referenced by its url or
   address.

   Examples:
      ${MULLE_USAGE_NAME} dependency set --append pthreads aliases pthread

Options:
   --append    : append value instead of set

Keys:
   aliases     : alternate names of dependency, separated by comma
   include     : alternative include filename instead of <name>.h
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_dependency_get_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency get <dep> <key>

   Retrieve a dependency settings value given a key. Specify the dependency
   with its url or address.

   Examples:
      ${MULLE_USAGE_NAME} dependency get pthreads aliases

Keys:
   aliases     : alternate names of dependency, separated by comma
   include     : alternative include filename instead of <name>.h
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_dependency_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency list [options]

   List dependencies of this project.

Options:
   --command : list dependencies as mulle-sourcetree commands
   --url     : show URL
EOF
   exit 1
}


sde_dependency_craftinfo_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo [option] <dep> <command>

   Manage build settings of a dependency. Thy will be stored in a subproject
   in your project inside a mulle-sde created folder "craftinfo". This is done
   for you automatically on the first setting add.

   mulle-sde uses a "oneshot" extension mulle-sde/craftinfo to create that
   subproject.

   The dependency can be specified by URL or by its address.

EOF

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
   then
      cat <<EOF >&2
   Eventually the "craftinfo" contents are used by \`mulle-craft\` to populate
   the \`dependency/share/mulle-craft\` folder and override any \`.mulle-make\`
   folders. That's all fairly complicated, but it's necessary to have proper
   setting inheritance across multiple nested projects.
EOF
   else
      echo "   (use -v to see more help)"
   fi

      cat <<EOF >&2
Commands:
   get               : retrieve a build setting for dependency with url
   list              : list builds settings
   set               : set a build setting

Options:
   --global          : use global settings instead of current platform settings
   --platform <name> : specify settings for a specific platform

EOF
  exit 1
}


sde_dependency_craftinfo_set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo <dep> set [option] <key> <value>

   Set a setting value for key. This will automatically create a proper
   "craftinfo" subproject for you, if there is none yet.

   See \`mulle-make definition help\` for more info about manipulating
   craftinfo settings.

   Example:
      mulle-sde dependency craftinfo nng --global set --append CPPFLAGS "-DX=0"

Options:
   --append : value will be appended to CPPFLAGS

EOF
  exit 1
}


sde_dependency_craftinfo_get_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo <url> get <key>

   Read setting if key.

   Example:
      mulle-sde dependency craftinfo nng --global get CPPFLAGS

EOF
  exit 1
}


sde_dependency_craftinfo_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo list <dep>

   List build settings of a dependency. By default the global settings and
   those for the current platform are listed. To see other platform settings
   use the "--platform" option of \`dependency craftinfo\`.

EOF
  exit 1
}


#
#
#
sde_dependency_set_main()
{
   log_entry "sde_dependency_set_main" "$@"

   local OPTION_APPEND="NO"

   while :
   do
      case "$1" in
         -a|--append)
            OPTION_APPEND="YES"
         ;;

         -*)
            sde_dependency_set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && sde_dependency_set_usage "missing address"
   shift

   local field="$1"
   [ -z "${field}" ] && sde_dependency_set_usage "missing field"
   shift

   local value="$1"

   case "${field}" in
      os-excludes)
         _sourcetree_set_os_excludes "${address}" \
                                     "${value}" \
                                     "${DEPENDENCY_MARKS}" \
                                     "${OPTION_APPEND}"
      ;;

      aliases|include)
         _sourcetree_set_userinfo_field "${address}" \
                                        "${field}" \
                                        "${value}" \
                                        "${OPTION_APPEND}"
      ;;

      *)
         fail "Unknown field name \"${field}\""
      ;;
   esac
}


sde_dependency_get_main()
{
   log_entry "sde_dependency_get_main" "$@"

   local url="$1"
   [ -z "${url}" ]&& sde_dependency_get_usage "missing url"
   shift

   local field="$1";
   [ -z "${field}" ] && sde_dependency_get_usage "missing field"
   shift

   case "${field}" in
      os-excludes)
         sourcetree_get_os_excludes "${url}"
      ;;

      aliases|include)
         sourcetree_get_userinfo_field "${url}" "${field}"
      ;;
   esac
}


sde_dependency_list_main()
{
   log_entry "sde_dependency_list_main" "$@"

   local marks
   local formatstring

   formatstring="%a;%m;%i={aliases,,-------}"
   marks="${DEPENDENCY_MARKS}"

   local OPTION_OUTPUT_COMMAND="NO"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_list_usage
         ;;

         --name-only)
            formatstring="%a"
         ;;

         --url)
            formatstring="${formatstring};%u"
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde_dependency_list_usage "Missing argument to \"$1\""
            shift

            marks="`comma_concat "${marks}" "$1"`"
         ;;

         --output-cmd|--output-command|--command)
            OPTION_OUTPUT_COMMAND="YES"
         ;;

         --)
            # pass rest to mulle-sourcetree
            shift
            break
         ;;

         -*)
            sde_dependency_list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_OUTPUT_COMMAND}" = "YES" ]
   then
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE}" -V -s ${MULLE_SOURCETREE_FLAGS} list \
            --marks "${DEPENDENCY_LIST_MARKS}" \
            --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
            --output-eval \
            --output-cmd \
            --output-no-column \
            --output-no-header \
            --output-no-marks "${DEPENDENCY_MARKS}" \
            "$@"
   else
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE}" -V -s ${MULLE_SOURCETREE_FLAGS} list \
            --format "${formatstring}\\n" \
            --marks "${DEPENDENCY_LIST_MARKS}" \
            --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
            --output-no-marks "${DEPENDENCY_MARKS}" \
            "$@"
   fi
}


#
# return values in globals
#    _url
#    _address
#    _nodetype
#    _address
#
_sde_enhance_url()
{
   log_entry "_sde_enhance_url" "$@"

   local url="$1"
   local branch="$2"
   local nodetype="$3"
   local address="$4"


   if [ -z "${nodetype}" ]
   then
      nodetype="`${MULLE_SOURCETREE} -V typeguess "${url}"`" || exit 1
      [ -z "${nodetype}" ] && fail "Specify --nodetype with this kind of URL"
   fi

   if [ -z "${address}" ]
   then
      address="`${MULLE_SOURCETREE} -V nameguess --nodetype "${nodetype}" "${url}"`"  || exit 1
      if [ -z "${address}" ]
      then
         fail "Specify --address with this kind of URL"
      fi
   fi

   _url=""
   _branch=""
   _address=""
   _nodetype=""

   #
   # create a convenient URL that can be substituted with env
   # variables. Easy to do for git. For tar archives not so much
   #
   local upcaseid

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"      || return 1
   fi

   upcaseid="`tweaked_de_camel_case "${address}"`"
   upcaseid="`printf "%s" "${upcaseid}" | tr -c 'a-zA-Z0-9' '_'`"
   upcaseid="`tr 'a-z' 'A-Z' <<< "${upcaseid}"`"

   local last
   local leading
   local extension

   case "${nodetype}" in
      git)
         if [ ! -z "${branch}" ]
         then
            _branch="\${${upcaseid}_BRANCH:-${branch}}"
         else
            _branch="\${${upcaseid}_BRANCH}"
         fi
      ;;

      tar|zip)
         [ ! -z "${branch}" ] && fail "The branch must be specified in the URL for archives."

         case "${url}" in
            # format .../branch.tar.gz or so
            *github.com/*)
               last="${url##*/}"         # basename
               leading="${url%${last}}"  # dirname
               branch="${last%%.*}"
               extension="${last#*.}"   # dirname

               url="${leading}\${${upcaseid}_BRANCH:-${branch}}.${extension}"
            ;;

            # format .../branch
         *mulle-kybernetik*/git/*)
               last="${url##*/}"         # basename
               leading="${url%${last}}"  # dirname
               branch="${last%%.*}"

               url="${leading}\${${upcaseid}_BRANCH:-${branch}}"
            ;;
         esac
      ;;
   esac

   # common wrapper for archive and repository
   _url="\${${upcaseid}_URL:-${url}}"
   _nodetype="${nodetype}"
   _address="${address}"
}


sde_dependency_add_main()
{
   log_entry "sde_dependency_add_main" "$@"

   local options
   local nodetype
   local address
   local branch
   local marks="${DEPENDENCY_MARKS}"

   local OPTION_ENHANCE="YES"     # enrich URL
   local OPTION_DIALECT="c"
   local OPTION_PRIVATE="NO"
   local OPTION_SHARE="YES"
   local OPTION_OPTIONAL="NO"

   #
   # grab options for mulle-sourcetree
   # interpret sde options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_add_usage
         ;;

         --if-missing)
            options="`concat "${options}" "--if-missing"`"
         ;;

         --header-less|--headerless)
            marks="`comma_concat "${marks}" "no-header"`"
         ;;

         --header-only|--headeronly)
            marks="`comma_concat "${marks}" "no-link"`"
         ;;

         --embedded)
            marks="`comma_concat "${marks}" "no-build,no-header,no-link,no-share"`"
         ;;

         -c|--c)
            OPTION_DIALECT="c"
         ;;

         -m|--objc)
            OPTION_DIALECT="objc"
         ;;

         --plain)
            OPTION_ENHANCE="NO"
         ;;

         --private)
            OPTION_PRIVATE="YES"
         ;;

         --public)
            OPTION_PRIVATE="NO"
         ;;

         --optional)
            OPTION_OPTIONAL="YES"
         ;;

         --branch)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            branch="$1"
         ;;

        --nodetype|--scm)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            nodetype="$1"
         ;;

         --address)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            address="$1"
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            marks="`comma_concat "${marks}" "$1"`"
         ;;

         --url)
            fail "Can't have --url here. Specify the URL as the last argument"
         ;;

         --*)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""

            options="`concat "${options}" "$1 '$2'"`"
            shift
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local url="$1"

   [ -z "${url}" ] && sde_dependency_add_usage "URL argument is missing ($*)"
   shift

   [ "$#" -eq 0 ] || sde_dependency_add_usage "Superflous arguments \"$*\""

   if [ "${OPTION_ENHANCE}" = "YES" ]
   then
      case "${nodetype}" in
         local|symlink|file)
            # no embellishment here
         ;;

         *)
            _sde_enhance_url "${url}" "${branch}" "${nodetype}" "${address}"

            url="${_url}"
            branch="${_branch}"
            nodetype="${_nodetype}"
            address="${_address}"
         ;;
      esac
   fi

   case "${OPTION_DIALECT}" in
      c)
         marks="`comma_concat "${marks}" "no-import,no-all-load" `"
      ;;
   esac

   if [ "${OPTION_PRIVATE}" = "YES" ]
   then
      marks="`comma_concat "${marks}" "no-public" `"
   fi

   if [ "${OPTION_OPTIONAL}" = "YES" ]
   then
      marks="`comma_concat "${marks}" "no-require" `"
   fi

   if [ ! -z "${nodetype}" ]
   then
      options="`concat "${options}" "--nodetype '${nodetype}'"`"
   fi
   if [ ! -z "${address}" ]
   then
      options="`concat "${options}" "--address '${address}'"`"
   fi
   if [ ! -z "${branch}" ]
   then
      options="`concat "${options}" "--branch '${branch}'"`"
   fi
   if [ ! -z "${marks}" ]
   then
      options="`concat "${options}" "--marks '${marks}'"`"
   fi

   log_verbose "Dependency: ${url}"
   eval_exekutor "${MULLE_SOURCETREE}" -V \
                     "${MULLE_TECHNICAL_FLAGS}"\
                     "${MULLE_SOURCETREE_FLAGS}" \
                        add "${options}" "'${url}'"
}


sde_add_craftinfo_subproject_if_needed()
{
   log_entry "sde_add_craftinfo_subproject_if_needed" "$@"

   local subprojectdir="$1"
   local name="$2"

   if [ -d "${subprojectdir}" ]
   then
      return 0
   fi
  # shellcheck source=src/mulle-sde-common.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh"

   sde_extension_main pimp --oneshot-name "${name}" mulle-sde/craftinfo || return 1

   [ -d "${subprojectdir}" ] || \
      internal_fail "did not produce \"${subprojectdir}\""

   exekutor "${MULLE_SOURCETREE}" -V ${MULLE_SOURCETREE_FLAGS} add --if-missing \
         --marks "no-update,no-delete,no-share,no-header,no-link" \
         --nodetype "local" \
         "${subprojectdir}"  || return 1

   exekutor "${MULLE_SOURCETREE}" -V ${MULLE_SOURCETREE_FLAGS} move "${subprojectdir}" top || return 1
}


#
# local _address
# local _name
# local _subprojectdir
# local _folder
#
__sde_craftinfo_vars_with_url_or_address()
{
   log_entry "sde_url_or_address_to_address" "$@"

   local url="$1"
   local extension="$2"

   _address="`exekutor "${MULLE_SOURCETREE}" -V get --url-addressing "${url}"`"
   if [ -z "${_address}" ]
   then
      _address="${url}"
   fi

   [ -z "${_address}" ] && fail "Empty url or address"

   _name="`fast_basename "${_address}"`"
   _subprojectdir="craftinfo/${_name}"
   _folder="${_subprojectdir}/${_name}${extension}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}"  = "YES" ]
   then
      log_trace2 "_name:          ${_name}"
      log_trace2 "_address:       ${_address}"
      log_trace2 "_subprojectdir: ${_subprojectdir}"
      log_trace2 "_folder:        ${_folder}"
   fi
}


sde_dependency_craftinfo_set_main()
{
   log_entry "sde_dependency_craftinfo_set_main" "$@"

   local url="$1"; shift
   local extension="$1"; shift

   local OPTION_APPEND="NO"
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_set_usage
         ;;

         --append|-a)
            OPTION_APPEND="YES"
         ;;

         -*)
            sde_dependency_craftinfo_set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] && sde_dependency_craftinfo_set_usage "Missing key"
   [ "$#" -eq 1 ] && sde_dependency_craftinfo_set_usage "Missing value"
   [ "$#" -gt 2 ] && sde_dependency_craftinfo_set_usage "Superflous arguments \"$*\""

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=".${MULLE_UNAME}"
   fi

   local _address
   local _name
   local _subprojectdir
   local _folder

   __sde_craftinfo_vars_with_url_or_address "${url}" "${extension}"

   sde_add_craftinfo_subproject_if_needed "${_subprojectdir}" "${_name}" || exit 1

   local setflags

   if [ "${OPTION_APPEND}" = "YES" ]
   then
      setflags="-+"
   fi

   exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
      definition --info-dir "${_folder}" set ${setflags} "$@"

}


sde_dependency_craftinfo_get_main()
{
   log_entry "sde_dependency_craftinfo_list_main" "$@"

   local url="$1"; shift
   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_get_usage
         ;;


         -*)
            sde_dependency_craftinfo_get_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_dependency_craftinfo_get_usage "Missing key"

   local _address
   local _name
   local _subprojectdir
   local _folder
   local rval

   if [ "${extension}" = "DEFAULT" ]
   then
      __sde_craftinfo_vars_with_url_or_address "${url}" ""
      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
         definition --info-dir "${_folder}.${MULLE_UNAME}" get "$@"
      rval=$?
      if [ $rval -ne 2 ]
      then
         return $rval
      fi

      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
         definition --info-dir "${_folder}" get "$@"
      return $?
   fi

   __sde_craftinfo_vars_with_url_or_address "${url}" "${extension}"

   exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
      definition --info-dir "${_folder}" get "$@"
}


sde_dependency_craftinfo_list_main()
{
   log_entry "sde_dependency_craftinfo_list_main" "$@"

   local url="$1"; shift
   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_list_usage
         ;;

         -*)
            sde_dependency_craftinfo_list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local _address
   local _name
   local _subprojectdir
   local _folder

   if [ "${extension}" = "DEFAULT" ]
   then
      __sde_craftinfo_vars_with_url_or_address "${url}" ""
      log_info "Global"
      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
         definition --info-dir "${_folder}" list "$@"
      log_info "${MULLE_UNAME}"
      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
         definition --info-dir "${_folder}.${MULLE_UNAME}" list "$@"
      return
   fi

   __sde_craftinfo_vars_with_url_or_address "${url}" "${extension}"

   log_info "${extension:-Global}"
   exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
      definition --info-dir "${_folder}" list "$@"
}


sde_dependency_craftinfo_main()
{
   log_entry "sde_dependency_craftinfo_main" "$@"

   local extension

   extension="DEFAULT"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_usage
         ;;

         --global)
            extension=""
         ;;

         --platform)
            [ "$#" -eq 1 ] && sde_dependency_craftinfo_usage "Missing argument to \"$1\""
            shift

            extension=".$1"
         ;;

         -*)
            sde_dependency_craftinfo_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_dependency_craftinfo_usage "Missing dependency craftinfo command"

   local subcmd="$1"
   shift

   [ $# -eq 0 ] && sde_dependency_craftinfo_usage "Missing url or address argument"

   local url="$1"
   shift

   if [ -z "${MULLE_MAKE}" ]
   then
      MULLE_MAKE="${MULLE_MAKE:-`command -v mulle-make`}"
      [ -z "${MULLE_MAKE}" ] && fail "mulle-make not in PATH"
   fi

   case "${subcmd:-list}" in
      set|get|list)
         sde_dependency_craftinfo_${subcmd}_main "${url}" "${extension}" "$@"
      ;;

      *)
        sde_dependency_craftinfo_usage "Unknown dependency craftinfo command \"${subcmd}\""
      ;;
   esac
}


###
### parameters and environment variables
###
sde_dependency_main()
{
   log_entry "sde_dependency_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_dependency_usage
         ;;

         -*)
            fail "Unknown option \"$1\""
            sde_dependency_usage
         ;;

         --)
            # pass rest to mulle-sourcetree
            shift
            break
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
      add)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_add_main "$@"
         return $?
      ;;

      commands)
         echo "\
add
craftinfo
get
list
map
mark
move
remove
set
unmark"
      ;;

      craftinfo)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_craftinfo_main "$@"
         return $?
      ;;

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_get_main "$@"
         return $?
      ;;


      keys)
         echo "\
aliases
include
os-excludes"
         return 0
      ;;

      list)
         sde_dependency_list_main "$@"
      ;;

      mark|move|remove|unmark)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE}" -V ${MULLE_SOURCETREE_FLAGS} \
                            "${cmd}" \
                            "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_set_main "$@"
         return $?
      ;;

      "")
         sde_dependency_usage
      ;;

      *)
         sde_dependency_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
