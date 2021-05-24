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

#
# no-cmake-loader     : C code needs no ObjCLoader (if all-load is set)
# no-cmake-searchpath : We don't flatten C source headers by default
# no-all-load         : C libraries are cherrypicked for symbols
# no-import           : use #include instead of #import
# singlephase         : assume most C stuff is old fashioned
#
DEPENDENCY_C_MARKS="no-import,no-all-load,no-cmake-loader,no-cmake-searchpath"
#
# no-singlephase      : assume most ObJC stuff is mulle-objc
#
DEPENDENCY_OBJC_MARKS="no-singlephase"

DEPENDENCY_EXECUTABLE_MARKS="no-link,no-header,no-bequeath"
DEPENDENCY_EMBEDDED_MARKS="no-build,no-header,no-link,no-share,no-readwrite"
DEPENDENCY_STARTUP_MARKS="all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header,no-cmake-searchpath,no-cmake-loader"


sde_dependency_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency [command]

   A dependency is usually a third party package, that is fetched via an URL.
   It will be built ahead of your project to provide headers to include and
   libraries to link against. You can also embed remote source files with
   the dependency command. See the \`add\` for more details.

   See the \`set\` command if the project has problems locating the header
   or library. Use \`mulle-sde dependency list -- --output-format cmd\` for
   copying single entries between projects.

   Check out the Wiki for information on how to setup and tweak your
   dependencies:

      https://github.com/mulle-sde/mulle-sde/wiki

Commands:
   add        : add a dependency to the sourcetree
   duplicate  : duplicate a dependency, usually for OS specific settings
   craftinfo  : change build options for a dependency
   get        : retrieve a dependency settings from the sourcetree
   info       : for some dependencies there might be online help available
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

   Add a dependency to your project. A dependency is usually a git repository
   or a tar/zip archive (more options may be available if additional
   mulle-fetch plugins are installed). But you can also embed remote source
   files into your source tree.

   There is a list of known projects on https://github.com/craftinfo. If the
   URL is craftinfo:name, then the respective craftinfo is searched and if
   a "sourcetree" file is found, this will be used to create the dependency.

   The default dependency is a C library with header files. You need to use
   the appropriate options to build Objective-C libraries, header-less or
   header-only or purely embedded dependencies.

   See the Wiki for more information:
      https://github.com/mulle-sde/mulle-sde/wiki

Examples:
   Add dependency via craftinfo:

      ${MULLE_USAGE_NAME} dependency add craftinfo:openssl

   Add a github repository as a dependency:

      ${MULLE_USAGE_NAME} dependency add --github madler --scm git zlib

   Add a tar archive as a dependency:

      ${MULLE_USAGE_NAME} dependency add https://foo.com/whatever.2.11.tar.gz

   Add a remote hosted file to your project:

      ${MULLE_USAGE_NAME} dependency add --embedded --scm file \\
                  --address src/foo.c https://foo.com/foo_2.11.c

   Add an archive with flexible versioning to the project:

      ${MULLE_USAGE_NAME} dependency add --c --address postgres --tag 11.2 \
                                         --marks singlephase \
'https://ftp.postgresql.org/pub/source/v${MULLE_TAG}/postgresql-${MULLE_TAG}.tar.bz2'
      ${MULLE_USAGE_NAME} environment set POSTGRES_TAG 11.1 # look in config

Options:
   --address <dst> : specify place in project for an embedded dependency
   --c             : used for C dependencies (default)
   --clean         : delete all previous dependencies and libraries
   --domain <name> : create an URL for a known domain, e.g. github
   --embedded      : the dependency becomes part of the local project
   --framework     : a MacOS framework (macOS only)
   --github <name> : a shortcut for --domain github --user <name>
                     works also for other known domains (e.g. --gitlab)
   --headerless    : has no headerfile
   --headeronly    : has no library
   --no-fetch      : do not attempt to find a matching craftinfo on github
   --if-missing    : if a node with the same address is present, do nothing
   --multiphase    : the dependency can be crafted in three phases (default)
   --objc          : used for Objective-C dependencies
   --optional      : dependency is not required to exist by dependency owner
   --plain         : do not enhance URLs with environment variables
   --private       : headers are not visible to API consumers
   --repo <name>   : used in conjunction with --domain to specify an url
   --singlephase   : the dependency must be crafted in one phase
   --startup       : dependency is a ObjC startup library
   --scm <name>    : specify remote format [git, svn, tar, zip, file]
   --user <name>   : used in conjunction with --domain to specify an url
   --tag <name>    : used in conjunction with --domain to specify an url

EOF
  exit 1
}


sde_dependency_set_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency set [options] <dep> <key> <value>

   Modify a dependency's sourcetree settings. The dependency is specified by
   url or address. It's a pretty common task to change the include header and
   the library name of a dependency. To change compile and link options use
   the \`${MULLE_USAGE_NAME} dependency craftinfo\" command.

Examples:
   Find a library named "pthreads" in addition to "pthread", which is the
   default name:

      ${MULLE_USAGE_NAME} dependency set --append pthreads aliases pthread

   Use <libdill.h> as the header to include, instead of <libdill/libdill.h>
   which is the default
      ${MULLE_USAGE_NAME} dependency set libdill include libdill.h

   Specifiying aliases works nicely in the generated cmake files. The
   'linkorder' command though will have a problem, as it doesn't use
   cmake's find_library to locate libraries.

   See the Wiki for more information:
      https://github.com/mulle-sde/mulle-sde/wiki

Options:
   --append          : append value instead of set

Keys:
   aliases           : names of library to search for, separated by comma
                       you can prefix a name with "Debug:" or "Release:" to
                       narrow the use to these cmake build types
EOF
   (
      cat <<EOF
   include           : include filename to use
   platform-excludes : names of platforms to exclude, separated by comma
EOF
      "${MULLE_SOURCETREE:-mulle-sourcetree}" -s set --print-common-keys "   "
   ) | sort >&2

  echo "" >&2
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
   aliases           : names of library to search for, separated by comma
   include           : include filename to use
   platform-excludes : names of platform to exclude, separated by comma

EOF
  exit 1
}


sde_dependency_info_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency info <name>

   Check online for help about a dependency. Pretty much just a README.md
   reader for https://github.com/craftinfo repositories. The dependency
   need not be present already.

   Examples:
      ${MULLE_USAGE_NAME} dependency info freetype

Environment:
   CRAFTINFO_REPOS : Repo URLS seperated by | (https://github.com/craftinfo)

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
   -l    : output long information
   -ll   : output full information
   -r    : recursive list
   -g    : output branch/tag information (use -G for raw output)
   -u    : output URL information  (use -U for raw output)
   --url : show URL
   --    : pass remaining arguments to mulle-sourcetree list


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


r_upcaseid()
{
   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"  || return 1
   fi

   r_de_camel_case_upcase_identifier "$1"
}

#
#
#
sde_dependency_set_main()
{
   log_entry "sde_dependency_set_main" "$@"

   local OPTION_APPEND='NO'
   local OPTION_DIALECT=''
   local OPTION_ENHANCE='YES'

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

         --enhance)
            OPTION_ENHANCE='YES'
         ;;

         --plain)
            OPTION_ENHANCE='NO'
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

   # make sure its really a library, less surprising for the user (i.e. me)
   local marks

   if ! marks="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" get "${address}" marks`"
   then
      return 1
   fi

   if ! sde_marks_compatible_with_marks "${marks}" "${DEPENDENCY_MARKS}"
   then
      fail "${address} is not a dependency"
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
                   "${cmd}" "${address}" "cmakeloader" &&
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                       ${MULLE_TECHNICAL_FLAGS} \
                   "${cmd}" "${address}" "import"
      return $?
   fi


   case "${field}" in
      platform-excludes)
         _sourcetree_set_os_excludes "${address}" \
                                     "${value}" \
                                     "${DEPENDENCY_MARKS}" \
                                     "${OPTION_APPEND}"
         return $?
      ;;

      aliases|include)
         _sde_set_sourcetree_userinfo_field "${address}" \
                                            "${field}" \
                                            "${value}" \
                                            "${OPTION_APPEND}"
         return $?
      ;;

      url)
         if [ "${OPTION_ENHANCE}" = 'YES' ]
         then
            local upcaseid
            local nodetype

            r_upcaseid "${address}" || return 1
            upcaseid="${RVAL}"

            if [ -z "${nodetype}" ]
            then
               nodetype="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                                          ${MULLE_TECHNICAL_FLAGS} \
                                          ${MULLE_DOMAIN_FLAGS} \
                                       typeguess \
                                          "${url}"`" || exit 1
               log_debug "Nodetype guessed as \"${nodetype}\""
            fi

            _sde_enhance_url "${value}" "${tag}" "" "${nodetype}" "${address}" ""

            value="\${${upcaseid}_URL:-${value}}"
         fi
      ;;

      tag|branch|nodetype)
         if [ "${OPTION_ENHANCE}" = 'YES' ]
         then
            local upcaseid

            r_upcaseid "${address}" || return 1
            upcaseid="${RVAL}"

            r_uppercase "${field}"
            value="\${${upcaseid}_${RVAL}:-${value}}"
         fi
      ;;
   esac

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                    ${MULLE_TECHNICAL_FLAGS} \
                    ${MULLE_SOURCETREE_FLAGS} \
                set "${address}" "${field}" "${value}"
}


