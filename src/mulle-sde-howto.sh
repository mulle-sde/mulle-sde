# shellcheck shell=bash
#
#   Copyright (c) 2025 Nat! - Mulle kybernetiK
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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_HOWTO_SH='included'


sde::howto::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto [cmd]

   Show HOWTOs for developent topics. AI friendly! HOWTOs for dependencies
   appear only after a successful \`mulle-sde craft\`.

   See also: mulle-sde api for API docs

Examples:
      mulle-sde howto list              # List howtos in current directory
      cd test && mulle-sde howto list   # List test-specific howtos
      mulle-sde howto show leaks
      mulle-sde howto show 2
      mulle-sde howto show --keyword leak --keyword sanitizer
      mulle-sde howto keywords
      mulle-sde howto grep sanitizer

Commands:
      list       : list available howto topics (default)
      show       : show howto file by number or filename
      keywords   : list all keywords from all howto files
      grep       : search for pattern in all howto files

   Use 'mulle-sde howto <cmd> --help' for command-specific help.

EOF
   exit 1
}


sde::howto::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto list [options] [keyword]

   List available howto topics, optionally filtered by keyword.
   By default, shows keywords for each topic.

Options:
      --no-keywords  : hide keywords column

Examples:
      mulle-sde howto list
      mulle-sde howto list --no-keywords
      mulle-sde howto list leak

EOF
   exit 1
}


sde::howto::show_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto show [options] <topic>

   Show howto file by number, exact filename, or partial filename match.

Options:
      --keyword <word>  : treat as keyword search, show all matching howtos
                          (can be specified multiple times, all must match)

Examples:
      mulle-sde howto show 2                    # Show by number
      mulle-sde howto show leaks                # Exact or fuzzy match on filename
      mulle-sde howto show leak-checking        # Partial match works too
      mulle-sde howto show --keyword leak --keyword sanitizer

EOF
   exit 1
}


sde::howto::keywords_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto keywords

   List all unique keywords from all howto files.

EOF
   exit 1
}


sde::howto::grep_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto grep <pattern>

   Search for pattern (case insensitive) in all howto files.
   Shows filename and line number for matches.

Examples:
      mulle-sde howto grep sanitizer
      mulle-sde howto grep "memory leak"

EOF
   exit 1
}


#
# Howtos are installed by extensions into share/howto/
# local howtos are created in assets/howto/
# howtos are also available via dependencies as ${DEPENDENCY_DIR}/.../share/${name}/howto
# similiar to how dependency toc works
#
# So we gather these in a predictable way and give them numbers
#
#
# Extract keywords from a howto file's HTML comment
# Returns keywords in RVAL as comma-separated string
#
sde::howto::r_extract_keywords()
{
   local file="$1"
   
   RVAL=""
   
   # Look for keywords comment line: <!-- keywords: word1, word2, word3 -->
   local keywords_line
   keywords_line="$(grep -i '^<!--[[:space:]]*[Kk]eywords:' "${file}" 2>/dev/null | head -n 1)"
   
   if [ ! -z "${keywords_line}" ]
   then
      # Extract keywords between "keywords:" and "-->"
      keywords_line="${keywords_line#*eywords:}"
      keywords_line="${keywords_line%-->*}"
      
      # Trim whitespace
      RVAL="$(echo "${keywords_line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
   fi
}


#
# Helper function to check if file matches keyword
# Checks filename, title (first line), and keywords comment (second line)
#
sde::howto::r_matches_keyword()
{
   local file="$1"
   local keyword="$2"
   
   if [ -z "${keyword}" ]
   then
      return 0  # No keyword means match all
   fi
   
   # Check filename
   r_basename "${file}"
   if grep -q -i "${keyword}" <<< "${RVAL}"
   then
      return 0
   fi
   
   # Check first two lines (title and keywords comment)
   local first_two_lines
   first_two_lines="$(head -n 2 "${file}" 2>/dev/null)"
   
   if grep -q -i "${keyword}" <<< "${first_two_lines}"
   then
      return 0
   fi
   
   return 1
}


#
# Collect all howtos in predictable order
# Parameters:
#   $1 - optional keyword filter
#   $2 - 'YES' to display, 'NO' to just collect
# Returns howtos in RVAL
#
sde::howto::r_collect_howtos()
{
   log_entry "sde::howto::r_collect_howtos" "$@"

   local keyword="$1"
   local display="${2:-NO}"
   local show_keywords="${3:-NO}"
   
   log_debug "keyword: '${keyword}'"
   log_debug "display: '${display}'"
   log_debug "show_keywords: '${show_keywords}'"
   
   local howtos
   local howto
   local count=0
   local name
   local keywords_str
   local use_etc='NO'
   local global_use_etc='NO'
   local reponame

   shell_enable_nullglob
   
   # Collect from global ~/.mulle/etc/howto (global user overrides)
   log_debug "Checking ~/.mulle/etc/howto"
   if [ -d "${HOME}/.mulle/etc/howto" ]
   then
      global_use_etc='YES'
      log_debug "Found ~/.mulle/etc/howto"
      for howto in "${HOME}"/.mulle/etc/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"
            
            if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
            then
               r_basename "${howto}"
               r_extensionless_basename "${RVAL}"
               name="${RVAL}"
               
               if [ "${show_keywords}" = 'YES' ]
               then
                  sde::howto::r_extract_keywords "${howto}"
                  keywords_str="${RVAL}"
                  if [ ! -z "${keywords_str}" ]
                  then
                     printf "%2d. %-30s [%s] (global)\n" "${count}" "${name}" "${keywords_str}"
                  else
                     printf "%2d. %-30s (global)\n" "${count}" "${name}"
                  fi
               else
                  printf "%2d. %-30s (global)\n" "${count}" "${name}"
               fi
            fi
            
            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug "~/.mulle/etc/howto does not exist"
   fi
   
   # Collect from global ~/.mulle/share/howto (global installed)
   log_debug "global_use_etc=${global_use_etc}"
   log_debug "Checking ~/.mulle/share/howto"
   if [ "${global_use_etc}" = 'NO' ] && [ -d "${HOME}/.mulle/share/howto" ]
   then
      log_debug "Found ~/.mulle/share/howto"
      for howto in "${HOME}"/.mulle/share/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"
            
            if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
            then
               r_basename "${howto}"
               r_extensionless_basename "${RVAL}"
               name="${RVAL}"
               
               if [ "${show_keywords}" = 'YES' ]
               then
                  sde::howto::r_extract_keywords "${howto}"
                  keywords_str="${RVAL}"
                  if [ ! -z "${keywords_str}" ]
                  then
                     printf "%2d. %-30s [%s] (global)\n" "${count}" "${name}" "${keywords_str}"
                  else
                     printf "%2d. %-30s (global)\n" "${count}" "${name}"
                  fi
               else
                  printf "%2d. %-30s (global)\n" "${count}" "${name}"
               fi
            fi
            
            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug "~/.mulle/share/howto does not exist or global_use_etc='YES'"
   fi
   
   # Collect from .mulle/etc/howto (local overrides)
   log_debug "Checking .mulle/etc/howto"
   if [ -d ".mulle/etc/howto" ]
   then
      use_etc='YES'
      log_debug "Found .mulle/etc/howto, using etc instead of share"
      for howto in .mulle/etc/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"
            
            if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
            then
               r_basename "${howto}"
               r_extensionless_basename "${RVAL}"
               name="${RVAL}"
               
               if [ "${show_keywords}" = 'YES' ]
               then
                  sde::howto::r_extract_keywords "${howto}"
                  keywords_str="${RVAL}"
                  if [ ! -z "${keywords_str}" ]
                  then
                     printf "%2d. %-30s [%s] (local)\n" "${count}" "${name}" "${keywords_str}"
                  else
                     printf "%2d. %-30s (local)\n" "${count}" "${name}"
                  fi
               else
                  printf "%2d. %-30s (local)\n" "${count}" "${name}"
               fi
            fi
            
            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug ".mulle/etc/howto does not exist"
   fi
   
   # Collect from .mulle/share/howto (installed by extensions)
   log_debug "use_etc=${use_etc}"
   log_debug "Checking .mulle/share/howto"
   if [ "${use_etc}" = 'NO' ] && [ -d ".mulle/share/howto" ]
   then
      log_debug "Found .mulle/share/howto"
      for howto in .mulle/share/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"
            
            if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
            then
               r_basename "${howto}"
               r_extensionless_basename "${RVAL}"
               name="${RVAL}"
               
               if [ "${show_keywords}" = 'YES' ]
               then
                  sde::howto::r_extract_keywords "${howto}"
                  keywords_str="${RVAL}"
                  if [ ! -z "${keywords_str}" ]
                  then
                     printf "%2d. %-30s [%s] (extension)\n" "${count}" "${name}" "${keywords_str}"
                  else
                     printf "%2d. %-30s (extension)\n" "${count}" "${name}"
                  fi
               else
                  printf "%2d. %-30s (extension)\n" "${count}" "${name}"
               fi
            fi
            
            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug ".mulle/share/howto does not exist or use_etc='YES'"
   fi
   
   # Collect from assets/howto/ (local project)
   log_debug "Checking assets/howto"

   local seen_basenames=""

   if [ -d "assets/howto" ]
   then
      log_debug "Found assets/howto"
      local xtrace_was_set='NO'
      case $- in
         *x*) xtrace_was_set='YES' ; set +x ;;
      esac

      for howto in assets/howto/*.md
      do
         [ "${xtrace_was_set}" = 'YES' ] && set -x
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            # Track basename for deduplication
            r_basename "${howto}"
            r_extensionless_basename "${RVAL}"
            name="${RVAL}"
            r_add_line "${seen_basenames}" "${name}"
            seen_basenames="${RVAL}"

            count=$((count + 1))
            log_debug "File exists, count=${count}"

            if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
            then
               if [ "${show_keywords}" = 'YES' ]
               then
                  sde::howto::r_extract_keywords "${howto}"
                  keywords_str="${RVAL}"
                  if [ ! -z "${keywords_str}" ]
                  then
                     printf "%2d. %-30s [%s] (local)\n" "${count}" "${name}" "${keywords_str}"
                  else
                     printf "%2d. %-30s (local)\n" "${count}" "${name}"
                  fi
               else
                  printf "%2d. %-30s (local)\n" "${count}" "${name}"
               fi
            fi
            
            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
         [ "${xtrace_was_set}" = 'YES' ] && set +x
      done
      [ "${xtrace_was_set}" = 'YES' ] && set -x
   else
      log_debug "assets/howto does not exist"
   fi

   # Build seen_basenames from all collected howtos so far
   local basename

   .foreachpath howto in ${howtos}
   .do
      r_basename "${howto}"
      r_extensionless_basename "${RVAL}"
      basename="${RVAL}"

      if ! find_line "${seen_basenames}" "${basename}"
      then
         r_add_line "${seen_basenames}" "${basename}"
         seen_basenames="${RVAL}"
      fi
   .done

   # Collect from subdirectories (demo, test, and MULLE_SDE_TEST_PATH)
   log_debug "Checking subdirectories for howtos"

   local subdirs="demo:test"

   if [ ! -z "${MULLE_SDE_TEST_PATH}" ]
   then
      r_colon_concat "${subdirs}" "${MULLE_SDE_TEST_PATH}"
      subdirs="${RVAL}"
   fi

   local subdir
   local subdir_name

   .foreachpath subdir in ${subdirs}
   .do
      log_debug "Checking subdir: ${subdir}"
      if [ -d "${subdir}" ]
      then
         log_debug "Found ${subdir}"
         # Check if either directory exists before globbing to avoid zsh errors
         if [ -d "${subdir}/.mulle/share/howto" ] || [ -d "${subdir}/.mulle/etc/howto" ]
         then
            for howto in "${subdir}"/.mulle/share/howto/*.md "${subdir}"/.mulle/etc/howto/*.md
            do
               log_debug "Checking file: ${howto}"
               if [ -f "${howto}" ]
               then
                  r_basename "${howto}"
                  r_extensionless_basename "${RVAL}"
                  basename="${RVAL}"

                  # Skip if we already have this basename
                  if ! find_line "${seen_basenames}" "${basename}"
                  then
                     count=$((count + 1))
                     log_debug "File exists, count=${count}"
                     r_add_line "${seen_basenames}" "${basename}"
                     seen_basenames="${RVAL}"

                     if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
                     then
                        r_basename "${subdir}"
                        subdir_name="${RVAL}"

                        if [ "${show_keywords}" = 'YES' ]
                        then
                           sde::howto::r_extract_keywords "${howto}"
                           keywords_str="${RVAL}"
                           if [ ! -z "${keywords_str}" ]
                           then
                              printf "%2d. %-30s [%s]\n" "${count}" "${subdir_name}/${basename}" "${keywords_str}"
                           else
                              printf "%2d. %-30s\n" "${count}" "${subdir_name}/${basename}"
                           fi
                        else
                           printf "%2d. %-30s\n" "${count}" "${subdir_name}/${basename}"
                        fi
                     fi

                     r_colon_concat "${howtos}" "${howto}"
                     howtos="${RVAL}"
                  fi
               fi
            done
         fi
      fi
   .done

   
   # Collect from dependencies
   log_debug "Getting dependency-dir"
   local dependency_dir
   
   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true
   
   log_debug "dependency_dir='${dependency_dir}'"
   
   if [ ! -z "${dependency_dir}" ] && [ -d "${dependency_dir}" ]
   then
      log_debug "Searching dependencies in ${dependency_dir}"
      local searchpath=':Release:Debug:RelDebug'
      local repo
      
      .foreachpath subdir in ${searchpath}
      .do
         log_debug "Checking ${dependency_dir}/${subdir}/share"
         if [ -d "${dependency_dir}/${subdir}/share" ]
         then
            for repo in "${dependency_dir}/${subdir}/share"/*
            do
               log_debug "Checking repo: ${repo}"
               if [ -d "${repo}/howto" ]
               then
                  log_debug "Found ${repo}/howto"
                  for howto in "${repo}/howto"/*.md
                  do
                     log_debug "Checking file: ${howto}"
                     if [ -f "${howto}" ]
                     then
                        count=$((count + 1))
                        log_debug "File exists, count=${count}"
                        
                        if [ "${display}" = 'YES' ] && sde::howto::r_matches_keyword "${howto}" "${keyword}"
                        then
                           r_basename "${howto}"
                           r_extensionless_basename "${RVAL}"
                           name="${RVAL}"
                           
                           r_basename "${repo}"
                           reponame="${RVAL}"
                           
                           if [ "${show_keywords}" = 'YES' ]
                           then
                              sde::howto::r_extract_keywords "${howto}"
                              keywords_str="${RVAL}"
                              if [ ! -z "${keywords_str}" ]
                              then
                                 printf "%2d. %-30s [%s] (${reponame})\n" "${count}" "${name}" "${keywords_str}"
                              else
                                 printf "%2d. %-30s (${reponame})\n" "${count}" "${name}"
                              fi
                           else
                              printf "%2d. %-30s (${reponame})\n" "${count}" "${name}"
                           fi
                        fi
                        
                        r_colon_concat "${howtos}" "${howto}"
                        howtos="${RVAL}"
                     fi
                  done
               fi
            done
         fi
      .done
   else
      log_debug "No dependency_dir or doesn't exist"
   fi

   shell_disable_nullglob
   
   log_debug "Total count: ${count}"
   log_debug "Collected howtos: ${howtos}"
   
   # Sort howtos for consistent ordering
   local sorted_howtos
   if [ ! -z "${howtos}" ]
   then
      # Convert colon-separated to newline-separated, sort, then back to colon-separated
      sorted_howtos="$(echo "${howtos}" | tr ':' '\n' | sort | tr '\n' ':')"
      # Remove trailing colon
      sorted_howtos="${sorted_howtos%:}"
   fi
   
   RVAL="${sorted_howtos}"
   return ${count}
}


sde::howto::list()
{
   log_entry "sde::howto::list" "$@"

   local keyword
   local show_keywords='YES'
   
   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::list_usage
         ;;

         --no-keywords)
            show_keywords='NO'
         ;;
         
         -*)
            sde::howto::list_usage "Unknown option $1"
         ;;
         
         *)
            keyword="$1"
         ;;
      esac
      shift
   done
   
   # Show current directory context
   local pwd_basename
   r_basename "${PWD}"
   pwd_basename="${RVAL}"
   
   log_info "Howtos"
   
   # as we are not immediately running in a subshell
   # DEPENDENCY_DIR might not be available though, so that's not an error
   # we just skip that
   
   sde::howto::r_collect_howtos "${keyword}" 'YES' "${show_keywords}"
   local count=$?
   
   # Check if we should suggest crafting
   local dependency_dir
   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true
   
   if [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ]
   then
      # Check if we have a sourcetree (in either etc or share)
      if [ -d ".mulle/etc/sourcetree" ] || [ -d ".mulle/share/sourcetree" ]
      then
         log_warning "Dependencies not yet crafted. Run 'mulle-sde craft' to get howtos from dependencies."
      fi
   fi
   
   if [ ${count} -eq 0 ]
   then
      if [ ! -z "${keyword}" ]
      then
         fail "No howto files found matching '${keyword}'"
      fi
      log_info "No howto files found"
   fi

   
   return 0
}


sde::howto::keywords()
{
   log_entry "sde::howto::keywords" "$@"
   
   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::keywords_usage
         ;;

         -*)
            sde::howto::keywords_usage "Unknown option $1"
         ;;
         
         *)
            sde::howto::keywords_usage "Unexpected argument $1"
         ;;
      esac
      shift
   done
   
   # Collect all howtos silently
   sde::howto::r_collect_howtos "" 'NO'
   local count=$?
   local howtos="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      log_info "No howto files found"
      return 1
   fi
   
   # Collect all keywords
   local all_keywords
   local howto
   
   .foreachpath howto in ${howtos}
   .do
      # Look for keywords comment line: <!-- keywords: word1 word2 word3 -->
      local keywords_line
      keywords_line="$(grep -i '^<!--[[:space:]]*[Kk]eywords:' "${howto}" 2>/dev/null | head -n 1)"
      
      if [ ! -z "${keywords_line}" ]
      then
         # Extract keywords between "keywords:" and "-->"
         # Remove <!-- and --> using case-insensitive pattern
         keywords_line="${keywords_line#*eywords:}"
         keywords_line="${keywords_line%-->*}"
         
         # Trim whitespace and add to collection
         keywords_line="$(echo "${keywords_line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
         
         if [ ! -z "${keywords_line}" ]
         then
            r_concat "${all_keywords}" "${keywords_line}"
            all_keywords="${RVAL}"
         fi
      fi
   .done
   
   if [ -z "${all_keywords}" ]
   then
      log_info "No keywords found in howto files"
      return 0
   fi
   
   # Split by spaces and commas, sort unique
   echo "${all_keywords}" | tr ' ,' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sort -u
   
   return 0
}


sde::howto::grep()
{
   log_entry "sde::howto::grep" "$@"
   
   local pattern
   
   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::grep_usage
         ;;

         -*)
            sde::howto::grep_usage "Unknown option $1"
         ;;
         
         *)
            [ ! -z "${pattern}" ] && sde::howto::grep_usage "Too many arguments"
            pattern="$1"
         ;;
      esac
      shift
   done
   
   [ -z "${pattern}" ] && sde::howto::grep_usage "Missing pattern for grep"
   
   # Collect all howtos silently
   sde::howto::r_collect_howtos "" 'NO'
   local count=$?
   local howtos="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      log_info "No howto files found"
      return 1
   fi
   
   # Grep through all files with line numbers
   local howto
   local found='NO'
   
   .foreachpath howto in ${howtos}
   .do
      # grep with -n for line numbers, -H for filename
      if rexekutor grep -n -H -i "${pattern}" "${howto}" 2>/dev/null
      then
         found='YES'
      fi
   .done
   
   if [ "${found}" = 'NO' ]
   then
      log_info "No matches found for '${pattern}'"
      return 1
   fi
   
   return 0
}


sde::howto::show()
{
   log_entry "sde::howto::show" "$@"

   local OPTION_KEYWORDS
   
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::show_usage
         ;;

         --keyword)
            shift
            [ $# -eq 0 ] && sde::howto::show_usage "Missing value for --keyword"
            r_comma_concat "${OPTION_KEYWORDS}" "$1"
            OPTION_KEYWORDS="${RVAL}"
         ;;

         -*)
            sde::howto::show_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local identifier="$1"
   
   # If keywords specified, use those instead of identifier
   if [ ! -z "${OPTION_KEYWORDS}" ]
   then
      identifier="${OPTION_KEYWORDS}"
   else
      [ -z "${identifier}" ] && sde::howto::show_usage "Missing argument (number or filename)"
   fi
   
   # Collect all howtos silently
   sde::howto::r_collect_howtos "" 'NO'
   local count=$?
   local howtos="${RVAL}"
   
   # If keywords specified, show all matching files
   if [ ! -z "${OPTION_KEYWORDS}" ]
   then
      local found='NO'
      local howto
      local keyword
      local all_match
      
      .foreachpath howto in ${howtos}
      .do
         all_match='YES'
         
         # Check if ALL keywords match (in filename OR first two lines)
         .foreachitem keyword in ${OPTION_KEYWORDS}
         .do
            # Check if this keyword matches filename, title, or keywords comment
            r_basename "${howto}"
            if ! grep -q -i "${keyword}" <<< "${RVAL}"
            then
               # Didn't match filename, check first two lines
               local first_two_lines
               first_two_lines="$(head -n 2 "${howto}" 2>/dev/null)"
               
               if ! grep -q -i "${keyword}" <<< "${first_two_lines}"
               then
                  # This keyword didn't match anywhere
                  all_match='NO'
                  .break
               fi
            fi
         .done
         
         # If all keywords matched, show this file
         if [ "${all_match}" = 'YES' ]
         then
            rexekutor grep -v '^<!--' "${howto}"
            echo ""  # Blank line between multiple results
            found='YES'
         fi
      .done
      
      if [ "${found}" = 'NO' ]
      then
         fail "No howto matching all keywords found"
      fi
      
      return 0
   fi
   
   # Normal mode: find by number or exact filename
   local found='NO'
   local index=0
   local howto
   
   # Check if identifier is a number
   case "${identifier}" in
      [0-9]*)
         # It's a number - find by index
         .foreachpath howto in ${howtos}
         .do
            index=$((index + 1))
            if [ ${index} -eq ${identifier} ]
            then
               rexekutor grep -v '^<!--' "${howto}"
               found='YES'
               .break
            fi
         .done
      ;;
      
      *)
         # It's a filename - try exact match first, then fuzzy match
         # Check if it's in subdir/name format
         case "${identifier}" in
            */*)
               # Has slash - look for specific subdir/name
               local subdir_part="${identifier%/*}"
               local name_part="${identifier#*/}"

               .foreachpath howto in ${howtos}
               .do
                  # Check if this howto is from the specified subdir and has the right name
                  if [[ "${howto}" == "${subdir_part}/"* ]]
                  then
                     r_basename "${howto}"
                     r_extensionless_basename "${RVAL}"
                     local name="${RVAL}"

                     if [ "${name}" = "${name_part}" ]
                     then
                        rexekutor grep -v '^<!--' "${howto}"
                        found='YES'
                        .break
                     fi
                  fi
               .done
            ;;
            
            *)
               # No slash - try exact match on basename first
               .foreachpath howto in ${howtos}
               .do
                  r_basename "${howto}"
                  r_extensionless_basename "${RVAL}"
                  local name="${RVAL}"

                  # Try exact match first
                  if [ "${name}" = "${identifier}" ]
                  then
                     rexekutor grep -v '^<!--' "${howto}"
                     found='YES'
                     .break
                  fi
               .done
               
               # If no exact match, try fuzzy match (substring)
               if [ "${found}" = 'NO' ]
               then
                  .foreachpath howto in ${howtos}
                  .do
                     r_basename "${howto}"
                     r_extensionless_basename "${RVAL}"
                     local name="${RVAL}"

                     # Check if identifier is contained in filename
                     if grep -q -i "${identifier}" <<< "${name}"
                     then
                        rexekutor grep -v '^<!--' "${howto}"
                        found='YES'
                        .break
                     fi
                  .done
               fi
            ;;
         esac
      ;;
   esac
   
   if [ "${found}" = 'NO' ]
   then
      case "${identifier}" in
         [0-9]*)
            fail "No howto with number ${identifier} found (total: ${count})"
         ;;
         *)
            fail "No howto named '${identifier}' found"
         ;;
      esac
   fi
}


sde::howto::main()
{
   log_entry "sde::howto::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::usage
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::howto::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="list"

   if [ $# -ne 0 ]
   then
      cmd="$1"
      shift
   fi

   case "${cmd}" in
      'help')
         sde::howto::usage
      ;;

      'list')
         sde::howto::list "$@"
      ;;

      'show'|'cat')
         sde::howto::show "$@"
      ;;
      
      'keywords')
         sde::howto::keywords "$@"
      ;;
      
      'grep')
         sde::howto::grep "$@"
      ;;
      
      *)
         sde::howto::usage "Unknown command '${cmd}'"
      ;;
   esac
}
