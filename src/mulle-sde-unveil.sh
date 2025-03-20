# shellcheck shell=bash
#
#   Copyright (c) 2022 Nat! - Mulle kybernetiK
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
MULLE_SDE_UNVEIL_SH='included'


sde::unveil::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} unveil [options]

   Emit a CSV that can be used to create an unveil command to sandbox
   mulle-make.

Options:
EOF
   exit 1
}


sde::unveil::main()
{
   log_entry "sde::unveil::main" "$@"

   local OPTION_EXECUTABLES='DEFAULT'
   local OPTION_SYMLINKS='DEFAULT'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::unveil::usage
         ;;

         --no-exe|--no-executable|--no-executables)
            OPTION_EXECUTABLES='NO'
         ;;

         --symlinks)
            OPTION_SYMLINKS='YES'
         ;;

         --no-symlinks)
            OPTION_SYMLINKS='NO'
         ;;

         -*)
            sde::unveil::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local dependency_dir
   local kitchen_dir
   local stash_dir
   local var_dir
   local libexec_dir
   local dependency_parent_dir
   local kitchen_parent_dir
   local stash_parent_dir
   local var_parent_dir
   local libexec_parent_dir

   rexekutor printf "%s;%s;d\n" "${MULLE_VIRTUAL_ROOT}" "crwx"

   #
   # the next directories only exist when mulle-craft is running
   # which means it must be possible to create them (indicated by 'D')
   #
   dependency_dir="${DEPENDENCY_DIR:-${MULLE_VIRTUAL_ROOT}/dependency}"
   r_dirname "${dependency_dir}"
   dependency_parent_dir="${RVAL}"
   if ! string_has_prefix "${dependency_parent_dir}" "${MULLE_VIRTUAL_ROOT}"
   then
      rexekutor printf "%s;%s;d\n" "${dependency_parent_dir}" "crwx"
   fi

   kitchen_dir="${KITCHEN_DIR:-${MULLE_VIRTUAL_ROOT}/kitchen}"
   r_dirname "${kitchen_dir}"
   kitchen_parent_dir="${RVAL}"
   if ! string_has_prefix "${kitchen_parent_dir}" "${MULLE_VIRTUAL_ROOT}" && \
      ! string_has_prefix "${kitchen_parent_dir}" "${dependency_parent_dir}"
   then
      rexekutor printf "%s;%s;d\n" "${kitchen_parent_dir}" "crwx"
   fi

   stash_dir="${MULLE_SOURCETREE_STASH_DIR:-${MULLE_VIRTUAL_ROOT}/stash}"
   r_dirname "${stash_dir}"
   stash_parent_dir="${RVAL}"
   if ! string_has_prefix "${stash_parent_dir}" "${MULLE_VIRTUAL_ROOT}"  && \
      ! string_has_prefix "${stash_parent_dir}" "${dependency_parent_dir}"  && \
      ! string_has_prefix "${stash_parent_dir}" "${kitchen_parent_dir}"
   then
      rexekutor printf "%s;%s;d\n" "${stash_parent_dir}" "crwx"
   fi

   var_dir="${MULLE_ETC_VAR_DIR:-${MULLE_VIRTUAL_ROOT}/.mulle/var}"
   r_dirname "${var_dir}"
   var_parent_dir="${RVAL}"
   if ! string_has_prefix "${var_parent_dir}" "${MULLE_VIRTUAL_ROOT}" && \
      ! string_has_prefix "${var_parent_dir}" "${dependency_parent_dir}"  && \
      ! string_has_prefix "${var_parent_dir}" "${kitchen_parent_dir}"  && \
      ! string_has_prefix "${var_parent_dir}" "${stash_parent_dir}"
   then
      rexekutor printf "%s;%s;d\n" "${var_parent_dir}" "crwx"
   fi

   libexec_dir="${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}"
   r_dirname "${libexec_dir}"
   libexec_parent_dir="${RVAL}"
   if ! string_has_prefix "${libexec_parent_dir}" "${MULLE_VIRTUAL_ROOT}" && \
      ! string_has_prefix "${libexec_parent_dir}" "${dependency_parent_dir}"  && \
      ! string_has_prefix "${libexec_parent_dir}" "${kitchen_parent_dir}"  && \
      ! string_has_prefix "${libexec_parent_dir}" "${stash_parent_dir}"  && \
      ! string_has_prefix "${libexec_parent_dir}" "${var_parent_dir}"
   then
      rexekutor printf "%s;%s;d\n" "${libexec_parent_dir}" "rx"
   fi

   # TODO need a better directory simplifier

   if [ "${OPTION_EXECUTABLES}" = 'NO' ]
   then
      return
   fi

   local options

   case "${OPTION_SYMLINKS}" in
      DEFAULT)
      ;;

      YES)
         options="--symlinks"
      ;;

      NO)
         options="--no-symlinks"
      ;;
   esac

   rexekutor "${MULLE_ENV:-mulle-env}" ${MULLE_TECHNICAL_FLAGS} \
                                       ${MULLE_ENV_FLAGS} \
                                    unveil \
                                       ${options}
}
