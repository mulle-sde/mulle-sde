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
MULLE_SDE_LSP_SH='included'


sde::lsp::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} lsp [options]

   Emit or install LSP configuration for the current project.

   Without --tool the kiro JSON is printed to stdout.

   The command resolves the LSP server binary path and the compile commands
   directory based on the current project dialect and configuration.

   Known tools and their default output paths:
      kiro       .kiro/settings/lsp.json
      opencode   opencode.json
      codex      codex.json
      claude     .claude/settings.json
      copilot    .github/lsp.json
      save       lsp.json    (generic kiro-format save)

Options:
   --configuration <c>        : build configuration (default: Debug)
   --debug                    : shortcut for --configuration Debug
   --release                  : shortcut for --configuration Release
   --tool <name> [<file>]     : write config for tool to <file> or default path
                                (can be repeated for multiple tools)

   Deprecated (use --tool instead):
   --save [file]              : alias for --tool save [file]
   --kiro [path]              : alias for --tool kiro [path]
   --opencode [file]          : alias for --tool opencode [file]

EOF
   exit 1
}


#
# Find the LSP server command for the given dialect.
# For objc/c we prefer mulle-clangd, for c++ we use clangd.
# Search order: mudo PATH -> regular PATH -> /opt fallback -> clangd fallback
#
sde::lsp::r_find_lsp_command()
{
   log_entry "sde::lsp::r_find_lsp_command" "$@"

   local dialect="$1"

   local preferred

   case "${dialect}" in
      objc|c)
         preferred="mulle-clangd"
      ;;

      *)
         preferred="clangd"
      ;;
   esac

   # try mudo first (finds it via the user's outside-environment PATH)
   if command -v mudo > /dev/null 2>&1
   then
      RVAL="$(mudo -f which "${preferred}" 2>/dev/null)"
      if [ ! -z "${RVAL}" ]
      then
         log_verbose "Found ${preferred} via mudo: ${RVAL}"
         return 0
      fi
   fi

   # try regular PATH
   RVAL="$(command -v "${preferred}" 2>/dev/null)"
   if [ ! -z "${RVAL}" ]
   then
      log_verbose "Found ${preferred} in PATH: ${RVAL}"
      return 0
   fi

   # /opt fallback for mulle-clangd
   if [ "${preferred}" = "mulle-clangd" ]
   then
      local optpath="/opt/mulle-clang-project/latest/bin/mulle-clangd"

      if [ -x "${optpath}" ]
      then
         RVAL="${optpath}"
         log_verbose "Found mulle-clangd at ${RVAL}"
         return 0
      fi

      # fall back to plain clangd
      if command -v mudo > /dev/null 2>&1
      then
         RVAL="$(mudo -f which clangd 2>/dev/null)"
         if [ ! -z "${RVAL}" ]
         then
            log_verbose "Falling back to clangd via mudo: ${RVAL}"
            return 0
         fi
      fi

      RVAL="$(command -v clangd 2>/dev/null)"
      if [ ! -z "${RVAL}" ]
      then
         log_verbose "Falling back to clangd in PATH: ${RVAL}"
         return 0
      fi
   fi

   RVAL=""
   return 1
}


sde::lsp::r_lsp_name()
{
   log_entry "sde::lsp::r_lsp_name" "$@"

   local command="$1"

   r_basename "${command}"
}


sde::lsp::r_find_bash_lsp_command()
{
   log_entry "sde::lsp::r_find_bash_lsp_command" "$@"

   if command -v mudo > /dev/null 2>&1
   then
      RVAL="$(mudo -f which bash-language-server 2>/dev/null)"
      if [ ! -z "${RVAL}" ]
      then
         log_verbose "Found bash-language-server via mudo: ${RVAL}"
         return 0
      fi
   fi

   RVAL="$(command -v bash-language-server 2>/dev/null)"
   if [ ! -z "${RVAL}" ]
   then
      log_verbose "Found bash-language-server in PATH: ${RVAL}"
      return 0
   fi

   RVAL=""
   return 1
}


