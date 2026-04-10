#! /usr/bin/env bash
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
MULLE_SDE_API_SH="included"


sde::api::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} api <cmd>

   Show API documentation (TOC.md files) from dependencies. AI friendly!

Examples:
      mulle-sde api list
      mulle-sde api cat mulle-core
      mulle-sde api apropos "how do I allocate memory?"

Commands:
      list               : list available API documentation from dependencies
      cat <name>         : show API doc by number or dependency name
      context            : dump all API docs to stdout (pipe to AI tool)
      apropos <question> : keyword search through API docs

   For code search use: ${MULLE_USAGE_NAME} code

List options:
      --all          : show all dependencies (default in vibecoding mode)
      --flat         : show only top-level dependencies (default otherwise)
      
EOF
   exit 1
}


sde::api::apropos_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} api apropos [options] <question>

   Search through dependency API docs (TOC.md files) for relevant APIs using
   keyword matching. If MULLE_SDE_AI_LOCAL is set, the question is passed to
   an AI wrapper with API docs as context instead.

   For source code search use: ${MULLE_USAGE_NAME} code search

Options:
   --json    : output structured JSON (default when MULLE_VIBECODING=YES)
   --no-json : force plain text output

Examples:
   ${MULLE_USAGE_NAME} api apropos "allocate memory"
   ${MULLE_USAGE_NAME} api apropos --json "container API"

Environment:
   MULLE_SDE_AI_LOCAL : path to AI wrapper script
   MULLE_VIBECODING   : set to YES to default to JSON output

EOF
   exit 1
}


#
# Helper function to ensure dependencies are crafted if in vibecoding mode
# Returns 0 if dependencies are available or were successfully crafted
# Returns 1 if dependencies could not be built
#
sde::api::ensure_dependencies_crafted()
{
   log_entry "sde::api::ensure_dependencies_crafted" "$@"

   local purpose="${1:-API information}"

   # Only auto-craft in vibecoding mode
   if [ "${MULLE_VIBECODING}" != 'YES' ]
   then
      return 0
   fi

   # Check if dependencies are already built
   local state

   state="$(rexekutor ${MULLE_TECHNICAL_FLAGS:--s} quickstatus -p 2>/dev/null)" || state=""

   if [ "${state}" = "complete" ]
   then
      log_debug "Dependencies already crafted"
      return 0
   fi

   # Dependencies not complete, try to craft
   log_info "Crafting dependencies to get ${purpose}..."

   # Capture exit code to prevent error cascade
   local rc

   rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS:--s} -DMULLE_VIBECODING=NO craft --no-clean craftorder
   rc=$?

   if [ $rc -ne 0 ]
   then
      log_warning "Failed to craft dependencies"
   fi

   return 0  # Always succeed, we'll show what we have
}


#
# Collect API documentation from dependencies
# API docs are in share/<name>/dox/TOC.md or share/<name>/TOC.md
# Returns list of paths in RVAL and count as return code
#
sde::api::r_extract_keywords()
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


