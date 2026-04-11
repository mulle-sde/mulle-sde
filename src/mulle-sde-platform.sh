# shellcheck shell=bash
#
#   Copyright (c) 2026 Nat! - Mulle kybernetiK
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
MULLE_SDE_PLATFORM_SH='included'


# Expand platform name for creating environment variable names
# Expands ${MULLE_UNAME} and other shell variables
sde::platform::r_expanded_platform()
{
   local value="$1"
   
   # Expand shell variables like ${MULLE_UNAME}
   eval RVAL=\"${value}\"
}


sde::platform::usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform [options] <command>

   Manage cross-compilation platforms for your project.

   You generally use this sequence for crosscompilation:
      mulle-sde platform add windows
      mulle-sde platform set windows root /opt/my-cross-toolset-root
      mulle-sde platform set windows emulator wine

   Memo:
      mulle-sde platform add --uname adds current platform

Options:
   --no-recurse        : don't propagate to test/demo directories

Commands:
   list                : list configured platforms (active and disabled)
   show                : show available toolchains
   add <platform>      : add and enable a platform
   get <platform> <key>: get platform setting (root, emulator)
   set <platform> <key> <value> : set platform setting
   enable <platform>   : enable a disabled platform
   disable <platform>  : disable a platform (keeps dependencies)
   remove              : remove a platform

Environment:
   MULLE_CRAFT_PLATFORMS      :
   MULLE_SOURCETREE_PLATFORMS :
   MULLE_EMULATOR__<PLATFORM>  :
   MULLE_CRAFT_CROSS_COMPILER_ROOT__<PLATFORM> :
EOF
   exit 1
}


sde::platform::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform list

   List all configured platforms. Active platforms (used for crafting) are
   shown first, followed by disabled platforms (in sourcetree but not crafted).
EOF
   exit 1
}


sde::platform::show_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform show

   Show available cross-compilation toolchains that can be added as platforms.
EOF
   exit 1
}


sde::platform::add_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform add [options] [<platform>]

   Add and enable a cross-compilation platform. If no platform name is given,
   use --uname to add the current host OS platform (\${MULLE_UNAME}).

   After adding a platform, configure it with:
      mulle-sde platform set <platform> root <cross-toolset-root>
      mulle-sde platform set <platform> emulator <emulator-binary>

Options:
   --uname             : add the current host OS name as a platform
   --toolchain-file    : path to a cmake toolchain file for this platform
   --global            : write all values to global scope
   --this-os           : write all values to current OS scope
   --this-host         : write all values to current host scope
   --this-user         : write all values to current user scope
   --this-os-user      : write all values to current user+OS scope
   --os <name>         : write all values to named OS scope
   --host <name>       : write all values to named host scope
   --user <name>       : write all values to named user scope
   --scope <name>      : write all values to arbitrary named scope

Defaults:
   platform lists      : --this-os-user
   toolchain/root/emulator : --this-host
EOF
   exit 1
}


sde::platform::remove_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform remove [options] [<platform>]

   Remove a platform entirely (removes from both craft list and sourcetree).
   This also clears associated environment variables (toolchain, emulator, etc).

Options:
   --uname             : remove the current host OS name as a platform
   --no-uname          : don't implicitly include/remove \${MULLE_UNAME}
   --global            : write all values to global scope
   --this-os           : write all values to current OS scope
   --this-host         : write all values to current host scope
   --this-user         : write all values to current user scope
   --this-os-user      : write all values to current user+OS scope
   --os <name>         : write all values to named OS scope
   --host <name>       : write all values to named host scope
   --user <name>       : write all values to named user scope
   --scope <name>      : write all values to arbitrary named scope

Defaults:
   platform lists      : --this-os-user
   toolchain/root/emulator : --this-host
EOF
   exit 1
}


sde::platform::set_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform set [options] <platform> <key> <value>

   Set a configuration value for a cross-compilation platform.

   Keys:
      root      : path to the cross-compiler toolset root directory
                  (sets MULLE_CRAFT_CROSS_COMPILER_ROOT__<PLATFORM>)
      emulator  : emulator binary used to run target binaries on the host
                  (sets MULLE_EMULATOR__<PLATFORM>)

Options:
   --global        : write to the global scope
   --this-os       : write to the current OS scope
   --this-host     : write to the current host scope (default)
   --this-user     : write to the current user scope
   --this-os-user  : write to the current user+OS scope
   --os <name>     : write to the named OS scope
   --host <name>   : write to the named host scope
   --user <name>   : write to the named user scope
   --scope <name>  : write to an arbitrary named scope

