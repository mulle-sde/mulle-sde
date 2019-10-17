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
MULLE_SDE_CRAFTORDER_SH="included"


sde_craftorder_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} craftorder [options]

   Show the craftorder of the dependencies.

Options:
   -h              : show this usage
   --cached        : show the cached craftorder contents
   --remaining     : show the part of the craftorder still needed to be crafted
   --remove-cached : remove cached craftorder contents
EOF
   exit 1
}


__get_craftorder_info()
{
   _cachedir="${MULLE_SDE_VAR_DIR}/cache"
   _craftorderfile="${_cachedir}/craftorder"
}


#
# this function is injected into the sourcetree walker
# it returns new marks in RVAL
#
r_append_mark_no_memo_to_subproject()
{
   local datasource="$1"
   local address="$2"
   local nodetype="$3"
   local marks="$4"

   if [ "${nodetype}" != "local" -o "${datasource}" != "/" ]
   then
      return 1
   fi

   case ",${marks}," in
      *',no-dependency',*)
         return 1
      ;;

      # this is to differentiate craftinfos from subprojects its
      # a hack
      *',no-link,'*)
         return 1
      ;;
   esac

   r_comma_concat "${marks}" "no-memo"
   return 0
}


#
# This should be another task so that it can run in parallel to the other
# updates
#
create_craftorder_file()
{
   log_entry "create_craftorder_file" "$@"

   local craftorderfile="$1"; shift
   local cachedir="$1"; shift

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   [ -z "${MULLE_FILE_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

   log_info "Updating ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} craftorder"

   mkdir_if_missing "${cachedir}"
   if ! redirect_exekutor "${craftorderfile}" \
      "${MULLE_SOURCETREE:-mulle-sourcetree}" \
            -V -s \
            ${MULLE_TECHNICAL_FLAGS} \
         craftorder \
            --no-print-env \
            --callback "`declare -f r_append_mark_no_memo_to_subproject`" \
            "$@"
   then
      remove_file_if_present "${craftorderfile}"
      fail "Failed to create craftorderfile"
   fi
}


create_craftorder_file_if_needed()
{
   log_entry "create_craftorder_file_if_needed" "$@"

   local craftorderfile="$1"; shift
   local cachedir="$1"; shift

   local sourcetreefile
   local craftorderfile

   #
   # our craftorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"

   sourcetreefile="${MULLE_VIRTUAL_ROOT}/.mulle/etc/sourcetree/config"

   #
   # produce a craftorderfile, if absent or old
   #
   if [ "${sourcetreefile}" -nt "${craftorderfile}" ]
   then
      create_craftorder_file "${craftorderfile}" "${cachedir}"
   else
      log_fluff "Craftorder file \"${craftorderfile}\" is up-to-date"
   fi
}


show_craftorder()
{
   log_entry "show_craftorder" "$@"

   log_info "Craftorder"
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     -V -s \
                     ${MULLE_TECHNICAL_FLAGS} \
                  craftorder \
                     --callback "`declare -f r_append_mark_no_memo_to_subproject`" \
                     "$@"
}


sde_craftorder_main()
{
   log_entry "sde_craftorder_main" "$@"

   local OPTION_CACHED='NO'
   local OPTION_REMOVE_CACHED='NO'
   local OPTION_CREATE='NO'
   local OPTION_REMAINING='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_craftorder_usage
         ;;

         --create)
            OPTION_CREATE='YES'
         ;;

         --cached)
            OPTION_CACHED='YES'
         ;;

         --remove-cached)
            OPTION_REMOVE_CACHED='YES'
         ;;

         --remaining)
            OPTION_REMAINING='YES'
         ;;

         -*)
            sde_craftorder_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_REMAINING}" = 'YES' -a "${OPTION_CACHED}" = 'YES' ]
   then
      fail "You can not specify --remaining and --cached at the same time"
   fi

   local _craftorderfile
   local _cachedir

   __get_craftorder_info

   if [ "${OPTION_REMOVE_CACHED}" = 'YES'  ]
   then
     if [ -z "${MULLE_PATH_SH}" ]
     then
        . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
     fi
     if [ -z "${MULLE_FILE_SH}" ]
     then
        . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
     fi

      remove_file_if_present "${_craftorderfile}"
      return 0
   fi

   if [ "${OPTION_CREATE}" = 'YES'  ]
   then
      create_craftorder_file "${_craftorderfile}" "${_cachedir}"
   fi

   if [ "${OPTION_REMAINING}" = 'NO' -a "${OPTION_CACHED}" = 'NO' ]
   then
      show_craftorder
      return $?
   fi


   log_verbose "Cached craftorder ${C_RESET_BOLD}${_craftorderfile}"

   if [ "${OPTION_REMAINING}" = 'YES' ]
   then
      if [ ! -f "${_craftorderfile}" ]
      then
         show_craftorder
      else
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_CRAFT:-mulle-craft}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           --craftorder-file "${_craftorderfile}" \
                        list
      fi
      return $?
   fi

   if [ ! -f "${_craftorderfile}" ]
   then
      log_warning "There is no cached craftorder file"
      return 0
   fi

   cat "${_craftorderfile}"
   return 0
}
