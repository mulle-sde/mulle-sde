#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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
MULLE_SDE_UPDATESUPPORT_SH="included"

#
# use for results retrieved from get_libraries_list
# or get_depedencies_list
#
_emit_dependencies()
{
   log_entry "_emit_dependencies" "$@"

   local name="$1"; shift
   local dependencies="$1"; shift
   local emitter="$1"; shift

   local dependency

   IFS="
"
   for dependency in ${dependencies}
   do
      IFS="${DEFAULT_IFS}"

      local address
      local marks
      local aliases

      IFS=";" read address marks aliases <<< "${dependency}"

      if [ ! -z "${address}" ]
      then
         log_verbose "Emit statements for ${name} ${C_MAGENTA}${C_BOLD}${address}"
         ${emitter} "${address}" "${marks}" "${aliases}" "$@"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


emit_dependencies()
{
   log_entry "emit_dependencies" "$@"

   _emit_dependencies "dependency" "$@"
}


emit_libraries()
{
   log_entry "emit_libraries" "$@"

   _emit_dependencies "library" "$@"
}


get_libraries_list()
{
  log_entry "get_libraries_list" "$@"

   if [ -z "${MULLE_SDE_LIBRARIES_SH}" ]
   then
      # shellcheck source=src/mulle-sde-libraries.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-libraries.sh"
   fi

   sde_libraries_main list --output-raw --no-output-header
}


get_no_include_dependencies_list()
{
   log_entry "get_no_include_dependencies_list" "$@"

   if [ -z "${MULLE_SDE_DEPENDENCIES_SH}" ]
   then
      # shellcheck source=src/mulle-sde-dependencies.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-dependencies.sh"
   fi

   sde_dependencies_main list \
                         --format "am" \
                         --marks no-include,link \
                         --output-raw \
                         --no-output-header
}


get_include_dependencies_list()
{
   log_entry "get_include_dependencies_list" "$@"

   if [ -z "${MULLE_SDE_DEPENDENCIES_SH}" ]
   then
      # shellcheck source=src/mulle-sde-dependencies.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-dependencies.sh"
   fi

   sde_dependencies_main list \
                         --format "am" \
                         --marks include,link \
                         --output-raw \
                         --no-output-header
}


get_dependencies_list()
{
   log_entry "get_dependencies_list" "$@"

   if [ -z "${MULLE_SDE_DEPENDENCIES_SH}" ]
   then
      # shellcheck source=src/mulle-sde-dependencies.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-dependencies.sh"
   fi

   sde_dependencies_main list \
                         --format "am" \
                         --marks link \
                         --output-raw \
                         --no-output-header
}

#
#
#

filter_lines_with_file()
{
   log_entry "filter_lines_with_file" "$@"

   if [ -f "$1" ]
   then
      fgrep -v -x -f "$1"
   else
      cat
   fi
}


#
# find all directories which may contain sources
# the consumer shouldn't do anything recursive afterwards because
# we did it for him already.
# We purposefully ignore all "hidden"
# directories and some common build and output directory names.
# If this ever becomes a problem, then outsource the find statement.
#
_find_directories_quoted()
{
   log_entry "_find_directories_quoted" "$@"

   local patterns="$1"
   local quote="$2"
   local where="$3"

   if [ -z "${patterns}" ]
   then
      log_warning "Did not find ${where}"
      return
   fi

   local i

   IFS="
"
   for i in `find . -mindepth 1 \
                    -type d \
                    \( -not -path '*/\.*' -a \
                       -not -path '*/build' -a \
                       -not -path '*/build/*' -a \
                       -not -path '*/build.d' -a \
                       -not -path '*/build.d/*' -a \
                       -not -path '*/dependencies' -a \
                       -not -path '*/dependencies/*' -a \
                       -not -path '*/addictions' -a \
                       -not -path '*/addictions/*'  \
                    \) \
                    -print`
   do
      IFS="${DEFAULT_IFS}"

      i="${i:2}" # remove ./

      if patternlines_match_text "${patterns}" "${i}" "" "${where}"
      then
         echo "${quote}$i${quote}"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


find_source_directories_quoted()
{
   log_entry "find_source_directories_quoted" "$@"

   local quote="$1"

   if [ -z "${MULLE_SDE_PATTERN_SH}" ]
   then
      # shellcheck source=src/mulle-sde-pattern.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-pattern.sh"
   fi

   local patterns

   patterns="`patternfile_read "${MULLE_SDE_ETC_DIR}/source/directories"`"

   _find_directories_quoted "${patterns}" "${quote}" "\"source/directories\""
}


find_header_directories_quoted()
{
   log_entry "find_header_directories_quoted" "$@"

   local quote="$1"

   if [ -z "${MULLE_SDE_PATTERN_SH}" ]
   then
      # shellcheck source=src/mulle-sde-pattern.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-pattern.sh"
   fi

   local patterns

   patterns="`patternfile_read "${MULLE_SDE_ETC_DIR}/header/directories"`"

   _find_directories_quoted "${patterns}" "${quote}" "\"header/directories\""
}


_find_files_quoted()
{
   log_entry "_find_files_quoted" "$@"

   local patterns="$1"; shift
   local quote="$1"; shift
   local where="$1"; shift

   [ $# -eq 0 ] && internal_fail "no dirs given"

   local i

   IFS="
"
   for i in `find "$@" -mindepth 1 -maxdepth 1 -type f -print `
   do
      IFS="${DEFAULT_IFS}"

      if patternlines_match_text "${patterns}" "${i}" "" "${where}"
      then
         rexekutor echo "${quote}$i${quote}"
      fi
   done
   IFS="${DEFAULT_IFS}"

}


find_headers_quoted()
{
   log_entry "find_headers_quoted" "$@"

   local quote="$1"; shift

   if [ -z "${MULLE_SDE_PATTERN_SH}" ]
   then
      # shellcheck source=src/mulle-sde-pattern.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-pattern.sh"
   fi

   local patterns

   patterns="`patternfile_read "${MULLE_SDE_ETC_DIR}/header/files"`"

   _find_files_quoted "${patterns}" "${quote}" "\"header/files\"" "$@"
}


find_sources_quoted()
{
   log_entry "find_sources_quoted" "$@"

   local quote="$1"; shift

   if [ -z "${MULLE_SDE_PATTERN_SH}" ]
   then
      # shellcheck source=src/mulle-sde-pattern.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-pattern.sh"
   fi

   local patterns

   patterns="`patternfile_read "${MULLE_SDE_ETC_DIR}/source/files"`"

   _find_files_quoted "${patterns}" "${quote}" "\"source/files\"" "$@"
}


#
# header emission
#
_emit_include_dirs_contents()
{
   log_entry "_emit_include_dirs_contents" "$@"

   local headers="$1"

   local i

   old="$IFS"
   IFS="
"
   for i in ${headers}
   do
      rexekutor echo "`dirname -- "${i}"`"
   done
   IFS="$old"
}


emit_include_dirs_contents()
{
   log_entry "emit_include_dirs_contents" "$@"

   _emit_include_dirs_contents "$@" | sort -u
}


emit_classified_files()
{
   log_entry "emit_classified_files" "$@"

   local classifier="$1"
   local files="$2"
   local emitter="$3"

   [ -z "${classifier}" ] && internal_fail "classifier is empty"
   [ -z "${emitter}" ] && internal_fail "emitter is empty"

   if [ -z "${files}" ]
   then
      return
   fi

   local filename

   local cmdline
   local filename

   cmdline="'${classifier}'"
   IFS="
"
   for filename in ${files}
   do
      cmdline="${cmdline} '${filename}'"
   done
   IFS="${DEFAULT_IFS}"

   local varname
   local collectname
   local collection

   while IFS=";" read varname filename
   do
      if [ -z "${varname}" ]
      then
         continue
      fi

      if [ "${varname}" != "${collectname}" ]
      then
         "${emitter}" "${collectname}" "${collection}"
         collectname="${varname}"
         collection="${filename}"
      else
         collection="`add_line "${collection}" "${filename}"`"
      fi
   done < <( eval "${cmdline}")

   if [ ! -z "${collection}" ]
   then
      "${emitter}" "${collectname}" "${collection}"
   fi
}
