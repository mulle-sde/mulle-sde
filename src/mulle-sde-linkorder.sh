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
MULLE_SDE_LINKORDER_SH="included"


sde_linkorder_usage()
{
   [ "$#" -ne 0 ] &&  log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} linkorder [options]

   Emit a string suitable for linking all dependencies and libraries on the
   current platform. The dependencies must have been built in order for this
   to work.

   The linkorder command may produce incorrect link names, if the aliases
   feature is used in a depencency.

   ${MULLE_USAGE_NAME} linkorder -ld

Options:
   --output-format <format>  : specify node,file,file_lf or ld, ld_lf
   --output-omit <library>   : do not emit link commands for library
EOF
   exit 1
}


r_sde_locate_library()
{
   log_entry "r_sde_locate_library" "$@"

   local searchpath="$1"; shift
   local libstyle="$1"; shift
   local require="$1"; shift

   r_platform_search "${searchpath}" \
                     "lib" \
                     "${libstyle}" \
                     "static" \
                     "${require}" \
                     "$@"
}


_emit_file_output()
{
   log_entry "_emit_file_output" "$@"

   local sep="${1: }"; shift
   local quote="${1: }"; shift

   local cmdline
   local filename

   local marks
   local csv

   IFS=$'\n' ; set -f
   for csv in "$@"
   do
      IFS="${DEFAULT_IFS}"; set +f

      filename="${csv%%;*}"

      r_quoted_concat "${result}" "${RVAL}" "${sep}" "${quote}"
      cmdline="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; set +f

   [ ! -z "${cmdline}" ] && rexekutor echo "${cmdline}"
}


emit_file_output()
{
   log_entry "emit_file_output" "$@"

   shift
   shift
   shift

   _emit_file_output " " "" "$@"
}


emit_file_lf_output()
{
   log_entry "emit_file_lf_output" "$@"

   shift
   shift
   shift

   _emit_file_output '$\n' "" "$@"
}


_emit_ld_output()
{
   log_entry "_emit_ld_output" "$@"

   local sep="$1"; shift
   local quote="$1"; shift
   local withldpath="$1"; shift
   local withrpath="$1"; shift
   local wholearchiveformat="$1"; shift

   local result

   if [ "${withldpath}" = 'YES' ]
   then
      r_platform_translate "ldpath" "-L" "${sep}" "${quote}" "${wholearchiveformat}" "$@" || exit 1
      r_concat "${result}" "${RVAL}" "${sep}"
      result="${RVAL}"
   fi

   r_platform_translate "ld" "-l" "${sep}" "${quote}" "${wholearchiveformat}" "$@" || exit 1
   r_concat "${result}" "${RVAL}" "${sep}"
   result="${RVAL}"

   if [ "${withrpath}" = 'YES' ]
   then
      r_platform_translate "rpath" "-Wl,-rpath -Wl," "${sep}" "${quote}" "${wholearchiveformat}" "$@" || exit 1
      r_concat "${result}" "${RVAL}" "${sep}"
      result="${RVAL}"
   fi

   [ ! -z "${result}" ] && rexekutor echo "${result}"
}


emit_ld_output()
{
   log_entry "emit_ld_output" "$@"

   _emit_ld_output " " "" "$@"
}


emit_ld_lf_output()
{
   log_entry "emit_ld_lf_output" "$@"

   _emit_ld_output $'\n' "" "$@"
}


emit_cmake_output()
{
   log_entry "emit_cmake_output" "$@"

   local withldpath="$1"; shift
   local withrpath="$1"; shift
   local wholearchiveformat="$1"; shift

   local line
   local delim

   delim=""
   for line in "$@"
   do
      option="`_emit_ld_output ";" \
                               "" \
                               "${withldpath}" \
                               "${withrpath}" \
                               "${wholearchiveformat}" \
                               "${line}" `"
      printf "${delim}%s" "${option}"
      delim=";"
   done
}


emit_csv_output()
{
   log_entry "emit_csv_output" "$@"

   shift
   shift
   shift

   printf "%s" "$@"
}


emit_node_output()
{
   log_entry "emit_node_output" "$@"

   shift
   shift
   shift

   local line

   for line in "$@"
   do
      echo "${line}"
   done
}



#
# If we are inside dynamic or standalone we just want to list the
# libraries, but not the linked dependencies.
#
linkorder_will_recurse()
{
   log_entry "linkorder_will_recurse" "$@"

   if ! nodemarks_contain "${_marks}" "static-link"
   then
       INSIDE_DYNAMIC="${INSIDE_DYNAMIC}x"
   fi

   if nodemarks_contain "${_marks}" "only-standalone"
   then
       INSIDE_STANDALONE="${INSIDE_STANDALONE}x"
   fi

   return 0
}