sde::lsp::emit_json()
{
   log_entry "sde::lsp::emit_json" "$@"

   local lsp_command="$1"
   local lsp_name="$2"
   local kitchen_dir="$3"
   local dialect="$4"
   local bash_command="$5"

   local language_key
   local file_extensions
   local project_patterns
   local fallback_flags

   case "${dialect}" in
      objc)
         language_key="objc"
         file_extensions='      "c", "m", "h", "aam", "nm", "nh"'
         project_patterns='      ".mulle", "CMakeLists.txt", "compile_commands.json", "Makefile"'
         fallback_flags='-std=c11'
      ;;

      c)
         language_key="c"
         file_extensions='      "c", "h"'
         project_patterns='      ".mulle", "CMakeLists.txt", "compile_commands.json", "Makefile"'
         fallback_flags='-std=c11'
      ;;

      c++|cpp)
         language_key="cpp"
         file_extensions='      "cpp", "cc", "cxx", "c", "h", "hpp", "hxx"'
         project_patterns='      "CMakeLists.txt", "compile_commands.json", "Makefile"'
         fallback_flags='-std=c++17'
      ;;

      *)
         language_key="${dialect}"
         file_extensions='      "c", "h"'
         project_patterns='      "CMakeLists.txt", "compile_commands.json", "Makefile"'
         fallback_flags='-std=c11'
      ;;
   esac

   #
   # Escape backslashes and double quotes for JSON
   # (r_escaped_json also escapes forward slashes which is ugly)
   #
   local escaped_command="${lsp_command//\\/\\\\}"
   escaped_command="${escaped_command//\"/\\\"}"

   local escaped_kitchen_dir="${kitchen_dir//\\/\\\\}"
   escaped_kitchen_dir="${escaped_kitchen_dir//\"/\\\"}"

   local bash_entry
   local trailing_comma

   if [ ! -z "${bash_command}" ]
   then
      local escaped_bash="${bash_command//\\/\\\\}"
      escaped_bash="${escaped_bash//\"/\\\"}"

      trailing_comma=","
      bash_entry="
    \"bash\": {
      \"name\": \"bash-language-server\",
      \"command\": \"${escaped_bash}\",
      \"args\": [\"start\"],
      \"file_extensions\": [
      \"sh\", \"bash\", \"zsh\"
      ],
      \"project_patterns\": [
      \".mulle\"
      ],
      \"exclude_patterns\": [\"**/test/**\", \"**/research/**\", \"**/old/**\"],
      \"multi_workspace\": false,
      \"initialization_options\": {},
      \"request_timeout_secs\": 60
    }"
   fi

   cat <<EOF
{
  "languages": {
    "${language_key}": {
      "name": "${lsp_name}",
      "command": "${escaped_command}",
      "args": ["--background-index", "--compile-commands-dir=${escaped_kitchen_dir}"],
      "file_extensions": [
${file_extensions}
      ],
      "project_patterns": [
${project_patterns}
      ],
      "exclude_patterns": ["**/test/**", "**/research/**", "**/old/**"],
      "multi_workspace": false,
      "initialization_options": {
        "${lsp_name}": {
          "fallbackFlags": ["${fallback_flags}"]
        }
      },
      "request_timeout_secs": 240
    }${trailing_comma}${bash_entry}
  }
}
EOF
}