sde_dependency_get_main()
{
   log_entry "sde_dependency_get_main" "$@"

   local address="$1"

   [ -z "${address}" ]&& sde_dependency_get_usage "missing address"
   shift

   local field="$1";

   [ -z "${field}" ] && sde_dependency_get_usage "missing field"
   shift

   case "${field}" in
      platform-excludes)
         sourcetree_get_os_excludes "${address}"
      ;;

      aliases|include)
         sde_get_sourcetree_userinfo_field "${address}" "${field}"
      ;;

      *)
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS} \
                     get "${address}" "${field}"
      ;;
   esac
}


sde_dependency_list_main()
{
   log_entry "sde_dependency_list_main" "$@"

   local marks
   local qualifier
   local formatstring

   formatstring="%a;%m;%i={aliases,,-------};%i={include,,-------}"
   marks="${DEPENDENCY_MARKS}"

   local OPTION_OUTPUT_COMMAND='NO'
   local OPTIONS

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


         --qualifier)
            [ "$#" -eq 1 ] && sde_dependency_list_usage "Missing argument to \"$1\""
            shift

            qualifier="${RVAL}"
         ;;

         --output-format)
            shift
            OPTION_OUTPUT_COMMAND='YES'
         ;;

         -l|-ll|-r|-g|-u|-G|-U)
            r_concat "${OPTIONS}" "$1"
            OPTIONS="${RVAL}"
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
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V -s \
               ${MULLE_TECHNICAL_FLAGS} \
            list \
               --marks "${DEPENDENCY_LIST_MARKS}" \
               --qualifier "${qualifier}" \
               --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
               --output-eval \
               --output-format cmd2 \
               --output-no-url \
               --output-no-column \
               --output-no-header \
               --output-no-marks "${DEPENDENCY_MARKS}" \
               --output-cmdline "${MULLE_USAGE_NAME} dependency add" \
               ${OPTIONS} \
               "$@"
   else
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" -V -s \
               ${MULLE_TECHNICAL_FLAGS} \
            list \
               --format "${formatstring}\\n" \
               --marks "${DEPENDENCY_LIST_MARKS}" \
               --qualifier "${qualifier}" \
               --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
               --output-no-marks "${DEPENDENCY_MARKS}" \
               ${OPTIONS} \
               "$@"
   fi
}


