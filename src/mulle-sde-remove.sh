# shellcheck shell=bash
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
# Rebuild if files of certain files are modified
#
MULLE_SDE_REMOVE_SH='included'


sde::remove::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} remove [options] <filepath|url|env>

   Remove an existing file or a dependency or environment variable.

   Example:
         ${MULLE_USAGE_NAME} remove src/MyProtocolClass.m
         ${MULLE_USAGE_NAME} remove gitlab:madler/zlib

Options:
   -h   : this help
   -q   : do not reflect and rebuild, if a dependency is removed
EOF
   exit 1
}



sde::remove::in_project()
{
   log_entry "sde::remove::in_project" "$@"

   local filename="$1"

   if ! remove_file_if_present "${filename}"
   then
      return 1
   fi

   exekutor mulle-sde reflect
   return $?
}


sde::remove::not_in_project()
{
   log_entry "sde::remove::not_in_project" "$@"

   local filename="$1"

   remove_file_if_present "${filename}"
}



###
### parameters and environment variables
###
sde::remove::main()
{
   log_entry "sde::remove::main" "$@"

   # if we are in a project, but not not really within yet, rexecute
   if [ -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      if rexekutor mulle-sde -s status --clear --project
      then
         sde::exec_command_in_subshell "CD" remove "$@"
      fi
   fi

   local OPTION_NAME
   local OPTION_VENDOR
   local OPTION_ALL_VENDORS='NO'
   local OPTION_FILE_EXTENSION
   local OPTION_EXTERNAL_COMMAND='YES'
   local OPTION_TYPE
   local OPTION_QUICK
   local OPTION_EMBEDDED
   local OPTION_IS_URL='DEFAULT'
   local OPTION_IS_ENV='DEFAULT'

   # need includes for usage

   include "path"
   include "file"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::remove::usage
         ;;

         --is-url)
            OPTION_IS_URL='YES'
         ;;

         --no-is-url|--no-url|--is-no-url)
            OPTION_IS_URL='NO'
         ;;

         --is-env)
            OPTION_IS_ENV='YES'
         ;;

         --no-is-env|--no-env|--is-no-env)
            OPTION_IS_ENV='NO'
         ;;

         --no-external-command)
            OPTION_EXTERNAL_COMMAND='NO'
         ;;

         -q|--quick)
            OPTION_QUICK='YES'
         ;;

         -*)
            sde::remove::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 1  ] && sde::remove::usage


   if [ $# -eq 1 -a "${OPTION_EXTERNAL_COMMAND}" = 'YES' ]
   then
      include "sde::common"

      sde::common::update_git_if_needed "${HOME}/.mulle/share/craftinfo}" \
                                        "${MULLE_SDE_CRAFTINFO_URL:-https://github.com/craftinfo/craftinfo.git}" \
                                        "${MULLE_SDE_CRAFTINFO_BRANCH}"

      sde::common::maybe_exec_external_command 'remove' \
                                               "$1" \
                                               "${HOME}/.mulle/share/craftinfo" \
                                               'NO'
      # if no external command happened, just continue
   fi

   local filename

   filename="$1"
   [  -z "${filename}" ] && sde::remove::usage "filename is empty"

   if [ "${OPTION_IS_ENV}" = 'DEFAULT' ]
   then
      r_identifier "${filename}"
      r_uppercase "${filename}"
      if [ "${RVAL}" = "${filename}" ]
      then
         OPTION_IS_ENV='YES'
      fi
   fi

   if [ "${OPTION_IS_ENV}" = 'YES' ]
   then
      if rexekutor mulle-env ${MULLE_TECHNICAL_FLAGS} environment remove "${filename}"
      then
         return 0
      fi
   fi

   if [ "${OPTION_IS_URL}" = 'DEFAULT' ]
   then
      case "${filename}" in
         *://*)
            OPTION_IS_URL='YES'
         ;;

         *:*)
            local scheme domain host scm user repo branch tag
            local composed

            eval `mulle-domain parse-url "${filename}" 2> /dev/null`
            if [ ! -z "${host}" -a ! -z "${user}" -a ! -z "${repo}" ]
            then
               composed="`mulle-domain compose-url --domain "${domain}" \
                                                   --scm "${git}"       \
                                                   --host "${host}"     \
                                                   --user "${user}"     \
                                                   --repo "${repo}"  `"
               filename="${composed:-${filename}}"
            fi
            OPTION_IS_URL='YES'
         ;;
      esac
   fi

   #
   # check if destination is within our project, decide on where to go
   #
   if [ -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      if [ "${OPTION_IS_URL}" != 'YES' ]
      then
         sde::remove::not_in_project "${filename}"
         return $?
      fi

      fail "Unknown URL ${filename}"
   fi

   if rexekutor mulle-sourcetree ${MULLE_TECHNICAL_FLAGS} -s get "${filename}" > /dev/null
   then
      OPTION_IS_URL='YES'
   fi

   if [ "${OPTION_IS_URL}" = 'YES' ]
   then
      mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency remove "${filename}" || return 1
      if [ "${OPTION_QUICK}" != 'YES' ]
      then
         if [ "${OPTION_EMBEDDED}" = 'YES' ]
         then
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} reflect &&
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} fetch
         else
            rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} reflect || return $?
            if sde::is_test_directory "$PWD"
            then
               rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} test craft
            else
               rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} craft --release craftorder
            fi
         fi
      fi
      return $?
   fi

   local filepath

   filepath="${filename}"
   if ! is_absolutepath "${filepath}"
   then
      r_filepath_concat "${MULLE_USER_PWD}" "${filename}"
      filepath="${RVAL}"
   fi

   # make comparable
   r_resolve_all_path_symlinks "${filepath}"
   filepath="${RVAL}"

   r_relative_path_between "${filepath}" "${MULLE_VIRTUAL_ROOT}"

   log_debug "${C_RED}${filepath} - ${MULLE_VIRTUAL_ROOT} = relative=${RVAL}"

   case "${RVAL}" in
      ../*)
         fail "Won't remove file that's not in the project"
      ;;

      *)
         sde::remove::in_project "${filepath#"${MULLE_VIRTUAL_ROOT}/"}"
         return $?
      ;;
   esac
}

