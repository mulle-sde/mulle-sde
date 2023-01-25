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
MULLE_SDE_STATUS_SH="included"


sde::status::usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} status [options]

   Get information about the current mulle-sde project status.

Options:
   --all         : add all information options
   --clear       : clear default information settings
   --config      : add sourcetree configuration information (default)
   --craftstatus : add craft information (default)
   --database    : add sourcetree database information (default)
   --graveyard   : add sourcetree graveyard information (default)
   --project     : add project information (default)
   --quickstatus : add dependency status information (default)
   --sourcetree  : add sourcetree information (default)
   --stash       : add sourcetree stash information( default)
   --tool        : add tool information (default)
   --treestatus  : add source files information
EOF
   exit 1
}


sde::status::project()
{
   log_entry "sde::status::project" "$@"

   local indent="$1"

   local rval
   local projectdir
   local parentdir
   local directory
   local mode=indir

   directory="`pwd -P`"

   if ! sde::r_determine_project_dir "${directory}"
   then
      log_warning "${indent}There is no mulle-sde project in \"${directory#"${MULLE_USER_PWD}/"}\"."
      if [ -d .mulle-sde ]
      then
        log_warning "${indent}There is and old possibly upgradable mulle-sde project in \"${directory#"${MULLE_USER_PWD}/"}\"."
      fi
      if [ -d .mulle-env ]
      then
        log_warning "${indent}There is and old possibly upgradable mulle-env environment in \"${directory#"${MULLE_USER_PWD}/"}\"."
      fi
      if [ -d .mulle-bootstrap ]
      then
        log_warning "${indent}There is and old non-upgradable mulle-bootstrap project in \"${directory#"${MULLE_USER_PWD}/"}\"."
      fi
      exit 1
   fi

   projectdir="${RVAL}"
   if [ "${directory}" != "${projectdir}" ]
   then
      log_verbose "${indent}The project directory is ${projectdir} (not ${directory})"
   else
      log_verbose "${indent}The project directory is ${projectdir}"
   fi

   r_dirname "${projectdir}"
   if sde::r_determine_project_dir "${RVAL}"
   then
      parentdir="${RVAL}"
      log_verbose "${indent}The parent directory is ${parentdir}"
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
            log_verbose "${indent}mulle-sde commands are executed in ${projectdir#"${MULLE_USER_PWD}/"}."
         else
            log_info "${indent}mulle-sde commands are executed in ${projectdir#"${MULLE_USER_PWD}/"}, but there is a parent project in ${parentdir#"${MULLE_USER_PWD}/"}"
         fi
      ;;

      inproject)
         log_info "${indent}mulle-sde commands are executed in the project directory ${C_RESET_BOLD}${projectdir#"${MULLE_USER_PWD}/"}"
      ;;

      inparent)
         log_info "${indent}mulle-sde commands are deferred to the parent project directory ${C_RESET_BOLD}${parentdir#"${MULLE_USER_PWD}/"}"
      ;;
   esac


   if [ "${directory}" != "${projectdir}" ]
   then
      log_verbose "${indent}The current directory is ${directory#"${MULLE_USER_PWD}/"}"
   fi

   if [ ! -z "${projectdir}" ]
   then
      exekutor cd "${projectdir}" || return 1
   fi
}


