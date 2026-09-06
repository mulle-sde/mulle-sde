# shellcheck shell=bash
#
#   Copyright (c) 2026 Nat! - Mulle kybernetiK
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
MULLE_SDE_VERIFY_SH='included'


sde::verify::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} verify [options]

   Compare the main project's source files and headers with its built product.
   This checks the project itself and does not require a test environment.

Options:
   --platform <name>       : check the product for this platform
   --sdk <name>            : check the product for this SDK
   --configuration <name>  : check the product for this configuration (Debug)

EOF
   exit 1
}


sde::verify::file_line()
{
   local prefix="$1"
   local filepath="$2"
   local mtime
   local size
   local absolute

   r_absolutepath "${filepath}"
   absolute="${RVAL}"
   mtime="$(modification_timestamp "${filepath}" 2>/dev/null)"
   size="$(file_size_in_bytes "${filepath}" 2>/dev/null)"
   printf "      %s: %s mtime=%s size=%s bytes\n" \
          "${prefix}" "${absolute}" "${mtime:-unknown}" "${size:-unknown}"
}


sde::verify::r_project_files()
{
   log_entry "sde::verify::r_project_files" "$@"

   local projectdir="$1"
   local files
   local matches
   local category
   local file
   local absolute
   local sourcedir

   for category in source header
   do
      matches="$(cd "${projectdir}" && \
         rexekutor "${MULLE_MATCH:-mulle-match}" \
                      list \
                         --type-matches "${category}" \
                         --format "%f\\n" 2>/dev/null)"

      while IFS= read -r file
      do
         [ -z "${file}" ] && continue
         case "${file}" in
            /*) absolute="${file}" ;;
            *)
               r_filepath_concat "${projectdir}" "${file}"
               absolute="${RVAL}"
            ;;
         esac

         case "${absolute}" in
            */.git/*|*/.mulle/*|*/build/*|*/kitchen/*)
               continue
            ;;
         esac
         r_add_unique_line "${files}" "${absolute}"
         files="${RVAL}"
      done <<< "${matches}"
   done

   # Keep verify useful when mulle-match is unavailable or has no configured
   # source patterns. This fallback deliberately stays in the project source
   # directory and excludes generated/build trees.
   if [ -z "${files}" ]
   then
      sourcedir="${PROJECT_SOURCE_DIR:-.}"
      r_filepath_concat "${projectdir}" "${sourcedir}"
      sourcedir="${RVAL}"
      if [ -d "${sourcedir}" ]
      then
         matches="$(rexekutor find "${sourcedir}" -type f \
            \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cxx' \
               -o -name '*.h' -o -name '*.hh' -o -name '*.hpp' -o -name '*.hxx' \
               -o -name '*.m' -o -name '*.mm' -o -name '*.inc' \
               -o -name '*.swift' -o -name '*.s' -o -name '*.S' \) \
            -not -path '*/.git/*' -not -path '*/.mulle/*' \
            -not -path '*/build/*' -not -path '*/kitchen/*' \
            -print 2>/dev/null)"
         while IFS= read -r file
         do
            [ -z "${file}" ] && continue
            r_add_unique_line "${files}" "${file}"
            files="${RVAL}"
         done <<< "${matches}"
      fi
   fi

   RVAL="${files}"
}


sde::verify::r_product_files()
{
   log_entry "sde::verify::r_product_files" "$@"

   local projectdir="$1"
   local projecttype="$2"
   local projectname="$3"
   local platform="$4"
   local searchpath
   local search_directory
   local file
   local files
   local prefix
   local static_suffix
   local dynamic_suffix
   local executable_suffix
   local pattern
   local craft="${MULLE_CRAFT:-mulle-craft}"
   local platform_tool="${MULLE_PLATFORM_TOOL:-mulle-platform}"

   RVAL=

   case "${projecttype}" in
      library)
         searchpath="$(rexekutor "${craft}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                           searchpath \
                              --add-kitchen-path \
                              --platforms "${platform}" \
                              --sdks "${OPTION_SDK:-${MULLE_CRAFT_SDKS}}" \
                              --configurations "${OPTION_CONFIGURATION:-Release:Debug}" \
                              library 2>/dev/null)"
         eval_rexekutor "$("${platform_tool}" environment 2>/dev/null)"
         prefix="${MULLE_PLATFORM_LIBRARY_PREFIX:-lib}"
         static_suffix="${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC:-.a}"
         dynamic_suffix="${MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC:-.so}"

         .foreachpath search_directory in ${searchpath}
         .do
            [ -d "${search_directory}" ] || continue
            for pattern in \
               "${prefix}${projectname}${static_suffix}" \
               "${prefix}${projectname}${dynamic_suffix}*" \
               "${prefix}${projectname}.dylib*" \
               "${projectname}${static_suffix}" \
               "${projectname}${dynamic_suffix}*"
            do
               while IFS= read -r file
               do
                  [ -z "${file}" ] && continue
                  r_resolve_all_path_symlinks "${file}"
                  r_add_unique_line "${files}" "${RVAL}"
                  files="${RVAL}"
               done <<< "$(rexekutor find "${search_directory}" -maxdepth 1 \( -type f -o -type l \) -name "${pattern}" -print 2>/dev/null)"
            done
         .done
      ;;

      executable)
         searchpath="$(rexekutor "${craft}" \
                              ${MULLE_TECHNICAL_FLAGS} \
                           searchpath \
                              --add-kitchen-path \
                              --platforms "${platform}" \
                              --sdks "${OPTION_SDK:-${MULLE_CRAFT_SDKS}}" \
                              --configurations "${OPTION_CONFIGURATION:-Release:Debug}" \
                              binary 2>/dev/null)"
         eval_rexekutor "$("${platform_tool}" environment 2>/dev/null)"
         executable_suffix="${MULLE_PLATFORM_EXECUTABLE_SUFFIX:-${MULLE_EXE_EXTENSION}}"

         .foreachpath search_directory in ${searchpath}
         .do
            [ -d "${search_directory}" ] || continue
            for pattern in "${projectname}${executable_suffix}" "${projectname}" "${projectname}.exe"
            do
               while IFS= read -r file
               do
                  [ -z "${file}" ] && continue
                  r_resolve_all_path_symlinks "${file}"
                  r_add_unique_line "${files}" "${RVAL}"
                  files="${RVAL}"
               done <<< "$(rexekutor find "${search_directory}" -maxdepth 1 \( -type f -o -type l \) -name "${pattern}" -print 2>/dev/null)"
            done
         .done
      ;;
   esac

   RVAL="${files}"
}


sde::verify::verify_platform()
{
   log_entry "sde::verify::verify_platform" "$@"

   local projectdir="$1"
   local platform="$2"
   local sdk="$3"
   local configuration="$4"
   local source_files="$5"
   local source_count="$6"
   local projectname="${PROJECT_NAME}"
   local projecttype="${PROJECT_TYPE}"
   local product_files
   local product_file
   local product_count=0
   local product_mtime
   local newest_mtime
   local newest_source
   local newer_count
   local comparison
   local source_file
   local source_mtime

   OPTION_SDK="${sdk}"
   OPTION_CONFIGURATION="${configuration}"
   sde::verify::r_product_files "${projectdir}" "${projecttype}" "${projectname}" "${platform}"
   product_files="${RVAL}"
   while IFS= read -r product_file
   do
      [ -z "${product_file}" ] && continue
      product_count=$((product_count + 1))
   done <<< "${product_files}"

   printf "\n  PLATFORM: %s  SDK: %s  CONFIGURATION: %s\n" \
          "${platform}" "${sdk}" "${configuration}"

   if [ "${product_count}" -eq 0 ]
   then
      if [ "${projecttype}" = 'none' ]
      then
         _missing_count=$((_missing_count + 1))
         printf "    conclusion: MISSING (expected: project type none has no product)\n"
      else
         _missing_count=$((_missing_count + 1))
         _incomplete_count=$((_incomplete_count + 1))
         printf "    conclusion: MISSING (no built product found)\n"
      fi
      _product_count=$((_product_count + product_count))
      return
   fi

   while IFS= read -r product_file
   do
      [ -z "${product_file}" ] && continue
      _matched_count=$((_matched_count + 1))
      product_mtime="$(modification_timestamp "${product_file}" 2>/dev/null)"

      printf "\n    PRODUCT: %s\n" "${projectname}"
      printf "        product: %s mtime=%s size=%s bytes\n" \
             "${product_file}" "${product_mtime:-unknown}" \
             "$(file_size_in_bytes "${product_file}" 2>/dev/null || printf unknown)"

      newest_mtime=''
      newest_source=''
      newer_count=0
      while IFS= read -r source_file
      do
         [ -z "${source_file}" ] && continue
         source_mtime="$(modification_timestamp "${source_file}" 2>/dev/null)"
         if [ -z "${newest_mtime}" ] || [ "${source_mtime:-0}" -gt "${newest_mtime}" ]
         then
            newest_mtime="${source_mtime}"
            newest_source="${source_file}"
         fi
         if [ "${source_mtime:-0}" -gt "${product_mtime:-0}" ]
         then
            newer_count=$((newer_count + 1))
            _stale_count=$((_stale_count + 1))
            printf "        NEWER SOURCE: %s mtime=%s\n" "${source_file}" "${source_mtime}"
         fi
      done <<< "${source_files}"

      if [ "${source_count}" -eq 0 ]
      then
         _missing_count=$((_missing_count + 1))
         _incomplete_count=$((_incomplete_count + 1))
         printf "        conclusion: MISSING (no project source files found)\n"
         continue
      fi

      if [ "${newer_count}" -ne 0 ]
      then
         comparison='>'
         printf "        conclusion: STALE (mtime %s %s mtime %s)\n" \
                "${newest_mtime:-unknown}" "${comparison}" \
                "${product_mtime:-unknown}"
      else
         if [ "${newest_mtime:-0}" -eq "${product_mtime:-0}" ]
         then
            comparison='='
         else
            comparison='<'
         fi
         printf "        newest source: %s mtime=%s size=%s bytes\n" \
                "${newest_source}" "${newest_mtime:-unknown}" \
                "$(file_size_in_bytes "${newest_source}" 2>/dev/null || printf unknown)"
         printf "        conclusion: UPTODATE (mtime %s %s mtime %s)\n" \
                "${newest_mtime:-unknown}" "${comparison}" \
                "${product_mtime:-unknown}"
      fi
   done <<< "${product_files}"

   _product_count=$((_product_count + product_count))
}


sde::verify::verify()
{
   log_entry "sde::verify::verify" "$@"

   local projectdir="$1"
   local platforms="$2"
   local sdks="$3"
   local configurations="$4"
   local projectname="${PROJECT_NAME}"
   local source_files
   local source_file
   local source_count=0
   local stale_advice

   # accumulator variables for platforms
   local _product_count=0
   local _matched_count=0
   local _missing_count=0
   local _incomplete_count=0
   local _stale_count=0

   r_absolutepath "${projectdir}"
   projectdir="${RVAL}"

   sde::verify::r_project_files "${projectdir}"
   source_files="${RVAL}"
   while IFS= read -r source_file
   do
      [ -z "${source_file}" ] && continue
      source_count=$((source_count + 1))
   done <<< "${source_files}"

   printf "PROJECT VERIFY: %s\n" "${projectname}"
   printf "  project directory: %s\n" "${projectdir}"
   printf "  source files: %s\n" "${source_count}"

   .foreachpath platform in ${platforms}
   .do
      .foreachpath sdk in ${sdks}
      .do
         .foreachpath configuration in ${configurations}
         .do
            sde::verify::verify_platform "${projectdir}" \
                                         "${platform}" \
                                         "${sdk}" \
                                         "${configuration}" \
                                         "${source_files}" \
                                         "${source_count}"
         .done
      .done
   .done

   printf "\nSUMMARY: products=%s matched=%s missing=%s stale=%s incomplete=%s\n" \
          "${_product_count}" "${_matched_count}" "${_missing_count}" \
          "${_stale_count}" "${_incomplete_count}"

   if [ "${_stale_count}" -ne 0 ]
   then
      stale_advice="Stale project sources detected. Run ${C_RESET_BOLD}mulle-sde craft --all${C_INFO} to rebuild the main project."
      log_vibe "${stale_advice}"
      log_warning "Advice: ${stale_advice}"
      printf "OVERALL: STALE\n"
      return 1
   fi
   if [ "${_incomplete_count}" -ne 0 ]
   then
      printf "OVERALL: MISSING\n"
      return 1
   fi

   printf "OVERALL: UPTODATE\n"
   return 0
}


sde::verify::main()
{
   log_entry "sde::verify::main" "$@"

   local OPTION_PLATFORM=""
   local OPTION_SDK=""
   local OPTION_CONFIGURATION=""

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help|help)
            sde::verify::usage
         ;;

         --platform)
            [ $# -eq 1 ] && sde::verify::usage "Missing argument to \"$1\""
            shift
            OPTION_PLATFORM="$1"
         ;;

         --sdk)
            [ $# -eq 1 ] && sde::verify::usage "Missing argument to \"$1\""
            shift
            OPTION_SDK="$1"
         ;;

         --configuration)
            [ $# -eq 1 ] && sde::verify::usage "Missing argument to \"$1\""
            shift
            OPTION_CONFIGURATION="$1"
         ;;

         --release)
            OPTION_CONFIGURATION='Release'
         ;;

         --debug)
            OPTION_CONFIGURATION='Debug'
         ;;

         -*)
            sde::verify::usage "Unknown option \"$1\""
         ;;

         *)
            sde::verify::usage "Superfluous argument \"$1\""
         ;;
      esac
      shift
   done

   local projectdir
   if ! sde::r_determine_project_dir "${PWD}"
   then
      fail "There is no mulle-sde project in \"${PWD}\""
   fi
   projectdir="${RVAL}"

   local platforms
   local sdks
   local configurations

   if [ ! -z "${OPTION_PLATFORM}" ]
   then
      platforms="${OPTION_PLATFORM}"
   else
      platforms="${MULLE_CRAFT_PLATFORMS:-${MULLE_UNAME}}"
   fi

   if [ ! -z "${OPTION_SDK}" ]
   then
      sdks="${OPTION_SDK}"
   else
      sdks="${MULLE_CRAFT_SDKS:-Default}"
   fi

   if [ ! -z "${OPTION_CONFIGURATION}" ]
   then
      configurations="${OPTION_CONFIGURATION}"
   else
      configurations="${MULLE_CRAFT_CONFIGURATIONS:-Debug}"
   fi

   sde::verify::verify "${projectdir}" \
                      "${platforms}" \
                      "${sdks}" \
                      "${configurations}"
}