#
# return values in globals
#
#    _address
#    _branch
#    _marks
#    _nodetype
#    _tag
#    _url
#
_sde_enhance_url()
{
   log_entry "_sde_enhance_url" "$@"

   local url="$1"
   local tag="$2"
   local branch="$3"
   local nodetype="$4"
   local address="$5"
   local marks="$6"

   local rval

   if [ -z "${address}" ]
   then
      address="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                                 ${MULLE_TECHNICAL_FLAGS} \
                                 ${MULLE_DOMAIN_FLAGS} \
                              nameguess \
                                 --scm "${nodetype}" \
                                 "${url}"`"
      rval=$?
      [ $rval = 127 ] && exit 1

      log_debug "Address guessed as \"${address}\""

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

   _address=""
   _branch=""
   _marks=""
   _nodetype=""
   _tag=""
   _url=""

   #
   # create a convenient URL that can be substituted with env
   # variables.
   #
   local upcaseid

   r_upcaseid "${address}" || return 1
   upcaseid="${RVAL}"

   if [ -z "${tag}" ]
   then
      _tag="\${${upcaseid}_TAG}"
   else
      _tag="\${${upcaseid}_TAG:-${tag}}"
   fi

   if [ -z "${branch}" ]
   then
      _branch="\${${upcaseid}_BRANCH}"
   else
      _branch="\${${upcaseid}_BRANCH:-${branch}}"
   fi
   #
   # so if we have a tag, we replace this in the URL with MULLE_TAG
   # that makes our URL flexible (hopefully)
   #
   if [ ! -z "${tag}" ]
   then
      url="${url/${tag}/\$\{MULLE_TAG\}}"
   fi

   # common wrapper for archive and repository
   _url="\${${upcaseid}_URL:-${url}}"
   _marks="${marks}"
   #
   # WRAPPING MARKS DOESN'T WORK YET asthe marks adding code bails
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


# like mulle_sde_init add_to_sourcetree but no templating
sde_dependency_add_to_sourcetree()
{
   log_entry "sde_dependency_add_to_sourcetree" "$@"

   local filename="$1"

   [ -z "${filename}" ] && internal_fail "filename is empty"

   local line
   local lines
   local arguments
   local arguments_list

   lines="`rexekutor egrep -v '^#' "${filename}"`"
   if [ -z "${lines}" ]
   then
      log_warning "${filename} contains no dependency information"
      return
   fi

   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_SOURCETREE_FLAGS} \
                        eval-add --filename "${filename}" "${lines}" || exit 1
}


