# shellcheck shell=bash
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
MULLE_SDE_MIGRATE_SH='included'


# gets executed in a subshell
sde::migrate::from_v0_41_to_v42()
{
   log_entry "sde::migrate::from_v0_41_to_v42" "$@"

   exekutor "${MULLE_SDE:-mulle-sde}" \
               ${MULLE_TECHNICAL_FLAGS} \
               -N \
            reflect || exit 1

   local i

   if [ ! -z "${PROJECT_SOURCE_DIR}" ]
   then
      log_info "Removing duplicates of headers now residing in \"${PROJECT_SOURCE_DIR}/reflect\""
      # remove old headers
      shell_enable_extglob
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
      shell_enable_nullglob
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


sde::migrate::from_v0_46_to_v47()
{
   log_entry "sde::migrate::from_v0_46_to_v47" "$@"

   (
      shell_enable_nullglob

      local i
      local name

      for i in .mulle/etc/match/*.d/*-source--*headers .mulle/share/match/*.d/*-source--*headers
      do
         name="${i//-source--/-header--}"
         exekutor mv "$i" "${name}"
      done

      for i in .mulle/*/sourcetree
      do
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakeall-load cmake-all-load
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakeintermediate-link cmake-intermediate-link
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakesearchpath cmake-searchpath
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakedependency cmake-dependency
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakeadd cmake-add
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakeinherit cmake-inherit
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakeloader cmake-loader
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks suppress-system-path cmake-suppress-system-path
         exekutor mulle-sourcetree --config-dir "$i" -N rename-marks cmakeplatform-darwin cmake-platform-darwin
      done
   )
}


sde::migrate::from_v0_47_to_v1_14()
{
   log_entry "sde::migrate::from_v0_47_to_v1_14" "$@"

   local filename
   local files

   files="`find . -name "auxscope" \( -type d -name stash -prune \) -type f -print`"
   .foreachline filename in ${files}
   .do
      case "${filename}" in
         */.mulle/etc/env/auxscope)
            inplace_sed "${filename}" -e 's/^project;10$/project;20/'
         ;;
      esac
   .done
}


sde::migrate::from_v1_14_to_v2_2()
{
   log_entry "sde::migrate::from_v1_14_to_v2_2" "$@"

   local filename
   local files

   files="`find CMakeLists.txt cmake -type f -print 2> /dev/null`"
   .foreachline filename in ${files}
   .do
      case "${filename}" in
         CMakeLists.txt|cmake/*.cmake)
            inplace_sed "${filename}" -e 's/\${CMAKE_INCLUDES}/\${INSTALL_CMAKE_INCLUDES}/' \
                                      -e 's/DESTINATION\ *"include\/\([^/]*\)\/private/DESTINATION\ "include\/\1/'

         ;;
      esac
   .done
}


sde::migrate::do()
{
   log_entry "sde::migrate::do" "$@"

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
   minor="${version#*.}"
   minor="${minor%%.*}"

   if [ "${oldmajor}" -eq 0 -a "${major}" -eq 0 -a "${oldminor}" -lt 42 ]
   then
      (
         sde::migrate::from_v0_41_to_v42
      ) || exit 1
      oldmajor=0
      oldminor=42
   fi

   if [ "${oldmajor}" -eq 0 -a "${major}" -eq 0 -a "${oldminor}" -lt 47 ]
   then
      (
         sde::migrate::from_v0_46_to_v47
      ) || exit 1
      oldmajor=0
      oldminor=47
   fi

   if [ "${oldmajor}" -lt 1 ] || [ "${oldmajor}" -eq 1 -a "${oldminor}" -le 13 ]
   then
      (
         sde::migrate::from_v0_47_to_v1_14
      ) || exit 1
      oldmajor=1
      oldminor=14
   fi

   if [ "${oldmajor}" -lt 2 ] || [ "${oldmajor}" -eq 2 -a "${oldminor}" -le 2 ]
   then
      (
         sde::migrate::from_v1_14_to_v2_2
      ) || exit 1
      oldmajor=2
      oldminor=2
   fi

   #
   # if craft etc is same as share now, we can remove etc
   #
   if diff .mulle/etc/craft .mulle/share/craft > /dev/null 2>&1
   then
      log_info "Removing .mulle/etc/craft as it's not different from .mulle/share/craft"
      rmdir_safer .mulle/etc/craft
   fi
}


# useful for testing
sde::migrate::main()
{
   log_entry "sde::migrate::main" "$@"

   local newversion="${MULLE_EXECUTABLE_VERSION}"
   local oldversion

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::migrate::usage
         ;;

         -*)
            sde::migrate::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ $# -gt 0 ]
   then
      oldversion="$1"
      shift
   fi

   if [ $# -gt 0 ]
   then
      newversion="$1"
      shift
   fi

   [ $# -ne 0 ] && sde::migrate::usage "Supeflous arguments \"$*\""

   if [ -z "${MULLE_SDE_INIT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-init.sh"
   fi

   if [ -z "${oldversion}" ]
   then
      sde::init::r_get_old_version
      oldversion="${RVAL}"
   fi

   sde::init::protect_unprotect "Unprotect" "ug+w"
   (
      sde::migrate::do "${oldversion}" "${newversion}"
   )
   rval=$?

   sde::init::protect_unprotect "Protect" "a-w"

   return $rval
}
