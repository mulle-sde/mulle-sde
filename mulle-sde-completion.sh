# bash completion for mulle-sde
# shellcheck shell=bash
#
# A comprehensive, context-aware completion for the mulle-sde project
# bootstrapping and environment tool.
#
# Discovery strategy:
#   1. Commands    : parsed from `mulle-sde commands` output (cached, stable)
#   2. Subcommands : parsed from the "Commands:" section of `mulle-sde <cmd> -h`
#   3. Options     : parsed from the "Options:" section of `mulle-sde <cmd> -h`
#                    plus the global / technical flag set
#   4. Content     : dynamic queries (dependency/library/config/subproject/...)
#                    cached with a short TTL
#
# Everything is wrapped in caches to keep completion fast even in large
# projects. Every dynamic source has a static fallback so completion never
# breaks when mulle-sde is missing or errors out.

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Number of seconds a dynamic (project specific) list stays cached
__mulle_sde_cache_ttl=15

# ---------------------------------------------------------------------------
# Small generic helpers
# ---------------------------------------------------------------------------

__mulle_sde_has_word() {
  local w="$1"; shift
  local x
  for x in "$@"; do
    [ "$x" = "$w" ] && return 0
  done
  return 1
}

__mulle_sde_unique() {
  local seen=() out=() w
  for w in $*; do
    if ! __mulle_sde_has_word "$w" "${seen[@]}"; then
      seen+=("$w")
      out+=("$w")
    fi
  done
  printf '%s\n' "${out[*]}"
}

# Strip ANSI colour / control sequences from a stream
__mulle_sde_strip_ansi() {
  sed 's/\x1b\[[0-9;]*[[:alpha:]]//g'
}

# ---------------------------------------------------------------------------
# TTL cache (name -> value, value_TS -> timestamp)
#   __mulle_sde_cache_get <name>
#   __mulle_sde_cache_set <name> <value>
# ---------------------------------------------------------------------------

__mulle_sde_cache_get() {
  local name="$1"
  local tsvar vartime now
  tsvar="${name}_TS"
  vartime="$(eval "printf '%s' \"\${${tsvar}-}\"")"
  [ -z "$vartime" ] && return 1
  now="$(date +%s 2>/dev/null)"
  [ -z "$now" ] && return 1
  [ $(( now - vartime )) -ge "$__mulle_sde_cache_ttl" ] && return 1
  eval "printf '%s' \"\${${name}-}\""
  return 0
}

__mulle_sde_static_cache_get() {
  local name="$1"
  eval "printf '%s' \"\${${name}-}\""
  [ -n "$(eval "printf '%s' \"\${${name}-}\"")" ]
}

__mulle_sde_cache_set() {
  local name="$1" value="$2"
  eval "${name}=\"\${value}\""
  eval "${name}_TS=\$(date +%s 2>/dev/null)"
}

__mulle_sde_static_cache_set() {
  local name="$1" value="$2"
  eval "${name}=\"\${value}\""
}

# ---------------------------------------------------------------------------
# Static data (compiled from the mulle-sde dispatch table)
# ---------------------------------------------------------------------------

# Global flags shown by `mulle-sde --list-flags` (cached, extends dynamically)
__mulle_sde_global_flags() {
  if ! __mulle_sde_static_cache_get "__mulle_sde_cached_global_flags"; then
    local flags
    flags="$(mulle-sde --list-flags 2>/dev/null)"
    if [ -z "$flags" ]; then
      flags="--environment-override --force --git-terminal-prompt --no-search --no-test-check --style --version"
    fi
    # Always merge in the mulle-bash technical flag set so completion is
    # useful even when --list-flags misbehaves / is missing.
    flags="$flags
-n --dry-run -s --silent --silent-but-warn -v --verbose
-ld --log-debug -le --log-environment -ls --log-settings -lx --log-exekutor
-lt --trace -tx --trace-immediately -tp --trace-profile
-tpwd --trace-pwd -tfpwd --trace-full-pwd -l- -t-
--mulle-no-color --mulle-no-error --mulle-list-technical-flags
-N --search-nearest --search-as-is --search-here --search-none
--defines -D -d -h --help"
    __mulle_sde_static_cache_set "__mulle_sde_cached_global_flags" "$(__mulle_sde_unique $flags)"
  fi
  printf '%s' "$__mulle_sde_cached_global_flags"
}

