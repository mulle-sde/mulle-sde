#! /usr/bin/env bash

CLASSIFY_DIRECTORY_SH="included"


classify_directory()
{
   log_entry "classify_directory" "$@"

   local directory="$1"

   if patternfile_matches_text "${MULLE_SDE_ETC_DIR}/source/directories" "${directory}"
   then
      echo "source"
      return 0
   fi

   if patternfile_matches_text "${MULLE_SDE_ETC_DIR}/test/directories" "${directory}"
   then
      echo "test"
      return 0
   fi

   return 1
}

