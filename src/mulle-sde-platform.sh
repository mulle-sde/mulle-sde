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



sde::platform::list_main()
{
   log_entry "sde::platform::list_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::platform::usage
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
   
   log_info "Available platforms:"

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
            sde::platform::usage
         ;;

         -*)
            sde::platform::usage "Unknown option \"$1\""
         ;;

         *)
            sde::platform::usage "Unexpected argument \"$1\""
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

   # Try to get default emulator for this platform
   local emulator

   emulator="`rexekutor mulle-platform emulator --platform "${platform}"`"
   if [ ! -z "${emulator}" ]
   then
      r_uppercase "${platform}"
      rexekutor mulle-sde environment set "MULLE_EMULATOR__${RVAL}" "${emulator}"
      log_fluff "Emulator: ${emulator}"
   fi
}


sde::platform::cross_compiler_root_setup()
{
   log_entry "sde::platform::cross_compiler_root_setup" "$@"

   local platform="$1"
   local compiler="$2"

   local root

   if [ ! -z "${compiler}" ]
   then
      root="`rexekutor mulle-platform crosscompiler-root --compiler "${compiler}" \
                                                                       --platform "${platform}"`"
      if [ ! -z "${root}" ]
      then
         r_uppercase "${platform}"
         exekutor mulle-sde environment set "MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}" "${root}"
         log_fluff "Cross-compiler root: ${root}"
      fi
   fi
}



sde::platform::platform_setup()
{
   log_entry "sde::platform::platform_setup" "$@"

   local platform="$1"

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
         fail "No toolchain found for platform '${platform}'."$'\n'"Looked for: ${PWD#${MULLE_USER_PWD/}}/cmake/[share/]toolchain--${MULLE_UNAME}-${platform}--*--*.cmake"$'\n'"Use -f to add platform without toolchain"
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
   exekutor mulle-sde environment set "MULLE_CRAFT_TOOLCHAIN__${RVAL}" "${toolchain_name}"

   log_fluff "Toolchain: ${toolchain_name}"
   
   # Extract compiler from toolchain name
   # Format: toolchain--<build>-<host>--<triplet>--<compiler>
   local compiler

   compiler="${toolchain_name##*--}"
   
   sde::platform::emulator_setup "${platform}"
   sde::platform::cross_compiler_root_setup "${platform}" "${compiler}"
}


sde::platform::add()
{
   log_entry "sde::platform::add" "$@"

   local platform="$1"
   local use_uname="$2"

   local value
   local need_uname='NO'
   local craft_platforms
   local sourcetree_platforms

   # Read literal values from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment get MULLE_CRAFT_PLATFORMS`"
   sourcetree_platforms="`rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS`"

   value="${platform}"
   if [ -z "${value}" ]
   then
      if [ "${use_uname}" != 'YES' ]
      then
         sde::platform::usage "Missing platform name"
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
      exekutor mulle-sde environment set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
      exekutor mulle-sde environment set MULLE_SOURCETREE_PLATFORMS "${sourcetree_platforms}"
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
          sde::platform::platform_setup "${platform}"
      fi
   fi
}


sde::platform::add_main()
{
   log_entry "sde::platform::add_main" "$@"

   local use_uname='DEFAULT'  # Default to matching both prefixed and unprefixed

   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         --uname)
            use_uname='YES'
            shift
         ;;

         --no-uname)
            use_uname='NO'
            shift
         ;;

         --toolchain-file)
            [ $# -eq 1 ] && craft::qualifier::usage "Missing argument to \"$1\""
            shift

            OPTION_TOOLCHAIN_FILE="$1"
         ;;

         -*)
            sde::platform::usage "Unknown option \"$1\" for remove command"
         ;;
         
         *)
            break
         ;;
      esac
   done

   [ $# -gt 1 ] && sde::platform::usage "Superfluous arguments \"$*\""

   local platform="${1:-}"

   sde::platform::add "${platform}" "${use_uname}"
   sde::platform::propagate_to_subdirs "add" "$@"
}


sde::platform::remove()
{
   log_entry "sde::platform::remove" "$@"

   local platform="$1"
   local use_uname="$2"

   local key
   local craft_platforms
   local sourcetree_platforms

   # Read literal values from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment get MULLE_CRAFT_PLATFORMS`"
   sourcetree_platforms="`rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS`"

   if [ -z "${platform}" ]
   then
      if [ "${use_uname}" != 'YES' ]
      then
         sde::platform::usage "Missing platform name"
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
      exekutor mulle-sde environment remove MULLE_CRAFT_PLATFORMS
   else
      exekutor mulle-sde environment set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
   fi

   if [ -z "${sourcetree_platforms}" ]
   then
      exekutor mulle-sde environment remove MULLE_SOURCETREE_PLATFORMS
   else
      exekutor mulle-sde environment set MULLE_SOURCETREE_PLATFORMS "${sourcetree_platforms}"
   fi

   if [ ! -z "${key}" ]
   then
      # Remove toolchain and compiler root variables
      local upperkey

      r_uppercase "${key}"
      upperkey="${RVAL}"

      exekutor mulle-sde environment remove "MULLE_CRAFT_TOOLCHAIN__${upperkey}"
      exekutor mulle-sde environment remove "MULLE_CRAFT_CROSS_COMPILER_ROOT__${upperkey}"
      exekutor mulle-sde environment remove "MULLE_EMULATOR__${upperkey}"
   fi

   log_info "Platform '${platform}' removed"
}


