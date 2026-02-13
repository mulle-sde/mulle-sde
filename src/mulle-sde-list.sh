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
MULLE_SDE_LIST_SH='included'


sde::list::usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} project list [options]

   List definitions, environment, files, dependencies to give an overview of
   your project.

Tip:
   If the files listed here do not correspond with the output of 
   \`mulle-match list\`, then check the environment for the contents of 
   MULLE_MATCH_FILENAMES, MULLE_MATCH_IGNORE_PATH and MULLE_MATCH_PATH.

Options:
   --all               : list dependencies, definitions, environment, files
   --raw-files         : list only unadorned filenames
   --unmatched-files   : list files that don't match patternfiles with reasons
   --[no-]dependencies : list dependencies
   --[no-]definitions  : list definitions
   --[no-]environment  : list environmnt
   --[no-]files        : list files

EOF
  exit 1
}



sde::list::files()
{
   log_entry "sde::list::files" "$@"

   local mode="${1:-cmake}"

   if [ "${mode}" = 'raw' ]
   then
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_MATCH:-mulle-match}" \
                     list \
                        --format "%f\\n" "$@"
      return $?
   fi

   if [ "${mode}" = 'unmatched' ]
   then
      sde::list::unmatched_files
      return $?
   fi

   local text

   text="`
   # MULLE_TECHNICAL_FLAGS on match is just too much
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_MATCH:-mulle-match}" \
                  list \
                     --format "%t/%c: %f\\n" "$@"

   `"

   log_debug "text: ${text}"

   local types
   local subtext
   local categories
   local type
   local category
   local separator

   separator=''
   types="`rexekutor sed 's|^\([^/]*\).*|\1|' <<< "${text}" | sort -u`"

   log_debug "types: ${types}"
   for type in ${types}
   do
      printf "%s" "${separator}"
      separator=''

      # https://stackoverflow.com/questions/12487424/uppercase-first-character-in-a-variable-with-bash
      log_info "${C_MAGENTA}${C_BOLD}$(tr '[:lower:]' '[:upper:]' <<< ${type:0:1})${type:1}"
      subtext="`rexekutor sed -n "s|^${type}/||p" <<< "${text}" `"
      log_debug "subtext: ${subtext}"

      categories="`rexekutor sed 's|^\([^:]*\).*|\1|' <<< "${subtext}" | sort -u`"
      log_debug "categories: ${categories}"

      for category in ${categories}
      do
         if [ "${MULLE_FLAG_LOG_TERSE}" = 'YES' ]
         then
            rexekutor sed -n "s|^${category}: ||p" <<< "${subtext}"
         else
            printf "%s" "${separator}"
            separator=$'\n'

            case "${mode}" in
               cmake)
                  r_identifier "${category}"
                  r_uppercase "${RVAL}"
                  log_info "   ${RVAL}"
               ;;

               *)
                  log_info "   $(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}"
               ;;
            esac
            rexekutor sed -n "s|^${category}: |      |p" <<< "${subtext}"
         fi
      done
   done
}


sde::list::dependencies()
{
   log_entry "sde::list::dependencies" "$@"

   local text
   local separator

   text="`
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                  list --output-no-header \
                       --output-no-indent \
                       --marks dependency,fs
   `"

   if [ ! -z "${text}" ]
   then
      if [ "${MULLE_FLAG_LOG_TERSE}" = 'YES' ]
      then
         echo "${text}"
      else
         printf "%s" "${separator}"
         separator=$'\n'
         log_info "${C_MAGENTA}${C_BOLD}Dependencies"
         sed 's|^|   |' <<< "${text}"
      fi
   fi
}


sde::list::libraries()
{
   log_entry "sde::list::libraries" "$@"

   local text
   local separator

   text="`
      MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
         exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                     list --output-no-header \
                          --output-no-indent \
                          --marks no-dependency,no-fs
   `"
   if [ ! -z "${text}" ]
   then
      if [ "${MULLE_FLAG_LOG_TERSE}" = 'YES' ]
      then
         echo "${text}"
      else
         printf "%s" "${separator}"
         separator=$'\n'
         log_info "${C_MAGENTA}${C_BOLD}Libraries"
         sed 's|^|   |' <<< "${text}"
      fi
   fi
}



sde::list::definitions()
{
   log_entry "sde::list::definitions" "$@"

   if [ -z "${MULLE_SDE_DEFINITION_SH}" ]
   then
      # shellcheck source=src/mulle-sde-definition.sh
      include "sde::definition"
   fi

   local text

   text="`sde::definition::main --terse --os "${MULLE_UNAME}" list`"
   if [ ! -z "${text}" ]
   then
      log_info "${C_MAGENTA}${C_BOLD}Definitions"
      sed 's|^||' <<< "${text}"
   else
      text="`sde::definition::main --terse --global list`"
      if [ ! -z "${text}" ]
      then
         log_info "${C_MAGENTA}${C_BOLD}Definitions"
         sed 's|^||' <<< "${text}"
      fi
   fi
}


sde::list::environment()
{
   log_entry "sde::list::environment" "$@"

   local text

   text="`mulle-env -s environment list --output-eval `"
   if [ ! -z "${text}" ]
   then
      if [ "${MULLE_FLAG_LOG_TERSE}" = 'YES' ]
      then
         echo "${text}"
      else
         log_info "${C_MAGENTA}${C_BOLD}Environment"
         sed 's|^|   |' <<< "${text}"
      fi
   fi
}


sde::list::unmatched_files()
{
   log_entry "sde::list::unmatched_files" "$@"

   log_info "${C_MAGENTA}${C_BOLD}Unmatched Files Analysis"
   echo

   # Step 1: Get all top-level items (files and directories)
   local all_items
   all_items=$(ls -A1 2>/dev/null | LC_ALL=C sort)

   # Step 2: Get items in MULLE_MATCH_PATH (basenames only)
   local match_items=""
   local item

   .foreachpath item in ${MULLE_MATCH_PATH}
   .do
      # Expand variables
      case "${item}" in
         \$*)
            item=$(eval echo "${item}")
         ;;
      esac

      # Get basename if it's a path
      r_basename "${item}"
      r_add_line "${match_items}" "${RVAL}"
      match_items="${RVAL}"
   .done

   # Step 3: Find not searched items
   local not_searched
   not_searched=$(comm -23 <(echo "${all_items}") <(echo "${match_items}" | LC_ALL=C sort))

   if [ ! -z "${not_searched}" ]
   then
      local count
      count=$(echo "${not_searched}" | grep -c . 2>/dev/null || echo 0)
      log_info "${C_YELLOW}${C_BOLD}Not in MULLE_MATCH_PATH (${count}):"
      echo "${not_searched}" | while IFS= read -r item
      do
         [ -z "${item}" ] && continue
         if [ -d "${item}" ]
         then
            echo "   ${item}/ (directory)"
         else
            echo "   ${item}"
         fi
      done
      echo
   fi

   # Step 4: Now check files within searched paths
   # Get all files from MULLE_MATCH_PATH
   local search_paths=""

   .foreachpath item in ${MULLE_MATCH_PATH}
   .do
      case "${item}" in
         \$*)
            item=$(eval echo "${item}")
         ;;
      esac

      if [ -e "${item}" ]
      then
         r_colon_concat "${search_paths}" "${item}"
         search_paths="${RVAL}"
      fi
   .done

   if [ -z "${search_paths}" ]
   then
      return 0
   fi

   # Get all files in search paths
   local tmpfile_all="/tmp/mulle-sde-all-searchable.$$"
   local tmpfile_matched="/tmp/mulle-sde-matched.$$"

   (
      local path
      local IFS=':'
      for path in ${search_paths}
      do
         if [ -d "${path}" ]
         then
            find "${path}" -type f 2>/dev/null | sed 's|^\./||'
         elif [ -f "${path}" ]
         then
            echo "${path}"
         fi
      done
   ) | LC_ALL=C sort -u > "${tmpfile_all}"

   # Get matched files
   "${MULLE_MATCH:-mulle-match}" list --format "%f\\n" 2>/dev/null | LC_ALL=C sort > "${tmpfile_matched}"

   # Find unmatched within searchable
   local unmatched_searchable
   unmatched_searchable=$(comm -23 "${tmpfile_all}" "${tmpfile_matched}")

   if [ ! -z "${unmatched_searchable}" ]
   then
      # Classify these files
      local extension_filtered=""
      local actively_ignored=""
      local no_match=""
      local file
      local basename
      local matched_pattern

      while IFS= read -r file
      do
         [ -z "${file}" ] && continue

         # Check if matches MULLE_MATCH_FILENAMES
         r_basename "${file}"
         basename="${RVAL}"
         matched_pattern='NO'

         if [ -z "${MULLE_MATCH_FILENAMES}" ]
         then
            matched_pattern='YES'
         else
            shell_disable_glob
            local pattern
            .foreachpath pattern in ${MULLE_MATCH_FILENAMES}
            .do
               if [[ "${basename}" == ${pattern} ]]
               then
                  matched_pattern='YES'
                  .break
               fi
            .done
            shell_enable_glob
         fi

         if [ "${matched_pattern}" = 'NO' ]
         then
            r_add_line "${extension_filtered}" "${file}"
            extension_filtered="${RVAL}"
         else
            # Check if actively ignored by patternfile
            if ! "${MULLE_MATCH:-mulle-match}" filename "${file}" >/dev/null 2>&1
            then
               r_add_line "${actively_ignored}" "${file}"
               actively_ignored="${RVAL}"
            else
               r_add_line "${no_match}" "${file}"
               no_match="${RVAL}"
            fi
         fi
      done <<< "${unmatched_searchable}"

      # Display extension filtered
      if [ ! -z "${extension_filtered}" ]
      then
         local count
         count=$(echo "${extension_filtered}" | grep -c . 2>/dev/null || echo 0)
         log_info "${C_YELLOW}${C_BOLD}Not in MULLE_MATCH_FILENAMES (${count}):"
         echo "${extension_filtered}" | while IFS= read -r file
         do
            [ -z "${file}" ] && continue
            echo "   ${file}"
         done
         echo
      fi

      # Display actively ignored
      if [ ! -z "${actively_ignored}" ]
      then
         local count
         count=$(echo "${actively_ignored}" | grep -c . 2>/dev/null || echo 0)
         log_info "${C_YELLOW}${C_BOLD}Actively ignored by patternfile (${count}):"
         echo "${actively_ignored}" | while IFS= read -r file
         do
            [ -z "${file}" ] && continue
            echo "   ${file}"
         done
         echo
      fi

      # Display no patternfile match
      if [ ! -z "${no_match}" ]
      then
         local count
         count=$(echo "${no_match}" | grep -c . 2>/dev/null || echo 0)
         log_info "${C_YELLOW}${C_BOLD}No patternfile match (${count}):"
         echo "${no_match}" | while IFS= read -r file
         do
            [ -z "${file}" ] && continue
            echo "   ${file}"
         done
         echo
      fi
   fi

   rm -f "${tmpfile_all}" "${tmpfile_matched}"
}


sde::list::main()
{
   log_entry "sde::list::main" "$@"

   local OPTION_LIST_DEFINITIONS='DEFAULT'
   local OPTION_LIST_DEPENDENCIES='DEFAULT'
   local OPTION_LIST_ENVIRONMENT='DEFAULT'
   local OPTION_LIST_FILES='DEFAULT'
   local OPTION_LIST_LIBRARIES='DEFAULT'
   local OPTION_RAW_FILES=''
   local OPTION_UNMATCHED_FILES='NO'

   local spacer

   spacer=":"  # nop

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::list::usage
         ;;

         --all)
            OPTION_LIST_DEFINITIONS='YES'
            OPTION_LIST_DEPENDENCIES='YES'
            OPTION_LIST_ENVIRONMENT='YES'
            OPTION_LIST_FILES='YES'
            OPTION_LIST_LIBRARIES='YES'
         ;;

         --raw-files)
            OPTION_RAW_FILES='raw'
         ;;

         -u|--unmatched|--unmatched-files)
            OPTION_UNMATCHED_FILES='YES'
            OPTION_LIST_FILES='YES'
         ;;

         --dependencies)
            OPTION_LIST_DEPENDENCIES='YES'
         ;;

         --no-dependencies)
            OPTION_LIST_DEPENDENCIES='NO'
         ;;

         --libraries)
            OPTION_LIST_LIBRARIES='YES'
         ;;

         --no-libraries)
            OPTION_LIST_LIBRARIES='NO'
         ;;

         --files)
            OPTION_LIST_FILES='YES'
         ;;

         --no-files)
            OPTION_LIST_FILES='NO'
         ;;

         --definitions)
            OPTION_LIST_DEFINITIONS='YES'
         ;;

         --no-definitions)
            OPTION_LIST_DEFINITIONS='NO'
         ;;

         --environment)
            OPTION_LIST_ENVIRONMENT='YES'
         ;;

         --no-environment)
            OPTION_LIST_ENVIRONMENT='NO'
         ;;

         -*)
            sde::list::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && sde::list::usage "Superflous arguments $*"

   if [ "${OPTION_LIST_DEFINITIONS}" = 'DEFAULT' -a \
        "${OPTION_LIST_DEPENDENCIES}" = 'DEFAULT' -a \
        "${OPTION_LIST_ENVIRONMENT}" = 'DEFAULT' -a \
        "${OPTION_LIST_FILES}" = 'DEFAULT' -a \
        "${OPTION_LIST_LIBRARIES}" = 'DEFAULT' \
      ]
   then
      OPTION_LIST_FILES='YES'
   fi

   if [ "${OPTION_LIST_FILES}" = 'YES' ]
   then
      if [ "${PROJECT_TYPE}" != 'none' -o "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         if [ "${OPTION_UNMATCHED_FILES}" = 'YES' ]
         then
            sde::list::files 'unmatched'
         else
            sde::list::files "${OPTION_RAW_FILES}"
         fi
         spacer="echo"
      else
         log_warning "No files listed in \"none\" projects.
${C_INFO}Use -f flag to force listing"
      fi
   fi

   if [ "${OPTION_LIST_DEPENDENCIES}" = 'YES' ]
   then
      eval "${spacer}"
      sde::list::dependencies
      spacer="echo"
   fi

   if [ "${OPTION_LIST_LIBRARRIES}" = 'YES' ]
   then
      eval "${spacer}"
      sde::list::libraries
      spacer="echo"
   fi

   if [ "${OPTION_LIST_DEFINITIONS}" = 'YES' ]
   then
      eval "${spacer}"
      sde::list::definitions
      spacer="echo"
   fi

   if [ "${OPTION_LIST_ENVIRONMENT}" = 'YES' ]
   then
      eval "${spacer}"
      sde::list::environment
      spacer="echo"
   fi
}
