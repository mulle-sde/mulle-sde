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

   Find the product (library/executable) of \`mulle-sde craft\`.
   If there are  multiple products the most recently built one will be used.
   Searchpath shows the places products of a certain type are expected to
   show up. See \`${MULLE_USAGE_NAME} product searchpath help\` for more info.

   Use \`${MULLE_USAGE_NAME} run\` to run executable products.

Commands:
   list                : list built products
   symlink             : symlink current product into ~/bin
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

sde::product::symlink_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} symlink [options]

   Forceably symlink the main executable of the given project, into ~/bin.
   This can be dangerous and convenient at the same time.

Options:
   --hard    : create a hard link instead
   --install : install (copy) instead of creating a link

EOF
   exit 1
}


sde::product::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} list

   List all craft products. The most recently built product will be listed
   first.

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


sde::product::vibecodehelp()
{
   log_entry "sde::product::vibecodehelp" "$@"

   local dir
   local candidates
   local candidate

   local ext
   local sourcefile
   local testfile

   .foreachpath ext in ${PROJECT_EXTENSIONS}
   .do
      r_basename "$1"
      sourcefile="main-${RVAL}.${ext}"

      if [ -d demo ]
      then
         if [ -z "$1" ]
         then
            _log_info "There is a demo available though, maybe try:
${C_RESET_BOLD}   ( cd 'demo' && mulle-sde run)"
             return
         fi

         candidates="$(find demo -name "${sourcefile}" -print)"
         .foreachline candidate in ${candidates}
         .do
            _log_info "There is a demo available though, maybe try:
${C_RESET_BOLD}   ( cd 'demo' && mulle-sde run '$1')"
         .done
      fi

      r_extensionless_basename "$1"
      testfile="${RVAL}.${ext}"

      .foreachpath dir in ${MULLE_SDE_TEST_PATH:-test}
      .do
         if [ -d "${dir}" ]
         then
            candidates="$(find "${dir}" -name "${testfile}" -print)"
            .foreachline candidate in ${candidates}
            .do
               _log_info "In ${C_RESET_BOLD}${dir}${C_INFO} there is a test available though, maybe try:
${C_RESET_BOLD}   (cd '${dir}' && mulle-sde test run '${candidate#./}')"
            .done
         fi
      .done
   .done
}


sde::product::r_executables()
{
   log_entry "sde::product::r_executables" "$@"

   # memo this test is possibly at the wrong place
   local projecttype

   projecttype="`rexekutor mulle-sde env get PROJECT_TYPE`"
   if [ "${projecttype}" != "executable" ]
   then
      log_error "\"mulle-sde run\" works only in executable projects"

      sde::product::vibecodehelp "$1"

      exit 1
   fi

   local kitchen_dir

   kitchen_dir="`rexekutor mulle-sde kitchen-dir`"

   log_setting "kitchen_dir: ${kitchen_dir}"

   if ! [ -d "${kitchen_dir}" ]
   then
      log_info "Running ${C_MAGENTA}${C_BOLD}craft${C_INFO} first to produce product"
      rexekutor mulle-sde craft || exit 1
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

      executables="`sed -n -e "s/"$'\033'"[^"$'\033'"]*$//g" \
                           -e 's/^.*[[:blank:]][[:blank:]][[:blank:]]\(.*\)/\1/p' \
                           "${filename}" `"
   fi


   if [ -z "${executables}" ]
   then
      log_debug "No executables found using .motd"
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
                                                    -perm 0111 \
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

   log_setting "executables  : ${executables}"

   RVAL="${executables}"
}


sde::product::r_preferred_executable_names()
{
   log_entry "sde::product::r_preferred_executable_names" "$@"

   local executables="$1"
   local preferredname="$2"

   local names
   local executable
   local executable_name

   # allow user to pass in path as well
   r_extensionless_basename "${preferredname}"
   preferredname="${RVAL}"

   .foreachline executable in ${executables}
   .do
      r_basename "${executable}"
      executable_name="${RVAL}"

      if [ ! -z "${preferredname}" -a "${preferredname}" = "${executable_name%.exe}" ]
      then
         RVAL="${executable}"
         log_debug "Preferred executable found: ${executable}"
         return 0
      fi

      r_add_line "${names}" "${executable_name}"
      names="${RVAL}"
   .done

   RVAL="${names}"
   return 2
}


sde::product::r_user_choses_executable()
{
   log_entry "sde::product::r_user_chosen_executable" "$@"

   local executables="$1"
   local preferredname="$2"

   local names

   if sde::product::r_preferred_executable_names "${executables}" "${preferredname}"
   then
      return 0
   fi
   names=$( sort <<< "${RVAL}" )

   # special case only one exectable ? then pick it if preferred name is empty
   r_count_lines "${names}"
   if [ ${RVAL} -eq 1 -a -z "${preferredname}" ]
   then
      RVAL="${executables}"
      return 0
   fi

   if [ "${MULLE_VIBECODING}" = 'YES' ]
   then
      RVAL=
      return 1
   fi

   local row

   rexekutor mudo -f mulle-menu --title "Choose executable:" \
                                --final-title "" \
                                --options "${names}"
   row=$?
   log_debug "row=${row}"

   local name 

   r_line_at_index "${names}" $row
   name="${RVAL}"

   # gotta find it now
   if sde::product::r_preferred_executable_names "${executables}" "${name}"
   then
      return 0 
   fi

   RVAL=
   return 2
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

   r_concat "${cmdline}" "--add-kitchen-path"
   cmdline="${RVAL}"

   if [ ! -z "${sdks}" ]
   then
      r_concat "${cmdline}" "--sdks '${sdks}'"
      cmdline="${RVAL}"
   fi

   r_concat "${cmdline}" "--configurations '${OPTION_CONFIGURATION:-Release:Debug}'"
   cmdline="${RVAL}"

   r_concat "${cmdline}" "'${type}'"
   cmdline="${RVAL}"

   RVAL="`eval_rexekutor ${cmdline}`"
}


sde::product::r_least_recently_changed_file()
{
   log_entry "sde::product::r_least_recently_changed_file" "$@"

   local candidates="$1"

   local candidate
   local latest_timestamp
   local timestamp
   local filepath

   log_setting "candidates: ${candidates}"

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


sde::product::r_product_paths()
{
   log_entry "sde::product::r_product_paths" "$@"

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
         RVAL=
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
      sde::product::r_executables "$1"
      candidates="${RVAL}"

      if sde::product::r_preferred_executable_names "${candidates}" "$@"
      then
         log_debug "returns preferred executable: ${RVAL}"
         return 0
      fi

      RVAL="${candidates}"
      log_debug "returns: ${RVAL}"
      return 0
   fi

   if [ -z "${candidates}" ]
   then
      fail "Product ${C_RESET_BOLD}${filename}${C_ERROR} not found."
   fi

   RVAL="${candidates}"
}


sde::product::list_main()
{
   log_entry "sde::product::list_main" "$@"

   local OPTION_ALL='YES'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::product::usage
         ;;

         -first-only|--1)
            OPTION_ALL='NO'
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

   local filepaths

   sde::product::r_product_paths "$@"
   filepaths="${RVAL}"

   if [ "${OPTION_ALL}" != 'YES' ]
   then
      sde::product::r_least_recently_changed_file "${filepaths}"
      filepaths="${RVAL}"
   fi

   if [ -z "${filepaths}" ]
   then
      return 0
   fi

   printf "%s\n" "${filepaths}"
}


sde::product::searchpath_main()
{
   log_entry "sde::product::searchpath_main" "$@"

   while [ $# -ne 0 ]
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


sde::product::r_platform_from_executable_path()
{
   log_entry "sde::product::r_platform_from_executable_path" "$@"

   local executable="$1"
   
   # Extract platform from path like kitchen/<platform>/<config>/executable
   # If no platform subdir, assume native
   case "${executable}" in
      */kitchen/*/*)
         # Extract the part after kitchen/
         local after_kitchen="${executable#*/kitchen/}"
         # Get first path component
         local platform="${after_kitchen%%/*}"
         # Check if it's a config name (Debug, Release, etc.) - if so, it's native
         case "${platform}" in
            Debug|Release|Test|RelWithDebInfo)
               RVAL="${MULLE_UNAME}"
            ;;
            *)
               RVAL="${platform}"
            ;;
         esac
      ;;
      *)
         RVAL="${MULLE_UNAME}"
      ;;
   esac
}


sde::product::r_executable()
{
   log_entry "sde::product::r_executable" "$@"

   local preferredname="$1"

   local executables

   sde::product::r_executables "${preferredname}"
   executables="${RVAL}"

   local executable

   if ! sde::product::r_user_choses_executable "${executables}" "${preferredname}"
   then
      return 1
   fi
}



#
# this needs to run outside of the sandbox
#
sde::product::symlink_main()
{
   local OPTION_MODE='SYMLINK'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::product::symlink_usage
         ;;

         --soft|--symlink|--symbolic)
            OPTION_MODE='SYMLINK'
         ;;

         --copy|--install)
            OPTION_MODE='COPY'
         ;;

         --hardlink|--hard|--hard-link)
            OPTION_MODE='HARDLINK'
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

   sde::product::r_executables ""  # unknown "${preferredname}"
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

   local ln_flags
   local linktype

   linktype="hard link"
   ln_flags=
   case "${OPTION_MODE}" in
      'SYMLINK')
            linktype="symlink"
            ln_flags='-s'
      ;;
   esac

   case "${OPTION_MODE}" in
      *'LINK')
         log_info "Create ${linktype} for ${C_MAGENTA}${C_BOLD}${name}${C_INFO} in ${C_RESET_BOLD}${dstdir#${MULLE_USER_PWD}/}"
         exekutor ln ${ln_flags} -f "${executable}" "${linkname}"
         log_verbose "${linkname} -> ${executable}"
      ;;

      *)
         log_info "Install ${C_MAGENTA}${C_BOLD}${name}${C_INFO} in ${C_RESET_BOLD}${dstdir#${MULLE_USER_PWD}/}"
         exekutor install -m 755 "${executable}" "${dstdir}"
      ;;
   esac
}


sde::product::main()
{
   log_entry "sde::product::main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_SDK
   local OPTION_EXISTS
   local OPTION_NAME
   local OPTION_SDE_RUN_ENV='YES'
   local MUDO_FLAGS="-e"

   while [ $# -ne 0 ]
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

         --no-run-env)
            OPTION_SDE_RUN_ENV='NO'
         ;;

         --name)
            [ $# -eq 1 ] && sde::product::usage "Missing argument to \"$1\""
            shift
            OPTION_NAME="$1"
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

   if [ "${OPTION_NAME}" ]
   then
      set -- "${OPTION_NAME}" "$@"
   fi

   case "${cmd}" in
      list)
         sde::product::list_main "$@"
      ;;


      symlink|link|install)
         fail "Use mulle-sde symlink instead, sorry for the inconvenience"
      ;;

      run)
         sde::product::run_main "${OPTION_SDE_RUN_ENV}" "$@"
      ;;

      searchpath)
         sde::product::searchpath_main "$@"
      ;;

      *)
         sde::product::list_main "${cmd}"
      ;;
   esac
}

