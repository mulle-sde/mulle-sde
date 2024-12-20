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
MULLE_SDE_CRAFTINFO_SH='included'


CRAFTINFO_MARKS="dependency,no-subproject,no-update,no-delete,no-share,no-header,no-link"
CRAFTINFO_LIST_MARKS="dependency,no-subproject"
CRAFTINFO_LIST_NODETYPES="local"


# this is a dependency subcommand

sde::craftinfo::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo [option] <command>

   Manage craft settings of a dependency. Settings will be stored as
   subprojects in a folder named "craftinfo" in your project root.

   mulle-sde uses a "oneshot" extension mulle-sde/craftinfo to create that
   subproject. This extension also simplifies the use of build scripts.

   See the \`${MULLE_USAGE_NAME} dependency craftinfo set\` command help for
   more information and typical usage examples.

EOF

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2
   Eventually the "craftinfo" contents are used by \`mulle-craft\` to populate
   the \`dependency/share/mulle-craft\` folder and override any
   \`.mulle/etc/craft/definition\`folders. This is necessary to have proper
   setting inheritance across multiple nested projects.

EOF
   else
      echo "   (use -v to see more help)"
   fi

      cat <<EOF >&2
Commands:
   create          : create an empty craftinfo. Rarely needed. Use \`set\`.
   export          : output shell script commands
   get             : retrieve a build setting of a dependency
   list            : list builds settings of a dependency
   remove          : remove the craftinfo with all settings
   readd           : add the craftinfo dependency back
   set             : set a build setting of a dependency
   script          : convenience for creating a build script
   show            : show craftinfos that are available online
   unset           : remove a build setting of a dependency

Options:
   --global        : use global settings instead of current OS settings
   --os <name>     : specify settings for a specific OS

Environment:
   CRAFTINFO_REPOS : Repo URLs separated by | (https://github.com/craftinfo)

EOF
  exit 1
}


sde::craftinfo::set_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo set [option] <dep> <key> <value>

   Change a "craftinfo" setting value for a key. Typically these are compile or
   link options that a part of a mulle-make definition, contained in the
   craftinfo. During a craft the appropriatedefinition is then passed to
   mulle-make during a craft. See \`mulle-make definition help\` for more info.

   This command will automatically create a proper "craftinfo" subproject,
   if there is none yet.

Examples:
   Set preprocessor flag -DX=0 for all platforms on dependency "nng":

      ${MULLE_USAGE_NAME} dependency craftinfo --global \\
         set --append nng CPPFLAGS "-DX=0"

   Use a user script "build.sh" to build dependency "xyz" on the current
   OS only. This script with executable bits set, should be placed by the user
   into "craftinfo/xyz/bin": (see "craftinfo script" help for an alternative)

      ${MULLE_USAGE_NAME} dependency craftinfo set xyz BUILD_SCRIPT build.sh
      ${MULLE_USAGE_NAME} environment set MULLE_SDE_ALLOW_BUILD_SCRIPT 'YES'

   Build curl via cmake and set some variables accordingly for linux:

      ${MULLE_USAGE_NAME} dependency craftinfo --os linux \\
         set curl \\
            CMAKEFLAGS "-DBUILD_CURL_EXE=OFF -DBUILD_SHARED_LIBS=OFF"

   Set mujs to build with -fPIC:
      mulle-sde dependency craftinfo --os linux set mujs XCFLAGS -fPIC

Options:
   --append  : value will be appended to key instead (e.g. CPPFLAGS += )
   --script  : use an existing script of the package to build

EOF
  exit 1
}


sde::craftinfo::script_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo script [option] <dep> [command]

   Assuming the dependency is itself build by a script or a build system, which
   escapes the mulle-make detection, you can use this shortcut command to
   produce a  wrapper script file, that will craft the dependency.

Examplex:
   The dependency "xyz" is build with \`make\` but needs a special parameter.
   The build script that will be generated will have three stages "build",
   "install", "clean". As Makefiles usually supports these commands you can get
   away with:

      ${MULLE_USAGE_NAME} dependency craftinfo --global \\
         script xyz \\
         'make --install-prefix "\${PREFIX}"'

   The dependency "foo" is build with an installer script \`install.sh\` in its
   "bin" directory, that can only do installation:

      ${MULLE_USAGE_NAME} dependency craftinfo --global \\
         script --install-cmd './bin/install.sh "\${PREFIX}"' \\
            foo

Options:
   --build-cmd <shell commands>   : command to run for build
   --clean-cmd <shell commands>   : command to run for clean  (unused)
   --install-cmd <shell commands> : command to run for install

EOF
  exit 1
}


sde::craftinfo::create_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo create <dep>

   Create an empty craftinfo for the given dependency.

   Example:
      mulle-sde dependency craftinfo create nng

EOF
  exit 1
}


sde::craftinfo::get_usage()
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


sde::craftinfo::unset_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo unset <dep> <key>

   Remove a setting by its key.

   Example:
      mulle-sde dependency craftinfo --global unset nng CPPFLAGS

EOF
  exit 1
}


sde::craftinfo::readd_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo readd <url>

   Add the automatically generated dependency back to the sourcetree, if
   it was accidentally deleted. This dependency copies the craftinfo into
   the dependency/share/mulle-craft folder during crafting.

EOF
  exit 1
}


sde::craftinfo::show_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo show

   Show available remote craftinfos

EOF
  exit 1
}


sde::craftinfo::remove_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo remove <dep>

   Remove a craftinfo with all its settings. If you want to remove a single
   setting use "unset".

   Example:
      mulle-sde dependency craftinfo remove nng

EOF
  exit 1
}



sde::craftinfo::export_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo export [dep]

   Export build settings of a dependency for use in a craftinfo "add"
   script.

EOF
  exit 1
}



sde::craftinfo::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dependency craftinfo list [dep]

   List build settings of a dependency. By default the global settings and
   those for the current OS are listed. To see other OS settings
   use the "--os" option of \`dependency craftinfo\`.

EOF
  exit 1
}


sde::craftinfo::copy_mulle_make_definitions()
{
   log_entry "sde::craftinfo::copy_mulle_make_definitions" "$@"

   local name="$1"

   local srcdir

   srcdir="`sde::dependency::source_dir_main "${name}" `"
   if [ -z "${srcdir}" ]
   then
      log_warning "No source directory for \"${name}\" found."
      return
   fi

   if [ ! -d "${srcdir}" ]
   then
      _log_warning "Source directory not there yet, be careful not to \
clobber possibly existing .mulle/etc/craft definitions"
      return
   fi

   local i

   local dstname

   shell_enable_nullglob
   for i in "${srcdir}"/.mulle/etc/craft/definition*
   do
      if [ -d "${i}" ]
      then
         r_basename "${i}"
         dstname="${RVAL:1}"

         exekutor cp -Rp "${i}" \
                         "${subprojectdir}/${dstname}"
      else
         log_warning "${i} exists but is not a directory ?"
      fi
   done
   shell_disable_nullglob
}


sde::craftinfo::add_craftinfo_subproject()
{
   log_entry "sde::craftinfo::add_craftinfo_subproject" "$@"

   local subprojectdir="$1"

   [ -z "${subprojectdir}" ] && _internal_fail "empty subprojectdir"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS:-} \
               add \
                  --if-missing \
                  --marks "${CRAFTINFO_MARKS}" \
                  --nodetype "local" \
                  "${subprojectdir}"  || return 1

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS:-} \
               move \
                  "${subprojectdir}" \
                  top || return 1
}


sde::craftinfo::readd_main()
{
   log_entry "sde::craftinfo::readd_main" "$@"

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::readd_usage
         ;;

         --lenient)
            OPTION_LENIENT='YES'
         ;;

         -*)
            sde::craftinfo::readd_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde::craftinfo::readd_usage "Missing url or address argument"
   [ $# -ne 1 ] && sde::craftinfo::readd_usage "Superflous arguments \"$*\""

   local url="$1"

   local _address
   local _name
   local _subprojectdir
   local _folder

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   "${OPTION_LENIENT}" \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi

   sde::craftinfo::add_craftinfo_subproject "${_subprojectdir}"
}



sde::craftinfo::add_craftinfo_subproject_if_needed()
{
   log_entry "sde::craftinfo::add_craftinfo_subproject_if_needed" "$@"

   local subprojectdir="$1"
   local name="$2"
   local copy="$3"
   local clobber="$4"

   [ -z "${subprojectdir}" ] && _internal_fail "empty subprojectdir"
   [ -z "${name}" ]          && _internal_fail "empty name"
   [ -z "${clobber}" ]       && _internal_fail "empty clobber"

   if [ -d "${subprojectdir}" ]
   then
      if [ "${clobber}" = "DEFAULT" ]
      then
         return 2
      fi
      if [ "${clobber}" = 'YES' ]
      then
         sde::craftinfo::remove_dir_safer "${subprojectdir}"
      fi
   fi

   if [ ! -d "${subprojectdir}" ]
   then
      (
#         local ptype

         # shellcheck source=src/mulle-sde-extension.sh
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh"

#         ptype="${PROJECT_TYPE}"
#         if [ "${ptype}" = 'none' ]
#         then
#            ptype='unknown'
#         fi

         #
         # Tricky: we are in a subshell. We don't have the environment variables
         #         for setting stuff up.
         #         Grab them from the outside via mudo -e
         #         Except if we have them already anyway, because we are
         #         "wild"
         MULLE_SDE_EXTENSION_BASE_PATH="${MULLE_SDE_EXTENSION_BASE_PATH:-"`mudo -e sh -c 'echo "$MULLE_SDE_EXTENSION_BASE_PATH"'`"}"
         MULLE_SDE_EXTENSION_PATH="${MULLE_SDE_EXTENSION_PATH:-"`mudo -e sh -c 'echo "$MULLE_SDE_EXTENSION_PATH"'`"}"

         exekutor sde::extension::main pimp --project-type "unknown" \
                                            --oneshot-name "${name}" \
                                            mulle-sde/craftinfo
      ) || return 1
      [ -d "${subprojectdir}" ] || \
         _internal_fail "did not produce \"${subprojectdir}\""

      if [ "${copy}" = 'YES' ]
      then
         sde::craftinfo::copy_mulle_make_definitions "${name}"
      fi
   fi

   sde::craftinfo::add_craftinfo_subproject "${subprojectdir}"
}


#
# local _address
# local _name
# local _subprojectdir
# local _folder
# local _config
#
sde::craftinfo::__vars_with_url_or_address()
{
   log_entry "sde::craftinfo::__vars_with_url_or_address" "$@"

   local url="$1"
   local emptyok="${2:-YES}"
   local configname="${3:-config}"

   _address="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                              --virtual-root \
                              -s \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_SOURCETREE_FLAGS:-} \
                           get \
                              "${url}"`"
   if [ -z "${_address}" ]
   then
      if [ "${emptyok}" != 'YES' ]
      then
         fail "Dependency with url \"${url}\" is unknown"
      fi
      _address="${url}"
   fi

   [ -z "${_address}" ] && fail "Empty url or address"

   local marks

   marks="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                              --virtual-root \
                              -s \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_SOURCETREE_FLAGS:-} \
                           get \
                              "${_address}" marks`"
   case ",${marks}," in
      *,no-build,*|*,no-fs,*)
         log_verbose "${_address} is not build directly, so no craftinfo"
         return 1
      ;;
   esac

   #
   # The -craftinfo suffix to the name is there to disambiguate in cmake
   # target names
   #
   r_basename "${_address}"
   _name="${RVAL}"
   _subprojectdir="craftinfo/${_name}-craftinfo"

   local key
   local config

   include "case"
   
   r_smart_file_upcase_identifier "${_name}"
   key="MULLE_SOURCETREE_CONFIG_NAME_${RVAL}"

   r_shell_indirect_expand "${key}"
   config="${RVAL:-${configname}}"
   _config=""

   if [ ! -z "${config}" ]
   then
      _folder="${_subprojectdir}.${config}/definition"
      if [ -d "${_folder}" ]
      then
         _config="${config}"
      else
         _folder=""
      fi
   fi

   _folder="${_folder:-"${_subprojectdir}/definition"}"

   log_setting "_name:          ${_name}"
   log_setting "_address:       ${_address}"
   log_setting "_subprojectdir: ${_subprojectdir}"
   log_setting "_folder:        ${_folder}"
}


