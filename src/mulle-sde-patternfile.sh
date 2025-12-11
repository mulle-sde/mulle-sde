# shellcheck shell=bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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
MULLE_SDE_PATTERNFILE_SH='included'


sde::patternfile::get_pattern_filenames()
{
   # get contents of non-ignore rules
   # remove comments and empty lines
   # get filenames only
   rexekutor mulle-match -s patternfiles cat \
             | grep -E -v '^#|^[[:space:]]*$'  \
             | sed -e 's/.*\/\(.*\)/\1/'     \
             | sort -u
}


sde::patternfile::r_searchnames()
{
   local filenames

   filenames="`sde::patternfile::get_pattern_filenames`"

   local s
   local remainders
   local line

   log_debug "filenames: ${filenames}"

   ## collect extension patterns like *.c and so on
   .foreachline line in ${filenames}
   .do
      case "${line}" in
         *\**\.\[*\])
            r_path_extension "${line}"
            s="${RVAL#\[}"
            s="${s%\]}"
            while [ ! -z "${s}" ]
            do
               r_add_unique_line "${extensions}" "*.${s:0:1}"
               extensions="${RVAL}"
               s="${s:1}"
            done
         ;;

         *\**\.*)
            r_path_extension "${line}"
            r_add_unique_line "${extensions}" "*.${RVAL}"
            extensions="${RVAL}"
         ;;

         *)
            log_debug "Unmatched: \"${line}\""
            r_add_unique_line "${remainders}" "${line}"
            remainders="${RVAL}"
         ;;
      esac
   .done

   log_debug "remainders: ${remainders}"

   local pattern
   local found

   .foreachline line in ${remainders}
   .do

      shell_disable_glob
      found=
      .foreachline pattern in ${extensions}
      .do
         if [[ "${line}" == ${pattern} ]]
         then
            found='YES'
            .break
         fi
      .done
      shell_enable_glob

      if [ "${found}" = 'YES' ]
      then
         .continue
      fi

      r_add_unique_line "${extensions}" "${line}"
      extensions="${RVAL}"
   .done

   RVAL="${extensions}"
}


sde::patternfile::r_environment_filter()
{
   local extensions="$1"


   local s
   local line

   .foreachline line in ${extensions}
   .do
      r_colon_concat "${s}" "${line}"
      s="${RVAL}"
   .done

   RVAL="${s}"
}


sde::patternfile::sorted_colons()
{
   tr ':' '\012' | sort | tr '\012' ':' | sed 's/:$//'
}


sde::patternfile::main()
{
   log_entry "sde::patternfile::main" "$@"

   local cmd="$1" ; shift

   local sayok

   local rval
   local name

   rval=-1
   case "${cmd}" in
      patternfile-editor)
         name="${MULLE_PATTERNFILE_EDITOR:-mulle-patternfile-editor}"
         if ! MULLE_PATTERNFILE_EDITOR=$(command  -v "${name}")
         then
            fail "\"${name}\" not installed.
${C_INFO}You can get ${C_RESET_BOLD}mulle-patternfile-editor${C_INFO} from
${C_RESET}   https://github.com/mulle-sde/mulle-patternfile-editor"
         fi
         rexekutor "${MULLE_PATTERNFILE_EDITOR}" "$@"
      ;;


      patterncheck)
         sayok='YES'
      ;;

      patternenv)
         sde::patternfile::r_searchnames
         sde::patternfile::r_environment_filter "${RVAL}"
         printf "%s\n" "${RVAL}"
         return 0
      ;;

      patternfile|pat|filename)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            rexekutor "${MULLE_MATCH:-mulle-match}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "${cmd}" \
                           "$@"
         rval=$?
      ;;

      patternmatch)
         MULLE_USAGE_NAME="${MULLE_USAGE_NAME}" \
            rexekutor "${MULLE_MATCH:-mulle-match}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                        "match" \
                           "$@"
         rval=$?
      ;;
   esac

   local before

   before="`mulle-sde env get MULLE_MATCH_FILENAMES`"

   sde::patternfile::r_searchnames
   sde::patternfile::r_environment_filter "${RVAL}"
   after="${RVAL}"

   if [ "${before}" != "${after}" ]
   then
      local missing
      local pattern
      local found
      
      .foreachpath pattern in ${after}
      .do
         found='NO'
         .foreachpath existing in ${before}
         .do
            if [ "${pattern}" = "${existing}" ]
            then
               found='YES'
               .break
            fi
         .done
         
         if [ "${found}" = 'NO' ]
         then
            r_colon_concat "${missing}" "${pattern}"
            missing="${RVAL}"
         fi
      .done
      
      if [ ! -z "${missing}" ]
      then
         r_colon_concat "${before}" "${missing}"
         local suggested="${RVAL}"
         
         r_escaped_doublequotes "${suggested}"
         suggested="${RVAL}"

         _log_warning "Environment variable ${C_RESET}MULLE_MATCH_FILENAMES${C_WARNING} is missing patterns from patternfiles.
${C_INFO}Current contents: ${C_RESET_BOLD}${before}${C_INFO}.
Missing patterns: ${C_RESET_BOLD}${missing}${C_INFO}.
Suggested command:
${C_RESET_BOLD}   mulle-sde env --global set MULLE_MATCH_FILENAMES=\"${suggested}\""
      fi
   else
      if [ "${sayok}" = 'YES' ]
      then
         _log_info "Environment variable ${C_RESET}MULLE_MATCH_FILENAMES${C_INFO} seems in sync with the patternfiles.
${C_INFO}Check ${C_RESET}MULLE_MATCH_PATH${C_INFO}, if files aren't found by ${C_RESET_BOLD}mulle-sde files${C_INFO}."
      fi
   fi

   return $rval
}
