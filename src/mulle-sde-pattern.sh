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
MULLE_SDE_PATTERN_SH="included"

#
# This is pretty similiar to.gitignore. But there are differences.
# For example the '!' operator preempts the search in a collection
# of patterns
#
pattern_matches_text()
{
   log_entry "pattern_matches_text" "$@"

   local pattern="$1"
   local text="$2"
   local flags="$3"

   #
   # if we are strict on text input, we can simplify pattern handling
   # a lot. Note that we only deal with relative paths anyway
   #
   case "${text}" in
      "")
         internal_fail "Empty text is illegal"
      ;;

      /*)
         internal_fail "Text \"${text}\" is illegal. It must not start with '/'"
      ;;

      */)
         internal_fail "Text \"${text}\" is illegal. It must not end with '/'"
      ;;
   esac

   case "${pattern}" in
      "")
         internal_fail "Empty pattern is illegal"
      ;;

      *//*)
         internal_fail "Pattern \"${pattern}\" is illegal. It must not contain  \"//\""
      ;;
   esac

   local YES=0
   local NO=1

   # gratuitous

   case "${flags}" in
      *WM_CASEFOLD*)
         pattern="` tr 'A-Z' 'a-z' <<< "${pattern}" `"
      ;;
   esac

   #
   # simple invert
   #
   case "${pattern}" in
      !*)
         pattern="${pattern:1}"
         YES=2   # negated
         NO=1    # doesn't match so we dont care
      ;;
   esac

   #
   # For things that look like a directory (trailing slash) we try to do it a little
   # differently. Otherwise its's pretty much just a tail match.
   #
   case "${pattern}" in
      /*/)
         case "${text}" in
            ${pattern:1:-1}|${pattern:1}*)
               return $YES
            ;;
         esac
      ;;

      */)
         case "${text}" in
            ${pattern:0:-1}|${pattern}*|*/${pattern}*)
               return $YES
            ;;
         esac
      ;;

      /*)
         case "${text}" in
            ${pattern:1})
               return $YES
            ;;
         esac
      ;;

      *)
         case "${text}" in
            ${pattern}|*/${pattern})
               return $YES
            ;;
         esac
      ;;
   esac

   return $NO
}

#
# There is this weird bash bug on os x, where the patterns do
# not appear int the entry output. I don't know why.
# ```
# 1517521574.715441519 patternlines_match_text 'src/main.c', '', '"/tmp/a/.mulle-sde/etc/source/patterns/90_SOURCES"'
# +++++ mulle-sde-pattern.sh:143 + local 'patterns=*.c'
# ```
patternlines_match_text()
{
   log_entry "patternlines_match_text" "$@"

   local patterns="$1"
   local text="$2"
   local flags="$3"
   local where="$4"

   local pattern
   local rval

   rval=1
   IFS="
"
   for pattern in ${patterns}
   do
      IFS="${DEFAULT_IFS}"

      pattern_matches_text "${pattern}" "${text}" "${flags}"
      case "$?" in
         0)
            log_debug "Pattern \"${pattern}\" did match text \"${text}\""
            rval=0
         ;;

         2)
            log_debug "Pattern \"${pattern}\" negates \"${text}\""
            rval=1
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"

   if [ $rval -eq 1 ]
   then
      log_debug "Text \"${text}\" did not match any patterns in ${where}"
   fi

   return $rval
}


patternfile_read()
{
   log_entry "patternfile_read" "$@"

   local filename="$1"
   (
      shopt -s globstar 2> /dev/null # bash 4.0

      while read line
      do
         if [ -z "${line}" ]
         then
            continue
         fi

         echo "${line}"
      done < <( egrep -v -s '^#' "${filename}" )
   )
}


patternfile_matches_text()
{
   log_entry "patternfile_matches_text" "$@"

   local filename="$1"
   local text="$2"
   local flags="$3"

   [ -z "${filename}" ] && internal_fail "filename is empty"
   [ -z "${text}" ]     && internal_fail "text is empty"

   case "${flags}" in
      *WM_CASEFOLD*)
         text="` tr 'A-Z' 'a-z' <<< "${text}" `"
      ;;
   esac

   local lines

   lines="` patternfile_read "${filename}" `"
   if [ -z "${lines}" ]
   then
      log_debug "\"${filename}\" does not exist or is empty"
      return 127
   fi

   patternlines_match_text "${lines}" "${text}" "${flags}" "\"${filename}\""
}


# main()
# {
#    while [ $# -ne 0 ]
#    do
#       if options_technical_flags "$1"
#       then
#          shift
#          continue
#       fi
#
#       break
#    done
#
#    options_setup_trace "${MULLE_TRACE}"
#
#    patternfile_matches_text "$@"
# }
#
#
#
# init()
# {
#    MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path 2> /dev/null`"
#    [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && \
#       echo "mulle-bashfunctions-env not installed" >&2 && \
#       exit 1
#
#    . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" "minimal" || exit 1
# }
#
# init "$@" # needs params
# main "$@"