sde::craftinfo::create_main()
{
   log_entry "sde::craftinfo::create_main" "$@"

   local OPTION_CLOBBER='DEFAULT'
   local OPTION_LENIENT='NO'

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::create_usage
         ;;

         --lenient)
            OPTION_LENIENT='YES'
         ;;

         --clobber)
            OPTION_CLOBBER='YES'
         ;;

         --no-clobber)
            OPTION_CLOBBER='NO'
         ;;

         -*)
            sde::craftinfo::create_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde::craftinfo::create_usage "Missing url or address argument"
   [ $# -ne 1 ] && sde::craftinfo::create_usage "Superflous arguments \"$*\""

   local url="$1"

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=""
   fi

   local _address
   local _name
   local _subprojectdir
   local _folder

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   "${OPTION_LENIENT}" \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi
   sde::craftinfo::add_craftinfo_subproject_if_needed "${_subprojectdir}" \
                                                      "${_name}" \
                                                      "${OPTION_COPY}" \
                                                      "${OPTION_CLOBBER}"
   case "$?" in
      0|2)
         return 0
      ;;
   esac

   return 1
}


sde::craftinfo::remove_main()
{
   log_entry "sde::craftinfo::remove_main" "$@"

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::remove_usage
         ;;


         -*)
            sde::craftinfo::remove_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde::craftinfo::remove_usage "Missing url or address argument"
   [ $# -gt 1 ] && shift && sde::craftinfo::remove_usage "Superflous arguments \"$*\""

   local url="$1"

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=""
   fi

   local _address
   local _name
   local _subprojectdir
   local _folder
   local _config

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   'NO' \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS:-} \
               remove \
                  "craftinfo/${_name}-craftinfo"  || return 1
   rmdir_safer "${_subprojectdir}"
}


