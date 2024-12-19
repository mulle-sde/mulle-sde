# shellcheck shell=bash
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
MULLE_SDE_DEPENDENCY_SH='included'


DEPENDENCY_MARKS='dependency,delete'  # with delete we filter out subprojects
DEPENDENCY_LIST_MARKS='dependency'
DEPENDENCY_LIST_NODETYPES='ALL'

#
# no-cmake-loader     : C code needs no ObjCLoader (if all-load is set)
# no-cmake-searchpath : We don't flatten C source headers by default
# no-all-load         : C libraries are cherrypicked for symbols
# no-import           : use #include instead of #import
# singlephase         : assume most C stuff is old fashioned
#
DEPENDENCY_C_MARKS='no-import,no-all-load,no-cmake-loader,no-cmake-searchpath'

#
# no-singlephase      : assume most ObjC stuff is mulle-objc
#
DEPENDENCY_OBJC_MARKS='no-singlephase'

# no-cmake-all-load   : need not and can't force load frameworks
# singlephase         : frameworks can't do multiphase
# no-cmake-add        : we don't need info from frameworks
# no-cmake-inherit    : we don't link against what a framework links (neccesarily)
# only-framework      : yes it's aframework
DEPENDENCY_FRAMEWORKS_MARKS='singlephase,no-cmake-add,no-cmake-all-load,no-cmake-inherit,only-framework'

DEPENDENCY_EXECUTABLE_MARKS='no-link,no-header,no-bequeath'
# enable some cmake flags, to "remove" them
DEPENDENCY_EMBEDDED_MARKS='no-build,no-header,no-link,no-share,no-readwrite,cmake-inherit,cmake-searchpath,cmake-all-load,cmake-loader'
DEPENDENCY_AMALGAMATED_MARKS='no-build,no-clobber,no-header,no-link,no-readwrite,no-share,no-share-shirk'
DEPENDENCY_STARTUP_MARKS='all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header,no-cmake-inherit'


