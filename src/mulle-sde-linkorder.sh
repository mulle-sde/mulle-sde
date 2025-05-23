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
MULLE_SDE_LINKORDER_SH='included'


sde::linkorder::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} linkorder [options]

   Emit a string suitable for linking all dependencies and libraries on the
   current platform. The dependencies must have been built, in order for this
   to work. There is a linkorder for executables that includes all startup
   libraries marked as \`no-intermediate-link\` and a second one that excludes
   them for linking shared libraries.

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


sde::linkorder::r_locate_library()
{
   log_entry "sde::linkorder::r_locate_library" "$@"

   local searchpath="$1"
   local libstyle="$2"
   local require="$3"

   shift 3

   platform::search::r_platform_search "${searchpath}" \
                                       "${libstyle}" \
                                       "static" \
                                       "${require}" \
                                       "$@"
}


sde::linkorder::r_locate_framework()
{
   log_entry "sde::linkorder::r_locate_framework" "$@"

   local searchpath="$1"

   shift 1

   platform::search::r_platform_search "${searchpath}" \
                                       "framework" \
                                       "" \
                                       "" \
                                       "$@"
}


sde::linkorder::_emit_file_output()
{
   log_entry "sde::linkorder::_emit_file_output" "$@"

   local sep="${1: }"; shift
   local quote="${1: }"; shift

   local cmdline
   local filename
   local csv

   for csv in "$@"
   do
      filename="${csv%%;*}"

      r_concat "${filename}" "${RVAL}" "${sep}"
      cmdline="${RVAL}"
   done

   [ ! -z "${cmdline}" ] && rexekutor printf "%s\n" "${cmdline}"
}


sde::linkorder::emit_file_output()
{
   log_entry "sde::linkorder::emit_file_output" "$@"

   shift 4

   sde::linkorder::_emit_file_output " " "" "$@"
}


sde::linkorder::emit_file_lf_output()
{
   log_entry "sde::linkorder::emit_file_lf_output" "$@"

   shift 4

   sde::linkorder::_emit_file_output '$\n' "" "$@"
}


sde::linkorder::_emit_ld_output()
{
   log_entry "sde::linkorder::_emit_ld_output" "$@"

   local sep="$1"
   local quote="$2"
   local withldpath="$3"
   local withrpath="$4"
   local preferredlibformat="$5"
   local wholearchiveformat="$6"

   shift 6

   [ -z "${wholearchiveformat}" ] && _internal_fail "wholearchiveformat is empty"
   [ -z "${preferredlibformat}" ] && _internal_fail "preferredlibformat is empty"

   local result

   if [ "${withldpath}" = 'YES' ]
   then
      platform::translate::r_translate_lines "ldpath" \
                                             "${preferredlibformat}" \
                                             "${wholearchiveformat}" \
                                             $'\n' \
                                             "'" \
                                             "$@" || exit 1
      if [ ! -z "${RVAL}" ]
      then
         r_add_line "${result}" "${RVAL}"  # quote protect this
         result="${RVAL}"
      fi
   fi

   platform::translate::r_translate_lines "ld" \
                                          "${preferredlibformat}" \
                                          "${wholearchiveformat}" \
                                          $'\n' \
                                          "" \
                                          "$@" || exit 1

   if [ "${OPTION_SIMPLIFY}" = 'YES' ]
   then
      platform::translate::r_simplify_wholearchive "${RVAL}" "${wholearchiveformat}"
   fi

   r_add_line "${result}" "${RVAL}"  # dont protect
   result="${RVAL}"

   if [ "${withrpath}" = 'YES' ]
   then
      platform::translate::r_translate_lines "rpath" \
                                             "${preferredlibformat}" \
                                             "${wholearchiveformat}" \
                                             $'\n' \
                                             "'" \
                                             "$@" || exit 1
      if [ ! -z "${RVAL}" ]
      then
         r_add_line "${result}" "${RVAL}" # protect
         result="${RVAL}"
      fi
   fi
   
   #
   # change line separator if needed
   #
   if [ "${sep}" != $'\n' ]
   then
      local line

      RVAL=
      .foreachline line in ${result}
      .do
         r_concat "${RVAL}" "${line}" "${sep}"
      .done

      result="${RVAL}"
   fi

   # omit trailing linefeed for cmake
   printf "%s" "${result}"

   if [ "${OPTION_OUTPUT_FINAL_LF}" = 'YES' ]
   then
      echo
   fi
}


sde::linkorder::emit_ld_output()
{
   log_entry "sde::linkorder::emit_ld_output" "$@"

   sde::linkorder::_emit_ld_output " " "" "$@"
}


sde::linkorder::emit_ld_lf_output()
{
   log_entry "sde::linkorder::emit_ld_lf_output" "$@"

   sde::linkorder::_emit_ld_output $'\n' "" "$@"
}


sde::linkorder::emit_cmake_output()
{
   log_entry "sde::linkorder::emit_cmake_output" "$@"

   sde::linkorder::_emit_ld_output ";" " " "$@"
}


sde::linkorder::emit_csv_output()
{
   log_entry "sde::linkorder::emit_csv_output" "$@"

   shift 4

   printf "%s" "$@"
}


sde::linkorder::emit_node_output()
{
   log_entry "sde::linkorder::emit_node_output" "$@"

   shift 4

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
sde::linkorder::will_recurse()
{
   log_entry "sde::linkorder::will_recurse" "$@"

   if sourcetree::marks::disable "${_marks}" "static-link"
   then
       INSIDE_DYNAMIC="${INSIDE_DYNAMIC}x"
   fi

   if sourcetree::marks::contain "${_marks}" "only-standalone"
   then
       INSIDE_STANDALONE="${INSIDE_STANDALONE}x"
   fi

   return 0
}


sde::linkorder::did_recurse()
{
   log_entry "sde::linkorder::did_recurse" "$@"

   if sourcetree::marks::disable "${_marks}" "static-link"
   then
       INSIDE_DYNAMIC="${INSIDE_DYNAMIC%x}"
   fi

   if sourcetree::marks::enable "${_marks}" "standalone"
   then
      INSIDE_STANDALONE="${INSIDE_STANDALONE%x}"
   fi

   return 0
}


sde::linkorder::callback()
{
   log_entry "sde::linkorder::callback (${INSIDE_STANDALONE} ${INSIDE_DYNAMIC})" "$@"

   #
   # collect libraries not marked as dependencies
   #
   if [ ! -z "${INSIDE_STANDALONE}" -o ! -z "${INSIDE_DYNAMIC}" ] && \
      sourcetree::marks::enable "${_marks}" "dependency"
   then
      # but hit me again later
      sourcetree::walk::remove_from_visited "${WALK_MODE}"
      log_fluff "Skipped dependency \"${_address}\" as it's inside dynamic/standalone"
      return
   fi

   log_verbose "Add ${C_MAGENTA}${C_BOLD}${_address}${C_VERBOSE} to linkorder"

   printf "%s\n" "${_address};${_marks};${_raw_userinfo}"
}


sde::linkorder::r_all_nodes()
{
   log_entry "sde::linkorder::r_all_nodes" "$@"

   local INSIDE_STANDALONE
   local INSIDE_DYNAMIC

   mode="`"${MULLE_SOURCETREE:-mulle-sourcetree}" mode`"  || exit 1

   local qualifier

   # TODO: why is this not ENABLES ? instead of MATCHES
   qualifier='MATCHES link'
   if [ "${OPTION_STARTUP}" = 'NO' ]
   then
      # startup is marked as no-intermediate-link, filter it out
      qualifier='MATCHES link AND MATCHES intermediate-link'
   fi

   local craft_qualifier

   craft_qualifier="`"${MULLE_CRAFT:-mulle-craft}" qualifier print-no-build`" || exit 1

   r_concat "${qualifier}" "${craft_qualifier}" $'\n'"AND "
   craft_qualifier="${RVAL}"

   local descend_qualifier

   descend_qualifier="${craft_qualifier}"


   # local option_scope="$1"
   # local option_sharedir="$2"
   # local option_configdir="$3"
   # local option_confignames="$4"
   # local option_use_fallback="$5"
   # local defer="$6"
   # local mode="$7"
   include "sourcetree::environment"

   sourcetree::environment::setup "" \
                                  "${MULLE_SOURCETREE_STASH_DIRNAME}" \
                                  "${mode}"

   local bequeath_flag

   bequeath_flag=""
   if [ "${OPTION_BEQUEATH}" = 'YES' ]
   then
      bequeath_flag="--bequeath"
   fi

   local configuration

   configuration="${OPTION_CONFIGURATION:-Debug}"

   include "sourcetree::walk"

   RVAL="`rexekutor sourcetree::walk::main \
                               --lenient \
                               --no-eval \
                               --in-order \
                               --backwards \
                               ${bequeath_flag} \
                               --configuration "${configuration}" \
                               --dedupe "linkorder" \
                               --callback-qualifier "${craft_qualifier}" \
                               --descend-qualifier "${descend_qualifier}" \
                               --will-recurse-callback sde::linkorder::will_recurse \
                               --did-recurse-callback sde::linkorder::did_recurse \
                               --no-callback-trace \
                               sde::linkorder::callback `"

   log_fluff "Reversing lines"
   r_reverse_lines "${RVAL}"
#   sde::linkorder::r_remove_leading_duplicate_nodes "${RVAL}"
}


#
# this
#
sde::linkorder::r_search_os_library()
{
   log_entry "sde::linkorder::r_search_os_library" "$@"

   local aliases="$1"

   local alias

   .foreachitem alias in ${aliases}
   .do
      if platform::search::r_platform_search "" library "" "" "${alias}"
      then
         return 0
      fi
   .done

   return 1
}


#
# local _dependency_libs
# local _optional_dependency_libs
# local _os_specific_libs
#
sde::linkorder::r_collect()
{
   log_entry "sde::linkorder::r_collect" "$@"

   local address="$1"
   local marks="$2"
   local aliases="$3"
   local library_searchpath="$4"
   local framework_searchpath="$5"
   local collect_libraries="$6"

   local name

   r_basename "${address}"
   name="${RVAL}"

   local librarytype
   local requirement
   local alias

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
      *,no-actual-link,*)
         log_fluff "Headerless library ${name} with dependencies not linked"
         return 4
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
            return 4
         fi

         #
         #  check that library is present
         #
         .foreachitem alias in ${aliases}
         .do
            alias="${alias#*:}"  # remove type if any
            if sde::linkorder::r_search_os_library "${alias}"
            then
               .break
            fi
         .done

         # otherwise prefer first alias
         if [ -z "${alias}" ]
         then
            alias="${aliases%%,*}"
            alias="${alias#*:}"  # remove type if any
         fi

         log_verbose "Use OS library ${C_MAGENTA}${C_BOLD}${alias}"
         r_concat "${alias}" "${marks}" ";"
         return 0
      ;;
   esac

   local libpath
   local aliasargs
   local aliasfail

   .foreachitem alias in ${aliases}
   .do
      alias="${alias#*:}"  # remove type if any
      r_concat "${aliasfail}" "'${alias}'" " or "
      aliasfail="${RVAL}"
      r_concat "${aliasargs}" "'${alias}'"
      aliasargs="${RVAL}"
   .done

   # TODO: libraries are preferred over frameworks, which is arbitrary

   eval sde::linkorder::r_locate_library "'${library_searchpath}'" \
                                         "'${librarytype}'" \
                                         "'${requirement}'" \
                                         "${aliasargs}"
   libpath="${RVAL}"

   if [ -z "${libpath}" ]
   then
      if [ ! -z "${framework_searchpath}" ]
      then
         eval sde::linkorder::r_locate_framework "'${framework_searchpath}'"  "${aliasargs}"
         libpath="${RVAL}"
      fi

      if [ -z "${libpath}" ]
      then
         #
         # require is per platform or os ? neither
         #
         case ",${marks},*" in
            *,no-require,*|*,no-require-os-${MULLE_UNAME},*)
               log_fluff "\"${libpath}\" is not found, but it is not required"
               return 4
            ;;
         esac

         r_concat "Did not find a linkable" "${aliasfail}"
         r_concat "${RVAL}" "${requirement}"
         r_concat "${RVAL}" "${librarytype}"
         r_concat "${RVAL}" "in searchpath \"${library_searchpath}\""

         if [ ! -z "${framework_searchpath}" ]
         then
            r_concat "${RVAL}" "or \"${framework_searchpath}\""
         fi

         fail "${RVAL}.
${C_INFO}The linkorder will be available after dependencies have been crafted.
${C_RESET_BOLD}   mulle-sde clean all
${C_RESET_BOLD}   mulle-sde craft"
      fi

      # make it distinguishable as framework
      r_comma_concat "${marks}" "only-framework"
      marks="${RVAL}"
   fi

   log_fluff "Found ${what:-library} \"${name}\" at \"${libpath}\""

   r_concat "${libpath}" "${marks}" ";"
}


sde::linkorder::r_library_searchpath()
{
   log_entry "sde::linkorder::r_library_searchpath" "$@"

   local if_exists="$1"

   include "platform::search"

   local options

   if [ "${if_exists}" = 'YES' ]
   then
      options="--if-exists"
   fi

   local searchpath
   local configuration

   configuration="${OPTION_CONFIGURATION:-Debug}"
   searchpath="`rexekutor mulle-craft \
                                 ${MULLE_TECHNICAL_FLAGS} \
                                 -s \
                              searchpath \
                                 ${options} \
                                 --configuration "${configuration}" \
                                 library`"
   if [ -z "${searchpath}" ]
   then
      _log_warning "The library searchpath is empty.
${C_INFO}Have dependencies been built for configuration \"${configuration}\" ?"
   fi

   log_fluff "Library searchpath is: ${searchpath}"
   RVAL="${searchpath}"
}


sde::linkorder::r_framework_searchpath()
{
   log_entry "sde::linkorder::r_framework_searchpath" "$@"

   local if_exists="$1"

   include "platform::search"

   local searchpath
   local configuration

   local options

   if [ "${if_exists}" = 'YES' ]
   then
      options="--if-exists"
   fi

   configuration="${OPTION_CONFIGURATION:-Debug}"
   searchpath="`rexekutor mulle-craft \
                                 ${MULLE_TECHNICAL_FLAGS} \
                                 -s \
                              searchpath \
                                 ${options} \
                                 --configuration "${configuration}" \
                                 framework`"
   if [ -z "${searchpath}" ]
   then
      _log_warning "The framework searchpath is empty.
${C_INFO}Have dependencies been built for configuration \"${configuration}\" ?"
   fi

   log_fluff "Framework searchpath is: ${searchpath}"
   RVAL="${searchpath}"
}


sde::linkorder::r_get_emission_lib()
{
   log_entry "sde::linkorder::r_get_emission_lib" "$@"

   local address="$1"
   local marks="$2"
   local raw_userinfo="$3"
   local library_searchpath="$4"
   local framework_searchpath="$5"
   local collect_libraries="$6"

   local aliases
   local userinfo

   if [ ! -z "${raw_userinfo}" ]
   then
      include "array"
      include "sourcetree::node"

      sourcetree::node::r_decode_raw_userinfo "${raw_userinfo}"
      userinfo="${RVAL}"

      case "${userinfo}" in
         *aliases*)
            r_assoc_array_get "${userinfo}" "aliases"
            aliases="${RVAL}"
         ;;
      esac
   fi

   # TODO: could remove duplicates with awk
   sde::linkorder::r_collect "${address%#*}" \
                             "${marks}" \
                             "${aliases}" \
                             "${library_searchpath}" \
                             "${framework_searchpath}" \
                             "${collect_libraries}"
}


sde::linkorder::r_remove_leading_duplicate_nodes()
{
   local nodes="$1"

   RVAL=

   .foreachline node in ${nodes}
   .do
      r_remove_line "${RVAL}" "${node}"
      r_add_line "${RVAL}" "${node}"
   .done
}


sde::linkorder::r_remove_line_by_first_field()
{
   local lines="$1"
   local search="$2"

   local line
   local delim

   delim=""
   RVAL=

   .foreachline line in ${lines}
   .do
      case "${line}" in
         ${search}|${search}\;*)
            # ignore this
         ;;

         *)
            RVAL="${RVAL}${delim}${line}"
            delim=$'\n'
         ;;
      esac
   .done
}


sde::linkorder::r_collect_emission_libs()
{
   log_entry "sde::linkorder::r_collect_emission_libs" "$@"

   local nodes="$1"
   local library_searchpath="$2"
   local framework_searchpath="$3"
   local collect_libraries="$4"
   local omit="$5"

   local dependency_libs
   local address
   local marks
   local raw_userinfo
   local _startup_load
   local _standalone_load
   local node
   local rval

   .foreachline node in ${nodes}
   .do
      IFS=";" read address marks raw_userinfo <<< "${node}"

      case ",${omit}," in
         *,${address},*)
            .continue
         ;;
      esac

      if [ "${OPTION_OUTPUT_FORMAT}" = "node" ]
      then
         line="${address}"
      else
         sde::linkorder::r_get_emission_lib "${address}" \
                                            "${marks}" \
                                            "${raw_userinfo}" \
                                            "${library_searchpath}" \
                                            "${framework_searchpath}" \
                                            "${collect_libraries}"
         rval=$?
         if [ $rval = 4 ]
         then
            .continue
         fi
         line="${RVAL}"
      fi

      RVAL="${dependency_libs}"
      r_remove_line "${RVAL}" "${line}"
      r_add_line "${RVAL}" "${line}"
      dependency_libs="${RVAL}"
   .done

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
sde::linkorder::main()
{
   log_entry "sde::linkorder::main" "$@"

   local OPTION_CONFIGURATION="${MULLE_CRAFT_CONFIGURATIONS%%,*}"
   local OPTION_OUTPUT_FORMAT="ld_lf"
   local OPTION_LD_PATH='YES'
   local OPTION_REVERSE='DEFAULT'
   local OPTION_RPATH='YES'
   local OPTION_SIMPLIFY='YES'
   local OPTION_FORCE_LOAD='NO'
   local OPTION_BEQUEATH='DEFAULT'
   local OPTION_WHOLE_ARCHIVE_FORMAT="${MULLE_CRAFT_WHOLE_ARCHIVE_FORMAT:-DEFAULT}"
   local OPTION_OUTPUT_OMIT
   local OPTION_STARTUP='YES'           # default executable link
   local OPTION_OUTPUT_FINAL_LF='YES'
   local OPTION_PREFERRED_LIBRARY_STYLE='static'

   local collect_libraries='YES'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::linkorder::usage
         ;;

         -c|--configuration)
           [ $# -eq 1 ] && sde::linkorder::usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="$1"
         ;;

         --preferred-library-style)
           [ $# -eq 1 ] && sde::linkorder::usage "Missing argument to \"$1\""
            shift

            OPTION_PREFERRED_LIBRARY_STYLE="$1"
         ;;

         --dynamic)
            OPTION_PREFERRED_LIBRARY_STYLE='dynamic'
         ;;

         --static)
            OPTION_PREFERRED_LIBRARY_STYLE='static'
         ;;

         --standalone)
            OPTION_PREFERRED_LIBRARY_STYLE='standalone'
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
            [ $# -eq 1 ] && sde::linkorder::usage "Missing argument to \"$1\""
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
            [ $# -eq 1 ] && sde::linkorder::usage "Missing argument to \"$1\""
            shift

            OPTION_WHOLE_ARCHIVE_FORMAT="$1"
            [ -z "${OPTION_WHOLE_ARCHIVE_FORMAT}" ] \
            && _internal_fail " --whole-archive-format argument can't be empty"
         ;;

         --output-format)
            [ $# -eq 1 ] && sde::linkorder::usage "Missing argument to \"$1\""
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
                  sde::linkorder::usage "Unknown format value \"${OPTION_OUTPUT_FORMAT}\""
               ;;
            esac
         ;;

         --stash-dir)
            [ $# -eq 1 ] && sde::linkorder::usage "Missing argument to \"$1\""
            shift

            MULLE_SOURCETREE_STASH_DIR="$1"
         ;;

         -*)
            sde::linkorder::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   case "${PROJECT_EXTENSIONS}" in
      args)
         fail "A linkorder is only available for library projects"
      ;;
   esac

   local nodes
   local name
   local all_loads
   local normal_loads
   local collect

   sde::linkorder::r_all_nodes
   nodes="${RVAL}"

   if [ "${OPTION_OUTPUT_FORMAT}" = "debug" ]
   then
      printf "%s\n" "${RVAL}"
      return 0
   fi

   log_debug "nodes: ${nodes}"
   if [ -z "${nodes}" ]
   then
      return 0
   fi


   include "path"
   #
   # load mulle-platform as library, since we dont want to call the executable
   # repeatedly
   #
   include "platform::translate"
   include "platform::search"

   local library_searchpath
   local framework_searchpath

   if [ "${OPTION_OUTPUT_FORMAT}" != "node" ]
   then
      sde::linkorder::r_library_searchpath 'YES'
      library_searchpath="${RVAL}"

      case "${MULLE_UNAME}" in
         darwin)
            sde::linkorder::r_framework_searchpath # optional s
            framework_searchpath="${RVAL}"
         ;;
      esac
   fi

   sde::linkorder::r_collect_emission_libs "${nodes}" \
                                           "${library_searchpath}" \
                                           "${framework_searchpath}" \
                                           "${collect_libraries}" \
                                           "${OPTION_OUTPUT_OMIT}"
   dependency_libs="${RVAL}"

   sde::linkorder::emit_${OPTION_OUTPUT_FORMAT}_output "${OPTION_LD_PATH}" \
                                                       "${OPTION_RPATH}" \
                                                       "${OPTION_PREFERRED_LIBRARY_STYLE}" \
                                                       "${OPTION_WHOLE_ARCHIVE_FORMAT}" \
                                                       ${dependency_libs}
}