sde::craftinfo::remove_dir_safer()
{
   log_entry "sde::craftinfo::remove_dir_safer" "$@"

   include "path"
   include "file"

   rmdir_safer "$1"
}


sde::craftinfo::get_addresses()
{
   log_entry "sde::craftinfo::get_addresses" "$@"

   include "sde::common"

   sde::common::rexekutor_sourcetree_nofail list \
        --marks "${CRAFTINFO_LIST_MARKS}" \
        --nodetypes "${CRAFTINFO_LIST_NODETYPES}" \
        --no-output-header \
        --output-format raw \
        --format '%a\n'
}


sde::craftinfo::script_main()
{
   log_entry "sde::craftinfo::script_main" "$@"

   local extension="$1"; shift

   local OPTION_BUILD_CMD
   local OPTION_CLEAN_CMD
   local OPTION_INSTALL_CMD

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::script_usage
         ;;

         --build-cmd)
            [ "$#" -eq 1 ] && \
               sde::craftinfo::script_usage "Missing argument to \"$1\""
            shift

            OPTION_BUILD_CMD="$1"
         ;;

         --clean-cmd)
            [ "$#" -eq 1 ] &&
               sde::craftinfo::script_usage "Missing argument to \"$1\""
            shift

            OPTION_CLEAN_CMD="$1"
         ;;

         --install-cmd)
            [ "$#" -eq 1 ] && \
               sde::craftinfo::script_usage "Missing argument to \"$1\""
            shift

            OPTION_INSTALL_CMD="$1"
         ;;

         -*)
            sde::craftinfo::script_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -gt 2 ] && shift && sde::craftinfo::script_usage "Superflous arguments \"$*\""

   if [ "$#" -eq 2 ]
   then
      [ ! -z "${OPTION_BUILD_CMD}" ] && log_warning "Argument overrides the --build-cmd option"

      OPTION_BUILD_CMD="$1"
      shift

      [ -z "${OPTION_BUILD_CMD}" ] && log_warning "Argument can't be empty"

      OPTION_INSTALL_CMD="${OPTION_BUILD_CMD} install"
      OPTION_CLEAN_CMD="${OPTION_BUILD_CMD} clean"
   fi

   local url

   url="$1"

   local _address
   local _name
   local _subprojectdir
   local _folder
   local _config

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   'NO' \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi

   sde::craftinfo::add_craftinfo_subproject_if_needed "${_subprojectdir}" \
                                                      "${_name}" \
                                                      "${OPTION_COPY}" \
                                                      "DEFAULT"
   case "$?" in
      0|2)
      ;;

      *)
         exit 1
      ;;
   esac

   local template

   template="${_subprojectdir}/bin/${_name}-build.example"
   if [ ! -f  "${template}" ]
   then
      _internal_fail "Template \"${template#${MULLE_USER_PWD}/}\" is unexpectedly missing"
   fi

   local script
   local scriptname

   scriptname="${_name}-build"
   script="${_subprojectdir}/bin/${scriptname}"

   local escaped_build_cmd
   local escaped_clean_command
   local escaped_install_command

   r_escaped_doublequotes "${build_cmd:-# do nothing}"
   escaped_build_cmd="${OPTION_BUILD_CMD}"

   r_escaped_doublequotes "${clean_command:-# do nothing}"
   escaped_clean_cmd="${OPTION_CLEAN_CMD}"

   r_escaped_doublequotes "${install_command:-# do nothing}"
   escaped_install_cmd="${OPTION_INSTALL_CMD}"

   rexekutor mulle-template \
                   --clean-env \
                   ${MULLE_TECHNICAL_FLAGS} \
                   -DBUILD="${escaped_build_cmd}" \
                   -DCLEAN="${escaped_clean_cmd}" \
                   -DINSTALL="${escaped_install_cmd}" \
                   -f \
                generate -o '#<#' \
                         -c '#>#' \
                         --no-date-environment \
                         "${template}" \
                         "${script}" || exit 1

   exekutor chmod 755 "${script}" || exit 1

   log_info "Generated ${C_RESET_BOLD}${script#${MULLE_USER_PWD}/}${C_INFO} script"

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=""
   fi

   exekutor "${MULLE_MAKE}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               definition \
                     --definition-dir "${_folder}${extension}" \
                  set \
                     BUILD_SCRIPT "${scriptname}"
}


