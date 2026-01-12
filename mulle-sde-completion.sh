# bash completion for mulle-sde
# Generated with comprehensive command analysis

# Cache variables
__mulle_sde_cached_flags=
__mulle_sde_cached_cmds=
__mulle_sde_cached_subcommands=()

# Helper: check if word is in array
__mulle_sde_array_contains() {
  local s="$1"; shift
  local x
  for x in "$@"; do
    [ "$x" = "$s" ] && return 0
  done
  return 1
}

# Helper: unique space-separated words
__mulle_sde_unique_words() {
  local seen=() out=() w
  for w in $*; do
    __mulle_sde_array_contains "$w" "${seen[@]}" || { seen+=("$w"); out+=("$w"); }
  done
  printf '%s\n' "${out[*]}"
}

# Helper: trim whitespace
__mulle_sde_trim() {
  local s="${*}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Helper: extract options from help text
__mulle_sde_split_opts_from_help() {
  local line opt list=""
  while IFS= read -r line; do
    case "$line" in
      " -"*|"  -"*|"   -"*|"    -"*)
        for opt in $line; do
          case "$opt" in
            -*) 
              opt="${opt%%[,:)]}"
              opt="${opt%%\**}"
              case "$opt" in
                \[*|\[*\]*) continue ;;
              esac
              list="$list $opt"
            ;;
          esac
        done
      ;;
    esac
  done
  __mulle_sde_unique_words $list
}

# Get global flags
__mulle_sde_flags() {
  if [ -z "$__mulle_sde_cached_flags" ]; then
    local out
    out="$(mulle-sde --list-flags 2>/dev/null)"
    if [ -z "$out" ]; then
      out="--environment-override --force --git-terminal-prompt --no-search --no-test-check --style --version -h --help help -f -e -N -d -D"
    fi
    __mulle_sde_cached_flags="$out"
  fi
  printf '%s\n' "$__mulle_sde_cached_flags"
}

# Get all main commands
__mulle_sde_commands() {
  if [ -z "$__mulle_sde_cached_cmds" ]; then
    local out
    out="$(mulle-sde commands 2>/dev/null | awk '{print $1}' | grep -v '^-' | tr '\n' ' ')"
    if [ -z "$out" ]; then
      # Fallback: comprehensive command list from source analysis
      out="add addiction-dir api bash-completion callback cd clean commands common-unames config craft craftinfo craftinfos craftorder craftorders craft-status craftstatus crun debug def definition definitions dep dependency dependency-dir doctor donefile donefiles edit editor editors enter env env-identifier environment exec execute export ext extension fetch file filename files find get headerorder hostname howto ignore init init-and-enter install json kitchen-dir lib libexec-dir libraries library library-path linkorder list log mark match migrate monitor move pat patterncheck patternenv patternfile patternfiles patternmatch product project project-dir protect recraft reflect reinit remove retest run searchpath set show source-dir sourcetree stash-dir status steal style sub subproject subprojects sweatcoding symbol symbols symlink task test todo tool tool-env treestatus uname unmark unprotect unveil update upgrade username version vibecoding view"
    fi
    __mulle_sde_cached_cmds="$out"
  fi
  printf '%s\n' "$__mulle_sde_cached_cmds"
}

# Get subcommands for a command
__mulle_sde_subcommands_from_cmd() {
  local cmd="$1"
  
  # Check cache
  if [ -n "${__mulle_sde_cached_subcommands[$cmd]}" ]; then
    printf '%s\n' "${__mulle_sde_cached_subcommands[$cmd]}"
    return
  fi
  
  local out
  # Try dynamic discovery first
  out="$(mulle-sde "$cmd" commands 2>/dev/null | awk '{print $1}' | grep -v '^-' | tr '\n' ' ')"
  
  # Static fallbacks based on source code analysis
  if [ -z "$out" ]; then
    case "$cmd" in
      dependency|dep)
        out="add binaries craftinfo duplicate downloads etcs export fetch get headers help info keys libraries list map mark move rcopy remove set shares source-dir toc unmark"
      ;;
      library|lib|libraries)
        out="add export get list mark move rcopy remove set unmark"
      ;;
      subproject|sub|subprojects)
        out="add enter get init list makeinfo map mark move remove set unmark"
      ;;
      config|sourcetree)
        out="copy get list name remove set show switch"
      ;;
      extension|ext)
        out="add all buildtool buildtools default extra find freshen list meta metas oneshot pimp remove runtime runtimes searchpath show usage vendorpath vendors"
      ;;
      clean)
        out="all alltestall archive cache craftinfos craftorder default fetch graveyard gravetidy mirror project subprojects test tidy"
      ;;
      product)
        out="list searchpath symlink"
      ;;
      tool)
        out="add compile doctor editor get link list remove status"
      ;;
      callback)
        out="add cat create list remove run"
      ;;
      task)
        out="add create kill list ps remove run"
      ;;
      environment|env)
        out="editor get list remove scope set"
      ;;
      patternfile|pat|patternfiles)
        out="add cat copy edit editor ignore list match path remove rename repair status"
      ;;
      definition|def|definitions)
        out="get list remove set"
      ;;
      craftinfo|craftinfos)
        out="get list remove set"
      ;;
      ignore)
        out="add clear list remove"
      ;;
      symbol|symbols)
        out="list"
      ;;
      *)
        out=""
      ;;
    esac
  fi
  
  # Cache result
  __mulle_sde_cached_subcommands[$cmd]="$out"
  
  printf '%s\n' "$out"
}

