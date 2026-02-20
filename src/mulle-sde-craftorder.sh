# shellcheck shell=bash
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
MULLE_SDE_CRAFTORDER_SH='included'


sde::craftorder::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} craftorder [options]

   Show the craftorder of the dependencies. The craftorder is the same for
   all sdks, platforms, configurations. mulle-craft will filter it later.

Options:
   -h                      : show this usage
   --cached                : show the cached craftorder contents
   --names                 : print only names of craftorder dependencies
   --print-craftorder-file : print file path of cached craftorder file
   --remaining             : show what remains uncrafted of a craftorder
EOF
   exit 1
}


sde::craftorder::__get_info()
{
   [ -z "${DEPENDENCY_DIR}" ] && fail "DEPENDENCY_DIR is not set.
${C_INFO}This command must be run inside a mulle-sde virtual environment.
${C_RESET_BOLD}   mulle-sde craft"

   _cachedir="${DEPENDENCY_DIR}/etc"
   _craftorderfile="${_cachedir}/craftorder"
}


#
# this function is injected into the sourcetree walker
# it returns new marks in RVAL
#
sde::craftorder::r_append_mark_no_memo_to_subproject()
{
   local datasource="$1"
   local address="$2"
   local nodetype="$3"
   local marks="$4"

   if [ "${nodetype}" != "local" -o "${datasource}" != "/" ]
   then
      return 1
   fi

   case ",${marks}," in
      *',no-dependency',*)
         return 1
      ;;

      # this is to differentiate craftinfos from subprojects its
      # a hack
      *',no-link,'*)
         return 1
      ;;
   esac

   r_comma_concat "${marks}" "no-memo"
   return 0
}


#
# This should be another task so that it can run in parallel to the other
# updates
#
sde::craftorder::create_file()
{
   log_entry "sde::craftorder::create_file" "$@"

   local craftorderfile="$1"; shift
   local cachedir="$1"; shift

   include "file"
   include "path"

   local rc

   rexekutor mulle-sourcetree -s dbstatus
   rc=$?

   #  0 : yes
   #  1 : no sourcetree
   #  2 : no (not up to date)
   #  3 : no (stash directory changed, needs fetch and clean)

   if [ $rc -gt 1 ]
   then
      log_verbose "Sourcetree is not up to date, needs fectch"
      exekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} fetch --no-quick-check || exit 1
   fi

   log_info "Creating ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}${C_INFO} craftorder"

   local callback

   # get "source" of function into callback
   callback="`declare -f sde::craftorder::r_append_mark_no_memo_to_subproject`"

   local rc

   exekutor mulle-craft dependency begin
   (
      mkdir_if_missing "${cachedir}"

      # remove old file, so if we get CTRL-Ced the state is more reasonable
      remove_file_if_present "${craftorderfile}"

      log_setting "SOURCETREE_MODE=${SOURCETREE_MODE}"
      log_setting "OPTION_PRINT_ENV=${OPTION_PRINT_ENV}"
      log_setting "MULLE_SOURCETREE_STASH_DIR=${MULLE_SOURCETREE_STASH_DIR}"
      log_setting "MULLE_VIRTUAL_ROOT=${MULLE_VIRTUAL_ROOT}"

      text="`rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               -s \
               ${MULLE_TECHNICAL_FLAGS:-} \
            craftorder \
               --no-print-env \
               --callback "${callback}" \
               "$@" `"
      rc=$?
      if [ $rc -ne 0 ]
      then
         fail "mulle-sourcetree failed to produce a craftorder ($rc)"
      fi
      redirect_exekutor "${craftorderfile}" printf "%s\n" "${text}"
   )
   rc=$?

   if [ $rc -eq 0 ]
   then
      exekutor mulle-craft dependency end
   else
      exekutor mulle-craft dependency fail
   fi
   return $rc
}


sde::craftorder::create_file_if_needed()
{
   log_entry "sde::craftorder::create_file_if_needed" "$@"

   local craftorderfile="$1"
   local cachedir="$2"

   #
   # our craftorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  _internal_fail "old mulle-bashfunctions installed"

   if ! [ ${MULLE_SOURCETREE_ETC_DIR+x} ]
   then
      eval `"${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sourcetree`
   fi

   local configname

   configname="${MULLE_SOURCETREE_CONFIG_NAME:-config}"
   configname="${configname%%:*}"

   local sourcetreefile

   sourcetreefile="${MULLE_SOURCETREE_ETC_DIR}/${configname}"
   if [ ! -f "${sourcetreefile}" ]
   then
      sourcetreefile="${MULLE_SOURCETREE_SHARE_DIR}/${configname}"
   fi

   #
   # produce a craftorderfile, if absent or old
   # zsh has different thoughts what -nt means so make -f check
   #
   if [ ! -e "${craftorderfile}" -o "${sourcetreefile}" -nt "${craftorderfile}" ]
   then
      sde::craftorder::create_file "${craftorderfile}" "${cachedir}"
      return $?
   fi

   log_fluff "Craftorder file \"${craftorderfile#"${MULLE_USER_PWD}/"}\" is up-to-date"
}


