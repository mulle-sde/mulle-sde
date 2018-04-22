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
[ "${TRACE}" = "YES" ] && set -x && : "$0" "$@"


if [ "`type -t "_mulle_match_complete"`" != "function" ]
then
   . "$(mulle-match libexec-dir)/mulle-match-bash-completion.sh"
fi

if [ "`type -t "_mulle_craft_complete"`" != "function" ]
then
   . "$(mulle-craft libexec-dir)/mulle-craft-bash-completion.sh"
fi

# will be loaded by mulle-env

# if [ "`type -t "_mulle_env_complete"`" != "function" ]
# then
#   . "$(mulle-env libexec-dir)/mulle-env-bash-completion.sh"
#fi

if [ "`type -t "_mulle_monitor_complete"`" != "function" ]
then
   . "$(mulle-monitor libexec-dir)/mulle-monitor-bash-completion.sh"
fi

if [ "`type -t "_mulle_sourcetree_complete"`" != "function" ]
then
   . "$(mulle-sourcetree libexec-dir)/mulle-sourcetree-bash-completion.sh"
fi


_mulle_sde_init_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local extensions
   local flags
   local i

   case "$cur" in
      -*)
         COMPREPLY=( $( compgen -W "-m -d -e -s" -- $cur ) )
         return
      ;;
   esac

   case "$prev" in
      init)
         COMPREPLY=( $( compgen -W "-m" -- $cur ) )
      ;;

      -b|--buildtool)
         extensions="`mulle-sde -s extension list buildtool`"
         COMPREPLY=( $( compgen -W "${extensions}" -- $cur ) )
      ;;

      -m|--meta)
         extensions="`mulle-sde -s extension list meta`"
         COMPREPLY=( $( compgen -W "${extensions}" -- $cur ) )
      ;;

      -e|--extra)
         extensions="`mulle-sde -s extension list extra`"
         COMPREPLY=( $( compgen -W "${extensions}" -- $cur ) )
      ;;

      -r|--runtime)
         extensions="`mulle-sde -s extension list runtime`"
         COMPREPLY=( $( compgen -W "${extensions}" -- $cur ) )
      ;;

      -d|--directory)
         COMPREPLY=( $( compgen -d -- "$cur" ) )
      ;;

      -s|--styles)
         if [ "`type -t "_mulle_env_style_complete"`" = "function" ]
         then
            _mulle_env_style_complete "mulle"
         else
             COMPREPLY=( $( compgen -W "mulle/restrict" -- $cur ) )
         fi
      ;;

      # mulle-sde extension usage -r --list-types "mulle-c/c"
      *)
        COMPREPLY=( $( compgen -W "library executable extension empty" -- $cur ) )
      ;;
   esac
}


_mulle_sde_library_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local list

   case "${prev}" in
      get|remove|set)
         list="`mulle-sde library list -- --format "%a\\n" --no-output-header`"
         COMPREPLY=( $( compgen -W "${list}" -- $cur ) )
         return
      ;;

      list)
      ;;

      add)
      ;;

      *)
         COMPREPLY=( $( compgen -W "add get list remove set" -- $cur ) )
      ;;
   esac
}

_mulle_sde_dependency_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local list

   case "${prev}" in
      get|remove|set)
         list="`mulle-sde dependency list -- --format "%a\\n" --no-output-header`"
         COMPREPLY=( $( compgen -W "${list}" -- $cur ) )
         return
      ;;

      list)
      ;;

      add)
      ;;


      *)
         COMPREPLY=( $( compgen -W "add get list remove set" -- $cur ) )
      ;;
   esac
}


_mulle_sde_extension_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local list

   case "${prev}" in
      list|upgrade)
         return
      ;;

      add)
         list="`mulle-sde -s extension list extra`"
         COMPREPLY=( $( compgen -W "${list}" -- $cur ) )
      ;;

      *)
         COMPREPLY=( $( compgen -W "add list upgrade" -- $cur ) )
      ;;
   esac
}


_mulle_sde_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local commands="\
callback
craft
dependency
environment
extension
find
init
library
mark
match
monitor
patternfile
subproject
task
test
unmark
update"

   local state="executable"

   local executable
   local cmd
   local subcmd
   local argument

   local i

   for i in "${COMP_WORDS[@]}"
   do
      case "${state}" in
         executable)
            executable="$i"
            state="flags"
         ;;

         flags)
            case "$i" in
               -*)
                  continue
               ;;
            esac

            cmd="$i"
            state="options"
         ;;

         options)
            case "$i" in
               -[a-z]d|--*dir|-[a-z]f|--*file)
                  state="options-arg"
                  continue
               ;;

               -*)
                  continue
               ;;
            esac

            subcmd="$i"
            state="suboptions"
         ;;

         options-arg)
            state="options"
         ;;

         suboptions)
            case "$i" in
               -[a-z]d|--*dir|-[a-z]f|--*file)
                  state="suboptions-arg"
                  continue
               ;;

               -*)
                  continue
               ;;
            esac

            argument="$i"
            break
         ;;

         suboptions-arg)
            state="suboptions"
         ;;
      esac
   done

#  echo "cmd     : ${cmd}" >&2
#  echo "subcmd  : ${subcmd}" >&2
#  echo "argument: ${argument}" >&2

   case "$cmd" in
      callback)
         _mulle_monitor_complete "$@"
         return 0
      ;;

      craft)
         _mulle_sde_craft_complete "$@"
         return 0
      ;;

      dependency)
         _mulle_sde_dependency_complete "$@"
         return 0
      ;;

      environment)
         _mulle_env_complete "$@"
         return 0
      ;;

      extension)
         _mulle_sde_extension_complete "$@"
         return 0
      ;;

      init)
         _mulle_sde_init_complete "$@"
         return 0
      ;;

      library)
         _mulle_sde_library_complete "$@"
         return 0
      ;;

      match|patternfile)
         _mulle_match_complete "$@"
         return 0
      ;;

      mark|unmark)
         _mulle_sourcetree_complete "$@"
         return 0
      ;;

      task)
         _mulle_monitor_complete "$@"
         return 0
      ;;

      tool)
         _mulle_env_complete "$@"
         return 0
      ;;
   esac

   case "$cur" in
      *)
         COMPREPLY=( $( compgen -W "${commands}" -- $cur ) )
         return 0
      ;;
   esac
}

complete -F _mulle_sde_complete mulle-sde