# All top-level commands (cached; stable across a session).
# `mulle-sde commands` lists every command including hidden / undocumented
# ones and aliases, so it is the authoritative source.
__mulle_sde_commands() {
  if ! __mulle_sde_static_cache_get "__mulle_sde_cached_commands"; then
    local out
    out="$(mulle-sde commands 2>&1 | awk '{print $1}' | grep -v '^-' | tr '\n' ' ')"
    if [ -z "$out" ]; then
      out="add addiction-dir api bash-completion callback cd check clean commands common-unames config craft craftinfo craftinfos craftorder craftorders craft-status craftstatus crun debug def definition definition-editor definitions dep dependency dependency-dir dependency-eval dependency-exec dependency-ls dependency-open dependency-tree doctor donefile donefiles edit editor enter env env-identifier environment environment-editor exec execute export ext extension fetch file files filename find get headerorder hostname howto ignore init init-and-enter install json kitchen-dir lib libexec-dir libraries library library-path link-args linkorder list log logstatus mark match migrate monitor monitor-editor move pat patterncheck patternenv patternfile patternfile-editor patternfiles patternmatch platform product project project-dir protect recraft reflect reinit remove retest run searchpath set show source-dir sourcetree sourcetree-editor stash-dir status steal style sub subproject subprojects sweatcoding symbol symbols symlink task test todo tool tool-editor tool-env treestatus uname unprotect unveil update upgrade username version vibecoding view"
    fi
    __mulle_sde_static_cache_set "__mulle_sde_cached_commands" "$(__mulle_sde_unique $out)"
  fi
  printf '%s' "$__mulle_sde_cached_commands"
}

# ---------------------------------------------------------------------------
# Help parsing
# ---------------------------------------------------------------------------

# Extract a word list from an indented "Name: value" section of help output.
# First arg: the "Commands:" / "Options:" heading (case-insensitive).
# Reads the raw help from stdin.
__mulle_sde_parse_help_section() {
  local heading="$1"
  awk -v h="$heading" '
    {
      # normalise heading comparison (allow colon, case-insensitive)
      line=$0
      sub(/[ \t]*$/, "", line)
    }
    index(tolower(line), tolower(h)) == 1 && substr(line, length(h)+1, 1) == ":" {
      insec=1
      next
    }
    insec && /^[[:space:]]*$/ { next }
    insec && !/^[[:space:]]+/ { exit }
    insec && /^[[:space:]]+[[:alnum:]_-]+[[:space:]]*:/ {
      match($0, /[[:alnum:]_-]+/)
      print substr($0, RSTART, RLENGTH)
    }
  ' | sort -u
}

# Extract subcommand names for a command from its `-h` output.
__mulle_sde_cmd_subcommands_raw() {
  local cmd="$1"
  mulle-sde "$cmd" -h 2>&1 | __mulle_sde_strip_ansi |
    __mulle_sde_parse_help_section "Commands"
}

# Extract option flags for a command (or command:subcommand) from `-h`.
__mulle_sde_cmd_options_raw() {
  local cmd="$1"
  local sub="${2:-}"
  if [ -z "$sub" ]; then
    mulle-sde "$cmd" -h 2>&1 | __mulle_sde_strip_ansi
  else
    mulle-sde "$cmd" "$sub" -h 2>&1 | __mulle_sde_strip_ansi
  fi | awk '
    /^Options:/ { insec=1; next }
    insec && /^[[:space:]]*$/ { next }
    insec && !/^[[:space:]]+/ { exit }
    insec {
      for (i=1; i<=NF; i++) {
        if ($i ~ /^--?[[:alnum:]-]/) {
          gsub(/[,:]$/, "", $i)
          print $i
        }
      }
    }
  ' | sort -u
}

