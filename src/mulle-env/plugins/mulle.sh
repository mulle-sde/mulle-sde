#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_ENV_MULLE_PLUGIN_SH="included"

####
# TODO: MOVE ALL THE ENVIRONMENT STUFF TO MULLE-SDE INIT THERE IS NO GOOD
# REASON ANYMORE WHY THIS IS HERE.
####


print_mulle_startup_sh()
{
   log_entry "print_mulle_startup_sh" "$@"

   print_developer_startup_sh

   cat << EOF
#######
### mulle startup
#######

case "\${MULLE_SHELL_MODE}" in
   *INTERACTIVE*)
      if [ -z "${MULLE_SDE_NO_ALIAS}" ]
      then
         alias buildorder="mulle-sde buildorder"
         alias clean="mulle-sde clean"
         alias craft="mulle-sde craft"
         alias dependency="mulle-sde dependency"
         alias environment="mulle-sde environment"
         alias extension="mulle-sde extension"
         alias fetch="mulle-sde fetch"
         alias show="mulle-sde show"
         alias list="mulle-sde list"
         alias library="mulle-sde library"
         alias log="mulle-sde log"
         alias match="mulle-sde match"
         alias monitor="mulle-sde monitor"
         alias patternfile="mulle-sde patternfile"
         alias subproject="mulle-sde subproject"
         alias update="mulle-sde update"
      fi
   ;;
esac

EOF
}


print_mulle_environment_os_darwin_sh()
{
   log_entry "print_mulle_environment_os_darwin_sh" "$@"

   cat <<EOF
#
# Git mirror and Zip/TGZ cache to conserve bandwidth
#
export MULLE_FETCH_MIRROR_DIR="\${HOME:-/tmp}/Library/Caches/mulle-fetch/git-mirror"
export MULLE_FETCH_ARCHIVE_DIR="\${HOME:-/tmp}/Library/Caches/mulle-fetch/archive"
EOF
}


#
print_mulle_environment_aux_sh()
{
   log_entry "print_mulle_environment_aux_sh" "$@"

   # dont inherit, just clobber

   cat <<EOF
#
# Git mirror and Zip/TGZ cache to conserve bandwidth
# Memo: override in os-specific env file
#
export MULLE_FETCH_MIRROR_DIR="\${HOME:-/tmp}/.cache/mulle-fetch/git-mirror"

#
# Git mirror and Zip/TGZ cache to conserve bandwidth
#
export MULLE_FETCH_ARCHIVE_DIR="\${HOME:-/tmp}/.cache/mulle-fetch/archive"

#
# PATH to search for git repositories locally
#
export MULLE_FETCH_SEARCH_PATH="\${MULLE_VIRTUAL_ROOT}/.."

#
# Prefer symlinking to local git repositories found via MULLE_FETCH_SEARCH_PATH
#
export MULLE_SOURCETREE_SYMLINK="YES"

#
# Use common folder for sharable projects
#
export MULLE_SOURCETREE_STASH_DIRNAME="stash"

#
# Share dependency directory (absolute for ease of use)
#
export DEPENDENCY_DIR="\${MULLE_VIRTUAL_ROOT}/dependency"

#
# Share addiction directory (absolute for ease of use)
#
export ADDICTION_DIR="\${MULLE_VIRTUAL_ROOT}/addiction"

#
# Use common build directory
#
export BUILD_DIR="\${MULLE_VIRTUAL_ROOT}/build"

EOF
}