# Get command-specific options
__mulle_sde_cmd_options() {
  local cmd="$1"
  local out
  out="$(mulle-sde "$cmd" -h 2>&1)"
  if [ -n "$out" ]; then
    __mulle_sde_split_opts_from_help <<EOF
$out
EOF
    return
  fi
  printf '%s\n' ""
}

# Get subcommand-specific options
__mulle_sde_subcmd_options() {
  local cmd="$1" sub="$2"
  local out
  out="$(mulle-sde "$cmd" "$sub" -h 2>&1)"
  if [ -n "$out" ]; then
    __mulle_sde_split_opts_from_help <<EOF
$out
EOF
    return
  fi
  printf '%s\n' ""
}

# Complete files
__mulle_sde_complete_files() {
  local cur="$1"
  COMPREPLY=( $(compgen -f -- "$cur") )
}

# Complete directories
__mulle_sde_complete_dirs() {
  local cur="$1"
  COMPREPLY=( $(compgen -d -- "$cur") )
}

# Complete enum values
__mulle_sde_complete_enums() {
  local cur="$1"; shift
  local words="$*"
  COMPREPLY=( $(compgen -W "$words" -- "$cur") )
}

# Complete dependency names
__mulle_sde_complete_dependencies() {
  local cur="$1"
  local deps
  deps="$(mulle-sde dependency list --output-no-header --output-no-marks 2>/dev/null | awk '{print $1}')"
  if [ -n "$deps" ]; then
    COMPREPLY=( $(compgen -W "$deps" -- "$cur") )
  else
    __mulle_sde_complete_files "$cur"
  fi
}

# Complete library names
__mulle_sde_complete_libraries() {
  local cur="$1"
  local libs
  libs="$(mulle-sde library list --output-no-header --output-no-marks 2>/dev/null | awk '{print $1}')"
  if [ -n "$libs" ]; then
    COMPREPLY=( $(compgen -W "$libs" -- "$cur") )
  else
    __mulle_sde_complete_files "$cur"
  fi
}

# Complete extension names
__mulle_sde_complete_extensions() {
  local cur="$1" type="$2"
  local exts
  case "$type" in
    meta|runtime|buildtool)
      exts="$(mulle-sde extension list 2>/dev/null | grep "^${type}" | awk '{print $2}')"
    ;;
    *)
      exts="$(mulle-sde extension list 2>/dev/null | awk '{print $2}')"
    ;;
  esac
  if [ -n "$exts" ]; then
    COMPREPLY=( $(compgen -W "$exts" -- "$cur") )
  else
    __mulle_sde_complete_files "$cur"
  fi
}

# Check if option needs a value
__mulle_sde_opt_needs_value() {
  case "$1" in
    -D*|-d|--directory|--dir|--project-dir|--source-dir|--kitchen-dir|--dependency-dir|--stash-dir|--addiction-dir|--definition-dir|--tool|--vendor|--vendorpath|--vendor-path|--name|--oneshot-name|--oneshot-class|--oneshot-category|--file-extension|--extension|--oneshot-extension|--type|--style|--build-type|--build-style|--c-build-type|--c-build-style|--config|--config-name|--platform|--os|--scope|--sdk|--language|--dialect|--project-language|--project-dialect|--scm|--domain|--host|--user|--repo|--tag|--branch|--address|--url|--key|--value|--format|--output-format|--tool|--tool-env|--git-terminal-prompt|--env-name|--env-scope|--ctags-*|--csv-separator|--template-header-file|--template-footer-file|--build-cmd|--install-cmd|--clean-cmd|--git|--zip|--tar|--marks|--nodetype|--fetchoptions|--raw-userinfo|--aliases|--include|--qualifier)
      return 0
    ;;
  esac
  return 1
}

