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
MULLE_SDE_DEFINITION_SH="included"


sde_definition_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} definition [options] [command]

   This command manipulates mulle-make definitions for a project. A common
   definition is CC to specify the compiler to use (e.g. mulle-clang).
   Definitions can be platform-specific, e.g. only valid for builds
   targetting linux.

   A commonly manipulated definition setting is \"CFLAGS\".

   See \`mulle-make definition\` for more detailed help about the available
   commands.

   Example:
      mulle-sde definition set CFLAGS '-DNO_REMORSE=1848'

   > To change settings of a dependency use \`mulle-sde dependency craftinfo\`
   > instead.

Options:
   --definition-dir <dir> : specify the definition directory to manipulate
   --platform <name>      : use the platform specific scope instead of global

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


r_pick_definition_dir()
{
   local etcdir="$1"
   local sharedir="$2"
   local suffix="$3"

   if [ ! -z "${etcdir}" -a -e "${etcdir}${suffix}" ]
   then
      RVAL="${etcdir}${suffix}"
   else
      RVAL="${sharedir}${suffix}"
   fi
}


r_definition_scopes()
{
   log_entry "sde_definition_scopes" "$@"

   local etcdir="$1"
   local sharedir="$2"
   local option="$3"

   local i
   local scopes 

   scopes=""
   shopt -s nullglob
   for i in "${etcdir}" "${etcdir}".* "${sharedir}" "${sharedir}".*
   do
      case "$i" in
         "${etcdir}"|"${sharedir}")
            if [ "${option}" != "no-global" ] # && [ -d "${i}" ]
            then
               r_add_unique_line "${scopes}" "global"
               scopes="${RVAL}"
            fi
         ;;

         *)
            # potentially allow .darwin.11 sometime in the future ?
            r_basename "$i"
            r_add_unique_line "${scopes}" "${RVAL#*\.}"
            scopes="${RVAL}"
         ;;
      esac
   done
   shopt -u nullglob

   RVAL="${scopes}"
}


sde_definition_scopes()
{
   log_entry "sde_definition_scopes" "$@"

   log_info "Defined Definition Scopes"

   r_definition_scopes

   if [ ! -z "${RVAL}" ]
   then
      printf "%s\n" "${RVAL}" | sed 's/^/   /'
   fi
}


sde_call_definition()
{
   log_entry "sde_call_definition" "$@"

   local cmd="$1"      
   local flags="$2"    
   local directory="$3"
   shift 3

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


sde_call_definition_if_dir_exists()
{
   log_entry "sde_call_definition_if_dir_exists" "$@"

   if [ ! -d "$3" ]
   then
      return 2
   fi
   sde_call_definition "$@"
}



_sde_definition_keys()
{
   log_entry "_sde_definition_keys" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   case "${scope}" in 
      "ALL")
         internal_fail "keys can not use --all"
      ;;

      "DEFAULT")
         if ! sde_call_definition_if_dir_exists "keys" "${flags}" "${etcdir}.${MULLE_UNAME}"
         then
            if sde_call_definition_if_dir_exists "keys" "${flags}" "${sharedir}.${MULLE_UNAME}"
            then
               return
            fi
         fi
      ;;
   esac 
   
   case "${scope}" in 
      DEFAULT|global)
         if ! sde_call_definition_if_dir_exists "keys" "${flags}" "${etcdir}"
         then
            sde_call_definition_if_dir_exists "keys" "${flags}" "${sharedir}"
            return $?
         fi
         return 0
      ;;
   esac

   if ! sde_call_definition_if_dir_exists "keys" "${flags}" "${etcdir}.${scope}"
   then
      if sde_call_definition_if_dir_exists "keys" "${flags}" "${sharedir}.${scope}"
      then
         return
      fi
   fi
}


sde_definition_keys()
{
   log_entry "sde_definition_keys" "$@"

   _sde_definition_keys "$@" | sort -u
}


sde_definition_get()
{
   log_entry "sde_definition_get" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   local directory

   case "${scope}" in
      ALL)
         r_pick_definition_dir "${etcdir}" "${sharedir}" 
         directory="${RVAL}"
         sde_call_definition "get" "${flags}" "${directory}" "$@"

         r_definition_scopes "no-global"
         scopes="${RVAL}"

         local i

         set -o noglob; IFS=$'\n'
         for i in ${scopes}
         do
            set +o noglob; IFS="${DEFAULT_IFS}"

            r_pick_definition_dir "${etcdir}" "${sharedir}" ".${scope}" 
            directory="${RVAL}"

            sde_call_definition "get" "${flags}" "${directory}" "$@"
         done
         set +o noglob; IFS="${DEFAULT_IFS}"
         return
         ;;

      DEFAULT)
         r_pick_definition_dir "${etcdir}" "${sharedir}" ".${MULLE_UNAME}"
         directory="${RVAL}"
         if sde_call_definition "get" "${flags}" "${directory}" "$@"
         then
            return
         fi
         r_pick_definition_dir "${etcdir}" "${sharedir}" 
         directory="${RVAL}"
      ;;

      global)
         r_pick_definition_dir "${etcdir}" "${sharedir}" 
         directory="${RVAL}"
      ;;

      *)
         r_pick_definition_dir "${etcdir}" "${sharedir}" ".${scope}" 
         directory="${RVAL}"
      ;;
   esac

   sde_call_definition "get" "${flags}" "${directory}" "$@"
}


sde_definition_list_scope()
{
   log_entry "sde_definition_list_global" "$@"

   local etcdir="$1"
   local sharedir="$2"
   local scope="$3"
   shift 3

   local directory

   r_pick_definition_dir "${etcdir}" "${sharedir}" ".${scope}"
   directory="${RVAL}"

   log_info "${scope}"
   sde_call_definition "list" "${flags}" "${directory}" "$@" \
   | sed 's/^/   /'
}


sde_definition_list_global()
{
   log_entry "sde_definition_list_global" "$@"

   local etcdir="$1"
   local sharedir="$2"
   shift 2

   local directory

   r_pick_definition_dir "${etcdir}" "${sharedir}" 
   directory="${RVAL}"

   log_info "Global"
   sde_call_definition "list" "${flags}" "${directory}" "$@" \
   | sed 's/^/   /'
}


#
# We don't symlink the definitions, as they are usually small. We could
# though.
#
sde_definition_set()
{
   log_entry "sde_definition_set" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   local scopes 

   case "${scope}" in
      ALL)
         etc_setup_from_share_if_needed "${etcdir}" "${sharedir}" "NO"
         sde_call_definition "set" "${flags}" "${etcdir}" "$@"

         r_definition_scopes "no-global"
         scopes="${RVAL}"

         local i

         set -o noglob; IFS=$'\n'
         for i in ${scopes}
         do
            set +o noglob; IFS="${DEFAULT_IFS}"

            etc_setup_from_share_if_needed "${etcdir}.${i}" "${sharedir}.${i}" "NO"
            sde_call_definition "set" "${flags}" "${etcdir}.${i}" "$@"
         done
         set +o noglob; IFS="${DEFAULT_IFS}"
         return
      ;;

      DEFAULT)
         etc_setup_from_share_if_needed "${etcdir}.${MULLE_UNAME}" "${sharedir}.${MULLE_UNAME}" "NO"
         sde_call_definition "set" "${flags}" "${etcdir}.${MULLE_UNAME}" "$@"
      ;;

      global)
         etc_setup_from_share_if_needed "${etcdir}" "${sharedir}" "NO"
         sde_call_definition "set" "${flags}" "${etcdir}" "$@"
      ;;

      *)
         etc_setup_from_share_if_needed "${etcdir}.${scope}" "${sharedir}.${scope}" "NO"
         sde_call_definition "set" "${flags}" "${etcdir}.${scope}" "$@"
      ;;
   esac
}



#
# remove is kind of tricky, since we may need to remove a value set by
# share, if this happens, we may need to create empty an empty etc
# with a key "INTENTIONALLY_LEFT_BLANK" so it doesn't get erased
#
sde_scoped_definition_remove()
{
   log_entry "sde_scoped_definition_remove" "$@"

   local flags="$1"
   local etcdir="$2"
   local sharedir="$3"

   shift 3

   local rval 

   if [ -d "${etcdir}" ]
   then
      sde_call_definition "remove" "${flags}" "${etcdir}" "$@"
      rval=$?
      etc_remove_if_possible "${etcdir}" "${sharedir}"
      return $rval
   fi

   # check if value exists in sharedir
   value="`sde_call_definition "get" "${flags}" "${sharedir}" "$@" `"
   if [ -z "${value}" ]
   then
      return 1
   fi        

   etc_setup_from_share_if_needed "${etcdir}" "${sharedir}" "NO"

   mkdir "${OPTION_ETC_DEFINITION_DIR}/keep"
   cat <<EOF  > "${OPTION_ETC_DEFINITION_DIR}/keep/README"
This file is here to protect this 'etc' definition folder from vanishing.

It was generated when you removed the \"$*\" definition, which was defined in
the 'share' folder. As 'etc' folders are reaped, when their contents are 
empty the 'keep' folder is required, to keep the \"$*\" definition 
(and possibly other defintitions) from mysteriously reappearing after an
upgrade.
EOF

   sde_call_definition "remove" "${flags}" "${etcdir}" "$@" # now we can remove
}


sde_definition_remove()
{
   log_entry "sde_definition_remove" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"

   shift 4

   case "${scope}" in
      ALL)
         sde_scoped_definition_remove "${flags}" \
                                      "${etcdir}" \
                                      "${sharedir}" \
                                      "$@"

         r_definition_scopes "no-global"
         scopes="${RVAL}"

         local i

         set -o noglob; IFS=$'\n'
         for i in ${scopes}
         do
            set +o noglob; IFS="${DEFAULT_IFS}"

            sde_scoped_definition_remove "${flags}" \
                                         "${etcdir}.${i}" \
                                         "${sharedir}.${i}" \
                                         "$@"
         done
         set +o noglob; IFS="${DEFAULT_IFS}"
         return
      ;;

      DEFAULT)
         if ! sde_scoped_definition_remove "${flags}" \
                                           "${etcdir}.${MULLE_UNAME}" \
                                           "${sharedir}.${MULLE_UNAME}" \
                                           "$@"
         then
            sde_scoped_definition_remove "${flags}" \
                                          "${etcdir}" \
                                          "${sharedir}" \
                                          "$@"
         fi
      ;; 

      global)
         sde_scoped_definition_remove "${flags}" \
                                      "${etcdir}"  \
                                      "${sharedir}" \
                                      "$@"
      ;;

      *)
         sde_scoped_definition_remove "${flags}" \
                                      "${etcdir}.${scope}" \
                                      "${sharedir}.${scope}" \
                                      "$@"
      ;;
   esac
}


sde_definition_list()
{
   log_entry "sde_definition_list" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   local directory
   local scopes 

   case "${scope}" in
      ALL)
         sde_definition_list_global  "${etcdir}" "${sharedir}" 

         r_definition_scopes "no-global"
         scopes="${RVAL}"

         local i

         set -o noglob; IFS=$'\n'
         for i in ${scopes}
         do
            set +o noglob; IFS="${DEFAULT_IFS}"
            sde_definition_list_scope "${etcdir}" "${sharedir}" "${i}"
         done
         set +o noglob; IFS="${DEFAULT_IFS}"
         return
         ;;

      DEFAULT)
         sde_definition_list_scope "${etcdir}" "${sharedir}" "${MULLE_UNAME}"
         sde_definition_list_global  "${etcdir}" "${sharedir}" 
         return
      ;;

      global)
         sde_definition_list_global  "${etcdir}" "${sharedir}" 
         return
      ;;

      *)
         sde_definition_list_scope "${etcdir}" "${sharedir}" "${scope}"
         r_pick_definition_dir "${etcdir}" "${sharedir}" ".${scope}"
         return
      ;;
   esac
}


sde_definition_main()
{
   log_entry "sde_definition_main" "$@"

   local OPTION_SHARE_DEFINITION_DIR=".mulle/share/craft/definition"
   local OPTION_ETC_DEFINITION_DIR=".mulle/etc/craft/definition"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || exit 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || exit 1
   fi
   if [ -z "${MULLE_ETC_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-etc.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-etc.sh" || exit 1
   fi

   local argument
   local flags
   local searchflags
   local terse="${MULLE_FLAG_LOG_TERSE}"
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

         --share-definition-dir)
            [ $# -eq 1 ] && sde_definition_usage "Missing argument to \"$1\""
            shift

            OPTION_SHARE_DEFINITION_DIR="$1"
         ;;

         --definition-dir|--etc-definition-dir)
            [ $# -eq 1 ] && sde_definition_usage "Missing argument to \"$1\""
            shift

            OPTION_ETC_DEFINITION_DIR="$1"
         ;;

         --global)
            r_concat "${searchflags}" "$1"
            scope="global"
            searchflags="${RVAL}"
         ;;

         --all)
            scope="ALL"
         ;;

         --platform|--os|--scope)
            [ $# -eq 1 ] && sde_definition_usage "Missing argument to \"$1\""
            shift

            scope="$1"
            r_concat "${searchflags}" "$1"
            searchflags="${RVAL}"
         ;;

         --terse)
            terse='YES'
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
         MULLE_FLAG_LOG_TERSE="${terse}" \
            rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                        search \
                           ${searchflags} \
                           "$@"
      ;;

      scopes)
         MULLE_FLAG_LOG_TERSE="${terse}" \
            sde_definition_scopes "$@"
      ;;


      get|keys|list|remove|set)
         MULLE_FLAG_LOG_TERSE="${terse}" \
            sde_definition_${cmd} "${scope}" \
                                  "${flags}" \
                                  "${OPTION_ETC_DEFINITION_DIR}" \
                                  "${OPTION_SHARE_DEFINITION_DIR}" \
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
