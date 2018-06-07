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
MULLE_SDE_PROJECTNAME_SH="included"


#
# This is a camel case to underscore converter that keeps single capitalized
# letters together with the previous word.
#
# Ex. MulleObjCBaseFoundation -> Mulle_ObjC_Base_Foundation
#     FBTroll -> FBTroll      # lucky, but pretty good IMO
#     FBTrollFB -> FBTrollF_B # unlucky, but i don't care
#
_tweaked_de_camel_case()
{
   local s="$1"

   local output

   local c
   local d
   local e

   while [ ! -z "${s}" ]
   do
      c="${s:0:1}"
      s="${s:1}"
      d="${s:0:1}"
      e="${s:1:1}"

      case "${d}" in
         [A-Z])
            case "${c}" in
               [a-z])
                  case "${e}" in
                     [^A-Z])
                        output="${output}${c}_"
                        continue
                     ;;

                     "")
                        output="${output}${c}${d}"
                        s="${s:1}"
                        continue
                     ;;

                     *)
                        output="${output}${c}${d}_"
                        s="${s:1}"
                        continue
                     ;;
                  esac
               ;;
            esac
         ;;
      esac

      output="${output}${c}"

   done

   echo "${output}"
}


tweaked_de_camel_case()
{
   # need this for [A-B] to be case sensitive, dont'ask
   # https://stackoverflow.com/questions/10695029/why-isnt-the-case-statement-case-sensitive-when-nocasematch-is-off
   LC_ALL=C _tweaked_de_camel_case "$@"
}


set_projectname_environment()
{
   log_entry "set_projectname_environment" "$@"

   local mode="$1"

   [ -z "${PROJECT_NAME}" ] && internal_fail "PROJECT_NAME cant be empty"

   PROJECT_IDENTIFIER="`tweaked_de_camel_case "${PROJECT_NAME}"`"
   PROJECT_IDENTIFIER="`printf "%s" "${PROJECT_IDENTIFIER}" | tr -c 'a-zA-Z0-9' '_'`"
   PROJECT_DOWNCASE_IDENTIFIER="`tr 'A-Z' 'a-z' <<< "${PROJECT_IDENTIFIER}"`"
   PROJECT_UPCASE_IDENTIFIER="`tr 'a-z' 'A-Z' <<< "${PROJECT_IDENTIFIER}"`"

   export PROJECT_NAME
   export PROJECT_IDENTIFIER
   export PROJECT_DOWNCASE_IDENTIFIER
   export PROJECT_UPCASE_IDENTIFIER

   # gratuitous optimization
   export MULLE_BASHFUNCTIONS_LIBEXEC_DIR
   export MULLE_MONITOR_DIR
   export MULLE_SDE_LIBEXEC_DIR
   export MULLE_SDE_DIR
}