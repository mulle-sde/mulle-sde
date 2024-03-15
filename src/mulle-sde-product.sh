# shellcheck shell=bash
#
#   Copyright (c) 2019 Nat! - Mulle kybernetiK
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
MULLE_SDE_PRODUCT_SH='included'

sde::product::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} product [options] <command>

   Find product of mulle-sde craft (list) or run it, if it's an executable.
   Searchpath shows the places products of a certain type are expected to
   show up. See \`${MULLE_USAGE_NAME} product searchpath help\` for more info.

   \`${MULLE_USAGE_NAME} run\` is a shortcut for \`${MULLE_USAGE_NAME} product run\`

Commands:
   list                : list built products
   link                : symlink current product into ~/bin
   run                 : run most recent product (if executable)
   searchpath          : show product places 

Options:
   -h                  : show this usage
   --configuration <c> : set configuration, like "Debug"
   --debug             : shortcut for --configuration Debug
   --release           : shortcut for --configuration Release
   --restrict          : run product with restricted environment
   --sdk <sdk>         : set sdk
EOF
   exit 1
}

sde::product::link_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} link

   Forceably symlink the main executable of the given project, into ~/bin.
   This can be dangerous and convenient at the same time.

EOF
   exit 1
}


sde::product::run_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options] [arguments] ...

   Run the main executable of the given project, with the arguments given.
   The executable will not run within the mulle-sde environment!

Options:
   --  :   pass remaining options as arguments

Environment:
   MULLE_SDE_RUN  : command line to use, use \${EXECUTABLE} as variable

EOF
   exit 1
}


sde::product::freshest_files()
{
   log_entry "sde::product::freshest_files" "$@"

   local files="$1"

   local filename
   local sortlines

   .foreachline filename in ${files}
   .do
      # guard for executables read from motd that find didn't check
      if [ -f "${filename}" ]
      then
         r_add_line "${sortlines}" "`modification_timestamp "${filename}"` ${filename#${MULLE_USER_PWD}/}"
         sortlines="${RVAL}"
      fi
   .done

   sort -rn <<< "${sortlines}" | sed 's/[0-9]* //'
}


sde::product::r_executables()
{
   log_entry "sde::product::r_executables" "$@"

   local projecttype

   projecttype="`mulle-sde env get PROJECT_TYPE`"
   if [ "${projecttype}" != "executable" ]
   then
      fail "\"mulle-sde run\" works only in executable projects"
   fi

   local kitchen_dir

   kitchen_dir="`mulle-sde kitchen-dir`"
   if ! [ -d "${kitchen_dir}" ]
   then
      log_info "Run craft first to produce product"
      mulle-sde craft || exit 1
   fi

   if ! [ -d "${kitchen_dir}" ]
   then
      fail "Couldn't figure out kitchen-dir. VERY OBSCURE!!"
   fi

   local motd_files
   local executables
   local filename

   motd_files="`rexekutor find "${kitchen_dir}" -name '.motd' \
                                                -type f \
                                                -not -path "${kitchen_dir}/.craftorder/*" `"

   motd_files="`sde::product::freshest_files "${motd_files}"`"

   log_setting "kitchen_dir : ${kitchen_dir}"
   log_setting "motd_files  : ${motd_files}"

   if [ ! -z "${motd_files}" ]
   then
      r_line_at_index "${motd_files}" 0
      filename="${RVAL}"

      executables="`rexekutor sed -n  -e "s/"$'\033'"[^"$'\033'"]*$//g" \
                                      -e 's/^.*[[:blank:]][[:blank:]][[:blank:]]\(.*\)/\1/p' \
                                     "${filename}" `"
   fi

   log_setting "executables  : ${executables}"

   if [ -z "${executables}" ]
   then
      #
      # fallback code, if we have no motd, or couldn't parse it
      # then look for PROJECT_NAME.exe or
      # PROJECT_NAME
      #
      local projectname

      projectname="`mulle-sde env get PROJECT_NAME`"
      executables="`rexekutor find "${kitchen_dir}" \( -name "${projectname}${MULLE_EXE_EXTENSION}" \
                                                    -o -name "${projectname}" \
                                                    \) \
                                                   -type f \
                                                   -perm +111 \
                                                   -not -path "${kitchen_dir}/.craftorder/*" `"

      executables="`sde::product::freshest_files "${executables}"`"
      if [ -z "${executables}" ]
      then
         fail "Could not figure what product was build.
${C_RESET_BOLD}${projectname}${C_ERROR} or ${C_RESET_BOLD}${projectname}.exe${C_ERROR} not found in ${C_RESET_BOLD}${kitchen_dir#${MULLE_USER_PWD}/}"
      fi

      # we pick the first of whatever
      r_line_at_index "${executables}"
      executables="${RVAL}"
   fi

   RVAL="${executables}"
}


sde::product::r_user_choses_executable()
{
   log_entry "sde::product::r_user_chosen_executable" "$@"

   local executables="$1"

   local names
   local executable

   .foreachline executable in ${executables}
   .do
      r_basename "${executable}"
      r_add_line "${names}" "${RVAL}"
      names="${RVAL}"
   .done

   local row

   rexekutor mudo -f mulle-menu --title "Choose executable:" \
                                --final-title "" \
                                --options "${names}"
   row=$?
   log_debug "row=${row}"

   r_line_at_index "${executables}" $row
   [ ! -z "${RVAL}" ]
}


sde::product::r_search_path()
{
   log_entry "sde::product::r_search_path" "$@"

   local type="$1"

   local cmdline

   cmdline="mulle-craft ${MULLE_TECHNICAL_FLAGS} searchpath"

   if [ "${OPTION_IF_MISSING}" = 'YES' ]
   then
      r_concat "${cmdline}" "--if-missing"
      cmdline="${RVAL}"
   fi

   local sdks

   sdks="${OPTION_SDK:-${MULLE_CRAFT_SDKS}}"

   if [ ! -z "${sdks}" ]
   then
      r_concat "${cmdline}" "--sdks '${sdks}'"
      cmdline="${RVAL}"
   fi

   r_concat "${cmdline}" "--configurations '${OPTION_CONFIGURATION:-Release:Debug}'"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "--kitchen"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "'${type}'"
   cmdline="${RVAL}"

   RVAL="`eval_rexekutor ${cmdline}`"
}


sde::product::r_product_path()
{
   log_entry "sde::product::r_product_path" "$@"

   local MULLE_PLATFORM_EXECUTABLE_SUFFIX
   local MULLE_PLATFORM_FRAMEWORK_PATH_LDFLAG
   local MULLE_PLATFORM_FRAMEWORK_PREFIX
   local MULLE_PLATFORM_FRAMEWORK_SUFFIX
   local MULLE_PLATFORM_LIBRARY_LDFLAG
   local MULLE_PLATFORM_LIBRARY_PATH_LDFLAG
   local MULLE_PLATFORM_LIBRARY_PREFIX
   local MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC
   local MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC
   local MULLE_PLATFORM_LINK_MODE
   local MULLE_PLATFORM_OBJECT_SUFFIX
   local MULLE_PLATFORM_RPATH_LDFLAG
   local MULLE_PLATFORM_RPATH_VALUE_PREFIX
   local MULLE_PLATFORM_WHOLE_ARCHIVE_LDFLAG_DEFAULT
   local MULLE_PLATFORM_WHOLE_ARCHIVE_LDFLAG_STATIC

   eval_rexekutor `mulle-platform environment`

   local type
   local filenames

   case "${PROJECT_TYPE}" in
      library)
         type="library"
         filenames=${MULLE_PLATFORM_LIBRARY_PREFIX}"${PROJECT_NAME}${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}"

         # also search for mulle-cored.lib (debug), generally speaking we should
         # do this more cleverly
         case "${MULLE_UNAME}" in
            mingw*)
               filenames=${filenames}:${MULLE_PLATFORM_LIBRARY_PREFIX}"${PROJECT_NAME}d${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}"
            ;;
         esac
      ;;

      executable)
         type="binary"
         filenames="${PROJECT_NAME}${MULLE_PLATFORM_EXECUTABLE_SUFFIX}"
      ;;

      none)
         log_info "Project type \"none\" builds no product"
         return
      ;;

      *)
         fail "Project type \"${PROJECT_TYPE}\" is unsupported by this command"
      ;;
   esac

   if ! sde::product::r_search_path "${type}"
   then
      fail "Product ${C_RESET_BOLD}${filenames}${C_ERROR} not found. Maybe not build yet ?"
   fi

   local searchpath

   searchpath="${RVAL}"
   log_debug "searchpath: ${searchpath}"

   local candidates

   .foreachpath filepath in ${searchpath}
   .do
      .foreachpath filename in ${filenames}
      .do
         r_filepath_concat "${filepath}" "${filename}"
         if [ -e "${RVAL}" ]
         then
            r_add_line "${candidates}" "${RVAL}"
            candidates="${RVAL}"
         fi
      .done
   .done

   # if we don't find a prime candidate and its an executable, we might be 
   # in "demos", where there are multiple candidates
   if [ -z "${candidates}" -a "${PROJECT_TYPE}" = 'executable' ]
   then
      sde::product::r_executables
      candidates="${RVAL}"
   fi

   if [ -z "${candidates}" ]
   then
      fail "Product ${C_RESET_BOLD}${filename}${C_ERROR} not found."
   fi

   local candidate
   local latest_timestamp
   local timestamp

   .foreachline candidate in ${candidates}
   .do
      timestamp="`modification_timestamp "${candidate}" `"
      if [ -z "${latest_timestamp}" ] || [ ${timestamp} -gt ${latest_timestamp} ]
      then
         filepath="${candidate}"
         latest_timestamp="${timestamp}"
      fi
   .done

   RVAL="${filepath}"
}

sde::product::list_main()
{
   log_entry "sde::product::list_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::product::usage
         ;;

         -*)
            sde::product::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::product::r_product_path
   printf "%s\n" "${RVAL}"
}


sde::product::searchpath_main()
{
   log_entry "sde::product::searchpath_main" "$@"

   while :
   do
      case "$1" in
         -h|--help|help)
            MULLE_USAGE_NAME=mulle-sde \
               rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS} searchpath -h
            exit 0
         ;;

         -*)
            sde::product::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   sde::product::r_search_path "$@"
   printf "%s\n" "${RVAL}"
}


sde::product::r_executable()
{
   log_entry "sde::product::r_executable" "$@"

   local executables

   sde::product::r_executables
   executables="${RVAL}"

   local executable

   if ! sde::product::r_user_choses_executable "${executables}"
   then
      return 1
   fi
}


sde::product::run_main()
{
   log_entry "sde::product::run_main" "$@"

   local EXECUTABLE

   if ! sde::product::r_executable
   then
      return 1
   fi
   EXECUTABLE="${RVAL}"

   local commandline

   commandline="`mulle-sde env get MULLE_SDE_RUN`"

   if [ ! -z "${commandline}" ]
   then
      r_expanded_string "${commandline}"
      commandline="${RVAL}"

      log_verbose "Use MULLE_SDE_RUN '${commandline}' as command line"
      eval_exekutor mudo -f "${commandline}" "$@"
   else
      exekutor mudo -f "${EXECUTABLE}" "$@"
   fi

   commandline="`mulle-sde env get MULLE_SDE_POST_RUN`"
   if [ ! -z "${commandline}" ]
   then
      r_expanded_string "${commandline}"
      commandline="${RVAL}"

      log_verbose "Use MULLE_SDE_POST_RUN '${commandline}' as command line"
      eval_exekutor mudo -f "${commandline}" "$@"
   fi
}


#
# this needs to run outside of the sandbox
#
sde::product::symlink_main()
{
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::product::symlink_usage
         ;;

         -*)
            sde::product::symlink_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local dstdir

   dstdir="${1:-${HOME}/bin}"

   local executables

   sde::product::r_executables
   executables="${RVAL}"

   local executable

   if ! sde::product::r_user_choses_executable "${executables}"
   then
      return 1
   fi
   executable="${RVAL}"

   local name

   r_basename "${executable}"
   name="${RVAL}"

   local linkname

   r_filepath_concat "${dstdir}" "${name}"
   linkname="${RVAL}"

   log_info "Create symlink for ${C_MAGENTA}${C_BOLD}${name}${C_INFO} in ${C_RESET_BOLD}${dstdir#${MULLE_USER_PWD}/}"
   exekutor ln -s -f "${executable}" "${linkname}"
   log_verbose "${linkname} -> ${executable}"
}


sde::product::main()
{
   log_entry "sde::product::main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_SDK
   local OPTION_EXISTS
   local MUDO_FLAGS="-e"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::product::usage
         ;;

         --if-exists)
            OPTION_EXISTS='YES'
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::product::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::product::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
         ;;

         --select)
            OPTION_SELECT='YES'
         ;;

         --restrict)
            MUDO_FLAGS=""
         ;;

         --release)
            OPTION_CONFIGURATION="Release"
         ;;

         --debug)
            OPTION_CONFIGURATION="Debug"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::product::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      list)
         sde::product::list_main "$@"
      ;;

      run)
         sde::product::run_main "$@"
      ;;

      searchpath)
         sde::product::searchpath_main "$@"
      ;;

      *)
         sde::product::usage
      ;;
   esac
}

