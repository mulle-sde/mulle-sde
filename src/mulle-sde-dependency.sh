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
DEPENDENCY_LIST_NODETYPES="ALL"


sde_dependency_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency [command]

   A dependency is a third party package, that is fetched via an URL.
   It will be built ahead of your project to provide headers to include and
   libraries to link against.

   See the \`set\` command if the project has problems locating the header
   or library. Use \`mulle-sde dependency list -- --output-format cmd\` for
   copying single entries between projects.

Commands:
   add        : add a dependency to the sourcetree
   craftinfo  : change build options for a dependency
   get        : retrieve a dependency settings from the sourcetree
   list       : list dependencies in the sourcetree (default)
   mark       : add marks to a dependency in the sourcetree
   move       : reorder dependencies in the sourcetree
   remove     : remove a dependency from the sourcetree
   set        : change a dependency settings in the sourcetree
   source-dir : find the source location of a dependency
   unmark     : remove marks from a dependency in the sourcetree
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
   a tar or zip archive (more options may be available if additional
   mulle-fetch plugins are installed).

   The default dependency is a library with a headerfile.

   You should specify with options, if a dependency supports the mulle-make
   three phase build protocol for vastly superior build times.

   You should also specify the language if the dependency is Objective-C.

Examples:
   Add a github repository as a dependency:

      ${MULLE_USAGE_NAME} dependency add --github madler --scm git zlib

   Add a tar archive as a dependency:

      -${MULLE_USAGE_NAME} dependency add https://foo.com/whatever.2.11.tar.gz

Options:
   --c             : used for C dependencies (default)
   --clean         : delete all previous dependencies and libraries
   --embedded      : the dependency becomes part of the local project
   --github <name> : create an URL for a - possibly fictitious - github name
   --headerless    : has no headerfile
   --headeronly    : has no library
   --no-fetch      : do not attempt to find a matching craftinfo on github
   --if-missing    : if a node with the same address is present, do nothing
   --multiphase    : the dependency can be crafted in three phases (default)
   --objc          : used for Objective-C dependencies
   --optional      : dependency is not required to exist by dependency owner
   --plain         : do not enhance URLs with environment variables
   --private       : headers are not visible to API consumers
   --singlephase   : the dependency must be crafted in one phase
   --startup       : dependency is a ObjC startup library
      (see: mulle-sourcetree -v add -h for more add options)
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
   address. It's pretty common to change the include header and the library
   name of a dependency.

   Examples:
      ${MULLE_USAGE_NAME} dependency set --append pthreads aliases pthread
      ${MULLE_USAGE_NAME} dependency set libdill include libdill.h

   Note: Specifiying aliases works nicely in the generated cmake files. The
         'linkorder' though has a problem, since it doesn't use cmake's
         find_library.

Options:
   --append    : append value instead of set

Keys:
   aliases     : names of library to search for, separated by comma
   include     : include filename to use
   os-excludes : names of OSes to exclude, separated by comma
   tag         : tag or version to fetch
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
   aliases     : names of library to search for, separated by comma
   include     : include filename to use
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

   Use \`mulle-sde dependency list -- --output-format cmd\` for copying
   single entries between projects.

Options:
   --        : pass remaining arguments to mulle-sourcetree list
   --url     : show URL
EOF
   exit 1
}


sde_dependency_source_dir_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency source-dir <dep>

   Find the source location of the given dependency. Will return empty, if
   the dependency is unknown. The returned filename does not need to exist yet.

EOF
   exit 1
}


#
#
#
sde_dependency_set_main()
{
   log_entry "sde_dependency_set_main" "$@"

   local OPTION_APPEND='NO'
   local OPTION_DIALECT=''

   while :
   do
      case "$1" in
         -a|--append)
            OPTION_APPEND='YES'
         ;;

         -c|--c)
            OPTION_DIALECT='c'
         ;;

         -m|--objc)
            OPTION_DIALECT='objc'
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

   if [ -z "${field}" ]
   then
      if [ -z "${OPTION_DIALECT}" ]
      then
         sde_dependency_set_usage "missing field"
      fi
   else
      if [ ! -z "${OPTION_DIALECT}" ]
      then
         sde_dependency_set_usage "superflous field"
      fi
      shift
   fi

   local value="$1"
   local cmd

   if [ ! -z "${OPTION_DIALECT}" ]
   then
      cmd="mark"
      case "${OPTION_DIALECT}"  in
         c)
            cmd="unmark"
         ;;
      esac


      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                       ${MULLE_TECHNICAL_FLAGS} \
                   "${cmd}" "${address}" "all-load" &&
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                       ${MULLE_TECHNICAL_FLAGS} \
                   "${cmd}" "${address}" "import"
      return $?
   fi


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
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                          ${MULLE_TECHNICAL_FLAGS} \
                      set "${address}" "${field}" "${value}"
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

   formatstring="%a;%m;%i={aliases,,-------};%i={include,,-------}"
   marks="${DEPENDENCY_MARKS}"

   local OPTION_OUTPUT_COMMAND='NO'

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

            r_comma_concat "${marks}" "$1"
            marks="${RVAL}"
         ;;

         --output-format)
            shift
            OPTION_OUTPUT_COMMAND='YES'
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

   if [ "${OPTION_OUTPUT_COMMAND}" = 'YES' ]
   then
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V -s \
               ${MULLE_TECHNICAL_FLAGS} \
            list \
               --marks "${DEPENDENCY_LIST_MARKS}" \
               --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
               --output-eval \
               --output-format cmd2 \
               --output-no-url \
               --output-no-column \
               --output-no-header \
               --output-no-marks "${DEPENDENCY_MARKS}" \
               --output-cmdline "${MULLE_USAGE_NAME} dependency add" \
               "$@"
   else
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V -s \
               ${MULLE_TECHNICAL_FLAGS} \
            list \
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
#    _marks
#
_sde_enhance_url()
{
   log_entry "_sde_enhance_url" "$@"

   local url="$1"
   local branch="$2"
   local nodetype="$3"
   local address="$4"
   local marks="$5"

   if [ -z "${nodetype}" ]
   then
      nodetype="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V typeguess "${url}"`" || exit 1
      [ -z "${nodetype}" ] && fail "Specify --nodetype with this kind of URL"
   fi

   if [ -z "${address}" ]
   then
      address="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V nameguess --nodetype "${nodetype}" "${url}"`"  || exit 1
      if [ -z "${address}" ]
      then
         if [ ! -e "${url}" ]
         then
            fail "Specify --address with this kind of URL"
         fi

         r_basename "${url}"
         address="${RVAL}"

         url="file://${url}"
         nodetype="git"
      fi
   fi

   _url=""
   _branch=""
   _address=""
   _marks=""
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

   r_de_camel_case_upcase_identifier "${address}"
   upcaseid="${RVAL}"

   local last
   local leading
   local extension

   case "${nodetype}" in
      tar|zip)
         case "${url}" in
            *\$\{MULLE_BRANCH\}*|*\$\{MULLE_TAG\}*)
            ;;

            *)
               [ ! -z "${branch}" ] && fail "The branch must be specified in the URL for archives."
            ;;
         esac

         case "${url}" in
            # format .../branch.tar.gz or so
            *github.com/*)
               last="${url##*/}"         # basename
               leading="${url%${last}}"  # dirname
               branch="${last%%.tar*}"
               if [ "${branch}" = "${last}" ]
               then
                  branch="${last%%.zip*}"
               fi
               if [ "${branch}" = "${last}" ]
               then
                  branch="${last%%.*.*}"
               fi
               if [ "${branch}" = "${last}" ]
               then
                  branch="${last%%.*}"
               fi
               extension="${last#${branch}.}"    # dirname

               url="${leading}\${MULLE_BRANCH}.${extension}"
            ;;

            # format .../branch
         *mulle-kybernetik*/git/*)
               last="${url##*/}"         # basename
               leading="${url%${last}}"  # dirname
               branch="${last%%.*}"

               url="${leading}\${MULLE_BRANCH}"
            ;;
         esac
      ;;
   esac

   if [ ! -z "${branch}" ]
   then
      _branch="\${${upcaseid}_BRANCH:-${branch}}"
   else
      _branch="\${${upcaseid}_BRANCH}"
   fi

   # common wrapper for archive and repository
   _url="\${${upcaseid}_URL:-${url}}"
   _marks="${marks}"
   # THIS DOESN'T WORK SINCE the marks adding code bails
   #
   # remedy: autogenerate let sourcetree autogenerate environment checks
   #         for MULLE_URL, MULLE_MARKS etc.
   #
   #  Maybe also allow changes based on UUID ?
   #
   # _marks="\${${upcaseid}_MARKS:-${marks}}"
   _nodetype="\${${upcaseid}_NODETYPE:-${nodetype}}"
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

   local OPTION_ENHANCE='YES'     # enrich URL
   local OPTION_DIALECT="c"
   local OPTION_PRIVATE='NO'
   local OPTION_EMBEDDED='NO'
   local OPTION_EXECUTABLE='NO'
   local OPTION_STARTUP='NO'
   local OPTION_SHARE='YES'
   local OPTION_OPTIONAL='NO'
   local OPTION_SINGLEPHASE='NO' # more common default for me :)
   local OPTION_FAKE_GITHUB
   local OPTION_CLEAN='NO'
   local OPTION_FETCH='YES'

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

         --address)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            address="$1"
         ;;

         --branch)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            branch="$1"
         ;;

         --clean)
            OPTION_CLEAN='YES'
         ;;

         -c|--c)
            OPTION_DIALECT='c'
         ;;

         --embedded)
            OPTION_EMBEDDED='YES'
         ;;

         --executable)
            OPTION_EXECUTABLE='YES'
         ;;

         --github|--fake)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_FAKE_GITHUB="$1"
         ;;

         --header-less|--headerless)
            r_comma_concat "${marks}" "no-header"
            marks="${RVAL}"
         ;;

         --header-only|--headeronly)
            r_comma_concat "${marks}" "no-link"
            marks="${RVAL}"
         ;;

         --if-missing)
            r_concat "${options}" "--if-missing"
            options="${RVAL}"
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${marks}" "$1"
            marks="${RVAL}"
         ;;

         --startup)
            OPTION_STARTUP='YES'
         ;;

         --multiphase)
            OPTION_SINGLEPHASE='NO'
         ;;

         --singlephase)
            OPTION_SINGLEPHASE='YES'
         ;;

         --mulle-c)
            OPTION_SINGLEPHASE='NO'
            OPTION_DIALECT='c'
         ;;

         --mulle-objc)
            OPTION_SINGLEPHASE='NO'
            OPTION_DIALECT='objc'
         ;;

         --nodetype|--scm)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            nodetype="$1"
         ;;

         --no-fetch)
            OPTION_FETCH='NO'
         ;;

         --objc|-m)
            OPTION_DIALECT='objc'
         ;;

         --optional)
            OPTION_OPTIONAL='YES'
         ;;

         --plain)
            OPTION_ENHANCE='NO'
         ;;

         --private)
            OPTION_PRIVATE='YES'
         ;;

         --public)
            OPTION_PRIVATE='NO'
         ;;

         --url)
            fail "Can't have --url here. Specify the URL as the last argument"
         ;;

         --*)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""

            r_concat "${options}" "$1 '$2'"
            options="${RVAL}"
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

   local originalurl

   originalurl="${url}"

   if [ ! -z "${OPTION_FAKE_GITHUB}" ]
   then
   	case "${nodetype}" in
   		git)
      		url="https://github.com/${OPTION_FAKE_GITHUB}/${url}.git"
      	;;

      	zip)
      		url="https://github.com/${OPTION_FAKE_GITHUB}/${url}/archive/latest.zip"
      	;;

      	*)
      		url="https://github.com/${OPTION_FAKE_GITHUB}/${url}/archive/latest.tar.gz"
      	;;
      esac
   fi

   if [ "${OPTION_ENHANCE}" = 'YES' ]
   then
      case "${nodetype}" in
         local|symlink|file)
            # no embellishment here
         ;;

         *)
            _sde_enhance_url "${url}" "${branch}" "${nodetype}" "${address}" "${marks}"

            url="${_url}"
            branch="${_branch}"
            nodetype="${_nodetype}"
            address="${_address}"
            marks="${_marks}"
         ;;
      esac
   fi

   # is a good idea for test though
   # if [ "${address}" = "${PROJECT_NAME}" ]
   # then
   #    fail "Adding your own project as a dependency is not a good idea"
   # fi

   case "${OPTION_DIALECT}" in
      c)
         # prepend is better in this case
         r_comma_concat "no-import,no-all-load" "${marks}"
         marks="${RVAL}"
      ;;
   esac

   if [ "${OPTION_SINGLEPHASE}" = 'NO' ]
   then
      r_comma_concat "${marks}" "no-singlephase"
      marks="${RVAL}"
   fi

   if [ "${OPTION_PRIVATE}" = 'YES' ]
   then
      r_comma_concat "${marks}" "no-public"
      marks="${RVAL}"
   fi

   if [ "${OPTION_OPTIONAL}" = 'YES' ]
   then
      r_comma_concat "${marks}" "no-require"
      marks="${RVAL}"
   fi

   if [ "${OPTION_EMBEDDED}" = 'YES' ]
   then
      r_comma_concat "${marks}" "no-build,no-header,no-link,no-share"
      marks="${RVAL}"
   fi

   if [ "${OPTION_EXECUTABLE}" = 'YES' ]
   then
      r_comma_concat "${marks}" "no-link,no-header,no-bequeath"
      marks="${RVAL}"
   fi

   if [ "${OPTION_STARTUP}" = 'YES' ]
   then
      # as startups are not installing a header, they must be singlephase
      # this should remove a previous add above
      r_comma_concat "${marks}" "all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header"
      marks="${RVAL}"
   fi

   if [ ! -z "${nodetype}" ]
   then
      r_concat "${options}" "--nodetype '${nodetype}'"
      options="${RVAL}"
   fi
   if [ ! -z "${address}" ]
   then
      r_concat "${options}" "--address '${address}'"
      options="${RVAL}"
   fi
   if [ ! -z "${branch}" ]
   then
      r_concat "${options}" "--branch '${branch}'"
      options="${RVAL}"
   fi
   if [ ! -z "${marks}" ]
   then
      r_concat "${options}" "--marks '${marks}'"
      options="${RVAL}"
   fi

   if [ "${OPTION_CLEAN}" = 'YES' ]
   then
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V \
                     "${MULLE_TECHNICAL_FLAGS}"\
                  clean --config
   fi

   log_verbose "URL: ${url}"
   if ! eval_exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V \
                      "${MULLE_TECHNICAL_FLAGS}"\
                        add "${options}" "'${url}'"
   then
      return 1
   fi

   if [ "${OPTION_FETCH}" = 'NO' ]
   then
      return 0
   fi

   local dependency

   dependency="${address:-${originalurl}}"
   if ! sde_dependency_craftinfo_exists_main "DEFAULT" "${dependency}"
   then
      return 0
   fi

   if ! sde_dependency_craftinfo_create_main "DEFAULT" "${dependency}"
   then
      return 1
   fi

   if ! sde_dependency_craftinfo_fetch_main "DEFAULT" --clobber "${dependency}"
   then
      return 1
   fi

}


