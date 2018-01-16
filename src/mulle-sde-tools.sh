#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_SDE_TOOLS_SH="included"


sde_tools_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} tools [options] [command]

Options:
   -h            : show this usage

Commands:
   add <tool>    : add a tool
   remove <tool> : remove a tool
   list          : list libraries (default)
EOF
   exit 1
}


_mulle_tools_add()
{
   local tool="$1"

   [ -z "${tool}" ] && internal_fail "tool must not be empty"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT not defined"

   if [ ! -d "${MULLE_ENV_DIR}" ]
   then
      fail "Need to \"mulle-env init\" first before adding tools"
   fi

   local executable

   #
   # use mudo to break out of
   # virtual environment
   #
   executable="`mudo which "${tool}"`"
   if [ -z "${executable}" ]
   then
      fail "Failed to find executable \"${tool}\""
   fi

   local toolsfile

   toolsfile="${MULLE_ENV_DIR}/tools"
   if fgrep -q -s -x "${tool}" "${toolsfile}"
   then
      log_warning "\"${tool}\" is already in the list of tools, will relink"
   else
      redirect_append_exekutor "${toolsfile}" echo "${tool}"
   fi

   local bindir

   bindir="${MULLE_VIRTUAL_ROOT}/bin"
   mkdir_if_missing "${bindir}"

   local dstfile

   dstfile="${bindir}/${tool}"

   exekutor chmod ugo+w "${bindir}"
   [ -e "${dstfile}" ] && exekutor chmod ugo+w "${dstfile}"

   exekutor ln -sf "${executable}" "${bindir}/" || exit 1

   exekutor chmod ugo-w "${dstfile}"
   exekutor chmod ugo-w "${bindir}"
}


_mulle_tools_remove()
{
   local tool="$1"

   [ -z "${tool}" ] && internal_fail "tool must not be empty"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT not defined"

   local toolsfile

   toolsfile="${MULLE_ENV_DIR}/tools"
   if [ ! -f "${toolsfile}" ]
   then
      log_warning "No tools present. Check your PATH."
      return 2
   fi

   local escaped

   escaped="`escaped_sed_pattern "${tool}"`"
   exekutor sed -i'.bak' "/^${escaped}\$/d" "${toolsfile}"

   local bindir

   bindir="${MULLE_VIRTUAL_ROOT}/bin"

   exekutor chmod ugo+w "${bindir}"
   remove_file_if_present "${bindir}/${tool}" &&
   exekutor chmod ugo-w "${bindir}"
}


_mulle_tools_list()
{
   local toolsfile

   toolsfile="${MULLE_ENV_DIR}/tools"
   if [ ! -f "${toolsfile}" ]
   then
      log_warning "No tools present. Check your PATH."
      return 2
   fi

   egrep '.' "${toolsfile}" | sort
}



###
### parameters and environment variables
###
sde_tools_main()
{
   log_entry "sde_tools_main" "$@"

   local MULLE_ENV_DIR

   MULLE_ENV_DIR="${MULLE_VIRTUAL_ROOT}/.mulle-env"
   #
   # handle options
   #
   while :
   do
      case "$1" in
         -*)
            sde_tools_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      add|list|remove)
         _mulle_tools_${cmd} "$@"
      ;;

      *)
         sde_tools_usage
      ;;
   esac
}
