#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_SDE_UPDATESUPPORT_SH="included"


sde_upgrade_usage()
{
SHOWN_COMMANDS="\
   project    : upgrade project template content  (rarely useful)
"

    cat <<EOF >&2
Usage:
   ${UPGRADE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME} upgrade [project]

   Upgrade to a newer mulle-sde version. The default is to upgrade the non
   project files only. Upgrading project files is usally also not recommended,
   as you could lose changes.

Options:
   --no-init   : do not run init again

Commands:
EOF

   (
      echo "${SHOWN_COMMANDS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
      then
         echo "${HIDDEN_COMMANDS}"
      fi
   ) | sed '/^$/d' | sort >&2

   cat <<EOF >&2
         (use -v for more commands)
EOF
   exit 1
}


###
### parameters and environment variables
###
sde_upgrade_main()
{
   log_entry "sde_upgrade_main" "$@"

   local OPTION_FORCE_OPTION="YES"

   #
   # experimental options with those you should be able to
   # change project types, build systems and what have you
   #
   local OPTION_EXTENSIONS
   local OPTION_INIT
   local OPTION_TYPE

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help)
            sde_upgrade_usage
         ;;

         --extensions)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_EXTENSIONS="$1"
         ;;

         --type)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_TYPE="$1"
         ;;

         --no-init)
            OPTION_INIT="NO"
         ;;

         --no-force)
            OPTION_FORCE_OPTION="NO"
         ;;

         -*)
            sde_upgrade_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local filename
   local projecttype

   extensions="${OPTION_EXTENSIONS}"
   if [ -z "${extensions}" ]
   then
      extensions="${MULLE_SDE_INSTALLED_EXTENSIONS}"
      if [ -z "${extensions}" ]
      then
         fail "Environment variable MULLE_SDE_INSTALLED_EXTENSIONS not set"
      fi
   fi

   projecttype="${OPTION_TYPE}"
   if [ -z "${projecttype}" ]
   then
      projecttype="${PROJECT_TYPE}"
      if [ -z "${projecttype}" ]
      then
         fail "Environment variable PROJECT_TYPE not set"
      fi
   fi

   local options
   local cmd

   #
   # By default upgrade "share" only
   #
   options="--no-demo
--no-project"

   #
   # support some hackish stuff, ain't documented yet
   # this triggers the various is_disabled_by_marks lines in init
   # that way you can selectively turn on/off part of what to upgrade
   # which might be nice down the road (or not)
   #
   while [ "$#" -ne 0 ]
   do
      case "$1" in
         no-*)
            options="`add_line "${options}" "--$1" `"
         ;;

         *)
            pattern="`escaped_grep_pattern "$1"`"
            options="`egrep -v -e "--no-${pattern}" <<< "${options}" `"
         ;;
      esac
      shift
   done

   if [ "${OPTION_INIT}" = "NO" ]
   then
      options="`add_line "${options}" "--no-init" `"
   fi

   # shellcheck source=src/mulle-sde-init.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   MULLE_FLAG_MAGNUM_FORCE="${OPTION_FORCE_OPTION}" \
      sde_init_main --no-env ${options} ${extensions} "${projecttype}"
}