Examples:
   mulle-sde platform set windows root /opt/mingw64
   mulle-sde platform set arm emulator qemu-arm
EOF
   exit 1
}


sde::platform::get_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform get [options] <platform> <key>

   Get a configuration value for a cross-compilation platform.

   Keys:
      root      : path to the cross-compiler toolset root directory
      emulator  : emulator binary used to run target binaries on the host

Options:
   --global        : read only from the global scope
   --this-os       : read only from the current OS scope
   --this-host     : read only from the current host scope
   --this-user     : read only from the current user scope
   --this-os-user  : read only from the current user+OS scope
   --os <name>     : read only from the named OS scope
   --host <name>   : read only from the named host scope
   --user <name>   : read only from the named user scope
   --scope <name>  : read only from an arbitrary named scope
EOF
   exit 1
}


sde::platform::enable_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform enable [options] <platform>

   Enable a previously disabled platform for crafting. The platform must have
   been added with 'platform add' first. Enabling adds the platform back to
   MULLE_CRAFT_PLATFORMS without touching the sourcetree.

   By default the change is written to the user+OS-specific scope (--this-os-user).
   Use --global or another scope option to override.

Options:
   --global        : write to the global scope
   --this-os       : write to the current OS scope
   --this-host     : write to the current host scope
   --this-user     : write to the current user scope
   --this-os-user  : write to the current user+OS scope (default)
   --os <name>     : write to the named OS scope
   --host <name>   : write to the named host scope
   --user <name>   : write to the named user scope
   --scope <name>  : write to an arbitrary named scope
EOF
   exit 1
}


sde::platform::disable_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} platform disable [options] <platform>

   Disable a platform so it is not used for crafting, without removing it from
   the sourcetree. Dependencies for the platform are kept. Re-enable later with
   'platform enable <platform>'.

   By default the change is written to the user+OS-specific scope (--this-os-user).
   Use --global or another scope option to override.

Options:
   --global        : write to the global scope
   --this-os       : write to the current OS scope
   --this-host     : write to the current host scope
   --this-user     : write to the current user scope
   --this-os-user  : write to the current user+OS scope (default)
   --os <name>     : write to the named OS scope
   --host <name>   : write to the named host scope
   --user <name>   : write to the named user scope
   --scope <name>  : write to an arbitrary named scope
EOF
   exit 1
}



sde::platform::list_main()
{
   log_entry "sde::platform::list_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::list_usage
         ;;

         -*)
            sde::platform::list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::platform::list_active
}


sde::platform::list_active()
{
   log_entry "sde::platform::list_active"

   if [ -z "${MULLE_CRAFT_PLATFORMS}" ]
   then
      log_info "Current platform active (${MULLE_UNAME})"
      return 0
   fi

   log_info "Active platforms (building):"

   local toolchain
   local varname
   local platform_expanded
   local unexpanded
   local has_enabled='NO'

   .foreachpath platform in ${MULLE_CRAFT_PLATFORMS}
   .do
      printf "  %s" "${platform}"
      if [ "${platform}" != "${MULLE_UNAME}" ]
      then
         # Convert platform to uppercase for variable name
         r_uppercase "${platform}"
         r_shell_indirect_expand "MULLE_CRAFT_TOOLCHAIN__${RVAL}"
         toolchain="${RVAL}"

         if [ ! -z "${toolchain}" ]
         then
            printf " (%s)" "${toolchain}"
         fi
         has_enabled='YES'
      fi
      printf "\n"
   .done

   local has_disabled='NO'
   local toolchain
   local varname
   local platform_expanded

   # Show disabled platforms (in sourcetree but not in craft)
   .foreachpath platform in ${MULLE_SOURCETREE_PLATFORMS}
   .do
      if find_item "${MULLE_CRAFT_PLATFORMS}" "${platform}" ':'
      then
         .continue
      fi

      if [ "${has_disabled}" = 'NO' ]
      then
         if [ "${has_enabled}" = 'YES' ]
         then
            log_info ""
         fi
         log_info "Disabled platforms:"
         has_disabled='YES'
      fi

      if [ "${platform}" != "${MULLE_UNAME}" ]
      then
         # Convert platform to uppercase for variable name
         r_uppercase "${platform}"
         r_shell_indirect_expand "MULLE_CRAFT_TOOLCHAIN__${RVAL}"
         toolchain="${RVAL}"

         if [ ! -z "${toolchain}" ]
         then
            printf " (%s)" "${toolchain}"
         fi
         has_enabled='YES'
      fi
      printf "[disabled] \n"
   .done
}