sde::api::r_collect_apis()
{
   log_entry "sde::api::r_collect_apis" "$@"
   
   local display="${1:-NO}"

   # If in test directory, always delegate to parent - APIs live in main project
   if sde::is_test_directory "${PWD}"
   then
      log_debug "In test directory, moving to parent for APIs"
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      
      (cd "${parent_dir}" 2>/dev/null && sde::api::r_collect_apis "${display}")
      return $?
   fi
   
   log_debug "display: '${display}'"
   
   local apis
   local count=0
   local dependency_dir

   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true

   log_debug "dependency_dir='${dependency_dir}'"

   if [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ]
   then
      log_debug "No dependency_dir or doesn't exist"
      RVAL=""
      return 0
   fi

   local platforms
   local searchpath=':Release:Debug:RelDebug'
   local subdir
   local repo
   local api
   local keywords_str
   local seen_repos
   local search_dir
   local reponame

   # Check if we have platform-specific directories
   platforms="$(rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS 2>/dev/null)" || true

   log_debug "platforms='${platforms}'"
   log_debug "searchpath='${searchpath}'"

   # Build list of platform directories to check (platform subdirs + root)
   local platform_dirs=":"  # Always check root (no platform subdir)

   if [ ! -z "${platforms}" ]
   then
      local platform
      for platform in ${platforms}
      do
         # Only add platform dir if it actually exists
         if [ -d "${dependency_dir}/${platform}" ]
         then
            r_colon_concat "${platform_dirs}" "${platform}"
            platform_dirs="${RVAL}"
            log_debug "Found platform directory: ${platform}"
         fi
      done
   fi
   
   log_debug "platform_dirs='${platform_dirs}'"

   .foreachpath platform_dir in ${platform_dirs}
   .do
      .foreachpath subdir in ${searchpath}
      .do
         if [ -z "${platform_dir}" ]
         then
            search_dir="${dependency_dir}/${subdir}/share"
         else
            search_dir="${dependency_dir}/${platform_dir}/${subdir}/share"
         fi

         log_debug "Checking ${search_dir}"
         if [ -d "${search_dir}" ]
         then
            shell_enable_nullglob
            for repo in "${search_dir}"/*
            do
               shell_disable_nullglob
               [ -e "${repo}" ] || continue
               log_debug "Checking repo: ${repo}"
               if [ -d "${repo}" ]
               then
                  r_basename "${repo}"
                  reponame="${RVAL}"
                  
                  if ! find_line "${seen_repos}" "${reponame}"
                  then
                     r_add_line "${seen_repos}" "${reponame}"
                     seen_repos="${RVAL}"

                     # Try share/<name>/dox/TOC.md first
                     api="${repo}/dox/TOC.md"
                     if [ -f "${api}" ]
                     then
                        count=$((count + 1))
                        log_debug "Found ${api}, count=${count}"

                        if [ "${display}" = 'YES' ]
                        then
                           sde::api::r_extract_keywords "${api}"
                           keywords_str="${RVAL}"
                           if [ ! -z "${keywords_str}" ]
                           then
                              printf "%2d. %-30s [%s]\n" "${count}" "${reponame}" "${keywords_str}"
                           else
                              printf "%2d. %-30s\n" "${count}" "${reponame}"
                           fi
                        fi

                        r_colon_concat "${apis}" "${api}"
                        apis="${RVAL}"
                        continue
                     fi

                     # Try share/<name>/TOC.md as fallback
                     api="${repo}/TOC.md"
                     if [ -f "${api}" ]
                     then
                        count=$((count + 1))
                        log_debug "Found ${api}, count=${count}"

                        if [ "${display}" = 'YES' ]
                        then
                           sde::api::r_extract_keywords "${api}"
                           keywords_str="${RVAL}"
                           if [ ! -z "${keywords_str}" ]
                           then
                              printf "%2d. %-30s [%s]\n" "${count}" "${reponame}" "${keywords_str}"
                           else
                              printf "%2d. %-30s\n" "${count}" "${reponame}"
                           fi
                        fi

                        r_colon_concat "${apis}" "${api}"
                        apis="${RVAL}"
                     fi
                  fi
               fi
            done
            .break
         fi
      .done
   .done
   
   log_debug "Total count: ${count}"
   log_debug "Collected apis: ${apis}"

   RVAL="${apis}"
   return ${count}
}


sde::api::list()
{
   log_entry "sde::api::list" "$@"

   # If in test directory, run in parent project using mudo
   if sde::is_test_directory "${PWD}"
   then
      log_debug "In test directory, running list in parent via mudo"
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      
      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde api list $*"
      return $?
   fi

   local OPTION_ALL

   # Default based on vibecoding mode
   if [ "${MULLE_VIBECODING}" = 'YES' ]
   then
      OPTION_ALL='YES'
   else
      OPTION_ALL='NO'
   fi

   log_setting "MULLE_VIBECODING: '${MULLE_VIBECODING}'"
   log_setting "OPTION_ALL (initial): ${OPTION_ALL}"
   
   while [ $# -ne 0 ]
   do
      case "$1" in
         --all|--full)
            OPTION_ALL='YES'
         ;;

         --flat)
            OPTION_ALL='NO'
         ;;
         
         *)
            sde::api::usage "Unknown option $1"
         ;;
      esac
      shift
   done

   local count
   local apis
   local toplevel_deps

   # Ensure dependencies are crafted in vibecoding mode
   sde::api::ensure_dependencies_crafted "API information"

   # Collect all APIs
   sde::api::r_collect_apis 'NO'
   count=$?
   apis="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      if [ "${MULLE_VIBECODING}" != 'YES' ]
      then
         log_info "No API documentation found (dependencies not yet crafted?)"
         return 1
      fi

      # In vibecoding mode, if still no APIs, try full craft
      log_info "No APIs found, attempting full craft..."

      rexekutor mulle-sde craft craftorder || fail "Could not build dependencies yet, so no APIs available"
      sde::api::r_collect_apis 'NO'
      count=$?
      apis="${RVAL}"
      
      if [ ${count} -eq 0 ]
      then
         log_info "No API documentation available for dependencies"
         return 0
      fi
   fi
   
   log_setting "OPTION_ALL (final): ${OPTION_ALL}"
   log_debug "Total APIs collected: ${count}"

   # Get top-level dependencies if not --all
   if [ "${OPTION_ALL}" = 'NO' ]
   then
      toplevel_deps="$(mulle-sourcetree -s list 2>/dev/null | tail -n +3)" || toplevel_deps=""
      log_setting "Filtering to top-level deps: ${toplevel_deps}"
   else
      log_setting "Showing all dependencies (no filtering)"
   fi
   
   # Display APIs
   local api
   local reponame
   local keywords_str
   local display_count=0
   
   .foreachpath api in ${apis}
   .do
      # Extract repo name from path
      r_basename "$(dirname "$(dirname "${api}")")"
      reponame="${RVAL}"
      
      log_debug "Processing API: ${reponame}"

      # Filter by top-level if needed
      if [ "${OPTION_ALL}" = 'NO' ]
      then
         if ! echo "${toplevel_deps}" | grep -q "^${reponame}$"
         then
            log_debug "Skipping non-toplevel: ${reponame}"
            .continue
         fi
      fi
      
      display_count=$((display_count + 1))
      log_debug "Displaying: ${reponame} (count=${display_count})"
      
      sde::api::r_extract_keywords "${api}"
      keywords_str="${RVAL}"
      if [ ! -z "${keywords_str}" ]
      then
         printf "%-30s [%s]\n" "${reponame}" "${keywords_str}"
      else
         printf "%-30s\n" "${reponame}"
      fi
   .done
   
   if [ ${display_count} -eq 0 ]
   then
      log_info "No API documentation available for top-level dependencies (use --all to see all)"
   fi
   
   return 0
}


sde::api::cat()
{
   log_entry "sde::api::cat" "$@"

   # If in test directory, run in parent project using mudo
   if sde::is_test_directory "${PWD}"
   then
      log_debug "In test directory, running cat in parent via mudo"
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      
      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde api cat $*"
      return $?
   fi

   local identifier="$1"
   
   [ -z "${identifier}" ] && sde::api::usage "Missing argument (number or dependency name)"
   
   # Ensure dependencies are crafted in vibecoding mode
   sde::api::ensure_dependencies_crafted "API information"

   # Collect all APIs silently
   sde::api::r_collect_apis 'NO'
   local count=$?
   local apis="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      if [ "${MULLE_VIBECODING}" = 'YES' ]
      then
         fail "No API documentation found even after crafting"
      else
         log_info "No API documentation found (dependencies not yet crafted?)"
      fi
      return 1
   fi
   
   # Find and show the requested API
   local found='NO'
   local index=0
   local api
   local dir
   local name
   
   # Check if identifier is a number
   case "${identifier}" in
      [0-9]*)
         # It's a number - find by index
         .foreachpath api in ${apis}
         .do
            index=$((index + 1))
            if [ ${index} -eq ${identifier} ]
            then
               rexekutor cat "${api}"
               found='YES'
               .break
            fi
         .done
      ;;
      
      *)
         # It's a name - search by dependency name
         .foreachpath api in ${apis}
         .do
            # Extract dependency name from path
            # api is like: /path/to/dependency/Release/share/mulle-core/dox/TOC.md
            dir="$(dirname "${api}")"  # .../mulle-core/dox or .../mulle-core
            dir="$(dirname "${dir}")"  # .../mulle-core
            r_basename "${dir}"
            name="${RVAL}"
            
            if [ "${name}" = "${identifier}" ]
            then
               rexekutor cat "${api}"
               found='YES'
               .break
            fi
         .done
      ;;
   esac
   
   if [ "${found}" = 'NO' ]
   then
      case "${identifier}" in
         [0-9]*)
            fail "No API doc with number ${identifier} found (total: ${count})"
         ;;
         *)
            fail "No API doc for dependency '${identifier}' found"
         ;;
      esac
   fi
}


sde::api::r_find_symbol()
{
   log_entry "sde::api::r_find_symbol" "$@"

   local dir="$1"
   local name="$2"
   local follow="$3"
   
   found="$(rexekutor find ${follow} "${dir}" -name "*.h" -exec grep -i -l "${name}" {} \; 2> /dev/null)"
   
   RVAL="${found}"
}


sde::api::find()
{
   log_entry "sde::api::find" "$@"

   # Delegate to code find
   include "sde::code"
   sde::code::find "$@"
}


sde::api::apropos()
{
   log_entry "sde::api::apropos" "$@"

   # If in test directory, run in parent project using mudo
   if sde::is_test_directory "${PWD}"
   then
      log_debug "In test directory, running apropos in parent via mudo"
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      
      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde api apropos $*"
      return $?
   fi

   local question
   local output_json='NO'

   # Default to JSON in vibecoding mode
   if [ "${MULLE_VIBECODING}" = 'YES' ]
   then
      output_json='YES'
   fi

   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::api::apropos_usage
         ;;

         --json)
            output_json='YES'
         ;;

         --no-json)
            output_json='NO'
         ;;

         -*)
            sde::api::apropos_usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   # Remaining arguments form the question
   question="$*"

   [ -z "${question}" ] && sde::api::apropos_usage "Missing question"

   # Ensure dependencies are crafted in vibecoding mode
   sde::api::ensure_dependencies_crafted "API information"

   # Collect all API docs silently
   sde::api::r_collect_apis 'NO'
   local count=$?
   local apis="${RVAL}"

   if [ ${count} -eq 0 ]
   then
      if [ "${MULLE_VIBECODING}" = 'YES' ]
      then
         fail "No API documentation found even after crafting"
      else
         log_info "No API documentation found. Run 'mulle-sde craft' to build dependencies."
      fi
      return 1
   fi

   # Get top-level dependencies for prioritization
   local toplevel_deps
   toplevel_deps="$(mulle-sourcetree -s list 2>/dev/null | tail -n +3)" || toplevel_deps=""

   # Check if MULLE_SDE_AI_LOCAL is set
   if [ ! -z "${MULLE_SDE_AI_LOCAL}" ]
   then
      # AI mode: build context file with prioritization
      local context_file
      context_file="$(mktemp /tmp/mulle-sde-api-context.XXXXXX)" || fail "Failed to create temp file"

      local max_context_chars=131072  # 128K
      local current_chars=0
      local api
      local content
      local reponame
      local keywords_str

      log_info "Building prioritized context from ${count} API docs..."

      # Helper function to add API doc to context
      add_api_to_context()
      {
         local api_file="$1"
         local priority_label="$2"

         if [ -f "${api_file}" ]
         then
            content="$(cat "${api_file}" 2>/dev/null)"
            local content_length=${#content}

            # Check if adding this file would exceed limit
            if [ $((current_chars + content_length + 200)) -lt ${max_context_chars} ]
            then
               r_dirname "${api_file}"
               r_basename "${RVAL}"
               reponame="${RVAL}"

               {
                  echo ""
                  echo "--- ${reponame} (${priority_label}) ---"
                  echo "${content}"
                  echo ""
               } >> "${context_file}"

               current_chars=$((current_chars + content_length + 200))
               return 0
            else
               log_debug "Context size limit reached at ${current_chars} chars"
               return 1
            fi
         fi
         return 1
      }

      # Priority 1: Top-level dependencies
      log_debug "Adding top-level dependencies..."
      .foreachpath api in ${apis}
      .do
         r_dirname "${api}"
         r_basename "${RVAL}"
         reponame="${RVAL}"

         if echo "${toplevel_deps}" | grep -q "^${reponame}$"
         then
            if ! add_api_to_context "${api}" "top-level"
            then
               .break
            fi
         fi
      .done

      # Priority 2: Amalgamated libraries
      if [ ${current_chars} -lt ${max_context_chars} ]
      then
         log_debug "Adding amalgamated dependencies..."
         .foreachpath api in ${apis}
         .do
            # Check if already added (top-level)
            r_dirname "${api}"
            r_basename "${RVAL}"
            reponame="${RVAL}"

            if echo "${toplevel_deps}" | grep -q "^${reponame}$"
            then
               .continue
            fi

            # Check for amalgamated keyword
            sde::api::r_extract_keywords "${api}"
            keywords_str="${RVAL}"

            if echo "${keywords_str}" | grep -q -i "amalgamated"
            then
               if ! add_api_to_context "${api}" "amalgamated"
               then
                  .break
               fi
            fi
         .done
      fi

      # Priority 3: Remaining dependencies
      if [ ${current_chars} -lt ${max_context_chars} ]
      then
         log_debug "Adding remaining dependencies..."
         .foreachpath api in ${apis}
         .do
            r_dirname "${api}"
            r_basename "${RVAL}"
            reponame="${RVAL}"

            # Skip if already added
            if grep -q "^--- ${reponame} " "${context_file}" 2>/dev/null
            then
               .continue
            fi

            if ! add_api_to_context "${api}" "other"
            then
               .break
            fi
         .done
      fi

      # Build the prompt
      local prompt="You are a helpful assistant for API documentation. Below is API documentation from multiple dependencies. Answer the user's question concisely based on this documentation. If the answer is not in the documentation, say so.

Question: ${question}"

      log_info "Querying AI (context size: ${current_chars} chars)..."

      # Call the AI with context file
      ${MULLE_SDE_AI_LOCAL} --context "${context_file}" "${prompt}"
      local exit_code=$?

      # Clean up temp file
      rm -f "${context_file}"

      return ${exit_code}
   else
      # TOC.md keyword search

      # Extract meaningful keywords from question
      local keywords
      keywords="$(echo "${question}" | \
         tr '[:upper:]' '[:lower:]' | \
         sed 's/[^a-z0-9 ]/ /g' | \
         tr -s ' ' '\n' | \
         grep -v -E '^(how|do|i|a|an|the|is|are|to|in|for|of|with|what|where|when|why|can|could|should|would|explain|show|tell|me|about)$' | \
         tr '\n' ' ' | \
         sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

      [ -z "${keywords}" ] && keywords="${question}"

      # Build grep pattern
      local pattern
      local word
      for word in ${keywords}
      do
         pattern="${pattern:+${pattern}|}${word}"
      done

      if [ -z "${pattern}" ]
      then
         log_info "No search pattern generated"
         return 1
      fi

      local all_matches=""
      local reponame
      local cnt
      local matches

      # rank files by match count, keep top 5, cap at 3 matches per file
      local counts_file
      r_make_tmp_file
      counts_file="${RVAL}"
      local api
      .foreachpath api in ${apis}
      .do
         cnt="$(rexekutor grep -c -i -E "${pattern}" "${api}" 2>/dev/null)"
         [ "${cnt:-0}" -gt 0 ] && printf '%s %s\n' "${cnt}" "${api}" >> "${counts_file}"
      .done

      local ranked_apis
      ranked_apis="$(sort -rn "${counts_file}" | head -5 | sed 's/^[0-9]* //')"
      rm -f "${counts_file}"

      for api in ${ranked_apis}
      do
         matches="$(rexekutor grep -m 3 -n -H -i -E "${pattern}" "${api}" 2>/dev/null)"
         [ -z "${matches}" ] && continue

         if [ "${output_json}" = 'YES' ]
         then
            all_matches="${all_matches}${matches}"$'\n'
         else
            r_dirname "${api}"
            r_basename "${RVAL}"
            reponame="${RVAL}"
            echo "--- ${reponame} ---"
            echo "${matches}"
            echo ""
         fi
      done

      if [ "${output_json}" = 'YES' ]
      then
         if [ -z "${all_matches}" ]
         then
            log_info "No matches found in API docs"
         else
            local prev_file="" first_file='YES' first_line='YES'
            local path lineno content
            printf '['
            while IFS= read -r line
            do
               [ -z "${line}" ] && continue
               path="${line%%:*}"
               line="${line#*:}"
               lineno="${line%%:*}"
               content="${line#*:}"
               content="${content//\\/\\\\}"
               content="${content//\"/\\\"}"
               if [ "${path}" != "${prev_file}" ]
               then
                  [ "${first_file}" = 'NO' ] && printf ']},'
                  first_file='NO'
                  printf '{"filename":"%s","location":"%s","lines":[' \
                     "${path##*/}" "${path}"
                  first_line='YES'
                  prev_file="${path}"
               fi
               [ "${first_line}" = 'NO' ] && printf ','
               first_line='NO'
               printf '{"line_number":%s,"content":"%s"}' "${lineno}" "${content}"
            done <<< "${all_matches}"
            printf ']}\n'
            printf ']\n'
         fi
      fi
   fi

   return 0
}


