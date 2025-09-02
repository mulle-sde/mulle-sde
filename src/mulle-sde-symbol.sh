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
   echo "   -f                   : force operation"
   echo "   --category <name>    : mulle-match category (${OPTION_CATEGORY})"
   echo "   --ctags-kinds <s>    : ctags kinds to list, e.g. cm for +/-methods"
   echo "   --ctags-language <s> : ctags language to use"
   echo "   --ctags-output <s>   : ctags output format (json)"
   echo "   --ctags-xformat <s>  : ctags xformat"
   echo "   --sources            : scan sources for ctags"
   echo "   --headers            : scan all headers for ctags"
   echo "   --public-headers     : scan public headers for ctags (default)"
   echo "   --ctags-xformat <s>  : ctags xformat"
   echo "   --csv-separator <s>  : separator character for CSV ('${OPTION_SEPARATOR}')"
   echo "   --keep-tmp           : keep temporary created files (for debugging)"
   ##
   ## ADD YOUR FLAGS DESCRIPTIONS HERE
   ##

   options_technical_flags_usage \
                "                : "
}


sde::symbol::usage()
{
   [ $# -ne 0 ] && log_error "$*"


   cat <<EOF >&2
Usage:
   mulle-sde symbol [flags] -- ...

   List symbols defined in the public headers (by default). This is a
   convenient way to run \`mulle-match list --category-matches public-headers\`
   and then execute \`ctags\` to create a list of symbols.

   All arguments after -- are passed to \`ctags\`.

   The ctags output formats are: u-ctags|e-ctags|etags|xref|json|csv. The
   default output is JSON for languages other than Objective-C and C. The tags
   formats will create a tags or TAGS file, instead of printing to standard
   output.

Flags:
EOF
   sde::symbol::print_flags | LC_ALL=C sort >&2

   exit 1
}

#
# So this is _maybe_ a little overengineered. We want to match "objc"
# against "ObjectiveC"

#
# Convert string to double metaphone code
# Parameters:
#   1: string to convert
# Returns:
#   RVAL: metaphone code
#
r_double_metaphone()
{
   local str="${1:-}"
   local len
   local i
   local char
   local code
   local prev_char

   # convert to uppercase
   str="${str^^}"
   len=${#str}
   code=""
   prev_char=""

   # basic rules for programming language names
   for ((i=0; i<len; i++))
   do
      char="${str:$i:1}"
      case "${char}" in
         [AEIOU])
            [ $i -eq 0 ] && code="${code}A"
            ;;
         [B])
            code="${code}B"
            ;;
         [C])
            if [ "${str:$i:2}" = "CH" ]
            then
               code="${code}X"
               ((i++))
            else
               code="${code}K"
            fi
            ;;
         [DT])
            code="${code}T"
            ;;
         [L])
            code="${code}L"
            ;;
         [MN])
            code="${code}N"
            ;;
         [P])
            code="${code}P"
            ;;
         [R])
            code="${code}R"
            ;;
         [SZ])
            code="${code}S"
            ;;
         [FV])
            code="${code}F"
            ;;
         [WY])
            [ $i -eq 0 ] && code="${code}A"
            ;;
         [XKQ])
            code="${code}K"
            ;;
         [JG])
            code="${code}J"
            ;;
      esac
      prev_char="${char}"
   done

   RVAL="${code}"
}

#
# Calculate similarity between two strings using metaphone
# Parameters:
#   1: string1
#   2: string2
# Returns:
#   RVAL: similarity score (0-100, higher is better match)
#
r_phonetic_match()
{
   local str1="${1:-}"
   local str2="${2:-}"
   local code1
   local code2
   local len1
   local len2
   local matches
   local i

   r_double_metaphone "${str1}"
   code1="${RVAL}"
   r_double_metaphone "${str2}"
   code2="${RVAL}"

   len1=${#code1}
   len2=${#code2}
   matches=0

   # Compare codes
   for ((i=0; i<len1 && i<len2; i++))
   do
      [ "${code1:$i:1}" = "${code2:$i:1}" ] && ((matches++))
   done

   # Score based on matches and length
   if [ ${len1} -gt ${len2} ]
   then
      RVAL=$((matches * 100 / len1))
   else
      RVAL=$((matches * 100 / len2))
   fi
}


#! /bin/bash

#
# Find best matching languages from ctags list
# Parameters:
#   1: search term
#   2: minimum score (optional, default: 80)
# Returns:
#   prints matching languages to stdout
#
#! /bin/bash

#
# Find best matching languages from ctags list
# Parameters:
#   1: search term
# Returns:
#   prints matching languages to stdout
#
r_find_best_language_matches()
{
   local search="${1:-}"

   local best_score=0
   local matches=""
   local language
   local score

   while read -r language
   do
      case "${language}" in
         *'[disabled]'*)
            continue
         ;;
      esac

      r_phonetic_match "${search}" "${language}"
      score=${RVAL}

      # skip zero scores
      [ ${score} -eq 0 ] && continue

      # collect languages with equal best score
      if [ ${score} -gt ${best_score} ]
      then
         best_score=${score}
         matches="${language}"
      else
         if [ ${score} -eq ${best_score} ]
         then
            r_add_line "${matches}" "${language}"
            matches="${RVAL}"
         fi
      fi
   done < <(rexekutor ctags --list-languages)

   log_debug "matches: $matches"
   RVAL="${matches}"
}

#
# Select best candidate from a list of matches
# Parameters:
#   1: search term
#   2: newline separated list of candidates
# Returns:
#   RVAL: selected candidate
#
r_select_best_candidate()
{
   local search="${1:-}"
   local candidates="${2:-}"

   local best
   local candidate

   .foreachline candidate in ${candidates}
   .do
      # check for exact match first (case insensitive)
      if [ "${candidate,,}" = "${search,,}" ]
      then
         RVAL="${candidate}"
         return
      fi
   .done

   # no exact match, pick shortest
   best=""
   .foreachline candidate in ${candidates}
   .do
      if [ -z "${best}" ] || [ ${#candidate} -lt ${#best} ]
      then
         best="${candidate}"
      fi
   .done

   log_info "Picked ${C_MAGENTA}${BOLD}${best}${C_INFO} as best match"
   RVAL="${best}"
}





#
# copy files to header, remove MULLE_OBJC_THREADSAFE_METHOD
# and MULLE_OBJC_THREADSAFE_PROPERTY
#
sde::symbol::copy_and_preprocess_c_sources()
{
   log_entry "sde::symbol::copy_and_preprocess_c_sources" "$@"

   local tmp_dir="$1"
   local language="$2"

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
                                      -e 's/MULLE_OBJC_[A-Z][A-Z]*_PROPERTY//g' \
                                      -e 's/MULLE_[A-Z][A-Z]*GLOBAL/extern/g' \
                                      -e 's/[_]*PROTOCOLCLASS_INTERFACE[0-9]*(\([^)]*\))/@interface \1/g' \
                                      -e 's/PROTOCOLCLASS_IMPLEMENTATION(\([^)]*\))/@implementation \1/g' \
                                      -e 's/PROTOCOLCLASS_END/@end/g' \
                                      -e 's/^[ ]*#[ ]*pragma.*$//' \
                                      "${filename}" \
      || fail "Failed to copy ${filename}"
   done
}



sde::symbol::ctags()
{
   log_entry "sde::symbol::ctags" "$@"

   local type="$1"
   local category="$2"
   local language="$3"
   local dialect="$4"
   local output_format="$5"
   local kinds="$6"
   local xformat="$7"
   local keep_tmp="$8"

   shift 8

   local directory

   directory="${PWD}"

   local tmp_dir

   case "${dialect}" in
      c|objc)
         r_make_tmp_directory || exit 1
         tmp_dir="${RVAL}"

         local options

         if [ ! -z "${type}" ]
         then
            options="--type-matches '${type}'"
         fi
         if [ ! -z "${category}" ]
         then
            r_concat "${options}" "--category-matches '${category}'"
            options="${RVAL}"
         fi

         sde::symbol::copy_and_preprocess_c_sources "${tmp_dir}" < \
            <( eval_rexekutor mulle-match list "${options}" ) || exit 1
         directory="${tmp_dir}"
      ;;
   esac

   local rval 

   (
      if [ ! -z "${xformat}" ]
      then
         set -- --_xformat="${xformat}" "$@"
      fi

      exekutor cd "${directory}"

#      tree >&2

      rexekutor find . -type f -print \
      | rexekutor ctags --output-format="${output_format}" \
                        -L - \
                        "--languages=${language}" \
                        "--kinds-${language}=${kinds}" \
                        "$@" \
      | (
           if [ "${language}" = "ObjectiveC" ]
           then
              rexekutor sed 's/^method /-/;s/^class /+/'
           else
              cat
           fi
        )
   )
   rval=$?

   if [ ! -z "${tmp_dir}" ]
   then
      if [ "${keep_tmp}" = 'NO' ]
      then
         rmdir_safer "${tmp_dir}"
      else
         log_info "Tmp is ${C_RESET}${tmp_dir}"
      fi
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


# sde::symbol::clangd()
# {
#    log_entry "sde::symbol::clangd" "$@"
#
#    local tmp_dir
#
#    r_make_tmp_directory || exit 1
#    tmp_dir="${RVAL}"
#
#    sde::symbol::copy_and_preprocess_c_sources "${tmp_dir}" < \
#       <( rexekutor mulle-match list --category-matches  "${OPTION_CATEGORY}" ) || exit 1
#
#    local rval
#
#    (
#       exekutor cd "${tmp_dir}" || exit 1
#
#       find . -type f -not -name "compile_commands.json" -print \
#       | redirect_exekutor "compile_commands.json" sde::symbol::generate_compilation_database
#
#       rexekutor clangd --compile-commands-dir=. "$@"
#    )
#    rval=$?
#
#    if [ "${OPTION_KEEP_TMP}" = 'NO' ]
#    then
#       rmdir_safer "${tmp_dir}"
#    else
#       log_info "Tmp is ${C_RESET}${tmp_dir}"
#    fi
#
#    return $rval
# }
#

r_unique_chars()
{
   local str="${1:-}"
   local result=""
   local char
   local i

   for ((i=0; i<${#str}; i++))
   do
      char="${str:i:1}"
      case "${result}" in
         *"${char}"*)
            continue
            ;;
         *)
            result="${result}${char}"
            ;;
      esac
   done

   RVAL="${result}"
}


sde::symbol::main()
{
   #
   # simple option/flag handling
   #
   local OPTION_LANGUAGE
   local OPTION_CATEGORY='public-headers'
   local OPTION_KINDS
   local OPTION_OUTPUT_FORMAT  # u-ctags|e-ctags|etags|xref|json
   local OPTION_XFORMAT
   local OPTION_KEEP_TMP='NO'
   local OPTION_SEPARATOR='|'
   local OPTION_CATEGORY
   local OPTION_TYPE='header'

#   local OPTION_CTAGS='YES'

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

         --category)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_CATEGORY="$1"
         ;;

         # the default
         --public-headers)
            OPTION_CATEGORY='public*'
            OPTION_TYPE='header'
         ;;

         --headers)
            OPTION_TYPE='header'
            OPTION_CATEGORY=''
         ;;

         --sources)
            OPTION_TYPE='source'
            OPTION_CATEGORY=''
         ;;


#         --clangd)
#            OPTION_CTAGS='NO'
#         ;;
#
#         --ctags)
#            OPTION_CTAGS='YES'
#         ;;

         --ctags-kinds)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_KINDS="$1"
         ;;

         --ctags-language)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_LANGUAGE="$1"
         ;;

         --ctags-output|--ctags-output-format)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_OUTPUT_FORMAT="$1"
         ;;

         --ctags-xformat)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_XFORMAT="$1"
         ;;

         ## shortcuts

         --csv|--json)
            OPTION_OUTPUT_FORMAT="${1:2}"
         ;;

         -F|--csv-separator)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            OPTION_SEPARATOR="$1"
         ;;

         ## C kinds
         --enumerators)
             OPTION_KINDS="${OPTION_KINDS}e"
         ;;

         --enums)
             OPTION_KINDS="${OPTION_KINDS}g"
         ;;

         --externs|--extern-variables)
             OPTION_KINDS="${OPTION_KINDS}x"
         ;;

         --functions)
             OPTION_KINDS="${OPTION_KINDS}f"
         ;;

         --ctag-headers)
             OPTION_KINDS="${OPTION_KINDS}h"
         ;;

         --labels)
             OPTION_KINDS="${OPTION_KINDS}L"
         ;;

         --locals|--local-variables)
             OPTION_KINDS="${OPTION_KINDS}l"
         ;;

         --macro-parameters)
             OPTION_KINDS="${OPTION_KINDS}D"
         ;;

         --macros)
             OPTION_KINDS="${OPTION_KINDS}d"
         ;;

         --members)
             OPTION_KINDS="${OPTION_KINDS}m"
         ;;

         --parameters)
             OPTION_KINDS="${OPTION_KINDS}z"
         ;;

         --prototypes)
             OPTION_KINDS="${OPTION_KINDS}p"
         ;;

         --structs)
             OPTION_KINDS="${OPTION_KINDS}s"
         ;;

         --typedefs)
             OPTION_KINDS="${OPTION_KINDS}t"
         ;;

         --unions)
             OPTION_KINDS="${OPTION_KINDS}u"
         ;;

         --variables|--variable-definitions)
             OPTION_KINDS="${OPTION_KINDS}v"
         ;;

         ## Objective C kinds

         --categories)
            OPTION_KINDS="${OPTION_KINDS}C"
         ;;

         --class-methods)
            OPTION_KINDS="${OPTION_KINDS}c"
         ;;

         --fields)
            OPTION_KINDS="${OPTION_KINDS}E"
         ;;

         --implementations)
            OPTION_KINDS="${OPTION_KINDS}I"
         ;;

         --instance-methods)
            OPTION_KINDS="${OPTION_KINDS}m"
         ;;

         --interfaces)
            OPTION_KINDS="${OPTION_KINDS}i"
         ;;

         --methods)
            OPTION_KINDS="${OPTION_KINDS}mc"
         ;;

         --properties)
            OPTION_KINDS="${OPTION_KINDS}p"
         ;;

         --protocols)
            OPTION_KINDS="${OPTION_KINDS}P"
         ;;
         ##

         --dialect|--project-dialect)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            PROJECT_DIALECT="$1"
         ;;

         --keep-tmp)
            OPTION_KEEP_TMP='YES'
         ;;

         --language|--project-language)
            [ $# -eq 1 ] && sde::symbol::usage "missing argument to $1"
            shift

            PROJECT_LANGUAGE="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         --)
            shift
            break
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

   log_setting "PROJECT_LANGUAGE : ${PROJECT_LANGUAGE}"
   log_setting "PROJECT_DIALECT  : ${PROJECT_DIALECT}"

   local language
   local try_language
   local dialect

   dialect="${PROJECT_DIALECT:-${PROJECT_LANGUAGE:-c}}"
   language="${OPTION_LANGUAGE}"

   if [ -z "${language}" ]
   then
      r_find_best_language_matches "${dialect}"
      r_select_best_candidate "${dialect}" "${RVAL}"
      language="${RVAL}"
      if [ -z "${language}" ]
      then
         log_warning "Defaulting to C. Check ctags --list-languages for supported languages"
         language="C"
      fi
   fi

   # %F = input file
   # %n = line number
   # %l = language
   # %k = kind
   # %N = name
   # %s = scope
   # %t = typeref
   # %S = signature
   # %p = pattern

   if [ -z "${OPTION_OUTPUT_FORMAT}" ]
   then
      case "${language}" in
         'ObjectiveC')
            OPTION_OUTPUT_FORMAT='xref'
            OPTION_KINDS="${OPTION_KINDS:-cm}"

            case "${OPTION_KINDS}" in
               cm|mc|c|m)
                  OPTION_XFORMAT="${OPTION_XFORMAT:-%K [%s %N] %F:%n}"
               ;;

               [a-z]|[A-Z])
                  OPTION_XFORMAT="${OPTION_XFORMAT:-%N (%s) %F:%n}"
               ;;
            esac
         ;;

         #
         # ctags just does not seem to work with C headers and --language C
         # Exuberant Ctags 5.8, Copyright (C) 1996-2009 Darren Hiebert
         # Compiled: Sep  3 2021, 18:12:18
         # https://github.com/universal-ctags/ctags/issues/4290
         #
         'C')
            OPTION_KINDS=${OPTION_KINDS:-'f+p'}
            OPTION_OUTPUT_FORMAT='xref'
            if [ "${OPTION_TYPE}" = 'header' ]
            then
               language="C++" # circumvents bug in ctags 5.9.0
            fi
         ;;

         *)
            OPTION_KINDS="${OPTION_KINDS:-'*'}"
            OPTION_OUTPUT_FORMAT='json'
         ;;
      esac
   fi

   if [ "${OPTION_OUTPUT_FORMAT}" = 'csv' ]
   then
      OPTION_OUTPUT_FORMAT='xref'
      OPTION_XFORMAT="%F${OPTION_SEPARATOR}%n${OPTION_SEPARATOR}%l${OPTION_SEPARATOR}%k${OPTION_SEPARATOR}%N${OPTION_SEPARATOR}%s${OPTION_SEPARATOR}%t${OPTION_SEPARATOR}%S${OPTION_SEPARATOR}%p"
      OPTION_KINDS="${OPTION_KINDS:-'*'}"
      printf "input${OPTION_SEPARATOR}line${OPTION_SEPARATOR}language${OPTION_SEPARATOR}kind${OPTION_SEPARATOR}name${OPTION_SEPARATOR}scope${OPTION_SEPARATOR}typeref${OPTION_SEPARATOR}signature${OPTION_SEPARATOR}pattern\n"
   fi

   # too objc specific
   r_unique_chars "${OPTION_KINDS}"
   OPTION_KINDS="${RVAL:-N}"

   sde::symbol::ctags "${OPTION_TYPE}"          \
                      "${OPTION_CATEGORY}"      \
                      "${language}"             \
                      "${dialect}"              \
                      "${OPTION_OUTPUT_FORMAT}" \
                      "${OPTION_KINDS}"         \
                      "${OPTION_XFORMAT}"       \
                      "${OPTION_KEEP_TMP}"      \
                      "$@"
   return $?
#
#   log_warning "clangd support has not been coded yet"
#   sde::symbol::clangd "$@"
}
