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
MULLE_SDE_DEFINITION_SH='included'


sde::definition::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} definition [options] [command]

   This command manipulates mulle-make definitions for a project. A common
   definition is CC to specify the compiler to use (e.g. mulle-clang).
   Definitions can be platform-specific, e.g. only valid for builds
   targetting linux. A commonly manipulated definition setting is \"CFLAGS\".

   Definitions set by extensions are stored in .mulle/share/craft. Your
   custom settings in .mulle/etc/craft will override them. Note that for
   each platform, there can be a definition.

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
   cat    : show definition file contents, similiar to list
   get    : get value of a definition
   keys   : get a list of known keys, unknown keys are possible too
   list   : list current definitions
   unset  : unset a definition
   search : locate definition directories
   remove : completely remove all definitions for a specific scope
   set    : change a definition

EOF
   exit 1
}


sde::definition::r_pick_dir()
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


sde::definition::r_scopes()
{
   log_entry "sde::definition::r_scopes" "$@"

   local etcdir="$1"
   local sharedir="$2"
   local option="$3"

   local i
   local scopes 

   scopes=""
   shell_enable_nullglob
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
   shell_disable_nullglob

   RVAL="${scopes}"
}


sde::definition::scopes()
{
   log_entry "sde::definition::scopes" "$@"

   log_info "Defined Definition Scopes"

   sde::definition::r_scopes

   if [ ! -z "${RVAL}" ]
   then
      printf "%s\n" "${RVAL}" | sed 's/^/   /'
   fi
}


sde::definition::call()
{
   log_entry "sde::definition::call" "$@"

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


sde::definition::call_if_dir_exists()
{
   log_entry "sde::definition::call_if_dir_exists" "$@"

   if [ ! -d "$3" ]
   then
      return 2
   fi
   sde::definition::call "$@"
}



sde::definition::_keys()
{
   log_entry "sde::definition::_keys" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   case "${scope}" in 
      "ALL")
         _internal_fail "keys can not use --all"
      ;;

      "DEFAULT")
         if ! sde::definition::call_if_dir_exists "keys" "${flags}" "${etcdir}.${MULLE_UNAME}"
         then
            if sde::definition::call_if_dir_exists "keys" "${flags}" "${sharedir}.${MULLE_UNAME}"
            then
               return
            fi
         fi
      ;;
   esac 
   
   case "${scope}" in 
      DEFAULT|global)
         if ! sde::definition::call_if_dir_exists "keys" "${flags}" "${etcdir}"
         then
            sde::definition::call_if_dir_exists "keys" "${flags}" "${sharedir}"
            return $?
         fi
         return 0
      ;;
   esac

   if ! sde::definition::call_if_dir_exists "keys" "${flags}" "${etcdir}.${scope}"
   then
      if sde::definition::call_if_dir_exists "keys" "${flags}" "${sharedir}.${scope}"
      then
         return
      fi
   fi
}


sde::definition::keys()
{
   log_entry "sde::definition::keys" "$@"

   sde::definition::_keys "$@" | sort -u
}


sde::definition::get()
{
   log_entry "sde::definition::get" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   local directory

   case "${scope}" in
      ALL)
         sde::definition::r_pick_dir "${etcdir}" "${sharedir}"
         directory="${RVAL}"
         sde::definition::call "get" "${flags}" "${directory}" "$@"

         sde::definition::r_scopes "no-global"
         scopes="${RVAL}"

         local i

         .foreachline i in ${scopes}
         .do
            sde::definition::r_pick_dir "${etcdir}" "${sharedir}" ".${scope}"
            directory="${RVAL}"

            sde::definition::call "get" "${flags}" "${directory}" "$@"
         .done   
         return
         ;;

      DEFAULT)
         sde::definition::r_pick_dir "${etcdir}" "${sharedir}" ".${MULLE_UNAME}"
         directory="${RVAL}"
         if sde::definition::call "get" "${flags}" "${directory}" "$@"
         then
            return
         fi
         sde::definition::r_pick_dir "${etcdir}" "${sharedir}"
         directory="${RVAL}"
      ;;

      global)
         sde::definition::r_pick_dir "${etcdir}" "${sharedir}"
         directory="${RVAL}"
      ;;

      *)
         sde::definition::r_pick_dir "${etcdir}" "${sharedir}" ".${scope}"
         directory="${RVAL}"
      ;;
   esac

   sde::definition::call "get" "${flags}" "${directory}" "$@"
}