sde::dependency::usage()
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
   copying single entries between projects, or use \`mulle-sourcetree rcopy\`.

   Check out the Wiki for information on how to setup and tweak your
   dependencies:

      https://github.com/mulle-sde/mulle-sde/wiki

Commands:
   add        : add a dependency to the sourcetree
   binaries   : list all binaries in the built dependencies folder
   duplicate  : duplicate a dependency, usually for OS specific settings
   craftinfo  : change build options for a dependency
   etcs       : list all etc files in the built dependencies folder
   export     : export dependency as script command
   fetch      : fetch dependencies (same as mulle-sde fetch)
   get        : retrieve a dependency settings from the sourcetree
   headers    : list all headers in the built dependencies folder
   info       : for some dependencies there might be online help available
   libraries  : list all libraries in the built dependencies folder
   list       : list dependencies in the sourcetree (default)
   mark       : add marks to a dependency in the sourcetree
   move       : reorder dependencies in the sourcetree
   rcopy      : copy a dependency from another project with a sourcetree
   remove     : remove a dependency from the sourcetree
   set        : change a dependency settings in the sourcetree
   shares     : list all share files in the built dependencies folder
   stashes    : list downloaded dependencies
   source-dir : find the source location of a dependency
   unmark     : remove marks from a dependency in the sourcetree
         (use <command> -h for more help about commands)
EOF
   exit 1
}


sde::dependency::add_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency add [options] <url>

   Add a dependency to your project. A dependency is usually a git repository
   or a tar/zip archive (more options may be available if additional
   mulle-fetch plugins are installed). But you can also embed remote source
   files into your source tree.

   The default dependency is a C library with header files. You need to use
   the appropriate options to build Objective-C libraries, header-less or
   header-only or purely embedded dependencies.

   See the Wiki for more information:
      https://github.com/mulle-sde/mulle-sde/wiki

Examples:
   Add a github repository as a dependency:
      ${MULLE_USAGE_NAME} dependency add --github madler --scm git zlib

   Add a tar archive as a dependency:
      ${MULLE_USAGE_NAME} dependency add https://foo.com/whatever.2.11.tar.gz

   Add a remote hosted file to your project:
      ${MULLE_USAGE_NAME} dependency add --embedded --scm file \\
                               --address src/foo.c https://foo.com/foo_2.11.c

   Add an archive with flexible versioning to the project:
      ${MULLE_USAGE_NAME} dependency add --c --address postgres --tag 11.2 \\
                               --marks singlephase \\
'https://ftp.postgresql.org/pub/source/v\${MULLE_TAG}/postgresql-\${MULLE_TAG}.tar.bz2'
      ${MULLE_USAGE_NAME} environment set POSTGRES_TAG 11.1 # look in config

Options:
   --address <dst> : specify place in project for an embedded dependency
   --c             : used for C dependencies (default)
   --clean         : delete all previous dependencies and libraries
   --domain <name> : create an URL for a known domain, e.g. github
   --embedded      : the dependency becomes part of the local project
   --fetchoptions  : options for mulle-fetch --options
   --framework     : a MacOS framework (macOS only)
   --git           : short cut for --scm git
   --github <name> : a shortcut for --domain github --user <name>
                     works also for other known domains (e.g. --gitlab)
   --headerless    : has no headerfile
   --headeronly    : has no library
   --if-missing    : if a node with the same address is present, do nothing
   --multiphase    : the dependency can be crafted in three phases (default)
   --objc          : used for Objective-C dependencies
   --optional      : dependency is not required to exist by dependency owner
   --plain         : do not enhance URLs with environment variables
   --private       : headers are not visible to API consumers
   --repo <name>   : used in conjunction with --domain to specify an url
   --scm <name>    : specify remote format [git, svn, tar, zip, file]
   --singlephase   : the dependency must be crafted in one phase
   --startup       : dependency is a ObjC startup library
   --tag <name>    : used in conjunction with --domain to specify an url
   --user <name>   : used in conjunction with --domain to specify an url

EOF
  exit 1
}


sde::dependency::set_usage()
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
   --append          : append the value
   --remove          : remove the value

Keys:
   aliases           : names of library to search for, separated by comma.
                       You can prefix a name with a build type and a colon,
                       like "Debug:" or "Release:".
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


sde::dependency::export_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency export <dep>

   Create mulle-sde command statements to recreate the dependency as
   specified in the sourcetree. (This does not export the craftinfo,
   use the more global \`mulle-sde export\` for this).

EOF
  exit 1
}


sde::dependency::get_usage()
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


sde::dependency::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency list [options]

   List the dependencies of this project in (quasi) JSON format.
   Use \`${MULLE_USAGE_NAME} dependency list --eval\` to expand value variables.

   Use \`${MULLE_USAGE_NAME} dependency list -c\` for less detail and
   columnar output.

   Use \`${MULLE_USAGE_NAME} dependency list -- --output-format cmd\` for copying
   single entries between projects.

   See the subcommand help \`mulle-sourcetree -v list -h\` for even more
   options, that are available.

Options:
   -c               : output in the columnar format
   -l               : columnar output long information
   -ll              : columnar output full information
   -m               : columnar show marks output (overwrites other flags)
   -r               : columnar recursive list
   -g               : columnar output branch/tag information (use -G for raw)
   -u               : columnar output URL information  (use -U for raw output)
   --eval           : expand variables in JSON format
   --json           : output true JSON format, precludes other flags (default)
   --no-mark <mark> : remove mark from columnar output
   --url            : show URL in columnar output
   --               : pass remaining arguments to mulle-sourcetree list


EOF
   exit 1
}


sde::dependency::source_dir_usage()
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


sde::dependency::r_upcaseid()
{
   include "case"

   r_smart_file_upcase_identifier "$1"
}


#
#
#
sde::dependency::set_main()
{
   log_entry "sde::dependency::set_main" "$@"

   local OPTION_OPERATION
   local OPTION_DIALECT=''
   local OPTION_ENHANCE='YES'

   while :
   do
      case "$1" in
         -a|--append)
            OPTION_OPERATION='APPEND'
         ;;

         -c|--c)
            OPTION_DIALECT='c'
         ;;

         -m|--objc)
            OPTION_DIALECT='objc'
         ;;

         -r|--remove)
            OPTION_OPERATION='REMOVE'
         ;;

         --enhance)
            OPTION_ENHANCE='YES'
         ;;

         --plain)
            OPTION_ENHANCE='NO'
         ;;

         -*)
            sde::dependency::set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address="$1"
   [ -z "${address}" ] && sde::dependency::set_usage "missing address"
   shift

   local field="$1"

   if [ -z "${field}" ]
   then
      if [ -z "${OPTION_DIALECT}" ]
      then
         sde::dependency::set_usage "missing field"
      fi
   else
      if [ ! -z "${OPTION_DIALECT}" ]
      then
         sde::dependency::set_usage "superfluous field"
      fi
      shift
   fi

   # make sure its really a library, less surprising for the user (i.e. me)
   local marks

   if ! marks="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" get "${address}" marks`"
   then
      return 1
   fi

   if ! sde::common::marks_compatible_with_marks "${marks}" "${DEPENDENCY_MARKS}"
   then
      if [ "${field}" != "marks" ]
      then
         fail "${address} is not a dependency"
      fi
      if ! sde::common::marks_compatible_with_marks "${value}" "${DEPENDENCY_MARKS}"
      then
         fail "${address} would not be a dependency anymore.
${C_INFO}Use \`mulle-sourcetree mark\`, if you want this to happen."
      fi
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
         sde::common::_set_platform_excludes "${address}" \
                                             "${value}" \
                                             "${DEPENDENCY_MARKS}" \
                                             "${OPTION_OPERATION}"
         return $?
      ;;

      aliases|include)
         sde::common::_set_userinfo_field "${address}" \
                                          "${field}" \
                                          "${value}" \
                                          "${OPTION_OPERATION}"
         return $?
      ;;

      url)
         if [ "${OPTION_ENHANCE}" = 'YES' ]
         then
            local upcaseid
            local nodetype

            if [ -z "${nodetype}" ]
            then
               nodetype="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                                          ${MULLE_TECHNICAL_FLAGS} \
                                          ${MULLE_DOMAIN_FLAGS} \
                                       typeguess \
                                          "${value}"`" || exit 1
               log_debug "Nodetype guessed as \"${nodetype}\""
            fi

            sde::dependency::__enhance_url "${value}" \
                                           "${tag}" \
                                           "" \
                                           "${nodetype}" \
                                           "${address}" ""

            value="${_url}"
         fi
      ;;

      tag|branch|nodetype)
         if [ "${OPTION_ENHANCE}" = 'YES' ]
         then
            local upcaseid

            sde::dependency::r_upcaseid "${address}" || return 1
            upcaseid="${RVAL}"

            r_uppercase "${field}"
            value="\${${upcaseid}_${RVAL}:-${value}}"
         fi
      ;;
   esac

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_SOURCETREE_FLAGS:-} \
                  set "${address}" "${field}" "${value}"
}


