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
MULLE_SDE_BUILD_SH="included"


#
# Dont't make it too complicated, mulle-sde craft builds 'all' or the desired
# user selected style
# Wan't something special ? Use mulle-craft directly
#
sde_craft_main()
{
   log_entry "sde_craft_main" "$@"

   local auxflags
   local touchfile
   local cmd

   cmd="${MULLE_SDE_CRAFT_STYLE:-all}"

   auxflags="--motd"

   if [ -z "${MULLE_SDE_NO_UPDATE}" ]
   then
      if [ -z "${MULLE_SDE_UPDATE_SH}" ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-update.sh"
      fi

      log_verbose "Run update if needed"

      sde_update_if_needed_main
   fi

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   set_projectname_environment "read"

   log_verbose "Craft \"${cmd}\" project \"${PROJECT_NAME}\""

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${cmd}" \
      exekutor "${MULLE_CRAFT}" ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_CRAFT_FLAGS} ${auxflags} "${cmd}" "$@"
}
