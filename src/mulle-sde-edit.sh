# shellcheck shell=bash
#
#   Copyright (c) 2024 Nat! - Mulle kybernetiK
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
# Rebuild if files of certain files are modified
#
MULLE_SDE_EDIT_SH='included'


sde::edit::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} edit [options] [arguments] ...

   Edit the current project with the editor of your choice.

Options:
   --select   : reselect editors
   --         : pass remaining arguments (if you need to pass --reselect)

Environment:
   MULLE_SDE_EDITORS : list of editor separated by ':' (${MULLE_SDE_EDITORS})

EOF
   exit 1
}


sde::edit::r_installed_editors()
{
   log_entry "sde::product::r_installed_editors" "$@"

   local editors="$1"

   local existing_editors
   local editor

   .foreachpath editor in ${editors}
   .do
      if mudo -f which "${editor}" > /dev/null 2>&1
      then
         r_add_line "${existing_editors}" "${editor}"
         existing_editors="${RVAL}"
      fi
   .done
   RVAL="${existing_editors}"
   log_debug "existing_editors: ${existing_editors}"
}


sde::edit::r_user_choses_editor()
{
   log_entry "sde::product::r_user_choses_editor" "$@"

   local editors="$1"

   local row

   rexekutor mudo -f mulle-menu --title "Choose editor:" \
                                --final-title "" \
                                --options "${editors}"
   row=$?

   log_debug "row=${row}"

   r_line_at_index "${editors}" $row
   [ ! -z "${RVAL}" ]
}


