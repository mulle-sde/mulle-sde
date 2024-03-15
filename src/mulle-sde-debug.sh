# shellcheck shell=bash
#
#   Copyright (c) 2019 Nat! - Mulle kybernetiK
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
#   may be used to endorse or promote debugs derived from this software
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
MULLE_SDE_DEBUG_SH='included'

sde::debug::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} debug [options] <command>

   Debug support. The debugger is usually gdb or lldb or some variation.
   This command can start a debugger of your choice with the project
   executable. It can also provide helpful output for IDEs.

Commands:
   run                 : debug most recent executable
   sublime-debug       : emit debug settings to place in your .sublime-project
   vscode-debug        : emit debug settings to place in your launch.json

Options:
   -h                  : show this usage
   --configuration <c> : set configuration, like "Debug"
   --debug             : shortcut for --configuration Debug
   --release           : shortcut for --configuration Release
   --restrict          : run debug with restricted environment
   --sdk <sdk>         : set sdk
EOF
   exit 1
}


sde::debug::debug_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} debug [options] [arguments] ...

   Debug the main executable of the given project, with the arguments given.
   The executable will not run within the mulle-sde environment!

Options:
   --  :   pass remaining options as arguments

EOF
   exit 1
}



sde::debug::r_user_choses_debugger()
{
   log_entry "sde::debug::r_user_chosen_debugger" "$@"

   local debuggers="$1"

   local row

   rexekutor mudo -f mulle-menu --title "Choose debugger:" \
                                --final-title "" \
                                --options "${debuggers}"
   row=$?
   log_debug "row=${row}"

   r_line_at_index "${debuggers}" $row
   [ ! -z "${RVAL}" ]
}


sde::debug::r_installed_debuggers()
{
   log_entry "sde::debug::r_installed_debuggers" "$@"

   local debuggers="$1"

   local existing_debuggers
   local debugger

   .foreachpath debugger in ${debuggers}
   .do
      if mudo -f which "${debugger}" > /dev/null
      then
         r_add_line "${existing_debuggers}" "${debugger}"
         existing_debuggers="${RVAL}"
      fi
   .done
   RVAL="${existing_debuggers}"
   log_debug "existing_debuggers: ${existing_debuggers}"
}


sde::debug::r_user_debugger()
{
   log_entry "sde::debug::r_debugger" "$@"

   local choices

   choices="${MULLE_SDE_DEBUGGERS:-mulle-gdb:gdb:lldb}"
   if ! sde::debug::r_installed_debuggers "${choices}"
   then
      fail "No suitable debugger found, please install one of: ${choices}"
   fi

   local debuggers

   debuggers="${RVAL}"

   if ! sde::debug::r_user_choses_debugger "${debuggers}"
   then
      return 1
   fi
}


sde::debug::r_debugger()
{
   log_entry "sde::debug::r_debugger" "$@"

   local debugger="$1"

   if [ ! -z "${debugger}" ]
   then
      debugger="`command -v "${debugger}"`"
   fi

   if [ -z "${debugger}" ]
   then
      sde::debug::r_user_debugger
      debugger="${RVAL}"
   fi

   RVAL="${debugger}"
   [ ! -z "${RVAL}" ]
}