sde::status::config()
{
   log_entry "sde::status::config" "$@"

   local indent="$1"

   local _craftorderfile
   local _cachedir

   [ -z "${MULLE_SDE_CRAFTORDER_SH}" ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftorder.sh"

   sde::craftorder::__get_info

   if [ ! -f "${_craftorderfile}" ]
   then
      log_fluff "No craftorderfile present yet"
      RVAL=""
      return 0
   fi

   local names
   local first_name

   names="${MULLE_SOURCETREE_CONFIG_NAME:-config}"
   first_name="${names%%:*}"

   local line
   local repository
   local filename
   local previous
   local changes

   log_verbose "Sourcetree configurations:"

   .foreachline repository in `rexekutor sed -e 's/^\([^;]*\).*/\1/' "${_craftorderfile}" `
   .do
      filename="${repository}/${MULLE_SDE_ETC_DIR#"${MULLE_VIRTUAL_ROOT}/"}/reflect"

      # if the file does not exist, this means
      # a) it's not a multi sourcetree project
      # if the file exists, we implicitly know its a mulle-sde project
      if [ ! -f "${filename}" ]
      then
         .continue
      fi

      # if we are in sync, we don't need to reflect
      previous="`grep -E -v '^#' "${filename}" 2> /dev/null `"
      if [ "${previous}" = "${first_name}" ]
      then
         .continue
      fi

      printf "${indent}%s\n" "${repository};${previous}"
   .done
   IFS="${DEFAULT_IFS}"
}


sde::status::sourcetree()
{
   log_entry "sde::status::sourcetree" "$@"

   if ! [ ${MULLE_SOURCETREE_ETC_DIR+x} ]
   then
      eval `"${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sourcetree`
   fi

   local sourcetreefile

   sourcetreefile="${MULLE_SOURCETREE_ETC_DIR}/config"
   if [ ! -f "${sourcetreefile}" ]
   then
      sourcetreefile="${MULLE_SOURCETREE_SHARE_DIR}/config"
   fi

   if [ ! -f "${sourcetreefile}" ]
   then
      log_verbose "Sourcetree status:"
      log_info "${indent}There is no sourcetree (${PWD#"${MULLE_USER_PWD}/"})"
      return
   fi

   local state
   local expect_dependencydir

   case ",${statustypes}," in
      *,database,*)
         log_verbose "Database status:"
         if rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                           -s dbstatus
         then
            log_info "${indent}Nothing needs to be fetched according to database"
         else
            log_info "${indent}Dependencies will be fetched/refreshed according to database"
            log_verbose "${indent}${C_RESET_BOLD}   mulle-sde fetch"
         fi
      ;;
   esac

   case ",${statustypes}," in
      *,quickstatus,*)
         log_verbose "Quick status:"

         DEPENDENCY_DIR="${DEPENDENCY_DIR:-dependency}"
         if [ ! -d "${DEPENDENCY_DIR}" ]
         then
            log_info "${indent}There is no ${C_RESET_BOLD}${DEPENDENCY_DIR}${C_INFO} directory"
         else
            state="`mulle-craft -s quickstatus -p`"
            case "${state}" in
               complete)
                  log_info "${indent}The dependency directory is ${state}"
               ;;

               *)
                  log_verbose "${indent}${C_RESET_BOLD}   mulle-sde craft"
               ;;
            esac
         fi
      ;;
   esac

   case ",${statustypes}," in
      *,treestatus,*)
         log_verbose "Tree status:"

         mulle-sde ${MULLE_TECHNICAL_FLAGS} --no-test-check treestatus | sed -e "s/^/${indent}/"
      ;;
   esac
}


