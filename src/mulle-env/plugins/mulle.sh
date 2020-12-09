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
         alias craftorder="mulle-sde craftorder"
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
         alias reflect="mulle-sde reflect"
         alias patternfile="mulle-sde patternfile"
         alias subproject="mulle-sde subproject"
      fi

      if [ -z "${MULLE_SDE_NO_QUICK_ALIAS}" ]
      then
         alias c="mulle-sde craft"
         alias C="mulle-sde clean; mulle-sde craft"
         alias CC="mulle-sde clean all; mulle-sde craft"
         alias t="mulle-sde test rerun --serial"
         alias tt="mulle-sde test craft ; mulle-sde test rerun --serial"
         alias T="mulle-sde test craft ; mulle-sde test"
         alias TT="mulle-sde test clean all; mulle-sde test"
         alias r="mulle-sde reflect"
         alias l="mulle-sde list --files"
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
MULLE_FETCH_MIRROR_DIR="\${MULLE_FETCH_MIRROR_DIR:-\${HOME:-/tmp}/Library/Caches/mulle-fetch/git-mirror}"
export MULLE_FETCH_MIRROR_DIR

MULLE_FETCH_ARCHIVE_DIR="\${MULLE_FETCH_ARCHIVE_DIR:-\${HOME:-/tmp}/Library/Caches/mulle-fetch/archive}"
export MULLE_FETCH_ARCHIVE_DIR
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
# Can be overridden with -DMULLE_FETCH_ARCHIVE_DIR on the commandline
#
MULLE_FETCH_MIRROR_DIR="\${MULLE_FETCH_MIRROR_DIR:-\${HOME:-/tmp}/.cache/mulle-fetch/git-mirror}"
export MULLE_FETCH_MIRROR_DIR

#
# Git mirror and Zip/TGZ cache to conserve bandwidth
# Can be overridden with -D on the commandline
MULLE_FETCH_ARCHIVE_DIR="\${MULLE_FETCH_ARCHIVE_DIR:-\${HOME:-/tmp}/.cache/mulle-fetch/archive}"
export MULLE_FETCH_ARCHIVE_DIR

#
# PATH to search for git repositories locally.
# Can be overridden with -DMULLE_FETCH_SEARCH_PATH on the commandline
#
MULLE_FETCH_SEARCH_PATH="\${MULLE_FETCH_SEARCH_PATH:-\${MULLE_VIRTUAL_ROOT}/..}"
export MULLE_FETCH_SEARCH_PATH

#
# Prefer symlinks to clones of git repos found in MULLE_FETCH_SEARCH_PATH
# Can be overridden with -DMULLE_SOURCETREE_SYMLINK on the commandline
#
MULLE_SOURCETREE_SYMLINK="\${MULLE_SOURCETREE_SYMLINK:-YES}"
export MULLE_SOURCETREE_SYMLINK

#
# Use common folder for sharable projects.
# Can be overridden with -MULLE_SOURCETREE_STASH_DIRNAME on the commandline
#
MULLE_SOURCETREE_STASH_DIRNAME="\${MULLE_SOURCETREE_STASH_DIRNAME:-stash}"
export MULLE_SOURCETREE_STASH_DIRNAME

#
# Share dependency directory (absolute for ease of use)
# Can be overridden with -DDEPENDENCY_DIR on the commandline
#
DEPENDENCY_DIR="\${DEPENDENCY_DIR:-\${MULLE_VIRTUAL_ROOT}/dependency}"
export DEPENDENCY_DIR

#
# Share addiction directory (absolute for ease of use)
# Can be overridden with -DADDICTION_DIR on the commandline
#
ADDICTION_DIR="\${ADDICTION_DIR:-\${MULLE_VIRTUAL_ROOT}/addiction}"
export ADDICTION_DIR

#
# Use common build directory
# Can be overridden with -DKITCHEN_DIR on the commandline
#
KITCHEN_DIR="\${KITCHEN_DIR:-\${MULLE_VIRTUAL_ROOT}/kitchen}"
export KITCHEN_DIR

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
# environment-project.sh                |
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
if [ -f "\${MULLE_ENV_ETC_DIR}/environment-project.sh" ]
then
   . "\${MULLE_ENV_ETC_DIR}/environment-project.sh"
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
# Therefore its not in a scope
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

   #
   # for people doing mulle-sde init none
   # have an assortment of tools ready so one can at least fetch stuff
   # and build stuff
   # sysctl and uptime are used by mulle-bashfunctions/parallel

   MULLE_SDE_BINARIES="\
column;optional
curl;optional
make;optional
ninja;optional
wget;optional
sysctl;optional
sw_vers;optional
uptime;optional
xcrun;optional
xcodebuild;optional
autoconf;optional
autoreconf;optional"
   printf "%s\n" "${MULLE_SDE_BINARIES}"

}

#
# smallish convention, mulle-env known scopes are times 20
# known scopes to mulle-sde are times 10 but not times 20
# user scopes could be just odd numbers ?
# The only reason for that, that you have an idea, where it came from
# though could "plop it" into the csv as well as a third field..
#
print_mulle_auxscope_sh()
{
   log_entry "print_mulle_auxscope_sh" "$@"

   echo "extension;30"
}


env_setup_mulle_tools()
{
   log_entry "env_setup_mulle_tools" "$@"

   local bindir="$1"; shift
   local libexecdir="$1"; shift

   [ -z "${MULLE_ENV_VAR_DIR}" ] && internal_fail "MULLE_ENV_VAR_DIR not set"

   #
   # avoid colliding with hosts names bin or libexec
   #
   bindir="${MULLE_ENV_VAR_DIR}/bin"
   libexecdir="${MULLE_ENV_VAR_DIR}/libexec"

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
      env_link_mulle_tool "mulle-template"   "${bindir}" "${libexecdir}" &&
      env_link_mulle_tool "mulle-test"       "${bindir}" "${libexecdir}" "tool" "optional"
   ) || return 1
}


## callback
env_r_mulle_add_runpath()
{
   log_entry "env_r_mulle_add_runpath" "$@"

   local directory="$1"
   local runpath="$2"

   [ -z "${MULLE_ENV_VAR_DIR}" ] && internal_fail "MULLE_ENV_VAR_DIR not set"

   # reverse order of precedence
   r_colon_concat "${MULLE_ENV_VAR_DIR}/bin" "${runpath}"
   r_colon_concat "${directory}/addiction/bin" "${RVAL}"
   r_colon_concat "${directory}/dependency/bin" "${RVAL}"
}


env_mulle_initialize()
{
   env_load_plugin "developer"
}


env_mulle_initialize
