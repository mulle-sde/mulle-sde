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

   Roam commands (semantic analysis):
   understand       : AI-powered code understanding
   preflight <sym>  : pre-change impact analysis
   callers <sym>    : show who calls this symbol
   callees <sym>    : show what this symbol calls
   refs <sym>       : show all references to symbol
   map              : show project skeleton with key symbols
   
   Direct tool access:
   cs <args>        : run cs directly with args
   lsp              : emit resolved lsp.json for the project
   roam <args>      : run roam directly with args
   ws <cmd>         : roam workspace commands

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
   local state

   state="$(rexekutor mulle-craft -s quickstatus -p 2>/dev/null)" || state=""
   [ "${state}" = "complete" ] && return 0

   log_info "Crafting dependencies..."

   local rc
   rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS:--s} -DMULLE_VIBECODING=NO craft --no-clean craftorder
   rc=$?
   [ $rc -ne 0 ] && log_warning "Failed to craft dependencies"
   return 0
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
      log_info "mulle-roam: $(command -v mulle-roam) ✓"
      roam_found='YES'
   elif command -v roam >/dev/null 2>&1
   then
      log_info "roam: $(command -v roam) ✓"
      roam_found='YES'
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


sde::code::r_project_root()
{
   log_entry "sde::code::r_project_root" "$@"

   # walk up to find the mulle-sde project root (has .mulle dir)
   local dir="${PWD}"
   while [ "${dir}" != "/" ]
   do
      if [ -d "${dir}/.mulle" ]
      then
         RVAL="${dir}"
         return 0
      fi
      r_dirname "${dir}"
      dir="${RVAL}"
   done
   RVAL="${PWD}"
}


sde::code::init()
{
   log_entry "sde::code::init" "$@"

   sde::code::r_roam_exe || fail "mulle-roam/roam is not installed. Run: ${MULLE_USAGE_NAME} code doctor"
   local roam_exe="${RVAL}"

   sde::code::r_project_root
   local project_root="${RVAL}"

   # Use mulle var dir for all roam indexes - keeps source dirs clean
   local var_dir
   var_dir="${MULLE_SDE_VAR_DIR:-${project_root}/.mulle/var}"
   local roam_db_dir="${var_dir}/roam"

   mkdir -p "${roam_db_dir}" || fail "Could not create roam db dir: ${roam_db_dir}"

   sde::code::r_stash_realpaths
   local stash_root="${RVAL}"
   
   # Ensure dependencies are crafted if stash is empty
   if [ -z "${stash_root}" ]
   then
      sde::code::ensure_dependencies_crafted
      sde::code::r_stash_realpaths
      stash_root="${RVAL}"
   fi

   # Index project itself
   log_verbose "Indexing project..."
   (
      cd "${project_root}" || exit 1
      ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" index
   )

   # Index each stash entry
   local dir
   for dir in "${stash_root}"/*
   do
      if [ -d "${dir}/.git" ]
      then
         r_basename "${dir}"
         log_verbose "Indexing ${RVAL}..."
         (
            cd "${dir}" || exit 1
            ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" index
         )
      fi
   done

   # Build workspace linking project + stash entries
   log_verbose "Building roam workspace..."
   set -- "${project_root}"
   for dir in "${stash_root}"/*
   do
      [ -d "${dir}/.git" ] && set -- "$@" "${dir}"
   done

   r_basename "${project_root}"
   local project_name="${RVAL}"

   ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" ws init "$@" --name "${project_name}"
   
   # After workspace init, index all repos in the workspace
   log_verbose "Indexing workspace repos..."
   (
      cd "${project_root}" || exit 1
      ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" index
   )
   
   for dir in "${stash_root}"/*
   do
      if [ -d "${dir}/.git" ]
      then
         (
            cd "${dir}" || exit 1
            ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" index
         )
      fi
   done
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
         local repo_path="${stash_root}/${repo_name}"
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


sde::code::search()
{
   log_entry "sde::code::search" "$@"

   [ $# -eq 0 ] && sde::code::search_usage "Missing query"
   [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ] && sde::code::search_usage

   sde::code::r_roam_exe || fail "mulle-roam/roam is not installed. Run: ${MULLE_USAGE_NAME} code doctor"
   local roam_exe="${RVAL}"

   sde::code::r_project_root
   local project_root="${RVAL}"

   local var_dir="${MULLE_SDE_VAR_DIR:-${project_root}/.mulle/var}"
   local roam_db_dir="${var_dir}/roam"

   # auto-init if no index yet
   if [ ! -d "${roam_db_dir}" ]
   then
      log_info "Initializing roam workspace..."
      sde::code::init
   fi

   sde::code::ensure_workspace_indexed "${roam_exe}" "${roam_db_dir}"

   ROAM_DB_DIR="${roam_db_dir}" rexekutor "${roam_exe}" search "$@"
}


sde::code::roam()
{
   log_entry "sde::code::roam" "$@"

   [ $# -eq 0 ] && sde::code::roam_usage
   [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ] && sde::code::roam_usage

   sde::code::r_roam_exe || fail "mulle-roam/roam is not installed. Run: ${MULLE_USAGE_NAME} code doctor"
   local roam_exe="${RVAL}"

   sde::code::r_project_root
   local project_root="${RVAL}"

   local var_dir="${MULLE_SDE_VAR_DIR:-${project_root}/.mulle/var}"
   local roam_db_dir="${var_dir}/roam"

   # auto-init if no index yet
   if [ ! -d "${roam_db_dir}" ]
   then
      log_info "Initializing roam workspace..."
      sde::code::init
   fi

   sde::code::ensure_workspace_indexed "${roam_exe}" "${roam_db_dir}"

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
   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true

   [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ] && \
   {
      sde::code::ensure_dependencies_crafted
      dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true
      [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ] && fail "Need to craft dependencies first"
   }

   (
      eval `mulle-platform env`

      local paths

      case "${type}" in
         'h'|'header'|'s'|'symbol')
            paths="${dependency_dir}/Debug/include:${dependency_dir}/Release/include:${dependency_dir}/include"
         ;;
         'l'|'library')
            paths="${dependency_dir}/Debug/lib:${dependency_dir}/Release/lib:${dependency_dir}/lib"
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

   # Always operate from main project, not test subdir
   if [ -f ".mulle/share/test/mulle-test" ]
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
      symbol)     sde::code::symbol "$@" ;;
      callers)    sde::code::callers "$@" ;;
      callees)    sde::code::callees "$@" ;;
      refs)       sde::code::refs "$@" ;;
      map)        sde::code::map "$@" ;;
      cs)         sde::code::cs "$@" ;;
      roam)       sde::code::roam "$@" ;;
      understand|preflight|ws) sde::code::roam "${cmd}" "$@" ;;
      lsp)
         include "sde::lsp"
         sde::lsp::main "$@"
      ;;
      *)          sde::code::usage "Unknown command '${cmd}'" ;;
   esac
}