# ---------------------------------------------------------------------------
# Fallback subcommand maps (used only when dynamic discovery fails)
# ---------------------------------------------------------------------------

__mulle_sde_subcommand_fallback() {
  case "$1" in
    dependency|dep)
      echo "add insert comment config duplicate craftinfo export fetch find get headers libraries list mark move rcopy remove set binaries etcs info shares source-dir unmark"
    ;;
    library|lib|libraries)
      echo "add export get list remove set"
    ;;
    config|sourcetree)
      echo "copy craft dependency get list reflect-configs remove set show"
    ;;
    extension|ext)
      echo "add change find freshen list meta pimp remove searchpath show usage vendors"
    ;;
    patternfile|pat|patternfiles)
      echo "add cat copy edit editor ignore list match remove rename"
    ;;
    definition|def|definitions)
      echo "cat export get keys list remove search set unset"
    ;;
    environment|env)
      echo "change editor get list remove scope set"
    ;;
    subproject|sub|subprojects)
      echo "add enter init list move remove"
    ;;
    callback)
      echo "add cat create list remove run"
    ;;
    task)
      echo "add create kill list ps remove run"
    ;;
    clean)
      echo "all alltestall archive cache craftinfos craftorder default fetch graveyard gravetidy mirror project subprojects test tidy"
    ;;
    craftinfo|craftinfos)
      echo "create export get list readd remove script set show unset"
    ;;
    product)
      echo "list searchpath symlink"
    ;;
    tool)
      echo "add compile doctor editor get link list remove status"
    ;;
    symbol|symbols)
      echo "list"
    ;;
    project)
      echo "rename remove variables"
    ;;
    platform)
      echo "add disable enable get list remove set show"
    ;;
    upgrade)
      echo "project"
    ;;
    *)
      echo ""
    ;;
  esac
}

# ---------------------------------------------------------------------------
# Alias normalisation
#
# Some mulle-sde aliases do NOT route `-h` to the same help as their canonical
# command (e.g. `def -h` prints the wrong usage). Dynamic discovery therefore
# always uses the canonical name. Completing still happen under whatever the
# user typed, since the returned words are offered verbatim.
# ---------------------------------------------------------------------------

__mulle_sde_canonical_cmd() {
  case "$1" in
    def|definitions)            echo definition ;;
    dep)                        echo dependency ;;
    lib|libraries)              echo library ;;
    pat|patternfiles)           echo patternfile ;;
    patternmatch)               echo match ;;
    sub|subprojects)            echo subproject ;;
    symbols)                    echo symbol ;;
    file|files)                 echo list ;;
    execute)                    echo exec ;;
    craftinfos)                 echo craftinfo ;;
    craftorders)                echo craftorder ;;
    craft-status)               echo craftstatus ;;
    donefiles)                  echo donefile ;;
    logstatus)                  echo log ;;
    sourcetree)                 echo config ;;
    vibecode)                   echo vibecoding ;;
    sweatcode)                  echo sweatcoding ;;
    *)                          echo "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
# Public accessors (with caching)
# ---------------------------------------------------------------------------

__mulle_sde_subcommands() {
  local cmd="$1"
  local cc
  cc="$(__mulle_sde_canonical_cmd "$cmd")"
  local cache="__mulle_sde_cached_subs_${cc}"
  if ! __mulle_sde_static_cache_get "$cache"; then
    local out
    out="$(__mulle_sde_cmd_subcommands_raw "$cc" | tr '\n' ' ')"
    if [ -z "$out" ]; then
      out="$(__mulle_sde_subcommand_fallback "$cc")"
    fi
    __mulle_sde_static_cache_set "$cache" "$out"
  fi
  printf '%s' "$(eval "printf '%s' \"\${${cache}-}\"")"
}

__mulle_sde_cmd_options() {
  local cmd="$1"
  local cc
  cc="$(__mulle_sde_canonical_cmd "$cmd")"
  local cache="__mulle_sde_cached_opts_${cc}"
  if ! __mulle_sde_static_cache_get "$cache"; then
    local out
    out="$(__mulle_sde_cmd_options_raw "$cc" | tr '\n' ' ')"
    __mulle_sde_static_cache_set "$cache" "$out"
  fi
  printf '%s' "$(eval "printf '%s' \"\${${cache}-}\"")"
}