sde::craftinfo::set_main()
{
   log_entry "sde::craftinfo::set_main" "$@"

   local extension="$1"; shift

   local flags

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::set_usage
         ;;

         --append|--append0|--additive|--non-additive|--clobber|-concat|--concat0|--ifempty)
            r_concat "${flags}" "$1"
            flags="${RVAL}"
         ;;

         -*)
            sde::craftinfo::set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local url

   if [ -z "${OPTION_ADDRESS}" ]
   then
      [ $# -eq 0 ] && sde::craftinfo::unset_usage "Missing url or address argument"

      url="$1"
      shift
   else
      url="${OPTION_ADDRESS}"
   fi

   [ "$#" -eq 0 ] && sde::craftinfo::set_usage "Missing key"
   [ "$#" -eq 1 ] && sde::craftinfo::set_usage "Missing value"
   [ "$#" -gt 2 ] && sde::craftinfo::set_usage "Superflous arguments \"$*\""

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=""
   fi

   local _address
   local _name
   local _subprojectdir
   local _folder
   local _config

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   'NO' \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi

   sde::craftinfo::add_craftinfo_subproject_if_needed "${_subprojectdir}" \
                                                      "${_name}" \
                                                      "${OPTION_COPY}" \
                                                      "DEFAULT"
   case "$?" in
      0|2)
      ;;

      *)
         exit 1
      ;;
   esac

   exekutor "${MULLE_MAKE}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               definition \
                     --definition-dir "${_folder}${extension}" \
                  set \
                     ${flags} "$@"
}