sde::platform::remove_main()
{
   log_entry "sde::platform::remove_main" "$@"

   local use_uname='DEFAULT'  # Default to matching both prefixed and unprefixed

   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         --uname)
            use_uname='YES'
            shift
         ;;

         --no-uname)
            use_uname='NO'
            shift
         ;;

         -*)
            sde::platform::usage "Unknown option \"$1\" for remove command"
         ;;

         *)
            break
         ;;
      esac
   done

   [ $# -gt 1 ] && sde::platform::usage "Superfluous arguments \"$*\""

   local platform="${1:-}"

   sde::platform::remove "${platform}" "${use_uname}"
   sde::platform::propagate_to_subdirs "remove" "$@"
}


sde::platform::set()
{
   log_entry "sde::platform::set" "$@"

   local platform="$1"
   local key="$2"
   local value="$3"
   local platform_expanded
   
   case "${key}" in
      root)
         r_uppercase "${platform}"
         rexekutor mulle-sde environment set "MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}" "${value}"
         log_info "Compiler root: ${value}"
      ;;
      
      emulator)
         r_uppercase "${platform}"
         rexekutor mulle-sde environment set "MULLE_EMULATOR__${RVAL}" "${value}"
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

   [ $# -lt 3 ] && sde::platform::usage "Usage: platform set <platform> <key> <value>"
   [ $# -gt 3 ] && sde::platform::usage "Superfluous arguments \"$*\""

   local platform="$1"
   local key="$2"
   local value="$3"

   sde::platform::set "${platform}" "${key}" "${value}"
   sde::platform::propagate_to_subdirs "set" "$@"
}


sde::platform::get()
{
   log_entry "sde::platform::get" "$@"

   local platform="$1"
   local key="$2"
   local value

   # Always read effective values (no scope flag)
   case "${key}" in
      root)
         r_uppercase "${platform}"
         r_shell_indirect_expand "MULLE_CRAFT_CROSS_COMPILER_ROOT__${RVAL}"
         value="${RVAL}"
         if [ ! -z "${value}" ]
         then
            printf "%s\n" "${value}"
         fi
      ;;

      emulator)
         r_uppercase "${platform}"
         r_shell_indirect_expand "MULLE_EMULATOR__${RVAL}"
         value="${RVAL}"
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

   [ $# -lt 2 ] && sde::platform::usage "Usage: platform get <platform> <key>"
   [ $# -gt 2 ] && sde::platform::usage "Superfluous arguments \"$*\""

   local platform="$1"
   local key="$2"
   
   sde::platform::get "${platform}" "${key}"
}


sde::platform::enable()
{
   log_entry "sde::platform::enable" "$@"

   local platform="$1"
   local craft_platforms
   local sourcetree_platforms
   
   # Read literal values from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment get MULLE_CRAFT_PLATFORMS`"
   sourcetree_platforms="`rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS`"
   
   if [ -z "${platform}" ]
   then
      r_colon_concat_if_missing "${craft_platforms}" '${MULLE_UNAME}'
      if [ "${RVAL}" != "${craft_platforms}" ]
      then
         craft_platforms="${RVAL}"
         exekutor mulle-sde environment set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
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
   rexekutor mulle-sde environment set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
   
   log_info "Platform '${platform}' enabled"
}


sde::platform::enable_main()
{
   log_entry "sde::platform::enable_main" "$@"

   [ $# -eq 0 ] && sde::platform::usage "Missing platform name"
   [ $# -gt 1 ] && sde::platform::usage "Superfluous arguments \"$*\""

   local platform="$1"

   sde::platform::enable "${platform}"
   sde::platform::propagate_to_subdirs "enable" "$@"
}


sde::platform::disable()
{
   log_entry "sde::platform::disable" "$@"

   local platform="$1"
   local craft_platforms
   
   # Read literal value from environment (not expanded)
   craft_platforms="`rexekutor mulle-sde environment get MULLE_CRAFT_PLATFORMS`"
   
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
      rexekutor mulle-sde environment remove MULLE_CRAFT_PLATFORMS
   else
      rexekutor mulle-sde environment set MULLE_CRAFT_PLATFORMS "${craft_platforms}"
   fi
   
   log_info "Platform '${platform}' disabled (dependencies kept)"
}


sde::platform::disable_main()
{
   log_entry "sde::platform::disable_main" "$@"

   [ $# -eq 0 ] && sde::platform::usage "Missing platform name"
   [ $# -gt 1 ] && sde::platform::usage "Superfluous arguments \"$*\""

   local platform="$1"

   sde::platform::disable "${platform}"
   sde::platform::propagate_to_subdirs "disable" "$@"
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

   local toolchain_path

   r_absolutepath "${OPTION_TOOLCHAIN_FILE}"
   toolchain_path="${RVAL}"

   local toolchain_file

   r_basename "${toolchain_path}"
   toolchain_file="${RVAL}"

   local extension

   r_path_extension "${toolchain_file}"
   extension="${RVAL:-cmake}"

   .foreachpath dir in ${MULLE_SDE_DEMO_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         rexekutor cd "${dir}"
         log_info "Propagating to ${C_RESET_BOLD}${dir}"
         MULLE_PLATFORM_RECURSE='NO' sde::platform::${cmd}_main "$@"
      )
      fi
   .done

   MULLE_SDE_TEST_PATH="${MULLE_SDE_TEST_PATH:-test}"

   .foreachpath dir in ${MULLE_SDE_TEST_PATH}
   .do
      if [ -d "${dir}" ]
      then
      (
         rexekutor cd "${dir}"

         if [ ! -z "${toolchain_file}" ]
         then
            if [ ! -e "${extension}/${toolchain_file}" ]
            then
               log_info "Copying toolchain file ${C_RESET_BOLD}${toolchain_file}${C_INFO} to ${C_RESET_BOLD}${dir}"

               mkdir_if_missing "${extension}"
               exekutor cp "${toolchain_path}" "${extension}/"
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
            [ $# -eq 1 ] && craft::qualifier::usage "Missing argument to \"$1\""
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
