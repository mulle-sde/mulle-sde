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
MULLE_SDE_STATUS_SH="included"


sde_status_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} status

   Get some information about the current mulle-sde environment (if any).
EOF
   exit 1
}


sde_status_main()
{
   log_entry "sde_status_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_status_usage
         ;;

         -*)
            sde_status_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] || sde_status_usage "Superflous arguments \"$*\""

   if [ -z "${MULLE_STRING_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh" || return 1
   fi
   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
   fi

   local rval
   local projectdir
   local parentdir
   local directory
   local mode=indir

   directory="`pwd -P`"

   if ! r_determine_project_dir "${directory}"
   then
      log_warning "There is no mulle-sde project here"
      if [ -d .mulle-sde ]
      then
        log_warning "There is and old possibly upgradable mulle-sde project here"
      fi
      if [ -d .mulle-env ]
      then
        log_warning "There is and old possibly upgradable mulle-env environment here"
      fi
      if [ -d .mulle-bootstrap ]
      then
        log_warning "There is and old non-upgradable mulle-bootstrap project here"
      fi
      exit 1
   fi

   projectdir="${RVAL}"
   if [ "${directory}" != "${projectdir}" ]
   then
      log_verbose "The project directory is ${projectdir}"
   else
      log_verbose "The project directory is ${projectdir}"
   fi

   r_fast_dirname "${projectdir}"
   if r_determine_project_dir "${RVAL}"
   then
      parentdir="${RVAL}"
      log_verbose "The parent directory is ${parentdir}"
   fi


   if [ "${projectdir}" != "${directory}" ]
   then
      mode=inproject
   fi

   if [ "${parentdir}" != "${projectdir}" -a -e "${projectdir}/.mulle/share/env/defer" ]
   then
      mode=inparent
   fi

   rval=0

   case "${mode}" in
      indir)
         if [ -z "${parentdir}" ]
         then
            log_verbose "mulle-sde commands are executed here."
         else
            log_info "mulle-sde has a parent project ${parentdir}, but \
commands are executed here"
         fi
      ;;

      inproject)
         log_info "mulle-sde commands are executed in the project directory ${C_RESET_BOLD}${projectdir}"
      ;;

      inparent)
         log_info "mulle-sde commands are deferred to the parent project directory ${C_RESET_BOLD}${parentdir}"
      ;;
   esac


   if [ "${directory}" != "${projectdir}" ]
   then
      log_verbose "The current directory is ${directory}"
   fi

   if [ ! -z "${projectdir}" ]
   then
      exekutor cd "${projectdir}" || exit 1
   fi

   if [ ! -f .mulle/etc/sourcetree/config ]
   then
      log_info "There is no sourcetree ($PWD)"
   else
      local state
      local expect_dependencydir

      if mulle-sourcetree -s dbstatus
      then
         log_info "Nothing needs to be fetched"
      else
         log_info "Dependencies need to be fetched"
         log_verbose "${C_RESET_BOLD}   mulle-sde fetch"
      fi

      if [ -d "${MULLE_SOURCETREE_STASH_DIRNAME:-stash}" ]
      then
         local file
         local hassymlinks
         local hasdirs
         local stashdir

         stashdir="${MULLE_SOURCETREE_STASH_DIRNAME:-stash}"
         for file in "${stashdir}"/*
         do
            if [ -L "${file}" ]
            then
               r_resolve_symlinks "${file}"
               if [ -z "${RVAL}" -o ! -e "${RVAL}" ]
               then
                  log_error "${C_ERROR}Symlink ${C_RESET_BOLD}${file}${C_ERROR} is broken"
               fi
               hassymlinks='YES'
            else
               # sometimes we'd prefer this to be a symlink, but mistaken fetch
               # placed a real folder here. Hard to check though
               if [ -d "${file}" ]
               then
                  hasdirs='YES'
               fi
            fi
         done

         if [ "${hasdirs}" = 'YES' -a "${hassymlinks}" = 'YES' ]
         then
            log_info "\"${stashdir}\" contains a mix of symlinks and directories"
         fi
      fi

      DEPENDENCY_DIR="${DEPENDENCY_DIR:-dependency}"
      if [ ! -d "${DEPENDENCY_DIR}" ]
      then
         log_info "There is no ${C_RESET_BOLD}${DEPENDENCY_DIR}${C_INFO} directory"
      else
         state="`mulle-craft -s quickstatus -p`"
         case "${state}" in
            complete)
               log_info "The dependency directory is ${state}"
            ;;

            *)
               log_verbose "${C_RESET_BOLD}   mulle-sde craft"
            ;;
         esac
      fi
   fi

   local graveyard

   graveyard="`mulle-env var-dir sourcetree`/graveyard"

   if [ -d  "${graveyard}" ]
   then
      DF="`command -v df`"
      if [ -z "${DF}" ]
      then
         size="`df -kh "${graveyard}" | awk '{ print $1 }'`"
         log_info "There is sourcetree grayeyard of ${size} size here"
      else
         log_info "There is sourcetree grayeyard here"
      fi
      log_verbose "${C_RESET_BOLD}   mulle-sourcetree clean --all-graveyards"
   fi

   log_verbose "Treestatus"

   mulle-sde ${MULLE_TECHNICAL_FLAGS} treestatus

   log_verbose "Craftstatus"

   mulle-sde ${MULLE_TECHNICAL_FLAGS} craftstatus

   return $rval
}

