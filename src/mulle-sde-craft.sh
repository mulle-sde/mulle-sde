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
MULLE_SDE_CRAFT_SH='included'


sde::craft::usage()
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

Tip:
   Try ${MULLE_USAGE_NAME} -v craft --serial, if you get compile errors.

   To push CFLAGS to the build process you can do it like this:
      ${MULLE_USAGE_NAME} -DCFLAGS=-H -v craft --clean --serial
   (You need to clean as cmake caches)

Options:
   -h                      : show this usage
   -v                      : show tool output inline
   -C                      : clean all before crafting
   -g                      : clean gravetidy before crafting
   -q                      : skip uptodate checks
   --clean                 : clean before crafting (see: mulle-sde clean)
   --from <domain>         : clean specific depenency before crafting (s.a)
   --run                   : attempt to run produced executable
   --analyze               : run clang analyzer when crafting the project
   --serial                : compile one file at a time
   --build-style <style>   : known styles are Debug/Release/Test/RelDebug

Targets:
   all                     : build dependency folder, then project
   craftorder              : build dependency folder
   <name>                  : name of a single entry in the craftorder
   project                 : build the project

Environment:
   MULLE_SCAN_BUILD               : tool to use for --analyze (mulle-scan-build)
   MULLE_SCAN_BUILD_DIR           : output directory (${KITCHEN_DIR:-kitchen}/analyzer)
   MULLE_SDE_MAKE_FLAGS           : flags to pass to mulle-make via mulle-craft
   MULLE_SDE_TARGET               : default target (all)
   MULLE_SDE_CRAFT_STYLE          : configuration to build (Debug)
   MULLE_SDE_REFLECT_CALLBACKS    : callbacks called during reflect
   MULLE_SDE_REFLECT_BEFORE_CRAFT : force reflect before craft (${MULLE_SDE_REFLECT_BEFORE_CRAFT:-NO})
EOF
   exit 1
}


sde::craft::perform_fetch_if_needed()
{
   log_entry "sde::craft::perform_fetch_if_needed" "$@"

   local dbrval="$1"

   #
   # This could fetch dependencies if required.
   # A 1 here means we have no sourcetree.
   #
   if [ ${dbrval} -ge 2 ]
   then
      include "sde::fetch"

      sde::fetch::do_sync_sourcetree "${OPTION_SERIAL}"
   fi
}


