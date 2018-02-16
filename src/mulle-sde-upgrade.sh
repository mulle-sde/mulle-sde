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
   common-extension    : upgrade common extension template content
   extra-extension     : upgrade extra extension template content
   runtime-extension   : upgrade runtime extension template content
"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} upgrade [command]*

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
   # handle options
   #
   while :
   do
      case "$1" in
         -h*|--help)
            sde_upgrade_usage
         ;;

         --no-force)
            OPTION_FORCE_OPTION="NO"
         ;;

         -*)
            fail "unknown option \"$1\""
            sde_upgrade_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local style
   local filename

   filename=".mulle-env/etc/style"
   style="`grep -v '^#' <<< "${filename}"`"
   if [ -z "${style}" ]
   then
      fail "mulle-env style could not be determined from \"${filename}\""
   fi

   filename=".mulle-sde/etc/extensions"
   extensions="`grep -v '^#' <<< "${filename}"`"
   if [ -z "${extensions}" ]
   then
      fail "mulle-sde extensions could not be determined from \"${filename}\""
   fi


   #
   # Force: how does it work ?
   # since we'er upgrading we pretty much want -f
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
   options="--no-bin
--no-etc
--no-libexec
--no-init
--no-motd
--no-buildtool-project
--no-common-project
--no-extra-project
--no-runtime-project
--no-buildtool-init
--no-common-init
--no-extra-init
--no-runtime-init
--no-share"

   while :
   do
      if [ "$#" -eq 0 ]
      then
         if [ ! -z "${cmd}" ]
         then
            break
         fi
         cmd="scripts"
      else
         cmd="$1"
         shift
      fi

      case "${cmd}" in
         buildtool-extension)
            options="`egrep -v '--no-buildtool-project|--no-buildtool-init' <<< "${options}" `"
            force="${OPTION_FORCE_OPTION}"
         ;;

         common-extension)
            options="`egrep -v '--no-common-project|--no-common-init' <<< "${options}" `"
            force="${OPTION_FORCE_OPTION}"
         ;;

         extra-extension)
            options="`egrep -v '--no-extra-project|--no-extra-init' <<< "${options}" `"
            force="${OPTION_FORCE_OPTION}"
         ;;

         etc)
            options="`egrep -v '--no-etc' <<< "${options}" `"
         ;;

         project)
            options="`egrep -v '--no-*-project|--no-*-init' <<< "${options}" `"
            force="${OPTION_FORCE_OPTION}"
         ;;

         runtime-extension)
            options="`egrep -v '--no-runtime-project|--no-runtime-init' <<< "${options}" `"
            force="${OPTION_FORCE_OPTION}"
         ;;

         scripts)
            options="`egrep -v '--no-bin|--no-libexec|--no-share' <<< "${options}" `"
         ;;

         *)
            log_error "Unknown command \"${cmd}\""
            sde_upgrade_usage
         ;;
      esac
   done

   # shellcheck source=src/mulle-sde-init.sh
   . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"

   MULLE_FLAG_MAGNUM_FORCE="${force}" \
      sde_init_main ${options} ${style} ${extensions}
}
