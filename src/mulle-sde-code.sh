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
MULLE_SDE_CODE_SH='included'


sde::code::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} code <cmd>

   Search and navigate source code in your project and dependencies.

Commands:
   doctor           : check code search tool availability
   grep <pattern>   : full-text search in code/comments (cs)
   search <query>   : find symbols by name (roam)
   find <type> <nm> : find header/library/symbol in dependencies
   symbol [opts]    : list symbols from headers/sources (ctags)
   cs <args>        : run cs directly with args
   lsp              : emit resolved lsp.json for the project
   roam <args>      : run roam directly with args
   ws <cmd>         : roam workspace commands

Roam commands (semantic analysis):
   understand       : AI-powered code understanding
   preflight <sym>  : pre-change impact analysis
   callers <sym>    : show who calls this symbol
   callees <sym>    : show what this symbol calls
   refs <sym>       : show all references to symbol
   map              : show project skeleton with key symbols

Examples:
   ${MULLE_USAGE_NAME} code grep "mulle_allocator"
   ${MULLE_USAGE_NAME} code grep --declarations "allocator"
   ${MULLE_USAGE_NAME} code search mulle_malloc
   ${MULLE_USAGE_NAME} code callers mulle_malloc
   ${MULLE_USAGE_NAME} code map
   ${MULLE_USAGE_NAME} code cs --only-declarations "malloc"
   ${MULLE_USAGE_NAME} code roam health

   Set MULLE_SDE_ROAM to override roam executable.

EOF
   exit 1
}


sde::code::search_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} code search [options] <query>

   Find symbols by name using semantic search (roam).
   Searches symbol names (functions, types, variables) in your project and 
   all crafted dependencies. Uses substring matching on symbol names.
   If roam is unavailable, falls back to a basic grep search.

   For full-text search in code/comments, use: ${MULLE_USAGE_NAME} code grep

Options:
   --json    : output structured JSON (default when MULLE_VIBECODING=YES)
   --no-json : force plain text output

Examples:
   ${MULLE_USAGE_NAME} code search mulle_malloc      # find symbols named *mulle_malloc*
   ${MULLE_USAGE_NAME} code search allocator_create  # find *allocator_create* symbols
   ${MULLE_USAGE_NAME} code grep "endian swap"       # full-text search in code

EOF
   exit 1
}


sde::code::ensure_dependencies_crafted()
{
   include "sde::vibecoding"

   sde::vibecoding::ensure_dependencies_crafted "code search"
}


sde::code::grep_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} code grep [options] <pattern>

   Fast text search through all source code using cs (code spelunker).
   Searches through your project and all crafted dependencies.

Options:
   --json             : output structured JSON (default when MULLE_VIBECODING=YES)
   --no-json          : force plain text output
   --declarations     : only show matches on declaration lines
   --usages           : only show matches on usage lines (excludes declarations)

Examples:
   ${MULLE_USAGE_NAME} code grep "TODO"
   ${MULLE_USAGE_NAME} code grep "mulle_allocator"
   ${MULLE_USAGE_NAME} code grep --declarations "malloc"
   ${MULLE_USAGE_NAME} code grep --usages "malloc"
   ${MULLE_USAGE_NAME} code grep --json "error:"

   For full cs control, use: ${MULLE_USAGE_NAME} code cs <args>

EOF
   exit 1
}


sde::code::roam_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} code <roam-cmd> [args]

   Run roam commands for semantic code analysis. The workspace is
   auto-initialized on first use.

Common commands:
   understand         : AI-powered code understanding
   search <symbol>    : search for symbol definitions
   preflight <symbol> : show symbol definition and references
   ws <cmd>           : run any roam workspace command

Examples:
   ${MULLE_USAGE_NAME} code understand
   ${MULLE_USAGE_NAME} code search mulle_malloc
   ${MULLE_USAGE_NAME} code preflight mulle_allocator
   ${MULLE_USAGE_NAME} code ws understand

EOF
   exit 1
}


sde::code::doctor_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} code doctor

   Check availability of code search tools (cs, mulle-roam/roam).

EOF
   exit 1
}


