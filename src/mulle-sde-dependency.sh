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


DEPENDENCY_MARKS="no-cmake-include"


sde_dependency_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dependency [options] [command]

   A dependency is a third party package, that is fetched via an URL.
   I will be built along with your project.

Options:
   -h           : show this usage

Commands:
   add <url>    : add a dependency
   remove <url> : remove a dependency
   list         : list dependencies (default)
         (use <command> -h for more help about commands)
EOF
   exit 1
}



sde_dependency_add_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dependency add [options] <url>

   Add a dependency to your project. A dependency is a git repository or
   a tar or zip archive (more options may be available if
   additional mulle-fetch plugins have been installed).

   The default dependency is a library with a headerfile.

   Example:
      ${MULLE_EXECUTABLE_NAME} dependency add https://github.com/mulle-c/mulle-allocator.git

Options:
   --branch <name> : specify branch to checkout for git repositories
   --cmake-include : provides a CMakeDependenciesAndLibraries.cmake include
   --embedded      : the dependency source code is not built
   --headerless    : the dependency has no headerfile
   --headeronly    : the dependency has no library
   --if-missing    : if a node with the same address is present, do nothing
   --plain         : do not enhance URLs with environment variables
      (see: mulle-sourcetree -v add -h for more information about options)
EOF
  exit 1
}


sde_dependency_set_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dependency set [options] <url> <key> <value>

   Modify a dependency's settings, which is referenced by its url.

   Examples:
      ${MULLE_EXECUTABLE_NAME} dependency set --append pthreads aliases pthread

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
   ${MULLE_EXECUTABLE_NAME} dependency get <url> <key>

   Retrieve dependency settings by its url.

   Examples:
      ${MULLE_EXECUTABLE_NAME} dependency get pthreads aliases

Keys:
   os-excludes : names of OSes to exclude, separated by comma
EOF
  exit 1
}


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
                                     "${LIBRARY_MARKS}" \
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
      nodetype="`${MULLE_SOURCETREE} typeguess "${url}"`" || exit 1
      [ -z "${nodetype}" ] && fail "Specify --nodetype with this kind of URL"
   fi

   if [ -z "${address}" ]
   then
      address="`${MULLE_SOURCETREE} nameguess --nodetype "${nodetype}" "${url}"`"  || exit 1
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
         _branch="\${${upcaseid}_BRANCH:-${branch}}"
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
            sde_dependency_usage
         ;;

         --cmake-include)
            marks="`sed -e 's/,no-cmake-include//'
                        -e 's/no-cmake-include//' <<< "${marks}"`"
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
            marks="`comma_concat "${marks}" "no-share,no-build"`"
         ;;

         --plain)
            OPTION_ENHANCE="NO"
         ;;

         --branch)
            [ "$#" -eq 1 ] && sde_dependency_usage "missing argument to \"$1\""
            shift

            branch="$1"
         ;;

         --nodetype)
            [ "$#" -eq 1 ] && sde_dependency_usage "missing argument to \"$1\""
            shift

            nodetype="$1"
         ;;

         --address)
            [ "$#" -eq 1 ] && sde_dependency_usage "missing argument to \"$1\""
            shift

            address="$1"
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde_dependency_usage "missing argument to \"$1\""
            shift

            marks="`comma_concat "${marks}" "$1"`"
         ;;

         --url)
            fail "Can't have --url here. Specify the URL as the last argument"
         ;;

         --*)
            [ "$#" -eq 1 ] && sde_dependency_usage "missing argument to \"$1\""

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
   [ -z "${url}" ] && sde_dependency_get_usage "missing url"
   shift

   if [ "${OPTION_ENHANCE}" = "YES" ]
   then
      _sde_enhance_url "${url}" "${branch}" "${nodetype}" "${address}"

      url="${_url}"
      branch="${_branch}"
      nodetype="${_nodetype}"
      address="${_address}"
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
   eval_exekutor "${MULLE_SOURCETREE}" "${MULLE_SOURCETREE_FLAGS}" \
                                          add "${options}" "'${url}'"
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

      get)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_get_main "$@"
         return $?
      ;;

      remove)
         exekutor "${MULLE_SOURCETREE}" -s ${MULLE_SOURCETREE_FLAGS} remove "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_set_main "$@"
         return $?
      ;;

      list)
         exekutor "${MULLE_SOURCETREE}" -s ${MULLE_SOURCETREE_FLAGS} list \
            --format "um" \
            --marks "dependency" \
             "$@"
      ;;

      *)
         log_error "Unknown command \"${cmd}\""
         sde_dependency_usage
      ;;
   esac
}
