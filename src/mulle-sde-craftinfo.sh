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
MULLE_SDE_CRAFTINFO_SH="included"


DEPENDENCY_MARKS="dependency,delete"  # with delete we filter out subprojects
DEPENDENCY_LIST_MARKS="dependency"
DEPENDENCY_LIST_NODETYPES="no-none,no-local,ALL"


# this is a dependency subcommand

sde_dependency_craftinfo_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo [option] <command>

   Manage build settings of a dependency. Thy will be stored in a subproject
   in your project inside a mulle-sde created folder "craftinfo". This is done
   for you automatically on the first setting add.

   mulle-sde uses a "oneshot" extension mulle-sde/craftinfo to create that
   subproject.

   The dependency can be specified by URL or by its address.

EOF

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2
   Eventually the "craftinfo" contents are used by \`mulle-craft\` to populate
   the \`dependency/share/mulle-craft\` folder and override any \`.mulle-make\`
   folders. That's all fairly complicated, but it's necessary to have proper
   setting inheritance across multiple nested projects.

EOF
   else
      echo "   (use -v to see more help)"
   fi

      cat <<EOF >&2
Commands:
   get               : retrieve a build setting for dependency
   list              : list builds settings
   remove            : remove a build setting
   set               : set a build setting

Options:
   --global          : use global settings instead of current platform settings
   --platform <name> : specify settings for a specific platform

EOF
  exit 1
}


sde_dependency_craftinfo_set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo set [option] <dep> <key> <value>

   Set a setting value for key. This will automatically create a proper
   "craftinfo" subproject for you, if there is none yet.

   See \`mulle-make definition help\` for more info about manipulating
   craftinfo settings.

   Example:
      mulle-sde dependency craftinfo --global set --append nng CPPFLAGS "-DX=0"

Options:
   --append : value will be appended to CPPFLAGS

EOF
  exit 1
}


sde_dependency_craftinfo_get_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo get <dep> <key>

   Read setting of a key.

   Example:
      mulle-sde dependency craftinfo --global get nng CPPFLAGS

EOF
  exit 1
}



sde_dependency_craftinfo_remove_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo remove <dep> <key>

   Remove a setting by its key.

   Example:
      mulle-sde dependency craftinfo --global remove nng CPPFLAGS

EOF
  exit 1
}



sde_dependency_craftinfo_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo <dep>

   List build settings of a dependency. By default the global settings and
   those for the current platform are listed. To see other platform settings
   use the "--platform" option of \`dependency craftinfo\`.

EOF
  exit 1
}


copy_mulle_make_definitions()
{
   log_entry "copy_mulle_make_definitions" "$@"

   local name="$1"

   local srcdir

   srcdir="`sde_dependency_source_dir_main "${name}"`"
   if [ -z "${srcdir}" ]
   then
      log_warning "No source directory for \${name}\" found."
      return
   fi

   if [ ! -d "${srcdir}" ]
   then
      log_warning "Source directory not there yet, be careful not to \
clobber possibly existing .mulle-make definitions"
      return
   fi

   local i
   local RVAL
   local dstname

   shopt -s nullglob
   for i in "${srcdir}"/.mulle-make* 
   do
      if [ -d "${i}" ]
      then
         r_fast_basename "${i}"
         dstname="${RVAL:1}"

         exekutor cp -Ra "${i}" \
                         "${subprojectdir}/${dstname}"
      else
         log_warning "${i} exists but is not a directory ?"
      fi
   done
   shopt -u nullglob
}


sde_add_craftinfo_subproject_if_needed()
{
   log_entry "sde_add_craftinfo_subproject_if_needed" "$@"

   local subprojectdir="$1"
   local name="$2"
   local copy="$3"

   [ -z "${subprojectdir}" ] && internal_fail "empty subprojectdir"
   [ -z "${name}" ] && internal_fail "empty name"

   if [ -d "${subprojectdir}" ]
   then
      return 0
   fi

   # shellcheck source=src/mulle-sde-common.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh"

   (
      local ptype

      ptype="${PROJECT_TYPE}"
      if [ "${ptype}" = 'none' ]
      then
         ptype='empty'
      fi

      sde_extension_main pimp --project-type "${ptype}" \
                              --oneshot-name "${name}" \
                              mulle-sde/craftinfo
   ) || return 1

   [ -d "${subprojectdir}" ] || \
      internal_fail "did not produce \"${subprojectdir}\""

   if [ "${copy}" = 'YES' ]
   then
      copy_mulle_make_definitions "${name}"
   fi

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_SOURCETREE_FLAGS} \
               add \
                  --if-missing \
                  --marks "no-update,no-delete,no-share,no-header,no-link" \
                  --nodetype "local" \
                  "${subprojectdir}"  || return 1

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_SOURCETREE_FLAGS} \
               move \
                  "${subprojectdir}" \
                  top || return 1
}


#
# local _address
# local _name
# local _subprojectdir
# local _folder
#
__sde_craftinfo_vars_with_url_or_address()
{
   log_entry "__sde_craftinfo_vars_with_url_or_address" "$@"

   local url="$1"
   local extension="$2"

   _address="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                              -V \
                              ${MULLE_SOURCETREE_FLAGS} \
                           get \
                              --url-addressing \
                              "${url}"`"
   if [ -z "${_address}" ]
   then
      _address="${url}"
   fi

   [ -z "${_address}" ] && fail "Empty url or address"

   r_fast_basename "${_address}"
   _name="${RVAL}"
   _subprojectdir="craftinfo/${_name}"
   _folder="${_subprojectdir}/mulle-make${extension}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}"  = 'YES' ]
   then
      log_trace2 "_name:          ${_name}"
      log_trace2 "_address:       ${_address}"
      log_trace2 "_subprojectdir: ${_subprojectdir}"
      log_trace2 "_folder:        ${_folder}"
   fi
}


