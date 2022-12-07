# shellcheck shell=bash
#
#   Copyright (c) 2022 Nat! - Mulle kybernetiK
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
MULLE_SDE_HEADERORDER_SH="included"


sde::headerorder::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} headerorder [options]

   Emit a string suitable for include dependency and library headers on the
   current platform. The dependencies must have been built, in order for this
   to work.

   \`${MULLE_USAGE_NAME} headerorder --output-format c\` emits #include
   statements for C.

Options:
   --recurse                 : print recursive headers
   --output-format <format>  : specify c or objc
   --output-omit <library>   : do not emit include commands for library
EOF
   exit 1
}



# TODO: use mulle-platform to figure out proper default searchpath
#       and -isystem flags and stuff

sde::headerorder::r_header_searchpath()
{
   log_entry "sde::headerorder::r_header_searchpath" "$@"

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
                                 header`"
   if [ -z "${searchpath}" ]
   then
      _log_warning "The header searchpath is empty.
${C_INFO}Have dependencies been built for configuration \"${configuration}\" ?"
   fi

   log_fluff "Header searchpath is: ${searchpath}"
   RVAL="${searchpath}"
}



sde::headerorder::do_emit_c_output()
{
   log_entry "sde::headerorder::do_emit_c_output" "$@"

   local forcecmd="$1"

   shift 1

   local line
   local incdir
   local incdirs

   for line in "$@"
   do
      IFS=";" read -r address marks include headerpath <<< "${line}"

      if [ -z "${headerpath}" ]
      then
         continue
      fi

      incdir="${headerpath%${include}}"
      incdir="${incdir%%/}"

      r_add_unique_line "${incdirs}" "${incdir}"
      incdirs="${RVAL}"
   done

   .foreachline line in ${incdirs}
   .do
      r_escaped_singlequotes "${line}"
      rexekutor printf "%s %s\n" "-isystem" "'${RVAL}'"
   .done

   local line

   for line in "$@"
   do
      IFS=";" read -r address marks include headerpath <<< "${line}"

      r_lowercase "${address}"
      if [ "${address}" != "${RVAL}" ]
      then
         cmd="#import"
      else
         cmd="#include"
      fi

      case ",${marks}," in
         *,no-all-load,*)
            cmd="#include"
         ;;
      esac

      cmd="${forcecmd:-${cmd}}"

      rexekutor printf "%s <%s>\n" "${cmd}" "${include}"
   done
}


sde::headerorder::emit_c_output()
{
   log_entry "sde::headerorder::emit_c_output" "$@"

   sde::headerorder::do_emit_c_output "#include" "$@"
}


sde::headerorder::emit_objc_output()
{
   log_entry "sde::headerorder::emit_objc_output" "$@"

   sde::headerorder::do_emit_c_output "" "$@"
}


sde::headerorder::emit_csv_output()
{
   log_entry "sde::headerorder::emit_csv_output" "$@"

   local line

   for line in "$@"
   do
      printf "%s\n" "${line}"
   done
}


sde::headerorder::callback()
{
   log_entry "sde::headerorder::callback (${INSIDE_STANDALONE} ${INSIDE_DYNAMIC})" "$@"

   log_verbose "Add ${C_MAGENTA}${C_BOLD}${_address}${C_VERBOSE} to headerorder"

   printf "%s\n" "${_address};${_marks};${_raw_userinfo}"
}


sde::headerorder::r_all_nodes()
{
   log_entry "sde::headerorder::r_all_nodes" "$@"

   local recursive="$1"
   local bequeath="$2"

   include "sourcetree::walk"

   local INSIDE_STANDALONE
   local INSIDE_DYNAMIC

   mode="`"${MULLE_SOURCETREE:-mulle-sourcetree}" mode`"  || exit 1

   local qualifier

   qualifier='MATCHES header'

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

   sourcetree::environment::default "" \
                                    "${MULLE_SOURCETREE_STASH_DIRNAME}" \
                                    "" \
                                    "" \
                                    "" \
                                    "" \
                                    "${mode}"

   local bequeath_flag

   bequeath_flag=""
   if [ "${bequeath}" = 'YES' ]
   then
      bequeath_flag="--bequeath"
   fi

   local recurse_flag

   recurse_flag="--flat"
   if [ "${recursive}" = 'YES' ]
   then
      recurse_flag="--in-order"
   fi

   RVAL="`rexekutor sourcetree::walk::main \
                               --lenient \
                               --no-eval \
                               --backwards \
                               ${recurse_flag} \
                               ${bequeath_flag} \
                               --configuration "Release" \
                               --dedupe "linkorder" \
                               --callback-qualifier "${craft_qualifier}" \
                               --descend-qualifier "${descend_qualifier}" \
                               --no-callback-trace \
                               sde::headerorder::callback `"

   log_fluff "Reversing lines"
   r_reverse_lines "${RVAL}"
}



sde::headerorder::r_locate_header()
{
   log_entry "sde::headerorder::r_locate_header" "$@"

   local searchpath="$1"
   local header="$2"

   local pathitem

   .foreachpath pathitem in ${searchpath}
   .do
      r_filepath_concat "${pathitem}" "${header}"
      if [ -f "${RVAL}" ]
      then
         return 0
      fi
   .done

   RVAL=
   return 1
}


