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
   ${MULLE_USAGE_NAME} edit [arguments] ...

   Edit the current project with the editor of your choice.

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
      if mudo which "${editor}" > /dev/null
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

   rexekutor mudo mulle-menu --title "Choose editor:" \
                             --final-title "" \
                             --options "${editors}"
   row=$?
   log_debug "row=${row}"

   r_line_at_index "${editors}" $row
   [ ! -z "${RVAL}" ]
}



sde::edit::main()
{
   log_entry "sde::edit::main" "$@"

   local OPTION_SELECT

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::edit::usage
         ;;

         --select)
            OPTION_SELECT='YES'
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

   local editor

   if [ "${OPTION_SELECT}" != 'YES' ]
   then
      editor="${MULLE_SDE_EDITOR_CHOICE}"
   fi

   if [ ! -z "${editor}" ]
   then
      editor="`command -v "${editor}"`"
   fi

   if [ -z "${editor}" ]
   then
      local editors
      local choices

      choices="${MULLE_SDE_EDITORS:-subl:clion.sh:codium:code:micro:emacs:vi}"
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

      rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} env --this-user set MULLE_SDE_EDITOR_CHOICE "${editor}"
   fi

   log_setting "editor: ${editor}"

   case "${editor}" in
      subl*|*/subl*)
         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} extension add --if-missing sublime-text
         if [ $# -eq 0 ]
         then
            set -- "${MULLE_VIRTUAL_ROOT}"
         fi
      ;;
      codium*|*/codium*|code*|*/code*)
         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} extension add --if-missing vscode-clang
         if [ $# -eq 0 ]
         then
            set -- "${MULLE_VIRTUAL_ROOT}"
         fi
      ;;
      clion*|*/clion*)
         rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} extension add --if-missing idea
         if [ $# -eq 0 ]
         then
            set -- "${MULLE_VIRTUAL_ROOT}"
         fi
      ;;

      *)
         if [ $# -eq 0 ]
         then
            set -- `dir_list_files "${MULLE_VIRTUAL_ROOT}/${PROJECT_SOURCE_DIR}" "*" "f"`
         fi
      ;;
   esac

   # want to edit with current environment, so no mudo
   exekutor "${editor}${MULLE_EXE_EXTENSION}" "$@"
}