sde_dependency_craftinfo_set_main()
{
   log_entry "sde_dependency_craftinfo_set_main" "$@"

   local extension="$1"; shift

   local OPTION_COPY='YES'
   local OPTION_APPEND='NO'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_set_usage
         ;;

         --append|-a)
            OPTION_APPEND='YES'
         ;;

         --no-copy)
            OPTION_COPY='NO'
         ;;

         -*)
            sde_dependency_craftinfo_set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_dependency_craftinfo_set_usage "Missing url or address argument"

   local url="$1"
   shift

   [ "$#" -eq 0 ] && sde_dependency_craftinfo_set_usage "Missing key"
   [ "$#" -eq 1 ] && sde_dependency_craftinfo_set_usage "Missing value"
   [ "$#" -gt 2 ] && sde_dependency_craftinfo_set_usage "Superflous arguments \"$*\""

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=""
   fi

   local _address
   local _name
   local _subprojectdir
   local _folder

   __sde_craftinfo_vars_with_url_or_address "${url}" "${extension}"

   sde_add_craftinfo_subproject_if_needed "${_subprojectdir}" \
                                          "${_name}" \
                                          "${OPTION_COPY}" || exit 1

   local setflags

   if [ "${OPTION_APPEND}" = 'YES' ]
   then
      setflags="-+"
   fi

   exekutor "${MULLE_MAKE}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_MAKE_FLAGS} \
               definition \
                  --definition-dir "${_folder}" \
                  set \
                  ${setflags} \
                  "$@"

}


sde_dependency_craftinfo_get_main()
{
   log_entry "sde_dependency_craftinfo_list_main" "$@"

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_get_usage
         ;;


         -*)
            sde_dependency_craftinfo_get_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_dependency_craftinfo_get_usage "Missing url or address argument"

   local url="$1"
   shift

   [ $# -eq 0 ] && sde_dependency_craftinfo_get_usage "Missing key"

   local _address
   local _name
   local _subprojectdir
   local _folder
   local rval

   if [ "${extension}" = "DEFAULT" ]
   then
      __sde_craftinfo_vars_with_url_or_address "${url}" ""
      exekutor "${MULLE_MAKE}" \
                    ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_MAKE_FLAGS} \
                  definition \
                     --definition-dir "${_folder}.${MULLE_UNAME}" \
                     get \
                     "$@"
      rval=$?
      if [ $rval -ne 2 ]
      then
         return $rval
      fi

      exekutor "${MULLE_MAKE}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_MAKE_FLAGS} \
                  definition \
                     --definition-dir \
                        "${_folder}" \
                        get \
                        "$@"
      return $?
   fi

   __sde_craftinfo_vars_with_url_or_address "${url}" "${extension}"

   exekutor "${MULLE_MAKE}"  \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_MAKE_FLAGS} \
               definition \
                  --definition-dir "${_folder}" \
                  get \
                  "$@"
}


sde_dependency_craftinfo_list_main()
{
   log_entry "sde_dependency_craftinfo_list_main" "$@"

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_list_usage
         ;;

         -*)
            sde_dependency_craftinfo_list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && \
      sde_dependency_craftinfo_list_usage "Missing url or address argument"

   local url="$1"
   shift

   local _address
   local _name
   local _subprojectdir
   local _folder

   if [ "${extension}" = "DEFAULT" ]
   then
      __sde_craftinfo_vars_with_url_or_address "${url}" ""
      log_info "Global"
      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
         definition --definition-dir "${_folder}" list "$@"
      log_info "${MULLE_UNAME}"
      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
         definition --definition-dir "${_folder}.${MULLE_UNAME}" list "$@"
      return
   fi

   __sde_craftinfo_vars_with_url_or_address "${url}" "${extension}"

   log_info "${extension:-Global}"
   exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} ${MULLE_MAKE_FLAGS} \
      definition --definition-dir "${_folder}" list "$@"
}


sde_dependency_craftinfo_main()
{
   log_entry "sde_dependency_craftinfo_main" "$@"

   local extension

   extension="DEFAULT"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_dependency_craftinfo_usage
         ;;

         --global)
            extension=""
         ;;

         --platform)
            [ "$#" -eq 1 ] && \
               sde_dependency_craftinfo_usage "Missing argument to \"$1\""
            shift

            extension=".$1"
         ;;

         -*)
            sde_dependency_craftinfo_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && \
      sde_dependency_craftinfo_usage "Missing dependency craftinfo command"

   local subcmd="$1"
   shift

   if [ -z "${MULLE_MAKE}" ]
   then
      MULLE_MAKE="${MULLE_MAKE:-`command -v mulle-make`}"
      [ -z "${MULLE_MAKE}" ] && fail "mulle-make not in PATH"
   fi

   case "${subcmd:-list}" in
      set|get|list)
         sde_dependency_craftinfo_${subcmd}_main "${extension}" "$@"
      ;;

      *)
        sde_dependency_craftinfo_usage "Unknown dependency craftinfo \
command \"${subcmd}\""
      ;;
   esac
}
