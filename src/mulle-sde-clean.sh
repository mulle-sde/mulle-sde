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
MULLE_SDE_CLEAN_SH="included"


sde_clean_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean [domain]

   Cleans various parts of the mulle-sde system. You can specify multiple
   domains. Clean will rebuild your project including subprojects.
   Use \`${MULLE_USAGE_NAME} -v -n -lx clean\` to preview, what will be
   cleaned.

Domains:
   all         : cleans everything
   buildorder  : like rebuild, but also wipes the cached buildorder
   cache       : clean some caches including the archive cache
   default     : clean project and subprojects (default)
   project     : clean project, keeps dependencies
   rebuild     : like default plus removes the dependency folder
   refetch     : combines "tidy" with "cache" to update all dependencies
   subproject  : clean subprojects
   tidy        : cleans everything and removes fetched dependencies. It's slow!
EOF
   exit 1
}



#
# use rexekutor to show call, put pass -n flag via technical flags so
# nothing gets actually deleted with -n
#


sde_clean_output_main()
{
   log_entry "sde_clean_output_main" "$@"

   log_verbose "Cleaning addiction directory"
   rmdir_safer "${ADDICTION_DIR}"
   log_verbose "Cleaning build directory"
   rmdir_safer "${BUILD_DIR}"
   log_verbose "Cleaning dependency directory"
   rmdir_safer "${DEPENDENCY_DIR}"
}


sde_clean_builddir_main()
{
   log_entry "sde_clean_builddir_main" "$@"

   log_verbose "Cleaning \"build\" directory"
   rmdir_safer "${BUILD_DIR}"
}

sde_clean_dependencydir_main()
{
   log_entry "sde_clean_dependencydir_main" "$@"

   log_verbose "Cleaning \"dependency\" directory"
   rmdir_safer "${DEPENDENCY_DIR}"
}


sde_clean_project_main()
{
   log_entry "sde_clean_project_main" "$@"

   rexekutor "${MULLE_CRAFT}" ${MULLE_TECHNICAL_FLAGS} clean project
}


sde_clean_dependency_main()
{
   log_entry "sde_clean_dependency_main" "$@"

   log_verbose "Cleaning \"dependency\" directory"
   rexekutor "${MULLE_CRAFT}" ${MULLE_TECHNICAL_FLAGS} clean dependency
}


sde_clean_subproject_main()
{
   log_entry "sde_clean_subproject_main" "$@"

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || internal_fail "missing file"
   fi

   local subprojects
   local subproject

   subprojects="`sde_subproject_get_names`"
   if [ -z "${subprojects}" ]
   then
      log_verbose "No subprojects, so done"
      return
   fi

   set -o noglob; IFS="
"
   for subproject in ${subprojects}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"
      rexekutor "${MULLE_CRAFT}" ${MULLE_TECHNICAL_FLAGS} clean "${subproject}"
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
}


#
# this will destroy the buildorder
# also wipe archive cache. Does not wipe git mirror cache unless -f is given
# because thats supposed to be harmless
#
sde_clean_cache_main()
{
   log_entry "sde_clean_cache_main" "$@"

   log_verbose "Cleaning sde cache"
   rmdir_safer ".mulle-sde/var/${MULLE_HOSTNAME}/cache"


   if [ ! -z "${MULLE_FETCH_MIRROR_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "YES" ]
      then
         rmdir_safer "${MULLE_FETCH_MIRROR_DIR}"
      fi
   fi

   if [ ! -z "${MULLE_FETCH_ARCHIVE_DIR}" ]
   then
      rmdir_safer "${MULLE_FETCH_ARCHIVE_DIR}"
   fi
}


sde_clean_var_main()
{
   log_entry "sde_clean_var_main" "$@"

   log_verbose "Cleaning var folders"

   IFS="
"
   for directory in `find . -name "var" -type d -print`
   do
      IFS="${DEFAULT_IFS}"
      case "${directory}" in
         */.mulle-*/var)
            rmdir_safer "${directory}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"
}


sde_clean_db_main()
{
   log_entry "sde_clean_db_main" "$@"

   rexekutor "${MULLE_SOURCETREE}" -V ${MULLE_TECHNICAL_FLAGS} reset
}


sde_clean_sourcetree_main()
{
   log_entry "sde_clean_sourcetree_main" "$@"

   rexekutor "${MULLE_SOURCETREE}" -V ${MULLE_TECHNICAL_FLAGS} clean
}


sde_clean_patternfile_main()
{
   log_entry "sde_clean_patternfile_main" "$@"

   rexekutor "${MULLE_MATCH}" ${MULLE_TECHNICAL_FLAGS} clean
}


sde_clean_monitor_main()
{
   log_entry "sde_clean_monitor_main" "$@"

   MULLE_MONITOR_DIR="${MULLE_SDE_MONITOR_DIR:-${MULLE_SDE_DIR}}" \
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      rexekutor "${MULLE_MONITOR}" ${MULLE_TECHNICAL_FLAGS} clean
}



sde_clean_main()
{
   log_entry "sde_clean_main" "$@"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_clean_usage
         ;;

         -*)
            sde_clean_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
   fi

   local domain
   local domains

   case "${1:-default}" in
      'domains')
         echo "\
all
cache
default
project
rebuild
subproject
tidy"
         exit 0
      ;;

      'all')
         domains="output var"
      ;;

      'buildorder')
         domains="cache builddir dependencydir"
      ;;

      'cache')
         domains="cache db monitor patternfile"
      ;;

      'default')
         domains="project subproject"
      ;;

      'dependency')
         domains="builddir dependencydir"
      ;;

      'rebuild')
         domains="builddir"
      ;;

      'refetch')
         domains="tidy cache"
      ;;

      'tidy')
         domains="sourcetree output var db monitor patternfile"
      ;;

      *)
         rexekutor "${MULLE_CRAFT}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_CRAFT_FLAGS} clean "$@"
      ;;
   esac

   local functionname

   set -o noglob
   for domain in ${domains}
   do
      set +o noglob

      functionname="sde_clean_${domain}_main"
      if [ "`type -t "${functionname}"`" = "function" ]
      then
         "${functionname}"
      else
         sde_clean_usage "Unknown clean domain \"${domain}\""
      fi
   done
   set +o noglob
}
