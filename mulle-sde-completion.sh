# bash completion for mulle-sde

# cache helpers
__mulle_sde_cached_flags=
__mulle_sde_cached_cmds=

__mulle_sde_array_contains() {
  local s="$1"; shift
  local x
  for x in "$@"; do
    [ "$x" = "$s" ] && return 0
  done
  return 1
}

__mulle_sde_unique_words() {
  # usage: __mulle_sde_unique_words list1... -> echoes unique space-separated
  # shellcheck disable=SC2048
  local seen=() out=() w
  for w in $*; do
    __mulle_sde_array_contains "$w" "${seen[@]}" || { seen+=("$w"); out+=("$w"); }
  done
  printf '%s\n' "${out[*]}"
}

__mulle_sde_trim() {
  # trim leading/trailing spaces
  local s="${*}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

__mulle_sde_split_opts_from_help() {
  # parse options from a help/usage text on stdin -> echoes options space-separated
  # heuristics: lines starting with spaces then '-' or '--'
  local line opt list=""
  while IFS= read -r line; do
    case "$line" in
      " -"*|"  -"*|"   -"*)
        # extract tokens that look like options
        # split line into words, take those starting with -
        for opt in $line; do
          case "$opt" in
            -*) 
              # strip trailing punctuation like ',' ':' ')'
              opt="${opt%%[,:)]}"
              # strip trailing '*' etc.
              opt="${opt%%\**}"
              # stop if option contains '[' like [-h]
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

__mulle_sde_flags() {
  if [ -z "$__mulle_sde_cached_flags" ]; then
    # collect global flags from program if possible
    local out
    out="$(mulle-sde --list-flags 2>/dev/null)"
    if [ -z "$out" ]; then
      # fallback (most common ones)
      out="--environment-override --force --git-terminal-prompt --no-search --no-test-check --style --version -h --help help -f -e -N"
    fi
    __mulle_sde_cached_flags="$out"
  fi
  printf '%s\n' "$__mulle_sde_cached_flags"
}

__mulle_sde_commands() {
  if [ -z "$__mulle_sde_cached_cmds" ]; then
    local out
    out="$(mulle-sde commands 2>/dev/null)"
    if [ -z "$out" ]; then
      out="add clean craft craftinfo craftorder craftstatus crun debug definition dependency edit env-identifier environment exec export extension fetch file files get headerorder hostname ignore init init-and-enter install json library libexec-dir linkorder list log mark match migrate monitor move patterncheck patternenv patternfile patternfiles filename patternmatch pat product project project-dir protect recraft reflect reinit remove retest run searchpath set show source-dir sourcetree stash-dir status steal style sub subproject symlink task test tool tool-env treestatus uname unprotect unveil update upgrade username version view"
    fi
    __mulle_sde_cached_cmds="$out"
  fi
  printf '%s\n' "$__mulle_sde_cached_cmds"
}

__mulle_sde_subcommands_from_cmd() {
  # tries dynamic 'mulle-sde <cmd> commands' then static fallbacks
  local cmd="$1"
  local out
  out="$(mulle-sde "$cmd" commands 2>/dev/null)"
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
    return
  fi
  case "$cmd" in
    dependency)
      printf '%s\n' "add binaries craftinfo duplicate downloads etcs export fetch get headers libraries list help info map mark move rcopy remove set shares source-dir unmark"
    ;;
    library)
      printf '%s\n' "add export get list set mark move remove unmark"
    ;;
    subproject)
      printf '%s\n' "add enter get init list makeinfo map mark move remove set unmark update-patternfile commands subcommands"
    ;;
    config)
      printf '%s\n' "copy list name switch remove show get set"
    ;;
    product)
      printf '%s\n' "list symlink run searchpath"
    ;;
    extension)
      printf '%s\n' "add find list meta pimp freshen remove searchpath show usage vendors meta runtime buildtool metas runtimes buildtools vendorpath"
    ;;
    tool)
      printf '%s\n' "list add remove get set link unlink path"
    ;;
    *)
      printf '%s\n' ""
    ;;
  esac
}

__mulle_sde_cmd_options() {
  # try to parse options from `<cmd> -h`
  local cmd="$1"
  local out
  out="$(mulle-sde "$cmd" -h 2>&1)"
  if [ -n "$out" ]; then
    __mulle_sde_split_opts_from_help <<EOF
$out
EOF
    return
  fi
  # fallback empty
  printf '%s\n' ""
}

__mulle_sde_subcmd_options() {
  # parse options for `cmd subcmd` by calling help
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
  local words="$*"
  COMPREPLY=( $(compgen -W "$words" -- "$cur") )
}

__mulle_sde_opt_needs_value() {
  # heuristics: long opts with '=' or options seen in help typically need a value
  # We'll assume every option not a simple boolean starts with patterns below
  case "$1" in
    -D*|-d|--directory|--dir|--project-dir|--source-dir|--kitchen-dir|--dependency-dir|--stash-dir|--addiction-dir|--definition-dir|--tool|--vendor|--name|--oneshot-name|--oneshot-class|--oneshot-category|--file-extension|--extension|--oneshot-extension|--type|--style|--build-type|--build-style|--c-build-type|--c-build-style|--config|--config-name|--platform|--os|--scope|--sdk|--language|--dialect|--project-language|--project-dialect|--scm|--domain|--host|--user|--repo|--tag|--branch|--address|--key|--value|--format|--output-format|--tool|--tool-env|--git-terminal-prompt|--env-name|--env-scope|--ctags-*|--csv-separator|--template-header-file|--template-footer-file|--build-cmd|--install-cmd|--clean-cmd|--git|--zip|--tar)
      return 0
    ;;
  esac
  return 1
}