linkorder_did_recurse()
{
   log_entry "linkorder_did_recurse" "$@"

   if ! nodemarks_contain "${_marks}" "static-link"
   then
       INSIDE_DYNAMIC="${INSIDE_DYNAMIC%x}"
   fi

   if nodemarks_contain "${_marks}" "only-standalone"
   then
      INSIDE_STANDALONE="${INSIDE_STANDALONE%x}"
   fi
}


linkorder_callback()
{
   log_entry "linkorder_callback (${INSIDE_STANDALONE} ${INSIDE_DYNAMIC})" "$@"

   #
   # collect libraries not marked as dependencies
   #
   if [ ! -z "${INSIDE_STANDALONE}" -o ! -z "${INSIDE_DYNAMIC}"  ] && \
      nodemarks_contain "${_marks}" "dependency"
   then
      # but hit me again later
      walk_remove_from_visited "${WALK_MODE}"
      # walk_remove_from_deduped "${MULLE_DATASOURCE}"
      log_debug "${_address}: skipped emit of dependency due to dynamic/standalone"
      return
   fi

   log_verbose "Add \"${_address}\" to linkorder "

   echo "${_address};${_marks};${_raw_userinfo}"
}


r_sde_linkorder_all_nodes()
{
   log_entry "r_sde_linkorder_all_nodes" "$@"

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      MULLE_SOURCETREE_LIBEXEC_DIR="`"${MULLE_SOURCETREE:-mulle-sourcetree}" libexec-dir`"

      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-environment.sh"  || exit 1
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
      [ -z "${MULLE_SOURCETREE_CRAFTORDER_SH}" ] && \
         . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-craftorder.sh"
   fi

   local INSIDE_STANDALONE
   local INSIDE_DYNAMIC

   mode="`"${MULLE_SOURCETREE:-mulle-sourcetree}" mode`"

   r_make_craftorder_qualifier 'MATCHES link'
   qualifier="${RVAL}"

   sourcetree_environment "" "${MULLE_SOURCETREE_STASH_DIRNAME}" "${mode}"

   RVAL="`sourcetree_walk_main --lenient \
                               --no-eval \
                               --post-order \
                               --backwards \
                               --configuration "Release" \
                               --dedupe "linkorder" \
                               --callback-qualifier "${qualifier}" \
                               --descend-qualifier "${qualifier}" \
                               --will-recurse-callback linkorder_will_recurse \
                               --did-recurse-callback linkorder_did_recurse \
                               --no-callback-trace \
                               linkorder_callback `"

   log_verbose "Reversing lines"
   r_reverse_lines "${RVAL}"
#   r_remove_leading_duplicate_nodes "${RVAL}"
}


#
# local _dependency_libs
# local _optional_dependency_libs
# local _os_specific_libs
#
r_linkorder_collect()
{
   log_entry "r_linkorder_collect" "$@"

   local address="$1"
   local marks="$2"
   local aliases="$3"
   local collect_libraries="$4"
   local searchpath="$5"

   local name

   r_fast_basename "${address}"
   name="${RVAL}"

   local librarytype
   local requirement

   librarytype="library"

   # find dependency lib and
   case ",${marks}," in
      *,only-standalone,*)
         [ -z "${_standalone_load}" ] || \
            fail "Nodes \"${name}\" and \"${_standalone_load}\" both marked as only-standalone"
         _standalone_load="${name}"

         librarytype="standalone"
         log_debug "${name} is a standalone library"
      ;;

      *,only-startup,*)
         [ -z "${_startup_load}" ] || \
            fail "Nodes \"${name}\" and \"${_startup_load%%;*}\" both marked as only-startup"
         _startup_load="${name};${marks}"
         log_debug "${name} is a startup library"
         return 2
      ;;

      *,no-dynamic-link,*)
         requirement="static"
      ;;

      *,no-static-link,*)
         requirement="dynamic"
      ;;
   esac

   case ",${marks},*" in
      *,no-dependency,*)
         # os-library, ignore it unless we do 'ld'
         if [ "${collect_libraries}" = 'NO' ]
         then
            return 2
         fi

         log_fluff "Use OS library \"${name}\""
         r_concat "${name}" "${marks}" ";"
         return 0
      ;;
   esac

   local libpath

   if [ -z "${aliases}" ]
   then
      aliases="${name}"
   fi

   r_sde_locate_library "${searchpath}" "${librarytype}" "${requirement}" ${aliases}
   libpath="${RVAL}"

   [ -z "${libpath}" ] && fail "Did not find a linkable \"${aliases}\" library in \"${searchpath}\".