sde::craftinfo::unset_main()
{
   log_entry "sde::craftinfo::unset_main" "$@"

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::unset_usage
         ;;


         -*)
            sde::craftinfo::unset_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local url

   if [ -z "${OPTION_ADDRESS}" ]
   then
      [ $# -eq 0 ] && sde::craftinfo::unset_usage "Missing url or address argument"

      url="$1"
      shift
   else
      url="${OPTION_ADDRESS}"
   fi

   [ "$#" -eq 0 ] && sde::craftinfo::unset_usage "Missing key"
   [ "$#" -gt 1 ] && shift && sde::craftinfo::unset_usage "Superflous arguments \"$*\""

   if [ "${extension}" = "DEFAULT" ]
   then
      extension=""
   fi

   local _address
   local _name
   local _subprojectdir
   local _folder
   local _config

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   'NO' \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi

   exekutor "${MULLE_MAKE}" \
                  ${MULLE_TECHNICAL_FLAGS} \
               definition \
                     --definition-dir "${_folder}${extension}" \
                  unset \
                     "$@"
}


sde::craftinfo::get_main()
{
   log_entry "sde::craftinfo::get_main" "$@"

   local extension="$1"; shift

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::get_usage
         ;;


         -*)
            sde::craftinfo::get_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local url

   if [ -z "${OPTION_ADDRESS}" ]
   then
      [ $# -eq 0 ] && sde::craftinfo::get_usage "Missing url or address argument"

      url="$1"
      shift
   else
      url="${OPTION_ADDRESS}"
   fi

   [ $# -eq 0 ] && sde::craftinfo::get_usage "Missing key"

   local _address
   local _name
   local _subprojectdir
   local _folder
   local _config

   if [ "${extension}" = "DEFAULT" ]
   then
      sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                 'YES' \
                                                 "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"

      local rval

      exekutor "${MULLE_MAKE}" \
                    ${MULLE_TECHNICAL_FLAGS} \
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
                  definition \
                     --definition-dir \
                        "${_folder}" \
                        get \
                        "$@"
      return $?
   fi

   sde::craftinfo::__vars_with_url_or_address "${url}" \
                                              'YES' \
                                              "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"

   exekutor "${MULLE_MAKE}"  \
                  ${MULLE_TECHNICAL_FLAGS} \
               definition \
                  --definition-dir "${_folder}${extension}" \
                  get \
                  "$@"
}


sde::craftinfo::_list_main()
{
   log_entry "sde::craftinfo::_list_main" "$@"

   local extension="$1"
   local url="$2"
   local indent="$3"

   shift 3

   local _address
   local _name
   local _subprojectdir
   local _folder
   local _config

   if ! sde::craftinfo::__vars_with_url_or_address "${url}" \
                                                   'YES'     \
                                                   "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   then
      return 1
   fi

   log_info "${url}"

   if [ "${extension}" != "DEFAULT" ]
   then
      log_info "${url}${extension}"

      log_info "${C_MAGENTA}${C_BOLD}${indent}${extension} ${C_RESET_BOLD}"
      exekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} \
         definition --definition-dir "${_folder}${extension}" list "$@"  | sed "s/^/   ${indent}/"
      return $?
   fi

   local text1
   local text2

   text1="`rexekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS} \
      definition --definition-dir "${_folder}" list "$@" | sed "s/^/   ${indent}/"`"
   text2="`rexekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS}  \
      definition --definition-dir "${_folder}.${MULLE_UNAME}" list "$@" | \
         sed "s/^/   ${indent}/"`"

   if [ ! -z "${text1}" -o ! -z "${text2}" ]
   then
      if [ ! -z "${_config}" ]
      then
         log_info "${url}.${_config}"
      else
         log_info "${url}"
      fi

      if [ ! -z "${text1}" ]
      then
         log_info "${C_MAGENTA}${C_BOLD}${indent}Global"
         printf "%s\n" "${text1}"
      fi

      if [ ! -z "${text2}" ]
      then
         log_info "${C_MAGENTA}${C_BOLD}${indent}${MULLE_UNAME}"
         printf "%s\n" "${text2}"
      fi
   fi
}


