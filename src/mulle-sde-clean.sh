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


# Cleaning is a delightfully complex topic. You want to clean because you
# want to recompile your project fully. A symlinked dependency has changed.
# You want your sourcetree clean again. You want to fetch newer versions from
# repositories. mulle-sde goofed somewhere and you want to start anew.
# But you don't want to clean too much, because rebuilding takes time.
#
# Identifying major clean tasks:
#
#            |    project    |      all      |     tidy      |    fetch      |
# -----------|---------------|---------------|---------------|---------------|
# craft      |    project    |     build     |  build,dep    |  build,dep    |
# -----------|---------------|---------------|---------------|---------------|
# fetch      |               |               |               |    archive    |
# -----------|---------------|---------------|---------------|---------------|
# make       |      N/A      |      N/A      |      N/A      |      N/A      |
# -----------|---------------|---------------|---------------|---------------|
# match      |               |               |               |               |
# -----------|---------------|---------------|---------------|---------------|
# monitor    |               |               |               |               |
# -----------|---------------|---------------|---------------|---------------|
# sde        |      N/A      |      N/A      |      N/A      |      N/A      |
# -----------|---------------|---------------|---------------|---------------|
# sourcetree |               |               |  cln/rst/grv  |               |
# -----------|---------------|---------------|---------------|---------------|
#
#
# craft:       project, craftorder, built, individual build, build, dependency
# fetch:       archive cache, repository cache
# make:        nothing
# match:       patternfiles in var
# monitor:     locks and status files in var
# sde:         N/A
# sourcetree:  touch, clean, reset, graveyard
#
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
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2



EOF
   fi
   cat <<EOF >&2
Domains:
   all         : clean craftorder, project. Remove folder "`fast_basename "${DEPENDENCY_DIR}"`"
   archive     : clean the archive cache
   default     : clean project and subprojects (default)
   fetch       : clean to force a fresh fetch from remotes
   project     : clean project, keep dependencies
   repository  : clean the repository mirror
   subprojects : clean subprojects
   test        : clean tests
   tidy        : clean everything and remove fetched dependencies. It's slow!
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

   log_verbose "Cleaning \"addiction\" directory"
   [ ! -z "${ADDICTION_DIR}" ] && rmdir_safer "${ADDICTION_DIR}"

   sde_clean_kitchendir_main "$@"
   sde_clean_dependencydir_main "$@"
}


sde_clean_kitchendir_main()
{
   log_entry "sde_clean_kitchendir_main" "$@"

   KITCHEN_DIR="${KITCHEN_DIR:-${BUILD_DIR}}"

   if [ ! -z "${KITCHEN_DIR}" ]
   then
      log_verbose "Cleaning \"kitchen\" directory"
      rmdir_safer "${KITCHEN_DIR}"
   else
      log_fluff "KITCHEN_DIR unknown, so don't clean"
   fi
}


sde_clean_dependencydir_main()
{
   log_entry "sde_clean_dependencydir_main" "$@"

   if [ ! -z "${DEPENDENCY_DIR}" ]
   then
      log_verbose "Cleaning \"dependency\" directory"
      rmdir_safer "${DEPENDENCY_DIR}"
   else
      log_fluff "DEPENDENCY_DIR unknown, so don't clean"
   fi
}


sde_clean_project_main()
{
   log_entry "sde_clean_project_main" "$@"

   rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_CRAFT_FLAGS} \
               clean \
                  project
}


sde_clean_dependency_main()
{
   log_entry "sde_clean_dependency_main" "$@"

   log_verbose "Cleaning \"dependency\" directory"
   rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_CRAFT_FLAGS} \
               clean \
                  dependency
}


sde_clean_subproject_main()
{
   log_entry "sde_clean_subproject_main" "$@"

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || \
         internal_fail "missing file"
   fi

   local subprojects
   local subproject

   subprojects="`sde_subproject_get_addresses`"
   if [ -z "${subprojects}" ]
   then
      log_fluff "No subprojects, so done"
      return
   fi

   local name
   set -o noglob; IFS=$'\n'
   for subproject in ${subprojects}
   do
      r_fast_basename "${subproject}"
      name="${RVAL}"

      set +o noglob; IFS="${DEFAULT_IFS}"
      rexekutor "${MULLE_CRAFT:-mulle-craft}" \
            ${MULLE_TECHNICAL_FLAGS} \
            ${MULLE_CRAFT_FLAGS} \
            clean \
               "${name}"
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
}