sde::dependency::get_main()
{
   log_entry "sde::dependency::get_main" "$@"

   local address="$1"

   [ -z "${address}" ]&& sde::dependency::get_usage "missing address"
   shift

   local field="$1"

   [ -z "${field}" ] && sde::dependency::get_usage "missing field"
   shift

   [ $# -ne 0 ] && sde::dependency::get_usage "Superflous arguments $*"

   case "${field}" in
      platform-excludes)
         sde::common::get_platform_excludes "${address}"
      ;;

      aliases|include)
         sde::common::get_sourcetree_userinfo_field "${address}" "${field}"
      ;;

      *)
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS:-} \
                     get --marks "${DEPENDENCY_MARKS}" \
                        "${address}" \
                        "${field}"
      ;;
   esac
}


sde::dependency::export_main()
{
   log_entry "sde::dependency::export_main" "$@"

   [ $# -eq 0 ] && sde::dependency::export_usage

   local address="$1"

   [ -z "${address}" ] && sde::dependency::export_usage "empty address"
   shift

   [ $# -ne 0 ] && sde::dependency::export_usage "superflous arguments $*"

   include "sde::common"

   sde::common::export_sourcetree_node 'dependency' "${address}" "${DEPENDENCY_MARKS}"
}


sde::dependency::json_filter()
{
   local mode="$1"

   # in default mode we use ' for easier copy/paste into sde env set
   # remove address and make it a "banner"
   case "${mode}" in
      DEFAULT)
         tr '"' $'\'' \
         | cut -c 7- \
         | sed -e '1,2d' \
               -e '/^$/N;/\n$/D' \
               -e "s/'\([a-z0-9A-Z_]*\)': /\1:/" \
               -e "s/,\$//" \
         | sed -e "/^address:/s/^address:[^']*'\\([^']*\\)'.*/\\1/;t next" \
               -e "s/^\([a-z]\)/   \1/" \
               -e ":next"
      ;;

      *)
         cat
      ;;
   esac
}


sde::dependency::pretty_filtered_json()
{
   log_entry "sde::dependency::pretty_filtered_json" "$@"

   local text="$1"
   local sep 

   sep=""
   .foreachline line in ${text}
   .do
      case "${line}" in
         '   '*)
            printf "%s\n" "${line}"
         ;;

         *)
            printf "%s${C_CYAN}${C_BOLD}%s${C_RESET}\n" "${sep}" "${line}"
            sep=$'\n'
         ;;
      esac
   .done
}