sde_dependency_use_craftinfo_main()
{
   log_entry "sde_dependency_use_craftinfo_main" "$@"

   local dependency="$1"
   local lenient="$2"

   # shellcheck source=src/mulle-sde-craftinfo.sh
   if [ -z "${MULLE_SDE_CRAFTINFO_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftinfo.sh"
   fi

   if ! sde_dependency_craftinfo_exists_main "DEFAULT" "${dependency}"
   then
      return 0
   fi

   local args

   if [ "${lenient}"  == 'YES' ]
   then
      args="--lenient"
   fi

   if ! sde_dependency_craftinfo_create_main "DEFAULT" ${args} "${dependency}"
   then
      return 1
   fi

   if ! sde_dependency_craftinfo_fetch_main "DEFAULT" ${args} --clobber "${dependency}"
   then
      return 1
   fi
}


sde_dependency_add_craftinfo_url()
{
   log_entry "sde_dependency_add_craftinfo_url" "$@"

   local dependency="$1"
   local lenient="$2"

   if [ "${OPTION_FETCH}" = 'NO' ]
   then
      fail "Craftinfo handling disabled by --no-fetch"
   fi

   if ! sde_dependency_use_craftinfo_main "${dependency}" "${lenient}"
   then
      fail "No craftinfo exists for \"${dependency}\""
   fi

   # grab sourcetree from craftinfo and apply it
   r_filepath_concat "${RVAL}" "sourcetree"
   sourcetree="${RVAL}"

   if [ ! -f "${sourcetree}" ]
   then
      sde_dependency_craftinfo_remove_main "DEFAULT" "${dependency}"
      fail "This craftinfo has no sourcetree file.
So it can't be used with craftinfo: style add."
   fi

   sde_dependency_add_to_sourcetree "${sourcetree}"
}


sde_dependency_add_main()
{
   log_entry "sde_dependency_add_main" "$@"

   local OPTION_CLEAN='NO'
   local OPTION_ENHANCE='YES'     # enrich URL
   local OPTION_DIALECT=
   local OPTION_PRIVATE='NO'
   local OPTION_EMBEDDED='NO'
   local OPTION_EXECUTABLE='NO'
   local OPTION_FETCH='YES'
   local OPTION_MARKS
   local OPTION_OPTIONAL='NO'
   local OPTION_SINGLEPHASE=
   local OPTION_SHARE='YES'
   local OPTION_STARTUP='NO'

   local OPTION_ADDRESS
   local OPTION_DOMAIN
   local OPTION_USER
   local OPTION_REPO
   local OPTION_FILTER
   local OPTION_TAG
   local OPTION_TAG_SET
   local OPTION_BRANCH
   local OPTION_BRANCH_SET

   local OPTION_OPTIONS

   local argc

   argc=$#

   local domains
   local name

   domains="`rexekutor ${MULLE_DOMAIN:-mulle-domain} -s list `"

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

            OPTION_ADDRESS="$1"
         ;;

         --branch)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
            OPTION_BRANCH_SET='YES'
         ;;

         --clean)
            OPTION_CLEAN='YES'
         ;;

         -c|--c)
            OPTION_DIALECT='c'
         ;;

         --embedded)
            OPTION_EMBEDDED='YES'
            OPTION_FETCH='NO'
         ;;

         --executable)
            OPTION_EXECUTABLE='YES'
         ;;

         --domain)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_DOMAIN="$1"
         ;;

         --repo)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_REPO="$1"
         ;;

         --filter)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_FILTER="$1"
         ;;

         --tag)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
            OPTION_TAG_SET='YES'
         ;;

         --user)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            OPTION_USER="$1"
         ;;

         --framework)
            r_comma_concat "${OPTION_MARKS}" "only-framework,singlephase"
            OPTION_MARKS="${RVAL}"
         ;;

         --header-less|--headerless)
            r_comma_concat "${OPTION_MARKS}" "no-header"
            OPTION_MARKS="${RVAL}"
         ;;

         --header-only|--headeronly)
            r_comma_concat "${OPTION_MARKS}" "no-link"
            OPTION_MARKS="${RVAL}"
         ;;

         --if-missing)
            r_concat "${OPTION_OPTIONS}" "--if-missing"
            OPTION_OPTIONS="${RVAL}"
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde_dependency_add_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"
         ;;

         --startup)
            OPTION_STARTUP='YES'
         ;;

         --multiphase|--no-singlephase)
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

            OPTION_NODETYPE="$1"
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

         --enhance)
            OPTION_ENHANCE='YES'
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

            name="${1#--}"
            if find_line "${domains}" "${name}"
            then
               OPTION_DOMAIN="${name}"
               shift
               OPTION_USER="$1"
            else
               r_concat "${OPTION_OPTIONS}" "$1 '$2'"
               OPTION_OPTIONS="${RVAL}"
               shift
            fi
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

   local options
   local nodetype
   local address
   local branch
   local user
   local originalurl
   local domain

   originalurl="${url}"

   nodetype="${OPTION_NODETYPE}"
   user="${OPTION_USER}"
   tag="${OPTION_TAG}"
   branch="${OPTION_BRANCH}"
   address="${OPTION_ADDRESS}"
   options="${OPTION_OPTIONS}"
   domain="${OPTION_DOMAIN}"

   case "${originalurl}" in
      craftinfo:*)
         [ ! -z "${nodetype}" ] && log_warning "Nodetype will be ignored with craftinfo: type URLs"
         [ ! -z "${user}" ]     && log_warning "User will be ignored with craftinfo: type URLs"
         [ ! -z "${tag}" ]      && log_warning "Tag will be ignored with craftinfo: type URLs"
         [ ! -z "${branch}" ]   && log_warning "Branch will be ignored with craftinfo: type URLs"
         [ ! -z "${address}" ]  && log_warning "Address will be ignored with craftinfo: type URLs"
         [ ! -z "${options}" ]  && log_warning "Options will be ignored with craftinfo: type URLs"

         sde_dependency_add_craftinfo_url "${originalurl#craftinfo:}" "YES"
         return $?
      ;;
   esac

   #
   # Special case, if we just get a name, we check if this is a project
   # which is in MULLE_FETCH_SEARCH_PATH. If yes we pick its location and
   # use the name of the parent directory as the user.
   #

   if [ $argc -eq 1 ]
   then
      local directory

      log_debug "Single argument special case search of MULLE_FETCH_SEARCH_PATH"
      IFS=":"
      for directory in ${MULLE_FETCH_SEARCH_PATH}
      do
         r_filepath_concat "${directory}" "$1"
         if [ ! -d "${RVAL}" ]
         then
            continue
         fi

         if [ -z "${MULLE_PATH_SH}" ]
         then
            . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"  || return 1
         fi

         log_fluff "Found \"${RVAL}\""

         r_absolutepath "${directory}"
