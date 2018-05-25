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
   ${MULLE_USAGE_NAME} clean [domains]

   Cleans various parts of the sde system. You can specify multiple domains.

Domains:
   all          : clean all domains
   build        : clean build directory
   addiction    : remove project addictions
   cache        : remove miscellaneous cache files (default)
   dependency   : remove project dependencies
   patternfile  : remove patternfile caches
   project      : clean project build directory (default)
   sourcetree   : remove sourcetree databases
EOF
   exit 1
}



sde_clean_addiction_main()
{
   log_entry "sde_clean_addiction_main" "$@"

   log_verbose "Cleaning \"addiction\" directory"
   rmdir_safer "${ADDICTION_DIR}"
}


sde_clean_build_main()
{
   log_entry "sde_clean_build_main" "$@"

   log_verbose "Cleaning \"addiction\" directory"
   rmdir_safer "${BUILD_DIR}"
}


sde_clean_dependency_main()
{
   log_entry "sde_clean_dependency_main" "$@"

   log_verbose "Cleaning \"dependency\" directory"
   rexekutor "${MULLE_CRAFT}" ${MULLE_TECHNICAL_FLAGS} clean dependency
}


#
# use rexekutor to show call, put pass -n flag via technical flags so
# nothing gets actually deleted with -n
#
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


sde_clean_project_main()
{
   log_entry "sde_clean_project_main" "$@"

   rexekutor "${MULLE_CRAFT}" ${MULLE_TECHNICAL_FLAGS} clean project
}


sde_clean_cache_main()
{
   log_entry "sde_clean_cache_main" "$@"

   log_verbose "Cleaning sde cache"
   rmdir_safer ".mulle-sde/var/${MULLE_HOSTNAME}/cache"
}


sde_clean_sourcetree_main()
{
   log_entry "sde_clean_sourcetree_main" "$@"

   rexekutor "${MULLE_SOURCETREE}" ${MULLE_TECHNICAL_FLAGS} reset
}


sde_clean_all_main()
{
   log_entry "sde_clean_all_main" "$@"

   sde_clean_addiction_main &&
   sde_clean_cache_main &&
   sde_clean_dependency_main &&
   sde_clean_monitor_main &&
#   sde_clean_patternfile_main && # superflous
   sde_clean_project_main &&
   sde_clean_build_main &&
   sde_clean_sourcetree_main
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

   if [ $# -eq 0 ]
   then
      sde_clean_cache_main &&
      sde_clean_monitor_main &&
      sde_clean_project_main
      return $?
   fi

   local domain

   while [ "$#" -ne 0 ]
   do
      domain="$1"
      case "${domain}" in
         build)
            domain="project"
         ;;

         buildorder)
            domain="dependency"
         ;;
      esac

      functionname="sde_clean_${domain}_main"
      if [ "`type -t "${functionname}"`" = "function" ]
      then
         "${functionname}"
      else
         sde_clean_usage "Unknown clean domain \"$1\""
      fi
      shift
   done
}