sde::dependency::list_main()
{
   log_entry "sde::dependency::list_main" "$@"

   local no_marks
   local qualifier
   local formatstring

   formatstring="%a;%s;%i={aliases,,-------};%i={include,,-------}"
   # with supermarks we don't filter stuff out anymore a priori
   no_marks=

   local OPTION_OUTPUT_COMMAND='NO'
   local OPTIONS
   local OPTION_JSON='DEFAULT'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::dependency::list_usage
         ;;

         -c|--columnar|--no-json)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
         ;;

         --expand|--eval)
            JSON_ARGS="--expand"
         ;;

         --json)
            [ "${OPTION_JSON}" = 'NO' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='YES'
         ;;

         --url)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            formatstring="${formatstring};%u"
         ;;

         -m)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            formatstring="%a;%m;%i={aliases,,-------};%i={include,,-------}"
         ;;

         --no-mark|--no-marks)
            [ "$#" -eq 1 ] && sde::dependency::list_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${no_marks}" "$1"
            no_marks="${RVAL}"
         ;;

         --name-only)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            formatstring="%a"
         ;;

         --qualifier)
            [ "$#" -eq 1 ] && sde::dependency::list_usage "Missing argument to \"$1\""
            shift

            qualifier="$1"
         ;;

         --output-format)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            shift
            OPTION_OUTPUT_COMMAND='YES'
         ;;

         -r)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            r_concat "${OPTIONS}" "$1"
            OPTIONS="${RVAL}"
            formatstring="%a;%s"
         ;;

         -l|-ll|-r|-g|-u|-G|-U)
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            r_concat "${OPTIONS}" "$1"
            OPTIONS="${RVAL}"
         ;;

         --)
            # this is actually "good", if one still wants JSON though you
            # can pass this after --, but usually its an error
            [ "${OPTION_JSON}" = 'YES' ] && fail "You can't mix --json with \"$1\""
            OPTION_JSON='NO'
            # pass rest to mulle-sourcetree
            shift
            break
         ;;

         -*)
            sde::dependency::list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_JSON}" != 'NO' ]
   then
      local text

      if ! text="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
                --silent-but-warn \
            json \
               --marks "${DEPENDENCY_LIST_MARKS}" \
               --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
               --qualifier "${qualifier}" \
               ${JSON_ARGS} | sde::dependency::json_filter "${OPTION_JSON}" `"
      then
         return $?
      fi
      sde::dependency::pretty_filtered_json "${text}"
      return
   fi

   if [ "${OPTION_OUTPUT_COMMAND}" = 'YES' ]
   then
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
                --silent-but-warn \
            list \
               --marks "${DEPENDENCY_LIST_MARKS}" \
               --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
               --qualifier "${qualifier}" \
               --output-eval \
               --output-format cmd2 \
               --output-no-url \
               --output-no-column \
               --output-no-header \
               --output-no-marks "${no_marks}" \
               --output-cmdline "${MULLE_USAGE_NAME} dependency add" \
               --verbatim \
               ${OPTIONS} \
               "$@"
   else
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} dependency" \
         rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
            list \
               --format "${formatstring}\\n" \
               --marks "${DEPENDENCY_LIST_MARKS}" \
               --qualifier "${qualifier}" \
               --nodetypes "${DEPENDENCY_LIST_NODETYPES}" \
               --output-no-marks "${no_marks}" \
               --verbatim \
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
sde::dependency::__enhance_url()
{
   log_entry "sde::dependency::__enhance_url" "$@"

   local url="$1"
   local tag="$2"
   local branch="$3"
   local nodetype="$4"
   local address="$5"
   local marks="$6"

   local rval
   local changes

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
      else
         changes='address'
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

   sde::dependency::r_upcaseid "${address}" || return 1
   upcaseid="${RVAL}"

   if [ -z "${tag}" ]
   then
      _tag="\${${upcaseid}_TAG}"
      r_concat "${changes}" 'tag'
      changes="${RVAL}"
   else
      case "${tag}" in
         \$\{*)
            # already wrapped
            _tag="${tag}"
         ;;

         *)
            _tag="\${${upcaseid}_TAG:-${tag}}"

            r_concat "${changes}" 'tag'
            changes="${RVAL}"
         ;;
      esac
   fi


   if [ -z "${branch}" ]
   then
      _branch="\${${upcaseid}_BRANCH}"
      r_concat "${changes}" 'branch'
      changes="${RVAL}"
   else
      case "${branch}" in
         \$\{*)
            # already wrapped
            _branch="${branch}"
         ;;

         *)
            _branch="\${${upcaseid}_BRANCH:-${branch}}"
            r_concat "${changes}" 'branch'
            changes="${RVAL}"
         ;;
      esac
   fi

   #
   # so if we have a tag, we replace this in the URL with MULLE_TAG
   # that makes our URL flexible (hopefully)
   #
   if [ ! -z "${tag}" ]
   then
      # one of the major pain points. I can't get this right and I am
      # constantly adjusting this. And I can't figure out a better way.
      case "${BASH_VERSION:-}" in
         [01236].*|5.1*)
            r_escaped_sed_pattern "${tag}"
            url="$(sed -e "s/${RVAL}/\\\${MULLE_TAG}/g" <<< "${url}" )"
            r_concat "${changes}" 'url'
            changes="${RVAL}"
         ;;

         *)
            if [[ -n "$ZSH_VERSION" ]]; then
                # zsh version
                url="${url//${tag}/\${MULLE_TAG\}}"
            else
                # bash version
                url="${url//${tag}/\$\{MULLE_TAG\}}"
            fi
            r_concat "${changes}" 'url'
            changes="${RVAL}"
         ;;
      esac
   fi

   log_setting "url: ${url}"

   case "${url}" in
      \$\{*)
         # already wrapped
         _url="${url}"
      ;;

      *)
         _url="\${${upcaseid}_URL:-${url}}"
         r_concat "${changes}" 'url'
         changes="${RVAL}"
      ;;
   esac

   # common wrapper for archive and repository
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
   case "${nodetype}" in
      \$\{*)
         # already wrapped
         _nodetype="${nodetype}"
      ;;

      *)
         _nodetype="\${${upcaseid}_NODETYPE:-${nodetype}}"
         r_concat "${changes}" 'nodetype'
         changes="${RVAL}"
      ;;
   esac

   if [ ! -z "${changes}" ]
   then
      log_verbose "Enhanced node fields: ${C_MAGENTA}${C_BOLD}${changes}"
   fi

   _address="${address}"
}


# like mulle_sde_init sde::init::add_to_sourcetree but no templating
sde::dependency::add_to_sourcetree()
{
   log_entry "sde::dependency::add_to_sourcetree" "$@"

   local filename="$1"

   [ -z "${filename}" ] && _internal_fail "filename is empty"

   local line
   local lines

   lines="`rexekutor grep -E -v '^#' "${filename}"`"
   if [ -z "${lines}" ]
   then
      log_warning "\"${filename}\" contains no dependency information"
      return
   fi

   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -N \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_SOURCETREE_FLAGS:-} \
                        eval-add --filename "${filename}" "${lines}" || exit 1
}


sde::dependency::add_main()
{
   log_entry "sde::dependency::add_main" "$@"

   local OPTION_AMALGAMATED='NO'
   local OPTION_CLEAN='NO'
   local OPTION_DIALECT=
   local OPTION_EMBEDDED='NO'
   local OPTION_ENHANCE='YES'     # enrich URL
   local OPTION_EXECUTABLE='NO'
   local OPTION_FETCH='YES'
   local OPTION_LATEST='NO'
   local OPTION_MARKS
   local OPTION_OPTIONAL='NO'
   local OPTION_PRIVATE='NO'
   local OPTION_SHARE='YES'
   local OPTION_SINGLEPHASE=
   local OPTION_STARTUP='DEFAULT'

   local OPTION_ADDRESS
   local OPTION_BRANCH
   local OPTION_BRANCH_SET
   local OPTION_DOMAIN
   local OPTION_FILTER
   local OPTION_HOST
   local OPTION_NODETYPE
   local OPTION_FETCHOPTIONS
   local OPTION_REPO
   local OPTION_TAG
   local OPTION_TAG_SET
   local OPTION_USER

   local OPTION_OPTIONS

   local argc

   argc=$#

   local domain
   local name
   local repo
   local domains

   #
   # grab options for mulle-sourcetree
   # interpret sde options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::dependency::add_usage
         ;;

         --address)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_ADDRESS="$1"
         ;;

         --branch)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
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

         --amalgamated)
            OPTION_AMALGAMATED='YES'
            OPTION_EMBEDDED='YES'
            OPTION_FETCH='NO'
         ;;

         --embedded)
            OPTION_EMBEDDED='YES'
            OPTION_FETCH='NO'
         ;;

         --executable)
            OPTION_EXECUTABLE='YES'
         ;;

         --domain)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_DOMAIN="$1"
         ;;

         --host)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_HOST="$1"
         ;;

         --repo)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_REPO="$1"
         ;;

         --filter)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_FILTER="$1"
         ;;

         --fetchoptions)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_FETCHOPTIONS="$1"
         ;;

         --tag)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
            OPTION_TAG_SET='YES'
         ;;

         --user)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
            shift

            OPTION_USER="$1"
         ;;

         --framework)
            r_comma_concat "${OPTION_MARKS}" "${DEPENDENCY_FRAMEWORKS_MARKS}"
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

         --latest)
            OPTION_LATEST='YES'
         ;;

         --marks)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
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

         --git|--zip|--tar)
            OPTION_NODETYPE="${1:2}"
         ;;

         --nodetype|--scm)
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""
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
            [ "$#" -eq 1 ] && sde::dependency::add_usage "Missing argument to \"$1\""

            domain="${1#--}"
            shift

            domains="${domains:-`rexekutor ${MULLE_DOMAIN:-mulle-domain} -s list `}"

            if find_line "${domains}" "${domain}"
            then
               OPTION_DOMAIN="${domain}"
               OPTION_USER="${1%/*}"
               OPTION_REPO="${OPTION_REPO:-"${1##*/}"}"
            else
               # unknown domain, must be some other option
               r_concat "${OPTION_OPTIONS}" "--${domain} '$1'"
               OPTION_OPTIONS="${RVAL}"
            fi
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local url="${1:-}"

   if [ -z "${url}" ]
   then
      if [ -z "${OPTION_USER}" -o -z "${OPTION_REPO}" -o "${OPTION_DEMO}" ]
      then
         if [ -z "${OPTION_USER}" -a -z "${OPTION_REPO}" -a "${OPTION_DEMO}" ]
         then
            sde::dependency::add_usage "URL argument is missing ($*)"
         else
            sde::dependency::add_usage "URL argument is missing or incomplete options given"
         fi
      fi
   else
      shift
      [ "$#" -eq 0 ] || sde::dependency::add_usage "Superflous arguments \"$*\""
   fi

   local options
   local nodetype
   local address
   local branch
   local host
   local user
   local originalurl
   local domain
   local fetchoptions

   originalurl="${url}"

   nodetype="${OPTION_NODETYPE}"
   user="${OPTION_USER}"
   tag="${OPTION_TAG}"
   branch="${OPTION_BRANCH}"
   address="${OPTION_ADDRESS}"
   options="${OPTION_OPTIONS}"
   domain="${OPTION_DOMAIN}"
   host="${OPTION_HOST}"
   repo="${OPTION_REPO}"
   fetchoptions="${OPTION_FETCHOPTIONS}"

   case "${originalurl}" in
      comment:*)
         scm="comment"
         url="${originalurl#*:}"
      ;;

      *:*)
         eval `rexekutor mulle-domain parse-url "${originalurl}"`

         # remap scm to nodetype, nodetype is misnomer through out this file
         # it should be scm
         nodetype="${nodetype:-${scm:-}}"
      ;;
   esac

   local found_local

   #
   # Special case, if we just get a name, we check if this is a project
   # which is in MULLE_FETCH_SEARCH_PATH. If yes we pick its location and
   # use the name of the parent directory as the user.
   #
   if [ $argc -eq 1 ]  # but already consumed!
   then
      local directory

      log_debug "Single argument special case search of MULLE_FETCH_SEARCH_PATH"

      include "path"

      IFS=":"
      for directory in ${MULLE_FETCH_SEARCH_PATH}
      do
         r_filepath_concat "${directory}" "${originalurl}"
         if [ ! -d "${RVAL}" ]
         then
            continue
         fi

         log_verbose "Found local \"${RVAL}\", assume github tar project"
         found_local='YES'

         r_simplified_absolutepath "${directory}"
#         r_dirname "${RVAL}"
         r_basename "${RVAL}"
         user="${RVAL}"

         nodetype="tar"
         tag="latest"
         domain="${domain:-github}"

         r_basename "${originalurl}"
         repo="${repo:-${RVAL}}"
         break
      done
      IFS="${DEFAULT_IFS}"
   fi

   local skip_this

   if [ -z "${found_local}" -a "${OPTION_LATEST}" = 'YES' ]
   then
      if ! latest_url="`rexekutor mulle-domain resolve --latest "${url}" '*' `"
      then
         log_warning "Could not figure out latest tag for \"${url}\""
      else
         # re-evaluate to fill values
         eval `rexekutor mulle-domain parse-url "${latest_url}"`

         # remap scm to nodetype, nodetype is misnomer through out this file
         # it should be scm, here though nodetype must be available
         nodetype="${scm}"
         domain="${domain:-github}"
      fi
   fi

   log_setting "address      : ${address}"
   log_setting "branch       : ${branch}"
   log_setting "domain       : ${domain}"
   log_setting "fetchoptions : ${fetchoptions}"
   log_setting "host         : ${host}"
   log_setting "nodetype     : ${nodetype}"
   log_setting "options      : ${options}"
   log_setting "repo         : ${repo}"
#   log_setting "scm          : ${scm}"
   log_setting "tag          : ${tag}"
   log_setting "url          : ${url}"
   log_setting "user         : ${user}"

   #
   # if domain is given, we compose from what's on the command line
   #
   case "${domain}" in
      "")
      ;;

      'generic')
         # keep URL as is
         url="${originalurl}"
      ;;

      *)
         nodetype="${nodetype:-tar}"
         url="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_DOMAIN_FLAGS} \
               compose-url \
                  --user "${user}" \
                  --tag "${tag}" \
                  --repo "${repo:-$url}" \
                  --scm "${nodetype}" \
                  "${domain}" `" || exit 1
      ;;
   esac

   log_setting "url (now)    : ${url}"

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
            -s \
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

      case "${guessed_user}" in
         mulle*)
            case "${scm}" in
               tar|zip)
                  tag="${tag:-latest}"
               ;;
            esac
         ;;
      esac
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
         nodetype="tar"  # nodetype none is only valid for libraries
         address="${originalurl}"
         tag="${latest:-latest}"
         url="https://github.com/${user:-${MULLE_USERNAME}}/${originalurl}/archive/${tag}.tar.gz"
         log_verbose "Adding this as a fake github project ${url} for symlink fetch"
      fi
   fi

   local marks

   marks="${DEPENDENCY_MARKS}"

   if [ "${OPTION_ENHANCE}" = 'YES' ]
   then
      case "${nodetype}" in
         'comment'|'error'|'local'|'symlink'|'file')
            # no embellishment here
         ;;

         *)
            sde::dependency::__enhance_url "${url}" \
                                           "${tag}" \
                                           "${branch}" \
                                           "${nodetype}" \
                                           "${address}" \
                                           "${marks}"

            url="${_url}"
            if [ "${OPTION_BRANCH_SET}" != 'YES' ]
            then
               branch="${_branch}"
            fi
            if [ "${OPTION_TAG_SET}" != 'YES' ]
            then
               tag="${_tag}"
            fi
            nodetype="${_nodetype}"
            address="${_address}"
            marks="${_marks}"
         ;;
      esac
   fi


   include "sde::library"

   sde::library::warn_stupid_name "${address}"

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
            log_info "C dependency assumed from name (if wrong use --objc )"
            OPTION_DIALECT='c'
         ;;

         [A-Z]*)
            log_info "Objective-C dependency assumed from name (if wrong use --c)"
            OPTION_DIALECT='objc'
         ;;

         *)
            log_info "C dependency assumed from name (if wrong use --objc )"
            OPTION_DIALECT='c'
         ;;
      esac
   fi

   #
   # singlephase might flip-flop around a bit in the marks, but that's not
   # a problem
   #
   case "${OPTION_DIALECT}" in
      'c')
         # prepend is better in this case
         r_comma_concat "${DEPENDENCY_C_MARKS}" "${marks}"
         marks="${RVAL}"

         case "${address##*/}" in
            mulle_*|Mulle*)
               r_comma_concat "${DEPENDENCY_C_MARKS}" "no-singlephase"
            ;;
         esac
      ;;

      'objc')
         # prepend is better in this case
         r_comma_concat "${DEPENDENCY_OBJC_MARKS}" "${marks}"
         marks="${RVAL}"
      ;;
   esac

   if [ "${nodetype}" = "clib" -a "${OPTION_EMBEDDED}" != 'YES' ]
   then
      log_warning "clib nodes are always embedded"
      OPTION_EMBEDDED='YES'
   fi

   #
   # force user selection
   #
   case "${OPTION_SINGLEPHASE}" in
      'NO')
         r_comma_concat "${marks}" "no-singlephase"
         marks="${RVAL}"
      ;;

      'YES')
         r_comma_concat "${marks}" "singlephase"
         marks="${RVAL}"
      ;;
   esac

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

   if [ "${OPTION_AMALGAMATED}" = 'YES' ]
   then
      r_comma_concat "${marks}" "${DEPENDENCY_AMALGAMATED_MARKS}"
      marks="${RVAL}"
   fi

   if [ "${OPTION_EXECUTABLE}" = 'YES' ]
   then
      r_comma_concat "${marks}" "${DEPENDENCY_EXECUTABLE_MARKS}"
      marks="${RVAL}"
   fi

   if [ "${OPTION_STARTUP}" = 'DEFAULT' ]
   then
      case "${address}" in
         *Start[Uu]p|*-[Ss]tart[Uu]p)
            log_verbose "Determined \"${address}\" to be a startup library by name"
            OPTION_STARTUP='YES'
         ;;
      esac
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

   case "${nodetype}" in
      'comment'|'error')
      ;;

      *)
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
      ;;
   esac

   if [ ! -z "${fetchoptions}" ]
   then
      r_concat "${options}" "--fetchoptions '${fetchoptions}'"
      options="${RVAL}"
   fi


   if [ "${OPTION_CLEAN}" = 'YES' ]
   then
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     --virtual-root \
                     "${MULLE_TECHNICAL_FLAGS}" \
                  clean --config
   fi

   if ! eval_rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        --virtual-root \
                    "${MULLE_TECHNICAL_FLAGS}" \
                        add "${options}" "'${url}'"
   then
      return 1
   fi

   local dependency

   dependency="${address:-${originalurl}}"

   if [ "${OPTION_EMBEDDED}" = 'YES' ]
   then
      _log_info "${C_VERBOSE}After \`mulle-sde fetch\` check for boring embedded files with \`mulle-sde fetch\` and ignore them with:
