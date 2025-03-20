# shellcheck shell=bash
#
#   Copyright (c) 2019 Nat! - Mulle kybernetiK
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
MULLE_SDE_EXPORT_SH='included'


sde::export::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} export <dependency|library>

   Export your tweaked dependency settings to ~/.mulle/share/craftinfo
   to easily share with other non-related projects. Furthermore you can share
   this with others, my hosting you own craftinfo directory or merging
   with the "official" repository:
      https://github.com/craftinfo/craftinfo

Options:
   -h           : show this usage
   --write      : write export to ${OPTION_DIRECTORY}
   --dir <path> : write to <path> instead of ${OPTION_DIRECTORY}

EOF
   exit 1
}



sde::export::main()
{
   log_entry "sde::export::main" "$@"

   local OPTION_WRITE='NO'
   local OPTION_DIRECTORY="${HOME}/.mulle/etc/craftinfo"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::export::usage
         ;;

         --write)
            OPTION_WRITE='YES'
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde::export::usage "Missing argument to \"$1\""
            shift

            OPTION_DIRECTORY="$1"
            OPTION_WRITE='YES'
         ;;

         -*)
            sde::export::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde::export::usage  "Missing name"

   local name

   name="$1"
   shift

   [ $# -ne 0 ] && sde::export::usage  "Superflous arguments $*"

   local type

   type='library'

   local address

   address="`mulle-sourcetree get --if-present --nodetype none "${name}" address`"
   if [ -z "${address}" ]
   then
      type='dependency'
      address="`mulle-sourcetree get --if-present --marks "dependency" "${name}" address`"
      if [ -z "${address}" ]
      then
         fail "${name} is neither a library nor a dependency"
      fi
   fi

   local sourcetree_text
   local craftinfo_text

   # first export the sourcetree commands
   sourcetree_text="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} ${type} export "${address}"`"

   # the export the craftinfo if any
   craftinfo_text="`rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} craftinfo export "${address}"`"

   if [ -z "${sourcetree_text}" -a -z "${craftinfo_text}" ]
   then
      fail "There is nothing to export for \"${name}\""
   fi

   local text

   text="#! /bin/sh"$'\n'

   if [ ! -z "${sourcetree_text}" ]
   then
      text="${text}"$'\n'"${sourcetree_text}"
   fi

   if [ ! -z "${craftinfo_text}" ]
   then
      text="${text}"$'\n'"${craftinfo_text}"
   fi

   if [ "${OPTION_WRITE}" != 'YES' ]
   then
      printf "%s\n" "${text}"
   fi

   local filename

   filename="${OPTION_DIRECTORY}/${address}/add"
   r_mkdir_parent_if_missing "${filename}"

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ] && [ -f "${filename}" ]
   then
      local diff_text

      if diff_text="`diff <( printf "%s\n" "${text}" ) "${filename}" `"
      then
         log_info "No diffs found."
         return 0
      fi

      log_error "${C_RESET_BOLD}${filename}${C_ERROR} already exists. Use -f to clobber"
      log_info "Diff:"
      printf "%s\n" "${diff_text}"
      exit 1
   fi

   redirect_exekutor "${filename}" printf "%s\n" "${text}"
   exekutor chmod 755 "${filename}"
}


sde::project::initialize()
{
   include "case"
   include "path"
   include "file"
}

sde::project::initialize

:

