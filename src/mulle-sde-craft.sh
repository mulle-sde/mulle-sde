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
MULLE_SDE_CRAFT_SH="included"


sde_craft_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} craft [options] [target] ...

   Build the dependency folder and/or the project according to target. The
   remaining arguments after target are passed to mulle-craft. See
   \`mulle-craft project|buildorder> help\` for all the options available.

   The dependency folder is built in order of \`mulle-sde buildorder\`.

Options:
   -h         : show this usage
   -q         : skip uptodate checks
   --clean    : clean before crafting (see: mulle-sde clean)
   --clean-domain <domain> : clean specific domain before casting (s.a)

Targets:
   all        : build dependency folder first, then the project (default)
   buildorder : build dependency folder
   <name>     : name of a single entry in the buildorder
   project    : build the project

Environment:
   MULLE_SDE_CRAFT_TARGET        : default craft target (${target})
   MULLE_SDE_MAKE_FLAGS          : flags to be passed to mulle-make (via craft)
   MULLE_SDE_UPDATE_CALLBACKS    : callback called during update
   MULLE_SDE_UPDATE_BEFORE_CRAFT : force update before craft (${MULLE_SDE_UPDATE_BEFORE_CRAFT:-NO})
EOF
   exit 1
}


sde_perform_updates()
{
   log_entry "sde_pre_update" "$@"

   local target="$1"
   local buildorderfile="$2"
   local cachedir="$3"
   local OPTION_UPDATE="$4"

   local dbrval

   dbrval=0

   local updateflags
   local tasks

   updateflags="--if-needed"

   case ":${MULLE_SDE_UPDATE_CALLBACKS}:" in
      *:source:*)
         tasks="source"
      ;;
   esac

   #
   # Make a quick estimate if this is a virgin checkout scenario, by checking
   # the buildorder file exist
   # If yes, then lets update once. If there is no buildorder file, let's
   # do it
   #
   if [ "${MULLE_SDE_UPDATE_BEFORE_CRAFT}" = 'YES' ]
   then
      log_debug "MULLE_SDE_UPDATE_BEFORE_CRAFT forces update"
      updateflags="" # "force" update
   fi

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                 -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
                 -s \
                  dbstatus
   dbrval="$?"
   log_fluff "dbstatus is $dbrval (0: ok, 1: missing, 2:dirty)"

   #
   # Check if we need to update the sourcetree.
   # This could fetch dependencies if required.
   # A 1 here means we have no sourcetree.
   #
   if [ ${dbrval} -eq 2 ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"

      if [ "${MULLE_SDE_FETCH}" = 'NO' ]
      then
         log_info "Fetching is disabled by environment MULLE_SDE_FETCH"
      else
         log_verbose "Run sourcetree update"

         eval_exekutor "'${MULLE_SOURCETREE:-mulle-sourcetree}'" \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              "${MULLE_SOURCETREE_FLAGS}" \
                           "update" || exit 1
      fi
      updateflags='' # db "force" update
   fi

   # run task sourcetree, if present (0) or was dirty (2)
   if [ ${dbrval} -ne 1 ]
   then
      case ":${MULLE_SDE_UPDATE_CALLBACKS}:" in
         *:sourcetree:*)
            tasks="${tasks} sourcetree"
         ;;
      esac
   fi

   if [ "${target}" = 'all' -o "${target}" = 'project' ]
   then
      [ -z "${MULLE_SDE_UPDATE_SH}" ] && \
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-update.sh"

      sde_update_main ${updateflags} ${tasks} || exit 1
   fi

   #
   # at this point, it's better to clean, because cmake caches might
   # get outdated (sourcetree updates don't run this often)
   #
   if [ ${dbrval} -eq 2 ]
   then
      [ -z "${MULLE_SDE_CLEAN_SH}" ] && \
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-clean.sh"

      sde_clean_main --no-test
   fi

   #
   # Possibly build a new buildorder file for sourcetree changes
   #
   case ${dbrval} in
      0)
         create_buildorder_file_if_needed "${buildorderfile}" "${cachedir}"
      ;;

      2)
         create_buildorder_file "${buildorderfile}" "${cachedir}"
      ;;
   esac
}

#
# Dont't make it too complicated, mulle-sde craft builds 'all' or the desired
# user selected style.
#
sde_craft_main()
{
   log_entry "sde_craft_main" "$@"

   local target
   local OPTION_UPDATE='YES'
   local OPTION_MOTD='YES'

   target="${MULLE_SDE_CRAFT_TARGET}"
   if [ "${PROJECT_TYPE}" = "none" ]
   then
      if [ -z "${target}" ]
      then
         target="buildorder"
         OPTION_UPDATE='NO'
      fi
   fi
   target="${target:-all}"

   while :
   do
      #
      # reparse technical flags here, because we want to have -v and friends
      # even if we use the "craft" alias inside the subshell
      #
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -h|--help|help)
            sde_craft_usage
         ;;

         -q|--quick|no-update)
            OPTION_UPDATE='NO'
         ;;

         --clean)
            [ -z "${MULLE_SDE_CLEAN_SH}" ] && \
               . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"
            sde_clean_main
         ;;

         --clean-domain)
            [ $# -eq 1 ] && sde_craft_usage "Missing argument to \"$1\""
            shift

            [ -z "${MULLE_SDE_CLEAN_SH}" ] && \
               . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"

            sde_clean_main "$1"
         ;;

         --no-motd)
            OPTION_MOTD='NO'
         ;;

         -V)
            # old flag silently ignored
         ;;

         ''|-*)
            break
         ;;

         *)
            target="$1"
            OPTION_UPDATE='NO'
            shift
            break
         ;;
      esac
      shift
   done


   #
   # our buildorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"
   [ -z "${MULLE_SDE_BUILDORDER_SH}" ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-buildorder.sh"

   local _buildorderfile
   local _cachedir

   __get_buildorder_info

   #
   # Things to do:
   #
   #  1. possibly sync the sourcetree db/fs/config if needed
   #  2. possibly run a mulle-sde update if needed
   #  3. possibly create a new buildorder file
   #  4. possibly clean build
   #
   sde_perform_updates "${target}" \
                       "${_buildorderfile}" \
                       "${_cachedir}" \
                       "${OPTION_UPDATE}"

   #
   # by default, we don't want to see the buildorder verbosity
   # but do like to see project verbosity
   #
   local buildorder_cmdline
   local project_cmdline
   local flags
   r_concat "${MULLE_TECHNICAL_FLAGS}" "${MULLE_CRAFT_FLAGS}"
   flags="${RVAL}"

   buildorder_cmdline="'${MULLE_CRAFT:-mulle-craft}' ${flags}"

   if [ -z "${flags}" -a "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
   then
      flags="-v"
   fi

   project_cmdline="'${MULLE_CRAFT:-mulle-craft}' ${flags}"
   if [ "${OPTION_MOTD}" = 'YES' ]
   then
      project_cmdline="${project_cmdline} '--motd'"
   fi

   local arguments

   if [ "${MULLE_SDE_ALLOW_BUILD_SCRIPT}" = 'YES' ]
   then
      arguments="--allow-script"
   fi

   local mulle_make_flags
   local need_dashdash='YES'
   local i

   while [ $# -ne 0  ]
   do
      if [ "$1" = '--' ]
      then
         need_dashdash='NO'
      fi

      arguments="${arguments} '$1'"
      shift
   done

   if [ ! -z "${MULLE_SDE_MAKE_FLAGS}" ]
   then
      if [ "${need_dashdash}" = 'YES' ]
      then
         arguments="${arguments} '--'"
      fi

      local i

      shopt -s nullglob
      for i in ${MULLE_SDE_MAKE_FLAGS}
      do
         arguments="${arguments} '$i'"
      done
      shopt -u nullglob
   fi

#   log_fluff "Craft ${C_RESET_BOLD}${target}${C_VERBOSE} of project ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}"

   case "${target}" in
      'all')
         if [ -f "${_buildorderfile}" ]
         then
            eval_exekutor "${buildorder_cmdline}" \
                                 --buildorder-file "'${_buildorderfile}'" \
                              buildorder \
                                 --no-memo-makeflags "'${flags}'" \
                                 "${arguments}" || return 1
         else
            log_fluff "No buildorderfile so skipping buildorder craft step"
         fi
      ;;

      'buildorder')
         if [ -f "${_buildorderfile}" ]
         then
            eval_exekutor "${buildorder_cmdline}" \
                                 --buildorder-file "'${_buildorderfile}'" \
                              buildorder \
                                 --no-memo-makeflags "'${flags}'" \
                                 "${arguments}" || return 1
         else
            log_info "There are no dependencies or libraries to build"
            log_fluff "${_buildorderfile} does not exist"
         fi
      ;;

      "")
         internal_fail "target is empty"
      ;;

      *)
         if [ -f "${_buildorderfile}" ]
         then
            eval_exekutor "${buildorder_cmdline}" \
                                 --buildorder-file "'${_buildorderfile}'" \
                              "${target}" \
                                 --no-memo-makeflags "'${flags}'" \
                                 "${arguments}" || return 1
         else
            log_info "There are no dependencies or libraries to build"
            log_fluff "${_buildorderfile} does not exist"
         fi
      ;;
   esac

   case "${target}" in
      'project'|'all')
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${target}" \
            eval_exekutor "${project_cmdline}" project "${arguments}" || return 1
   esac
}



sde_buildstatus_main()
{
   log_entry "sde_buildstatus_main" "$@"

   local _buildorderfile
   local _cachedir

   __get_buildorder_info

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_CRAFT:-mulle-craft}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_CRAFT_FLAGS} \
                  status \
                     -f "${_buildorderfile}" \
                     "$@"
}
