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
   ${MULLE_USAGE_NAME} craft [options] [command] ...

   Build the dependency folder and the project.

   The dependency folder is built with using the \`mulle-sde buildorder\` file.

   This is a frontend to mulle-craft <project|buildorder>. See
   \`mulle-craft help\` for all the options available.

Options:
   -h         : show this usage
   -q         : skip uptodate checks

Commands:
   all        : build dependency folder first, then the project (default)
   buildorder : build dependency folder
   dependency : synoym for buildorder
   project    : build the project

EOF
   exit 1
}


append_mark_no_memo_to_subproject()
{
   if [ "${MULLE_NODETYPE}" != "local" -o "${MULLE_DATASOURCE}" != "/" ]
   then
      return
   fi

   case ",${MULLE_MARKS}," in
      *",no-dependency,"*)
         return
      ;;
   esac

   MULLE_MARKS="`comma_concat "${MULLE_MARKS}" "no-memo" `"
}


#
# This should be another task so that it can run in parallel to the other
# updates
#
create_buildorder_file()
{
   log_entry "create_buildorder_file" "$@"

   local buildorderfile="$1"
   local cachedir="$2"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
   fi

   log_info "Updating ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} buildorder"

   mkdir_if_missing "${cachedir}"
   if ! redirect_exekutor "${buildorderfile}" \
      "${MULLE_SOURCETREE}" -V ${MULLE_SOURCETREE_FLAGS} \
         buildorder \
            --output-marks ${MULLE_CRAFT_BUILDORDER_OPTIONS} \
            --callback "`declare -f append_mark_no_memo_to_subproject`"
   then
      remove_file_if_present "${buildorderfile}"
      exit 1
   fi
}


create_buildorder_file_if_needed()
{
   log_entry "create_buildorder_file_if_needed" "$@"

   local buildorderfile="$1"
   local cachedir="$2"

   local sourcetreefile
   local buildorderfile
   #
   # our buildorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"

   sourcetreefile="${MULLE_VIRTUAL_ROOT}/.mulle-sourcetree/etc/config"

   #
   # produce a buildorderfile, if absent or old
   #
   if [ "${sourcetreefile}" -nt "${buildorderfile}" ]
   then
      create_buildorder_file "${buildorderfile}" "${cachedir}"
   else
      log_fluff "Buildorder file \"${buildorderfile}\" is up-to-date"
   fi
}

#
# Dont't make it too complicated, mulle-sde craft builds 'all' or the desired
# user selected style.
#
sde_craft_main()
{
   log_entry "sde_craft_main" "$@"

   local cmd
   local OPTION_UPDATE="YES"
   local OPTION_MOTD="YES"

   cmd="${MULLE_SDE_CRAFT_STYLE:-all}"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_craft_usage
         ;;

         -q|--quick|no-update)
            OPTION_UPDATE="NO"
         ;;

         --no-motd)
            OPTION_MOTD="NO"
         ;;

         all|buildorder|dependency|project)
            cmd="$1"
            shift
            break
         ;;

         *)
            break
         ;;
      esac
      shift
   done


   #
   # our buildorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"

   local buildorderfile
   local cachedir
   local buildorderfilename

   cachedir="${MULLE_SDE_DIR}/var/${MULLE_HOSTNAME}/cache"
   buildorderfilename="buildorder"  # might make this flexible
   buildorderfile="${cachedir}/${buildorderfilename}"

   if [ "${OPTION_UPDATE}" = "YES" ]
   then
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
      # the buildorder file exisz
      # If yes, then lets update once. If there is no buildorder file, let's
      # do it
      #
      if [ "${MULLE_SDE_UPDATE_BEFORE_CRAFT}" = "YES" ]
      then
         log_debug "MULLE_SDE_UPDATE_BEFORE_CRAFT forces update"
         updateflags="" # "force" update
      fi

      #
      # Check if we need to update the sourcetree.
      # This could fetch dependencies if required.
      # A 1 here means we have no sourcetree.
      #
      local dbrval

      "${MULLE_SOURCETREE}" -V ${MULLE_SOURCETREE_FLAGS} -s dbstatus
      dbrval="$?"
      log_debug "dbstatus is $dbrval (0: ok, 1: missing, 2:dirty)"

      if [ ${dbrval} -eq 2 ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"

         if [ "${MULLE_SDE_FETCH}" = "NO" ]
         then
            log_info "Fetching is disabled by environment MULLE_SDE_FETCH"
         else
            log_verbose "Run sourcetree update"

            eval_exekutor "'${MULLE_SOURCETREE}'" \
                           "${MULLE_SOURCETREE_FLAGS}" "update" || exit 1
         fi
         updateflags="" # db "force" update
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

      if [ "${OPTION_UPDATE}" = "YES" ]
      then
         if [ -z "${MULLE_SDE_UPDATE_SH}" ]
         then
            . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-update.sh"
         fi

         sde_update_main ${updateflags} ${tasks} || exit 1
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
   fi

   # get a bit of environment happening for actual crafting
   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   set_projectname_environment "read"

   local cmdline

   cmdline="'${MULLE_CRAFT}' ${MULLE_TECHNICAL_FLAGS} ${MULLE_CRAFT_FLAGS}"
   if [ "${OPTION_MOTD}" = "YES" ]
   then
      cmdline="${cmdline} '--motd'"
   fi

   local arguments

   while [ $# -ne 0  ]
   do
      arguments="${arguments} '$1'"
      shift
   done

   log_verbose "Craft \"${cmd}\" project \"${PROJECT_NAME}\""

   case "${cmd}" in
      'all')
         if [ -f "${buildorderfile}" ]
         then
            MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${cmd}" \
               eval_exekutor "${cmdline}" buildorder \
                                          --buildorder-file "'${buildorderfile}'" \
                                          "${arguments}" || return 1
         else
            log_fluff "No buildorderfile so skipping buildorder craft step"
         fi
      ;;

      'buildorder'|'dependency')
         if [ -f "${buildorderfile}" ]
         then
            MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${cmd}" \
               eval_exekutor "${cmdline}" buildorder \
                                          --buildorder-file "'${buildorderfile}'" \
                                          "${arguments}" || return 1
         else
            log_info "There are no dependencies or libraries to build"
         fi
      ;;
   esac

   case "${cmd}" in
      'project'|'all')
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${cmd}" \
            eval_exekutor "${cmdline}" project "${arguments}" || return 1
   esac
}
