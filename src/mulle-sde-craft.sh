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
MULLE_SDE_CRAFT_SH="included"


sde_craft_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} craft [options] [target] ...

   Build the dependency folder and/or the project according to target. The
   remaining arguments after target are passed to mulle-craft. See
   \`mulle-craft <project|craftorder> help\` for all the options available.

   The dependency folder is crafted in order of \`mulle-sde craftorder\`.

   The default target is \"${MULLE_SDE_CRAFT_TARGET:-all}\"

   Try ${MULLE_USAGE_NAME} -v craft --serial, if you get compile errors.

Options:
   -h                      : show this usage
   -v                      : show tool output inline
   -q                      : skip uptodate checks
   --clean                 : clean before crafting (see: mulle-sde clean)
   --clean-domain <domain> : clean specific domain before crafting (s.a)
   --run                   : attempt to run produced executable
   --analyze               : run clang analyzer when crafting the project
   --serial                : compile one file at a time

Targets:
   all                     : build dependency folder, then project
   craftorder              : build dependency folder
   <name>                  : name of a single entry in the craftorder
   project                 : build the project

Environment:
   MULLE_SCAN_BUILD               : tool to use for --analyze (mulle-scan-build)
   MULLE_SCAN_BUILD_DIR           : output directory ($KITCHEN_DIR/analyzer)
   MULLE_SDE_MAKE_FLAGS           : flags to be passed to mulle-make (via craft)
   MULLE_SDE_TARGET               : default target (all)
   MULLE_SDE_CRAFT_STYLE          : configuration to build (Debug)
   MULLE_SDE_REFLECT_CALLBACKS    : callbacks called during reflect
   MULLE_SDE_REFLECT_BEFORE_CRAFT : force reflect before craft (${MULLE_SDE_REFLECT_BEFORE_CRAFT:-NO})
EOF
   exit 1
}


sde_perform_fetch_if_needed()
{
   log_entry "sde_perform_fetch_if_needed" "$@"

   local dbrval="$1"

   #
   # This could fetch dependencies if required.
   # A 1 here means we have no sourcetree.
   #
   if [ ${dbrval} -ge 2 ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"

      if [ "${MULLE_SDE_FETCH}" = 'NO' ]
      then
         log_info "Fetching is disabled by environment MULLE_SDE_FETCH"
      else
         log_verbose "Run sourcetree sync"

         eval_exekutor "'${MULLE_SOURCETREE:-mulle-sourcetree}'" \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              "${MULLE_SOURCETREE_FLAGS}" \
                           "sync" \
                               "${OPTION_SYNCFLAGS}" || exit 1

         # run this quickly, because incomplete previous fetches trip me
         # up too often (not doing this since mulle-sde doctor is OK now)
         # exekutor mulle-sde status --stash-only

         if ! rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                        --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS} \
                         ${MULLE_SOURCETREE_FLAGS} \
                       -s \
                     dbstatus
         then
            internal_fail "Database not clean after sync"
         fi
      fi
   fi
}



sde_perform_reflect_if_needed()
{
   log_entry "sde_perform_reflect_if_needed" "$@"

   local target="$1"
   local dbrval="$2"

   local reflectflags
   local tasks

   reflectflags="--if-needed"

   case ":${MULLE_SDE_REFLECT_CALLBACKS}:" in
      *:source:*)
         tasks="source"
      ;;
   esac

   #
   # Make a quick estimate if this is a virgin checkout scenario, by checking
   # if the craftorder file exists.
   # If yes, then lets reflect once. If there is no craftorder file, let's
   # do it
   #
   if [ "${MULLE_SDE_REFLECT_BEFORE_CRAFT}" = 'YES' ]
   then
      log_debug "MULLE_SDE_REFLECT_BEFORE_CRAFT forces reflect"
      reflectflags="" # "force" reflect
   fi

   #
   # Check if we need to reflect the sourcetree.
   # This could fetch dependencies if required.
   # A 1 here means we have no sourcetree.
   #
   if [ ${dbrval} -ge 2 ]
   then
      reflectflags='' # db "force" reflect
   fi

   # run task sourcetree, if present (0) or was dirty (2)
   if [ ${dbrval} -ne 1 ]
   then
      case ":${MULLE_SDE_REFLECT_CALLBACKS}:" in
         *:sourcetree:*)
            tasks="${tasks} sourcetree"
         ;;
      esac
   fi

   if [ "${target}" = 'all' -o "${target}" = 'project' ]
   then
      [ -z "${MULLE_SDE_REFLECT_SH}" ] && \
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-reflect.sh"

      sde_reflect_main ${reflectflags} ${tasks} || exit 1
   fi
}


#
# TODO: option to make a deep check on sourcetrees in addition to shallow
#       only, clean all if an inferior sourcetree is dirty (though this
#       won't catch sourcechanges), so maybe pointless
#
sde_perform_clean_if_needed()
{
   log_entry "sde_perform_clean_if_needed" "$@"

   local dbrval="$1"
   local mode="$2"

   local clean

   #
   # at this point, it's better to clean, because cmake caches might
   # get outdated (sourcetree syncs don't run this often)
   #
   if [ "${mode}" = 'DEFAULT' -a ${dbrval} -ge 2  ]
   then
      clean='YES'
   fi

   if [ "${clean:-${mode}}" = 'YES' ]
   then
      [ -z "${MULLE_SDE_CLEAN_SH}" ] && \
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-clean.sh"

      sde_clean_main --no-test
   fi
}


sde_create_craftorder_if_needed()
{
   log_entry "sde_create_craftorder_if_needed" "$@"

   local target="$1"
   local craftorderfile="$2"
   local cachedir="$3"
   local dbrval="$4"

   #
   # Possibly build a new craftorder file for sourcetree changes
   #
   case "${target}" in
      'craftorder'|'all')
         case ${dbrval} in
            0)
               create_craftorder_file_if_needed "${craftorderfile}" "${cachedir}"
            ;;

            1)
            ;;

            *)
               create_craftorder_file "${craftorderfile}" "${cachedir}"
            ;;
         esac
      ;;
   esac
}


sde_craft_target()
{
   log_entry "sde_craft_target" "$@"

   local target="$1"
   local project_cmdline="$2"
   local craftorder_cmdline="$3"
   local craftorderfile="$4"
   local flags="$5"
   local arguments="$6"

   [ $# -eq 6 ] || internal_fail "API error"

   case "${target}" in
      'all')
         if [ -f "${craftorderfile}" ]
         then
            eval_exekutor "${craftorder_cmdline}" \
                                 --craftorder-file "'${craftorderfile}'" \
                              craftorder \
                                 --no-memo-makeflags "'${flags}'" \
                                 "${arguments}" || return 1
         else
            log_fluff "No craftorderfile so skipping craftorder craft step"
         fi
      ;;

      'craftorder')
         if [ -f "${craftorderfile}" ]
         then
            eval_exekutor "${craftorder_cmdline}" \
                                 --craftorder-file "'${craftorderfile}'" \
                              craftorder \
                                 --no-memo-makeflags "'${flags}'" \
                                 "${arguments}"  || return 1
         else
            log_info "There are no dependencies or libraries to build"
            log_fluff "${craftorderfile} does not exist"
         fi
      ;;

      "")
         internal_fail "target is empty"
      ;;

      *)
         if [ -f "${craftorderfile}" ]
         then
            eval_exekutor "${craftorder_cmdline}" \
                                 --craftorder-file "'${craftorderfile}'" \
                              "${target}" \
                                 --no-memo-makeflags "'${flags}'" \
                                 "${arguments}"  || return 1
         else
            log_info "There are no dependencies or libraries to build"
            log_fluff "${craftorderfile} does not exist"
         fi
      ;;
   esac

   # project doesn't pay of in multiphase
   case "${target}" in
      'project'|'all')
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${target}" \
            eval_exekutor "${project_cmdline}" project "${arguments}"  || return 1
   esac
}

#
# Dont't make it too complicated, mulle-sde craft builds 'all' or the desired
# user selected style.
#
sde_craft_main()
{
   log_entry "sde_craft_main" "$@"

   local target
   local OPTION_REFLECT='YES'
   local OPTION_MOTD='YES'
   local OPTION_RUN='NO'
   local OPTION_CLEAN='DEFAULT'
   local OPTION_SYNCFLAGS

   [ -z "${PROJECT_TYPE}" ] && internal_fail "PROJECT_TYPE is undefined"

   log_debug "PROJECT_TYPE=${PROJECT_TYPE}"

   if [ "${PROJECT_TYPE}" = "none" ]
   then
      target="craftorder"
      OPTION_REFLECT='NO'
   fi

   MULLE_SDE_TARGET="${MULLE_SDE_TARGET:-${MULLE_SDE_CRAFT_TARGET}}"

   target="${target:-${MULLE_SDE_TARGET}}"
   target="${target:-all}"

   while :
   do
      #
      # reparse technical flags here, because we want to have -v and friends
      # even if we use the "craft" alias inside the subshell
      #
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -h|--help|help)
            sde_craft_usage
         ;;

         -q|--quick|no-update|no-reflect)
            OPTION_REFLECT='NO'
         ;;

         --sync-flags)
            OPTION_SYNCFLAGS="$1"
         ;;

         --analyze)
            OPTION_ANALYZE=YES
         ;;

         --analyze-dir)
            [ $# -eq 1 ] && sde_craft_usage "Missing argument to \"$1\""
            shift

            MULLE_SCAN_BUILD_DIR="$1"
         ;;

         --clean)
            OPTION_CLEAN='YES'
         ;;

         --no-clean)
            OPTION_CLEAN='NO'
         ;;

         --clean-domain)
            [ $# -eq 1 ] && sde_craft_usage "Missing argument to \"$1\""
            shift

            [ -z "${MULLE_SDE_CLEAN_SH}" ] && \
               . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-fetch.sh"

            sde_clean_main "$1"
         ;;

         --no-motd)
            OPTION_MOTD='NO'
         ;;

         --run)
            OPTION_RUN='YES'
         ;;

         ''|-*)
            break
         ;;

         *)
            target="$1"
            OPTION_REFLECT='NO'
            shift
            break
         ;;
      esac
      shift
   done

   #
   # our craftorder is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] &&  internal_fail "old mulle-bashfunctions installed"
   [ -z "${MULLE_SDE_CRAFTORDER_SH}" ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftorder.sh"

   local _craftorderfile
   local _cachedir

   __get_craftorder_info

   log_verbose "Check sourcetree for changes"

   #
   # Things to do:
   #
   #  1. possibly sync the sourcetree db/fs/config if needed
   #  2. possibly run a mulle-sde reflect if needed
   #  3. possibly create a new craftorder file
   #  4. possibly clean build
   #
   local dbrval

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      dbrval=3
   else
      rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                    --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_SOURCETREE_FLAGS} \
                    -s \
                     dbstatus
      dbrval="$?"
      log_fluff "dbstatus is $dbrval (0: ok, 1: missing, 2:dirty)"
   fi

   # do the clean first as it wipes the database
   sde_perform_clean_if_needed "${dbrval}" "${OPTION_CLEAN}"

   sde_perform_fetch_if_needed "${dbrval}"

   if [ "${OPTION_REFLECT}" != 'NO' ]
   then
      sde_perform_reflect_if_needed "${target}" "${dbrval}"
   fi

   sde_create_craftorder_if_needed "${target}" \
                                   "${_craftorderfile}" \
                                   "${_cachedir}" \
                                   "${dbrval}"

   #
   # by default, we don't want to see the craftorder verbosity
   # but do like to see project verbosity
   #
   local craftorder_cmdline
   local project_cmdline
   local flags

   flags="${MULLE_TECHNICAL_FLAGS}"

   craftorder_cmdline="'${MULLE_CRAFT:-mulle-craft}' ${flags}"

#
# no more since the warning grepper exists now
#
#   if [ -z "${flags}" -a "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
#   then
#      flags="-v"
#   fi

   project_cmdline="'${MULLE_CRAFT:-mulle-craft}' ${flags}"
   if [ "${OPTION_MOTD}" = 'YES' ]
   then
      project_cmdline="${project_cmdline} '--motd'"
   fi

   if [ "${OPTION_ANALYZE}" = 'YES' ]
   then
      case "${PROJECT_DIALECT}" in
         objc)
            project_cmdline="${MULLE_SCAN_BUILD:-mulle-scan-build} \
                                 ${MULLE_SCAN_BUILD_OPTIONS} \
                                 -o '${MULLE_SCAN_BUILD_DIR:-${KITCHEN_DIR}/analyzer}' \
                                 ${project_cmdline}"
         ;;

         *)
            project_cmdline="${MULLE_SCAN_BUILD:-scan-build} \
                                 ${MULLE_SCAN_BUILD_OPTIONS} \
                                 -o '${MULLE_SCAN_BUILD_DIR:-${KITCHEN_DIR}/analyzer}' \
                                 ${project_cmdline}"
         ;;
      esac
   fi

   local arguments

   if [ "${MULLE_SDE_ALLOW_BUILD_SCRIPT}" = 'YES' ]
   then
      arguments="--allow-script"
   fi

   local mulle_make_flags
   local buildstyle
   local runstyle
   local need_dashdash='YES'
   local i

   while [ $# -ne 0  ]
   do
      if [ "$1" = '--' ]
      then
         need_dashdash='NO'
      fi

      case "$1" in
         --release|--debug|--test)
            buildstyle="${1:2}"
         ;;
      esac

      arguments="${arguments} '$1'"
      shift
   done

   if [ ! -z "${MULLE_CRAFT_MAKE_FLAGS}" ]
   then
      if [ "${need_dashdash}" = 'YES' ]
      then
         arguments="${arguments} '--'"
      fi

      local i

      shell_enable_nullglob
      for i in ${MULLE_CRAFT_MAKE_FLAGS}
      do
         arguments="${arguments} '$i'"
      done
      shell_disable_nullglob
   fi

   buildstyle="${buildstyle:-${MULLE_SDE_CRAFT_STYLE}}"
   case "${buildstyle}" in
      [Rr][Ee][Ll][Ee][Aa][Ss][Ee])
         runstyle="Release"
         arguments=" --release ${arguments}"
      ;;

      [Dd][Ee][Bb][Uu][Gg])
         runstyle="Debug"
         arguments=" --debug ${arguments}"
      ;;

      [Tt][Ee][Ss][Tt])
         arguments="--test --library-style dynamic ${arguments}"
      ;;

      *)
         runstyle="" # erase unknown buildstyle
      ;;
   esac

#   log_fluff "Craft ${C_RESET_BOLD}${target}${C_VERBOSE} of project ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}"

   sde_craft_target "${target}"  \
                    "${project_cmdline}" \
                    "${craftorder_cmdline}" \
                    "${_craftorderfile}" \
                    "${flags}" \
                    "${arguments}" || return 1

   log_verbose "Craft was successful"
   if [ "${OPTION_RUN}" = 'YES' ]
   then
      local executable

      #
      # should ask cmake or someone else for the executable name
      # should check environment for EXECUTABLE_DEBUG or EXECUTABLE_RELEASE
      # and so on
      #
      executable="${KITCHEN_DIR:-kitchen}/${runstyle:-Debug}/${PROJECT_NAME}"
      if [ -x "${executable}" ]
      then
         exekutor "${executable}"
      else
         fail "Can't find executable to run (${executable})"
      fi
   fi
}



sde_craftstatus_main()
{
   log_entry "sde_craftstatus_main" "$@"

   local _craftorderfile
   local _cachedir

   [ -z "${MULLE_SDE_CRAFTORDER_SH}" ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftorder.sh"

   __get_craftorder_info

   if [ ! -f "${_craftorderfile}" ]
   then
      log_info "There is no craftinfo yet. It will be available after the next craft"
      return 1
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_CRAFT:-mulle-craft}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --craftorder-file "${_craftorderfile}" \
                  status \
                     "$@"
}