#
# Build the opencode lsp entry for one language using jq and splice it
# into the given opencode.json file (created as {} if missing).
#
# opencode "lsp" format:
#   { "lsp": { "<lang>": { "command": ["bin","arg",...],
#                          "extensions": [...],
#                          "initialization": {...} } } }
#
sde::lsp::splice_opencode_json()
{
   log_entry "sde::lsp::splice_opencode_json" "$@"

   local opencode_file="$1"
   local lsp_command="$2"
   local kitchen_dir="$3"
   local dialect="$4"
   local lsp_name="$5"
   local bash_command="$6"

   if ! command -v jq > /dev/null 2>&1
   then
      fail "jq is required for --opencode but was not found in PATH"
   fi

   # resolve language key and extensions
   local language_key
   local extensions
   local fallback_flags

   case "${dialect}" in
      objc)
         language_key="objc"
         extensions='["c","m","h","aam","nm","nh"]'
         fallback_flags='-std=c11'
      ;;
      c)
         language_key="c"
         extensions='["c","h"]'
         fallback_flags='-std=c11'
      ;;
      c++|cpp)
         language_key="cpp"
         extensions='["cpp","cc","cxx","c","h","hpp","hxx"]'
         fallback_flags='-std=c++17'
      ;;
      *)
         language_key="${dialect}"
         extensions='["c","h"]'
         fallback_flags='-std=c11'
      ;;
   esac

   # read existing file or start fresh
   local existing="{}"
   if [ -f "${opencode_file}" ]
   then
      existing="$(cat "${opencode_file}")" || fail "Could not read ${opencode_file}"
   fi

   # build the jq update expression for the primary language entry;
   # disable the built-in clangd so our custom server wins
   local updated
   updated="$(printf '%s' "${existing}" | jq \
      --arg lang    "${language_key}" \
      --arg cmd     "${lsp_command}" \
      --arg kdir    "${kitchen_dir}" \
      --arg name    "${lsp_name}" \
      --arg flags   "${fallback_flags}" \
      --argjson exts "${extensions}" \
      '.lsp[$lang] = {
         "command":        [$cmd, "--background-index", ("--compile-commands-dir=" + $kdir)],
         "extensions":     $exts,
         "initialization": { ($name): { "fallbackFlags": [$flags] } }
      }
      | .lsp["clangd"] = { "disabled": true }')" \
   || fail "jq failed to build opencode lsp entry"

   # optionally splice bash-language-server entry and disable the built-in
   if [ -n "${bash_command}" ]
   then
      updated="$(printf '%s' "${updated}" | jq \
         --arg cmd "${bash_command}" \
         '.lsp["bash"] = {
            "command":    [$cmd, "start"],
            "extensions": ["sh","bash","zsh"]
         }')" \
      || fail "jq failed to add bash lsp entry"
   else
      # disable built-in bash LSP so it doesn't interfere
      updated="$(printf '%s' "${updated}" | jq \
         '.lsp["bash"] = { "disabled": true }')" \
      || fail "jq failed to disable built-in bash lsp entry"
   fi

   local opencode_dir
   r_dirname "${opencode_file}"
   opencode_dir="${RVAL}"

   if [ ! -d "${opencode_dir}" ] && [ "${opencode_dir}" != "." ]
   then
      exekutor mkdir -p "${opencode_dir}" || fail "Could not create ${opencode_dir}"
   fi

   redirect_exekutor "${opencode_file}" printf "%s\n" "${updated}" \
      || fail "Could not write ${opencode_file}"
   log_info "Spliced lsp into ${opencode_file}"
}


#
# Return the default output path and format tag for a given tool name.
# Sets RVAL to "format:default_path".
#
sde::lsp::r_tool_defaults()
{
   local tool="$1"

   case "${tool}" in
      kiro)     RVAL="kiro:.kiro/settings/lsp.json"  ;;
      save)     RVAL="kiro:lsp.json"                 ;;
      opencode) RVAL="opencode:opencode.json"         ;;
      codex)    RVAL="codex:codex.json"               ;;
      claude)   RVAL="claude:.claude/settings.json"   ;;
      copilot)  RVAL="copilot:.github/lsp.json"      ;;
      *)
         log_error "Unknown tool \"${tool}\". Known tools: kiro, save, opencode, codex, claude, copilot"
         RVAL=""
         return 1
      ;;
   esac
   return 0
}


#
# Emit codex.json lsp section (merged into existing file if present).
# Format mirrors opencode but uses "lsp" → { "<lang>": { command, args, extensions } }
#
sde::lsp::splice_codex_json()
{
   log_entry "sde::lsp::splice_codex_json" "$@"

   local codex_file="$1"
   local lsp_command="$2"
   local kitchen_dir="$3"
   local dialect="$4"
   local lsp_name="$5"
   local bash_command="$6"

   if ! command -v jq > /dev/null 2>&1
   then
      fail "jq is required for codex output but was not found in PATH"
   fi

   local language_key extensions fallback_flags

   case "${dialect}" in
      objc)      language_key="objc"; extensions='["c","m","h","aam","nm","nh"]'; fallback_flags='-std=c11' ;;
      c)         language_key="c";    extensions='["c","h"]';                     fallback_flags='-std=c11' ;;
      c++|cpp)   language_key="cpp";  extensions='["cpp","cc","cxx","c","h","hpp","hxx"]'; fallback_flags='-std=c++17' ;;
      *)         language_key="${dialect}"; extensions='["c","h"]';               fallback_flags='-std=c11' ;;
   esac

   local existing="{}"
   [ -f "${codex_file}" ] && existing="$(cat "${codex_file}")" || true

   local updated
   updated="$(printf '%s' "${existing}" | jq \
      --arg lang    "${language_key}" \
      --arg cmd     "${lsp_command}" \
      --arg kdir    "${kitchen_dir}" \
      --arg name    "${lsp_name}" \
      --arg flags   "${fallback_flags}" \
      --argjson exts "${extensions}" \
      '.lsp[$lang] = {
         "command":    [$cmd, "--background-index", ("--compile-commands-dir=" + $kdir)],
         "extensions": $exts,
         "initialization": { ($name): { "fallbackFlags": [$flags] } }
      }')" \
   || fail "jq failed to build codex lsp entry"

   if [ -n "${bash_command}" ]
   then
      updated="$(printf '%s' "${updated}" | jq \
         --arg cmd "${bash_command}" \
         '.lsp["bash"] = { "command": [$cmd, "start"], "extensions": ["sh","bash","zsh"] }')" \
      || fail "jq failed to add bash lsp entry for codex"
   fi

   local codex_dir
   r_dirname "${codex_file}"
   codex_dir="${RVAL}"
   [ ! -d "${codex_dir}" ] && [ "${codex_dir}" != "." ] && \
      exekutor mkdir -p "${codex_dir}"

   redirect_exekutor "${codex_file}" printf "%s\n" "${updated}" \
      || fail "Could not write ${codex_file}"
   log_info "Spliced lsp into ${codex_file}"
}


