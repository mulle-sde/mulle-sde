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

   sde_dependencies_main -s dependencies list \
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

   sde_dependencies_main -s dependencies list \
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

   sde_dependencies_main -s dependencies list \
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


_find_directories_list()
{
   log_entry "_find_directories_list" "$@"

   local directory
   local old

   IFS="
"
   for directory in "$@"
   do
      if [ ! -z "${old}" ]
      then
         printf " "
      fi

      printf "%s" "'${directory}'"

      old="${directory}"
   done

   IFS="${DEFAULT_IFS}"
}


_find_extensions_qualifier()
{
   log_entry "_find_extensions_qualifier" "$@"

   local ext
   local old

   for ext in $*
   do
      if [ ! -z "${old}" ]
      then
         printf "%s" " -o "
      fi

      printf "%s \"*.%s\"" "-name" "${ext}"
      old="${ext}"
   done
}



find_headers()
{
   log_entry "find_headers" "$@"

   local qualifier
   local directories

   local exedir
   local executable

   exedir="`dirname -- "$0" `"
   executable="${exedir}/is-header-or-source"
   extensions="`${executable} -lh`" || internal_fail "\"${executable}\" is missing"

   directories="`_find_directories_list "$@" `"
   qualifier="`_find_extensions_qualifier ${extensions}`"

   eval_exekutor find "${directories}" '\(' "${qualifier}" '\)' -print  \
      | exekutor egrep -v '/old/|/build/' \
      | exekutor filter_lines_with_file ".mulle-sde/share/ignore-headers"
}



find_sources()
{
   log_entry "find_sources" "$@"

   local qualifier
   local directories


   local exedir
   local executable

   exedir="`dirname -- "$0" `"
   executable="${exedir}/is-header-or-source"
   extensions="`${executable} -ls`" || internal_fail "\"${executable}\" is missing"

   directories="`_find_directories_list "$@" `"
   qualifier="`_find_extensions_qualifier ${extensions}`"

   local cmd

   eval_exekutor find "${directories}" '\(' "${qualifier}" '\)' -print  \
      | exekutor egrep -v '/old/|/build/' \
      | exekutor filter_lines_with_file ".mulle-sde/share/ignore-sources"
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
      echo "`dirname -- "${i}"`"
   done
   IFS="$old"
}


emit_include_dirs_contents()
{
   log_entry "emit_include_dirs_contents" "$@"

   _emit_include_dirs_contents "$@" | sort -u
}


emit_header_contents()
{
   log_entry "emit_header_contents" "$@"

   local headers="$1"

   egrep -v '\+Private\.h|_private\.h' <<< "${headers}"
}


emit_private_header_contents()
{
   log_entry "emit_private_header_contents" "$@"

   local headers="$1"

   egrep '\+Private\.h|_private\.h' <<< "${headers}"
}



emit_source_contents()
{
   log_entry "_emit_source_contents" "$@"

   local sources="$1"

   egrep -v '\Standalone\.|_standalone\.' <<< "${sources}"
}


emit_standalone_source_contents()
{
   log_entry "emit_standalone_source_contents" "$@"

   local sources="$1"

   egrep '\Standalone\.|_standalone\.' <<< "${sources}"
}


#
#
#
existing_source_dirs()
{
   log_entry "existing_source_dirs" "$@"

   local i
   local old

   local i

   old="$IFS"
   IFS="
"
   for i in "$@"
   do
      if [ -d "${i}" ]
      then
         echo "${i}"
      fi
   done
   IFS="$old"
}


source_directories()
{
   log_entry "main" "$@"

   local directorynames="$1"

   local executable
   if [ -z "${directorynames}" ]
   then
      executable="${MULLE_VIRTUAL_ROOT}/.mulle-sde/bin/source-directory-names"
      if [ -x "${executable}" ]
      then
         directorynames="`${executable}`" || internal_fail "\"${executable}\" failed"
      else
         fail "No source directories specified (and \"${executable}\"  doesn't exist)"
      fi
      if [ -z "${directorynames}" ]
      then
         fail "\"${executable}\" returned nothing"
      fi
   fi

   existing_source_dirs "${directorynames}"
}

