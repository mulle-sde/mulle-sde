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


sde_list_files()
{
   local text

   text="`
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MATCH:-mulle-match}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_MATCH_FLAGS} \
                  list \
                     --format "%t/%c: %f\\n" "$@"

   `"

   local types
   local subtext
   local categories
   local type
   local category
   local seperator

   seperator=''
   types="`rexekutor sed 's|^\([^/]*\).*|\1|' <<< "${text}" | sort -u`"
   for type in ${types}
   do
      printf "%s" "${seperator}"
      seperator=''

      # https://stackoverflow.com/questions/12487424/uppercase-first-character-in-a-variable-with-bash
      log_info "${C_MAGENTA}${C_BOLD}$(tr '[:lower:]' '[:upper:]' <<< ${type:0:1})${type:1}"
      subtext="`rexekutor sed -n "s|^${type}/||p" <<< "${text}" `"

      categories="`rexekutor sed 's|^\([^:]*\).*|\1|' <<< "${subtext}" | sort -u`"
      for category in ${categories}
      do
         printf "%s" "${seperator}"
         seperator=$'\n'
         log_info "   $(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}"
         rexekutor sed -n "s|^${category}: |      |p" <<< "${subtext}"
      done
   done
}


sde_list_dependencies()
{
   local text

   local seperator

   text="`
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_SOURCETREE_FLAGS} \
                  list --output-no-header \
                       --marks dependency,fs
   `"
   if [ ! -z "${text}" ]
   then
      printf "%s" "${seperator}"
      seperator=$'\n'
      log_info "${C_MAGENTA}${C_BOLD}Dependencies"
      sed 's|^|   |' <<< "${text}"
   fi

   text="`
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS} \
                     list --output-no-header \
                          --marks no-dependency,no-fs
   `"
   if [ ! -z "${text}" ]
   then
      printf "%s" "${seperator}"
      seperator=$'\n'
      log_info "${C_MAGENTA}${C_BOLD}Libraries"
      sed 's|^|   |' <<< "${text}"
   fi
}


sde_list_main()
{
   if [ "${PROJECT_TYPE}" != 'none' ]
   then
      sde_list_files
   fi
   sde_list_dependencies
}