print_mulle_include_environment_sh()
{
   log_entry "print_none_include_environment_sh" "$@"

   cat <<EOF
# Top/down order of inclusion. Left overrides right if present.
# Keep these files (except environment-custom.sh) clean off manual edits so
# that mulle-env can read and set environment variables.
#
# .mulle/etc/env                        | .mulle/share/env
# --------------------------------------|--------------------
#                                       | environment-plugin.sh
#                                       | environment-plugin-os-\${MULLE_UNAME}.sh
#                                       | environment-project.sh
#                                       | environment-extension.sh
# environment-global.sh                 |
# environment-os-\${MULLE_UNAME}.sh      |
# environment-host-\${MULLE_HOSTNAME}.sh |
# environment-user-\${USER}.sh           |
# environment-custom.sh                 |
#

#
# The plugin file, if present is to be set by a mulle-env plugin
#
if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-plugin.sh" ]
then
   . "\${MULLE_ENV_SHARE_DIR}/environment-plugin.sh"
fi

#
# The plugin file, if present is to be set by a mulle-env plugin
#
if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-plugin-os\${MULLE_UNAME}.sh" ]
then
   . "\${MULLE_ENV_SHARE_DIR}/environment-plugin-os\${MULLE_UNAME}.sh"
fi


#
# The project file, if present is to be set by mulle-sde init itself
# w/o extensions
#
if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-project.sh" ]
then
   . "\${MULLE_ENV_SHARE_DIR}/environment-project.sh"
fi

#
# The extension file, if present is to be set by mulle-sde extensions.
#
if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-extension.sh" ]
then
   . "\${MULLE_ENV_SHARE_DIR}/environment-extension.sh"
fi

#
# Global user settings
#
if [ -f "\${MULLE_ENV_ETC_DIR}/environment-global.sh" ]
then
   . "\${MULLE_ENV_ETC_DIR}/environment-global.sh"
fi

#
# Load in some user modifications depending on os, hostname, username.
#
if [ -f "\${MULLE_ENV_ETC_DIR}/environment-host-\${MULLE_HOSTNAME}.sh" ]
then
   . "\${MULLE_ENV_ETC_DIR}/environment-host-\${MULLE_HOSTNAME}.sh"
fi

if [ -f "\${MULLE_ENV_ETC_DIR}/environment-os-\${MULLE_UNAME}.sh" ]
then
   . "\${MULLE_ENV_ETC_DIR}/environment-os-\${MULLE_UNAME}.sh"
fi

if [ -f "\${MULLE_ENV_ETC_DIR}/environment-user-\${USER}.sh" ]
then
   . "\${MULLE_ENV_ETC_DIR}/environment-user-\${USER}.sh"
fi

#
# For more complex edits, that don't work with the cmdline tool
#
if [ -f "\${MULLE_ENV_ETC_DIR}/environment-custom.sh" ]
then
   . "\${MULLE_ENV_ETC_DIR}/environment-custom.sh"
fi
EOF
}


print_mulle_include_sh()
{
   log_entry "print_mulle_include_sh" "$@"

   print_none_include_header_sh "$@"
   print_mulle_include_environment_sh "$@"
   print_none_include_footer_sh "$@"
}


print_mulle_tools_sh()
{
   log_entry "print_mulle_tools_sh" "$@"

   print_developer_tools_sh "$@"
}



print_mulle_optional_tools_sh()
{
   log_entry "print_mulle_optional_tools_sh" "$@"

   print_developer_optional_tools_sh "$@"
}


print_mulle_auxscopes_sh()
{
   log_entry "print_mulle_auxscopes_sh" "$@"

   echo "project
extension"
}


env_setup_mulle_tools()
{
   log_entry "env_setup_mulle_tools" "$@"

   local bindir="$1"; shift
   local libexecdir="$1"; shift


   #
   # avoid colliding with hosts names bin or libexec
   #
   bindir="${MULLE_VIRTUAL_ROOT}/.mulle/var/.env/bin"
   libexecdir="${MULLE_VIRTUAL_ROOT}/.mulle/var/.env/libexec"

   env_setup_developer_tools "${bindir}" "${libexecdir}"

   #
   # Since the PATH is restricted, we need a basic set of tools
   # in directory/bin to get things going
   # (We'd also need in PATH: git, tar, sed, tr, gzip, zip. But that's not
   # checked yet)
   #
   # parameters to pass:
   #
   # local toolname="$1"
   # local dstbindir="$2"
   # local dstlibexecdir="$3"
   # local copystyle="${4:-tool}"
   # local optional="$5"
   (
      env_link_mulle_tool "mulle-craft"      "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-dispense"   "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-fetch"      "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-make"       "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-match"      "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-monitor"    "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-platform"   "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-sde"        "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-sourcetree" "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-test"       "${bindir}" "${libexecdir}" "tool" "optional"
   ) || return 1
}


## callback
env_r_mulle_add_runpath()
{
   log_entry "env_r_mulle_add_runpath" "$@"

   local directory="$1"
   local runpath="$2"

   # reverse order of precedence
   r_colon_concat "${MULLE_VIRTUAL_ROOT}/.mulle/var/.env/bin" "${runpath}"
   r_colon_concat "${directory}/addiction/bin" "${RVAL}"
   r_colon_concat "${directory}/dependency/bin" "${RVAL}"
}


env_mulle_initialize()
{
   env_load_plugin "developer"
}


env_mulle_initialize
