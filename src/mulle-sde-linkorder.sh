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

   This command is useful for compiling and linking single sourcefiles.

   The linkorder command may produce incorrect link names, if the aliases
   feature is used.

Options:
   --output-format <format>  : specify node,file,file_lf or ld, ld_lf
EOF
   exit 1
}


r_sde_locate_library()
{
   log_entry "r_sde_locate_library" "$@"

   local libstyle="$1"; shift
   local require="$1"; shift

   [ -z "${MULLE_PLATFORM_SEARCH_SH}" ] &&
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-search.sh"

   r_platform_search "${DEPENDENCY_DIR}:${ADDICTION_DIR}" \
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

   local cmdline
   local filename

   local marks
   local csv

   IFS="
" ; set -f
   for csv in "$@"
   do
      IFS="${DEFAULT_IFS}"; set +f

      filename="${csv%%;*}"

      r_concat "${cmdline}" "${filename}" "${sep}"
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

   local sep=" "
   _emit_file_output "${sep}" "$@"
}


emit_file_lf_output()
{
   log_entry "emit_file_lf_output" "$@"

   shift
   shift
   shift

   local sep="
"
   _emit_file_output "${sep}" "$@"
}


_emit_ld_output()
{
   log_entry "_emit_ld_output" "$@"

   local sep="${1: }"; shift
   local withldpath="$1"; shift
   local withrpath="$1"; shift
   local wholearchiveformat="$1"; shift

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   [ -z "${MULLE_PLATFORM_TRANSLATE_SH}" ] && \
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-translate.sh"


   local result

   if [ "${withldpath}" = 'YES' ]
   then
      r_platform_translate "ldpath" "-L" "${sep}" "${wholearchiveformat}" "$@" || exit 1
      r_concat "${result}" "${RVAL}" "${sep}"
      result="${RVAL}"
   fi

   r_platform_translate "ld" "-l" "${sep}" "${wholearchiveformat}" "$@" || exit 1
   r_concat "${result}" "${RVAL}" "${sep}"
   result="${RVAL}"

   if [ "${withrpath}" = 'YES' ]
   then
      r_platform_translate "rpath" "-Wl,-rpath -Wl," "${sep}" "${wholearchiveformat}" "$@" || exit 1
      r_concat "${result}" "${RVAL}" "${sep}"
      result="${RVAL}"
   fi

   [ ! -z "${result}" ] && rexekutor echo "${result}"
}


emit_ld_output()
{
   log_entry "_emit_ld_output" "$@"

   local sep=" "
   _emit_ld_output "${sep}" "$@"
}


emit_ld_lf_output()
{
   log_entry "_emit_ld_output" "$@"

   local sep="
"
   _emit_ld_output "${sep}" "$@"
}



emit_csv_output()
{
   log_entry "emit_csv_output" "$@"

   shift
   shift
   shift
   shift

   printf "%s" "$@"
}



sde_linkorder_all_nodes()
{
   log_entry "sde_linkorder_all_nodes" "$@"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS} \
               walk \
                  --lenient \
                  --buildorder-qualifier 'MATCHES link' \
                  --permissions 'descend-symlink,descend-mark' \
                  'echo "${MULLE_ADDRESS};${MULLE_MARKS};${MULLE_RAW_USERINFO}"'
}


#
# local _dependency_libs
# local _optional_dependency_libs
# local _os_specific_libs
#
linkorder_collect()
{
   log_entry "sde_linkorder_main" "$@"

   local address="$1"
   local marks="$2"
   local aliases="$3"
   local collect_libraries="$4"

   local name

   r_fast_basename "${address}"
   name="${RVAL}"

   local librarytype
   local requirement

   librarytype="library"

   # find dependency lib and
   case ",${marks}," in
      *,only-standalone,*)
         [ -z "${standalone_load}" ] || \
            fail "Nodes \"${name}\" and \"${standalone_load}\" both marked as only-standalone"
         standalone_load="${name}"

         librarytype="standalone"
         log_debug "${name} is a standalone library"
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
            return 1
         fi

         r_concat "${name}" "${marks}" ";"
         return
      ;;
   esac

   local libpath

   r_sde_locate_library "${librarytype}" "${requirement}" "${name}" ${aliases}
   libpath="${RVAL}"
   [ -z "${libpath}" ] && fail "Did not find \"${name}\" library.
${C_INFO}The linkorder is available after dependencies have been built.
${C_RESET_BOLD}   mulle-sde craft"

   log_fluff "Found library \"${name}\" at \"${libpath}\""

   r_concat "${libpath}" "${marks}" ";"
}


sde_linkorder_main()
{
   log_entry "sde_linkorder_main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_OUTPUT_FORMAT="file_lf"
   local OPTION_LD_PATH='YES'
   local OPTION_RPATH='YES'
   local OPTION_FORCE_LOAD='NO'
   local OPTION_WHOLE_ARCHIVE_FORMAT='whole-archive'

   local collect_libraries='NO'

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
               node|csv|file|file_lf)
                  collect_libraries='NO'
               ;;

               ld|ld_lf)
                  collect_libraries='YES'
               ;;

               *)
                  sde_linkorder_usage "Unknown format value \"${OPTION_TYPE}\""
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

   #
   # load mulle-platform as library, since we would be calling the executable
   # repeatedly
   #
   if [ -z "${MULLE_PLATFORM_LIBEXEC_DIR}" ]
   then
      MULLE_PLATFORM_LIBEXEC_DIR="`exekutor "${MULLE_PLATFORM:-mulle-platform}" libexec-dir`" || exit 1
   fi

   local nodes
   local name
   local all_loads
   local normal_loads
   local collect

   nodes="`sde_linkorder_all_nodes`" || exit 1

   if [ "${OPTION_OUTPUT_FORMAT}" = "node" ]
   then
      log_info "Nodes"
      echo "${nodes}"
      return 0
   fi

   log_debug "nodes: ${nodes}"

   local dependency_libs

   IFS="
" ; set -f
   for node in ${nodes}
   do
      IFS="${DEFAULT_IFS}"; set +f

      local address
      local marks
      local raw_userinfo

      IFS=";" read address marks raw_userinfo <<< "${node}"

      local aliases
      local userinfo

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

         aliases="`assoc_array_get "${userinfo}" "aliases"`"
      fi

      # TODO: could remove duplicates with awk
      if linkorder_collect "${address}" "${marks}" "${aliases}"
      then
         r_add_unique_line "${dependency_libs}" "${RVAL}"
         dependency_libs="${RVAL}"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +f

   emit_${OPTION_OUTPUT_FORMAT}_output "${OPTION_LD_PATH}" \
                                       "${OPTION_RPATH}" \
                                       "${OPTION_WHOLE_ARCHIVE_FORMAT}" \
                                       ${dependency_libs}
}