__mulle_sde_complete_value_for_opt() {
  local prev="$1" cur="$2" cmd="$3" sub="$4"
  # dir-like
  case "$prev" in
    -d|--directory|--project-dir|--source-dir|--kitchen-dir|--dependency-dir|--stash-dir|--addiction-dir|--definition-dir|--tool|--vendorpath|--vendor-path)
      __mulle_sde_complete_dirs "$cur"; return;;
  esac
  # file-like
  case "$prev" in
    --file|--file-extension|--script|--build-cmd|--install-cmd|--clean-cmd|--template-header-file|--template-footer-file|--project-file)
      __mulle_sde_complete_files "$cur"; return;;
  esac
  # enums
  case "$prev" in
    --os|--platform|--this-os|--this-host)
      local oss
      oss="$(mulle-sde common-unames 2>/dev/null)"
      [ -z "$oss" ] && oss="darwin linux freebsd windows mingw msys sunos"
      __mulle_sde_complete_enums "$cur" $oss
      return
    ;;
    --build-style|--build-type|--c-build-style|--craftorder-build-style)
      __mulle_sde_complete_enums "$cur" "Debug Release RelDebug Test"
      return
    ;;
    --language|--project-language)
      __mulle_sde_complete_enums "$cur" "c objc"
      return
    ;;
    --dialect|--project-dialect)
      __mulle_sde_complete_enums "$cur" "c objc"
      return
    ;;
    --scm|--nodetype)
      __mulle_sde_complete_enums "$cur" "git svn tar zip file clib none local"
      return
    ;;
    --output-format)
      case "$cmd" in
        linkorder) __mulle_sde_complete_enums "$cur" "ld ld_lf file file_lf cmake csv node debug"; return;;
        headerorder) __mulle_sde_complete_enums "$cur" "c objc csv"; return;;
        dependency) __mulle_sde_complete_enums "$cur" "json cmd cmd2 raw csv"; return;;
        library) __mulle_sde_complete_enums "$cur" "json"; return;;
        *)
          __mulle_sde_complete_enums "$cur" "json csv raw"
          return
        ;;
      esac
    ;;
  esac
  # fallback to files
  __mulle_sde_complete_files "$cur"
}

_mulle_sde_complete() {
  local cur prev words cword
  COMPREPLY=()
  words=("${COMP_WORDS[@]}")
  cword=$COMP_CWORD
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  # find first non-flag as potential command
  local i cmd sub
  cmd=""
  sub=""
  for ((i=1; i<cword; i++)); do
    case "${COMP_WORDS[i]}" in
      -*) 
        # skip flag and its value if attached (heuristic)
        continue
      ;;
      *)
        cmd="${COMP_WORDS[i]}"
        # possible subcommand
        if [ $((i+1)) -lt $cword ]; then
          case "${COMP_WORDS[i+1]}" in
            -*) ;;
            *) sub="${COMP_WORDS[i+1]}";;
          esac
        fi
        break
      ;;
    esac
  done

  # if previous is an option that needs value, complete it
  if __mulle_sde_opt_needs_value "$prev"; then
    __mulle_sde_complete_value_for_opt "$prev" "$cur" "$cmd" "$sub"
    return 0
  fi

  # completing options? if current starts with -
  if [[ "$cur" == -* ]]; then
    # before command: offer global flags
    if [ -z "$cmd" ]; then
      local gflags
      gflags="$(__mulle_sde_flags)"
      COMPREPLY=( $(compgen -W "$gflags" -- "$cur") )
      return 0
    fi
    # after command, merge global and command-specific flags
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

  # completing the command itself
  if [ -z "$cmd" ]; then
    local cmds
    cmds="$(__mulle_sde_commands)"
    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
    return 0
  fi

  # completing subcommand if applicable
  if [ -n "$cmd" ] && [ -z "$sub" ] && [ "$prev" = "$cmd" ]; then
    local subs
    subs="$(__mulle_sde_subcommands_from_cmd "$cmd")"
    if [ -n "$subs" ]; then
      COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
      return 0
    fi
  fi

  # special heuristics for arguments based on command/subcommand
  case "$cmd" in
    init)
      # directory after -d handled by option rule; otherwise no strict args
      __mulle_sde_complete_dirs "$cur"; return 0
    ;;
    dependency)
      case "$sub" in
        add|remove|rm|get|set|export|json|'')
          # guess URL or path
          __mulle_sde_complete_files "$cur"; return 0
        ;;
      esac
    ;;
    library)
      case "$sub" in
        add|remove|rm|get|set|export|'')
          COMPREPLY=( $(compgen -W "-l -f --framework --private --optional" -- "$cur") )
          return 0
        ;;
      esac
    ;;
    product)
      case "$sub" in
        run|symlink)
          __mulle_sde_complete_files "$cur"; return 0
        ;;
      esac
    ;;
    run|exec|execute|debug)
      __mulle_sde_complete_files "$cur"; return 0
    ;;
    add|remove|file|files|list|match|patternfile|patternfiles|filename|patternmatch)
      __mulle_sde_complete_files "$cur"; return 0
    ;;
  esac

  # default: complete files and directories
  __mulle_sde_complete_files "$cur"
  return 0
}

complete -F _mulle_sde_complete mulle-sde