sde::platform::show()
{
   log_entry "sde::platform::show"

   local host
   local toolchains
   local seen_platforms

   host="`mulle-bashfunctions uname`"
   seen_platforms=""

   log_info "Current platform:"
   printf "  %s (native)\n" "${host}"
   log_info ""
   log_info "Available cross-compile platforms:"

   local toolchain
   local basename
   local target_host
   local triplet
   local compiler
   local rest
   
   # First check cmake/ (project-specific, takes precedence)
   if [ -d cmake ]
   then
      toolchains="`find cmake -maxdepth 1 -name "toolchain--${host}-*--*--*.cmake" 2>/dev/null`"
      
      if [ ! -z "${toolchains}" ]
      then
         while IFS= read -r toolchain
         do
            basename="`basename "${toolchain}" .cmake`"
            # Parse: toolchain--<build>-<host>--<triplet>--<compiler>
            # Remove "toolchain--<build>-"
            rest="${basename#toolchain--${host}-}"
            target_host="${rest%%-*}"
            rest="${rest#*--}"
            triplet="${rest%--*}"
            compiler="${rest##*--}"
            
            printf "  %s (%s, %s) - %s\n" "${target_host}" "${triplet}" "${compiler}" "${toolchain}"
            seen_platforms="${seen_platforms} ${target_host}"
         done <<< "${toolchains}"
      fi
   fi
   
   # Then check cmake/share/ (mulle-sde managed, lower priority)
   if [ -d cmake/share ]
   then
      toolchains="`find cmake/share -maxdepth 1 -name "toolchain--${host}-*--*--*.cmake" 2>/dev/null`"
      
      if [ ! -z "${toolchains}" ]
      then
         while IFS= read -r toolchain
         do

            r_extensionless_basename "${toolchain}"
            basename="${RVAL}"

            rest="${basename#toolchain--${host}-}"
            target_host="${rest%%-*}"
            
            # Skip if already seen in cmake/
            if ! grep -q -w "${target_host}" <<< "${seen_platforms}"
            then
               rest="${rest#*--}"
               triplet="${rest%--*}"
               compiler="${rest##*--}"
               printf "  %s (%s, %s) - %s\n" "${target_host}" "${triplet}" "${compiler}" "${toolchain}"
            fi
         done <<< "${toolchains}"
      fi
   fi
   
   if [ -z "${seen_platforms}" ] && [ -z "${toolchains}" ]
   then
      log_info "  (none found)"
   fi
}


sde::platform::show_main()
{
   log_entry "sde::platform::show_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::show_usage
         ;;

         -*)
            sde::platform::show_usage "Unknown option \"$1\""
         ;;

         *)
            sde::platform::show_usage "Unexpected argument \"$1\""
         ;;
      esac

      shift
   done

   sde::platform::show
}




sde::platform::emulator_setup()
{
   log_entry "sde::platform::emulator_setup" "$@"

   local platform="$1"
   local write_scope_flags="${2:---this-host}"

   # Try to get default emulator for this platform
   local emulator

   emulator="`rexekutor mulle-platform emulator --platform "${platform}"`"
   if [ ! -z "${emulator}" ]
   then
      r_uppercase "${platform}"
      rexekutor mulle-sde environment ${write_scope_flags} set "MULLE_EMULATOR__${RVAL}" "${emulator}"
      log_fluff "Emulator: ${emulator}"
   fi
}


sde::platform::cross_compiler_root_setup()
{
   log_entry "sde::platform::cross_compiler_root_setup" "$@"

   local platform="$1"
   local compiler="$2"
   local write_scope_flags="${3:---this-host}"

   local root

   if [ ! -z "${compiler}" ]
   then
      root="`rexekutor mulle-platform crosscompiler-root --compiler "${compiler}" \
                                                                       --platform "${platform}"`"
      if [ ! -z "${root}" ]
      then
         r_uppercase "${platform}"
         exekutor mulle-sde environment ${write_scope_flags} set "MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}" "${root}"
         log_fluff "Cross-compiler root: ${root}"
      fi
   fi
}



