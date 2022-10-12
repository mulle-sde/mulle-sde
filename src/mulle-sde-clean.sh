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


# Cleaning is a delightfully complex topic. You want to "clean all" because you
# want to recompile your project fully. A symlinked dependency has changed.
# You want your sourcetree clean again. You want to fetch newer versions from
# repositories with "clean tidy" or mulle-sde goofed somewhere and you want to
# start anew.
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
# sourcetree |               |               |  cln/rst      |               |
# -----------|---------------|---------------|---------------|---------------|
#
#
# craft:       project, craftorder, built, individual build, build, dependency
# fetch:       archive cache, mirror cache
# make:        nothing
# match:       patternfiles in var
# monitor:     locks and status files in var
# sde:         N/A
# sourcetree:  touch, clean, reset  (do not clear graveyards,)
#
sde::clean::domains_usage()
{
   cat <<EOF
   all         : clean craftinfos, craftorder, project. Remove folder "`basename -- "${DEPENDENCY_DIR}"`"
   archive     : clean the archive cache
   craftorder  : clean all dependencies
   craftinfos  : clean craftinfos
   default     : clean project and subprojects (default)
   fetch       : clean to force a fresh fetch from remotes
   graveyard   : clean graveyard (which can become quite large)
   gravetidy   : clean everything and graveyards (tidy + graveyard)
   mirror      : clean the repository mirror
   project     : clean project, keep dependencies
   subprojects : clean subprojects
   test        : clean tests
   tidy        : clean everything (except archive and graveyard). It's slow!
EOF
}


