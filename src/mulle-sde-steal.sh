#! /usr/bin/env bash
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
MULLE_SDE_STEAL_SH="included"


sde_steal_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} steal [options] <URL>

   Steal source code from a mulle-c compatible repository, and flatten the
   source files into a destination directory, which is the current working
   directory by default.

   Individual include.h and include-private.h headers will be created.
   In the ideal and common case, you don't have to edit anything.

Options:
   -d <dir>               : change destination directory (PWD)
EOF
  "${MULLE_SOURCETREE}" add --print-common-options >&2
  echo "" >&2
  exit 1
}



fetch_repositories()
{
   log_entry "fetch_repositories" "$@"

   local tmpdir="$1" ; shift

   (
      cd "${tmpdir}" &&
      exekutor "${MULLE_SOURCETREE}" ${MULLE_TECHNICAL_FLAGS} -s -N add "$@" &&
      exekutor "${MULLE_SOURCETREE}" ${MULLE_TECHNICAL_FLAGS} -N sync
   )
}


combine_sources()
{
   log_entry "combine_sources" "$@"

   local dstdir="$1"; shift
   local tmpdir="$1"; shift

   # should check that nothing gets clobbered ...
   (
      cd "${tmpdir}" &&
      #
      # Dont want include.h, include-private.h which we need to merge
      # differently. Also don't want any .mulle or .git files or some such.
      # And we only care for sources... Don't want any test files either
      # (farmhash)
      #
      # If we hit a folder with a 'main.c' file, we ignore the whole folder.
      #
      local cmdline

      cmdline="find stash/*/src"
      prunes=""

      for main in `rexekutor find stash/*/src -type 'f' -name "main.[cm]" -print`
      do
         r_dirname "${main}"
         r_concat "${prunes}" "-path '${RVAL}'" " -o "
         prunes="${RVAL}"
      done

      if [ ! -z "${prunes}" ]
      then
         cmdline="${cmdline} \\( ${prunes} \\) -prune -o "
      fi

      expr="-type 'f' -a \
            \\( \
               \\! -name 'include.h' -a \
               \\! -name 'include-private.h' -a \
               \\! -regex '.*/\.[a-z]/.*' -a \
               \\( \
                  -name '*.[hcm]' -o \
                  -name '*.inc' -o \
                  -name '*.aam' \
               \\) -a \
               \\! -name '[_-]standalone.[cm]' -a \
               \\! -name '[_-]test.[hcm]' -a \
               \\! -name '[_-]test.inc' -a \
               \\! -name '[_-]test.aam' \
            \\)"

      # make it nicer to print for exekutor by removing superflous space
      local old

      old=""
      while [ "${old}" != "${expr}" ]
      do
         old="${expr}"
         expr="${expr//  / }"
      done

      cmdline="${cmdline} ${expr} -print0"

      eval_exekutor "${cmdline}" \
         | exekutor xargs -0 '-I%' cp -p -n '%' "${dstdir}/"
   )
}


create_include()
{
   log_entry "create_include" "$@"

   local identifier="$1"

   local header

   rexekutor echo "#ifndef ${identifier}_include_h__"
   rexekutor echo "#define ${identifier}_include_h__"
   rexekutor echo ""
   (
      shopt -s nullglob
      for header in _*-include.h
      do
         rexekutor echo "# include \"${header}\""
      done
   )
   rexekutor echo ""
   rexekutor echo "#endif ${identifier}_include_h__"
}


create_include_private()
{
   log_entry "create_include_private" "$@"

   local identifier="$1"

   local header

   rexekutor echo "#ifndef ${identifier}_include_private_h__"
   rexekutor echo "#define ${identifier}_include_private_h__"
   rexekutor echo ""
   (
      shopt -s nullglob
      for header in _*-include-private.h
      do
         rexekutor echo "#include \"${header}\""
      done
   )
   rexekutor echo ""
   rexekutor echo "#endif ${identifier}_include_private_h__"
}



create_include_files()
{
   log_entry "create_include_files" "$@"

   local identifier="$1"

   redirect_exekutor include.h create_include "${identifier}"  &&
   redirect_exekutor include-private.h create_include_private "${identifier}"
}


#
# TODO: Doesn't work 100% for mulle-data, since it embeds farmhash, which
# ususally runs configure before (though it never uses the config.h file ?)
# Doesn't work for mulle-thread, since it doesn't catch mintomic.
#

sde_steal_main()
{
   log_entry "sde_steal_main" "$@"

   local KEEP_TMP='DEFAULT'

   MULLE_SOURCETREE="$(command -v mulle-sourcetree)"
   [ -z "${MULLE_SOURCETREE}" ] && fail "No \"mulle-sourcetree\" found in PATH ($PATH)"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde_steal_usage
         ;;

         --keep-tmp)
            KEEP_TMP='YES'
         ;;

         -d)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            exekutor mkdir -p "$1" 2> /dev/null
            exekutor cd "$1" || fail "can't change to \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sde_steal_usage "Missing URL"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=mulle-init.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"   || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=mulle-init.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"   || return 1
   fi


   #
   # Create a tmp directory, where we want to fetch stuff into.
   # Then fetch, which will get us everything we (should) need
   #
   local tmpdir

   r_make_tmp "steal" "-d"
   tmpdir="${RVAL}"

   local name
   local identifier

   r_basename "${PWD}"
   name="${RVAL}"

   r_identifier "${name}"
   identifier="${RVAL:-unknown}"

   fetch_repositories "${tmpdir}" "$@" &&
   combine_sources "${PWD}" "${tmpdir}" &&
   create_include_files "${identifier}" || exit 1

   if [ "${KEEP_TMP}" = 'YES' ]
   then
      log_info "Not removing ${C_RESET_BOLD}${tmpdir}"
   else
      rmdir_safer "${tmpdir}"
   fi
}