#
# Resolve roam executable: MULLE_SDE_ROAM > mulle-roam > roam
# Returns exe name in RVAL, returns 1 if none found
#
sde::code::r_roam_exe()
{
   if [ -n "${MULLE_SDE_ROAM}" ]
   then
      if command -v "${MULLE_SDE_ROAM}" >/dev/null 2>&1
      then
         RVAL="${MULLE_SDE_ROAM}"
         return 0
      fi
      RVAL=""
      return 1
   fi

   if command -v mulle-roam >/dev/null 2>&1
   then
      RVAL="mulle-roam"
      return 0
   fi

   if command -v roam >/dev/null 2>&1
   then
      RVAL="roam"
      return 0
   fi

   RVAL=""
   return 1
}


sde::code::r_usable_roam_exe()
{
   log_entry "sde::code::r_usable_roam_exe" "$@"

   sde::code::r_roam_exe || return 1

   local roam_exe="${RVAL}"
   if ! "${roam_exe}" --help >/dev/null 2>&1
   then
      RVAL=""
      return 1
   fi

   RVAL="${roam_exe}"
   return 0
}


sde::code::doctor()
{
   log_entry "sde::code::doctor" "$@"

   [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ] && sde::code::doctor_usage

   local ok='YES'

   # Check PATH setup
   local gopath_bin
   local user_path
   user_path="$(mudo -f printenv PATH)"
   
   local pipx_bin="${HOME}/.local/bin"
   if [ -d "${pipx_bin}" ]
   then
      case ":${user_path}:" in
         *":${pipx_bin}:"*)
            ;;
         *)
            log_warning "pipx bin directory not in PATH: ${pipx_bin}"
            log_info "   Add to PATH: export PATH=\"\$PATH:${pipx_bin}\""
            ok='NO'
            ;;
      esac
   fi

   # Check cs - try direct PATH first, then mudo
   local cs_found='NO'
   
   if command -v cs >/dev/null 2>&1
   then
      log_info "cs: $(command -v cs) ✓"
      cs_found='YES'
   elif command -v mudo >/dev/null 2>&1
   then
      local mudo_cs
      mudo_cs="$(mudo -f which cs 2>/dev/null)"
      if [ -n "${mudo_cs}" ]
      then
         log_info "cs (via mudo): ${mudo_cs} ✓"
         cs_found='YES'
      fi
   fi
   
   if [ "${cs_found}" = 'NO' ]
   then
      log_warning "cs: not found"
      
      # Check if GOPATH/bin is in PATH
      gopath_bin="$(go env GOPATH 2>/dev/null)/bin"
      if [ -n "${gopath_bin}" ] && [ -d "${gopath_bin}" ]
      then
         case ":${user_path}:" in
            *":${gopath_bin}:"*)
               ;;
            *)
               log_warning "Go bin directory not in PATH: ${gopath_bin}"
               log_info "   Add to PATH: export PATH=\"\$PATH:${gopath_bin}\""
               ;;
         esac
      fi
      
      log_info "Install it with:"$'\n'"${C_RESET_BOLD}   go install github.com/boyter/cs/v3@latest"
      ok='NO'
   fi

   # Check roam - try direct PATH first, then mudo
   local roam_found='NO'
   
   if command -v mulle-roam >/dev/null 2>&1
   then
      if mulle-roam --help >/dev/null 2>&1
      then
         log_info "mulle-roam: $(command -v mulle-roam) ✓"
         roam_found='YES'
      else
         log_warning "mulle-roam: found but not working (try: pipx install --force mulle-roam-code)"
         ok='NO'
      fi
   elif command -v roam >/dev/null 2>&1
   then
      if roam --help >/dev/null 2>&1
      then
         log_info "roam: $(command -v roam) ✓"
         roam_found='YES'
      else
         log_warning "roam: found but not working"
         ok='NO'
      fi
   elif command -v mudo >/dev/null 2>&1
   then
      local mudo_roam
      mudo_roam="$(mudo which mulle-roam 2>/dev/null || mudo which roam 2>/dev/null)"
      if [ -n "${mudo_roam}" ]
      then
         log_info "mulle-roam (via mudo): ${mudo_roam} ✓"
         roam_found='YES'
      fi
   fi
   
   if [ "${roam_found}" = 'NO' ]
   then
      log_warning "mulle-roam: not found"
      log_info "Install it with:"$'\n'"${C_RESET_BOLD}   pipx install mulle-roam-code"
      ok='NO'
   fi

   if [ "${MULLE_SDE_ROAM}" ]
   then
      if command -v "${MULLE_SDE_ROAM}" >/dev/null 2>&1
      then
         log_info "MULLE_SDE_ROAM=${MULLE_SDE_ROAM}: $(command -v "${MULLE_SDE_ROAM}") ✓"
      else
         log_warning "MULLE_SDE_ROAM=${MULLE_SDE_ROAM}: not found"
         ok='NO'
      fi
   fi

   [ "${ok}" = 'YES' ]
}