# Complete value for an option
__mulle_sde_complete_value_for_opt() {
  local prev="$1" cur="$2" cmd="$3" sub="$4"
  
  # Directory-like options
  case "$prev" in
    -d|--directory|--project-dir|--source-dir|--kitchen-dir|--dependency-dir|--stash-dir|--addiction-dir|--definition-dir|--vendorpath|--vendor-path)
      __mulle_sde_complete_dirs "$cur"; return
    ;;
  esac
  
  # File-like options
  case "$prev" in
    --file|--file-extension|--script|--build-cmd|--install-cmd|--clean-cmd|--template-header-file|--template-footer-file|--project-file)
      __mulle_sde_complete_files "$cur"; return
    ;;
  esac
  
  # Enum options
  case "$prev" in
    --os|--platform|--this-os|--this-host)
      local oss
      oss="$(mulle-sde common-unames 2>/dev/null)"
      [ -z "$oss" ] && oss="darwin linux freebsd windows mingw msys sunos android"
      __mulle_sde_complete_enums "$cur" $oss; return
    ;;
    --build-style|--build-type|--c-build-style|--craftorder-build-style)
      __mulle_sde_complete_enums "$cur" "Debug Release RelDebug Test"; return
    ;;
    --language|--project-language)
      __mulle_sde_complete_enums "$cur" "c objc c++ swift"; return
    ;;
    --dialect|--project-dialect)
      __mulle_sde_complete_enums "$cur" "c objc c++"; return
    ;;
    --scm|--nodetype)
      __mulle_sde_complete_enums "$cur" "git svn tar zip file clib none local comment"; return
    ;;
    --output-format|--format)
      case "$cmd" in
        linkorder) __mulle_sde_complete_enums "$cur" "ld ld_lf file file_lf cmake csv node debug"; return;;
        headerorder) __mulle_sde_complete_enums "$cur" "c objc csv"; return;;
        dependency) __mulle_sde_complete_enums "$cur" "json cmd cmd2 raw csv"; return;;
        library) __mulle_sde_complete_enums "$cur" "json csv"; return;;
        symbol) __mulle_sde_complete_enums "$cur" "u-ctags e-ctags etags xref json csv"; return;;
        *)
          __mulle_sde_complete_enums "$cur" "json csv raw"; return
        ;;
      esac
    ;;
    --ctags-output|--ctags-output-format)
      __mulle_sde_complete_enums "$cur" "u-ctags e-ctags etags xref json csv"; return
    ;;
    --category)
      case "$cmd" in
        symbol) __mulle_sde_complete_enums "$cur" "public-headers headers sources"; return;;
      esac
    ;;
    --csv-separator)
      __mulle_sde_complete_enums "$cur" "\",\" \";\" \"|\""; return
    ;;
    --ctags-language)
      __mulle_sde_complete_enums "$cur" "C C++ ObjectiveC Swift Rust Go Java Python JavaScript TypeScript"; return
    ;;
    --ctags-kinds)
      __mulle_sde_complete_enums "$cur" "f+p c+d+e+f+g+m+n+p+s+t+u+v c+f+m+v f+p+m+c"; return
    ;;
    --style)
      __mulle_sde_complete_enums "$cur" "none relax restrict inherit wild"; return
    ;;
    --scope)
      __mulle_sde_complete_enums "$cur" "global extension project"; return
    ;;
    --domain)
      case "$cmd" in
        clean) __mulle_sde_complete_enums "$cur" "all alltestall archive cache craftinfos craftorder default fetch graveyard gravetidy mirror project subprojects test tidy"; return;;
      esac
    ;;
  esac
  
  # Context-specific completions
  case "$cmd:$sub:$prev" in
    dependency:*:--address|dependency:add:*)
      __mulle_sde_complete_files "$cur"; return
    ;;
    dependency:get:*|dependency:set:*|dependency:remove:*|dependency:mark:*|dependency:unmark:*)
      __mulle_sde_complete_dependencies "$cur"; return
    ;;
    library:get:*|library:set:*|library:remove:*|library:mark:*|library:unmark:*)
      __mulle_sde_complete_libraries "$cur"; return
    ;;
    extension:add:*|extension:remove:*)
      __mulle_sde_complete_extensions "$cur" ""; return
    ;;
  esac
  
  # Default: complete files
  __mulle_sde_complete_files "$cur"
}

