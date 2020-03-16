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
   current platform. The dependencies must have been built, in order for this
   to work. There is a linkorder for executables that includes all
   startup libraries marked as \`no-intermediate-link\` and a second one that
   excludes them for linking shared libraries.

   The linkorder command may produce incorrect link names, if the aliases
   feature is used by a dependency entry.

   \`${MULLE_USAGE_NAME} linkorder --output-format ld\` emits arguments for
   gcc or clang.

Options:
   --output-format <format>  : specify node,file,file_lf or ld, ld_lf
   --output-omit <library>   : do not emit link commands for library
   --startup                 : include startup libraries (default)
   --no-startup              : exclude startup libraries
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

      r_concat "${result}" "${RVAL}" "${sep}"
      cmdline="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; set +f

   [ ! -z "${cmdline}" ] && rexekutor printf "%s\n" "${cmdline}"
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

   [ -z "${wholearchiveformat}" ] && internal_fail "wholearchiveformat is empty"

   local result

   if [ "${withldpath}" = 'YES' ]
   then
      r_platform_translate_lines "ldpath" "-L"  $'\n' "${wholearchiveformat}" "$@" || exit 1
      r_add_line "${result}" "${RVAL}"
      result="${RVAL}"
   fi

   r_platform_translate_lines "ld" "-l" $'\n' "${wholearchiveformat}" "$@" || exit 1
   r_add_line "${result}" "${RVAL}"
   result="${RVAL}"

   if [ "${withrpath}" = 'YES' ]
   then
      r_platform_translate_lines "rpath" "-Wl,-rpath -Wl,"  $'\n' "${wholearchiveformat}" "$@" || exit 1
      r_add_line "${result}" "${RVAL}"
      result="${RVAL}"
   fi

   if [ "${OPTION_SIMPLIFY}" = 'YES' ]
   then
      r_platform_simplify_wholearchive "${result}" "${wholearchiveformat}"
      result="${RVAL}"
   fi

   if [ "${sep}" != $'\n' ]
   then
      local line

      RVAL=
      IFS=$'\n'; set -f
      for line in ${result}
      do
         IFS="${DEFAULT_IFS}"; set +f
         r_concat "${RVAL}" "${line}" "${sep}"
      done
      IFS="${DEFAULT_IFS}"; set +f

      result="${RVAL}"
   fi

   # omit trailing linefeed for cmake
   printf "%s" "${result}"

   if [ "${OPTION_OUTPUT_FINAL_LF}" = 'YES' ]
   then
      echo
   fi
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

   _emit_ld_output ";" " " "$@"
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
      printf "%s\n" "${line}"
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

   printf "%s\n" "${_address};${_marks};${_raw_userinfo}"
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

   local qualifier

   qualifier='MATCHES link'
   if [ "${OPTION_STARTUP}" = 'NO' ]
   then
      qualifier='MATCHES link AND MATCHES intermediate-link'
   fi

   r_make_craftorder_qualifier "${qualifier}"
   qualifier="${RVAL}"

   sourcetree_environment "" "${MULLE_SOURCETREE_STASH_DIRNAME}" "${mode}"


   RVAL="`sourcetree_walk_main --lenient \
                               --no-eval \
                               --in-order \
                               --backwards \
                               --bequeath \
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
# this
#
r_search_os_library()
{
   log_entry "r_search_os_library" "$@"

   local aliases="$1"

   local cmd

   IFS=","; set -f
   for alias in ${aliases}
   do
      IFS="${DEFAULT_IFS}"; set +f
      if r_platform_search "" library "" "" "${alias}"
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}"; set +f

   return 1
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

   r_basename "${address}"
   name="${RVAL}"

   local librarytype
   local requirement
   local alias
   local aliases

   aliases="${aliases:-${name}}"
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
   esac

   case ",${marks}," in
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
            return 4
         fi

         #
         #  check that library is present
         #
         IFS=","; set -f
         for alias in ${aliases}
         do
            alias="${alias#*:}"  # remove type if any
            if r_search_os_library "${alias}"
            then
               break
            fi
         done
         set +f; IFS="${DEFAULT_IFS}"

         # otherwise prefer first alias
         if [ -z "${alias}" ]
         then
            alias="${aliases%%,*}"
            alias="${alias#*:}"  # remove type if any
         fi

         log_fluff "Use OS library \"${alias}\""
         r_concat "${alias}" "${marks}" ";"
         return 0
      ;;
   esac

   local libpath
   local aliasargs
   local aliasfail

   IFS=","; set -f
   for alias in ${aliases}
   do
      alias="${alias#*:}"  # remove type if any
      r_concat "${aliasfail}" "'${alias}'" " or "
      aliasfail="${RVAL}"
      r_concat "${aliasargs}" "'${alias}'"
      aliasargs="${RVAL}"
   done
   set +f; IFS="${DEFAULT_IFS}"

   eval r_sde_locate_library "'${searchpath}'" "'${librarytype}'" "'${requirement}'" "${aliasargs}"
   libpath="${RVAL}"

   if [ -z "${libpath}" ]
   then
      case ",${marks},*" in
         *,no-require,*)
            log_fluff "\"${libpath}\" is not found, but it is not required"
            return 4
         ;;
      esac

      fail "Did not find a linkable ${aliasfail} ${requirement} ${librarytype} in \"${searchpath}\".