#
# Keep in mind, that ideally this command should also "just" work even if
# there is no environment, just to quickly hit up an editor from muscle memory
#
sde::edit::main()
{
   log_entry "sde::edit::main" "$@"

   local OPTION_SELECT
   local OPTION_JSON_ENV
   local OPTION_SQUELCH='DEFAULT'
   local OPTION_EDITOR

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::edit::usage
         ;;

         --squelch)
            OPTION_SQUELCH='YES'
         ;;

         --no-squelch)
            OPTION_SQUELCH='NO'
         ;;

         --select|--reselect)
            OPTION_SELECT='YES'
         ;;

         --json-env)
            OPTION_JSON_ENV='YES'
         ;;

         --[A-Za-z]*)
            OPTION_EDITOR="${1:2}"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::edit::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   # so we are NOT in mulle-sde currently, the main reason for this is
   # that mulle-sde may run in a sandbox, and this for example makes it
   # impossible for "Sublime Text" to fork off a server.
   #
   # We do want the environment though... We don't need the tool resrictions
   #
   local directory

   local ADDICTION_DIR
   local DEPENDENCY_DIR
   local KITCHEN_DIR
   local STASH_DIR

   if sde::r_determine_project_dir
   then
      MULLE_VIRTUAL_ROOT="${RVAL}"

      log_debug "Sourcing environment from ${MULLE_VIRTUAL_ROOT#${MULLE_USER_PWD}/}..."

      . "${MULLE_VIRTUAL_ROOT}/.mulle/share/env/include-environment.sh"

      #
      # gather KITCHEN_DIR
      # gather STASH_DIR
      # gather DEPENDENCY_DIR
      # gather ADDICTION_DIR
      # and pass as environment
      #
      ADDICTION_DIR="`mulle-craft addiction-dir`"
      DEPENDENCY_DIR="`mulle-craft dependency-dir`"
      KITCHEN_DIR="`mulle-craft kitchen-dir`"
      STASH_DIR="`mulle-sourcetree stash-dir`"
   fi

   if [ "${OPTION_JSON_ENV}" = 'YES' ]
   then
      cat <<EOF
{
   "ADDICTION_DIR":  "${ADDICTION_DIR:-${PWD}/addiction}",
   "DEPENDENCY_DIR": "${DEPENDENCY_DIR:-${PWD}/dependency}",
   "KITCHEN_DIR":    "${KITCHEN_DIR:-${PWD}/kitchen}",
   "STASH_DIR":      "${STASH_DIR:-${PWD}/${MULLE_SOURCETREE_STASH_DIRNAME:-stash}}"
}
EOF
      return 0
   fi

   local editor

   if [ "${OPTION_SELECT}" != 'YES' ]
   then
      editor="${OPTION_EDITOR:-${MULLE_SDE_EDITOR_CHOICE}}"
   fi

   if [ ! -z "${editor}" ]
   then
      editor="`command -v "${editor}"`"
   fi

   if [ -z "${editor}" ]
   then
      local editors
      local choices

      case "${MULLE_UNAME}" in
         windows)
            choices="${MULLE_SDE_EDITORS:-subl.exe:clion.exe:vscode.exe:cursor.exe}"
         ;;

         macos)
            choices="${MULLE_SDE_EDITORS:-subl:clion:lion:vscode:cursor.exe}"
         ;;

         *)
            choices="${MULLE_SDE_EDITORS:-subl:clion.sh:clion:codium:code:cursor:micro:emacs:vi}"
         ;;
      esac

      if ! sde::edit::r_installed_editors "${choices}"
      then
         fail "No suitable editor found, please install one of: ${choices}"
      fi
      editors="${RVAL}"

      if ! sde::edit::r_user_choses_editor "${editors}"
      then
         return 1
      fi
      editor="${RVAL}"

      # don't save preference if we are not in sde
      if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
      then
         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} env --this-user set MULLE_SDE_EDITOR_CHOICE "${editor}"
      fi
   fi

   log_setting "editor: ${editor}"

   local vendorprefix

   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      PROJECT_TYPE="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} env get PROJECT_TYPE`"
      if [ "${PROJECT_TYPE}" = "none" ]
      then
         vendorprefix="mulle-sde/"
      fi
   fi

   case "${editor}" in
      subl*|*/subl*)
         local any

         any="`dir_list_files "${MULLE_VIRTUAL_ROOT:-${MULLE_USER_PWD}}" "*.sublime-project" 2> /dev/null | head -1`"
         if [ ! -z "${MULLE_VIRTUAL_ROOT}" -a -z "${any}" ]
         then
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} extension add --if-missing "${vendorprefix}sublime-text"
         fi

         if [ $# -eq 0 ]
         then
            # memo: if you just open a folder, sublime-text will not necessarily
            #       read the project file and then most likely you won't have
            #       access to build systems and debugging, which sucketh
            if [ ! -z "${any}" ]
            then
               set -- --project-file "${any}"
            else
               set -- "${MULLE_VIRTUAL_ROOT:-${MULLE_USER_PWD}}"
            fi
         fi
      ;;
      cursor|codium*|*/codium*|code*|*/code*)
         if [ ! -z "${MULLE_VIRTUAL_ROOT}" -a ! -d .vscode ]
         then
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} extension add --if-missing "${vendorprefix}vscode-clang"
         fi
         if [ $# -eq 0 ]
         then
            set -- ${MULLE_VIRTUAL_ROOT}
         fi
      ;;
      clion*|*/clion*)
         if [ ! -z "${MULLE_VIRTUAL_ROOT}" -a ! -d .idea ]
         then
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} extension add --if-missing "${vendorprefix}idea"
         fi
         if [ $# -eq 0 ]
         then
            set -- ${MULLE_VIRTUAL_ROOT}
         fi
         if [ "${OPTION_SQUELCH}" = 'DEFAULT' ]
         then
            OPTION_SQUELCH='YES'
         fi
         OPTION_BG='YES'
      ;;

      *)
         if [ $# -eq 0 ]
         then
            set -- `dir_list_files "${MULLE_VIRTUAL_ROOT}/${PROJECT_SOURCE_DIR}" "*" "f"`
         fi
      ;;
   esac

   #
   # gather KITCHEN_DIR
   # gather STASH_DIR
   # gather DEPENDENCY_DIR
   # gather ADDICTION_DIR
   # and pass as environment
   #
   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      export ADDICTION_DIR="${ADDICTION_DIR}"
      export DEPENDENCY_DIR="${DEPENDENCY_DIR}"
      export KITCHEN_DIR="${KITCHEN_DIR}"
      export STASH_DIR="${STASH_DIR}"

      exekutor_trace exekutor_print export ADDICTION_DIR="${ADDICTION_DIR}"
      exekutor_trace exekutor_print export DEPENDENCY_DIR="${DEPENDENCY_DIR}"
      exekutor_trace exekutor_print export KITCHEN_DIR="${KITCHEN_DIR}"
      exekutor_trace exekutor_print export STASH_DIR="${STASH_DIR}"
   fi

   if [ "${OPTION_SQUELCH}" = 'YES' ]
   then
      if [ "${OPTION_BG}" = 'YES' ]
      then
         exekutor exec "${editor}${MULLE_EXE_EXTENSION}" "$@" > /dev/null 2>&1 &
      else
         exekutor exec "${editor}${MULLE_EXE_EXTENSION}" "$@" > /dev/null 2>&1
      fi
   else
      if [ "${OPTION_BG}" = 'YES' ]
      then
         exekutor exec "${editor}${MULLE_EXE_EXTENSION}" "$@" &
      else
         exekutor exec "${editor}${MULLE_EXE_EXTENSION}" "$@"
      fi
   fi
}
