#! /usr/bin/env bash

CLASSIFY_SOURCES_SH="included"

#
# get a list of files, classify them as
#
# variablename;filename
#
[ "${TRACE}" = "YES" ] && set -x && : "$0" "$@"


classify_source()
{
   log_entry "classify_source" "$@"

   local filename="$1"

   shopt -s nullglob
   for patternfile in [0-9][0-9]_*
   do
      shopt -u nullglob
      if patternfile_matches_text "${patternfile}" "${filename}"
      then
         echo "${patternfile:3};${filename}"
      fi
   done
   shopt -u nullglob
}


classify_sources()
{
   log_entry "classify_sources" "$@"

   local sourcefile

   if [ -z "${MULLE_SDE_PATTERN_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-pattern.sh" || internal_fail "missing file"
   fi

   if [ -d "${MULLE_SDE_ETC_DIR}/source/patterns" ]
   then
   (
      exekutor cd "${MULLE_SDE_ETC_DIR}/source/patterns"

      for sourcefile in "$@"
      do
         classify_source "${sourcefile}"
      done
   )
   fi
}


