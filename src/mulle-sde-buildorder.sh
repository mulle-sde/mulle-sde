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
MULLE_SDE_BUILDORDER_SH="included"


sde_buildorder_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} buildorder [options]

   Show the buildorder of the dependencies.

Options:
   -h           : show this usage
   --cached     : show the cached buildorder contents
   --remaining  : show the part of the buildorder still needed to be built
EOF
   exit 1
}


__get_buildorder_info()
{
   _cachedir="${MULLE_SDE_DIR}/var/${MULLE_HOSTNAME}/cache"
   _buildorderfile="${_cachedir}/buildorder"
}


append_mark_no_memo_to_subproject()
{
   if [ "${MULLE_NODETYPE}" != "local" -o "${MULLE_DATASOURCE}" != "/" ]
   then
      return
   fi

   case ",${MULLE_MARKS}," in
      *",no-dependency,"*)
         return
      ;;
   esac

   r_comma_concat "${MULLE_MARKS}" "no-memo"
   MULLE_MARKS="${RVAL}"
}


#
# This should be another task so that it can run in parallel to the other
# updates
#
create_buildorder_file()
{
   log_entry "create_buildorder_file" "$@"

   local buildorderfile="$1"; shift
   local cachedir="$1"; shift

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   [ -z "${MULLE_FILE_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"

   log_info "Updating ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} buildorder"

   mkdir_if_missing "${cachedir}"
   if ! redirect_exekutor "${buildorderfile}" \
      "${MULLE_SOURCETREE:-mulle-sourcetree}" \
            -V \
            ${MULLE_TECHNICAL_FLAGS} \
            ${MULLE_SOURCETREE_FLAGS} \
         buildorder \
            --output-marks \
            --callback "`declare -f append_mark_no_memo_to_subproject`" \
            "$@"
   then
      remove_file_if_present "${buildorderfile}"
      exit 1
   fi
}


create_buildorder_file_if_needed()
{
   log_entry "create_buildorder_file_if_needed" "$@"

   local buildorderfile="$1"; shift
   local cachedir="$1"; shift

   local sourcetreefile
   local buildorderfile
   #
   # our buildorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"

   sourcetreefile="${MULLE_VIRTUAL_ROOT}/.mulle-sourcetree/etc/config"

   #
   # produce a buildorderfile, if absent or old
   #
   if [ "${sourcetreefile}" -nt "${buildorderfile}" ]
   then
      create_buildorder_file "${buildorderfile}" "${cachedir}"
   else
      log_fluff "Buildorder file \"${buildorderfile}\" is up-to-date"
   fi
}


show_buildorder()
{
   log_entry "show_buildorder" "$@"

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     -V \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_SOURCETREE_FLAGS} \
                  buildorder \
                     --output-marks \
                     --callback "`declare -f append_mark_no_memo_to_subproject`" \
                     "$@"
}


sde_buildorder_main()
{
   log_entry "sde_buildorder_main" "$@"

   local OPTION_CACHED='NO'
   local OPTION_REMAINING='NO'

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_buildorder_usage
         ;;

         --cached)
            OPTION_CACHED='YES'
         ;;

         --remaining)
            OPTION_REMAINING='YES'
         ;;

         -*)
            sde_buildorder_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_REMAINING}" = 'YES' -a "${OPTION_CACHED}" = 'YES' ]
   then
      fail "You can not specify --build and --cached at the same time"
   fi

   if [ "${OPTION_REMAINING}" = 'NO' -a "${OPTION_CACHED}" = 'NO' ]
   then
      show_buildorder
      return $?
   fi

   local _buildorderfile
   local _cachedir

   __get_buildorder_info

   log_verbose "Cached buildorder ${C_RESET_BOLD}${_buildorderfile}"

   if [ "${OPTION_REMAINING}" = 'YES' ]
   then
      if [ ! -f "${_buildorderfile}" ]
      then
         show_buildorder
      else
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            exekutor "${MULLE_CRAFT:-mulle-craft}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_CRAFT_FLAGS} \
                           --buildorder-file "${_buildorderfile}" \
                        list
      fi
      return $?
   fi

   if [ ! -f "${_buildorderfile}" ]
   then
      log_warning "There is no cached buildorder file"
      return 0
   fi


   cat "${_buildorderfile}"
   return 0
}
