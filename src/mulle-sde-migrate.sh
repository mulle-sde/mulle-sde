#! /usr/bin/env bash
#
#   Copyright (c) 2020 Nat! - Mulle kybernetiK
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
MULLE_SDE_MIGRATE_SH="included"


# gets executed in a subshell
sde_migrate_from_v0_41_to_v42()
{
   log_entry "sde_migrate_from_v0_41_to_v42" "$@"

   mulle-sde reflect

   local i

   if [ ! -z "${PROJECT_SOURCE_DIR}" ]
   then
      log_info "Removing duplicates of headers now residing in \"${PROJECT_SOURCE_DIR}/reflect\""
      # remove old headers
      shopt -s nullglob
      for i in "${PROJECT_SOURCE_DIR}"/reflect/*
      do
         r_basename "$i"
         remove_file_if_present "${PROJECT_SOURCE_DIR}/${RVAL}"
      done
      remove_file_if_present "${PROJECT_SOURCE_DIR}/objc-loader.inc"
   fi

   # remove old cmake stuff
   if [ -d cmake ]
   then
      log_info "Removing duplicates of cmake files now residing in \"cmake/reflect\""
      shopt -s nullglob
      for i in cmake/reflect/*
      do
         r_basename "$i"
         remove_file_if_present "cmake/${RVAL}"
      done

      #
      # Move old fashioned cmake files away now
      #
      log_info "Renaming cmake/ files Headers.cmake Sources.cmake DependenciesAndLibraries.cmake to .cmake.orig"

      [ -f "cmake/Headers.cmake" ] && exekutor mv cmake/Headers.cmake cmake/Headers.cmake.orig
      [ -f "cmake/Sources.cmake" ] && exekutor mv cmake/Sources.cmake cmake/Sources.cmake.orig
      [ -f "cmake/DependenciesAndLibraries.cmake" ] && exekutor mv cmake/DependenciesAndLibraries.cmake cmake/DependenciesAndLibraries.cmake.orig
   fi

   #
   # patch CMakeLists.txt
   #
   if [ -f "CMakeLists.txt" ]
   then
      log_info "Adding cmake/reflect to CMAKE_MODULE_PATH in CMakeLists.txt"
      exekutor cp CMakeLists.txt CMakeLists.txt.orig
      inplace_sed -e "/list( INSERT CMAKE_MODULE_PATH 0 \"\${PROJECT_SOURCE_DIR}\/cmake\/share\")/a\\
list( INSERT CMAKE_MODULE_PATH 0 \"\${PROJECT_SOURCE_DIR}/cmake/reflect\")" CMakeLists.txt
   fi
}


sde_migrate()
{
   log_entry "sde_migrate" "$@"

   local oldversion="$1"
   local version="$2"

   if [ -f ".mulle/share/env/include-environment.sh" ]
   then
      export MULLE_VIRTUAL_ROOT="`pwd -P`"

      log_fluff "Rereading settings in subshell"
      . ".mulle/share/env/include-environment.sh"
   fi

   local oldmajor
   local oldminor

   oldmajor="${oldversion%%.*}"
   oldminor="${oldversion#*.}"
   oldminor="${oldminor%%.*}"

   local major
   local minor

   major="${version%%.*}"
   minor="${minor#*.}"
   minor="${minor%%.*}"

   if [ "${oldmajor}" -eq 0 -a "${major}" -eq 0 -a "${oldminor}" -lt 42 ]
   then
      (
         sde_migrate_from_v0_41_to_v42
      ) || exit 1
      oldmajor=0
      oldminor=42
   fi

   #
   # if craft etc is same as share now, we can remove etc
   #
   if diff -q .mulle/etc/craft .mulle/share/craft > /dev/null 2>&1
   then
      log_info "Removing .mulle/etc/craft as its no different from .mulle/share/craft"
      rmdir_safer .mulle/etc/craft
   fi
}
