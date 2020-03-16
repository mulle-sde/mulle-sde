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
MULLE_SDE_LIST_SH="included"


sde_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} list [options]

   List definitions,environment,files,dependencies to give an overview of
   your project.

Options:
   --files            : list only files
   --no-dependencies  : do not list dependencies
   --no-files         : do not list files
   --no-definitions   : do not list definitions
   --no-environment   : do not list environmnt

EOF
  exit 1
}



sde_list_files()
{
   log_entry "sde_list_files" "$@"

   local text

   text="`
   # MULLE_TECHNICAL_FLAGS on match is just too much
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MATCH:-mulle-match}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                  list \
                     --format "%t/%c: %f\\n" "$@"

   `"

   log_debug "text: ${text}"

   local types
   local subtext
   local categories
   local type
   local category
   local separator

   separator=''
   types="`rexekutor sed 's|^\([^/]*\).*|\1|' <<< "${text}" | sort -u`"

   log_debug "types: ${types}"
   for type in ${types}
   do
      printf "%s" "${separator}"
      separator=''

      # https://stackoverflow.com/questions/12487424/uppercase-first-character-in-a-variable-with-bash
      log_info "${C_MAGENTA}${C_BOLD}$(tr '[:lower:]' '[:upper:]' <<< ${type:0:1})${type:1}"
      subtext="`rexekutor sed -n "s|^${type}/||p" <<< "${text}" `"
      log_debug "subtext: ${subtext}"

      categories="`rexekutor sed 's|^\([^:]*\).*|\1|' <<< "${subtext}" | sort -u`"
      log_debug "categories: ${categories}"

      for category in ${categories}
      do
         printf "%s" "${separator}"
         separator=$'\n'
         log_info "   $(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}"
         rexekutor sed -n "s|^${category}: |      |p" <<< "${subtext}"
      done
   done
}


sde_list_dependencies()
{
   log_entry "sde_list_dependencies" "$@"

   local text
   local separator

   text="`
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                  list --output-no-header \
                       --marks dependency,fs
   `"
   if [ ! -z "${text}" ]
   then
      printf "%s" "${separator}"
      separator=$'\n'
      log_info "${C_MAGENTA}${C_BOLD}Dependencies"
      sed 's|^|   |' <<< "${text}"
   fi

   text="`
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                     list --output-no-header \
                          --marks no-dependency,no-fs
   `"
   if [ ! -z "${text}" ]
   then
      printf "%s" "${separator}"
      separator=$'\n'
      log_info "${C_MAGENTA}${C_BOLD}Libraries"
      sed 's|^|   |' <<< "${text}"
   fi
}


sde_list_definitions()
{
   log_entry "sde_list_definitions" "$@"

   if [ -z "${MULLE_SDE_DEFINITION_SH}" ]
   then
      # shellcheck source=src/mulle-sde-definition.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-definition.sh"
   fi

   local text

   text="`sde_definition_main --terse --os "${MULLE_UNAME}" list`"
   if [ ! -z "${text}" ]
   then
      log_info "${C_MAGENTA}${C_BOLD}Definitions"
      sed 's|^||' <<< "${text}"
   else
      text="`sde_definition_main --terse --global list`"
      if [ ! -z "${text}" ]
      then
         log_info "${C_MAGENTA}${C_BOLD}Definitions"
         sed 's|^||' <<< "${text}"
      fi
   fi
}


sde_list_environment()
{
   log_entry "sde_list_environment" "$@"

   local text

   text="`mulle-env -s environment list --output-eval `"
   if [ ! -z "${text}" ]
   then
      log_info "${C_MAGENTA}${C_BOLD}Environment"
      sed 's|^|   |' <<< "${text}"
   fi
}


sde_list_main()
{
   log_entry "sde_list_main" "$@"

   local OPTION_LIST_DEPENDENCIES='YES'
   local OPTION_LIST_FILES='YES'
   local OPTION_LIST_DEFINITIONS='YES'
   local OPTION_LIST_ENVIRONMENT='YES'
   local spacer

   spacer=":"  # nop

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_list_usage
         ;;

         --no-dependencies)
            OPTION_LIST_DEPENDENCIES='NO'
         ;;

         --files)
            OPTION_LIST_FILES='YES'
            OPTION_LIST_DEFINITIONS='NO'
            OPTION_LIST_ENVIRONMENT='NO'
            OPTION_LIST_DEPENDENCIES='NO'
         ;;

         --no-files)
            OPTION_LIST_FILES='NO'
         ;;

         --no-definitions)
            OPTION_LIST_DEFINITIONS='NO'
         ;;

         --no-environment)
            OPTION_LIST_ENVIRONMENT='NO'
         ;;

         -*)
            sde_list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && sde_list_usage "Superflous arguments $*"

   if [ "${OPTION_LIST_FILES}" = 'YES' -a "${PROJECT_TYPE}" != 'none' ]
   then
      sde_list_files
      spacer="echo"
   fi

   if [ "${OPTION_LIST_DEPENDENCIES}" = 'YES' ]
   then
      eval "${spacer}"
      sde_list_dependencies
      spacer="echo"
   fi

   if [ "${OPTION_LIST_ENVIRONMENT}" = 'YES' ]
   then
      eval "${spacer}"
      sde_list_environment
      spacer="echo"
   fi

   if [ "${OPTION_LIST_DEFINITIONS}" = 'YES' ]
   then
      eval "${spacer}"
      sde_list_definitions
      spacer="echo"
   fi
}
