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
   etc                 : upgrade .mulle-env etc folder (DANGEROUS!)
   project             : upgrade project template content  (rarely useful)
   scripts             : upgrade .mulle-env folders bin,share,libexec (default)
"

HIDDEN_COMMANDS="\
   buildtool-extension : upgrade buildtool extension template content
   extra-extension     : upgrade extra extension template content
   runtime-extension   : upgrade runtime extension template content
"

    cat <<EOF >&2
Usage:
   ${UPGRADE_USAGE_NAME:-${MULLE_EXECUTABLE_NAME} upgrade [command]*

   Upgrade to a newer mulle-sde version. The default is to upgrade the scripts
   and share data only. Upgrading etc is not recommended, as you would lose
   your customizations. Upgrading project is also not recommended, as you
   could lose changes in your main file and the Makefiles.

Options:
   -h                  : show this usage
   --no-force          : do not overwrite files (used by "project" and
                         "*-extension" only)

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
      filename="${MULLE_SDE_ETC_DIR}c/extensions"
      extensions="`grep -v '^#' < "${filename}"`"
      if [ -z "${extensions}" ]
      then
         fail "mulle-sde extensions could not be determined from \"${filename}\""
      fi
   fi

   projecttype="${OPTION_TYPE}"
   if [ -z "${projecttype}" ]
   then
      filename="${MULLE_SDE_ETC_DIR}/projecttype"
      projecttype="`grep -v '^#' < "${filename}"`"
      if [ -z "${projecttype}" ]
      then
         fail "mulle-sde project-type could not be determined from \"${filename}\""
      fi
   fi

   #
   # Force: how does it work ?
   # since we are upgrading we pretty much want -f
   #
   # But we only need it for project anyway. But then it's usually not
   # convenient to really copy the buildtime templates again.
   # So in general we say force, as that's harmless. For project related
   # stuff it is set to YES, except if the user said --no-force.
   #

   local options
   local cmd
   local force

   force="NO"

   #
   # By default upgrade "bin" "libexec" "share" which is cmd="scripts"
   #
   if [ "$#" -eq 0 ]
   then
   options="\
--no-demo
--no-project"
   else
      options="\
--no-motd
--no-demo
--no-project
\
--no-buildtool-project
--no-extra-project
--no-meta-project
--no-runtime-project
\
--no-buildtool-init
--no-extra-init
--no-meta-init
--no-runtime-init"

      while :
      do
         case "${cmd}" in
            buildtool-extension)
               options="`egrep -v -e '--no-buildtool-project|--no-buildtool-init' <<< "${options}" `"
            ;;

            meta-extension)
               options="`egrep -v -e '--no-meta-project|--no-meta-init' <<< "${options}" `"
            ;;

            extra-extension)
               options="`egrep -v -e '--no-extra-project|--no-extra-init' <<< "${options}" `"
            ;;

            runtime-extension)
               options="`egrep -v -e '--no-runtime-project|--no-runtime-init' <<< "${options}" `"
            ;;

            project)
               options="`egrep -v -e '--no-*-project|--no-*-init' <<< "${options}" `"
            ;;

            *)
               log_error "Unknown command \"${cmd}\""
               sde_upgrade_usage
            ;;
         esac
      done
   fi

   if [ "${OPTION_INIT}" = "NO" ]
   then
      options="`add_line "${options}" "--no-init" `"
   fi

   # shellcheck source=src/mulle-sde-init.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   MULLE_FLAG_MAGNUM_FORCE="${OPTION_FORCE_OPTION}" \
      sde_init_main --no-env ${options} ${style} ${extensions} "${projecttype}"
}