# Returns space-separated list in RVAL
#
sde::code::r_stash_realpaths()
{
   log_entry "sde::code::r_stash_realpaths" "$@"

   local stash_dir="${MULLE_SOURCETREE_STASH_DIR}"

   if [ -z "${stash_dir}" ] || [ ! -d "${stash_dir}" ]
   then
      stash_dir="$(rexekutor mulle-env -s get --output-eval MULLE_SOURCETREE_STASH_DIR 2>/dev/null)" || true
   fi

   if [ -z "${stash_dir}" ] || [ ! -d "${stash_dir}" ]
   then
      RVAL=""
      return 1
   fi

   RVAL="${stash_dir}"
}


sde::code::grep()
{
   log_entry "sde::code::grep" "$@"

   local output_json='NO'
   # MEMO: test files have lots of occurences of boring code, so move to back
   local cs_flags="--test-penalty 0.005"
   
   [ "${MULLE_VIBECODING}" = 'YES' ] && output_json='YES'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help) sde::code::grep_usage ;;
         --json)    output_json='YES' ;;
         --no-json) output_json='NO' ;;
         --declarations|--only-declarations)
            cs_flags="${cs_flags} --only-declarations"
         ;;
         --usages|--only-usages)
            cs_flags="${cs_flags} --only-usages"
         ;;
         -*) sde::code::grep_usage "Unknown option $1" ;;
         *)  break ;;
      esac
      shift
   done

   [ $# -eq 0 ] && sde::code::grep_usage "Missing pattern"

   local query="$*"

   if ! command -v cs >/dev/null 2>&1
   then
      fail "cs (code spelunker) is not installed or not in PATH"
   fi

   sde::code::r_stash_realpaths
   if [ -z "${RVAL}" ]
   then
      sde::code::ensure_dependencies_crafted
      sde::code::r_stash_realpaths
      [ -z "${RVAL}" ] && fail "No stash entries found (run 'mulle-sde craft' first?)"
   fi

   local stash_dir="${RVAL}"

   # cs is unreliable with multiple --dir args; run per subdir and merge
   local results=""
   local dir_results
   local dir
   for dir in "${stash_dir}"/*
   do
      [ -d "${dir}" ] || continue
      dir_results="$(rexekutor cs ${cs_flags} "${query}" --dir "${dir}" --format json 2>/dev/null)"
      [ -z "${dir_results}" ] || [ "${dir_results}" = "null" ] || [ "${dir_results}" = "[]" ] && continue
      # strip leading [ and trailing ] to merge arrays
      dir_results="${dir_results#\[}"
      dir_results="${dir_results%\]}"
      [ -z "${results}" ] && results="${dir_results}" || results="${results},${dir_results}"
   done
   [ -n "${results}" ] && results="[${results}]"

   if [ -z "${results}" ] || [ "${results}" = "[]" ] || [ "${results}" = "null" ]
   then
      log_info "No results found for: ${query}"
      return 1
   fi

   if [ "${output_json}" = 'YES' ]
   then
      printf '%s\n' "${results}"
   else
      # human-friendly: parse JSON with bash/grep
      printf '%s\n' "${results}" | grep -o '"location":"[^"]*"\|"line_number":[0-9]*\|"content":"[^"]*"' | \
      while IFS= read -r field
      do
         case "${field}" in
            '"location":"'*)
               location="${field#\"location\":\"}"
               location="${location%\"}"
               printf "\n  %s\n" "${location}"
            ;;
            '"line_number":'*)
               ln="${field#\"line_number\":}"
            ;;
            '"content":"'*)
               content="${field#\"content\":\"}"
               content="${content%\"}"
               [ -n "${content}" ] && printf "    %s: %s\n" "${ln}" "${content}"
            ;;
         esac
      done
   fi
}



sde::code::r_roam_db_dir()
{
   local var_dir="${MULLE_SDE_VAR_DIR:-${MULLE_VIRTUAL_ROOT}/.mulle/var}"

   RVAL="${var_dir}/roam"
}


sde::code::init()
{
   log_entry "sde::code::init" "$@"

   sde::code::r_usable_roam_exe || fail "mulle-roam/roam is not installed or not working. Run: ${MULLE_USAGE_NAME} code doctor"
   local roam_exe="${RVAL}"

   sde::code::r_stash_realpaths
   local stash_root="${RVAL}"

   # Ensure dependencies are crafted if stash is empty
   if [ -z "${stash_root}" ]
   then
      sde::code::ensure_dependencies_crafted
      sde::code::r_stash_realpaths
      stash_root="${RVAL}"
   fi

   sde::code::r_roam_db_dir
   local roam_db_dir="${RVAL}"
   local ws_dir="${roam_db_dir}/ws"

   # Clean previous workspace
   rm -rf "${ws_dir}"
   mkdir -p "${ws_dir}" || fail "Could not create ${ws_dir}"

   # Symlink project source files
   if [ -d "src" ]
   then
      mkdir -p "${ws_dir}/project"
      find "$(pwd)/src" \( -name "*.h" -o -name "*.m" -o -name "*.mm" \
                           -o -name "*.aam" -o -name "*.c" \) \
         -exec ln -sf {} "${ws_dir}/project/" \; 2>/dev/null
   fi

   # Symlink each stash entry's source files
   local dir

   for dir in "${stash_root}"/*
   do
      [ -d "${dir}/src" ] || continue
      r_basename "${dir}"
      mkdir -p "${ws_dir}/${RVAL}"
      find "${dir}/src" \( -name "*.h" -o -name "*.m" -o -name "*.mm" \
                           -o -name "*.aam" -o -name "*.c" \) \
         -exec ln -sf {} "${ws_dir}/${RVAL}/" \; 2>/dev/null
   done

   # Create a git repo so roam's file discovery works
   (
      cd "${ws_dir}" || exit 1
      git init -q
      git add -A
      git commit -q -m "ws" --allow-empty
   ) || fail "Failed to create git index"

   # Configure and index
   (
      cd "${ws_dir}" || exit 1
      case "${PROJECT_DIALECT}" in
         'objc')
            "${roam_exe}" config --c-dialect mulle-objc
         ;;
      esac
      "${roam_exe}" config --exclude "test/**"
      "${roam_exe}" config --exclude "tests/**"
      "${roam_exe}" config --exclude "demo/**"
      "${roam_exe}" index --force
   ) || fail "Failed to index"

   # Move the index.db to roam_db_dir, discard the rest
   mv "${ws_dir}/.roam/index.db" "${roam_db_dir}/index.db" || fail "Failed to move index.db"
   rm -rf "${ws_dir}"

   log_info "Index complete: ${roam_db_dir}/index.db"
}


#
# Semantic search using roam
#
sde::code::ensure_workspace_indexed()
{
   log_entry "sde::code::ensure_workspace_indexed" "$@"

   local roam_exe="$1"
   local roam_db_dir="$2"

   # Find repos listed as NOT INDEXED in the workspace
   local ws_output

   ws_output="$(ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" ws 2>/dev/null)"
   
   [ -z "${ws_output}" ] && return 0
   
   # Parse workspace output to find NOT INDEXED repos
   local line
   local repo_name
   local stash_root
   local repo_path
   
   sde::code::r_stash_realpaths
   stash_root="${RVAL}"
   
   while IFS= read -r line
   do
      if echo "${line}" | grep -q 'NOT INDEXED'
      then
         # Extract repo name (first word on the line)
         repo_name="$(echo "${line}" | awk '{print $1}')"
         [ -z "${repo_name}" ] && continue
         
         # Try to find the repo in stash
         repo_path="${stash_root}/${repo_name}"
         if [ -d "${repo_path}" ]
         then
            log_info "Indexing ${repo_name}..."
            (
               cd "${repo_path}" || exit 1
               ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" index
            )
         fi
      fi
   done <<< "${ws_output}"
}


sde::code::basic_search()
{
   log_entry "sde::code::basic_search" "$@"

   local query="$1"
   local output_json="${2:-NO}"

   [ -z "${query}" ] && fail "Missing query"

   local project_root="${MULLE_VIRTUAL_ROOT}"

   sde::code::r_stash_realpaths
   local stash_root="${RVAL}"

   local matches=""
   local root
   local root_matches
   local search_roots
   local line filepath lineno content

   if [ -z "${stash_root}" ]
   then
     sde::code::ensure_dependencies_crafted
     sde::code::r_stash_realpaths
     stash_root="${RVAL}"
   fi

   r_add_line "${search_roots}" "${project_root}"
   search_roots="${RVAL}"

   if [ ! -z "${stash_root}" ] && [ -d "${stash_root}" ]
   then
     for root in "${stash_root}"/*
     do
        [ -d "${root}" ] || continue
        r_add_line "${search_roots}" "${root}"
        search_roots="${RVAL}"
     done
   fi

   while IFS= read -r root
   do
     [ -z "${root}" ] && continue
     [ ! -d "${root}" ] && continue

     root_matches="$(
         LC_ALL=C grep -R -n -H -i -F \
            --exclude-dir='.git' \
            --exclude-dir='.mulle' \
            --exclude-dir='build' \
            --exclude-dir='kitchen' \
            --exclude-dir='dependency' \
            --exclude-dir='stash' \
            --include='*.h' \
            --include='*.hh' \
            --include='*.hpp' \
            --include='*.c' \
            --include='*.cc' \
            --include='*.cpp' \
            --include='*.m' \
            --include='*.mm' \
            --include='*.swift' \
            --include='*.go' \
            --include='*.rs' \
            --include='*.java' \
            --include='*.js' \
            --include='*.ts' \
            --include='*.tsx' \
            --include='*.sh' \
            -- "${query}" "${root}" 2>/dev/null
      )"

      if [ ! -z "${root_matches}" ]
      then
         matches="${matches}${matches:+$'\n'}${root_matches}"
      fi
   done <<EOF
${search_roots}
EOF

   if [ -z "${matches}" ]
   then
      if [ "${output_json}" = 'YES' ]
      then
         printf '[]\n'
      else
         log_info "No results found for: ${query}"
      fi
      return 1
   fi

   if [ "${output_json}" = 'YES' ]
   then
      local first='YES'

      printf '['
      while IFS= read -r line
      do
         [ -z "${line}" ] && continue

         filepath="${line%%:*}"
         line="${line#*:}"
         lineno="${line%%:*}"
         content="${line#*:}"

         content="${content//\\/\\\\}"
         content="${content//\"/\\\"}"
         content="${content//$'\t'/\\t}"

         [ "${first}" = 'NO' ] && printf ','
         first='NO'
         printf '{"location":"%s","line_number":%s,"content":"%s"}' "${filepath}" "${lineno}" "${content}"
      done <<< "${matches}"
      printf ']\n'
      return 0
   fi

   local prev_path=""
   while IFS= read -r line
   do
      [ -z "${line}" ] && continue

      filepath="${line%%:*}"
      line="${line#*:}"
      lineno="${line%%:*}"
      content="${line#*:}"

      if [ "${filepath}" != "${prev_path}" ]
      then
         printf "\n  %s\n" "${filepath}"
         prev_path="${filepath}"
      fi
      printf "    %s: %s\n" "${lineno}" "${content}"
   done <<< "${matches}"
}


sde::code::search()
{
   log_entry "sde::code::search" "$@"

   local output_json='NO'
   [ "${MULLE_VIBECODING}" = 'YES' ] && output_json='YES'

   [ $# -eq 0 ] && sde::code::search_usage "Missing query"
   [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ] && sde::code::search_usage

   local fallback_query=""
   local arg
   for arg in "$@"
   do
      case "${arg}" in
         --json)
            output_json='YES'
         ;;
         --no-json)
            output_json='NO'
         ;;
         -*)
         ;;
         *)
            fallback_query="${fallback_query:+${fallback_query} }${arg}"
         ;;
      esac
   done

   [ -z "${fallback_query}" ] && fallback_query="$*"
   [ -z "${fallback_query}" ] && sde::code::search_usage "Missing query"

   if ! sde::code::r_usable_roam_exe
   then
      log_warning "mulle-roam/roam is unavailable; falling back to basic grep search"
      sde::code::basic_search "${fallback_query}" "${output_json}"
      return $?
   fi

   local roam_exe="${RVAL}"

   sde::code::r_roam_db_dir
   local roam_db_dir="${RVAL}"

   # auto-init if no index yet
   if [ ! -f "${roam_db_dir}/index.db" ]
   then
      log_info "Initializing roam index..."
      sde::code::init
   fi

   ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" search "$@"
}


sde::code::roam()
{
   log_entry "sde::code::roam" "$@"

   [ $# -eq 0 ] && sde::code::roam_usage
   [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ] && sde::code::roam_usage

   sde::code::r_usable_roam_exe || fail "mulle-roam/roam is not installed or not working. Run: ${MULLE_USAGE_NAME} code doctor"
   local roam_exe="${RVAL}"

   sde::code::r_roam_db_dir
   local roam_db_dir="${RVAL}"

   # auto-init if no index yet
   if [ ! -f "${roam_db_dir}/index.db" ]
   then
      log_info "Initializing roam index..."
      sde::code::init
   fi

   ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" "$@"
}


sde::code::find()
{
   log_entry "sde::code::find" "$@"

   [ $# -eq 0 ] && fail "Missing type argument (header|library|symbol)"
   local type=$1
   shift

   [ $# -eq 0 ] && fail "Missing name argument"
   local name=$1
   shift

   [ $# -ne 0 ] && fail "Superflous arguments $*"

   local dependency_dir

   dependency_dir="${MULLE_CRAFT_DEPENDENCY_UNQUALIFIED_DIR:-${MULLE_CRAFT_DEPENDENCY_DIR:-${DEPENDENCY_DIR}}}"

   [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ] && \
   {
      sde::code::ensure_dependencies_crafted
      dependency_dir="${MULLE_CRAFT_DEPENDENCY_UNQUALIFIED_DIR:-${MULLE_CRAFT_DEPENDENCY_DIR:-${DEPENDENCY_DIR}}}"
      [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ] && fail "Need to craft dependencies first"
   }

   (
      eval `mulle-platform env`

      local paths

      case "${type}" in
         'h'|'header'|'s'|'symbol')
            paths="`rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                              --dependency-dir "${dependency_dir}" \
                           searchpath \
                              --no-addiction \
                              --configurations "Debug:Release" \
                              header`"
         ;;
         'l'|'library')
            paths="`rexekutor "${MULLE_CRAFT:-mulle-craft}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                              --dependency-dir "${dependency_dir}" \
                           searchpath \
                              --no-addiction \
                              --configurations "Debug:Release" \
                              library`"
         ;;
         *)
            fail "Unknown type \"${type}\" (use: header, library, symbol)"
         ;;
      esac

      local dir abs_dir found

      .foreachpath dir in ${paths}
      .do
         r_absolutepath "${dir}"
         abs_dir="${RVAL}"
         [ ! -d "${abs_dir}" ] && .continue

         case "${type}" in
            's'|'symbol')
               found="$(rexekutor find "${abs_dir}" -name "*.h" -exec grep -i -l "${name}" {} \; 2>/dev/null)"
            ;;
            'l'|'library')
               found="$(rexekutor find "${abs_dir}" -type f -name "${name}" -print 2>/dev/null | head -1)"
               [ -z "${found}" ] && found="$(rexekutor find "${abs_dir}" -type f -name "${MULLE_PLATFORM_LIBRARY_PREFIX}${name}${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}" -print 2>/dev/null | head -1)"
               [ -z "${found}" ] && found="$(rexekutor find "${abs_dir}" -type f -name "${MULLE_PLATFORM_LIBRARY_PREFIX}${name}${MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC}*" -print 2>/dev/null | head -1)"
               [ -z "${found}" ] && found="$(rexekutor find "${abs_dir}" -type f -name "*${name}*${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}" -print 2>/dev/null | head -1)"
               [ -z "${found}" ] && found="$(rexekutor find "${abs_dir}" -type f -name "*${name}*${MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC}*" -print 2>/dev/null | head -1)"
            ;;
            *)
               found="$(rexekutor find "${abs_dir}" -name "${name}" -print 2>/dev/null)"
            ;;
         esac

         if [ ! -z "${found}" ]
         then
            printf "%s\n" "${found}"
            return
         fi
      .done

      log_warning "Nothing found"
   )
}


sde::code::symbol()
{
   log_entry "sde::code::symbol" "$@"

   # Delegate to mulle-sde-symbol
   include "sde::symbol"
   sde::symbol::main "$@"
}


sde::code::class()
{
   log_entry "sde::code::class" "$@"

   [ $# -eq 0 ] && fail "Missing class name"

   local name="$1"

   sde::code::r_usable_roam_exe || fail "mulle-roam/roam is not installed or not working"
   local roam_exe="${RVAL}"

   sde::code::r_roam_db_dir
   local roam_db_dir="${RVAL}"

   if [ ! -f "${roam_db_dir}/index.db" ]
   then
      log_info "Initializing roam index..."
      sde::code::init
   fi

   # Show class: superclass, subclasses, methods
   printf "=== %s ===\n\n" "${name}"

   printf "%s\n" "--- Hierarchy ---"
   ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" symbol "${name}" 2>/dev/null
   printf "\n%s\n" "--- Subclasses / Consumers ---"
   ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" uses "${name}" 2>/dev/null

   # Find the .m file and show methods
   local file
   file="$(ROAM_DB_DIR="${roam_db_dir}" "${roam_exe}" --json symbol "${name}" 2>/dev/null \
           | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('location','').split(':')[0])" 2>/dev/null)"
   if [ -n "${file}" ]
   then
      printf "\n%s\n" "--- Methods ---"
      ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" file "${file}" 2>/dev/null
   fi
}


sde::code::callers()
{
   log_entry "sde::code::callers" "$@"

   [ $# -eq 0 ] && fail "Missing symbol name"
   
   sde::code::roam symbol "$@"
}


sde::code::callees()
{
   log_entry "sde::code::callees" "$@"

   [ $# -eq 0 ] && fail "Missing symbol name"
   
   sde::code::roam symbol "$@"
}


sde::code::refs()
{
   log_entry "sde::code::refs" "$@"

   [ $# -eq 0 ] && fail "Missing symbol name"
   
   sde::code::roam symbol "$@"
}


sde::code::map()
{
   log_entry "sde::code::map" "$@"
   
   sde::code::roam map "$@"
}


sde::code::cs()
{
   log_entry "sde::code::cs" "$@"

   if ! command -v cs >/dev/null 2>&1
   then
      fail "cs (code spelunker) is not installed or not in PATH"
   fi

   sde::code::r_stash_realpaths
   if [ -z "${RVAL}" ]
   then
      sde::code::ensure_dependencies_crafted
      sde::code::r_stash_realpaths
      [ -z "${RVAL}" ] && fail "No stash entries found (run 'mulle-sde craft' first?)"
   fi

   rexekutor cs --test-penalty 0.1 --dir "${RVAL}" "$@"
}


sde::code::main()
{
   log_entry "sde::code::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help) sde::code::usage ;;
         -*) sde::code::usage "Unknown option \"$1\"" ;;
         *)  break ;;
      esac
      shift
   done

   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "wrong"

   # Always operate from main project, not test subdir
   # AI loves this apparently..
   if [ "${MULLE_VIBECODING}" = 'YES' -a -f ".mulle/share/test/mulle-test" ]
   then
      local parent_dir

      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      log_debug "In test directory, running code from parent: ${parent_dir}"
      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde code $*"
      return $?
   fi

   local cmd="${1:-help}"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      doctor)     sde::code::doctor "$@" ;;
      grep)       sde::code::grep "$@" ;;
      search)     sde::code::search "$@" ;;
      find)       sde::code::find "$@" ;;
      class)      sde::code::class "$@" ;;
      symbol)     sde::code::symbol "$@" ;;
      callers)    sde::code::callers "$@" ;;
      callees)    sde::code::callees "$@" ;;
      refs)       sde::code::refs "$@" ;;
      map)        sde::code::map "$@" ;;
      cs)         sde::code::cs "$@" ;;
      roam)       sde::code::roam "$@" ;;
      init|reset) sde::code::init "$@" ;;
      understand|preflight|ws) sde::code::roam "${cmd}" "$@" ;;
      lsp)
         include "sde::lsp"
         sde::lsp::main "$@"
      ;;
      *)
         sde::code::usage "Unknown command '${cmd}'"
      ;;
   esac
}