#
# We don't symlink the definitions, as they are usually small. We could
# though.
#
sde::definition::set()
{
   log_entry "sde::definition::set" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   local additive="$5"

   shift 5

   local scopes 
   local cmd

   if [ "${additive}" = 'YES' ]
   then
      additivemode="-+"
   else
      additivemode="--non-additive"
   fi

   case "${scope}" in
      ALL)
         etc_setup_from_share_if_needed "${etcdir}" "${sharedir}" 'NO'
         sde::definition::call 'set' "${additivemode}" "${flags}" "${etcdir}" "$@"

         sde::definition::r_scopes "no-global"
         scopes="${RVAL}"

         local i

         .foreachline i in ${scopes}
         .do
            etc_setup_from_share_if_needed "${etcdir}.${i}" "${sharedir}.${i}" 'NO'
            sde::definition::call 'set' "${additivemode}" "${flags}" "${etcdir}.${i}" "$@"
         .done   
         return
      ;;

      DEFAULT)
         etc_setup_from_share_if_needed "${etcdir}.${MULLE_UNAME}" "${sharedir}.${MULLE_UNAME}" 'NO'
         sde::definition::call 'set' "${additivemode}" "${flags}" "${etcdir}.${MULLE_UNAME}" "$@"
      ;;

      global)
         etc_setup_from_share_if_needed "${etcdir}" "${sharedir}" 'NO'
         sde::definition::call 'set' "${additivemode}" "${flags}" "${etcdir}" "$@"
      ;;

      *)
         etc_setup_from_share_if_needed "${etcdir}.${scope}" "${sharedir}.${scope}" 'NO'
         sde::definition::call 'set' "${additivemode}" "${flags}" "${etcdir}.${scope}" "$@"
      ;;
   esac
}


#
# unset is kind of tricky, since we may need to unset a value set by
# share, if this happens, we may need to create an empty etc
# with a key "INTENTIONALLY_LEFT_BLANK" so it doesn't get erased
#
sde::definition::scoped_unset()
{
   log_entry "sde::definition::scoped_unset" "$@"

   local flags="$1"
   local etcdir="$2"
   local sharedir="$3"

   shift 3

   local rval 

   if [ -d "${etcdir}" ]
   then
      sde::definition::call "unset" "${flags}" "${etcdir}" "$@"
      rval=$?
      etc_remove_if_possible "${etcdir}" "${sharedir}"
      return $rval
   fi

   # check if value exists in sharedir
   value="`sde::definition::call "get" "${flags}" "${sharedir}" "$@" `"
   if [ -z "${value}" ]
   then
      return 1
   fi        

   etc_setup_from_share_if_needed "${etcdir}" "${sharedir}" 'NO'

   mkdir "${OPTION_ETC_DEFINITION_DIR}/keep"
   cat <<EOF  > "${OPTION_ETC_DEFINITION_DIR}/keep/README"
This file is here to protect this 'etc' definition folder from vanishing.

It was generated when you removed the \"$*\" definition, which was defined in
the 'share' folder. As 'etc' folders are reaped, when their contents are 
empty the 'keep' folder is required, to keep the \"$*\" definition 
(and possibly other defintitions) from mysteriously reappearing after an
upgrade.
EOF

   sde::definition::call "unset" "${flags}" "${etcdir}" "$@" # now we can unset
}


sde::definition::unset()
{
   log_entry "sde::definition::unset" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"

   shift 4

   case "${scope}" in
      ALL)
         sde::definition::scoped_unset "${flags}" \
                                     "${etcdir}" \
                                     "${sharedir}" \
                                     "$@"

         sde::definition::r_scopes "no-global"
         scopes="${RVAL}"

         local i

         .foreachline i in ${scopes}
         .do
            sde::definition::scoped_unset "${flags}" \
                                        "${etcdir}.${i}" \
                                        "${sharedir}.${i}" \
                                        "$@"
         .done         
         return
      ;;

      DEFAULT)
         if ! sde::definition::scoped_unset "${flags}" \
                                          "${etcdir}.${MULLE_UNAME}" \
                                          "${sharedir}.${MULLE_UNAME}" \
                                          "$@"
         then
            sde::definition::scoped_unset "${flags}" \
                                        "${etcdir}" \
                                        "${sharedir}" \
                                        "$@"
         fi
      ;; 

      global)
         sde::definition::scoped_unset "${flags}" \
                                     "${etcdir}"  \
                                     "${sharedir}" \
                                     "$@"
      ;;

      *)
         sde::definition::scoped_unset "${flags}" \
                                     "${etcdir}.${scope}" \
                                     "${sharedir}.${scope}" \
                                     "$@"
      ;;
   esac
}


sde::definition::remove()
{
   log_entry "sde::definition::remove" "$@"

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   local suffix

   case "${scope}" in 
      ALL)
         fail "Removing all is not possible"
      ;;

      DEFAULT)
         suffix="${1:-${scope}}"
      ;;

      *)
         suffix="${scope}"
      ;;
   esac

   if [ ! -z "${suffix}" ]
   then
      suffix=".${suffix}"
   fi

   local directory

   directory="${etcdir}${suffix}"

   log_debug "directory: ${directory}"

   if [ ! -z "${etcdir}" -a -e "${directory}" ]
   then
      rmdir_safer "${directory}"
      return $?
   fi

   if [ ! -z "${sharedir}" -a -e "${sharedir}${suffix}" ]
   then
      mkdir_if_missing "${directory}"
      redirect_exekutor "${directory}/README.md" cat <<EOF
Empty directory supersedes \"share\" definitions.
EOF
      return 0
   fi

   log_info "Nothing found to remove"
}