sde::platform::platform_setup()
{
   log_entry "sde::platform::platform_setup" "$@"

   local platform="$1"
   local write_scope_flags="${2:---this-host}"

   # If host and platform are the same, no toolchain needed (native build)
   [ "${platform}" = "'${MULLE_UNAME}'" ] && _internal_fail "wrong platform"
   [ -z "${platform}" ] && _internal_fail "empty platform"

   # Find matching toolchain file (prefer cmake/ over cmake/share/)
   # New format: toolchain--<build>-<host>--<triplet>--<compiler>.cmake
   #
   # TODO: what about non-cmake ??
   #
   local toolchain_file

   toolchain_file="${OPTION_TOOLCHAIN_FILE}"

   local dir

   if [ -z "${toolchains}" ]
   then
      for dir in cmake cmake/share
      do
         if [ -d "${dir}" ]
         then
            toolchain_file="`rexekutor find "${dir}" -maxdepth 1 -name "toolchain--${MULLE_UNAME}-${platform}--*--*.cmake" | head -1`"
            if [ ! -z "${toolchain_file}" ]
            then
               OPTION_TOOLCHAIN_FILE="${toolchain_file}"
               break
            fi
         fi
      done
   fi

   if [ -z "${toolchain_file}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "No toolchain found for platform '${platform}'."$'\n'"Looked for: ${PWD#${MULLE_USER_PWD}/}/cmake/[share/]toolchain--${MULLE_UNAME}-${platform}--*--*.cmake"$'\n'"Use -f to add platform without toolchain"
      fi
      log_info "No toolchain found for platform '${platform}', but continuing due to -f"
      return
   fi

   local toolchain_name
   local craft_platforms
   local sourcetree_platforms
   local varname

   # Extract toolchain name (without .cmake extension)
   r_extensionless_basename "${toolchain_file}"
   toolchain_name="${RVAL}"

   r_uppercase "${platform}"
   exekutor mulle-sde environment ${write_scope_flags} set "MULLE_CRAFT_TOOLCHAIN__${RVAL}" "${toolchain_name}"

   log_fluff "Toolchain: ${toolchain_name}"
   
   # Extract compiler from toolchain name
   # Format: toolchain--<build>-<host>--<triplet>--<compiler>
   local compiler

   compiler="${toolchain_name##*--}"
   
   sde::platform::emulator_setup "${platform}" "${write_scope_flags}"
   sde::platform::cross_compiler_root_setup "${platform}" "${compiler}" "${write_scope_flags}"
}


sde::platform::add()
{
   log_entry "sde::platform::add" "$@"

   local platform="$1"
   local use_uname="$2"
   local read_scope_flags="${3:-}"
   local write_scope_flags="${4:---this-os-user}"
   local machine_scope_flags="${5:---this-host}"

   local value
   local need_uname='NO'
   local craft_platforms
   local sourcetree_platforms

   # Read literal values from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_CRAFT_PLATFORMS`"
   sourcetree_platforms="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_SOURCETREE_PLATFORMS`"

   value="${platform}"
   if [ -z "${value}" ]
   then
      if [ "${use_uname}" != 'YES' ]
       then
          sde::platform::add_usage "Missing platform name"
       fi

      value='${MULLE_UNAME}'
      platform="${MULLE_UNAME}"
      need_uname='NO'  # Already setting it
   else
      if [ "${use_uname}" != 'NO' ]
      then
         # Check if ${MULLE_UNAME} is already in the list
         if ! find_item "${sourcetree_platforms}" '${MULLE_UNAME}' ":"
         then
            need_uname='YES'
         fi
      fi
   fi

   # Add ${MULLE_UNAME} first if needed
   if [ "${need_uname}" = 'YES' ]
   then
      r_colon_concat_if_missing "${sourcetree_platforms}" '${MULLE_UNAME}'
      sourcetree_platforms="${RVAL}"

      r_colon_concat_if_missing "${craft_platforms}" '${MULLE_UNAME}'
      craft_platforms="${RVAL}"
   fi

   # Add the specified platform
   local platforms_before

   platforms_before="${sourcetree_platforms}"
   r_colon_concat_if_missing "${sourcetree_platforms}" "${value}"
   sourcetree_platforms="${RVAL}"

   r_colon_concat_if_missing "${craft_platforms}" "${value}"
   craft_platforms="${RVAL}"

   log_setting "platforms_before     : ${platforms_before}"
   log_setting "sourcetree_platforms : ${sourcetree_platforms}"
   log_setting "craft_platforms      : ${craft_platforms}"
   
    if [ "${platforms_before}" != "${sourcetree_platforms}" ]
    then
      exekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
      exekutor mulle-sde environment ${write_scope_flags} set MULLE_SOURCETREE_PLATFORMS "${sourcetree_platforms}"
   else
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "Platform ${C_MAGENTA}${C_BOLD}${platform}${C_WARNING} already present"
      fi
   fi

    if [ "${value}" != '${MULLE_UNAME}' ]
    then
       if [ "${platforms_before}" != "${sourcetree_platforms}" -o "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
       then
           sde::platform::platform_setup "${platform}" "${machine_scope_flags}"
       fi
    fi
}


sde::platform::add_main()
{
   log_entry "sde::platform::add_main" "$@"

   local use_uname='DEFAULT'  # Default to matching both prefixed and unprefixed
   local scope_flags=""
   local has_scope='NO'
   local read_scope_flags
   local write_scope_flags
   local machine_scope_flags
   local -a propagate_argv=( "$@" )

   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::add_usage
         ;;

         --uname)
            use_uname='YES'
          ;;

         --no-uname)
            use_uname='NO'
          ;;

         --toolchain-file)
            [ $# -eq 1 ] && sde::platform::add_usage "Missing argument to \"$1\""
            shift

            OPTION_TOOLCHAIN_FILE="$1"
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            scope_flags="$1"
            has_scope='YES'
         ;;

         --os|--host|--user|--scope)
            [ $# -lt 2 ] && sde::platform::add_usage "Missing argument to \"$1\""
            scope_flags="$1 $2"
            has_scope='YES'
            shift
         ;;

         -*)
            sde::platform::add_usage "Unknown option \"$1\""
          ;;
         
         *)
            break
         ;;
      esac
      shift
   done

   [ $# -gt 1 ] && sde::platform::add_usage "Superfluous arguments \"$*\""

   local platform="${1:-}"

   if [ "${has_scope}" = 'YES' ]
   then
      read_scope_flags="${scope_flags}"
      write_scope_flags="${scope_flags}"
      machine_scope_flags="${scope_flags}"
   else
      read_scope_flags=""
      write_scope_flags="--this-os-user"
      machine_scope_flags="--this-host"
   fi

   sde::platform::add "${platform}"          \
                      "${use_uname}"         \
                      "${read_scope_flags}"  \
                      "${write_scope_flags}" \
                      "${machine_scope_flags}"
   sde::platform::propagate_to_subdirs "add" "${propagate_argv[@]}"
}


