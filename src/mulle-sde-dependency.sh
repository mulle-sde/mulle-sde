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
   I will be built along with your project. Dependencies are managed with
   mulle-sourcetree. The build definitions for a dependency are managed with
   mulle-make.

Commands:
   add        : add a dependency to the sourcetree
   definition : change build options for the dependency
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
   --branch <name> : specify branch to checkout for git repositories
   --embedded      : the dependency source code is not built
   --headerless    : the dependency has no headerfile
   --headeronly    : the dependency has no library
   --if-missing    : if a node with the same address is present, do nothing
   --plain         : do not enhance URLs with environment variables
      (see: mulle-sourcetree -v add -h for more information about options)
EOF
  exit 1
}

sde_dependency_buildinfo_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency definition [option] <url> <command>

   Manage a dependencys build settings. These will be stored in a folder
   inside "buildinfo" at the top of your project. mulle-sde uses a "oneshot"
   extension mulle-sde/buildinfo to create that subfolder.

   The values in this "buildinfo" folder are manipulated using mulle-make
   (see \`mulle-make definition help\` for more info).

   Eventually the "buildinfo" contents are used by \`mulle-craft\` to populate
   the \`dependency/share/mulle-craft\` folder and override any \`.mulle-make\`
   folders. That's all fairly complicated, but it's necessary to have proper
   setting inheritance across multiple projects.

   Example:
      mulle-sde dependency buildinfo --global set -+ subproject/nng \
                  CPPFLAGS "-DNNG_ENABLE_TLS=ON"

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


sde_dependency_set_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency set [options] <url> <key> <value>

   Modify a dependency's settings, which is referenced by its url.

   Examples:
      ${MULLE_USAGE_NAME} dependency set --append pthreads aliases pthread

Options:
   --append    : append value instead of set

Keys:
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


sde_dependency_get_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency get <url> <key>

   Retrieve dependency settings by its url.

   Examples:
      ${MULLE_USAGE_NAME} dependency get pthreads aliases

Keys:
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
            sde_dependency_set_usage "unknown option \"$1\""
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
         log_error "unknown field name \"${field}\""
         sde_dependency_set_usage
      ;;
   esac
}


sde_dependency_get_main()
{
   log_entry "sde_dependency_get_main" "$@"

   local url="$1"
   [ -z "${url}" ]&& sde_dependency_get_usage "missing url"
   shift

   local field="$1"
   [ -z "${field}" ] && sde_dependency_get_usage "missing field"
   shift

   case "${field}" in
      os-excludes)
         sourcetree_get_os_excludes "${url}"
      ;;

      *)
         log_error "unknown field name \"${field}\""
         sde_dependency_get_usage
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
            sde_dependency_list_usage "unknown option \"$1\""
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

   _url=""
   _branch=""
   _address=""
   _nodetype=""

   if [ -z "${nodetype}" ]
   then
      nodetype="`${MULLE_SOURCETREE} -V typeguess "${url}"`" || exit 1
      [ -z "${nodetype}" ] && fail "Specify --nodetype with this kind of URL"
   fi

   if [ -z "${address}" ]
   then
      address="`${MULLE_SOURCETREE} -V nameguess --nodetype "${nodetype}" "${url}"`"  || exit 1
   fi

   #
   # create a convenient URL that can be substituted with env
   # variables. Easy to do for git. For tar archives not so much
   #
   local upcaseid

   upcaseid="`tr 'a-z-' 'A-Z_' <<< "${address}"`"

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

         --plain)
            OPTION_ENHANCE="NO"
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
   [ -z "${url}" ] && sde_dependency_add_usage "Missing url"
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

sde_add_buildinfo_subproject_if_needed()
{
   log_entry "sde_add_buildinfo_subproject_if_needed" "$@"

   local subprojectdir="$1"
   local name="$2"

   if [ ! -d "${subprojectdir}" ]
   then
     # shellcheck source=src/mulle-sde-common.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh"

      sde_extension_main pimp --oneshot-name "${name}" mulle-sde/buildinfo || exit 1
   fi

   [ -d "${subprojectdir}" ] || \
      internal_fail "did not produce \"${subprojectdir}\""

   if exekutor "${MULLE_SOURCETREE}" -V add --if-missing \
         --marks "no-update,no-delete,no-share,no-header,no-link" \
         --nodetype "local" \
         "${subprojectdir}"
   then
      exekutor "${MULLE_SOURCETREE}" -V move "${subprojectdir}" top
   fi
}


sde_dependency_buildinfo_main()
{
   log_entry "sde_dependency_buildinfo_main" "$@"

   local extension

   extension=".${MULLE_UNAME}"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_buildinfo_usage
         ;;

         --global)
            extension=""
         ;;

         --platform)
            [ "$#" -eq 1 ] && sde_dependency_buildinfo_usage "Missing argument to \"$1\""
            shift

            extension=".$1"
         ;;

         -*)
            sde_dependency_buildinfo_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_dependency_buildinfo_usage "Missing address"

   local url="$1"; shift

   [ $# -eq 0 ] && sde_dependency_buildinfo_usage "Missing subcommand after dependency \"$url\""

   local subcmd="$1"; shift

   local folder
   local address

   address="`exekutor "${MULLE_SOURCETREE}" -V get --url-addressing "${url}"`"
   if [ -z "${address}" ]
   then
      address="${url}"
   fi

   [ -z "${address}" ] && fail "Invalid url or address"

   local subprojectdir
   local name

   name="`fast_basename "${address}"`"
   subprojectdir="buildinfo/${name}"

   case "${subcmd}" in
      set)
         sde_add_buildinfo_subproject_if_needed "${subprojectdir}" "${name}"
      ;;

      get|list)
      ;;

      *)
        sde_dependency_buildinfo_usage "Unknown subcommand \"${subcmd}\""
      ;;
   esac

   local folder

   folder="${subprojectdir}/mulle-make${extension}"

   if [ -z "${MULLE_MAKE}" ]
   then
      MULLE_MAKE="${MULLE_MAKE:-`command -v mulle-make`}"
      [ -z "${MULLE_MAKE}" ] && fail "mulle-make not in PATH"
   fi

   exekutor "${MULLE_MAKE}" ${MULLE_MAKE_FLAGS} \
      definition --info-dir "${folder}" "${subcmd}" "$@"
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
            fail "unknown option \"$1\""
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

   case "${cmd:-list}" in
      add)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_add_main "$@"
         return $?
      ;;

      definition)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_buildinfo_main "$@"
         return $?
      ;;

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_get_main "$@"
         return $?
      ;;

      list)
         sde_dependency_list_main "$@"
      ;;

      mark|move|remove|unmark)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE}" -V -s ${MULLE_SOURCETREE_FLAGS} ${cmd} "$@"
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
         log_error "Unknown command \"${cmd}\""
         sde_dependency_usage
      ;;
   esac
}