sde::craft::r_perform_craftorder_reflects_if_needed()
{
   log_entry "sde::craft::r_perform_craftorder_reflects_if_needed" "$@"

   local craftorderfile="$1"

   if [ ! -f "${craftorderfile}" ]
   then
      log_fluff "No craftorderfile, so no dependencies to reflect"
      RVAL=""
      return 0
   fi

   local repository
   local filename
   local previous
   local changes
   local actual
   local configname
   local key
   local dependencyname

   changes=""

   include "case"

   local lines

   lines="`sed -e 's/^\([^;]*\).*/\1/' "${craftorderfile}" `"
   .foreachline repository in ${lines}
   .do
      filename="${repository}/${MULLE_SDE_ETC_DIR#"${MULLE_VIRTUAL_ROOT}/"}/reflect"

      # if the file does not exist, this means
      # a) it's not a multi sourcetree project
      # if the file exists, we implicitly know its a mulle-sde project
      if [ ! -f "${filename}" ]
      then
         log_fluff "${repository} has only a single sourcetree"
         .continue
      fi

      r_basename "${repository}"
      dependencyname="${RVAL}"

      r_smart_file_upcase_identifier "${dependencyname}"
      key="MULLE_SOURCETREE_CONFIG_NAME_${RVAL}"

      r_shell_indirect_expand "${key}"
      configname="${RVAL:-config}"

      # if we are in sync, we don't need to reflect
      previous="`grep -E -v '^#' "${filename}" 2> /dev/null `"

      if [ "${previous}" = "${configname}" ]
      then
         log_fluff "${repository#"${MULLE_USER_PWD}/"} is already reflected for sourcetree \"${configname}\""
         .continue
      fi

      # check if the config switch is still around
      actual="`(
         MULLE_VIRTUAL_ROOT=
         rexekutor cd "${repository}" &&
         rexekutor "${MULLE_SDE:-mulle-sde}" ${MULLE_TECHNICAL_FLAGS} \
                                             env get MULLE_SOURCETREE_CONFIG_NAME
      )`"

      if [ -z "${actual}" ]
      then
         actual="config"
      fi

      if [ "${actual}" != "${configname}" ]
      then
         fail "Need config switch for ${repository#"${MULLE_USER_PWD}/"} - currently set to \"${actual}\" - to reflect as \"${configname}\"
${C_INFO}Suggested remedy:
${C_RESET_BOLD}   mulle-sde config switch -d ${dependencyname} ${configname}"
      fi

      log_fluff "${repository#"${MULLE_USER_PWD}/"} may need reflection"

      include "sde::reflect"

      # can easily parallelize, we need to reflect with our settings though
      # but not too many settings.
      (
        MULLE_VIRTUAL_ROOT=
        exekutor cd "${repository}" &&
        rexekutor "${MULLE_SDE:-mulle-sde}" ${MULLE_TECHNICAL_FLAGS} \
                                            reflect
      )

      case $? in
         0)
         ;;

         1)
            RVAL=""
            return 1
         ;;

         2)
            r_colon_concat "${changes}" "${repository}"
            changes="${RVAL}"
         ;;
      esac
   .done

   RVAL="${changes}"
   return 0
}


sde::craft::perform_mainproject_reflect_if_needed()
{
   log_entry "sde::craft::perform_mainproject_reflect_if_needed" "$@"

   local target="$1"
   local dbrval="$2"

   local reflectflags
   local tasks

   tasks=""
   reflectflags="--if-needed"

   case ":${MULLE_SDE_REFLECT_CALLBACKS:-}:" in
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
   if [ "${MULLE_SDE_REFLECT_BEFORE_CRAFT:-}" = 'YES' ]
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
      case ":${MULLE_SDE_REFLECT_CALLBACKS:-}:" in
         *:sourcetree:*)
            r_concat "${tasks}" "sourcetree"
            tasks="${RVAL}"
         ;;
      esac
   fi

   if [ "${target}" = 'all' -o "${target}" = 'project' ]
   then
      ! [ ${MULLE_SDE_REFLECT_SH+x} ] && \
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-reflect.sh"

      sde::reflect::main ${reflectflags} ${tasks} || fail "reflect fail" 1
   fi
}


#
# TODO: option to make a deep check on sourcetrees in addition to shallow
#       only, clean all if an inferior sourcetree is dirty (though this
#       won't catch sourcechanges), so maybe pointless
#
sde::craft::perform_clean_if_needed()
{
   log_entry "sde::craft::perform_clean_if_needed" "$@"

   local dbrval="$1"
   local mode="${2:-DEFAULT}"

   local cleandomain

   #
   # at this point, it's better to clean, because cmake caches might
   # get outdated (sourcetree syncs don't run this often)
   #
   case "${mode}" in
      'DEFAULT')
         if [ "${dbrval}" -lt 2  ]
         then
            return $dbrval
         fi
      ;;

      'NO')
         return $dbrval
      ;;

      'ALL')
         cleandomain='all'
      ;;

      'GRAVETIDY')
         cleandomain='gravetidy'
         dbrval=2
      ;;
   esac

   include "sde::clean"

   log_info "Clean ${C_RESET_BOLD}${cleandomain}"
   sde::clean::main --no-test ${cleandomain}
   return $dbrval
}


sde::craft::create_craftorder_if_needed()
{
   log_entry "sde::craft::create_craftorder_if_needed" "$@"

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
               sde::craftorder::create_file_if_needed "${craftorderfile}" "${cachedir}"
               return $?
            ;;

            1)
            ;;

            *)
               sde::craftorder::create_file "${craftorderfile}" "${cachedir}"
               return $?
            ;;
         esac
      ;;
   esac
}


sde::craft::target()
{
   log_entry "sde::craft::target" "$@"

   local target="$1"
   local project_cmdline="$2"
   local craftorder_cmdline="$3"
   local craftorderfile="$4"
   local flags="$5"
   local arguments="$6"

   [ $# -eq 6 ] || _internal_fail "API error"

   # uses rexekutor because -n flag should be passed down
   case "${target}" in
      'all')
         if [ -f "${craftorderfile}" ]
         then
            eval_rexekutor "${craftorder_cmdline}" \
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
            eval_rexekutor "${craftorder_cmdline}" \
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
         _internal_fail "target is empty"
      ;;

      *)
         if [ -f "${craftorderfile}" ]
         then
            eval_rexekutor "${craftorder_cmdline}" \
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
      'project')
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} ${target}" \
            eval_rexekutor "${project_cmdline}" project "${arguments}"  || return 1
      ;;

      'all')
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME} craft" \
            eval_rexekutor "${project_cmdline}" project "${arguments}"  || return 1
      ;;
   esac
}


sde::craft::r_scan_build_executable()
{
   log_entry "sde::craft::r_scan_build_executable" "$@"

   RVAL="${MULLE_SCAN_BUILD:-}"
   if [ -z "${RVAL}" ]
   then
      case "${PROJECT_DIALECT}" in
         objc)
            case "${MULLE_UNAME}" in
               windows)
                  RVAL="scan-build.exe" # sic
               ;;

               *)
                  RVAL="mulle-scan-build"
               ;;
            esac
         ;;
      esac
   fi

   if [ -z "${RVAL}" ]
   then
      case "${MULLE_UNAME}" in
         windows)
            RVAL="scan-build.exe"
         ;;

         *)
            RVAL="scan-build"
         ;;
      esac
   fi
}


sde::craft::r_scan_build_anaylzer()
{
   log_entry "sde::craft::r_scan_build_anaylzer" "$@"

   local scanbuild="$1"

   RVAL=

   case "${scanbuild}" in
      mulle-scan-build*)
         local compiler

         compiler="`command -v "mulle-clang" `"
         r_resolve_symlinks "${compiler}"
      ;;
   esac
}


#
# Dont't make it too complicated, mulle-sde craft builds 'all' or the desired
# user selected style.
#
sde::craft::main()
{
   log_entry "sde::craft::main" "$@"

   local target=""
   local buildstyle=""
   local OPTION_REFLECT='YES'
   local OPTION_MOTD='YES'
   local OPTION_RUN='NO'
   local OPTION_CLEAN='DEFAULT'
   local OPTION_SYNCFLAGS=""
   local OPTION_ANALYZE=""

   log_debug "PROJECT_TYPE=${PROJECT_TYPE}"

   target="${MULLE_SDE_TARGET:-${MULLE_SDE_CRAFT_TARGET}}"
   if [ "${target}" = "NONE" ]
   then
      log_fluff "MULLE_SDE_TARGET/MULLE_SDE_CRAFT_TARGET is \"NONE\", so nothing will be built"
      return 0
   fi

   if [ "${PROJECT_TYPE}" = "none" ]
   then
      log_fluff "PROJECT_TYPE is \"none\", so only craftorder will be built"
      target="craftorder"
      OPTION_REFLECT='NO'
   fi

   target="${target:-all}"

   while [ $# -ne 0 ]
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
            sde::craft::usage
         ;;

         # clean options
         -c|--clean)
            OPTION_CLEAN='YES'
         ;;

         -a|-C|--all)
            OPTION_CLEAN='ALL'
         ;;

         --clean-domain|--from)
            [ $# -eq 1 ] && sde::craft::usage "Missing argument to \"$1\""
            shift

            include "sde::clean"

            sde::clean::main "$1"
         ;;

         -g|--clean-gravetidy|--gravetidy)
            OPTION_CLEAN='GRAVETIDY'
         ;;

         --no-clean)
            OPTION_CLEAN='NO'
         ;;

         # other options
         --analyze)
            OPTION_ANALYZE=YES
         ;;

         --analyze-dir)
            [ $# -eq 1 ] && sde::craft::usage "Missing argument to \"$1\""
            shift

            MULLE_SCAN_BUILD_DIR="$1"
         ;;


         --build-type|--build-style)
            [ $# -eq 1 ] && sde::craft::usage "Missing argument to \"$1\""
            shift

            buildstyle="$1"
         ;;

         --debug|--release)
            r_capitalize "${1:2}"
            buildstyle="${RVAL}"
         ;;

         --dump-env)
            echo ">>>>>>>>>>>>>>>>>> [ ENV ] >>>>>>>>>>>>>>>>>>>>>>>>" >&2
            rexekutor env | sort >&2
            echo "<<<<<<<<<<<<<<<<<< [ ENV ] <<<<<<<<<<<<<<<<<<<<<<<<" >&2
            exit 1
         ;;

         --no-motd)
            OPTION_MOTD='NO'
         ;;

         -q|--quick|no-update|no-reflect)
            OPTION_REFLECT='NO'
         ;;

         --run)
            OPTION_RUN='YES'
         ;;

         --sync-flags)
            OPTION_SYNCFLAGS="$1"
         ;;

         --serial)
            OPTION_SERIAL='YES'
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
   [ -z "${PROJECT_TYPE}" ] && _internal_fail "PROJECT_TYPE is undefined"
   [ -z "${MULLE_HOSTNAME}" ] &&  _internal_fail "old mulle-bashfunctions installed"
   ! [ ${MULLE_SDE_CRAFTORDER_SH+x} ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftorder.sh"

   local _craftorderfile
   local _cachedir

   sde::craftorder::__get_info

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
                     ${MULLE_TECHNICAL_FLAGS:-} \
                     ${MULLE_SOURCETREE_FLAGS:-} \
                    -s \
                     dbstatus
      dbrval="$?"
      log_verbose "Sourcetree status is $dbrval (0: ok, 1: missing, 2:dirty)"
   fi

   # do the clean first as it wipes the database
   sde::craft::perform_clean_if_needed "${dbrval}" "${OPTION_CLEAN}"
   dbrval=$?

   sde::craft::perform_fetch_if_needed "${dbrval}"

   # reflect after fetch, as we might have gotten (or lost) embedded deps
   if [ "${OPTION_REFLECT}" != 'NO' ]
   then
      sde::craft::perform_mainproject_reflect_if_needed "${target}" "${dbrval}"
   fi

   if ! sde::craft::create_craftorder_if_needed "${target}" \
                                                "${_craftorderfile}" \
                                                "${_cachedir}" \
                                                "${dbrval}"
   then
      fail "Could not create craftorder"
   fi

   #
   # we have to check that our craftorder dependencies have reflected to the
   # same sourcetree name. Usually this should be quick, as this is very rare
   #
   if ! sde::craft::r_perform_craftorder_reflects_if_needed "${_craftorderfile}"
   then
      fail "Could not perform reflects"
   fi

   if [ ! -z "${RVAL}" ]
   then
      log_warning "There have been changes in the dependencies ${RVAL}.
${C_INFO}You may need to make multiple clean all/craft cycles to pick them all up."
   fi

   #
   # there is a possibility, that a reflection changes the craftorder though!
   #

   #
   #
   # by default, we don't want to see the craftorder verbosity
   # but do like to see project verbosity
   #
   local craftorder_cmdline
   local project_cmdline
   local flags

   flags="${MULLE_TECHNICAL_FLAGS:-}"

   craftorder_cmdline="'${MULLE_CRAFT:-mulle-craft}' ${flags}"

#
# no more since the warning grepper exists now
#
#   if [ -z "${flags}" -a "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
#   then
#      flags="-v"
#   fi

   project_cmdline="'${MULLE_CRAFT:-mulle-craft}' ${flags}"

   # keep flags around for no-memo-flags

   if [ "${OPTION_MOTD}" = 'YES' ]
   then
      project_cmdline="${project_cmdline} '--motd'"
   fi

   if [ "${OPTION_ANALYZE}" = 'YES' ]
   then
      local scanbuild

      sde::craft::r_scan_build_executable
      scanbuild="${RVAL}"

      sde::craft::r_scan_build_anaylzer "${scanbuild}"
      analyzer="${RVAL}"

      local cmdline

      cmdline="'${scanbuild}' ${MULLE_SCAN_BUILD_OPTIONS:-} \
-o '${MULLE_SCAN_BUILD_DIR:-${KITCHEN_DIR:-kitchen}}/analyzer'"

      if [ ! -z "${analyzer}" ]
      then
         cmdline="${cmdline} -v --use-analyzer '${analyzer}'"
      fi

      # add some analyzers to default
      #
      cmdline="${cmdline} \
-enable-checker optin.performance.Padding \
-enable-checker optin.portability.UnixAPI \
-enable-checker osx.NumberObjectConversion \
-enable-checker osx.ObjCProperty \
-enable-checker osx.cocoa.AutoreleaseWrite \
-enable-checker osx.cocoa.ClassRelease \
-enable-checker osx.cocoa.Dealloc \
-enable-checker osx.cocoa.ClassRelease \
-enable-checker osx.cocoa.IncompatibleMethodTypes \
-enable-checker osx.cocoa.Loops \
-enable-checker osx.cocoa.MissingSuperCall \
-enable-checker osx.cocoa.Loops \
-enable-checker osx.cocoa.NonNilReturnValue  \
-enable-checker osx.cocoa.Loops \
-enable-checker osx.cocoa.RetainCount \
-enable-checker osx.cocoa.RunLoopAutoreleaseLeak \
-enable-checker osx.cocoa.SelfInit  \
-enable-checker osx.cocoa.SuperDealloc \
-enable-checker osx.cocoa.UnusedIvars \
-enable-checker osx.cocoa.VariadicMethodTypes \
-enable-checker security.FloatLoopCounter \
-enable-checker security.insecureAPI.bzero \
-enable-checker security.insecureAPI.bcopy \
-enable-checker security.insecureAPI.bcmp"

      project_cmdline="${cmdline} ${project_cmdline}"
   fi

   local arguments

   arguments=""
   if [ "${MULLE_SDE_ALLOW_BUILD_SCRIPT:-}" = 'YES' ]
   then
      arguments="--allow-script"
   fi

   local mulle_make_flags

   mulle_make_flags="${MULLE_CRAFT_MAKE_FLAGS}"

   if [ "${OPTION_ANALYZE}" = 'YES' ]
   then
      r_concat "${mulle_make_flags}" "--analyze"
      mulle_make_flags="${RVAL}"
   fi

   local runstyle
   local need_dashdash='YES'

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

      r_concat "${arguments}" "'$1'"
      arguments="${RVAL}"
      shift
   done

   if [ ! -z "${mulle_make_flags:-}" ]
   then
      if [ "${need_dashdash}" = 'YES' ]
      then
         r_concat "${arguments}" '--'
         arguments="${RVAL}"
      fi

      local i

      .for i in ${mulle_make_flags}
      .do
         r_concat "${arguments}" "'$i'"
         arguments="${RVAL}"
      .done
   fi

   if [ -z "${buildstyle:-}" ]
   then
      buildstyle="${MULLE_SDE_CRAFT_STYLE:-}"
      if [ ! -z "${buildstyle:-}" ]
      then
         log_verbose "Buildstyle set from MULLE_SDE_CRAFT_STYLE (${buildstyle})"
      fi
   fi

   case "${buildstyle}" in
      [Rr][Ee][Ll][Ee][Aa][Ss][Ee])
         log_verbose "Buildstyle is Release"
         runstyle="Release"
         r_concat "--release" "${arguments}"
         arguments="${RVAL}"
      ;;

      [Rr][Ee][Ll][Dd][Ee][Bb][Uu][Gg])
         log_verbose "Buildstyle is RelDebug"
         runstyle="RelDebug"
         r_concat "--release-debug" "${arguments}"
         arguments="${RVAL}"
      ;;

      [Dd][Ee][Bb][Uu][Gg])
         log_verbose "Buildstyle is Debug"
         runstyle="Debug"
         r_concat "--debug" "${arguments}"
         arguments="${RVAL}"
      ;;

      [Tt][Ee][Ss][Tt])
         log_verbose "Buildstyle is test"
         r_concat "--test --library-style dynamic" "${arguments}"
         arguments="${RVAL}"
      ;;

      *)
         runstyle="" # erase unknown buildstyle
      ;;
   esac

   if [ "${OPTION_SERIAL}" = 'YES' ]
   then
      r_concat '--serial' "${arguments}"
      arguments="${RVAL}"
   fi

   #
   # always specify is better, because then we don't get accidentally
   # mulle-clang as the C compiler.
   #
   # if plain C, don't emot language
   #if [ "${PROJECT_LANGUAGE}" != "${PROJECT_DIALECT}" ] && \
   #   ! [ "${PROJECT_LANGUAGE}" = "c" -a -z "${PROJECT_DIALECT}" ]
   #then
   # can only do this for the project, which makes it kinda pointless
   #
   #   r_concat "--language c --dialect ${PROJECT_DIALECT}" "${project_cmdline}"
   #   project_cmdline="${RVAL}"
   #fi

   log_fluff "Craft ${C_RESET_BOLD}${target}${C_VERBOSE} of project ${C_MAGENTA}${C_BOLD}${PROJECT_NAME}"

   sde::craft::target "${target}"  \
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


sde::craft::craftstatus_main()
{
   log_entry "sde::craft::craftstatus_main" "$@"

   local _craftorderfile
   local _cachedir

   ! [ ${MULLE_SDE_CRAFTORDER_SH+x} ] && \
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-craftorder.sh"

   sde::craftorder::__get_info

   if [ ! -f "${_craftorderfile}" ]
   then
      log_info "There is no craftinfo yet. It will be available after the next craft"
      return 1
   fi

   MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
      exekutor "${MULLE_CRAFT:-mulle-craft}" \
                     ${MULLE_TECHNICAL_FLAGS:-} \
                     --craftorder-file "${_craftorderfile}" \
                  status \
                     "$@"
}