sde::platform::remove()
{
   log_entry "sde::platform::remove" "$@"

   local platform="$1"
   local use_uname="$2"
   local read_scope_flags="${3:-}"
   local write_scope_flags="${4:---this-os-user}"
   local machine_scope_flags="${5:---this-host}"
   local shadow_empty="${6:-NO}"

   local key
   local craft_platforms
   local sourcetree_platforms

   # Read literal values from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_CRAFT_PLATFORMS`"
   sourcetree_platforms="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_SOURCETREE_PLATFORMS`"

   if [ -z "${platform}" ]
   then
      if [ "${use_uname}" != 'YES' ]
      then
         sde::platform::remove_usage "Missing platform name"
      fi
      platform='${MULLE_UNAME}'
   else
      key="${platform}"
   fi

   local varname

   # Check if platform exists
   if ! find_item "${sourcetree_platforms}" "${platform}" ":"
   then
      log_warning "Platform \"${platform}\" is not configured"
      return 0
   fi

   # Remove from platforms
   r_colon_remove "${craft_platforms}" "${platform}"
   craft_platforms="${RVAL}"

   r_colon_remove "${sourcetree_platforms}" "${platform}"
   sourcetree_platforms="${RVAL}"

   if [ -z "${craft_platforms}" ]
   then
      if [ "${shadow_empty}" = 'YES' ]
      then
         exekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS ""
      else
         exekutor mulle-sde environment ${write_scope_flags} remove MULLE_CRAFT_PLATFORMS
      fi
   else
      exekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
   fi

   if [ -z "${sourcetree_platforms}" ]
   then
      if [ "${shadow_empty}" = 'YES' ]
      then
         exekutor mulle-sde environment ${write_scope_flags} set MULLE_SOURCETREE_PLATFORMS ""
      else
         exekutor mulle-sde environment ${write_scope_flags} remove MULLE_SOURCETREE_PLATFORMS
      fi
   else
      exekutor mulle-sde environment ${write_scope_flags} set MULLE_SOURCETREE_PLATFORMS "${sourcetree_platforms}"
   fi

   if [ ! -z "${key}" ]
   then
      # Remove toolchain and compiler root variables
      local upperkey

      r_uppercase "${key}"
      upperkey="${RVAL}"

      exekutor mulle-sde environment ${machine_scope_flags} remove "MULLE_CRAFT_TOOLCHAIN__${upperkey}"
      exekutor mulle-sde environment ${machine_scope_flags} remove "MULLE_CRAFT_CROSS_COMPILER_ROOT__${upperkey}"
      exekutor mulle-sde environment ${machine_scope_flags} remove "MULLE_EMULATOR__${upperkey}"
   fi

   log_info "Platform '${platform}' removed"
}


