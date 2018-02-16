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
   if [ "$#" -ne 0 ]
   then
      log_error "$1"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} init [options] <type>

   Create a mulle-sde project, which can be either an executable or a
   library. Check \`mulle-sde extensions\` for available options.

   e.g.  mulle-sde init -r builtin:c -b mulle:cmake executable

Options:
   -b <buildtool> : specify the buildtool extension to use (<vendor>:cmake)
   -c <common>    : specify the common extensions to install (<vendor:sde)
   -d <dir>       : directory to populate (working directory)
   -e <extra>     : specify extra extensions. Multiple -e <extra> are possible
   -n             : do not install files into project template files
   -p <name>      : project name
   -r <runtime>   : specify runtime extension to use (<vendor>:c)
   -v <vendor>    : extension vendor to use (builtin)

Types:
   executable     : create an executable project
   library        : create a library project
   empty          : does not produce project files
EOF
   exit 1
}


_copy_extension_dir()
{
   log_entry "_copy_extension_dir" "$@"

   local directory="$1"
   local force="$2"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      flags=-v
   fi

   # remove old stuff with possibly outdated files
   if [ "${force}" != "YES" ]
   then
      flags="${flags} -n"  # don't clobber
   fi

   if [ -d "${directory}" ]
   then
      log_fluff "Installing from \"${directory}\""

      exekutor cp -Ra ${flags} "${directory}" ".mulle-sde/"
   fi
}


_append_to_motd()
{
   log_entry "_append_to_motd" "$@"

   local extensiondir="$1"

   local text

   if [ -f "${extensiondir}/motd" ]
   then
      text="`LC_ALL=C egrep -v '^#' "${extensiondir}/motd" `"
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
   local force="$1"; shift

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

      if [ "${force}" = "YES" ]
      then
         force="-f"
      else
         force=""
      fi

      _template_main --embedded ${force} --template-dir "${projectdir}" "$@" || exit 1
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
      log_fluff "Running init script \"${extensiondir}/init\""
      eval_exekutor "${extensiondir}/init" "${projecttype}" "$@" || \
         fail "init script \"${extensiondir}/init\" failed"
   else
      log_fluff "No init script \"${extensiondir}/init\" found"
   fi
}


install_dependency_extension()
{
   log_entry "install_dependency_extension" "$@"

   local projecttype="$1"; shift
   local exttype="$1"; shift
   local dependency="$1"; shift
   local marks="$1"; shift

   local parent
   local addmarks
   local extname
   local vendor

   parent="`cut -d';' -f1 <<< "${dependency}" `"
   addmarks="`cut -s -d';' -f2 <<< "${dependency}" `"

   vendor="`cut -s -d':' -f1 <<< "${parent}" `"
   extname="`cut -d':' -f2 <<< "${parent}" `"

   marks="`comma_concat "${marks}" "${addmarks}"`"

   install_extension "${projecttype}" \
                     "${exttype}" \
                     "${extname}" \
                     "${vendor:-builtin}" \
                     "${marks}" \
                     "$@"
}


install_dependencies()
{
   log_entry "install_dependencies" "$@"

   local dependencies="$1" ; shift
   local projecttype="$1" ; shift
   local defaultexttype="$1" ; shift
   local marks="$1" ; shift

   local dependency
   local exttype

   IFS=";"
   while read dependency exttype
   do
      IFS="${DEFAULT_IFS}"
      if [ -z "${dependency}" ]
      then
         continue
      fi

      install_dependency_extension "${projecttype}" \
                                   "${exttype:-${defaultexttype}}" \
                                   "${dependency}" \
                                   "${marks}" \
                                   "$@"
   done < <( "`LC_ALL=C egrep -v '^#' "${dependencies}" 2> /dev/null`")
   IFS="${DEFAULT_IFS}"
}


install_extension()
{
   log_entry "install_extension" "$@"

   local projecttype="$1"; shift
   local exttype="$1"; shift
   local extname="$1"; shift
   local vendor="$1"; shift
   local marks="$1"; shift
   local force="$1"; shift

   # user can turn off extensions by passing ""
   if [ -z "${extname}" ]
   then
      return
   fi

   local extensiondir

   if ! extensiondir="`find_extension "${extname}" "${vendor}"`"
   then
      log_error "Could not find extension \"${extname}\" from \
vendor \"${vendor}\""
      return 1
   fi

   case "${exttype}" in
      buildtool)
         # need at least an empty directory there to "show support"
         if [ ! -d "${extensiondir}/project/${projecttype}" ]
         then
            log_error "Extension \"${vendor}:${extname}\" does not support \
projecttype \"${projecttype}\""
            return 1
         fi
      ;;
   esac

   case "${marks}" in
      *no-dependency*|*no-${exttype}-dependency*)
         log_fluff "${vendor}:${extname}: ignoring \
 \"${extensiondir}/dependency\" due to no-dependency mark"
      ;;

      *)
         if [ -f "${extensiondir}/dependencies" ]
         then
            install_dependencies "${extensiondir}/dependencies" \
                                 "${projecttype}" \
                                 "${exttype}" \
                                 "${marks}" \
                                 "$@"
         fi
      ;;
   esac

   log_verbose "Installing ${exttype} extension \"${vendor}:${extname}\""

   #
   # copy bin, etc, share, libexec
   #
   case "${marks}" in
      *no-bin*|*no-${exttype}-bin*)
         log_fluff "${vendor}:${extname}: ignoring .mulle-sde/bin directories \
due to marks"
      ;;

      *)
         _copy_extension_dir "${extensiondir}/bin" "${force}"
      ;;
   esac

   case "${marks}" in
      *no-share*|*no-${exttype}-share*)
         log_fluff "${vendor}:${extname}: ignoring .mulle-sde/share directories \
due to marks"
      ;;

      *)
         _copy_extension_dir "${extensiondir}/share" "${force}"
      ;;
   esac

   case "${marks}" in
      *no-etc*|*no-${exttype}-etc*)
         log_fluff "${vendor}:${extname}: ignoring .mulle-sde/etc directories \
due to marks"
      ;;

      *)
         _copy_extension_dir "${extensiondir}/etc" # never force this
      ;;
   esac

   case "${marks}" in
      *no-libexec*|*no-${exttype}-libexec*)
         log_fluff "${vendor}:${extname}: ignoring .mulle-sde/libexec directories \
due to marks"
      ;;

      *)
         _copy_extension_dir "${extensiondir}/libexec" "${force}"
      ;;
   esac

   # project and other custom stuff
   case "${marks}" in
      *no-project*|*no-${exttype}-project*)
         log_fluff "${vendor}:${extname}: ignoring any project files due to marks"
      ;;

      *)
         _copy_extension_project_files "${extensiondir}" \
                                       "${projecttype}" \
                                       "${force}" \
                                       "$@"
      ;;
   esac

   case "${marks}" in
      *no-init*|*no-${exttype}-init*)
         log_fluff "${vendor}:${extname}: ignoring an init script due to marks"
      ;;

      *)
         _run_extension_init "${extensiondir}" "${projecttype}" "$@"
      ;;
   esac

   case "${marks}" in
      *no-motd*|*no-${exttype}-motd*)
         log_fluff "${vendor}:${extname}: ignoring any motd info due to \
marks"
      ;;

      *)
         _append_to_motd "${extensiondir}"
      ;;
   esac
}


install_motd()
{
   log_entry "install_motd" "$@"

   local text="$1"
   local motdfile=".mulle-env/etc/motd"

   if [ -z "${text}" ]
   then
      remove_file_if_present "$motdfile"
      return
   fi

   mkdir_if_missing ".mulle-env/etc"
   redirect_exekutor ".mulle-env/etc/motd" echo "${text}"
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
   local marks="$2"
   local force="$3"

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

   local cmdline_options
   local _MOTD

   _MOTD=""
   cmdline_options="\
--buildtool `colon_concat "${buildtool_vendor}" "${buildtool_name}"` \
--runtime `colon_concat "${runtime_vendor}" "${runtime_name}"` \
--common `colon_concat "${common_vendor}" "${common_name}"` \
"

   if [ "${force}" = "YES" ]
   then
      rmdir_safer ".mulle-sde/libexec"
      rmdir_safer ".mulle-sde/share"
      rmdir_safer ".mulle-sde/bin"
   fi

   #
   # buildtool is the most likely to fail, due to a mistyped
   # projectdir, if that happens, we have done the least pollution yet
   #
   (
      install_extension "${projecttype}" \
                        "buildtool" \
                        "${buildtool_name}" \
                        "${buildtool_vendor}" \
                        "${marks}" \
                        "${force}" \
                        -p "${OPTION_NAME}" &&
      install_extension "${projecttype}" \
                        "runtime" \
                        "${runtime_name}" \
                        "${runtime_vendor}" \
                        "${marks}" \
                        "${force}" \
                        -p "${OPTION_NAME}" &&
      install_extension "${projecttype}" \
                        "common" \
                        "${common_name}" \
                        "${common_vendor}" \
                        "${marks}" \
                        "${force}" \
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
   local option

   IFS="
"; set -o noglob
   for extra in ${OPTION_EXTRAS}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob
      if [ ! -z "${extra}" ]
      then
         extra_vendor="`cut -s -d':' -f1 <<< "${extra}" `"
         extra_name="` cut -d':' -f2 <<< "${extra}" `"
         extra_vendor="${extra_vendor:-builtin}"

         install_extension "${projecttype}" \
                           "extra" \
                           "${extra_name}" \
                           "${extra_vendor}" \
                           "${marks}" \
                           "${force}" \
                           -p "${OPTION_NAME}"

         option="--extra `colon_concat "${extra_vendor}" "${extra_name}"`"
         cmdline_options="`concat "${cmdline_options}" "${option}"`"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob


   #
   # remember installed extensions
   #
   local extensionsfile
   local versionfile

   mkdir_if_missing ".mulle-sde/etc" || exit 1

   extensionsfile=".mulle-sde/etc/extensions"
   versionfile=".mulle-sde/etc/version"

   log_verbose "Creating \"${extensionsfile}\""
   redirect_exekutor "${extensionsfile}" echo "${cmdline_options}"

   log_verbose "Creating \"${versionfile}\""
   redirect_exekutor "${versionfile}" echo "${MULLE_SDE_VERSION}"

   fix_permissions

   case "${marks}" in
      *no-motd*)
      ;;

      *)
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
      ;;
   esac
}


###
### parameters and environment variables
###
sde_init_main()
{
   log_entry "sde_init_main" "$@"

   local OPTION_NAME
   local OPTION_EXTRAS
   local OPTION_COMMON="sde"
   local OPTION_RUNTIME="c"
   local OPTION_BUILDTOOL="cmake"
   local OPTION_VENDOR="builtin"
   local OPTION_INIT_ENV="YES"
   local OPTION_ENV_STYLE="mulle:restricted"
   local OPTION_BLURB=""

   local OPTION_MARKS=""

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

         --no-blurb)
            OPTION_BLURB="--no-blurb"
         ;;

         --no-env)
            OPTION_INIT_ENV="NO"
         ;;

         --no-*)
            OPTION_MARKS="`concat "${OPTION_MARKS}" "${1:-2}"`"
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


   if [ -z "${MULLE_PATH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   fi

   if [ -z "${MULLE_FILE}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
   fi

   if [ -z "${MULLE_SDE_EXTENSION_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh" || exit 1
   fi

   #
   # make nicer in the future for now just hax
   #
   [ "$#" -eq 0 ] && sde_init_usage "missing project type"

   local projecttype

   projecttype="$1"
   shift
   [ "$#" -eq 0 ] || sde_init_usage "extranous argmuents \"$*\""

   if [ "${OPTION_INIT_ENV}" = "YES" ]
   then
      export MULLE_EXECUTABLE_NAME
      exekutor mulle-env ${MULLE_ENV_FLAGS} init ${OPTION_BLURB} \
                         --style "${OPTION_ENV_STYLE}"
      case $? in
         0)
         ;;

         2)
            log_fluff "mulle-env warning noted, but ignored"
         ;;

         *)
            exit 1
         ;;
      esac
   fi

   mkdir_if_missing ".mulle-sde" || exit 1

   if ! install_project "${projecttype}" \
                        "${OPTION_MARKS}" \
                        "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      rmdir_safer ".mulle-sde"
      rmdir_safer ".mulle-env"
      exit 1
   fi
}