sde::craftinfo::list_main()
{
   log_entry "sde::craftinfo::list_main" "$@"

   local extension="$1"; shift
   local url

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::list_usage
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::craftinfo::list_usage "Unknown option \"$1\""
         ;;

         *)
            url="$1"
            shift
            break
         ;;
      esac

      shift
   done

   if [ ! -z "${url}" ]
   then
      sde::craftinfo::_list_main "${extension}" "${url}" ""
      return $?
   fi

   .foreachline url in `mulle-sde dependency list --columnar \
                                                  -- \
                                                     --format '%a\n' \
                                                     --output-format csv \
                                                     --output-no-header`
   .do
      # ignore crafinfo dependencies, slightly counterintuitively
      case "${url}" in
         craftinfo/*)
            .continue
         ;;
      esac

      sde::craftinfo::_list_main "${extension}" "${url}" "   "
   .done
}


sde::craftinfo::export_definitions()
{
   log_entry "sde::craftinfo::export_definitions" "$@"

   local definition_dir="$1"
   local config_name="$2"
   local address="$3"

   local os_name

   r_path_extension "${definition_dir}"
   os_name="${RVAL}"

   local export_line

   export_line="mulle-sde craftinfo"
   if [ "${config_name:-default}" != 'default' ]
   then
      r_concat "${export_line}" "--config '${config_name}'"
      export_line="${RVAL}"
   fi
   if [ ! -z "${os_name}" ]
   then
      r_concat "${export_line}" "--os '${os_name}'"
      export_line="${RVAL}"
   fi
   export_line="${export_line} --address '${address}'"

   rexekutor "${MULLE_MAKE}" ${MULLE_TECHNICAL_FLAGS}  \
               definition                              \
                  --definition-dir "${definition_dir}" \
                  export                               \
                     --export-command "${export_line}"
}


sde::craftinfo::export_scripts()
{
   log_entry "sde::craftinfo::export_scripts" "$@"

   local config_dir="$1"

   if [ ! -d "${config_dir}/bin" ]
   then
      return
   fi

   local scripts
   local script
   local actual_scripts

   scripts="`dir_list_files "${config_dir}/bin" '' 'f'`"

   .foreachline script in ${scripts}
   .do
      case "${script}" in
         *\.example)
            log_fluff "Ignore example file \"${script}\""
            .continue
         ;;
      esac

      if [ ! -x "${script}" ]
      then
         log_fluff "Ignore file \"${script}\" as its not executable"
         .continue
      fi

      r_add_line "${actual_scripts}" "${script}"
      actual_scripts="${RVAL}"
   .done

   if [ -z "${actual_scripts}" ]
   then
      return
   fi

   # use  "quoted" heredoc
   printf "#\n"
   printf "# Scripts\n"
   printf "#\n\n"
   printf "mkdir -p \"${config_dir}/bin\"\n"

   local script_name

   .foreachline script in ${actual_scripts}
   .do
      r_basename "${script}"
      script_name="${RVAL}"

      printf "cat <<'EOF' > \"${config_dir}/bin/${script_name}\"\n"
      cat "${script}"
      printf "EOF\n"
      printf "chmod 755 \"${config_dir}/bin/${script_name}\"\n\n"
   .done
}


sde::craftinfo::_export_main()
{
   log_entry "sde::craftinfo::_export_main" "$@"

   local extension="$1"
   local export_scripts="$2"
   shift 2

   local address="$1"

   local name

   r_basename "${address}"
   name="${RVAL}"

   if [ -z "${name}" ]
   then
      fail "need a name"
   fi

   #
   # MEMO do not use "${OPTION_CONFIG_NAME:-${MULLE_SOURCETREE_CONFIG_NAME}}"
   # for export
   #
   local configname="${OPTION_CONFIG_NAME}"
   local pattern

   if [ -z "${configname}" ]
   then
      pattern='*'
   else
      pattern=".${configname}"
   fi

   local config_dirs
   local config_dir

   pattern="${name}-craftinfo${pattern}"
   config_dirs="`dir_list_files craftinfo "${pattern}" 'd'`"
   if [ -z "${config_dirs}" ]
   then
      fail "No craftinfos found for \"${address}\" (craftinfo/${name}-craftinfo)"
   fi

   local definition_dir
   local definition_dirs
   local config_name
   local have_definition_dir

   .foreachline config_dir in ${config_dirs}
   .do
      r_basename "${config_dir}"
      case "${RVAL}" in
         *\.*)
            config_name="${RVAL##*\.}"
         ;;

         *)
            config_name='default'
         ;;
      esac

#      r_filepath_concat "craftinfo" "${config_dir}"
#      config_dir="${RVAL}"

      if [ -z "${extension}" ]
      then
         pattern='*'
      else
         pattern="${extension}"
      fi

      definition_dirs="`dir_list_files "${config_dir}" "definition${pattern}" 'd'`"
      .foreachline definition_dir in ${definition_dirs}
      .do
         sde::craftinfo::export_definitions "${definition_dir}" \
                                            "${config_name}" \
                                            "${address}"
         have_definition_dir='YES'
      .done

      # export scripts if wanted
      if [ "${export_scripts}" = 'YES' ]
      then
         if [ -z "${have_definition_dir}" ]
         then
            printf "mulle-sde craftinfo create \"${config_name}\"\n"
            have_definition_dir='NO' # just marker as we printed already
         fi

         sde::craftinfo::export_scripts "${config_dir}"
      fi
   .done
}


sde::craftinfo::export_main()
{
   log_entry "sde::craftinfo::export_main" "$@"

   local extension="$1"; shift
   local url

   local OPTION_EXPORT_SCRIPTS='YES'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::export_usage
         ;;

         --export-scripts)
            OPTION_EXPORT_SCRIPTS='YES'
         ;;

         --no-export-scripts)
            OPTION_EXPORT_SCRIPTS='NO'
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::craftinfo::export_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 1 ] && sde::craftinfo::export_usage

   local url

   url="$1"

   if [ "${extension}" = 'DEFAULT' ]
   then
      extension=""
   fi

   sde::craftinfo::_export_main "${extension}" "${OPTION_EXPORT_SCRIPTS}" "${url}" ""
}


sde::craftinfo::show_main()
{
   log_entry "sde::craftinfo::show_main" "$@"

   local url

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::show_usage
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::craftinfo::show_usage "Unknown option \"$1\""
         ;;

         *)
            url="$1" # ???
            shift
            break
         ;;
      esac

      shift
   done

   local urls
   local user

   dir_list_files "${HOME}/.mulle/share/craftinfo" "[a-zA-Z]*" 'd'
}


sde::craftinfo::main()
{
   log_entry "sde::craftinfo::main" "$@"

   local extension
   local OPTION_CONFIG_NAME

   extension="DEFAULT"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::craftinfo::usage
         ;;

         --global)
            extension=""
         ;;

         --config-name|--config)
            [ "$#" -eq 1 ] && \
               sde::craftinfo::usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIG_NAME="$1"
         ;;

         --address)
            [ "$#" -eq 1 ] && \
               sde::craftinfo::usage "Missing argument to \"$1\""
            shift

            OPTION_ADDRESS="$1"
         ;;

         --os|--platform)
            [ "$#" -eq 1 ] && \
               sde::craftinfo::usage "Missing argument to \"$1\""
            shift

            extension=".$1"
         ;;

         -*)
            sde::craftinfo::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_MAKE}" ]
   then
      MULLE_MAKE="${MULLE_MAKE:-`command -v mulle-make`}"
      [ -z "${MULLE_MAKE}" ] && fail "mulle-make not in PATH"
   fi

   local subcmd="list"

   if [ $# -ne 0 ]
   then
      subcmd="$1"
      shift
   fi

   case "${subcmd}" in
      create|set|get|list|export|exists|readd|remove|script|show|unset)
         sde::craftinfo::${subcmd}_main "${extension}" "$@" || return 1
         if [ "${subcmd}" = "set" -o "${subcmd}" = "script" ]
         then
            _log_info "Your edits will be used after:
${C_RESET_BOLD}   mulle-sde clean all"
         fi
      ;;

      *)
        sde::craftinfo::usage "Unknown dependency craftinfo \
command \"${subcmd}\""
      ;;
   esac
}