sde::platform::remove_main()
{
   log_entry "sde::platform::remove_main" "$@"

   local use_uname='DEFAULT'  # Default to matching both prefixed and unprefixed
   local scope_flags=""
   local has_scope='NO'
   local read_scope_flags
   local write_scope_flags
   local machine_scope_flags
   local shadow_empty='NO'
   local -a propagate_argv=( "$@" )

   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::remove_usage
         ;;

         --uname)
            use_uname='YES'
          ;;

         --no-uname)
            use_uname='NO'
          ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            scope_flags="$1"
            has_scope='YES'
          ;;

         --os|--host|--user|--scope)
            [ $# -lt 2 ] && sde::platform::remove_usage "Missing argument to \"$1\""
            scope_flags="$1 $2"
            has_scope='YES'
            shift
         ;;

         -*)
            sde::platform::remove_usage "Unknown option \"$1\""
          ;;

         *)
            break
         ;;
      esac
      shift
   done

   [ $# -gt 1 ] && sde::platform::remove_usage "Superfluous arguments \"$*\""

   local platform="${1:-}"

   if [ "${has_scope}" = 'YES' ]
   then
      read_scope_flags="${scope_flags}"
      write_scope_flags="${scope_flags}"
      machine_scope_flags="${scope_flags}"
   else
      read_scope_flags=""
      write_scope_flags="--this-os-user"
      machine_scope_flags="--this-host"
      shadow_empty='YES'
   fi

   sde::platform::remove "${platform}"       \
                         "${use_uname}"      \
                         "${read_scope_flags}" \
                         "${write_scope_flags}" \
                         "${machine_scope_flags}" \
                         "${shadow_empty}"
   sde::platform::propagate_to_subdirs "remove" "${propagate_argv[@]}"
}


sde::platform::set()
{
   log_entry "sde::platform::set" "$@"

   local platform="$1"
   local key="$2"
   local value="$3"
   local write_scope_flags="${4:---this-host}"
   local platform_expanded
   
   case "${key}" in
      root)
         r_uppercase "${platform}"
         rexekutor mulle-sde environment ${write_scope_flags} set "MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}" "${value}"
         log_info "Compiler root: ${value}"
      ;;
      
      emulator)
         r_uppercase "${platform}"
         rexekutor mulle-sde environment ${write_scope_flags} set "MULLE_EMULATOR__${RVAL}" "${value}"
         log_info "Emulator: ${value}"
      ;;
      
      *)
         fail "Unknown key '${key}'. Valid keys: root, emulator"
      ;;
   esac
}


sde::platform::set_main()
{
   log_entry "sde::platform::set_main" "$@"

   local scope_flags=""
   local has_scope='NO'
   local write_scope_flags
   local -a propagate_argv=( "$@" )

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::set_usage
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            scope_flags="$1"
            has_scope='YES'
         ;;

         --os|--host|--user|--scope)
            [ $# -lt 2 ] && sde::platform::set_usage "Missing argument to \"$1\""
            scope_flags="$1 $2"
            has_scope='YES'
            shift
         ;;

         -*)
            sde::platform::set_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   [ $# -lt 3 ] && sde::platform::set_usage "Missing arguments"
   [ $# -gt 3 ] && sde::platform::set_usage "Superfluous arguments \"$*\""

   local platform="$1"
   local key="$2"
   local value="$3"

   if [ "${has_scope}" = 'YES' ]
   then
      write_scope_flags="${scope_flags}"
   else
      write_scope_flags="--this-host"
   fi

   sde::platform::set "${platform}" "${key}" "${value}" "${write_scope_flags}"
   sde::platform::propagate_to_subdirs "set" "${propagate_argv[@]}"
}


sde::platform::get()
{
   log_entry "sde::platform::get" "$@"

   local platform="$1"
   local key="$2"
   local read_scope_flags="${3:-}"
   local value

   case "${key}" in
      root)
         r_uppercase "${platform}"
         value="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}`"
         if [ ! -z "${value}" ]
         then
            printf "%s\n" "${value}"
         fi
      ;;

      emulator)
         r_uppercase "${platform}"
         value="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_EMULATOR__${RVAL}`"
         if [ ! -z "${value}" ]
         then
            printf "%s\n" "${value}"
         fi
      ;;

      *)
         fail "Unknown key '${key}'. Valid keys: root, emulator"
      ;;
   esac
}