sde::api::context_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} api context [options]

   Output all API documentation (TOC.md files) from dependencies to stdout,
   suitable for piping to an AI tool. Content is prioritized and truncated
   to fit within the context size limit.

Options:
   --context-size <n> : maximum output in bytes (default: 131072 = 128K)

Examples:
   ${MULLE_USAGE_NAME} api context | my-ai-tool "how do I allocate memory?"
   ${MULLE_USAGE_NAME} api context --context-size 262144 > /tmp/context.txt

EOF
   exit 1
}


sde::api::context()
{
   log_entry "sde::api::context" "$@"

   local max_chars=131072

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::api::context_usage
         ;;
         --context-size)
            shift
            max_chars="${1:-131072}"
         ;;
         -*)
            sde::api::context_usage "Unknown option $1"
         ;;
         *)
            break
         ;;
      esac
      shift
   done

   sde::api::ensure_dependencies_crafted "API information"

   sde::api::r_collect_apis 'NO'
   local count=$?
   local apis="${RVAL}"

   if [ ${count} -eq 0 ]
   then
      log_info "No API documentation found. Run 'mulle-sde craft' to build dependencies."
      return 1
   fi

   local toplevel_deps
   toplevel_deps="$(mulle-sourcetree -s list 2>/dev/null | tail -n +3)" || toplevel_deps=""

   local current_chars=0
   local api reponame content keywords_str

   # emit one api file to stdout, track size, return 1 if limit reached
   _emit_api()
   {
      local api_file="$1"
      [ -f "${api_file}" ] || return 1
      content="$(cat "${api_file}" 2>/dev/null)"
      local len=${#content}
      if [ $((current_chars + len + 200)) -ge ${max_chars} ]
      then
         log_debug "Context size limit reached at ${current_chars} chars"
         return 1
      fi
      r_dirname "${api_file}"; r_basename "${RVAL}"; reponame="${RVAL}"
      printf '\n--- %s ---\n%s\n' "${reponame}" "${content}"
      current_chars=$((current_chars + len + 200))
      return 0
   }

   # Pass 1: top-level deps
   .foreachpath api in ${apis}
   .do
      r_dirname "${api}"; r_basename "${RVAL}"; reponame="${RVAL}"
      echo "${toplevel_deps}" | grep -q "^${reponame}$" || .continue
      _emit_api "${api}" || .break
   .done

   # Pass 2: amalgamated
   [ ${current_chars} -lt ${max_chars} ] &&
   .foreachpath api in ${apis}
   .do
      r_dirname "${api}"; r_basename "${RVAL}"; reponame="${RVAL}"
      echo "${toplevel_deps}" | grep -q "^${reponame}$" && .continue
      sde::api::r_extract_keywords "${api}"
      echo "${RVAL}" | grep -q -i "amalgamated" || .continue
      _emit_api "${api}" || .break
   .done

   # Pass 3: remaining
   [ ${current_chars} -lt ${max_chars} ] &&
   .foreachpath api in ${apis}
   .do
      _emit_api "${api}" || .break
   .done

   log_debug "Context output: ${current_chars} chars from ${count} available docs"
}


sde::api::main()
{
   log_entry "sde::api::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::api::usage
         ;;

         -*)
            sde::api::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"
   if [ $# -ne 0 ]
   then
      cmd="$1"
      shift
   fi

   case "${cmd}" in
      'help')
         sde::api::usage
      ;;

      'list')
         sde::api::list "$@"
      ;;

      'cat'|'display')
         sde::api::cat "$@"
      ;;
      
      'find')
         sde::api::find "$@"
      ;;
      
      'apropos')
         sde::api::apropos "$@"
      ;;

      'context')
         sde::api::context "$@"
      ;;

      *)
         sde::api::usage "Unknown command '${cmd}'"
      ;;
   esac
}