sde::status::stash()
{
   log_entry "sde::status::stash" "$@"

   local indent="$1"

   local file
   local hassymlinks
   local hasdirs
   local state
   local color
   local ok_or_fail

   local stashdir

   stashdir="${MULLE_SOURCETREE_STASH_DIRNAME:-stash}"

   shell_enable_nullglob
   for file in "${stashdir}"/*
   do
      state="missing"
      if [ -L "${file}" ]
      then
         r_resolve_symlinks "${file}"
         state="symlink"
         if [ -z "${RVAL}" -o ! -e "${RVAL}" ]
         then
            state="broken"
            log_error "${indent}${C_ERROR}Symlink ${C_RESET_BOLD}${file}${C_ERROR} is broken"
         fi
      else
         # sometimes we'd prefer this to be a symlink, but mistaken fetch
         # placed a real folder here. Hard to check though
         if [ -d "${file}" ]
         then
            state="directory"
         else
            if [ -f "${file}" ]
            then
               state="file"
            fi
         fi
      fi

      ok_or_fail="OK"

      case "${state}" in
         broken)
            color="${C_RED}"
            ok_or_fail="FAIL"
         ;;
         missing)
            color="${C_RED}"
            ok_or_fail="FAIL"
         ;;
         symlink)
            color="${C_GREEN}"
         ;;
         directory)
            color="${C_BLUE}"
         ;;
         file)
            color="${C_MAGENTA}"
         ;;
      esac
      printf "${indent}%b\n" "${color}${file}${C_RESET};${ok_or_fail}"
   done
   shell_disable_nullglob
}


sde::status::graveyard()
{
   log_entry "sde::status::graveyard" "$@"

   local indent="$1"

   local graveyard
   local size

   eval `"${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sourcetree` || return 1
   graveyard="${MULLE_SOURCETREE_VAR_DIR}/graveyard"
   if [ -d "${graveyard}" ]
   then
      DU="`command -v du`"
      if [ ! -z "${DU}" ]
      then
         size="`${DU} -kh -d0 "${graveyard}" | awk '{ print $1 }'`"
         log_warning "${indent}There is a sourcetree grayeyard of ${size} size here"
      else
         log_warning "${indent}There is a sourcetree grayeyard here"
      fi
      _log_info "${indent}You can remove it with
${C_RESET_BOLD}${indent}   mulle-sde clean graveyard"
   fi
}


sde::status::main()
{
   log_entry "sde::status::main" "$@"

   local statustypes
   local indent

   indent=""
   statustypes="config,craftstatus,database,graveyard,project,quickstatus,stash,tool"
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      indent="   "
   fi

   if [ "${MULLE_FLAG_LOG_FLUFF}" = 'YES' ]
   then
      statustypes="${statustypes},treestatus"
      indent="   "
   fi

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::status::usage
         ;;

         --clear|--reset)
            statustypes=""
         ;;

         --craftstatus|--config|--database|--graveyard|--project|--quickstatus|--stash|--treestatus|--tool)
            r_comma_concat "${statustypes}" "${1:2}"
            statustypes="${RVAL}"
         ;;

         --sourcetree)
            r_comma_concat "${statustypes}" "database,quickstatus,treestatus"
            statustypes="${RVAL}"
         ;;

         --all)
            statustypes="config,craftstatus,database,graveyard,project,quickstatus,stash,treestatus,tool"
         ;;

         -*)
            sde::status::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] || sde::status::usage "Superflous arguments \"$*\""

   include "string"
   include "path"
   include "file"

#   if [ -z "${MULLE_STRING_SH}" ]
#   then
#      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-string.sh" || return 1
#   fi
#   if [ -z "${MULLE_PATH_SH}" ]
#   then
#      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
#   fi
#   if [ -z "${MULLE_FILE_SH}" ]
#   then
#      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
#   fi

   case ",${statustypes}," in
      *,tool,*)
         log_verbose "Tool status:"

         rexekutor mulle-env ${MULLE_TECHNICAL_FLAGS} tool doctor || return 1
      ;;
   esac

   case ",${statustypes}," in
      *,project,*)
         log_verbose "Project status:"
         sde::status::project "${indent}" || return 1
      ;;
   esac

   case ",${statustypes}," in
      *,config,*)
         sde::status::config "${indent}"
      ;;
   esac

   case ",${statustypes}," in
      *,sourcetree,*|*,database,*|*,quickstatus,*|*,treestatus,*)
         sde::status::sourcetree "${indent}"
      ;;
   esac

   case ",${statustypes}," in
      *,stash,*)
         local stashdir
         local abs_stashdir

         stashdir="${MULLE_SOURCETREE_STASH_DIRNAME:-stash}"
         r_absolutepath "${stashdir}"
         abs_stashdir="${RVAL}"

         if [ -d "${abs_stashdir}" ]
         then
            log_verbose "Stash status: (${abs_stashdir#"${MULLE_USER_PWD}/"})"

            sde::status::stash ""  \
            | rexecute_column_table_or_cat ';' \
            | sed -e "s/^/   ${indent}/"
         fi
      ;;
   esac

   case ",${statustypes}," in
      *,graveyard,*)
         log_verbose "Graveyard status:"
         sde::status::graveyard "${indent}"
      ;;
   esac

   case ",${statustypes}," in
      *,patternfile,*)
         log_verbose "Patternfile status:"

         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} patternfile status
      ;;
   esac

   case ",${statustypes}," in
      *,craftstatus,*)
         log_verbose "Craft status:"

         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} --no-test-check craftstatus --output-terse
      ;;
   esac

   return $rval
}

