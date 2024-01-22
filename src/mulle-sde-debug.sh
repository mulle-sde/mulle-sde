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
MULLE_SDE_DEBUG_SH='included'


sde::debug::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} debug [arguments] ...

   ** THIS COMMAND IS WORK IN PROGRESS **

   Debug the main executable of the given project, with the arguments given.
   The debugg and the executable will not run within the mulle-sde environment!

Environment:
   MULLE_SDE_DEBUGGERS : list of debugger separated by ':' (${MULLE_SDE_DEBUGGERS})

EOF
   exit 1
}


sde::debug::main()
{
   local executable

   # shellcheck source=src/mulle-sde-product.sh
   include "sde::product"

   if ! executable="`sde::product::main`"
   then
      sde::debug::usage "Product not yet available"
   fi

   if [ ! -x "${executable}" ]
   then
      sde::debug::usage "Product not yet available"
   fi

   local debuggers
   local debugger
   local debugger_executable

   debuggers="${MULLE_SDE_DEBUGGERS:-mulle-gdb:gdb:lldb}"
   .foreachpath debugger in ${debuggers}
   .do
      if ! debugger_executable="`mudo command -v "${MULLE_SDE_DEBUGGER:-mulle-gdb}"`"
      then
         .break
      fi
   .done

   if [ -z "${debugger_executable}" ]
   then
      fail "No suitable debugger found, please install one of: ${debuggers}"
   fi
   exekutor mudo "${debugger_executable}" "${executable}" "$@"
}

