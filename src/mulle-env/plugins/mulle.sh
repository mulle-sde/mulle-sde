# shellcheck shell=bash
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
MULLE_ENV_MULLE_PLUGIN_SH='included'

####
# TODO: MOVE ALL THE ENVIRONMENT STUFF TO MULLE-SDE INIT THERE IS NO GOOD
# REASON ANYMORE WHY THIS IS HERE.
####


env::plugin::mulle::print_startup()
{
   log_entry "env::plugin::mulle::print_startup" "$@"

   env::plugin::developer::print_startup

   cat << EOF
#######
### mulle startup
#######

case "\${MULLE_SHELL_MODE}" in
   *INTERACTIVE*)
      if [ -z "\${MULLE_SDE_NO_ALIAS}" ]
      then
         alias clean="mulle-sde clean"
         alias craft="mulle-sde craft"
         alias craftorder="mulle-sde craftorder"
         alias dependency="mulle-sde dependency"
         alias environment="mulle-sde environment"
         alias extension="mulle-sde extension"
         alias fetch="mulle-sde fetch"
         alias library="mulle-sde library"
         alias list="mulle-sde list"
         alias log="mulle-sde log"
         alias match="mulle-sde match"
         alias monitor="mulle-sde monitor"
         alias patternfile="mulle-sde patternfile"
         alias reflect="mulle-sde reflect"
         alias run="mulle-sde run"
         alias show="mulle-sde show"
         alias subproject="mulle-sde subproject"
      fi

      if [ -z "\${MULLE_SDE_NO_QUICK_ALIAS}" ]
      then
         alias C="mulle-sde clean; mulle-sde craft"
         alias c="mulle-sde craft"
         alias CC="mulle-sde clean all; mulle-sde craft"
         alias l="mulle-sde list --files"
         alias r="mulle-sde reflect"
         alias T="mulle-sde test craft ; mulle-sde test"
         alias t="mulle-sde test rerun --serial"
         alias TT="mulle-sde test clean all; mulle-sde test"
         alias tt="mulle-sde test craft ; mulle-sde test rerun --serial"
      fi
   ;;
esac

EOF
}


env::plugin::mulle::print_environment_os_darwin()
{
   log_entry "env::plugin::mulle::print_environment_os_darwin" "$@"

   cat <<EOF
#
# Git mirror and Zip/TGZ cache to conserve bandwidth
#
export MULLE_FETCH_MIRROR_DIR="\${HOME:-/tmp}/Library/Caches/mulle-fetch/git-mirror"

#
# Git mirror and Zip/TGZ cache to conserve bandwidth
#
export MULLE_FETCH_ARCHIVE_DIR="\${HOME:-/tmp}/Library/Caches/mulle-fetch/archive"
EOF
}


#
env::plugin::mulle::print_environment_aux()
{
   log_entry "env::plugin::mulle::print_environment_aux" "$@"

   # dont inherit, just clobber

   cat <<EOF
#
# Git mirror and Zip/TGZ cache to conserve bandwidth
# Memo: Will often be overridden in an os-specific environment file
# Can be overridden with -DMULLE_FETCH_ARCHIVE_DIR on the commandline
#
export MULLE_FETCH_MIRROR_DIR="\${HOME:-/tmp}/.cache/mulle-fetch/git-mirror"

#
# Git mirror and Zip/TGZ cache to conserve bandwidth
#
export MULLE_FETCH_ARCHIVE_DIR="\${HOME:-/tmp}/.cache/mulle-fetch/archive"

#
# PATH to search for git repositories locally.
#
export MULLE_FETCH_SEARCH_PATH="\${MULLE_VIRTUAL_ROOT}/.."

#
# Prefer symlinks to clones of git repos found in MULLE_FETCH_SEARCH_PATH
#
export MULLE_SOURCETREE_SYMLINK='YES'

EOF
}