#
# Merge the lsp section into .claude/settings.json.
# Claude-code uses a flat JSON settings file; we add/update a "lsp" key.
#
sde::lsp::splice_claude_json()
{
   log_entry "sde::lsp::splice_claude_json" "$@"

   local claude_file="$1"
   local lsp_command="$2"
   local kitchen_dir="$3"
   local dialect="$4"
   local lsp_name="$5"
   local bash_command="$6"

   if ! command -v jq > /dev/null 2>&1
   then
      fail "jq is required for claude output but was not found in PATH"
   fi

   local language_key extensions fallback_flags

   case "${dialect}" in
      objc)      language_key="objc"; extensions='["c","m","h","aam","nm","nh"]'; fallback_flags='-std=c11' ;;
      c)         language_key="c";    extensions='["c","h"]';                     fallback_flags='-std=c11' ;;
      c++|cpp)   language_key="cpp";  extensions='["cpp","cc","cxx","c","h","hpp","hxx"]'; fallback_flags='-std=c++17' ;;
      *)         language_key="${dialect}"; extensions='["c","h"]';               fallback_flags='-std=c11' ;;
   esac

   local existing="{}"
   [ -f "${claude_file}" ] && existing="$(cat "${claude_file}")" || true

   local updated
   updated="$(printf '%s' "${existing}" | jq \
      --arg lang    "${language_key}" \
      --arg cmd     "${lsp_command}" \
      --arg kdir    "${kitchen_dir}" \
      --arg name    "${lsp_name}" \
      --arg flags   "${fallback_flags}" \
      --argjson exts "${extensions}" \
      '.lsp[$lang] = {
         "command":    [$cmd, "--background-index", ("--compile-commands-dir=" + $kdir)],
         "extensions": $exts,
         "initialization": { ($name): { "fallbackFlags": [$flags] } }
      }')" \
   || fail "jq failed to build claude lsp entry"

   local claude_dir
   r_dirname "${claude_file}"
   claude_dir="${RVAL}"
   [ ! -d "${claude_dir}" ] && [ "${claude_dir}" != "." ] && \
      exekutor mkdir -p "${claude_dir}"

   redirect_exekutor "${claude_file}" printf "%s\n" "${updated}" \
      || fail "Could not write ${claude_file}"
   log_info "Spliced lsp into ${claude_file}"
}