#         r_dirname "${RVAL}"
         r_basename "${RVAL}"
         user="${RVAL}"
         nodetype="tar"
         tag="latest"
         domain="${domain:-github}"
         break
      done
      IFS="${DEFAULT_IFS}"
   fi

   #
   # if domain is given, we compose from what's on the command line
   #
   if [ ! -z "${domain}" ]
   then
      nodetype="${nodetype:-tar}"
      url="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_DOMAIN_FLAGS} \
            compose-url \
               --user "${user}" \
               --tag "${tag}" \
               --repo "${OPTION_REPO:-$url}" \
               --scm "${nodetype}" \
               "${domain}" `" || exit 1
   fi

   #
   # Lets mulle-domain guess us some of the stuff, if none were given
   #
   if [ -z "${tag}" -a -z "${branch}" ]
   then
      local guessed_scheme
      local guessed_domain
      local guessed_repo
      local guessed_user
      local guessed_branch
      local guessed_scm
      local guessed_tag

      eval "`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
            ${MULLE_TECHNICAL_FLAGS} \
            ${MULLE_DOMAIN_FLAGS} \
          parse-url \
            --prefix "guessed_" \
            "${url}" `"

      if [ ! -z "${guessed_repo}" -a -z "${address}" ]
      then
         log_debug "Address guessed as \"${guessed_repo}\""
         address="${guessed_repo}"
      fi

      if [ ! -z "${guessed_scm}" -a -z "${scm}" ]
      then
         log_debug "Nodetype guessed as \"${guessed_scm}\""
         scm="${guessed_scm}"
      fi

      if [ ! -z "${guessed_tag}" ]
      then
         log_debug "Tag guessed as \"${guessed_tag}\""
         tag="${guessed_tag}"
      else
         if [ ! -z "${guessed_branch}" ]
         then
            log_debug "Branch guessed as \"${guessed_branch}\""
            branch="${guessed_branch}"
         fi
      fi
   fi

   if [ -z "${nodetype}" ]
   then
      nodetype="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                                 ${MULLE_TECHNICAL_FLAGS} \
                                 ${MULLE_DOMAIN_FLAGS} \
                              typeguess "${url}"`" || exit 1

      log_debug "Nodetype guessed as \"${nodetype}\""

      #
      # want to support just saying "add x" and it means a sister project in
      # the same directory. So we make it a fake git project that will get
      # symlinked.
      #
      if [ "${nodetype}" = "none" ]
      then
         nodetype="git"  # nodetype none is only valid for libraries
         address="${originalurl}"
         url="https://github.com/${GITHUB_USER:${LOGNAME:-whoever}}/${originalurl}"
         log_verbose "Adding this as a fake github project ${url} for symlink fetch"
      fi
   fi

   local marks

   marks="${DEPENDENCY_MARKS}"

   if [ "${OPTION_ENHANCE}" = 'YES' ]
   then
      case "${nodetype}" in
         local|symlink|file)
            # no embellishment here
         ;;

         *)
            _sde_enhance_url "${url}" "${tag}" "${branch}" "${nodetype}" "${address}" "${marks}"

            url="${_url}"
            if [ "${OPTION_BRANCH_SET}" != 'YES' ]
            then
               branch="${_branch}"
            fi
            if [ "${OPTION_BRANCH_SET}" != 'YES' ]
            then
               tag="${_tag}"
            fi
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

   if [ -z "${OPTION_DIALECT}" ]
   then
      # order is important here!
      case "${address##*/}" in
         *_*)
            log_info "C dependency assumed (if wrong use --objc )"
            OPTION_DIALECT='c'
         ;;

         [A-Z]*)
            log_info "Objective-C dependency assumed (if wrong use --c)"
            OPTION_DIALECT='objc'
         ;;

         *)
            log_info "C dependency assumed (if wrong use --objc )"
            OPTION_DIALECT='c'
         ;;
      esac
   fi
   case "${OPTION_DIALECT}" in
      c)
         # prepend is better in this case
         r_comma_concat "${DEPENDENCY_C_MARKS}" "${marks}"
         marks="${RVAL}"
      ;;

      objc)
         # prepend is better in this case
         r_comma_concat "${DEPENDENCY_OBJC_MARKS}" "${marks}"
         marks="${RVAL}"
      ;;
   esac

   if [ -z "${OPTION_SINGLEPHASE}" ]
   then
      if [ "${OPTION_DIALECT}" = 'objc' ]
      then
         OPTION_SINGLEPHASE='YES'
      else
         case "${address##*/}" in
            mulle_*|Mulle*)
               OPTION_SINGLEPHASE='YES'
            ;;

            *)
               OPTION_SINGLEPHASE='NO'
            ;;
         esac
      fi
   fi

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
      r_comma_concat "${marks}" "${DEPENDENCY_EMBEDDED_MARKS}"
      marks="${RVAL}"
   fi

   if [ "${OPTION_EXECUTABLE}" = 'YES' ]
   then
      r_comma_concat "${marks}" "${DEPENDENCY_EXECUTABLE_MARKS}"
      marks="${RVAL}"
   fi

   if [ "${OPTION_STARTUP}" = 'YES' ]
   then
      r_comma_concat "${marks}" "${DEPENDENCY_STARTUP_MARKS}"
      marks="${RVAL}"
   fi

   r_comma_concat "${marks}" "${OPTION_MARKS}"
   marks="${RVAL}"

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
   if [ ! -z "${tag}" ]
   then
      r_concat "${options}" "--tag '${tag}'"
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

   local dependency

   dependency="${address:-${originalurl}}"

   if [ "${OPTION_FETCH}" != 'NO' ]
   then
      sde_dependency_use_craftinfo_main "${dependency}" "NO"
   fi

   if [ "${OPTION_EMBEDDED}" != 'YES' ]
   then
      case "${OPTION_DIALECT}" in
         c)
            if [ "${OPTION_PRIVATE}" = 'YES' ]
            then
               case "${MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE}" in
                  'NONE'|'DISABLE')
                     log_warning "MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE is set to DISABLE.