${C_RESET_BOLD}   mulle-sde ignore <gitignore-like-pattern>"
   else
      _log_info "${C_VERBOSE}You can change the library search names with:
${C_RESET_BOLD}   mulle-sde dependency set ${address} aliases ${address#lib},${address#lib}2
${C_VERBOSE}You can change the header include with:
${C_RESET_BOLD}   mulle-sde dependency set ${address} include ${address#lib}/${address#lib}.h"

      case "${OPTION_DIALECT}" in
         c)
            if [ "${OPTION_PRIVATE}" = 'YES' ]
            then
               case "${MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE}" in
                  'NONE'|'DISABLE')
                     _log_warning "MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE is set to DISABLE.
${C_INFO}The library header of ${dependency} may not be available automatically.
To enable:
${C_RESET_BOLD}mulle-sde environment set MULLE_SOURCETREE_TO_C_PRIVATEINCLUDE_FILE ON"
                  ;;
               esac
            else
               case "${MULLE_SOURCETREE_TO_C_INCLUDE_FILE}" in
                  'NONE'|'DISABLE')
                     _log_warning "MULLE_SOURCETREE_TO_C_INCLUDE_FILE is set to DISABLE.
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


sde::dependency::source_dir_main()
{
   log_entry "sde::dependency::source_dir_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::dependency::source_dir_usage
         ;;

         -*)
            sde::dependency::source_dir_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local address=$1

   [ -z "${address}" ] && sde::dependency::source_dir_usage "Missing argument"
   shift
   [ $# -ne 0 ]        && sde::dependency::source_dir_usage "Superflous arguments \"$*\""

   local escaped

   r_escaped_shell_string "${address}"
   escaped="${RVAL}"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_SOURCETREE_FLAGS:-} \
                  walk \
                     --lenient \
                     --qualifier 'MATCHES dependency' \
                     --verbatim \
                     '[ "${NODE_ADDRESS}" = "'${escaped}'" ] && printf "%s\n" "${NODE_FILENAME}"'

}