__mulle_sde_subcmd_options() {
  local cmd="$1" sub="$2"
  local cc
  cc="$(__mulle_sde_canonical_cmd "$cmd")"
  local cache="__mulle_sde_cached_opts_${cc}_${sub}"
  if ! __mulle_sde_static_cache_get "$cache"; then
    local out
    out="$(__mulle_sde_cmd_options_raw "$cc" "$sub" | tr '\n' ' ')"
    __mulle_sde_static_cache_set "$cache" "$out"
  fi
  printf '%s' "$(eval "printf '%s' \"\${${cache}-}\"")"
}

# ---------------------------------------------------------------------------
# Dynamic content completions (project specific, TTL cached)
# ---------------------------------------------------------------------------

__mulle_sde_list_complete() {
  local cur="$1" cache="$2" cmd="$3" subcmd="${4:-list}"
  shift 4
  local vals
  vals="$(__mulle_sde_cache_get "$cache")"
  if [ -z "$vals" ]; then
    vals="$(mulle-sde "$cmd" "$subcmd" --output-no-header --output-no-marks 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
    [ -z "$vals" ] && vals="$(mulle-sde "$cmd" "$subcmd" 2>/dev/null | awk '{print $1}' | grep -v '^-\|^usage\|^Usage\|command\|Commands' | tr '\n' ' ')"
    __mulle_sde_cache_set "$cache" "$vals"
  fi
  if [ -n "$vals" ]; then
    COMPREPLY=( $(compgen -W "$vals" -- "$cur") )
  else
    __mulle_sde_complete_files "$cur"
  fi
}

__mulle_sde_complete_files() {
  local cur="$1"
  COMPREPLY=( $(compgen -f -- "$cur") )
}

__mulle_sde_complete_dirs() {
  local cur="$1"
  COMPREPLY=( $(compgen -d -- "$cur") )
}

__mulle_sde_complete_enums() {
  local cur="$1"; shift
  COMPREPLY=( $(compgen -W "$*" -- "$cur") )
}

__mulle_sde_complete_dependencies() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_deps" "dependency"
}

__mulle_sde_complete_libraries() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_libs" "library"
}

__mulle_sde_complete_configs() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_configs" "config"
}

__mulle_sde_complete_subprojects() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_subs" "subproject"
}

__mulle_sde_complete_envvars() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_envvars" "environment"
}

__mulle_sde_complete_definitions() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_defs" "definition"
}

__mulle_sde_complete_callbacks() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_callbacks" "callback"
}

__mulle_sde_complete_tasks() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_tasks" "task"
}

__mulle_sde_complete_patternfiles() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_patfiles" "patternfile"
}

__mulle_sde_complete_extensions() {
  __mulle_sde_list_complete "$1" "__mulle_sde_cached_exts" "extension"
}

# ---------------------------------------------------------------------------
# Option value completion
# ---------------------------------------------------------------------------

__mulle_sde_opt_needs_value() {
  case "$1" in
    -D*|-d|--directory|--dir|--project-dir|--source-dir|--kitchen-dir|--dependency-dir|--stash-dir|--addiction-dir|--definition-dir|--tool|--vendor|--vendorpath|--vendor-path|--name|--oneshot-name|--oneshot-class|--oneshot-category|--file-extension|--extension|--type|--style|--build-type|--build-style|--c-build-type|--c-build-style|--craftorder-build-style|--config|--config-name|--configuration|--platform|--os|--scope|--sdk|--language|--dialect|--project-language|--project-dialect|--scm|--domain|--host|--user|--repo|--tag|--branch|--address|--url|--key|--value|--format|--output-format|--csv-separator|--cat|--ctags-*|--ctags-output|--ctags-output-format|--ctags-language|--ctags-kinds|--category|--marks|--nodetype|--subproject|--git-terminal-prompt|--env-name|--env-scope|--include|--qualifier)
      return 0
    ;;
  esac
  return 1
}

