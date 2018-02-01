#! /usr/bin/env bash

CLASSIFY_HEADERS_SH="included"

#
# get a list of files, classify them as
#
# variablename;filename
#


classify_header()
{
   log_entry "classify_header" "$@"

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


classify_headers()
{
   log_entry "classify_headers" "$@"

   local headerfile

   if [ -z "${MULLE_SDE_PATTERN_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-pattern.sh" || internal_fail "missing file"
   fi

   if [ -d "${MULLE_SDE_ETC_DIR}/header/patterns" ]
   then
   (
      exekutor cd "${MULLE_SDE_ETC_DIR}/header/patterns"

      for headerfile in "$@"
      do
         classify_header "${headerfile}"
      done
   )
   fi
}