${C_INFO}The linkorder is available after dependencies have been built.
${C_RESET_BOLD}   mulle-sde clean all
${C_RESET_BOLD}   mulle-sde craft"

   log_fluff "Found library \"${name}\" at \"${libpath}\""

   r_concat "${libpath}" "${marks}" ";"
}


r_library_searchpath()
{
   log_entry "r_library_searchpath" "$@"

   [ -z "${MULLE_PLATFORM_SEARCH_SH}" ] &&
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-search.sh"

   local searchpath
   local configuration

   configuration="${OPTION_CONFIGURATION:-Release}"
   searchpath="`rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS} \
                                      ${MULLE_CRAFT_FLAGS} \
                                      -s \
                                      searchpath \
                                      --if-exists \
                                      --prefix-only \
                                      --configuration "${configuration}" \
                                      library`"
   if [ -z "${searchpath}" ]
   then
      fail "The library searchpath is empty. Have dependencies been built for configuration \"${configuration}\" ?"
   fi

   log_fluff "Library searchpath is: ${searchpath}"
   RVAL="${searchpath}"
}


r_get_emission_lib()
{
   log_entry "r_get_emission_lib" "$@"

   local address="$1"
   local marks="$2"
   local raw_userinfo="$3"
   local searchpath="$4"
   local collect_libraries="$5"

   local aliases
   local userinfo

   aliases=
   userinfo=

   if [ ! -z "${raw_userinfo}" ]
   then
      [ -z "${MULLE_ARRAY_SH}" ] && \
         . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh"

      # TODO: WRONG!! must base64 decode ?
      case "${raw_userinfo}" in
         base64:*)
            userinfo="`base64 --decode <<< "${raw_userinfo:7}"`"
            if [ "$?" -ne 0 ]
            then
               internal_fail "userinfo could not be base64 decoded."
            fi
         ;;

         *)
            userinfo="${raw_userinfo}"
         ;;
      esac

      case "${userinfo}" in
         *aliases*)
            r_assoc_array_get "${userinfo}" "aliases"
            aliases="${RVAL}"
         ;;
      esac
   fi

   # TODO: could remove duplicates with awk
   r_linkorder_collect "${address%#*}" \
                       "${marks}" \
                       "${aliases}" \
                       "${collect_libraries}" \
                       "${searchpath}"
}


r_remove_leading_duplicate_nodes()
{
   local nodes="$1"

   RVAL=

   IFS=$'\n' ; set -f
   for node in ${nodes}
   do
      r_remove_line "${RVAL}" "${node}"
      r_add_line "${RVAL}" "${node}"
   done
   IFS="${DEFAULT_IFS}"; set +f
}


r_collect_emission_libs()
{
   log_entry "r_collect_emission_libs" "$@"

   local nodes="$1"
   local searchpath="$2"
   local collect_libraries="$3"
   local omit="$4"

   local dependency_libs

   local address
   local marks
   local raw_userinfo
   local raw_userinfo

   local _startup_load
   local _standalone_load

   local node

   IFS=$'\n' ; set -f
   for node in ${nodes}
   do
      IFS="${DEFAULT_IFS}"; set +f

      IFS=";" read address marks raw_userinfo <<< "${node}"

      case ",${omit}," in
         *,${address},*)
            continue
         ;;
      esac

      if [ "${OPTION_OUTPUT_FORMAT}" = "node" ]
      then
         line="${address}"
      else
         if ! r_get_emission_lib "${address}" \
                                 "${marks}" \
                                 "${raw_userinfo}" \
                                 "${searchpath}" \
                                 "${collect_libraries}"
         then
            continue
         fi
         line="${RVAL}"
      fi

      RVAL="${dependency_libs}"
      r_remove_line "${RVAL}" "${line}"
      r_add_line "${RVAL}" "${line}"
      dependency_libs="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; set +f

   if [ "${_startup_load}" ]
   then
      RVAL="${dependency_libs}"
      r_remove_line "${RVAL}" "${_startup_load}"
      r_add_line "${RVAL}" "${_startup_load}"
      dependency_libs="${RVAL}"
   fi

   if [ "${OPTION_REVERSE}" = 'YES' ]
   then
      r_reverse_lines "${dependency_libs}"
      dependency_libs="${RVAL}"
   fi

   RVAL=${dependency_libs}
}