sde::craftorder::show_cached()
{
   log_entry "sde::craftorder::show_cached" "$@"

   local craftorderfile="$1"

   [ -z "${craftorderfile}" ] && _internal_fail "no craftorderfile location given"

   if [ -f "${craftorderfile}" ]
   then
      log_info "Cached craftorder ${C_RESET_BOLD}(${craftorderfile#"${MULLE_USER_PWD}/"}"
      cat "${craftorderfile}"
      return 0
   fi

   log_info "There is no cached craftorder ${C_RESET_BOLD}${craftorderfile#"${MULLE_USER_PWD}/"}"
   return 1
}


sde::craftorder::show_uncached()
{
   log_entry "sde::craftorder::show_uncached" "$@"

   local callback

   log_info "Craftorder"

   callback="`declare -f sde::craftorder::r_append_mark_no_memo_to_subproject`"
   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     --virtual-root \
                     -s \
                     ${MULLE_TECHNICAL_FLAGS} \
                  craftorder \
                     --callback "${callback}" \
                     "$@"
}


sde::craftorder::list()
{
   log_entry "sde::craftorder::main" "$@"

   local craftorderfile="$1"

   if [ "${OPTION_CACHED}" = 'YES' ]
   then
      if sde::craftorder::show_cached "${craftorderfile}"
      then
         if [ "${OPTION_UNCACHED}" = 'DEFAULT' ]
         then
            OPTION_UNCACHED='NO'
         fi
      fi
   fi

   if [ "${OPTION_UNCACHED}" != 'NO' ]
   then
      sde::craftorder::show_uncached
   fi

   if [ "${OPTION_REMAINING}" != 'YES' ]
   then
      return 0
   fi

   log_info "Remaining"
   if [ -f "${craftorderfile}" ]
   then
      sde::craftorder::show_cached "${craftorderfile}"
      return 0
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_CRAFT:-mulle-craft}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --craftorder-file "${craftorderfile}" \
                  list
}


sde::craftorder::main()
{
   log_entry "sde::craftorder::main" "$@"

   local OPTION_CACHED='YES'
   local OPTION_CREATE='NO'
   local OPTION_NAMES='NO'
   local OPTION_UNCACHED='DEFAULT'
   local OPTION_PRINT_CACHEFILE_PATH='NO'

   #
   # handle options
   #
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::craftorder::usage
         ;;

         --create)
            OPTION_CREATE='YES'
         ;;

         --cached)
            OPTION_CACHED='YES'
         ;;

         --names)
            OPTION_NAMES='YES'
         ;;

         --no-cached)
            OPTION_CACHED='YES'
         ;;

         --uncached)
            OPTION_UNCACHED='YES'
         ;;

         --uncached-if-needed)
            OPTION_UNCACHED='DEFAULT'
         ;;

         --no-uncached)
            OPTION_UNCACHED='YES'
         ;;

         --remaining)
            OPTION_REMAINING='YES'
         ;;

         --print-craftorder-file)
            OPTION_PRINT_CACHEFILE_PATH='YES'
         ;;

         -*)
            sde::craftorder::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] || sde::craftorder::usage "Superflous arguments \"$*\""

   if [ "${OPTION_REMAINING}" = 'YES' -a "${OPTION_CACHED}" = 'YES' ]
   then
      fail "You can not specify --remaining and --cached at the same time"
   fi

   local _craftorderfile
   local _cachedir

   sde::craftorder::__get_info

   if [ "${OPTION_PRINT_CACHEFILE_PATH}" = 'YES'  ]
   then
      printf "%s\n" "${_craftorderfile#"${MULLE_USER_PWD}/"}"
      exit 0
   fi

   if [ "${OPTION_CREATE}" = 'YES'  ]
   then
      sde::craftorder::create_file "${_craftorderfile}" \
                                   "${_cachedir}" \
      || fail "Failed to create craftorderfile"
   fi

   if [ "${OPTION_NAMES}" = 'YES'  ]
   then
      sde::craftorder::list "${_craftorderfile}" | sed 's/.*\/\([^;]*\);.*/\1/'
   else
      sde::craftorder::list "${_craftorderfile}"
   fi
}