sde::dependency::contains_numeric_arguments()
{
   log_entry "sde::dependency::contains_numeric_arguments" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         [0-9]*)
            return 0
         ;;
      esac
      shift
   done
   return 1
}


sde::dependency::headers_main()
{
   log_entry "sde::dependency::headers_main" "$@"


   if [ ! -d "${DEPENDENCY_DIR}" ]
   then
      fail "Need to build dependencies, to list available headers"
   fi

   local directories
   local directory

   for directory in "${DEPENDENCY_DIR}/include" "${DEPENDENCY_DIR}/Debug/include"
   do
      if [ -d "${directory}" ]
      then
         r_concat "${directories}" "'${directory}'"
         directories="${RVAL}"
      fi
   done

   if [ -z "${directories}" ]
   then
      log_warning "Apparently there are no headers available, recraft dependencies ?"
      return
   fi

   eval_rexekutor tree  -I '*.cmake' --prune --noreport "${directories}"
}


sde::dependency::libraries_main()
{
   log_entry "sde::dependency::libraries_main" "$@"


   if [ ! -d "${DEPENDENCY_DIR}" ]
   then
      fail "Need to build dependencies, to list linkable libraries"
   fi

   local directories
   local directory

   for directory in "${DEPENDENCY_DIR}/lib" "${DEPENDENCY_DIR}/Debug/lib"
   do
      if [ -d  "${directory}" ]
      then
         r_concat "${directories}" "'${directory}'"
         directories="${RVAL}"
      fi
   done

   if [ -z "${directories}" ]
   then
      log_warning "Apparently there are no libraries available, recraft dependencies ?"
      return
   fi

   eval_rexekutor tree -I '*.cmake' --prune --noreport "${directories}"
}