sde::clean::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean [options] [domain|dependency]

   Cleans various parts of the mulle-sde system. After a clean all, mulle-sde
   will rebuild your project including subprojects and dependencies.
   Use \`${MULLE_USAGE_NAME} -v -n -lx clean\` to preview, what will be
   cleaned.

   Instead of a domain, you can also specify a dependency to clean. Your
   project will be built from this point. "clean" only cleans the specified
   project and forces a rebuild from this point. It does not clean in
   subsequent projects. It's up to the build system to act on the necessary
   changes. This works most of the time but:

      When in doubt, clean all.
      When still in doubt, clean tidy.
      If doubts persist, clean cache.
      Only then give up.

Options:
   --no-graveyard : do not create backups in graveyard
   --no-test      : do not check, if a dependecy exists

Environment:
   MULLE_SDE_CLEAN_DEFAULT : default domains to clear 
EOF

   cat <<EOF >&2

Domains:
EOF
   sde::clean::domains_usage >&2
   exit 1
}


#
# use rexekutor to show call, put pass -n flag via technical flags so
# nothing gets actually deleted with -n
#
sde::clean::kitchendir()
{
   log_entry "sde::clean::kitchendir" "$@"

   KITCHEN_DIR="${KITCHEN_DIR:-${BUILD_DIR}}"

   if [ ! -z "${KITCHEN_DIR}" ]
   then
      log_verbose "Cleaning \"kitchen\" directory"
      rmdir_safer "${KITCHEN_DIR}"
   else
      log_fluff "KITCHEN_DIR unknown, so don't clean"
   fi
}


sde::clean::dependencydir()
{
   log_entry "sde::clean::dependencydir" "$@"

   if [ ! -z "${DEPENDENCY_DIR}" ]
   then
      log_verbose "Cleaning \"dependency\" directory"
      rmdir_safer "${DEPENDENCY_DIR}"
   else
      log_fluff "DEPENDENCY_DIR unknown, so don't clean"
   fi
}


sde::clean::output()
{
   log_entry "sde::clean::output" "$@"

   log_verbose "Cleaning \"addiction\" directory"
   [ ! -z "${ADDICTION_DIR}" ] && rmdir_safer "${ADDICTION_DIR}"

   sde::clean::kitchendir "$@"
   sde::clean::dependencydir "$@"
}


sde::clean::dependency()
{
   log_entry "sde::clean::dependency" "$@"

   log_verbose "Cleaning \"dependency\" directory"
   rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean \
                  dependency
}


sde::clean::project()
{
   log_entry "sde::clean::project" "$@"

   rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean \
                  project
}


sde::clean::craftinfo()
{
   log_entry "sde::clean::craftinfo" "$@"

   if [ -z "${MULLE_SDE_CRAFTINFO_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftinfo.sh" || \
         _internal_fail "missing file"
   fi

   local craftinfos
   local craftinfo

   craftinfos="`sde::craftinfo::get_addresses`"
   if [ -z "${craftinfos}" ]
   then
      log_fluff "No craftinfos, so done"
      return
   fi

   shell_disable_glob; IFS=$'\n'
   for craftinfo in ${craftinfos}
   do
      shell_enable_glob; IFS="${DEFAULT_IFS}"
      rexekutor "${MULLE_CRAFT:-mulle-craft}" \
            ${MULLE_TECHNICAL_FLAGS} \
            clean \
               "${craftinfo}"
   done
   shell_enable_glob; IFS="${DEFAULT_IFS}"
}


sde::clean::subproject()
{
   log_entry "sde::clean::subproject" "$@"

   if [ -z "${MULLE_SDE_SUBPROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-subproject.sh" || \
         _internal_fail "missing file"
   fi

   local subprojects
   local subproject

   subprojects="`sde::subproject::get_addresses`"
   if [ -z "${subprojects}" ]
   then
      log_fluff "No subprojects, so none to clean."
      return
   fi

   local name

   shell_disable_glob; IFS=$'\n'
   for subproject in ${subprojects}
   do
      r_basename "${subproject}"
      name="${RVAL}"

      shell_enable_glob; IFS="${DEFAULT_IFS}"
      rexekutor "${MULLE_CRAFT:-mulle-craft}" \
            ${MULLE_TECHNICAL_FLAGS} \
            clean \
               "${name}"
   done
   shell_enable_glob; IFS="${DEFAULT_IFS}"
}


sde::clean::craftordercache()
{
   log_entry "sde::clean::craftordercache" "$@"

   [ -z "${MULLE_SDE_VAR_DIR}" ] && _internal_fail "MULLE_SDE_VAR_DIR not defined"

   log_verbose "Cleaning sde cache"
   remove_file_if_present "${MULLE_SDE_VAR_DIR}/cache/craftorder"
}


#
# this will destroy the craftorder
# also wipe archive cache. Does not wipe git mirror cache unless -f is given
# because thats supposed to be harmless
#
sde::clean::archive()
{
   log_entry "sde::clean::archive" "$@"

   if [ ! -z "${MULLE_FETCH_ARCHIVE_DIR}" ]
   then
      log_verbose "Cleaning archive cache \"${MULLE_FETCH_ARCHIVE_DIR#${MULLE_USER_PWD}/}\""

      rmdir_safer "${MULLE_FETCH_ARCHIVE_DIR}"
   else
      log_warning "MULLE_FETCH_ARCHIVE_DIR is not defined"
   fi
}


sde::clean::mirror()
{
   log_entry "sde::clean::mirror" "$@"

   if [ ! -z "${MULLE_FETCH_MIRROR_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         log_verbose "Cleaning repository mirror \"${MULLE_FETCH_MIRROR_DIR#${MULLE_USER_PWD}/}\""

         rmdir_safer "${MULLE_FETCH_MIRROR_DIR}"
      else
         log_warning "Need -f flag for mirror cleaning"
      fi
   else
      log_warning "MULLE_FETCH_MIRROR_DIR is not defined"
   fi
}


sde::clean::var()
{
   log_entry "sde::clean::var" "$@"

   log_verbose "Cleaning \"${MULLE_SDE_VAR_DIR}\" folder"

   rmdir_safer "${MULLE_SDE_VAR_DIR}"
}


sde::clean::tmp()
{
   log_entry "sde::clean::tmp" "$@"

   local dir

   shell_enable_nullglob
   for dir in .mulle/var/*/*/tmp  .mulle/var/*/tmp
   do
      shell_disable_nullglob
      if [ -d "${dir}" ]
      then
         log_verbose "Cleaning \"${dir}\" folder"

         rmdir_safer "${dir}"
      fi
   done
   shell_disable_nullglob
}


sde::clean::db()
{
   log_entry "sde::clean::db" "$@"

   log_verbose "Cleaning sourcetree database"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
               reset
}


sde::clean::sourcetree()
{
   log_entry "sde::clean::sourcetree" "$@"

   log_verbose "Cleaning sourcetree"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean
}


sde::clean::sourcetree_share()
{
   log_entry "sde::clean::sourcetree_share" "$@"

   log_verbose "Cleaning sourcetree and stash"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean --share
}


sde::clean::patternfile()
{
   log_entry "sde::clean::patternfile" "$@"

   log_verbose "Cleaning patternfiles"

   rexekutor "${MULLE_MATCH:-mulle-match}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean
}


sde::clean::monitor()
{
   log_entry "sde::clean::monitor" "$@"

   log_verbose "Cleaning monitor files"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      rexekutor "${MULLE_MONITOR:-mulle-monitor}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                  clean
}


sde::clean::graveyard()
{
   log_entry "sde::clean::graveyard" "$@"

   log_verbose "Cleaning graveyard"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
               desecrate
}


sde::clean::test()
{
   log_entry "sde::clean::test" "$@"

   log_verbose "Cleaning test"

   rexekutor "${MULLE_TEST:-mulle-test}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean
}


sde::clean::testall()
{
   log_entry "sde::clean::testall" "$@"

   log_verbose "Cleaning all test"

   rexekutor "${MULLE_TEST:-mulle-test}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               clean all
}



sde::clean::main()
{
   log_entry "sde::clean::main" "$@"

   local OPTION_TEST="YES"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help|help)
            sde::clean::usage
         ;;

         --no-graveyard)
            MULLE_SOURCETREE_GRAVEYARD_ENABLED='NO'
            export MULLE_SOURCETREE_GRAVEYARD_ENABLED
         ;;

         --no-test)
            OPTION_TEST="NO"
         ;;

         --no-default)
            MULLE_SDE_CLEAN_DEFAULT=
         ;;

         -*)
            sde::clean::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   DEPENDENCY_DIR="${DEPENDENCY_DIR:-${MULLE_CRAFT_DEPENDENCY_DIR}}"
   DEPENDENCY_DIR="${DEPENDENCY_DIR:-${MULLE_VIRTUAL_ROOT}/${MULLE_CRAFT_DEPENDENCY_DIRNAME:-dependency}}"

   KITCHEN_DIR="${KITCHEN_DIR:-${MULLE_CRAFT_KITCHEN_DIR}}"
   KITCHEN_DIR="${KITCHEN_DIR:-${MULLE_VIRTUAL_ROOT}/${MULLE_CRAFT_KITCHEN_DIRNAME:-kitchen}}"

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

   [ $# -gt 1 ] && shift && sde::clean::usage "superflous arguments \"$*\""

   case "${1:-default}" in
      'domains')
         echo "\
all
alltestall
archive
craftinfos
craftorder
cache
default
dependency
fetch
graveyard
gravetidy
mirror
project
subprojects
tidy
test"
         exit 0
      ;;

      all)
         domains="kitchendir dependencydir craftordercache"
      ;;

      alltestall)
         domains="kitchendir dependencydir craftordercache testall"
      ;;

      archive)
         domains="archive"
      ;;

      craftinfo|craftinfos)
         domains="craftinfo"
      ;;

      craftorder)
         rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                     clean \
                        craftorder
      ;;

      cache)
         domains="archive mirror"
      ;;

      default)
         r_concat "${MULLE_SDE_CLEAN_DEFAULT}" "project subproject"
         domains="${RVAL}"
      ;;

      # used by mulle-craft implicitly via error message
      dependency)
         domains="dependencydir"
      ;;

      project)
         domains="project"
      ;;

      fetch)
         domains="sourcetree craftordercache output db monitor patternfile archive"
      ;;

      graveyard)
         domains="graveyard"
      ;;

      gravetidy|grave-tidy|gtidy)
         domains="graveyard sourcetree_share craftordercache output var db monitor patternfile"
         MULLE_SOURCETREE_GRAVEYARD_ENABLED='NO'
         export MULLE_SOURCETREE_GRAVEYARD_ENABLED
      ;;

      subproject|subprojects)
         domains="subproject"
      ;;

      mirror|repository)
         domains="mirror"
      ;;

      test)
         domains="test"
      ;;

      tidy)
         domains="sourcetree_share craftordercache output var db monitor patternfile"
      ;;

      tmp)
         domains="tmp"
      ;;

      domains-usage)
         sde::clean::domains_usage
         return 0
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
                                       --virtual-root \
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

         local target

         target="$1"

#         case "${MULLE_UNAME}" in
#            darwin)
#               if [ ! -z "${target}" -a "${target}" != "${PROJECT_NAME}" ]
#               then
#                  fail "Cleaning of a dependency by name leads to misery on Mac OS.
#${C_INFO}Work around: ${C_RESET_BOLD}clean all"
#               fi
#            ;;
#         esac
         rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                     clean \
                        "${target}"
         return $?
      ;;
   esac

   local functionname
   local rval 

   rval=0
   shell_disable_glob
   for domain in ${domains}
   do
      shell_enable_glob

      functionname="sde::clean::${domain}"
      if shell_is_function "${functionname}"
      then
         "${functionname}"
         if [ $? -ne 0 ]
         then
            log_debug "${functionname} failed"
            rval=1
         fi
      else
         # log_verbose "Clean ${domain}"
         rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                     clean \
                        "${domain}"
      fi
   done
   shell_enable_glob

   return $rval
}
