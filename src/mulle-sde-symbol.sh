#! /usr/bin/env mulle-bash
#! MULLE_BASHFUNCTIONS_VERSION=<|MULLE_BASHFUNCTIONS_VERSION|>
# shellcheck shell=bash
#
#
#  mulle-sde-symbols.sh
#  src
#
#  Copyright (c) 2024 Nat! - Mulle kybernetiK.
#  All rights reserved.
#
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
#  Neither the name of Mulle kybernetiK nor the names of its contributors
#  may be used to endorse or promote products derived from this software
#  without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
MULLE_SDE_SYMBOL_SH='included'

sde::symbol::print_flags()
{
   echo "   -f    : force operation"

   ##
   ## ADD YOUR FLAGS DESCRIPTIONS HERE
   ##

   options_technical_flags_usage \
                "         : "
}


sde::symbol::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-sde symbol [flags]

   List symbols defined in the public headers (by default) by classes.
   Unfortunately ctags does not do categories or protocols, so the output
   is very incomplete.

   clangd is supergimped and useless.

Flags:
EOF
   sde::symbol::print_flags | LC_ALL=C sort >&2

   exit 1
}



#
# copy files to header, remove MULLE_OBJC_THREADSAFE_METHOD
# and MULLE_OBJC_THREADSAFE_PROPERTY
#
sde::symbol::copy_and_preprocess_sources()
{
   log_entry "sde::symbol::copy_and_prepocess_sources" "$@"

   local tmp_dir="$1"

   local filename 

   while read -r filename
   do
      r_dirname "${filename}"
      dir_path="${RVAL}"
      
      if [ "${dir_path}" != "." ]
      then
         mkdir_if_missing "${tmp_dir}/${dir_path}"
      fi

      r_filepath_concat "${tmp_dir}" "${filename}"
      #
      # MEMO: #pragma mark - trips up ctags, so we just remove pragma lines
      #
      redirect_exekutor "${RVAL}" sed -e 's/MULLE_OBJC_[A-Z][A-Z]*_METHOD//g' \
                                      -e 's/MULLE_[A-Z][A-Z]*GLOBAL//g' \
                                      -e 's/^[ ]*#[ ]*pragma.*$//' \
                                      "${filename}" \
      || fail "Failed to copy ${filename}"
   done
}



sde::symbol::ctags()
{
   log_entry "sde::symbol::ctags" "$@"

   local tmp_dir

   r_make_tmp_directory || exit 1
   tmp_dir="${RVAL}"

   sde::symbol::copy_and_prepocess_sources "${tmp_dir}" < \
      <( rexekutor mulle-match list --category-matches  "${OPTION_CATEGORY}" ) || exit 1

   local language

   language='ObjectiveC'

   local rval 

   (
      exekutor cd "${tmp_dir}" 
      find . -type f -print \
      | rexekutor grep -E -v '/reflect/|/generic/' \
      | rexekutor ctags -x -L - "--languages=${language}" \
                      "--kinds-${language}=${OPTION_KINDS}" \
                      --_xformat="${OPTION_FORMAT}" \
      | rexekutor sed 's/^method /-/;s/^class /+/'
   )
   rval=$?

   if [ "${OPTION_KEEP_TMP}" = 'NO' ]
   then
      rmdir_safer "${tmp_dir}"
   else
      log_info "Tmp is ${C_RESET}${tmp_dir}"
   fi

   return $rval
}



sde::symbol::generate_compilation_database()
{
   log_entry "sde::symbol::generate_compilation_database" "$@"

   echo "["

   local file

   while IFS= read -r file
   do
      cat <<EOF
   {
      "directory": "$PWD",
      "file": "$file",
      "command": "mulle-clang -x objective-c -c $file"
   },
EOF
   done | sed '$ s/,$//'
   echo "]"
}


sde::symbol::clangd()
{
   log_entry "sde::symbol::clangd" "$@"
   
   local tmp_dir

   r_make_tmp_directory || exit 1
   tmp_dir="${RVAL}"

   sde::symbol::copy_and_preprocess_sources "${tmp_dir}" < \
      <( rexekutor mulle-match list --category-matches  "${OPTION_CATEGORY}" ) || exit 1

   local rval 

   (
      exekutor cd "${tmp_dir}" || exit 1
      
      find . -type f -not -name "compile_commands.json" -print \
      | redirect_exekutor "compile_commands.json" sde::symbol::generate_compilation_database

      rexekutor clangd --compile-commands-dir=. "$@"
   )
   rval=$?

   if [ "${OPTION_KEEP_TMP}" = 'NO' ]
   then
      rmdir_safer "${tmp_dir}"
   else
      log_info "Tmp is ${C_RESET}${tmp_dir}"
   fi

   return $rval
}


sde::symbol::main()
{
   #
   # simple option/flag handling
   #
   local OPTION_CATEGORY='public-headers'
   local OPTION_KINDS='cm'
   local OPTION_FORMAT='%K [%s %N] %F:%n'
   local OPTION_KEEP_TMP='NO'
   local OPTION_CTAGS='NO'

   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -f|--force)
            MULLE_FLAG_MAGNUM_FORCE='YES'
         ;;

         -h*|--help|help)
            sde::symbol::usage
         ;;

         --ctags)
            OPTION_CTAGS='YES'
         ;;

         --clangd)
            OPTION_CTAGS='NO'
         ;;

         --keep-tmp)
            OPTION_KEEP_TMP='YES'
         ;;

         --category)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_CATEGORY="$1"
         ;;

         --kinds)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_KINDS="$1"
         ;;

         --format)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_FORMAT="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            sde::symbol::usage "Unknown flag \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   options_setup_trace "${MULLE_TRACE}" && set -x

   if [ "${OPTION_CTAGS}" = 'YES' ]
   then
      sde::symbol::ctags "$@"
      return $?
   fi

   sde::symbol::clangd "$@"
}