${C_INFO}The linkorder will only be available after dependencies have been crafted.
${C_RESET_BOLD}   mulle-sde clean all
${C_RESET_BOLD}   mulle-sde craft"
   fi

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
   searchpath="`rexekutor mulle-craft \
                                 ${MULLE_TECHNICAL_FLAGS} \
                                 -s \
                              searchpath \
                                 --if-exists \
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



r_remove_line_by_first_field()
{
   local lines="$1"
   local search="$2"

   local line
   local delim

   RVAL=
   set -o noglob ; IFS=$'\n'
   for line in ${lines}
   do
      case "${line}" in
         ${search}|${search}\;*)
            # ignore this
         ;;

         *)
            RVAL="${RVAL}${delim}${line}"
            delim=$'\n'
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob
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
#
sde_linkorder_main()
{
   log_entry "sde_linkorder_main" "$@"

   local OPTION_CONFIGURATION="${CONFIGURATIONS%%:*}"
   local OPTION_OUTPUT_FORMAT="ld_lf"
   local OPTION_LD_PATH='YES'
   local OPTION_REVERSE='DEFAULT'
   local OPTION_RPATH='YES'
   local OPTION_SIMPLIFY='YES'
   local OPTION_FORCE_LOAD='NO'
   local OPTION_BEQUEATH='YES'
   local OPTION_WHOLE_ARCHIVE_FORMAT
   local OPTION_OUTPUT_OMIT
   local OPTION_STARTUP='YES'           # default executable link
   local OPTION_OUTPUT_FINAL_LF='YES'

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

   [ -z "${MULLE_PLATFORM_SEARCH_SH}" ] && \
      . "${MULLE_PLATFORM_LIBEXEC_DIR}/mulle-platform-search.sh"


   r_platform_default_whole_archive_format
   OPTION_WHOLE_ARCHIVE_FORMAT="${RVAL}"
   [ -z "${OPTION_WHOLE_ARCHIVE_FORMAT}" ] && internal_fail "No wholearchiveformat available on this platform ?"

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

         --output-no-final-lf)
            OPTION_OUTPUT_FINAL_LF='NO'
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

         --bequeath)
            OPTION_BEQUEATH='YES'
         ;;

         --no-bequeath)
            OPTION_BEQUEATH='NO'
         ;;

         --reverse)
            OPTION_REVERSE='YES'
         ;;

         --no-reverse)
            OPTION_REVERSE='NO'
         ;;

         --startup)
            OPTION_STARTUP='YES'
         ;;

         --no-startup)
            OPTION_STARTUP='NO'
         ;;

         --simplify)
            OPTION_SIMPLIFY='YES'
         ;;

         --no-simplify)
            OPTION_SIMPLIFY='NO'
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

               debug|node|csv|ld_lf)
               ;;

               cmake|ld)
                  OPTION_OUTPUT_FINAL_LF='NO'
               ;;

               *)
                  sde_linkorder_usage "Unknown format value \"${OPTION_OUTPUT_FORMAT}\""
               ;;
            esac
         ;;

         --stash-dir)
            [ $# -eq 1 ] && sde_linkorder_usage "Missing argument to \"$1\""
            shift

            MULLE_SOURCETREE_STASH_DIR="$1"
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
      printf "%s\n" "${RVAL}"
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