sde::definition::cmd_scope()
{
   log_entry "sde::definition::cmd_scope" "$@"

   local cmd="$1"
   shift 1

   local etcdir="$1"
   local sharedir="$2"
   local scope="$3"
   shift 3

   local directory

   sde::definition::r_pick_dir "${etcdir}" "${sharedir}" ".${scope}"
   directory="${RVAL}"

   if [ -d "${directory}" ]
   then
      log_info "${scope}"
      sde::definition::call "${cmd}" "${flags}" "${directory}" "$@" \
      | sed 's/^/   /'
   fi
}


sde::definition::cmd_global()
{
   log_entry "sde::definition::cmd_global" "$@"

   local cmd="$1"
   shift 1

   local etcdir="$1"
   local sharedir="$2"
   shift 2

   local directory

   sde::definition::r_pick_dir "${etcdir}" "${sharedir}"
   directory="${RVAL}"

   log_info "global"
   sde::definition::call "${cmd}" "${flags}" "${directory}" "$@" \
   | sed 's/^/   /'
}


sde::definition::_cmd()
{
   log_entry "sde::definition::_cmd" "$@"

   local cmd="$1"
   shift 1

   local scope="$1"
   local flags="$2"
   local etcdir="$3"
   local sharedir="$4"
   shift 4

   local directory
   local scopes 

   case "${scope}" in
      ALL)
         sde::definition::cmd_global "${cmd}" "${etcdir}" "${sharedir}"

         sde::definition::r_scopes "no-global"
         scopes="${RVAL}"

         local i

         .foreachline i in ${scopes}
         .do
            sde::definition::cmd_scope "${cmd}" "${etcdir}" "${sharedir}" "${i}"
         .done
         return
         ;;

      DEFAULT)
         sde::definition::cmd_scope "${cmd}" "${etcdir}" "${sharedir}" "${MULLE_UNAME}"
         sde::definition::cmd_global "${cmd}" "${etcdir}" "${sharedir}"
         return
      ;;

      global)
         sde::definition::cmd_global "${cmd}" "${etcdir}" "${sharedir}"
         return
      ;;

      *)
         sde::definition::cmd_scope "${cmd}" "${etcdir}" "${sharedir}" "${scope}"
         sde::definition::r_pick_dir "${etcdir}" "${sharedir}" ".${scope}"
         return
      ;;
   esac
}


sde::definition::list()
{
   log_entry "sde::definition::list" "$@"

   sde::definition::_cmd "list" "$@"
}


sde::definition::cat()
{
   log_entry "sde::definition::cat" "$@"

   sde::definition::_cmd "cat" "$@"
}


sde::definition::main()
{
   log_entry "sde::definition::main" "$@"

   local OPTION_SHARE_DEFINITION_DIR=".mulle/share/craft/definition"
   local OPTION_ETC_DEFINITION_DIR=".mulle/etc/craft/definition"

   include "path"
   include "file"
   include "etc"

   local argument
   local flags
   local searchflags
   local terse="${MULLE_FLAG_LOG_TERSE}"
   local scope="DEFAULT"
   local OPTION_ADDITIVE='YES'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::definition::usage
         ;;

         --allow-unknown-option|--no-allow-unknown-option)
            r_concat "${flags}" "$1"
            flags="${RVAL}"
         ;;

         --share-definition-dir)
            [ $# -eq 1 ] && sde::definition::usage "Missing argument to \"$1\""
            shift

            OPTION_SHARE_DEFINITION_DIR="$1"
         ;;

         --definition-dir|--etc-definition-dir)
            [ $# -eq 1 ] && sde::definition::usage "Missing argument to \"$1\""
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
            [ $# -eq 1 ] && sde::definition::usage "Missing argument to \"$1\""
            shift

            scope="$1"
            r_concat "${searchflags}" "$1"
            searchflags="${RVAL}"
         ;;

         -+|--additive)
            OPTION_ADDITIVE='YES'
         ;;

         --non-additive)
            OPTION_ADDITIVE='NO'
         ;;

         --terse)
            terse='YES'
         ;;

         -*)
            sde::definition::usage "Unknown definition option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

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
            sde::definition::scopes "$@"
      ;;

     set)
         MULLE_FLAG_LOG_TERSE="${terse}" \
            sde::definition::set "${scope}" \
                                 "${flags}" \
                                 "${OPTION_ETC_DEFINITION_DIR}" \
                                 "${OPTION_SHARE_DEFINITION_DIR}" \
                                 "${OPTION_ADDITIVE}" \
                                 "$@"
      ;;


      cat|get|keys|list|remove|set|unset)
         MULLE_FLAG_LOG_TERSE="${terse}" \
            sde::definition::${cmd} "${scope}" \
                                    "${flags}" \
                                    "${OPTION_ETC_DEFINITION_DIR}" \
                                    "${OPTION_SHARE_DEFINITION_DIR}" \
                                    "$@"
      ;;

      '')
         sde::definition::usage
      ;;

      *)
         sde::definition::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