#
# Write .github/lsp.json in GitHub Copilot CLI format:
#   { "lspServers": { "<name>": { "command": "...", "args": [...], "fileExtensions": {...} } } }
#
sde::lsp::write_copilot_json()
{
   log_entry "sde::lsp::write_copilot_json" "$@"

   local copilot_file="$1"
   local lsp_command="$2"
   local kitchen_dir="$3"
   local dialect="$4"
   local lsp_name="$5"
   local bash_command="$6"

   if ! command -v jq > /dev/null 2>&1
   then
      fail "jq is required for copilot output but was not found in PATH"
   fi

   local server_name file_extensions

   case "${dialect}" in
      objc)
         server_name="mulle-clangd"
         file_extensions='{ ".c": "c", ".m": "objc", ".h": "objc", ".aam": "objc", ".nm": "objc", ".nh": "objc" }'
      ;;
      c)
         server_name="clangd"
         file_extensions='{ ".c": "c", ".h": "c" }'
      ;;
      c++|cpp)
         server_name="clangd"
         file_extensions='{ ".cpp": "cpp", ".cc": "cpp", ".cxx": "cpp", ".c": "c", ".h": "cpp", ".hpp": "cpp", ".hxx": "cpp" }'
      ;;
      *)
         server_name="clangd"
         file_extensions='{ ".c": "c", ".h": "c" }'
      ;;
   esac

   local existing="{}"
   [ -f "${copilot_file}" ] && existing="$(cat "${copilot_file}")" || true

   local updated
   updated="$(printf '%s' "${existing}" | jq \
      --arg name "${server_name}" \
      --arg cmd  "${lsp_command}" \
      --arg kdir "${kitchen_dir}" \
      --argjson exts "${file_extensions}" \
      '.lspServers[$name] = {
         "command": $cmd,
         "args":    ["--background-index", ("--compile-commands-dir=" + $kdir)],
         "fileExtensions": $exts
      }')" \
   || fail "jq failed to build copilot lsp entry"

   if [ -n "${bash_command}" ]
   then
      updated="$(printf '%s' "${updated}" | jq \
         --arg cmd "${bash_command}" \
         '.lspServers["bash"] = {
            "command": $cmd,
            "args":    ["start"],
            "fileExtensions": { ".sh": "shellscript", ".bash": "shellscript" }
         }')" \
      || fail "jq failed to add bash lsp entry for copilot"
   fi

   local copilot_dir
   r_dirname "${copilot_file}"
   copilot_dir="${RVAL}"
   [ ! -d "${copilot_dir}" ] && [ "${copilot_dir}" != "." ] && \
      exekutor mkdir -p "${copilot_dir}"

   redirect_exekutor "${copilot_file}" printf "%s\n" "${updated}" \
      || fail "Could not write ${copilot_file}"
   log_info "Wrote ${copilot_file}"
}


#
# Write config for a single tool entry.
# tool_entry is "toolname:filepath"
#
sde::lsp::write_tool()
{
   log_entry "sde::lsp::write_tool" "$@"

   local tool_entry="$1"
   local lsp_command="$2"
   local lsp_name="$3"
   local kitchen_dir="$4"
   local dialect="$5"
   local bash_command="$6"
   local kiro_json="$7"

   local tool="${tool_entry%%:*}"
   local file="${tool_entry#*:}"

   # resolve defaults if no file was given
   if [ -z "${file}" ]
   then
      sde::lsp::r_tool_defaults "${tool}" || return 1
      file="${RVAL#*:}"
   fi

   local format
   sde::lsp::r_tool_defaults "${tool}" || return 1
   format="${RVAL%%:*}"

   case "${format}" in
      kiro)
         local dir
         r_dirname "${file}"
         dir="${RVAL}"
         [ ! -d "${dir}" ] && [ "${dir}" != "." ] && \
            exekutor mkdir -p "${dir}"
         redirect_exekutor "${file}" printf "%s\n" "${kiro_json}" \
            || fail "Could not write ${file}"
         log_info "Wrote ${file}"
      ;;

      opencode)
         sde::lsp::splice_opencode_json "${file}" \
                                         "${lsp_command}" \
                                         "${kitchen_dir}" \
                                         "${dialect}" \
                                         "${lsp_name}" \
                                         "${bash_command}"
      ;;

      codex)
         sde::lsp::splice_codex_json "${file}" \
                                      "${lsp_command}" \
                                      "${kitchen_dir}" \
                                      "${dialect}" \
                                      "${lsp_name}" \
                                      "${bash_command}"
      ;;

      claude)
         sde::lsp::splice_claude_json "${file}" \
                                       "${lsp_command}" \
                                       "${kitchen_dir}" \
                                       "${dialect}" \
                                       "${lsp_name}" \
                                       "${bash_command}"
      ;;

      copilot)
         sde::lsp::write_copilot_json "${file}" \
                                       "${lsp_command}" \
                                       "${kitchen_dir}" \
                                       "${dialect}" \
                                       "${lsp_name}" \
                                       "${bash_command}"
      ;;
   esac
}