sde::platform::get_main()
{
   log_entry "sde::platform::get_main" "$@"

   local scope_flags=""
   local has_scope='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::get_usage
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            scope_flags="$1"
            has_scope='YES'
         ;;

         --os|--host|--user|--scope)
            [ $# -lt 2 ] && sde::platform::get_usage "Missing argument to \"$1\""
            scope_flags="$1 $2"
            has_scope='YES'
            shift
         ;;

         -*)
            sde::platform::get_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   [ $# -lt 2 ] && sde::platform::get_usage "Missing arguments"
   [ $# -gt 2 ] && sde::platform::get_usage "Superfluous arguments \"$*\""

   local platform="$1"
   local key="$2"
   local read_scope_flags

   if [ "${has_scope}" = 'YES' ]
   then
      read_scope_flags="${scope_flags}"
   else
      read_scope_flags=""
   fi

   sde::platform::get "${platform}" "${key}" "${read_scope_flags}"
}


sde::platform::enable()
{
   log_entry "sde::platform::enable" "$@"

   local platform="$1"
   local read_scope_flags="${2:-}"
   local write_scope_flags="${3:---this-os-user}"

   local craft_platforms
   local sourcetree_platforms

   # Read literal values from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_CRAFT_PLATFORMS`"
   sourcetree_platforms="`rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS`"

   if [ -z "${platform}" ]
   then
      r_colon_concat_if_missing "${craft_platforms}" '${MULLE_UNAME}'
      if [ "${RVAL}" != "${craft_platforms}" ]
      then
         craft_platforms="${RVAL}"
         exekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
      fi
      return
   fi

   # Check platform exists in sourcetree
   if ! find_item "${sourcetree_platforms}" "${platform}" ":"
   then
      fail "Platform '${platform}' is not configured. Use 'mulle-sde platform add ${platform}' first."
   fi

   # Add to craft platforms using mulle-bashfunctions
   r_colon_concat_if_missing "${craft_platforms}" "${platform}"
   craft_platforms="${RVAL}"
   rexekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS "${craft_platforms}"

   log_info "Platform '${platform}' enabled"
}


sde::platform::enable_main()
{
   log_entry "sde::platform::enable_main" "$@"

   local scope_flags=""
   local has_scope='NO'
   local -a propagate_argv=( "$@" )

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::enable_usage
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            scope_flags="$1"
            has_scope='YES'
         ;;

         --os|--host|--user|--scope)
            [ $# -lt 2 ] && sde::platform::enable_usage "Missing argument to \"$1\""
            scope_flags="$1 $2"
            has_scope='YES'
            shift
         ;;

         -*)
            sde::platform::enable_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   [ $# -eq 0 ] && sde::platform::enable_usage "Missing platform name"
   [ $# -gt 1 ] && sde::platform::enable_usage "Superfluous arguments \"$*\""

   local platform="$1"
   local read_scope_flags
   local write_scope_flags

   if [ "${has_scope}" = 'YES' ]
   then
      read_scope_flags="${scope_flags}"
      write_scope_flags="${scope_flags}"
   else
      read_scope_flags=""
      write_scope_flags="--this-os-user"
   fi

   sde::platform::enable "${platform}" "${read_scope_flags}" "${write_scope_flags}"
   sde::platform::propagate_to_subdirs "enable" "${propagate_argv[@]}"
}


sde::platform::disable()
{
   log_entry "sde::platform::disable" "$@"

   local platform="$1"
   local read_scope_flags="${2:-}"
   local write_scope_flags="${3:---this-os-user}"
   local shadow_empty="${4:-NO}"

   local craft_platforms

   # Read literal value from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment ${read_scope_flags} get MULLE_CRAFT_PLATFORMS`"

   # Check if platform is in craft platforms
   if ! find_item "${craft_platforms}" "${platform}" ":"
   then
      log_warning "Platform '${platform}' is not enabled"
      return 0
   fi

   # Remove platform from craft platforms using mulle-bashfunctions
   r_colon_remove "${craft_platforms}" "${platform}"
   craft_platforms="${RVAL}"

   # Update environment (if empty after removal, remove the variable)
   if [ -z "${craft_platforms}" ]
   then
      if [ "${shadow_empty}" = 'YES' ]
      then
         rexekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS ""
      else
         rexekutor mulle-sde environment ${write_scope_flags} remove MULLE_CRAFT_PLATFORMS
      fi
   else
      rexekutor mulle-sde environment ${write_scope_flags} set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
   fi

   log_info "Platform '${platform}' disabled (dependencies kept)"
}


sde::platform::disable_main()
{
   log_entry "sde::platform::disable_main" "$@"

   local scope_flags=""
   local has_scope='NO'
   local shadow_empty='NO'
   local -a propagate_argv=( "$@" )

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::disable_usage
         ;;

         --global|--this-os|--this-host|--this-user|--this-os-user)
            scope_flags="$1"
            has_scope='YES'
         ;;

         --os|--host|--user|--scope)
            [ $# -lt 2 ] && sde::platform::disable_usage "Missing argument to \"$1\""
            scope_flags="$1 $2"
            has_scope='YES'
            shift
         ;;

         -*)
            sde::platform::disable_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   [ $# -eq 0 ] && sde::platform::disable_usage "Missing platform name"
   [ $# -gt 1 ] && sde::platform::disable_usage "Superfluous arguments \"$*\""

   local platform="$1"
   local read_scope_flags
   local write_scope_flags

   if [ "${has_scope}" = 'YES' ]
   then
      read_scope_flags="${scope_flags}"
      write_scope_flags="${scope_flags}"
   else
      read_scope_flags=""
      write_scope_flags="--this-os-user"
      shadow_empty='YES'
   fi

   sde::platform::disable "${platform}" "${read_scope_flags}" "${write_scope_flags}" "${shadow_empty}"
   sde::platform::propagate_to_subdirs "disable" "${propagate_argv[@]}"
}


#
# this through OPTION_TOOLCHAIN_FILE will also propagate the last chosen one
#
sde::platform::propagate_to_subdirs()
{
   log_entry "sde::platform::propagate_to_subdirs" "$@"

   local cmd="$1"
   shift

   [ "${MULLE_PLATFORM_RECURSE}" = 'NO' ] && return 0

   local dir

   MULLE_SDE_DEMO_PATH="${MULLE_SDE_DEMO_PATH:-demo}"
   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   local toolchain_path

   r_absolutepath "${OPTION_TOOLCHAIN_FILE}"
   toolchain_path="${RVAL}"

   local toolchain_file

   r_basename "${toolchain_path}"
   toolchain_file="${RVAL}"

   local cmake_dir

   r_path_extension "${toolchain_file}"
   cmake_dir="${RVAL:-cmake}"

   local subdirs

   subdirs="${MULLE_SDE_TEST_PATH}:${MULLE_SDE_DEMO_PATH}"

   .foreachpath dir in ${subdirs}
   .do
      if [ -d "${dir}" ]
      then
      (
         rexekutor cd "${dir}"

         if [ ! -z "${toolchain_file}" ]
         then
            if [ ! -e "${cmake_dir}/${toolchain_file}" ] \
               && [ ! -e "${cmake_dir}/share/${toolchain_file}" ]
            then
               log_info "Copying toolchain file ${C_RESET_BOLD}${toolchain_file}${C_INFO} to ${C_RESET_BOLD}${dir}"

               mkdir_if_missing "${cmake_dir}"
               exekutor cp "${toolchain_path}" "${cmake_dir}/"
            fi
         fi

         log_info "Propagating to ${C_RESET_BOLD}${dir}"
         MULLE_PLATFORM_RECURSE='NO' sde::platform::${cmd}_main "$@"
      )
      fi
   .done
}


sde::platform::main()
{
   log_entry "sde::platform::main" "$@"

   local OPTION_RECURSE='YES'
   local OPTION_TOOLCHAIN_FILE

   # Parse global options first
   while [ $# -ne 0 ]
   do
      case "$1" in
         --no-recurse|--no-propagate)
            OPTION_RECURSE='NO'
         ;;

         -h|--help|help)
            sde::platform::usage
         ;;

         --toolchain-file)
            [ $# -eq 1 ] && sde::platform::usage "Missing argument to \"$1\""
            shift

            OPTION_TOOLCHAIN_FILE="$1"
         ;;

         -*)
            sde::platform::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"
   shift

   # Export recurse for subcommands to use
   MULLE_PLATFORM_RECURSE="${OPTION_RECURSE}"
   export MULLE_PLATFORM_RECURSE

   case "${cmd}" in
      list)
         sde::platform::list_main "$@"
      ;;

      add)
         sde::platform::add_main "$@"
      ;;

      get)
         sde::platform::get_main "$@"
      ;;

      set)
         sde::platform::set_main "$@"
      ;;

      enable)
         sde::platform::enable_main "$@"
      ;;

      disable)
         sde::platform::disable_main "$@"
      ;;

      remove)
         sde::platform::remove_main "$@"
      ;;

      show)
         sde::platform::show_main "$@"
      ;;

      -h|--help|help)
         sde::platform::usage
      ;;

      *)
         sde::platform::usage "Unknown command \"${cmd}\""
      ;;
   esac
}