sde_dependency_source_dir_main()
{
   log_entry "sde_dependency_source_dir_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_source_dir_usage
         ;;

         -*)
            sde_dependency_source_dir_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address=$1

   [ -z "${address}" ] && sde_dependency_source_dir_usage "Missing argument"
   shift
   [ $# -ne 0 ]        && sde_dependency_source_dir_usage "Superflous arguments \"$*\""

   local escaped

   r_escaped_shell_string "${address}"
   escaped="${RVAL}"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  walk \
                     --lenient \
                     --qualifier 'MATCHES dependency' \
                     '[ "${NODE_ADDRESS}" = "'${escaped}'" ] && printf "%s\n" "${NODE_FILENAME}"'

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

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

   # shellcheck source=src/mulle-sde-common.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftinfo.sh"

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
source-dir
unmark"
      ;;

      craftinfo)
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

      remove)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -V \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "${cmd}" \
                           --if-present \
                           "craftinfo/$1"

         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -V \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "${cmd}" \
                           "$@"
      ;;

      mark|move|unmark)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -V \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "${cmd}" \
                           "$@"
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde_dependency_set_main "$@"
         return $?
      ;;

      source-dir)
         sde_dependency_source_dir_main "$@"
      ;;

      "")
         sde_dependency_usage
      ;;

      *)
         sde_dependency_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
