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

Options:
   -b <builder>   : specify buildtool to use (cmake)
   -d <dir>       : directory to populate (working directory)
   -n <name>      : project name
   -r <runtime>   : specify runtime to use (c)
   -v <vendor>    : extension vendor to use (mulle)

Types:
   executable     : create an executable project
   library        : create a library project
   empty          : do not create project files
EOF
   exit 1
}


install_file()
{
   log_entry "install_updater" "$@"

   local filename="$1"
   local extensiondir="$2"

   local dstfile

   dstfile=".mulle-sde/bin/${filename}"
   if [ -f "${dstfile}" ] && [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
   then
      log_verbose "Won't overwrite existing \"${dstfile}\" ($PWD)"
      return 0
   fi

   local srcfile

   srcfile="${extensiondir}/${filename}"
   if [ ! -f "${srcfile}" ]
   then
      log_fluff "\"${srcfile}\" is missing"
      return 1
   fi

   mkdir_if_missing ".mulle-sde/bin" || exit 1
   exekutor cp -a "${srcfile}" "${dstfile}" || exit 1
   exekutor chmod +x "${dstfile}"
}


install_buildtool_extension()
{
   log_entry "install_buildtool_extension" "$@"

   local name="$1"
   local vendor="$2"

   local extensiondir

   extensiondir="`find_extension "${name}" "buildtool" "${vendor}"`" || \
      fail "Could not find buildtool extension \"${name}\" from vendor \"${vendor}\""

   install_file "did-update-src" "${extensiondir}" || fail "did-update-src is required"
   install_file "did-update-sourcetree" "${extensiondir}" || :

   local text

   if [ -f "${extensiondir}/motd" ]
   then
      text="`cat "${extensiondir}/motd" `"
      if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
      then
         _MOTD="`add_line "${_MOTD}" "${text}" `"
      fi
   fi
}


install_runtime_extension()
{
   log_entry "install_runtime_extension" "$@"

   local name="$1"; shift
   local vendor="$1"; shift

   local extensiondir

   extensiondir="`find_extension "${name}" "runtime" "${vendor}"`" || \
      fail "Could not find runtime extension \"${name}\" from vendor \"${vendor}\""

   eval_exekutor "${extensiondir}/init" "$@"

   local text

   if [ -f "${extensiondir}/motd" ]
   then
      text="`cat "${extensiondir}/motd" `"
      if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
      then
         _MOTD="`add_line "${_MOTD}" "${text}" `"
      fi
   fi
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


###
### parameters and environment variables
###
sde_init_main()
{
   log_entry "sde_init_main" "$@"

   local OPTION_NAME
   local OPTION_RUNTIME="c"
   local OPTION_BUILDTOOL="cmake"
   local OPTION_VENDOR="mulle"
   local OPTION_INIT_ENV="YES"
   local OPTION_ENV_STYLE="mulle:restricted"

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help)
            sde_init_usage
         ;;

         -n|--name)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_NAME="$1"
         ;;

         -b|--buildtool)
            [ $# -eq 1 ] && sde_init_usage
            shift

            OPTION_BUILDTOOL="`tr 'A-Z' 'a-z' <<< "$1" `"
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

         -d|--directory)
            [ $# -eq 1 ] && sde_init_usage
            shift

            mkdir -p "$1" 2> /dev/null
            cd "$1" || fail "can't change to \"$1\""
         ;;

         --no-env)
            OPTION_INIT_ENV="NO"
         ;;

         --env-style)
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

   if [ "${OPTION_INIT_ENV}" = "YES" ]
   then
      export MULLE_EXECUTABLE_NAME
      exekutor mulle-env ${MULLE_ENV_FLAGS} init --style "${OPTION_ENV_STYLE}"
   fi

   #
   # make nicer in the future for now just hax
   #
   local projecttype

   [ "$#" -ne 1 ] && sde_init_usage

   projecttype="$1"

   local arguments

   arguments=""
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "YES" ]
   then
      arguments="-f"
   fi
   if [ ! -z "${OPTION_NAME}" ]
   then
      arguments="`concat "${arguments}" "-n '${OPTION_NAME}'" `"
   fi
   arguments="`concat "${arguments}" "'${projecttype}'" `"

   local _MOTD

   _MOTD=""

   install_runtime_extension "${OPTION_RUNTIME}" \
                             "${OPTION_VENDOR}" \
                             "${arguments}" &&
   install_buildtool_extension "${OPTION_BUILDTOOL}" \
                               "${OPTION_VENDOR}"

   if [ ! -z "${_MOTD}" ]
   then
      _MOTD="
"
   fi

   _MOTD="`add_line "${_MOTD}" "Ready to build with:
   mulle-sde build
" `"
   install_motd "${_MOTD}"

   echo "${_MOTD}"
}