# Main completion function
_mulle_sde_complete() {
  local cur prev words cword
  COMPREPLY=()
  words=("${COMP_WORDS[@]}")
  cword=$COMP_CWORD
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  
  # Find first non-flag as potential command
  local i cmd sub
  cmd=""
  sub=""
  for ((i=1; i<cword; i++)); do
    case "${COMP_WORDS[i]}" in
      -d)
        # -d takes directory, skip next word
        ((i++))
        continue
      ;;
      -D*)
        # -D defines, skip
        continue
      ;;
      -*)
        # Other flags, skip
        if __mulle_sde_opt_needs_value "${COMP_WORDS[i]}"; then
          ((i++))
        fi
        continue
      ;;
      *)
        cmd="${COMP_WORDS[i]}"
        # Look for subcommand
        if [ $((i+1)) -lt $cword ]; then
          local next="${COMP_WORDS[i+1]}"
          case "$next" in
            -*) ;;
            *)
              # Check if it's actually a subcommand
              local subs
              subs="$(__mulle_sde_subcommands_from_cmd "$cmd")"
              if [ -n "$subs" ]; then
                for s in $subs; do
                  if [ "$s" = "$next" ]; then
                    sub="$next"
                    break
                  fi
                done
              fi
            ;;
          esac
        fi
        break
      ;;
    esac
  done
  
  # If previous is an option that needs value, complete it
  if __mulle_sde_opt_needs_value "$prev"; then
    __mulle_sde_complete_value_for_opt "$prev" "$cur" "$cmd" "$sub"
    return 0
  fi
  
  # Completing options (current word starts with -)
  if [[ "$cur" == -* ]]; then
    if [ -z "$cmd" ]; then
      # Before command: offer global flags
      local gflags
      gflags="$(__mulle_sde_flags)"
      COMPREPLY=( $(compgen -W "$gflags" -- "$cur") )
      return 0
    fi
    # After command: merge global and command-specific flags
    local cflags gflags
    if [ -n "$sub" ] && [ "$prev" != "$sub" ]; then
      cflags="$(__mulle_sde_subcmd_options "$cmd" "$sub")"
    else
      cflags="$(__mulle_sde_cmd_options "$cmd")"
    fi
    gflags="$(__mulle_sde_flags)"
    COMPREPLY=( $(compgen -W "$gflags $cflags" -- "$cur") )
    return 0
  fi
  
  # Completing the command itself
  if [ -z "$cmd" ]; then
    local cmds
    cmds="$(__mulle_sde_commands)"
    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    return 0
  fi
  
  # Completing subcommand
  if [ -n "$cmd" ] && [ -z "$sub" ]; then
    # Check if we're right after the command
    if [ "$prev" = "$cmd" ] || [ "${COMP_WORDS[i]}" = "$cmd" ]; then
      local subs
      subs="$(__mulle_sde_subcommands_from_cmd "$cmd")"
      if [ -n "$subs" ]; then
        COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
        return 0
      fi
    fi
  fi
  
  # Command/subcommand-specific argument completions
  case "$cmd" in
    init|reinit)
      __mulle_sde_complete_dirs "$cur"; return 0
    ;;
    dependency|dep)
      case "$sub" in
        add)
          # URL or path for dependency add
          __mulle_sde_complete_files "$cur"; return 0
        ;;
        remove|rm|get|set|mark|unmark|export|craftinfo)
          __mulle_sde_complete_dependencies "$cur"; return 0
        ;;
        move|mv)
          __mulle_sde_complete_dependencies "$cur"; return 0
        ;;
        list|''|help)
          # No positional args for list
          ;;
      esac
    ;;
    library|lib|libraries)
      case "$sub" in
        add)
          # Library names or flags
          if [[ "$cur" != -* ]]; then
            COMPREPLY=( $(compgen -W "-l -f --framework --private --optional" -- "$cur") )
          fi
          return 0
        ;;
        remove|rm|get|set|mark|unmark|export)
          __mulle_sde_complete_libraries "$cur"; return 0
        ;;
        move)
          __mulle_sde_complete_libraries "$cur"; return 0
        ;;
      esac
    ;;
    extension|ext)
      case "$sub" in
        add|remove|pimp|freshen)
          __mulle_sde_complete_extensions "$cur" ""; return 0
        ;;
        find)
          __mulle_sde_complete_files "$cur"; return 0
        ;;
      esac
    ;;
    clean)
      case "$sub" in
        ''|help)
          # Domains or dependency names
          local domains="all alltestall archive cache craftinfos craftorder default fetch graveyard gravetidy mirror project subprojects test tidy"
          local deps
          deps="$(mulle-sde dependency list --output-no-header --output-no-marks 2>/dev/null | awk '{print $1}')"
          COMPREPLY=( $(compgen -W "$domains $deps" -- "$cur") )
          return 0
        ;;
      esac
    ;;
    config|sourcetree)
      case "$sub" in
        switch|copy|remove|get|set)
          # Config names
          local configs
          configs="$(mulle-sde config list 2>/dev/null | awk '{print $1}')"
          if [ -n "$configs" ]; then
            COMPREPLY=( $(compgen -W "$configs" -- "$cur") )
          fi
          return 0
        ;;
      esac
    ;;
    subproject|sub)
      case "$sub" in
        add|init)
          __mulle_sde_complete_dirs "$cur"; return 0
        ;;
        enter)
          # Subproject names
          local subs
          subs="$(mulle-sde subproject list 2>/dev/null | awk '{print $1}')"
          if [ -n "$subs" ]; then
            COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
          fi
          return 0
        ;;
        remove|get|set|mark|unmark)
          # Subproject names
          local subs
          subs="$(mulle-sde subproject list 2>/dev/null | awk '{print $1}')"
          if [ -n "$subs" ]; then
            COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
          fi
          return 0
        ;;
      esac
    ;;
    environment|env)
      case "$sub" in
        get|set|remove)
          # Environment variable names
          local envvars
          envvars="$(mulle-sde environment list 2>/dev/null | awk '{print $1}')"
          if [ -n "$envvars" ]; then
            COMPREPLY=( $(compgen -W "$envvars" -- "$cur") )
          fi
          return 0
        ;;
      esac
    ;;
    patternfile|pat)
      case "$sub" in
        edit|cat|remove|rename)
          # Patternfile names
          local patfiles
          patfiles="$(mulle-sde patternfile list 2>/dev/null | awk '{print $1}')"
          if [ -n "$patfiles" ]; then
            COMPREPLY=( $(compgen -W "$patfiles" -- "$cur") )
          else
            __mulle_sde_complete_files "$cur"
          fi
          return 0
        ;;
        add|match|ignore)
          __mulle_sde_complete_files "$cur"; return 0
        ;;
      esac
    ;;
    definition|def)
      case "$sub" in
        get|set|remove)
          # Definition keys
          local keys
          keys="$(mulle-sde definition list 2>/dev/null | awk '{print $1}')"
          if [ -n "$keys" ]; then
            COMPREPLY=( $(compgen -W "$keys" -- "$cur") )
          fi
          return 0
        ;;
      esac
    ;;
    craftinfo)
      case "$sub" in
        get|set|remove)
          # Dependency names for craftinfo
          __mulle_sde_complete_dependencies "$cur"; return 0
        ;;
      esac
    ;;
    callback)
      case "$sub" in
        cat|remove|run)
          # Callback names
          local callbacks
          callbacks="$(mulle-sde callback list 2>/dev/null | awk '{print $1}')"
          if [ -n "$callbacks" ]; then
            COMPREPLY=( $(compgen -W "$callbacks" -- "$cur") )
          fi
          return 0
        ;;
        add|create)
          __mulle_sde_complete_files "$cur"; return 0
        ;;
      esac
    ;;
    task)
      case "$sub" in
        remove|kill|run)
          # Task names
          local tasks
          tasks="$(mulle-sde task list 2>/dev/null | awk '{print $1}')"
          if [ -n "$tasks" ]; then
            COMPREPLY=( $(compgen -W "$tasks" -- "$cur") )
          fi
          return 0
        ;;
        add|create)
          __mulle_sde_complete_files "$cur"; return 0
        ;;
      esac
    ;;
    vibecoding|sweatcoding)
      if [[ "$cur" != -* ]]; then
        COMPREPLY=( $(compgen -W "on off yes no" -- "$cur") )
        return 0
      fi
    ;;
    symbol|symbols)
      if [[ "$cur" != -* ]]; then
        __mulle_sde_complete_files "$cur"; return 0
      fi
    ;;
    run|exec|execute|debug|crun)
      __mulle_sde_complete_files "$cur"; return 0
    ;;
    add|remove|file|files|list|match|filename)
      __mulle_sde_complete_files "$cur"; return 0
    ;;
    cd|enter)
      __mulle_sde_complete_dirs "$cur"; return 0
    ;;
    find|steal|move|symlink|protect|unprotect|mark|unmark)
      __mulle_sde_complete_files "$cur"; return 0
    ;;
  esac
  
  # Default: complete files
  __mulle_sde_complete_files "$cur"
  return 0
}

# Register completion
complete -F _mulle_sde_complete mulle-sde
