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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_INIT_SH="included"


sde_init_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} init [options] <type>

   Create a mulle-sde project, which can be either an executable or a
   library. Check `mulle-sde extensions` for available options.
   It is possible to prefix the vendor to buildtool, common, runtime.

   e.g.  mulle-sde init -r c -b mulle:cmake exectuable

Options:
   -b <buildtool> : specify the buildtool extension to use (<vendor>:cmake)
    -c <common>   : specify the common extensions to install (<vendor:common)
   -d <dir>       : directory to populate (working directory)
   -e <extra>     : specify extra extensions. Multiple -e <extra> are possible
   -r <runtime>   : specify runtime extension to use (<vendor:c)
   -v <vendor>    : extension vendor to use (builtin)

Types:
   executable     : create an executable project
   library        : create a library project
   empty          : don't create a project (just an environment)
EOF
   exit 1
}


_copy_extension_dirs()
{
   log_entry "_copy_extension_dirs" "$@"

   local extensiondir="$1"

   [ -z "${extensiondir}" ] && internal_fail "extensiondir is empty"

   (
      shopt -s nullglob

      local flags
      local directory

      if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
      then
         flags=-v
      fi

      for directory in "${extensiondir}/bin" \
                       "${extensiondir}/libexec" \
                       "${extensiondir}/lib" \
                       "${extensiondir}/share"
      do
         if [ -d "${directory}" ]
         then
            log_fluff "Installing from \"${directory}\""

            exekutor cp -Ra ${flags} "${directory}" ".mulle-sde/"
         fi
      done
   )
}


_append_to_motd()
{
   log_entry "_append_to_motd" "$@"

   local extensiondir="$1"

   local text

   if [ -f "${extensiondir}/motd" ]
   then
      text="`egrep -v '^#' "${extensiondir}/motd" `"
      if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
      then
         _MOTD="`add_line "${_MOTD}" "${text}" `"
      fi
   fi
}


_copy_extension_project_files()
{
   log_entry "_copy_extension_project_files" "$@"

   local extensiondir="$1"; shift
   local projecttype="$1"; shift

   local projectdir

   projectdir="${extensiondir}/project/${projecttype}"
   #
   # copy and expand stuff from project folder
   #
   if [ -d "${projectdir}" ]
   then
      if [ -z "${MULLE_SDE_INITSUPPORT_SH}" ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-template.sh" || internal_fail "include fail"
      fi
      _template_main --embedded --template-dir "${projectdir}" || exit 1
   else
      log_fluff "No project files to copy, as \"${projectdir}\" is not there ($PWD)"
   fi
}


_run_extension_init()
{
   log_entry "_run_extension_init" "$@"

   local extensiondir="$1"; shift
   local projecttype="$1" ; shift

   if [ -x "${extensiondir}/init" ]
   then
      eval_exekutor "${extensiondir}/init" "${projecttype}" "$@" || exit 1
   fi
}


install_dependency_extension()
{
   log_entry "install_dependency_extension" "$@"

   local projecttype="$1"
   local exttype="$2"
   local dependency="$3"

   local extname
   local vendor

   vendor="`cut -s -d':' -f1 <<< "${dependency}" `"
   extname="`cut -s -d':' -f2 <<< "${dependency}" `"

   install_extension "${projecttype}" "${exttype}" "${extname}" "${vendor}"
}


install_extension()
{
   log_entry "install_extension" "$@"

   local projecttype="$1"; shift
   local exttype="$1"; shift
   local extname="$1"; shift
   local vendor="$1"; shift

   # user can turn off extensions by passing ""
   if [ -z "${extname}" ]
   then
      return
   fi

   local extensiondir

   if ! extensiondir="`find_extension "${extname}" "${vendor}"`"
   then
      log_error "Could not find extension \"${extname}\" from vendor \"${vendor}\""
      return 1
   fi

   case "${exttype}" in
      buildtool)
         # need at least an empty directory there to "show support"
         if [ ! -d "${extensiondir}/project/${projecttype}" ]
         then
            log_error "Extension \"${vendor}:${extname}\" does not support projecttype \"${projecttype}\""
            return 1
         fi
      ;;
   esac

   local dependency

   dependency="`egrep -v '^#' "${extensiondir}/dependency" 2> /dev/null`"
   if [ ! -z "${dependency}" ]
   then
      log_fluff "Found dependency \"${dependency}\""

      install_dependency_extension "${projecttype}" "${exttype}" "${dependency}"
   else
      log_fluff "No dependency found in \"${extensiondir}/dependency"
   fi
   log_fluff "Install ${exttype} extension \"${vendor}:${extname}\""

   _copy_extension_dirs "${extensiondir}"
   _copy_extension_project_files "${extensiondir}" "${projecttype}"
   _run_extension_init "${extensiondir}" "${projecttype}" "$@"
   _append_to_motd "${extensiondir}"
}


