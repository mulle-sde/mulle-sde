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
       INSIDE_DYNAMIC="${INSIDE_DYNAMIC%?}"
   fi

   if nodemarks_contain "${_marks}" "only-standalone"
   then
      INSIDE_STANDALONE="${INSIDE_STANDALONE%?}"
   fi
}


# only callback as environment available
#
linkorder_callback()
{
   log_entry "linkorder_callback" "$@"

   if [ ! -z "${INSIDE_STANDALONE}" -o ! -z "${INSIDE_DYNAMIC}"  ] && \
      nodemarks_contain "${_marks}" "dependency"
   then
      # but hit me again later
      walk_remove_from_visited "${_nodeline}"
      log_debug "${_address}: skipped emit of dependency due to dynamic/standalone"
      return
   fi

   r_add_line "${linkorder_collection}" "${_address};${_marks};${_raw_userinfo}"
   linkorder_collection="${RVAL}"
}


r_sde_linkorder_all_nodes()
{
   log_entry "r_sde_linkorder_all_nodes" "$@"

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      MULLE_SOURCETREE_LIBEXEC_DIR="`"${MULLE_SOURCETREE:-mulle-sourcetree}" libexec-dir`"

      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-environment.sh"  || exit 1
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
      [ -z "${MULLE_SOURCETREE_BUILDORDER_SH}" ] && \
         . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-buildorder.sh"
   fi

   local linkorder_collection
   local INSIDE_STANDALONE
   local INSIDE_DYNAMIC

   mode="`"${MULLE_SOURCETREE:-mulle-sourcetree}" mode`"

   local rval

   r_make_buildorder_qualifier 'MATCHES link'
   qualifier="${RVAL}"

   sourcetree_environment "" "${MULLE_SOURCETREE_STASH_DIRNAME}" "${mode}"
   sourcetree_walk_main --lenient \
                        --no-eval \
                        --pre-order \
                        --permissions 'descend-symlink' \
                        --visit-qualifier "${qualifier}" \
                        --prune \
                        --will-recurse-callback linkorder_will_recurse \
                        --did-recurse-callback linkorder_did_recurse \
                        --no-callback-trace \
                        linkorder_callback

   RVAL="${linkorder_collection}"
}


#
# local _dependency_libs
# local _optional_dependency_libs
# local _os_specific_libs
#
linkorder_collect()
{
   log_entry "linkorder_collect" "$@"

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
            return 2
         fi

         r_concat "${name}" "${marks}" ";"
         return 0
      ;;
   esac

   local libpath

   if [ -z "${aliases}" ]
   then
      aliases="${name}"
   fi

   r_sde_locate_library "${librarytype}" "${requirement}" ${aliases}
   libpath="${RVAL}"

   [ -z "${libpath}" ] && fail "Did not find a linkable \"${name}\" library.
${C_INFO}The linkorder is available after dependencies have been built.
${C_RESET_BOLD}   mulle-sde clean all
${C_RESET_BOLD}   mulle-sde craft"

   log_fluff "Found library \"${name}\" at \"${libpath}\""

   r_concat "${libpath}" "${marks}" ";"
}


sde_linkorder_main()
{
   log_entry "sde_linkorder_main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_OUTPUT_FORMAT="ld_lf"
   local OPTION_LD_PATH='YES'
   local OPTION_RPATH='YES'
   local OPTION_FORCE_LOAD='NO'
   local OPTION_WHOLE_ARCHIVE_FORMAT='whole-archive-as-needed'

   local collect_libraries='YES'

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

         --no-libraries)
            collect_libraries='NO'
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

               node|csv|ld|ld_lf)
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

   r_sde_linkorder_all_nodes
   nodes="${RVAL}"

   if [ "${OPTION_OUTPUT_FORMAT}" = "node" ]
   then
      log_info "Nodes"
      echo "${nodes}"
      return 0
   fi

   log_debug "nodes: ${nodes}"

   local dependency_libs
   local aliases
   local userinfo
   local address
   local marks
   local raw_userinfo

   IFS="
" ; set -f
   for node in ${nodes}
   do
      IFS="${DEFAULT_IFS}"; set +f


      IFS=";" read address marks raw_userinfo <<< "${node}"

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

         aliases="`assoc_array_get "${userinfo}" "aliases"`"
      fi

      # TODO: could remove duplicates with awk
      if linkorder_collect "${address%#*}" "${marks}" "${aliases}" "${collect_libraries}"
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