#
# linkorder is really complicated! First the dependencies have a specific
# order, which we must respect. Then we want to move common links as far
# down as possible
# So for a -> b -> c
#        d -> e
#        f -> c
#
# We need to emit:
#        a, b, d, e, f, c
#
# Basically its like a craftorder in reverse, but with the dependencies
# of the non-static libraries removed... ugh
#
sde_linkorder_main()
{
   log_entry "sde_linkorder_main" "$@"

   local OPTION_CONFIGURATION="${CONFIGURATIONS%%:*}"
   local OPTION_OUTPUT_FORMAT="ld_lf"
   local OPTION_LD_PATH='YES'
   local OPTION_REVERSE='DEFAULT'
   local OPTION_RPATH='YES'
   local OPTION_FORCE_LOAD='NO'
   local OPTION_WHOLE_ARCHIVE_FORMAT
   local OPTION_OUTPUT_OMIT

   local collect_libraries='YES'

   #
   # load mulle-platform as library, since we would be calling the executable
   # repeatedly
   #
   if [ -z "${MULLE_PLATFORM_LIBEXEC_DIR}" ]
   then
      MULLE_PLATFORM_LIBEXEC_DIR="`exekutor "${MULLE_PLATFORM:-mulle-platform}" libexec-dir`" || exit 1
   fi

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   [ -z "${MULLE_PLATFORM_TRANSLATE_SH}" ] && \
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-translate.sh"

   r_platform_default_whole_archive_format
   OPTION_WHOLE_ARCHIVE_FORMAT="${RVAL}"

   while :
   do
      case "$1" in
         -h|--help|help)
            sde_linkorder_usage
         ;;

         -c|--configuration)
           [ $# -eq 1 ] && sde_linkorder_usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="$1"
         ;;

         --output-rpath)
            OPTION_RPATH='YES'
         ;;

         --output-no-rpath)
            OPTION_RPATH='NO'
         ;;

         --output-ld-path)
            OPTION_LD_PATH='YES'
         ;;

         --output-no-ld-path)
            OPTION_LD_PATH='NO'
         ;;

         --output-omit)
            [ $# -eq 1 ] && sde_linkorder_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_OUTPUT_OMIT}" "$1"
            OPTION_OUTPUT_OMIT="${RVAL}"
         ;;

         --no-libraries)
            collect_libraries='NO'
         ;;

         --reverse)
            OPTION_REVERSE="YES"
         ;;

         --no-reverse)
            OPTION_REVERSE="NO"
         ;;

         --whole-archive-format)
            [ $# -eq 1 ] && sde_linkorder_usage "Missing argument to \"$1\""
            shift

            OPTION_WHOLE_ARCHIVE_FORMAT="$1"
         ;;

         --output-format)
            [ $# -eq 1 ] && sde_linkorder_usage "Missing argument to \"$1\""
            shift

            OPTION_OUTPUT_FORMAT="$1"
            case "${OPTION_OUTPUT_FORMAT}" in
               file|file_lf)
                  collect_libraries='NO'
               ;;

               debug|node|cmake|csv|ld|ld_lf)
               ;;

               *)
                  sde_linkorder_usage "Unknown format value \"${OPTION_OUTPUT_FORMAT}\""
               ;;
            esac
         ;;

         -*)
            sde_linkorder_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${DEPENDENCY_DIR}" ] && internal_fail "DEPENDENCY_DIR not defined"


   local nodes
   local name
   local all_loads
   local normal_loads
   local collect

   r_sde_linkorder_all_nodes
   nodes="${RVAL}"

   if [ "${OPTION_OUTPUT_FORMAT}" = "debug" ]
   then
      echo "${RVAL}"
      return 0
   fi

   log_debug "nodes: ${nodes}"

   local searchpath

   if [ "${OPTION_OUTPUT_FORMAT}" != "node" ]
   then
      r_library_searchpath
      searchpath="${RVAL}"
   fi

   r_collect_emission_libs "${nodes}" "${searchpath}" "${collect_libraries}" "${OPTION_OUTPUT_OMIT}"
   dependency_libs="${RVAL}"

   emit_${OPTION_OUTPUT_FORMAT}_output "${OPTION_LD_PATH}" \
                                       "${OPTION_RPATH}" \
                                       "${OPTION_WHOLE_ARCHIVE_FORMAT}" \
                                       ${dependency_libs}
}
