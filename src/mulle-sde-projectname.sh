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


set_projectname_environment()
{
   log_entry "set_projectname_environment" "$@"

   if [ ! -z "${PROJECT_UPCASE_IDENTIFIER}" ]
   then
      return
   fi

   [ -z "${PROJECT_NAME}" ] && internal_fail "PROJECT_NAME can't be empty"

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"      || return 1
   fi

   PROJECT_C_NAME="`printf "%s" "${PROJECT_NAME}" | tr -c 'a-zA-Z0-9$' '_'`"

   local RVAL

   r_tweaked_de_camel_case "${PROJECT_NAME}"
   PROJECT_IDENTIFIER="${RVAL}"
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