sde_clean_craftordercache_main()
{
   log_entry "sde_clean_craftordercache_main" "$@"

   [ -z "${MULLE_SDE_VAR_DIR}" ] && internal_fail "MULLE_SDE_VAR_DIR not defined"

   log_verbose "Cleaning sde cache"
   rmdir_safer "${MULLE_SDE_VAR_DIR}/cache"
}


#
# this will destroy the craftorder
# also wipe archive cache. Does not wipe git mirror cache unless -f is given
# because thats supposed to be harmless
#
sde_clean_archive_main()
{
   log_entry "sde_clean_archive_main" "$@"

   if [ ! -z "${MULLE_FETCH_ARCHIVE_DIR}" ]
   then
      log_verbose "Cleaning archive cache"

      rmdir_safer "${MULLE_FETCH_ARCHIVE_DIR}"
   fi
}


sde_clean_repository_main()
{
   log_entry "sde_clean_repository_main" "$@"

   if [ ! -z "${MULLE_FETCH_MIRROR_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         log_verbose "Cleaning repository cache"

         rmdir_safer "${MULLE_FETCH_MIRROR_DIR}"
      fi
   fi
}


sde_clean_var_main()
{
   log_entry "sde_clean_var_main" "$@"

   log_verbose "Cleaning \".mulle-sde/var\" folder"

   rmdir_safer "${MULLE_SDE_VAR_DIR}"
}


sde_clean_db_main()
{
   log_entry "sde_clean_db_main" "$@"

   log_verbose "Cleaning sourcetree database"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               reset
}


sde_clean_sourcetree_main()
{
   log_entry "sde_clean_sourcetree_main" "$@"

   log_verbose "Cleaning sourcetree"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               clean
}


sde_clean_sourcetree_share_main()
{
   log_entry "sde_clean_sourcetree_share_main" "$@"

   log_verbose "Cleaning sourcetree and stash"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               clean --share
}


sde_clean_patternfile_main()
{
   log_entry "sde_clean_patternfile_main" "$@"

   log_verbose "Cleaning patternfiles"

   rexekutor "${MULLE_MATCH:-mulle-match}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_MONITOR_FLAGS} \
               clean
}


sde_clean_monitor_main()
{
   log_entry "sde_clean_monitor_main" "$@"

   log_verbose "Cleaning monitor files"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      rexekutor "${MULLE_MONITOR:-mulle-monitor}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_MONITOR_FLAGS} \
                  clean
}


sde_clean_graveyard_main()
{
   log_entry "sde_clean_graveyard_main" "$@"

   log_verbose "Cleaning graveyard"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               desecrate
}



sde_clean_test_main()
{
   log_entry "sde_clean_test_main" "$@"

   log_verbose "Cleaning test"

   rexekutor "${MULLE_TEST:-mulle-test}" \
                  -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               clean
}


sde_clean_main()
{
   log_entry "sde_clean_main" "$@"

   local OPTION_TEST="YES"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde_clean_usage
         ;;

         --no-test)
            OPTION_TEST="NO"
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
archive
craftorder
cache
default
dependency
fetch
project
repository
subprojects
tidy"
         exit 0
      ;;

      all)
         domains="kitchendir dependencydir craftordercache"
      ;;

      archive)
         domains="archive"
      ;;

      craftorder)
         rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_CRAFT_FLAGS} \
                     clean \
                        craftorder
      ;;

      cache)
         domains="archive repository"
      ;;

      default)
         domains="project subproject"
      ;;

      # used by mulle-craft implicitly via error message
      dependency)
         domains="dependencydir"
      ;;

      project)
         domains="project"
      ;;

      fetch)
         domains="sourcetree craftordercache output var db monitor patternfile archive"
      ;;

      subproject|subprojects)
         domains="subproject"
      ;;

      repository)
         domains="repository"
      ;;

      test)
         domains="test"
      ;;

      tidy)
         domains="sourcetree_share craftordercache graveyard output var db monitor patternfile"
      ;;

      *)
         if [ "${OPTION_TEST}" = "YES" ]
         then
            local escaped_dependency
            local targets
            local found

            r_escaped_grep_pattern "$1"
            escaped_dependency="${RVAL}"

            targets="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                                       -V \
                                       -s \
                                    craftorder \
                                       --no-output-marks | sed 's|^.*/||'`"
            found="`grep -x "${escaped_dependency}" <<< "${targets}" `"

            if [ -z "${found}" ]
            then
               fail "Unknown clean target \"$1\".
${C_VERBOSE}Known dependencies:
${C_RESET}`sort -u <<< "${targets}" | sed 's/^/   /'`
"
            fi
         fi

         rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_CRAFT_FLAGS} \
                     clean \
                        "$1"
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