sde::dependency::binaries_main()
{
   log_entry "sde::dependency::binaries_main" "$@"


   if [ ! -d "${DEPENDENCY_DIR}" ]
   then
      fail "Need to build dependencies, to list binaries"
   fi

   local directories
   local directory

   for directory in "${DEPENDENCY_DIR}/bin" "${DEPENDENCY_DIR}/Debug/bin"
   do
      if [ -d  "${directory}" ]
      then
         r_concat "${directories}" "'${directory}'"
         directories="${RVAL}"
      fi
   done

   if [ -z "${directories}" ]
   then
      log_warning "Apparently there are no binaries available"
      return
   fi

   eval_rexekutor tree --prune --noreport "${directories}"
}


sde::dependency::etcs_main()
{
   log_entry "sde::dependency::etcs_main" "$@"


   if [ ! -d "${DEPENDENCY_DIR}" ]
   then
      fail "Need to build dependencies, to list etc files"
   fi

   local directories
   local directory

   for directory in "${DEPENDENCY_DIR}/etc" "${DEPENDENCY_DIR}/Debug/etc"
   do
      if [ -d  "${directory}" ]
      then
         r_concat "${directories}" "'${directory}'"
         directories="${RVAL}"
      fi
   done

   if [ -z "${directories}" ]
   then
      log_warning "Apparently there are no etc files"
      return
   fi

   eval_rexekutor tree --prune --noreport "${directories}"
}


