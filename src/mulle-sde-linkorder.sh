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

Options:
   --output-format <format>  : specify file,file_lf or ld, ld_lf
EOF
   exit 1
}


sde_linkorder_all_nodes()
{
   log_entry "sde_linkorder_all_nodes" "$@"

   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  walk \
                     --lenient \
                     --qualifier 'MATCHES link' \
                     'echo "${MULLE_ADDRESS};${MULLE_MARKS}"'
}


r_sde_locate_library()
{
   log_entry "r_sde_locate_library" "$@"

   local standalone="$1"; shift

   local prefer
   local type

   prefer="static"
   type="library"

   if [ "${standalone}" = "YES" ]
   then
      type="standalone"
      prefer="dynamic"
   fi

   [ -z "${MULLE_PLATFORM_SEARCH_SH}" ] &&
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-search.sh"

   r_platform_search "${DEPENDENCY_DIR}:${ADDICTION_DIR}" \
                     "lib" \
                     "${type}" \
                     "${prefer}" \
                     "$@"
}


_emit_file_output()
{
   log_entry "_emit_file_output" "$@"

   local sep="${1: }"; shift

   local cmdline
   local filename
   local RVAL

   IFS="
" ; set -f
   for filename in "$@"
   do
      IFS="${DEFAULT_IFS}"; set +f

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

   local sep=" "
   _emit_file_output "${sep}" "$@"
}


emit_file_lf_output()
{
   log_entry "emit_file_lf_output" "$@"

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

   [ -z "${MULLE_PATH_SH}" ] && \
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   [ -z "${MULLE_PLATFORM_TRANSLATE_SH}" ] && \
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-translate.sh"

   local RVAL
   local result

   if [ "${withldpath}" = 'YES' ]
   then
      r_platform_translate "ldpath" "-L" "${sep}" "$@" || exit 1
      r_concat "${result}" "${RVAL}" "${sep}"
      result="${RVAL}"
   fi

   r_platform_translate "ld" "-l" "${sep}" "$@" || exit 1
   r_concat "${result}" "${RVAL}" "${sep}"
   result="${RVAL}"

   if [ "${withrpath}" = 'YES' ]
   then
      r_platform_translate "rpath" "-Wl,-rpath -Wl," "${sep}" "$@" || exit 1
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


sde_linkorder_main()
{
   log_entry "sde_linkorder_main" "$@"

   local OPTION_CONFIGURATION
   local OPTION_OUTPUT_FORMAT="file_lf"
   local OPTION_LD_PATH='YES'
   local OPTION_RPATH='YES'

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

         --output-rpath)
            OPTION_RPATH='NO'
         ;;

         --output-ld-path)
            OPTION_LD_PATH='YES'
         ;;

         --output-no-ld-path)
            OPTION_LD_PATH='NO'
         ;;

         --output-format)
           [ $# -eq 1 ] && sde_linkorder_usage "Missing argument to \"$1\""
            shift

            OPTION_OUTPUT_FORMAT="$1"
            case "${OPTION_OUTPUT_FORMAT}" in
               file|file_lf|ld|ld_lf)
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
      MULLE_PLATFORM_LIBEXEC_DIR="`exekutor "${MULLE_PLATFORM:-mulle-platform}" libexec-dir`"
   fi

   local nodes
   local name
   local address
   local all_loads
   local normal_loads
   local collect

   nodes="`sde_linkorder_all_nodes`" || exit 1

   log_debug "nodes: ${nodes}"

   local dependency_libs
   local optional_dependency_libs
   local os_specific_libs

   IFS="
" ; set -f
   for node in ${nodes}
   do
      IFS="${DEFAULT_IFS}"; set +f

      IFS=";" read address marks <<< "${node}"

      r_fast_basename "${address}"
      name="${RVAL}"

      local is_standalone

      is_standalone="NO"
      # find dependency lib and
      case ",${marks}," in
         *,only-standalone,*)
            [ -z "${standalone_load}" ] || \
               fail "Nodes \"${name}\" and \"${standalone_load}\" both marked as only-standalone"
            standalone_load="${name}"

            is_standalone="YES"
            log_debug "${name} is a standalone library"
         ;;

         *,no-all-load,*)
            r_add_line  "${static_loads}" "${name}"
            normal_loads="${RVAL}"
            log_debug "${name} is a C library"
         ;;

         *)
            r_add_line  "${all_loads}" "${name}"
            all_loads="${RVAL}"
            log_debug "${name} is an ObjC library"
         ;;
      esac

      local libpath

      r_sde_locate_library "${is_standalone}" "${name}"
      libpath="${RVAL}"
      [ -z "${libpath}" ] && fail "Did not find \"${name}\" library"

      log_fluff "Found \"${libpath}\" as library \"${name}\""

      r_add_unique_line "${dependency_libs}" "${libpath}"
      dependency_libs="${RVAL}"

      local linklibrary_dir
      local linkinclude_dir

      linklibrary_dir="${DEPENDENCY_DIR}/lib"
      linkinclude_dir="${DEPENDENCY_DIR}/include/${name}/link"

      if [ -d "${linkinclude_dir}" ]
      then
         log_fluff "Reading link information from \"${linkinclude_dir}\""

         dlibs="`exekutor egrep -s -v '^#' "${linkinclude_dir}/dependency-libraries.txt" `"
         olibs="`exekutor egrep -s -v '^#' "${linkinclude_dir}/optional-dependency-libraries.txt" `"
         oslibs="`exekutor egrep -s -v '^#' "${linkinclude_dir}/os-specific-libraries.txt" `"

         if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
         then
            log_trace2 "dependencies : ${dlibs}"
            log_trace2 "optionals    : ${olibs}"
            log_trace2 "os-specifics : ${oslibs}"
         fi

         r_add_unique_lines "${dependency_libs}" "${dlibs}"
         dependency_libs="${RVAL}"
         r_add_unique_lines "${optional_dependency_libs}" "${olibs}"
         optional_dependency_libs="${RVAL}"
         r_add_unique_lines "${os_specific_libs}" "${oslibs}"
         os_specific_libs="${RVAL}"
      else
         log_fluff "No link information in \"${linkinclude_dir}\""
      fi
   done
   IFS="${DEFAULT_IFS}"; set +f

   emit_${OPTION_OUTPUT_FORMAT}_output "${OPTION_LD_PATH}" \
                                       "${OPTION_RPATH}" \
                                       ${dependency_libs} \
                                       ${optional_dependency_libs} \
                                       ${os_specific_libs}
}
