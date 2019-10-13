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
MULLE_SDE_PLUGIN_SH="included"


#
# make this nicer, in that we provide the variable name to the
# plugin and the plugin sets it witch its functionname
#
load_plugin_if_needed()
{
   local varname="$1"
   local filename="$2"
   local definename="$3"
   local functionname="$4"
   local fallback="$5"

   [ -z "${varname}" ] && internal_fail "varname is empty"
   [ -z "${filename}" ] && internal_fail "filename is empty"
   [ -z "${definename}" ] && internal_fail "definename is empty"
   [ -z "${functionname}" ] && internal_fail "functionname is empty"

   local plugin
   local libexedir
   plugin="$(eval echo "\${${varname}}" )"
   if [ -z "${plugin}" ]
   then
      r_dirname="$0"
      libexedir="${RVAL}/../libexec"
      plugin="${libexedir}/${filename}"
      if [ ! -f "${plugin}" ]
      then
         # developer support
         plugin="${exedir}/../../c/libexec/${filename}"
         if [ ! -f "${plugin}" ]
         then
            return 1
         fi
      fi
   fi

   if [ -z "$(eval echo "\${${definename}}" )" ]
   then
      . "${plugin}" || fail "could not find \"libexec/${filename}\""
      log_debug "Did load plugin \"libexec/${filename}\""
   else
      functionname="${fallback}"
   fi
   eval "${varname}='${functionname}'"

   local value

   value="$(eval echo "\${${varname}}" )"

   log_debug "${varname}=${value}"
}
