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

   The dependency folder is built with he \`mulle-sde buildorder\` file.

   This is a frontend to mulle-craft <project|buildorder>. See
   \`mulle-craft help\` for all the options available.


Options:
   -h         : show this usage

Commands:
   all        : build dependency folder first then the project (default)
   dependency : build dependency folder only
   project    : build the project only

EOF
   exit 1
}


#
# Dont't make it too complicated, mulle-sde craft builds 'all' or the desired
# user selected style
#
sde_craft_main()
{
   log_entry "sde_craft_main" "$@"

   local cmd
   local updateflags

   cmd="${MULLE_SDE_CRAFT_STYLE:-all}"

   case "$1" in
      -h|--help|help)
         sde_craft_usage
      ;;

      ""|-*)
      ;;

      all|dependency|project)
         cmd="$1"
         shift
      ;;
   esac

   updateflags="--if-needed"
   #
   # Make a quick estimate if this is a virgin checkout scenario
   # If yes, then lets update once (why ?, noob support ?)
   #
   if [ "${MULLE_SDE_UPDATE_BEFORE_CRAFT}" != "NO" ] && [ ! -d "${DEPENDENCY_DIR}" ]
   then
      # for mulle-c11, which has only a .mulle-env but no .mulle-sde
      if [ -d "${MULLE_SDE_DIR}" ]
      then
         log_fluff "Directory \"dependency\" does not exist, so run update once"
         MULLE_SDE_UPDATE_BEFORE_CRAFT="YES"
         updateflags="" # "force" update
      fi
   fi

   if [ "${MULLE_SDE_UPDATE_BEFORE_CRAFT}" = "YES" ] # usually from environment
   then
      tasks="source"
   fi

   #
   # Check if we need to update. If we do, we do.
   # This will fetch dependencies if required. An error here means we have
   # no sourcetree
   #
   local dbrval

   "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} -s dbstatus
   dbrval="$?"

   if [ ${dbrval} -eq 2 ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"

      log_verbose "Run sourcetree update"

      eval_exekutor "'${MULLE_SOURCETREE}'" \
                     "${MULLE_SOURCETREE_FLAGS}" "update" || exit 1
   fi

   if [ ${dbrval} -ne 0 ]
   then
      tasks="${tasks} sourcetree"
   fi

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   set_projectname_environment "read"

   if [ ! -z "${tasks}" ]
   then
      if [ -z "${MULLE_SDE_UPDATE_SH}" ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-update.sh"
      fi

      sde_update_main ${updateflags} ${tasks}
   fi

   local cmdline
   local buildorderfile

   cmdline="'${MULLE_CRAFT}' ${MULLE_TECHNICAL_FLAGS} ${MULLE_CRAFT_FLAGS}"

   if [ ${dbrval} -ne 1 ]
   then
      local sourcetreefile
      local statefile
      local cachedir

      #
      # our buildorder is specific to a host
      #
      [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"

      cachedir="${MULLE_SDE_DIR}/var/${MULLE_HOSTNAME}/cache"
      buildorderfile="${cachedir}/buildorder"
      statefile="${DEPENDENCY_DIR}/.state"
      sourcetreefile=".mulle-sourcetree/etc/config"

      #
      # produce a buildorderfile, if absent or old
      #
      if [ "${sourcetreefile}" -nt "${buildorderfile}" ]
      then
         if [ -z "${MULLE_PATH_SH}" ]
         then
            . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
         fi
         if [ -z "${MULLE_FILE_SH}" ]
         then
            . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
         fi

         log_verbose "Create buildorder file (${buildorderfile})"

         mkdir_if_missing "${cachedir}"
         if ! redirect_exekutor "${buildorderfile}" \
            "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} buildorder \
                 --output-marks ${MULLE_CRAFT_BUILDORDER_OPTIONS} 
         then
            remove_file_if_present "${buildorderfile}"
            exit 1
         fi 
      fi
   fi

   cmdline="${cmdline} --motd"

   local arguments

   while [ $# -ne 0  ]
   do
      arguments="${arguments} '$1'"
      shift
   done

   log_verbose "Craft \"${cmd}\" project \"${PROJECT_NAME}\""

   if [ "${cmd}" != "project" ]
   then
      if [ ! -z "${buildorderfile}" ]
      then
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${cmd}" \
            eval_exekutor "${cmdline}" buildorder \
                                       --buildorder-file "'${buildorderfile}'" \
                                       "${arguments}" || return 1
      fi
   fi

   if [ "${cmd}" != "dependency" ]
   then
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${cmd}" \
         eval_exekutor "${cmdline}" project "${arguments}"
   fi
}
