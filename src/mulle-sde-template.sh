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
MULLE_SDE_TEMPLATE_SH="included"

#
# TEMPLATE
#

template_usage()
{
   if [ -z "${TEMPLATE_USAGE_TEXT}" ]
   then
      TEMPLATE_USAGE_TEXT="`egrep -v '^#' "${TEMPLATE_DIR}/../../usage" 2> /dev/null `"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} [options]

   ${TEMPLATE_USAGE_TEXT:-Copy template files into the project.}

Options:
   -d <dir>   : use "dir" instead of working directory
   -p <name>  : give project a name
   -l <lang>  : specify project's main language (C)
   -t <dir>   : template directory to copy and expand from
EOF
   exit 1
}


expand_template_variables()
{
   log_entry "expand_template_variables" "$@"

   local escaped_pn
   local escaped_pi
   local escaped_pl
   local escaped_pui
   local escaped_pul
   local escaped_chn
   local escaped_umcli

   # verify minimal set
   [ -z "${PROJECT_NAME}" ] && internal_fail "PROJECT_NAME is empty"
   [ -z "${PROJECT_IDENTIFIER}" ] && internal_fail "PROJECT_IDENTIFIER is empty"
   [ -z "${PROJECT_LANGUAGE}" ] && internal_fail "PROJECT_LANGUAGE is empty"
   [ -z "${PROJECT_UPCASE_IDENTIFIER}" ] && internal_fail "PROJECT_UPCASE_IDENTIFIER is empty"

   local project_upcase_language

   project_upcase_language="`tr a-z A-Z <<< "${PROJECT_LANGUAGE}" `"

   escaped_pn="` escaped_sed_pattern "${PROJECT_NAME}" `"
   escaped_pi="` escaped_sed_pattern "${PROJECT_IDENTIFIER}" `"
   escaped_pl="` escaped_sed_pattern "${PROJECT_LANGUAGE}" `"
   escaped_pui="` escaped_sed_pattern "${PROJECT_UPCASE_IDENTIFIER}" `"
   escaped_pul="` escaped_sed_pattern "${project_upcase_language}" `"
   escaped_chn="` escaped_sed_pattern "${C_HEADER_NAME}" `"
   escaped_umcli="` escaped_sed_pattern "${UPCASE_C_LIBRARY_IDENTIFIER}" `"

   local escaped_a
   local escaped_d
   local escaped_o
   local escaped_t
   local escaped_u
   local escaped_y

   local nowdate
   local nowtime

   nowdate="`date "+%d.%m.%Y"`"
   nowtime="`date "+%H:%M:%S"`"
   nowyear="`date "+%Y"`"

   escaped_a="` escaped_sed_pattern "${AUTHOR:-${USER}}" `"
   escaped_d="` escaped_sed_pattern "${nowdate}" `"
   escaped_o="` escaped_sed_pattern "${ORGANIZATION}" `"
   escaped_t="` escaped_sed_pattern "${nowtime}" `"
   escaped_u="` escaped_sed_pattern "${USER}" `"
   escaped_y="` escaped_sed_pattern "${nowyear}" `"

   rexekutor sed -e "s/<|PROJECT_NAME|>/${escaped_pn}/g" \
                 -e "s/<|PROJECT_IDENTIFIER|>/${escaped_pi}/g" \
                 -e "s/<|PROJECT_LANGUAGE|>/${escaped_pl}/g" \
                 -e "s/<|PROJECT_UPCASE_IDENTIFIER|>/${escaped_pui}/g" \
                 -e "s/<|PROJECT_UPCASE_LANGUAGE|>/${escaped_pul}/g" \
                 -e "s/<|AUTHOR|>/${escaped_a}/g" \
                 -e "s/<|DATE|>/${escaped_d}/g" \
                 -e "s/<|ORGANIZATION|>/${escaped_o}/g" \
                 -e "s/<|TIME|>/${escaped_t}/g" \
                 -e "s/<|USER|>/${escaped_u}/g" \
                 -e "s/<|YEAR|>/${escaped_y}/g" \
                 -e "s/<|C_HEADER_NAME|>/${escaped_chn}/g" \
                 -e "s/<|UPCASE_C_LIBRARY_IDENTIFIER|>/${escaped_umcli}/g"
}


copy_and_expand_template()
{
   log_entry "copy_and_expand_template" "$@"

   local dstfile="$1"
   local templatedir="$2"

   if [ -e "${dst}" -a "${FLAG_FORCE}" != "YES" ]
   then
      log_fluff "\"${dst}\" already exists, so skipping it"
      return
   fi

   local templatefile

   templatefile="` filepath_concat "${templatedir}" "${dstfile}" `"

   [ ! -f "${templatefile}" ] && internal_fail "\"${templatefile}\" is missing"

   local text

   text="`expand_template_variables < "${templatefile}" `"

   mkdir_if_missing "`dirname -- "${dstfile}" `"
   redirect_exekutor "${dstfile}" echo "${text}"
}


