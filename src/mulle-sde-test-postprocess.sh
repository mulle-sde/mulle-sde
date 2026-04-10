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
MULLE_SDE_TEST_POSTPROCESS_SH='included'

# library code for mulle-sde-test

sde::test::emit_include_h()
{
   log_entry "sde::test::emit_include_h" "$@"

   local dialect="${1:-}"
   local meta_dialect="$2"
   local guard_identifier="$3"

   if [ "${dialect}" != "objc" ]
   then
      printf "#ifndef %s\n" "${guard_identifier}"
      printf "#define %s\n\n" "${guard_identifier}"
   fi

   printf "// THIS FILE WILL BE CLOBBERED BY mulle-sde test craft\n\n"

   if [ "${dialect}" = "objc" ]
   then
      printf "#include \"include.h\"\n\n"
   fi

   emit_line()
   {
      local path="$1"
      local is_objc="$2"

      if [ "${dialect}" = "c" ]   && [ "${is_objc}" = "yes" ];  then return 0; fi
      if [ "${dialect}" = "objc" ] && [ "${is_objc}" = "no" ];   then return 0; fi


      # memo as the include/import headers are in the dependency include now
      # we can use "" instead of <>
      if [ "${dialect}" = "objc" ] && [ "${is_objc}" = "yes" ]; then
         printf "#import \"%s\"\n" "${path}"
      else
         printf "#include \"%s\"\n" "${path}"
      fi
   }

   local hdr
   local rel

   for hdr in $(find "$INC_ROOT" -maxdepth 1 -type f -name '*.h' | sort)
   do
      rel="${hdr#$INC_ROOT/}"
      case "${rel}" in
         'include.h'|'import.h')
            continue
         ;;
      esac

      emit_line "${rel}" "no"
   done

   if [ -n "$(find "$INC_ROOT" -maxdepth 1 -type f -name '*.h')" ]
   then
      printf "\n"
   fi

   local root_hdr
   local dir
   local depname

   for dir in $(find "$INC_ROOT" -maxdepth 1 -mindepth 1 -type d | sort)
   do
      r_basename "${dir}"
      depname="${RVAL}"

      root_hdr="${dir}/${depname}.h"

      if [ "${meta_dialect}" = "objc" ]
      then
         case "${depname}" in
            'mulle-objc-'*)
               if [ "${PROJECT_NAME}" != 'mulle-objc-runtime' -a \
                    "${PROJECT_NAME}" != 'mulle-objc-debug' ]
               then
                  printf "%s\n" "// skipped \"${depname}\" due to 'mulle-objc-*' (hack)"
                  log_debug "Skip \"${depname}\""
                  continue
               fi
            ;;
         esac
      fi

      case "${depname}" in
         *'mintomic')
            log_debug "Skip \"${depname}\""
            printf "%s\n" "// skipped \"${depname}\" due to 'mintomic' (hack)"
            continue
         ;;
      esac

      # for <mulle-time/mulle-time.h> ....
      if [ -f "$root_hdr" ]
      then
         if [ ! -e "${dir}/.no-mulle-test" ]
         then
            if [[ "${depname:0:1}" =~ [A-Z] ]]
            then
               emit_line "${depname}/${depname}.h" "yes"
            else
               emit_line "${depname}/${depname}.h" "no"
            fi
         else
            log_debug "Skip \"${depname}\""
            printf "%s\n" "// skipped \"${depname}/${depname}.h\" due to .no-mulle-test"
         fi
         continue
      fi

      #
      # Lets try not emitting for now
      #
      printf "%s\n" "// no umbrella header \"${depname}/${depname}.h\" found, skipping \"${depname}\""

      #while IFS= read -r hdr
      #do
      #   rel="${hdr#$INC_ROOT/}"
      #
      #   emit_line "${rel}" "no"
      #done < <(find "$dir" -type f -name '*.h' ! -path "*/cmake/*" | sort)
   done

   if [ "${dialect}" != "objc" ]
   then
      printf "\n#endif /* %s */\n" "${guard_identifier}"
   else
      printf "\n"
   fi
}


sde::test::emit_import_h()
{
   log_entry "sde::test::emit_import_h" "$@"

   sde::test::emit_include_h 'objc' 'objc' "$@"
}