${C_INFO}The library header of ${dependency} may not be available automatically.
To enable:
${C_RESET_BOLD}mulle-sde environment set MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE ON"
                  ;;
               esac
            else
               case "${MULLE_SOURCETREE_TO_C_INCLUDE_FILE}" in
                  'NONE'|'DISABLE')
                     log_warning "MULLE_SOURCETREE_TO_C_INCLUDE_FILE is set to DISABLE.
${C_INFO}The library header of ${dependency} may not be available automatically.
To enable:
${C_RESET_BOLD}mulle-sde environment set MULLE_SOURCETREE_TO_C_INCLUDE_FILE ON"
                  ;;
               esac
            fi
         ;;
      esac
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
   # shellcheck source=src/mulle-sde-craftinfo.sh
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
duplicate
get
list
help
info
map
mark
move
remove
set
source-dir
unmark"
      ;;

      info)
         sde_dependency_craftinfo_info_main "$@"
         return $?
      ;;

      craftinfo)
         sde_dependency_craftinfo_main "$@"
         return $?
      ;;

      duplicate|mark|move|unmark)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -V \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "${cmd}" \
                           "$@"
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
platform-excludes"
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
                           "craftinfo/$1-craftinfo"

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

      star-search)
         log_info "Searching... be patient"
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -V \
                           ${MULLE_TECHNICAL_FLAGS} \
                        walk \
                           --dedupe-mode nodeline-no-uuid \
                           --lenient "[ \"\${NODE_ADDRESS}\" = \"$1\" ] && \
echo \"\${NODE_MARKS} \${NODE_TAG} \${NODE_BRANCH} \${NODE_URL} (\${WALK_DATASOURCE#\${PWD}/})\"" | sort -u
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