default_template_setup()
{
   log_entry "default_template_setup" "$@"

   local templatedir="$1"

   if [ ! -d "${templatedir}" ]
   then
      log_fluff "\"${templatedir}\" does not exist."
      return 0
   fi

   IFS="
"
   for filename in `( cd "${templatedir}" ; find . -type f -print )`
   do
      IFS="${DEFAULT_IFS}"
      copy_and_expand_template "${filename}" "${templatedir}"
   done
   IFS="${DEFAULT_IFS}"
}


#
# calls either template_setup eventually, if that is defined
#
_template_main()
{
   log_entry "_template_main" "$@"

   local OPTION_EMBEDDED="NO"

   case "$1" in
      --embedded)
         OPTION_EMBEDDED="YES"
         shift
      ;;
   esac

   local FLAG_FORCE="NO"

   TEMPLATE_DIR="`dirname -- "$0"`/project"
   TEMPLATE_DIR="`absolutepath "${TEMPLATE_DIR}" `"

   while [ $# -ne 0 ]
   do

      if [ "${OPTION_EMBEDDED}" = "NO" ]
      then
         if options_technical_flags "$1"
         then
            shift
            continue
         fi
      fi

      case "$1" in
         -h|--help)
            template_usage
         ;;

         -d|--directory)
            shift
            [ $# -eq 0 ] && template_usage

            mkdir_if_missing "$1" || return 1
            rexekutor cd "$1"
         ;;

         -p|--project-name)
            shift
            [ $# -eq 0 ] && template_usage

            PROJECT_NAME="$1"
         ;;

         -f|--force)
            FLAG_FORCE="YES"
         ;;

         -l|--language)
            shift
            [ $# -eq 0 ] && template_usage

            PROJECT_LANGUAGE="$1"
         ;;

         --template-dir)
            shift
            [ $# -eq 0 ] && template_usage

            TEMPLATE_DIR="$1"
         ;;

         --version)
            echo "${VERSION}"
            exit 0
         ;;

         -*)
            log_error "unknown options \"$1\""
            template_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" ]
   then
      FLAG_FORCE="YES"
   fi

   if [ "${OPTION_EMBEDDED}" = "NO" ]
   then
      options_setup_trace "${MULLE_TRACE}"
   fi

   [ $# -ne 0 ] && template_usage

   #
   # if we are called from an external script, template_setup
   # may have been defined. We use this then instead
   #
   local template_callback

   template_callback="default_template_setup"
   if [ "`type -t "template_setup"`" = "function" ]
   then
      template_callback="template_setup"
   fi


   local dir_name

   dir_name="`basename -- "${PWD}"`"

   PROJECT_LANGUAGE="${PROJECT_LANGUAGE:-c}"
   PROJECT_NAME="${PROJECT_NAME:-${dir_name}}"
   PROJECT_IDENTIFIER="`echo "${PROJECT_NAME}" | tr '-' '_' | tr '[A-Z]' '[a-z]'`"
   PROJECT_UPCASE_IDENTIFIER="`echo "${PROJECT_IDENTIFIER}" | tr '[a-z]' '[A-Z]'`"
   UPCASE_MULLE_C_LIBRARY_IDENTIFIER="`echo "${UPCASE_MULLE_C_LIBRARY_NAME}" | tr '-' '_'`"

   case "${cmd}" in
      version)
         echo "${VERSION}"
         exit 0
      ;;

      *)
         "${template_callback}" "${TEMPLATE_DIR}" \
                                "${PROJECT_NAME}" \
                                "${PROJECT_IDENTIFIER}" \
                                "${PROJECT_UPCASE_IDENTIFIER}" \
                                "${UPCASE_MULLE_C_LIBRARY_IDENTIFIER}"
      ;;
   esac
}


template_main()
{
   log_entry "template_main" "$@"

   # technical flags
   local MULLE_FLAG_DONT_DEFER="NO"
   local MULLE_FLAG_EXEKUTOR_DRY_RUN="NO"
   local MULLE_FLAG_FOLLOW_SYMLINKS="YES"
   local MULLE_FLAG_LOG_CACHE="NO"
   local MULLE_FLAG_LOG_DEBUG="NO"
   local MULLE_FLAG_LOG_EXEKUTOR="NO"
   local MULLE_FLAG_LOG_FLUFF="NO"
   local MULLE_FLAG_LOG_MERGE="NO"
   local MULLE_FLAG_LOG_SCRIPTS="NO"
   local MULLE_FLAG_LOG_SETTINGS="NO"
   local MULLE_FLAG_LOG_VERBOSE="NO"
   local MULLE_TRACE_PATHS_FLIP_X="NO"
   local MULLE_TRACE_POSTPONE="NO"
   local MULLE_TRACE_RESOLVER_FLIP_X="NO"
   local MULLE_TRACE_SETTINGS_FLIP_X="NO"

   _template_main "$@"
}