install_motd()
{
   log_entry "install_motd" "$@"

   local text="$1"
   local motdfile=".mulle-env/motd"

   if [ -f "${motdfile}" -a "${FLAG_FORCE}" != "YES" ]
   then
      return
   fi

   if [ -z "${text}" ]
   then
      remove_file_if_present "$motdfile"
      return
   fi

   mkdir_if_missing ".mulle-env"
   redirect_exekutor ".mulle-env/motd" echo "${text}"
}


fix_permissions()
{
   log_entry "fix_permissions" "$@"

   (
      shopt -s nullglob

      chmod +x .mulle-sde/bin/* 2> /dev/null
      chmod +x .mulle-sde/libexec/* 2> /dev/null
   )
}


install_project()
{
   log_entry "install_project" "$@"

   local projecttype="$1"

   local common_vendor
   local runtime_vendor
   local buildtool_vendor
   local common_name
   local runtime_name
   local buildtool_name

   if [ ! -z "${OPTION_COMMON}" ]
   then
      common_name="` cut -s -d':' -f2 <<< "${OPTION_COMMON}" `"
      if [ -z "${common_name}" ]
      then
         common_vendor="${OPTION_VENDOR}"
         common_name="${OPTION_COMMON}"
      else
         common_vendor="`cut -s -d':' -f1 <<< "${OPTION_COMMON}" `"
      fi
   fi

   if [ ! -z "${OPTION_RUNTIME}" ]
   then
      runtime_name="` cut -s -d':' -f2 <<< "${OPTION_RUNTIME}" `"
      if [ -z "${runtime_name}" ]
      then
         runtime_vendor="${OPTION_VENDOR}"
         runtime_name="${OPTION_RUNTIME}"
      else
         runtime_vendor="`cut -s -d':' -f1 <<< "${OPTION_RUNTIME}" `"
      fi
   fi

   if [ ! -z "${OPTION_BUILDTOOL}" ]
   then
      buildtool_name="` cut -s -d':' -f2 <<< "${OPTION_BUILDTOOL}" `"
      if [ -z "${buildtool_name}" ]
      then
         buildtool_vendor="${OPTION_VENDOR}"
         buildtool_name="${OPTION_BUILDTOOL}"
      else
         buildtool_vendor="`cut -s -d':' -f1 <<< "${OPTION_BUILDTOOL}" `"
      fi
   fi

   local _MOTD

   _MOTD=""

   #
   # buildtool is the most likely to fail, due to a mistyped
   # projectdir, if that happens, we have done the least pollution yet
   #
   (
      install_extension "${projecttype}" "buildtool" "${buildtool_name}" "${buildtool_vendor}" \
                        -p "${OPTION_NAME}" &&
      install_extension "${projecttype}" "runtime" "${runtime_name}" "${runtime_vendor}" \
                        -p "${OPTION_NAME}" &&
      install_extension "${projecttype}" "common" "${common_name}" "${common_vendor}" \
                        -p "${OPTION_NAME}"
   ) || return 1

   #
   # optionally install "extra" extensions
   # f.e. a "git" extension could auto-init the project and create
   # a .gitignore file
   #
   # Extra extensions must be fully qualified.
   #
   local extra
   local extra_vendor
   local extra_name

   IFS="
"
   for extra in ${OPTION_EXTRAS}
   do
      IFS="${DEFAULT_IFS}"
      if [ ! -z "${extra}" ]
      then
         extra_vendor="`cut -s -d':' -f1 <<< "${extra}" `"
         extra_name="` cut -s -d':' -f2 <<< "${extra}" `"

         install_extension "extra" "${extra_name}" "${extra_vendor}" \
                        -p "${OPTION_NAME}" "${projecttype}"
      fi
   done

   IFS="${DEFAULT_IFS}"

   fix_permissions

   if [ ! -z "${_MOTD}" ]
   then
      _MOTD="
"
   fi

   local motd

   motd="`printf "%b" "${C_INFO}Ready to build with:${C_RESET}${C_BOLD}
   mulle-sde craft${C_RESET}" `"

   _MOTD="${_MOTD}${motd}"

   install_motd "${_MOTD}"
}


###
### parameters and environment variables
###
sde_init_main()
{
   log_entry "sde_init_main" "$@"

   local OPTION_NAME
   local OPTION_EXTRAS
   local OPTION_COMMON="common"
   local OPTION_RUNTIME="c"
   local OPTION_BUILDTOOL="cmake"
   local OPTION_VENDOR="builtin"
   local OPTION_INIT_ENV="YES"
   local OPTION_ENV_STYLE="mulle:restricted"
   local OPTION_BLURB=""

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_init_usage
         ;;

         -p|--project-name)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_NAME="$1"
         ;;

         -b|--buildtool)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_BUILDTOOL="`tr 'A-Z' 'a-z' <<< "$1" `"
         ;;

         -c|--common)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_COMMON="`tr 'A-Z' 'a-z' <<< "$1" `"
         ;;


         -e|--extra)
            [ $# -eq 1 ] && sde_init_usage
            shift

            local extra

            extra="`tr 'A-Z' 'a-z' <<< "$1" `"
            OPTION_EXTRAS="`add_line "${OPTION_EXTRAS}" "${extra}" `"
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_init_usage
            shift

            exekutor mkdir -p "$1" 2> /dev/null
            exekutor cd "$1" || fail "can't change to \"$1\""
         ;;

         -r|--runtime)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_RUNTIME="`tr 'A-Z' 'a-z' <<< "$1" `"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_VENDOR="$1"
         ;;

         --no-blurb)
            OPTION_BLURB="--no-blurb"
         ;;

         --no-env)
            OPTION_INIT_ENV="NO"
         ;;

         --style|--env-style)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_ENV_STYLE="$1"
         ;;

         -*)
            sde_init_usage
            ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_SDE_EXTENSIONS_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extensions.sh" || exit 1
   fi

   #
   # make nicer in the future for now just hax
   #
   [ "$#" -ne 1 ] && log_error "missing or extraneous type" && sde_init_usage

   local projecttype

   projecttype="$1"

   if [ "${OPTION_INIT_ENV}" = "YES" ]
   then
      export MULLE_EXECUTABLE_NAME
      exekutor mulle-env ${MULLE_ENV_FLAGS} init ${OPTION_BLURB} --style "${OPTION_ENV_STYLE}"
      case $? in
         0|2)
         ;;

         *)
            exit 1
         ;;
      esac
   fi

   mkdir_if_missing ".mulle-sde" || exit 1

   case "${projecttype}" in
      empty)
         return
      ;;

      *)
         if ! install_project "${projecttype}"
         then
            rmdir_safer ".mulle-sde"
            rmdir_safer ".mulle-env"
            exit 1
         fi
      ;;
   esac
}
