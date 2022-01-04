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
MULLE_SDE_CONFIG_SH="included"


sde::config::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} sourcetree [options] [command]

   This command manipulates mulle-sourcetree configs for a project. Usually
   your project only has one sourcetree configuration named "config", but
   sometimes it can be useful to have multiple sourcetree configurations.

Commands:
   name   : get name of current sourcetree configuratioon
   list   : list current sourcetree configurations
   remove : remove a sourcetree configuration
   copy   : copy a sourcetree configuration

EOF
   exit 1
}


sde::config::list_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config list [options]

   List the currently active sourcetree configuration. You can also see the
   available sourcetree configurations.

Options:
   -a                  : list all available sourcetree configurations
   -r                  : list sourcetree configs recursively
   --ignore-default    : ignore "config" only sourcetrees (default)
   --no-ignore-default : print all sourcetreee configurations
   --name              : list the sourcetree configuration name only

EOF
   exit 1
}


#
# this function is actually executed inside mulle-sourcetree so
# globals and other functions are not necessarily available.
#
sde::config::walk_config_name_callback()
{
   local reflectfile
   local config

   reflectfile=".mulle/etc/sde/reflect"
   if [ -f "${reflectfile}" ]
   then
      config="`egrep -v '^#' "${reflectfile}" `"
   fi
   config="${config:-config}"

   printf "%s: %s\n" "${NODE_FILENAME#${MULLE_USER_PWD}/}" "${config}"
}


sde::config::walk_name_callback_no_default()
{
   local reflectfile
   local config

   reflectfile=".mulle/etc/sde/reflect"
   if [ -f "${reflectfile}" ]
   then
      config="`egrep -v '^#' "${reflectfile}" `"
   fi
   config="${config:-config}"

   if [ "${config}" != "config" ]
   then
      printf "%s: %s\n" "${NODE_FILENAME#${MULLE_USER_PWD}/}" "${config}"
   fi
}


sde::config::walk_callback()
{
   if [ -z "${MULLE_SOURCETREE_CONFIG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-config.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-config.sh" || exit 1
   fi

   local names

   names="`(
      eval $(mulle-env mulle-tool-env sourcetree) ;
      sourcetree::config::name_main -a --separator ':'
      )`"

   printf "%s: %s\n" "${NODE_FILENAME#${MULLE_USER_PWD}/}" "${names:--}"
}


sde::config::walk_callback_no_default()
{
   if [ -z "${MULLE_SOURCETREE_CONFIG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-config.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-config.sh" || exit 1
   fi

   local names

   names="`(
      eval $(mulle-env mulle-tool-env sourcetree) ;
      sourcetree::config::name_main -a --separator ':'
      )`"

   if [ ! -z "${names}" -a "${names}" != "config" ]
   then
      printf "%s: %s\n" "${NODE_FILENAME#${MULLE_USER_PWD}/}" "${names}"
   fi
}


sde::config::dependency_walk()
{
   local functionname="$1"

   # get "source" of function into callback
   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -N \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               walk \
                  --cd \
                  --marks dependency,mainproject \
                  --declare-function "`declare -f "${functionname}" `" \
                  "${functionname}"
   return $?
}


sde::config::list()
{
   log_entry "sde::config::list" "$@"

   local OPTION_RECURSIVE='NO'
   local OPTION_IGNORE_DEFAULT='YES'
   local OPTION_LIST_NAMES='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::list_usage
         ;;

         --ignore-default)
            OPTION_IGNORE_DEFAULT='YES'
         ;;

         --no-ignore-default)
            OPTION_IGNORE_DEFAULT='NO'
         ;;

         --name|--names)
            OPTION_LIST_NAMES='YES'
         ;;

         -r)
            OPTION_RECURSIVE='YES'
         ;;

         -*)
            sde::config::list_usage "Unknown config option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   if [ "${OPTION_RECURSIVE}" = 'YES' ]
   then
      if [ "${OPTION_LIST_NAMES}" = 'YES' ]
      then
         if [ "${OPTION_IGNORE_DEFAULT}" = 'YES' ]
         then
            sde::config::dependency_walk sde::config::walk_name_callback_no_default
         else
            sde::config::dependency_walk sde::config::walk_config_name_callback
         fi
      else
         if [ "${OPTION_IGNORE_DEFAULT}" = 'YES' ]
         then
            sde::config::dependency_walk sde::config::walk_callback_no_default
         else
            sde::config::dependency_walk sde::config::walk_callback
         fi
      fi
      return $?
   fi

   MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        -N \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_SOURCETREE_FLAGS} \
                     config list "$@" || exit 1
}



sde::config::main()
{
   log_entry "sde::config::main" "$@"


   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::config::usage
         ;;

         -*)
            sde::config::usage "Unknown config option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="$1"

   [ $# -ge 1 ] && shift

   case "${cmd:-list}" in
      list)
         sde::config::list "$@"
      ;;

      name|copy|remove)
         MULLE_VIRTUAL_ROOT="${MULLE_VIRTUAL_ROOT}" \
            rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                              -N \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_SOURCETREE_FLAGS} \
                           "$@" || exit 1
      ;;

      '')
         sde::config::usage
      ;;

      *)
         sde::config::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
