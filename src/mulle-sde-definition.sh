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
MULLE_SDE_MAKEINFO_SH="included"


sde_definition_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} definition [options] [command]

   This command manipulates mulle-make definitions for a project. A common
   definition is CC to specify the compiler to use (e.g. mulle-clang).
   Definitions can be OS-specific, e.g. only valid for linux.

   A commonly manipulated definition setting is \"CFLAGS\".

   See \`mulle-make definition\` for more detailed help about the available
   commands.

   Example:
      mulle-sde definition set CFLAGS '--no-remorse'

   > To change settings of a dependency use \`mulle-sde dependency craftinfo\`
   > instead.

Options:
   --definition-dir <dir> : specify definition directory to manipulate
   --os <name>            : use the OS specific scope instead of global

Commands:
   get    : get value of a definition
   keys   : get a list of known keys, unknown keys are possible too
   list   : list current definitions
   remove : remove a definition
   search : locate definition directories
   set    : change a definition

EOF
   exit 1
}


r_definition_scopes()
{
   log_entry "sde_definition_scopes" "$@"

   local option="$1"

   local i

   RVAL=""
   shopt -s nullglob
   for i in .mulle/etc/craft/definition .mulle/etc/craft/definition.*
   do
      case "$i" in
         .mulle/etc/craft/definition)
				if [ -d .mulle/etc/craft/definition ]
				then
	            if [ "${option}" != "no-global" ]
	            then
	               r_add_line "${RVAL}" "global"
	            fi
	         fi
         ;;

         *)
            r_add_line "${RVAL}" "${i#.mulle/etc/craft/definition.}"
         ;;
      esac
   done
   shopt -u nullglob
}


sde_definition_scopes()
{
   log_entry "sde_definition_scopes" "$@"

   log_info "Defined Definition Scopes"

   r_definition_scopes

   if [ ! -z "${RVAL}" ]
   then
      echo "${RVAL}" | sed 's/^/   /'
   fi
}


sde_call_definition()
{
   log_entry "sde_call_definition" "$@"

   local cmd="$1";       [ $# -ne 0 ] && shift
   local flags="$1";     [ $# -ne 0 ] && shift
   local directory="$1"; [ $# -ne 0 ] && shift

   MULLE_USAGE_NAME="mulle-sde" \
   MULLE_USAGE_COMMAND="definition" \
      exekutor "${MULLE_MAKE:-mulle-make}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${flags} \
                  "definition" \
                     --definition-dir "${directory}" \
                     "${cmd}" \
                        "$@"
}


sde_definition_set_remove()
{
   log_entry "sde_definition_set_remove" "$@"

   local cmd="$1"   ; [ $# -ne 0 ] && shift
   local scope="$1" ; [ $# -ne 0 ] && shift
   local flags="$1" ; [ $# -ne 0 ] && shift
   local definitiondir="$1" ; [ $# -ne 0 ] && shift

   local key="$1"

   if [ "${scope}" = "DEFAULT" ]
   then
      r_definition_scopes "no-global"

      local i

      set -f; IFS=$'\n'
      for i in ${RVAL}
      do
         set +f; IFS="${DEFAULT_IFS}"
         sde_call_definition "remove" \
                             "${flags}"  \
                             "${definitiondir}.${i}" \
                             "${key}"
      done
   fi
   set +f; IFS="${DEFAULT_IFS}"

   local directory

   case "${scope}" in
      DEFAULT|global)
         directory="${definitiondir}"
      ;;

      *)
         directory="${definitiondir}.${scope}"
      ;;
   esac

   sde_call_definition "${cmd}" "${flags}" "${directory}" "$@"
}


_sde_definition_keys()
{
   log_entry "_sde_definition_keys" "$@"

   local cmd="$1"
   local scope="$2"
   local flags="$3"
   local definitiondir="$4"

   if [ "${scope}" = "DEFAULT" ]
   then
      sde_call_definition "keys" "${flags}" "${definitiondir}.${MULLE_UNAME}"
   fi

   local directory

   case "${scope}" in
      DEFAULT|global)
         directory="${definitiondir}"
      ;;

      *)
         directory="${definitiondir}.${scope}"
      ;;
   esac

}


sde_definition_keys()
{
   log_entry "sde_definition_keys" "$@"

   _sde_definition_keys "$@" | sort -u
}


sde_definition_get()
{
   log_entry "sde_definition_get" "$@"

   local scope="$1"; shift
   local flags="$1"; shift
   local definitiondir="$1"; shift

   if [ "${scope}" = "DEFAULT" ]
   then
      if sde_call_definition "get" \
                             "${flags}"  \
                             "${definitiondir}.${MULLE_UNAME}" \
                             "$@"
      then
         return
      fi
   fi

   local directory

   case "${scope}" in
      DEFAULT|global)
         directory="${definitiondir}"
      ;;

      *)
         directory="${definitiondir}.${scope}"
      ;;
   esac

   sde_call_definition "get" "${flags}" "${directory}" "$@"
}



sde_definition_list()
{
   log_entry "sde_definition_list" "$@"

   local scope="$1"; shift
   local flags="$1"; shift
   local definitiondir="$1"; shift

   local firstscope
   local directory

   case "${scope}" in
      DEFAULT|global)
         firstscope="global"
         directory="${definitiondir}"
      ;;

      *)
         firstscope="${scope}"
         directory="${definitiondir}.${scope}"
      ;;
   esac

   log_info "${firstscope}"
   sde_call_definition "list" "${flags}" "${directory}" "$@" | sed 's/^/   /'

   if [ "${scope}" != "DEFAULT" ]
   then
      return
   fi

   r_definition_scopes "no-global"

   local i

   set -f; IFS=$'\n'
   for i in ${RVAL}
   do
      set +f; IFS="${DEFAULT_IFS}"

      log_info "${i}"
      sde_call_definition "list" \
                          "${flags}"  \
                          "${definitiondir}.${i}" | sed 's/^/   /'
   done
   set +f; IFS="${DEFAULT_IFS}"
}



sde_definition_main()
{
   log_entry "sde_definition_main" "$@"

   local OPTION_DEFINITION_DIR=".mulle/etc/craft/definition"

   local argument
   local flags
   local searchflags

   local scope="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_definition_usage
         ;;

         --allow-unknown-option|--no-allow-unknown-option)
            r_concat "${flags}" "$1"
            flags="${RVAL}"
         ;;

         --definition-dir)
            [ $# -eq 1 ] && sde_definition_usage "Missing argument to \"$1\""
            shift

            OPTION_DEFINITION_DIR="$1"
         ;;

         --global)
            r_concat "${searchflags}" "$1"
            scope="global"
            searchflags="${RVAL}"
         ;;

         --os)
            [ $# -eq 1 ] && sde_definition_usage "Missing argument to \"$1\""
            shift

            scope="$1"
            r_concat "${searchflags}" "$1"
            searchflags="${RVAL}"
         ;;

         -*)
            sde_definition_usage "Unknown definition option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_definition_usage

   local cmd="$1"; shift

   case "${cmd}" in
      search)
         MULLE_USAGE_NAME="mulle-sde" \
            rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                        search \
                           ${searchflags} \
                              "$@"
      ;;

      scopes)
         sde_definition_scopes "$@"
      ;;


      keys)
         sde_call_definition "keys"
      ;;

      get|keys|list)
         sde_definition_${cmd} "${scope}" \
                               "${flags}" \
                               "${OPTION_DEFINITION_DIR}" \
                               "$@"
      ;;

      remove|set)
         sde_definition_set_remove "${cmd}" \
                                   "${scope}" \
                                   "${flags}" \
                                   "${OPTION_DEFINITION_DIR}" \
                                   "$@"
      ;;

      '')
         sde_definition_usage
      ;;

      *)
         sde_definition_usage "Unknown command \"${cmd}\""
      ;;
   esac
}