sde::test::generate_generic_c_headers()
{
   log_entry "sde::test::generate_generic_c_headers" "$@"

   local dependency_dir="$1"
   shift 

   local text

   if ! text=`sde::test::emit_include_h 'c' "$@"`
   then
      return 1
   fi

   local headerfile

   r_filepath_concat "${dependency_dir}" 'include.h'
   headerfile="${RVAL}"

   redirect_exekutor "${headerfile}" printf "%s\n" "${text}"
}


sde::test::generate_generic_objc_headers()
{
   log_entry "sde::test::generate_generic_objc_headers" "$@"

   local dependency_dir="$1"
   shift 

   local text

   if ! text=`sde::test::emit_import_h "$@"`
   then
      return 1
   fi

   local headerfile

   r_filepath_concat "${dependency_dir}" 'import.h'
   headerfile="${RVAL}"

   redirect_exekutor "${headerfile}" printf "%s\n" "${text}"
}


sde::test::postprocess_headers()
{
   log_entry "sde::test::postprocess_headers" "$@"

   local test_directory="$1"
   local sdk="$2"
   local platform="$3"
   local configuration="$4"

   local PROJECT_NAME="${PROJECT_NAME}"
   local TEST_PROJECT_NAME="${TEST_PROJECT_NAME}"
   local PROJECT_LANGUAGE="${PROJECT_LANGUAGE}"
   local PROJECT_DIALECT="${PROJECT_DIALECT}"

   # for post processing we "just" get the environment of the test folder
   # wholesale
   if [ -z "${PROJECT_NAME}" ]
   then
      PROJECT_NAME="$(rexekutor mulle-env -E get --output-eval PROJECT_NAME)"

      if [ -z "${PROJECT_NAME}" ]
      then
         log_warning "PROJECT_NAME not set, skipping post-processing"
         exit 0
      fi
      TEST_PROJECT_NAME="$(rexekutor mulle-env -E get --output-eval TEST_PROJECT_NAME)"
      PROJECT_LANGUAGE="$(rexekutor mulle-env -E get --output-eval PROJECT_LANGUAGE)"
      PROJECT_DIALECT="$(rexekutor mulle-env -E get --output-eval PROJECT_DIALECT)"
   fi

   log_setting "PROJECT_NAME      : ${PROJECT_NAME}"
   log_setting "TEST_PROJECT_NAME : ${TEST_PROJECT_NAME}"
   log_setting "PROJECT_LANGUAGE  : ${PROJECT_LANGUAGE}"
   log_setting "PROJECT_DIALECT   : ${PROJECT_DIALECT}"

   local guard_name

   guard_name="${PROJECT_NAME}"
   if [ -z "${TEST_PROJECT_NAME}" ]  # check 4 older tests
   then
      guard_name="${PROJECT_NAME}-test"
   fi

   include "case"

   r_smart_file_downcase_identifier "${guard_name}"
   guard_name="${RVAL}"

   local rc

   exekutor mulle-env -E -d "${test_directory}" exec mulle-craft dependency begin
   (
      cd "${test_directory}" || exit 1

      local dependency_dir

      dependency_dir="$(rexekutor mulle-env -E exec \
                                       mulle-craft dependency dir --sdk "${sdk}" \
                                                                  --platform "${platform}" \
                                                                  --configuration "${configuration}")"
      local INC_ROOT

      r_filepath_concat "${dependency_dir}" "include"
      INC_ROOT="${RVAL}"

      mkdir_if_missing "${INC_ROOT}"

      case "${PROJECT_LANGUAGE}" in
         'c')
            sde::test::generate_generic_c_headers "${INC_ROOT}" \
                                                  "${PROJECT_DIALECT:-c}" \
                                                  "${guard_name}_include_h__"

            case "${PROJECT_DIALECT}" in
               'objc')
                  sde::test::generate_generic_objc_headers "${INC_ROOT}"
               ;;
            esac
         ;;
      esac
   )
   rc=$?

   if [ $rc -eq 0 ]
   then
      exekutor mulle-env -E -d "${test_directory}" exec mulle-craft dependency end
   else
      exekutor mulle-env -E -d "${test_directory}" exec mulle-craft dependency fail
   fi
   exit $rc
}