sde::lsp::main()
{
   log_entry "sde::lsp::main" "$@"

   local OPTION_CONFIGURATION="Debug"
   local tool_entries=""   # newline-separated list of "toolname:filepath"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::lsp::usage
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::lsp::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --debug)
            OPTION_CONFIGURATION="Debug"
         ;;

         --release)
            OPTION_CONFIGURATION="Release"
         ;;

         --tool)
            [ $# -eq 1 ] && sde::lsp::usage "Missing argument to \"$1\""
            shift
            local _tool="$1"
            local _file=""
            if [ $# -gt 1 ] && [ "${2:0:1}" != "-" ] && [ "$2" != "help" ]
            then
               shift
               _file="$1"
            fi
            if [ -z "${_file}" ]
            then
               sde::lsp::r_tool_defaults "${_tool}" || sde::lsp::usage "Unknown tool \"${_tool}\""
               _file="${RVAL#*:}"
            fi
            tool_entries="${tool_entries:+${tool_entries}
}${_tool}:${_file}"
         ;;

         # --- deprecated aliases ---
         --save)
            local _file=""
            if [ $# -gt 1 ] && [ "${2:0:1}" != "-" ] && [ "$2" != "help" ]
            then
               shift
               _file="$1"
            fi
            [ -z "${_file}" ] && _file="lsp.json"
            tool_entries="${tool_entries:+${tool_entries}
}save:${_file}"
         ;;

         --kiro)
            local _file=""
            if [ $# -gt 1 ] && [ "${2:0:1}" != "-" ] && [ "$2" != "help" ]
            then
               shift
               _file="$1"
            fi
            [ -z "${_file}" ] && _file=".kiro/settings/lsp.json"
            tool_entries="${tool_entries:+${tool_entries}
}kiro:${_file}"
         ;;

         --opencode)
            local _file=""
            if [ $# -gt 1 ] && [ "${2:0:1}" != "-" ] && [ "$2" != "help" ]
            then
               shift
               _file="$1"
            fi
            [ -z "${_file}" ] && _file="opencode.json"
            tool_entries="${tool_entries:+${tool_entries}
}opencode:${_file}"
         ;;

         -*)
            sde::lsp::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   local dialect

   dialect="${PROJECT_DIALECT:-${PROJECT_LANGUAGE:-c}}"

   log_setting "dialect       : ${dialect}"
   log_setting "configuration : ${OPTION_CONFIGURATION}"

   local lsp_command

   if ! sde::lsp::r_find_lsp_command "${dialect}"
   then
      fail "Could not find an LSP server (mulle-clangd or clangd)"
   fi
   lsp_command="${RVAL}"

   local lsp_name

   sde::lsp::r_lsp_name "${lsp_command}"
   lsp_name="${RVAL}"

   local kitchen_dir

   kitchen_dir="$(rexekutor mulle-craft \
                              ${MULLE_TECHNICAL_FLAGS} \
                              --configuration "${OPTION_CONFIGURATION}" \
                              kitchen-dir)" \
   || fail "Could not determine kitchen directory"

   log_setting "lsp_command : ${lsp_command}"
   log_setting "lsp_name    : ${lsp_name}"
   log_setting "kitchen_dir : ${kitchen_dir}"

   local bash_command=""

   if sde::lsp::r_find_bash_lsp_command
   then
      bash_command="${RVAL}"
      log_setting "bash_command : ${bash_command}"
   fi

   # No --tool given: print kiro JSON to stdout
   if [ -z "${tool_entries}" ]
   then
      sde::lsp::emit_json "${lsp_command}" \
                           "${lsp_name}" \
                           "${kitchen_dir}" \
                           "${dialect}" \
                           "${bash_command}"
      return $?
   fi

   # Capture kiro JSON once; reused by all kiro-format tools
   local kiro_json
   kiro_json="$(sde::lsp::emit_json "${lsp_command}" \
                                     "${lsp_name}" \
                                     "${kitchen_dir}" \
                                     "${dialect}" \
                                     "${bash_command}")"

   local entry
   local IFS_save="${IFS}"
   IFS=$'\n'
   for entry in ${tool_entries}
   do
      IFS="${IFS_save}"
      sde::lsp::write_tool "${entry}" \
                            "${lsp_command}" \
                            "${lsp_name}" \
                            "${kitchen_dir}" \
                            "${dialect}" \
                            "${bash_command}" \
                            "${kiro_json}"
      IFS=$'\n'
   done
   IFS="${IFS_save}"
}