__mulle_sde_complete_value_for_opt() {
  local prev="$1" cur="$2" cmd="$3" sub="$4"

  case "$prev" in
    -d|--directory|--project-dir|--source-dir|--kitchen-dir|--dependency-dir|--stash-dir|--addiction-dir|--definition-dir|--vendorpath|--vendor-path)
      __mulle_sde_complete_dirs "$cur"; return
    ;;
  esac

  case "$prev" in
    --file|--file-extension|--script|--build-cmd|--install-cmd|--clean-cmd|--template-header-file|--template-footer-file|--project-file|--address)
      __mulle_sde_complete_files "$cur"; return
    ;;
  esac

  case "$prev" in
    --os|--platform|--this-os|--this-host)
      local oss
      oss="$(mulle-sde common-unames 2>/dev/null)"
      [ -z "$oss" ] && oss="darwin linux freebsd windows mingw msys sunos android"
      __mulle_sde_complete_enums "$cur" $oss
      return
    ;;
    --build-style|--build-type|--c-build-style|--craftorder-build-style|--configuration)
      __mulle_sde_complete_enums "$cur" "Debug Release RelDebug Test Profile"
      return
    ;;
    --language|--project-language)
      __mulle_sde_complete_enums "$cur" "c objc c++ swift"
      return
    ;;
    --dialect|--project-dialect)
      __mulle_sde_complete_enums "$cur" "c objc c++"
      return
    ;;
    --scm|--nodetype)
      __mulle_sde_complete_enums "$cur" "git svn tar zip file clib none local comment"
      return
    ;;
    --output-format|--format)
      case "$cmd" in
        linkorder|link-args) __mulle_sde_complete_enums "$cur" "ld ld_lf file file_lf cmake csv node debug"; return ;;
        headerorder) __mulle_sde_complete_enums "$cur" "c objc csv"; return ;;
        dependency) __mulle_sde_complete_enums "$cur" "json cmd cmd2 raw csv"; return ;;
        library) __mulle_sde_complete_enums "$cur" "json csv"; return ;;
        symbol) __mulle_sde_complete_enums "$cur" "u-ctags e-ctags etags xref json csv"; return ;;
        *) __mulle_sde_complete_enums "$cur" "json csv raw"; return ;;
      esac
    ;;
    --ctags-output|--ctags-output-format|--ctags-format)
      __mulle_sde_complete_enums "$cur" "u-ctags e-ctags etags xref json csv"
      return
    ;;
    --ctags-language)
      __mulle_sde_complete_enums "$cur" "C C++ ObjectiveC Swift Rust Go Java Python JavaScript TypeScript"
      return
    ;;
    --ctags-kinds)
      __mulle_sde_complete_enums "$cur" "f+p c+d+e+f+g+m+n+p+s+t+u+v c+f+m+v f+p+m+c"
      return
    ;;
    --style)
      __mulle_sde_complete_enums "$cur" "none relax restrict inherit wild"
      return
    ;;
    --scope)
      __mulle_sde_complete_enums "$cur" "global extension project local user host os"
      return
    ;;
    --category)
      case "$cmd" in
        symbol) __mulle_sde_complete_enums "$cur" "public-headers headers sources"; return ;;
      esac
    ;;
    --csv-separator)
      __mulle_sde_complete_enums "$cur" '","' '";"' '"|"'
      return
    ;;
    --domain)
      case "$cmd" in
        clean) __mulle_sde_complete_enums "$cur" "all alltestall archive cache craftinfos craftorder default fetch graveyard gravetidy mirror project subprojects test tidy"; return ;;
      esac
    ;;
  esac

  case "$cmd:$sub" in
    dependency:*) __mulle_sde_complete_dependencies "$cur"; return ;;
    library:*) __mulle_sde_complete_libraries "$cur"; return ;;
  esac

  __mulle_sde_complete_files "$cur"
}

# ---------------------------------------------------------------------------
# Context specific positional completion (after sub-command)
# ---------------------------------------------------------------------------