# env::plugin::mulle::print_include_environment()
# {
#    log_entry "env::plugin::mulle::print_include_environment" "$@"
#
#    cat <<EOF
# # Top/down order of inclusion. Left overrides right if present.
# # Keep these files (except environment-custom.sh) clean off manual edits so
# # that mulle-env can read and set environment variables.
# #
# # .mulle/etc/env                        | .mulle/share/env
# # --------------------------------------|--------------------
# #                                       | environment-plugin.sh
# #                                       | environment-plugin-os-\${MULLE_UNAME}.sh
# # environment-project.sh                |
# #                                       | environment-extension.sh
# # environment-global.sh                 |
# # environment-os-\${MULLE_UNAME}.sh                              |
# # environment-host-\${MULLE_HOSTNAME}.sh                         |
# # environment-user-\${MULLE_USERNAME}.sh                         |
# # environment-user-\${MULLE_USERNAME}-os-\${MULLE_UNAME}.sh      |
# # environment-user-\${MULLE_USERNAME}-host-\${MULLE_HOSTNAME}.sh |
# # environment-custom.sh                                          |
# #
#
# #
# # The plugin file, if present is to be set by a mulle-env plugin
# #
# if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-plugin.sh" ]
# then
#    . "\${MULLE_ENV_SHARE_DIR}/environment-plugin.sh"
# fi
#
# #
# # The plugin file, if present is to be set by a mulle-env plugin
# #
# if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-plugin-os\${MULLE_UNAME}.sh" ]
# then
#    . "\${MULLE_ENV_SHARE_DIR}/environment-plugin-os\${MULLE_UNAME}.sh"
# fi
#
#
# #
# # The project file, if present is to be set by mulle-sde init itself
# # w/o extensions
# #
# if [ -f "\${MULLE_ENV_ETC_DIR}/environment-project.sh" ]
# then
#    . "\${MULLE_ENV_ETC_DIR}/environment-project.sh"
# fi
#
# #
# # The extension file, if present is to be set by mulle-sde extensions.
# #
# if [ -f "\${MULLE_ENV_SHARE_DIR}/environment-extension.sh" ]
# then
#    . "\${MULLE_ENV_SHARE_DIR}/environment-extension.sh"
# fi
#
#
# #
# # Global user settings
# #
# if [ -f "\${MULLE_ENV_ETC_DIR}/environment-global.sh" ]
# then
#    . "\${MULLE_ENV_ETC_DIR}/environment-global.sh"
# fi
#
# #
# # Load in some user modifications depending on os, hostname, username.
# #
# if [ -f "\${MULLE_ENV_ETC_DIR}/environment-host-\${MULLE_HOSTNAME}.sh" ]
# then
#    . "\${MULLE_ENV_ETC_DIR}/environment-host-\${MULLE_HOSTNAME}.sh"
# fi
#
# if [ -f "\${MULLE_ENV_ETC_DIR}/environment-os-\${MULLE_UNAME}.sh" ]
# then
#    . "\${MULLE_ENV_ETC_DIR}/environment-os-\${MULLE_UNAME}.sh"
# fi
#
# if [ -f "\${MULLE_ENV_ETC_DIR}/environment-user-\${MULLE_USERNAME}.sh" ]
# then
#    . "\${MULLE_ENV_ETC_DIR}/environment-user-\${MULLE_USERNAME}.sh"
# fi
#
#
# #
# # For more complex edits, that don't work with the cmdline tool
# # Therefore its not in a scope
# #
# if [ -f "\${MULLE_ENV_ETC_DIR}/environment-custom.sh" ]
# then
#    . "\${MULLE_ENV_ETC_DIR}/environment-custom.sh"
# fi
#
# EOF
# }


env::plugin::mulle::print_include()
{
   log_entry "env::plugin::mulle::print_include" "$@"

   env::plugin::none::print_include_header "$@"
   env::plugin::none::print_include_environment "$@"
   env::plugin::none::print_include_footer "$@"
}


env::plugin::mulle::print_tools()
{
   log_entry "env::plugin::mulle::print_tools" "$@"

   env::plugin::developer::print_tools "$@"

   #
   # for people doing mulle-sde init none
   # have an assortment of tools ready so one can at least fetch stuff
   # and build stuff
   # sysctl and uptime are used by mulle-bashfunctions/parallel
   #
   MULLE_SDE_BINARIES="\
mulle-column
column
curl
make
ninja
wget
shasum
sysctl
sw_vers
tree
uptime
xcrun
xcodebuild
autoconf
autoreconf"
   printf "%s\n" "${MULLE_SDE_BINARIES}"

}


env::plugin::mulle::print_auxscope()
{
   log_entry "env::plugin::mulle::print_auxscope" "$@"

   echo "extension;30"
   echo "post-extension;210"
}


env::plugin::mulle::setup_tools()
{
   log_entry "env::plugin::mulle::setup_tools" "$@"

   local bindir="$1"; shift
   local libexecdir="$1"; shift

   [ -z "${MULLE_ENV_VAR_DIR}" ] && _internal_fail "MULLE_ENV_VAR_DIR not set"

   #
   # avoid colliding with hosts names bin or libexec
   #
   bindir="${MULLE_ENV_VAR_DIR}/bin"
   libexecdir="${MULLE_ENV_VAR_DIR}/libexec"

   env::plugin::developer::setup_tools "${bindir}" "${libexecdir}"

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
      env::tool::link_mulle_tool "mulle-craft"      "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-dispense"   "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-domain"     "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-fetch"      "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-make"       "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-match"      "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-menu"       "${bindir}"                 &&
      env::tool::link_mulle_tool "mulle-monitor"    "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-platform"   "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-sde"        "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-semver"     "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-sourcetree" "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-template"   "${bindir}" "${libexecdir}" &&
      env::tool::link_mulle_tool "mulle-test"       "${bindir}" "${libexecdir}" "tool" "optional"
   ) || return 1
}


## callback
env::plugin::mulle::r_add_runpath()
{
   log_entry "env::plugin::mulle::r_add_runpath" "$@"

   local directory="$1"
   local runpath="$2"

   [ -z "${MULLE_ENV_VAR_DIR}" ] && _internal_fail "MULLE_ENV_VAR_DIR not set"

   # reverse order of precedence
   local newpath

   newpath="${MULLE_ENV_VAR_DIR}/bin"

   local item

   .foreachpath item in ${runpath}
   .do
      if [ "${item}" != "${MULLE_ENV_VAR_DIR}/bin" ]
      then
         r_colon_concat "${newpath}" "${item}"
         newpath="${RVAL}"
      fi
   .done
   RVAL="${newpath}"
}


env::plugin::mulle::initialize()
{
   env::plugin::load "developer"

   MULLE_ENVIRONMENT_RELAX_KEYS="${MULLE_ENVIRONMENT_RELAX_KEYS}
MULLE_ENV_PLUGIN_PATH \
MULLE_NO_COLOR \
MULLE_SDE_EXTENSION_PATH \
MULLE_SDE_SANDBOX_RUNNING \
MULLE_SOURCETREE_PLUGIN_PATH \
MULLE_USER_PWD"
}


env::plugin::mulle::initialize

:
