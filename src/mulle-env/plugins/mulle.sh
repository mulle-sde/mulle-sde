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
         alias fetch="mulle-sde show"
         alias show="mulle-sde find"
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
# TODO: this stuff should move to mulle-sde
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
export MULLE_SOURCETREE_SHARE_DIR="\${MULLE_VIRTUAL_ROOT}/stash"

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

#
# Modify path so that dependency and addictions executables are found and
# preferred.
#
export PATH="\${DEPENDENCY_DIR}/bin:\${ADDICTION_DIR}/bin:\$PATH"

EOF
}


print_mulle_include_sh()
{
   log_entry "print_mulle_include_sh" "$@"

   print_developer_include_sh "$@"
}


#
# since all mulle- tools are uniform, this is easy.
# If it's a library, we need to strip off -env from
# the toolname for the libraryname. Also libexec is versionized
# so add the version
#
env_copy_mulle_tool()
{
   log_entry "env_copy_mulle_tool" "$@"

   local toolname="$1"
   local dstbindir="$2"
   local dstlibexecdir="$3"
   local copystyle="${4:-tool}"

   #
   # these dependencies should be there, but just check
   #
   local exefile

   exefile="`command -v "${toolname}" `"
   if [ -z "${exefile}" ]
   then
      fail "${toolname} not in PATH"
   fi

   # doing it like this renames "src" to $toolname

   local srclibexecdir
   local parentdir
   local srclibname

   srclibdir="`exekutor "${exefile}" libexec-dir `" || exit 1
   srclibexecdir="`fast_dirname "${srclibdir}" `"
   srclibname="`fast_basename "${srclibdir}" `"

   local dstbindir
   local dstexefile
   local dstlibname

   dstlibname="${toolname}"
   dstexefile="${dstbindir}/${toolname}"
   mkdir_if_missing "${dstbindir}"

   if [ "${copystyle}" = "library" ]
   then
      local version

      version="`"${exefile}" version `" || exit 1
      dstlibname="`sed 's/-env$//' <<< "${toolname}" `"
      dstlibdir="${dstlibexecdir}/${dstlibname}/${version}"
   else
      dstlibdir="${dstlibexecdir}/${dstlibname}"
   fi

   # remove previous symlinks or files
   remove_file_if_present "${dstexefile}"
   remove_file_if_present "${dstlibdir}" || rmdir_safer "${dstlibdir}"

   #
   # Developer option, since I don't want to edit copies. Doesn't work
   # on mingw, but shucks.
   #
   if [ "${srclibname}" = "src" -a "${MULLE_ENV_DEVELOPER}" != "NO" ]
   then
      mkdir_if_missing "${dstbindir}"
      mkdir_parent_if_missing "${dstlibdir}" > /dev/null

      log_fluff "Creating symlink \"${dstexefile}\""

      exekutor ln -s -f "${exefile}" "${dstexefile}"
      exekutor ln -s -f "${srclibexecdir}/src" "${dstlibdir}"
   else
      mkdir_if_missing "${dstlibdir}"

      ( cd "${srclibdir}" ; tar cf - . ) | \
      ( cd "${dstlibdir}" ; tar xf -  )

      mkdir_if_missing "${dstbindir}"

      log_fluff "Copying \"${dstexefile}\""

      exekutor cp "${exefile}" "${dstexefile}" &&
      exekutor chmod 755 "${dstexefile}"
   fi
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



env_setup_mulle_tools()
{
   log_entry "env_setup_mulle_tools" "$@"

   local bindir="$1"
   local libexecdir="$2"

   [ -z "${directory}" ] && internal_fail "directory is empty"

   #
   # Since the PATH is restricted, we need a basic set of tools
   # in directory/bin to get things going
   # (We'd also need in PATH: git, tar, sed, tr, gzip, zip. But that's not
   # checked yet)
   #
   (
      env_copy_mulle_tool "mulle-bashfunctions-env" "${bindir}" "${libexecdir}" "library" &&
      env_copy_mulle_tool "mulle-craft"             "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-dispense"          "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-env"               "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-fetch"             "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-make"              "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-match"             "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-monitor"           "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-sde"               "${bindir}" "${libexecdir}" &&
      env_copy_mulle_tool "mulle-sourcetree"        "${bindir}" "${libexecdir}"
   ) || return 1
}


## callback
env_r_mulle_add_runpath()
{
   log_entry "env_mulle_add_runpath" "$@"

   local directory="$1"
   local runpath="$2"

   # prepend in reverse order, so dependencies is first
   r_colon_concat "${runpath}" "${directory}/addiction/bin" "${runpath}"
   runpath="${RVAL}"
   r_colon_concat "${directory}/dependency/bin" "${runpath}"
}


env_mulle_initialize()
{
   env_load_plugin "developer"
}


env_mulle_initialize