__mulle_sde_complete_positional() {
  local cmd="$1" sub="$2" cur="$3"

  # Directory based
  case "$cmd" in
    init|reinit|init-and-enter|cd|enter|project|fetch|install)
      __mulle_sde_complete_dirs "$cur"; return
    ;;
  esac

  case "$cmd:$sub" in
    subproject:add|subproject:init)
      __mulle_sde_complete_dirs "$cur"; return
    ;;
  esac

  # File based
  case "$cmd:$sub" in
    add:*|remove:*|list:*|file:*|files:*|find:*|move:*|steal:*|symlink:*|protect:*)
      __mulle_sde_complete_files "$cur"; return
    ;;
    patternfile:add|patternfile:match|patternfile:ignore|match:*|filename:*|patterncheck:*)
      __mulle_sde_complete_files "$cur"; return
    ;;
    symbol:*|symbols:*)
      __mulle_sde_complete_files "$cur"; return
    ;;
    run:*|debug:*|crun:*)
      __mulle_sde_complete_files "$cur"; return
    ;;
  esac

  case "$cmd" in
    add|remove|list|file|files|find|move|steal|symlink|protect|unprotect|mark|unmark|match|filename|patterncheck|symbol|symbols|run|debug|exec|execute|reflect|verify|check)
      __mulle_sde_complete_files "$cur"; return
    ;;
  esac

  # Dependency names
  case "$cmd:$sub" in
    dependency:get|dependency:set|dependency:remove|dependency:mark|dependency:unmark|dependency:move|dependency:export|dependency:craftinfo|dependency:duplicate)
      __mulle_sde_complete_dependencies "$cur"; return
    ;;
    craftinfo:get|craftinfo:set|craftinfo:list|craftinfo:remove|craftinfo:create|craftinfo:script|craftinfo:unset|craftinfo:export)
      __mulle_sde_complete_dependencies "$cur"; return
    ;;
    clean:*)
      local domains
      domains="all alltestall archive cache craftinfos craftorder default fetch graveyard gravetidy mirror project subprojects test tidy $(__mulle_sde_subcommand_fallback clean)"
      __mulle_sde_complete_enums "$cur" $domains
      return
    ;;
  esac

  # Library names
  case "$cmd:$sub" in
    library:get|library:set|library:remove|library:export)
      __mulle_sde_complete_libraries "$cur"; return
    ;;
    library:add)
      __mulle_sde_complete_enums "$cur" "-l -f --framework --private --optional"
      return
    ;;
  esac

  # Extension names
  case "$cmd:$sub" in
    extension:add|extension:remove|extension:freshen|extension:change|extension:usage)
      __mulle_sde_complete_extensions "$cur"; return
    ;;
    extension:find)
      __mulle_sde_complete_files "$cur"; return
    ;;
  esac

  # Config names
  case "$cmd:$sub" in
    config:set|config:get|config:copy|config:remove|config:show|config:dependency|config:reflect-configs)
      __mulle_sde_complete_configs "$cur"; return
    ;;
    sourcetree:set|sourcetree:get|sourcetree:copy|sourcetree:remove|sourcetree:show)
      __mulle_sde_complete_configs "$cur"; return
    ;;
  esac

  # Subproject names
  case "$cmd:$sub" in
    subproject:enter|subproject:remove|subproject:move|subproject:get|subproject:set)
      __mulle_sde_complete_subprojects "$cur"; return
    ;;
    sub:enter|sub:remove|sub:move|sub:get|sub:set)
      __mulle_sde_complete_subprojects "$cur"; return
    ;;
  esac

  # Environment variable names
  case "$cmd:$sub" in
    environment:get|environment:set|environment:remove)
      __mulle_sde_complete_envvars "$cur"; return
    ;;
    env:get|env:set|env:remove)
      __mulle_sde_complete_envvars "$cur"; return
    ;;
  esac

  # Definition keys
  case "$cmd:$sub" in
    definition:get|definition:set|definition:remove|definition:unset|definition:keys)
      __mulle_sde_complete_definitions "$cur"; return
    ;;
    def:get|def:set|def:remove|def:unset)
      __mulle_sde_complete_definitions "$cur"; return
    ;;
  esac

  # Callback / task names
  case "$cmd:$sub" in
    callback:cat|callback:remove|callback:run)
      __mulle_sde_complete_callbacks "$cur"; return
    ;;
    task:remove|task:run|task:kill)
      __mulle_sde_complete_tasks "$cur"; return
    ;;
  esac

  # Patternfile names
  case "$cmd:$sub" in
    patternfile:cat|patternfile:edit|patternfile:remove|patternfile:copy|patternfile:rename|patternfile:list)
      __mulle_sde_complete_patternfiles "$cur"; return
    ;;
    pat:cat|pat:edit|pat:remove|pat:copy)
      __mulle_sde_complete_patternfiles "$cur"; return
    ;;
  esac

  # vibecoding / sweatcoding on/off
  case "$cmd" in
    vibecoding|sweatcoding|vibecode|sweatcode)
      if [ -z "$sub" ] && [[ "$cur" != -* ]]; then
        __mulle_sde_complete_enums "$cur" "on off yes no"
        return
      fi
    ;;
  esac

  # Product subcommands
  case "$cmd:$sub" in
    product:symlink|product:searchpath|product:list)
      :
    ;;
  esac

  compopt -o default 2>/dev/null
  COMPREPLY=()
}