sde::debug::run_main()
{
   log_entry "sde::debug::run_main" "$@"

   local executables

   include "sde::product"

   sde::product::r_executables
   executables="${RVAL}"

   local executable

   if ! sde::product::r_user_choses_executable "${executables}"
   then
      return 1
   fi
   executable="${RVAL}"

   local debugger
   local preference

   if [ "${OPTION_SELECT}" != 'YES' ]
   then
      preference="`rexekutor mulle-sde env --this-user get MULLE_SDE_DEBUGGER_CHOICE 2> /dev/null`"
      log_fluff "Retrieved debugger preference: ${preference}"
   fi

   if ! sde::debug::r_debugger "${preference}"
   then
      return 1
   fi
   debugger="${RVAL}"

   if [ "${debugger}" != "${preference}" ]
   then
      log_verbose "Saving debugger preference: ${debugger}"
      rexekutor mulle-sde env --this-user set MULLE_SDE_DEBUGGER_CHOICE "${debugger}"
   fi

   #
   # gather KITCHEN_DIR
   # gather STASH_DIR
   # gather DEPENDENCY_DIR
   # gather ADDICTION_DIR
   # and pass as environment
   #
   local ADDICTION_DIR
   local DEPENDENCY_DIR
   local KITCHEN_DIR
   local STASH_DIR

   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      ADDICTION_DIR="`mulle-craft addiction-dir`"
      DEPENDENCY_DIR="`mulle-craft dependency-dir`"
      KITCHEN_DIR="`mulle-craft kitchen-dir`"
      STASH_DIR="`mulle-sourcetree stash-dir`"

      export ADDICTION_DIR="${ADDICTION_DIR}"
      export DEPENDENCY_DIR="${DEPENDENCY_DIR}"
      export KITCHEN_DIR="${KITCHEN_DIR}"
      export STASH_DIR="${STASH_DIR}"

      exekutor_trace exekutor_print export ADDICTION_DIR="${ADDICTION_DIR}"
      exekutor_trace exekutor_print export DEPENDENCY_DIR="${DEPENDENCY_DIR}"
      exekutor_trace exekutor_print export KITCHEN_DIR="${KITCHEN_DIR}"
      exekutor_trace exekutor_print export STASH_DIR="${STASH_DIR}"
   fi

   exekutor mudo -f "${debugger}${MULLE_EXE_EXTENSION}" "${executable}" "$@"
}


sde::debug::main()
{
   log_entry "sde::debug::main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_SDK
   local OPTION_EXISTS
   local MUDO_FLAGS="-e"
   local OPTION_SELECT

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::debug::usage
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::debug::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::debug::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
         ;;

         --select|--reselect)
            OPTION_SELECT='YES'
         ;;

         --restrict)
            MUDO_FLAGS=""
         ;;

         --release)
            OPTION_CONFIGURATION="Release"
         ;;

         --debug)
            OPTION_CONFIGURATION="Debug"
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::debug::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-}"

   [ $# -ne 0 ] && shift


   case "${cmd}" in
      sublime-debug)
         include "sde::product"

         if ! sde::product::r_executable
         then
            return 1
         fi

         local executable

         executable="${RVAL}"

         if ! sde::debug::r_debugger "$@"
         then
            return 1
         fi

         local debugger_path

         debugger_path="${RVAL}"

         local kitchen_dir

         kitchen_dir="`rexekutor mulle-sde kitchen-dir`"

         echo "{}" \
         | rexekutor jq "\
if .settings == null then .settings = {} else . end \
| (.settings.sublimegdb_workingdir)  |= \"${kitchen_dir}/Debug\" \
| (.settings.sublimegdb_commandline) |= \"${debugger_path} --interpreter=mi ${executable#${kitchen_dir}/Debug/}\" \
"
      ;;

      vscode-debug)
         include "sde::product"

         if sde::product::r_executable
         then
            local executable

            executable="${RVAL}"

            local executable_name

            r_basename "${executable}"
            executable_name="${RVAL%${MULLE_EXE_EXTENSION}}"

            local kitchen_dir

            kitchen_dir="`rexekutor mulle-sde kitchen-dir`"

            local dependency_dir

            dependency_dir="`rexekutor mulle-sde dependency-dir`"

            local debugger

            if ! sde::debug::r_debugger
            then
               return
            fi
            debugger="${RVAL}"

            local mimode
            local debugtype

            mimode="gdb"
            debugtype="cppdbg"

            case "${RVAL}" in
               *lldb*)
                  mimode="lldb"
               ;;
            esac

            cat <<EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug ${executable_name}",
            "type": "cppdbg",
            "request": "launch",
            "stopAtEntry": true,
            "program": "${executable}",
            "args": [],
            "environment": [],
            "cwd": "${kitchen_dir}",
            "additionalSOLibSearchPath": "${dependency_dir}/Debug/lib:${dependency_dir}/dependency/lib",
            "MIMode": "${mimode}",
            "miDebuggerPath": "${debugger}",
            "preLaunchTask": "Debug"
        }
    ]
}
EOF
         fi
      ;;

      run)
         shift
         sde::debug::run_main "$@"
      ;;

      *)
         sde::debug::run_main "$@"
      ;;
   esac
}