#
# local _dependency_libs
# local _optional_dependency_libs
# local _os_specific_libs
#
sde::headerorder::r_collect()
{
   log_entry "sde::headerorder::r_collect" "$@"

   local address="$1"
   local marks="$2"
   local include="$3"
   local header_searchpath="$4"

   case ",${marks},*" in
      *,no-header,*)
         return 4
      ;;
   esac

   local name

   r_basename "${address}"
   name="${RVAL}"

   include="${include:-"${name}/${name}.h"}"

   local headerpath

   sde::headerorder::r_locate_header "${header_searchpath}" \
                                     "${include}"
   headerpath="${RVAL}"

   if [ -z "${headerpath}" ]
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

      # don't really bother for system headers right now
      case ",${marks},*" in
         *,no-dependency,*)
         ;;

         *)
            r_concat "Did not find an includeable" "${include}"
            r_concat "${RVAL}" "in searchpath \"${header_searchpath}\""

            fail "${RVAL}.
${C_INFO}The headerorder will only be available after dependencies have been crafted.
${C_RESET_BOLD}   mulle-sde clean all
${C_RESET_BOLD}   mulle-sde craft"
         ;;
      esac
   fi

   log_fluff "Found \"${name}\" at \"${headerpath}\""

   RVAL="${address};${marks};${include};${headerpath}"
}


sde::headerorder::r_library_searchpath()
{
   log_entry "sde::headerorder::r_library_searchpath" "$@"

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


sde::headerorder::r_framework_searchpath()
{
   log_entry "sde::headerorder::r_framework_searchpath" "$@"

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


sde::headerorder::r_get_emission_header()
{
   log_entry "sde::headerorder::r_get_emission_header" "$@"

   local address="$1"
   local marks="$2"
   local raw_userinfo="$3"
   local header_searchpath="$4"

   local include
   local userinfo

   include=
   userinfo=

   if [ ! -z "${raw_userinfo}" ]
   then
      include "array"
      include "sourcetree::node"

      sourcetree::node::r_decode_raw_userinfo "${raw_userinfo}"
      userinfo="${RVAL}"

      case "${userinfo}" in
         *include*)
            r_assoc_array_get "${userinfo}" "include"
            include="${RVAL}"
         ;;
      esac
   fi

   sde::headerorder::r_collect "${address%#*}" \
                                "${marks}" \
                                "${include}"  \
                                "${header_searchpath}"
}


sde::headerorder::r_collect_emission_headers()
{
   log_entry "sde::headerorder::r_collect_emission_headers" "$@"

   local nodes="$1"
   local header_searchpath="$2"
   local omit="$3"

   local headers
   local address
   local marks
   local raw_userinfo
   local node
   local rval
   local line 
   local _startup_load
   local _standalone_load

   .foreachline node in ${nodes}
   .do
      IFS=";" read -r address marks raw_userinfo <<< "${node}"

      case ",${omit}," in
         *,${address},*)
            .continue
         ;;
      esac

      sde::headerorder::r_get_emission_header "${address}" \
                                              "${marks}" \
                                              "${raw_userinfo}" \
                                              "${header_searchpath}"
      rval=$?
      if [ $rval = 4 ]
      then
         .continue
      fi

      line="${RVAL}"
      r_remove_line "${headers}" "${line}"
      r_add_line "${RVAL}" "${line}"
      headers="${RVAL}"
   .done

   if [ "${OPTION_REVERSE}" = 'YES' ]
   then
      r_reverse_lines "${headers}"
      headers="${RVAL}"
   fi

   RVAL=${headers}
}


#
# headerorder is really complicated! First the dependencies have a specific
# order, which we must respect. Then we want to move common includes as far
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
sde::headerorder::main()
{
   log_entry "sde::headerorder::main" "$@"

   local OPTION_CONFIGURATION="${MULLE_CRAFT_CONFIGURATIONS%%,*}"
   local OPTION_OUTPUT_FORMAT="objc"
   local OPTION_REVERSE='DEFAULT'
   local OPTION_BEQUEATH='DEFAULT'
   local OPTION_OUTPUT_OMIT
   local OPTION_RECURSIVE='DEFAULT'

   local collect_libraries='YES'

   while :
   do
      case "$1" in
         -h|--help|help)
            sde::headerorder::usage
         ;;

         -c|--configuration)
           [ $# -eq 1 ] && sde::headerorder::usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIGURATION="$1"
         ;;

         --output-omit)
            [ $# -eq 1 ] && sde::headerorder::usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_OUTPUT_OMIT}" "$1"
            OPTION_OUTPUT_OMIT="${RVAL}"
         ;;

         --bequeath)
            OPTION_BEQUEATH='YES'
         ;;

         --no-bequeath)
            OPTION_BEQUEATH='NO'
         ;;

         --recursive)
            OPTION_RECURSIVE='YES'
         ;;

         --no-recursive)
            OPTION_RECURSIVE='NO'
         ;;

         --reverse)
            OPTION_REVERSE='YES'
         ;;

         --no-reverse)
            OPTION_REVERSE='NO'
         ;;

         --output-format)
            [ $# -eq 1 ] && sde::headerorder::usage "Missing argument to \"$1\""
            shift

            OPTION_OUTPUT_FORMAT="$1"
            case "${OPTION_OUTPUT_FORMAT}" in
               c|objc|csv)
               ;;

               *)
                  sde::headerorder::usage "Unknown format value \"${OPTION_OUTPUT_FORMAT}\""
               ;;
            esac
         ;;

         -*)
            sde::headerorder::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   local nodes
   local name
   local all_loads
   local normal_loads
   local collect

   sde::headerorder::r_all_nodes "${OPTION_RECURSIVE}" "${OPTION_BEQUEATH}"
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


   local header_searchpath

   sde::headerorder::r_header_searchpath "YES"
   header_searchpath="${RVAL}"

   local headers

   sde::headerorder::r_collect_emission_headers "${nodes}" \
                                                 "${header_searchpath}" \
                                                 "${OPTION_OUTPUT_OMIT}"
   headers="${RVAL}"

   sde::headerorder::emit_${OPTION_OUTPUT_FORMAT}_output ${headers}
}