# ---------------------------------------------------------------------------
# Main completion entry point
# ---------------------------------------------------------------------------

_mulle_sde_complete() {
  local cur prev words cword
  local i cmd sub next subs
  local word

  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # Identify the command and subcommand chosen so far.
  cmd=""
  sub=""
  for ((i=1; i<COMP_CWORD; i++)); do
    word="${COMP_WORDS[i]}"
    case "$word" in
      '')
        continue
      ;;
      -d)
        # -d takes a directory argument, swallow the following word
        ((i++))
        continue
      ;;
      -D*|--)
        continue
      ;;
      -*)
        # flag that consumes an argument swallows the following word
        if __mulle_sde_opt_needs_value "$word"; then
          ((i++))
        fi
        continue
      ;;
      *)
        if [ -z "$cmd" ]; then
          cmd="$word"
        elif [ -z "$sub" ]; then
          subs="$(__mulle_sde_subcommands "$cmd")"
          if [ -n "$subs" ] && __mulle_sde_has_word "$word" $subs; then
            sub="$word"
          fi
        fi
        continue
      ;;
    esac
  done

  # 1) Complete an option argument.
  if [ -n "$prev" ] && __mulle_sde_opt_needs_value "$prev"; then
    __mulle_sde_complete_value_for_opt "$prev" "$cur" "$cmd" "$sub"
    return 0
  fi

  # 2) Complete an option flag.
  if [[ "$cur" == -* ]]; then
    local opts
    if [ -n "$sub" ]; then
      opts="$(__mulle_sde_subcmd_options "$cmd" "$sub")"
    elif [ -n "$cmd" ]; then
      opts="$(__mulle_sde_cmd_options "$cmd")"
    fi
    __mulle_sde_complete_enums "$cur" $(__mulle_sde_global_flags) $opts
    return 0
  fi

  # 3) Complete a subcommand (right after the main command name).
  if [ -n "$cmd" ] && [ -z "$sub" ]; then
    # only when we are immediately after the command
    if [ "$prev" = "$cmd" ]; then
      subs="$(__mulle_sde_subcommands "$cmd")"
      if [ -n "$subs" ]; then
        __mulle_sde_complete_enums "$cur" $subs
        return 0
      fi
    fi
    # positional argument for the command itself
    __mulle_sde_complete_positional "$cmd" "" "$cur"
    return 0
  fi

  # 4) Complete a positional argument after a subcommand.
  if [ -n "$cmd" ] && [ -n "$sub" ]; then
    __mulle_sde_complete_positional "$cmd" "$sub" "$cur"
    return 0
  fi

  # 5) Complete the top-level command.
  __mulle_sde_complete_enums "$cur" $(__mulle_sde_commands)
  return 0
}

# Register the completion for mulle-sde
complete -F _mulle_sde_complete mulle-sde