sde::dependency::shares_main()
{
   log_entry "sde::dependency::shares_main" "$@"


   if [ ! -d "${DEPENDENCY_DIR}" ]
   then
      fail "Need to build dependencies, to list share files"
   fi

   local directories
   local directory

   for directory in "${DEPENDENCY_DIR}/share" "${DEPENDENCY_DIR}/Debug/share"
   do
      if [ -d  "${directory}" ]
      then
         r_concat "${directories}" "'${directory}'"
         directories="${RVAL}"
      fi
   done

   if [ -z "${directories}" ]
   then
      log_warning "Apparently there are no share files"
      return
   fi

   eval_rexekutor tree --prune --noreport "${directories}"
}


sde::dependency::downloads_main()
{
   log_entry "sde::dependency::downloads_main" "$@"

   if [ ! -d "${MULLE_SOURCETREE_STASH_DIR:-stash}" ]
   then
      fail "Need to fetch dependencies, to list stashed files"
   fi

   if [ ! -d "${MULLE_SOURCETREE_STASH_DIR:-stash}" ]
   then
      log_warning "Apparently there are no share files"
      return
   fi

   eval_rexekutor tree --noreport "${MULLE_SOURCETREE_STASH_DIR:-stash}"
}


sde::dependency::stashes_main()
{
   sde::dependency::downloads_main "$@"
}



###
### parameters and environment variables
###
sde::dependency::main()
{
   log_entry "sde::dependency::main" "$@"

   local cmd

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::dependency::usage
         ;;

         -*)
            cmd="list" # assume its for list
            break
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

   if [ -z "${cmd}" ]
   then
      cmd="${1:-list}"

      [ $# -ne 0 ] && shift
   fi

   # shellcheck source=src/mulle-sde-common.sh
   include "sde::common"
   # shellcheck source=src/mulle-sde-craftinfo.sh
   include "sde::craftinfo"

   local rc 

   case "${cmd}" in
      add)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde::dependency::add_main "$@"
         return $?
      ;;

      commands)
         echo "\
add
binaries
craftinfo
duplicate
downloads
etcs
export
fetch
get
headers
libraries
list
help
info
map
mark
move
rcopy
remove
set
shares
source-dir
unmark"
      ;;

      craftinfo)
         sde::craftinfo::main "$@"
         return $?
      ;;

      duplicate|mark|unmark|rcopy)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           ${MULLE_TECHNICAL_FLAGS} \
                           --silent-but-warn \
                        "${cmd}" \
                           "$@"
      ;;

      fetch)
         include "sde::fetch"

         sde::fetch::main "$@"
      ;;

      get|export)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde::dependency::${cmd}_main "$@"
         return $?
      ;;

      binaries|downloads|etcs|headers|libraries|shares|stashes)
         sde::dependency::${cmd}_main "$@"
      ;;


      keys)
         echo "\
aliases
include
platform-excludes"
         return 0
      ;;

      list)
         sde::dependency::list_main "$@"
      ;;

      move)
         if sde::dependency::contains_numeric_arguments "$@"
         then
            fail "Only move dependencies by name, as the sourcetree is shared with libraries"
         fi
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           ${MULLE_TECHNICAL_FLAGS} \
                           --silent-but-warn \
                        'move' \
                           "$@"
      ;;

      remove|rem)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
             exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "remove" \
                           "$@"
         rc=$?

         if [ $rc -eq 0 ]
         then
            MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           --virtual-root \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "remove" \
                           --if-present \
                           "craftinfo/$1-craftinfo"
         fi
         return $rc
      ;;

      set)
         # shellcheck source=src/mulle-sde-common.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-common.sh"

         sde::dependency::set_main "$@"
         return $?
      ;;

      source-dir)
         sde::dependency::source_dir_main "$@"
      ;;

      "")
         sde::dependency::usage
      ;;

      *)
         sde::dependency::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
