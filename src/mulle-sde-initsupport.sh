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
MULLE_SDE_INITSUPPORT_SH="included"

#
# INIT
#

init_usage()
{
   if [ -z "${INIT_USAGE_TEXT}" ]
   then
      INIT_USAGE_TEXT="`cat "${SHARE_DIR}/../usage" 2> /dev/null `"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} [flags] <command> [options] [directory]

   ${INIT_USAGE_TEXT:-Initialize the project.}

Commands:
   executable : create an executable project
   library    : create a library project
   version    : print ${MULLE_EXECUTABLE_NAME} version

Options:
   -d <dir>   : use "dir" instead of working directory
   -p <name>  : give project a name
   -l <lang>  : specify project's main language (C)
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
   local escaped_chn
   local escaped_umcli

   escaped_pn="` escaped_sed_pattern "${PROJECT_NAME}" `"
   escaped_pi="` escaped_sed_pattern "${PROJECT_IDENTIFIER}" `"
   escaped_pi="` escaped_sed_pattern "${PROJECT_LANGUAGE}" `"
   escaped_pui="` escaped_sed_pattern "${PROJECT_UPCASE_IDENTIFIER}" `"
   escaped_chn="` escaped_sed_pattern "${C_HEADER_NAME}" `"
   escaped_umcli="` escaped_sed_pattern "${UPCASE_C_LIBRARY_IDENTIFIER}" `"

   rexekutor sed -e "s/<|PROJECT_NAME|>/${escaped_pn}/g" \
                 -e "s/<|PROJECT_IDENTIFIER|>/${escaped_pi}/g" \
                 -e "s/<|PROJECT_LANGUAGE|>/${escaped_pl}/g" \
                 -e "s/<|PROJECT_UPCASE_IDENTIFIER|>/${escaped_pui}/g" \
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


__common_env()
{
   log_entry "__common_env" "$@"

   local dir_name

   dir_name="`basename -- "${PWD}"`"

   PROJECT_LANGUAGE="${OPTION_LANGUAGE}"
   PROJECT_NAME="${PROJECT_NAME:-${dir_name}}"
   PROJECT_IDENTIFIER="`echo "${PROJECT_NAME}" | tr '-' '_' | tr '[A-Z]' '[a-z]'`"
   PROJECT_UPCASE_IDENTIFIER="`echo "${PROJECT_IDENTIFIER}" | tr '[a-z]' '[A-Z]'`"
   UPCASE_MULLE_C_LIBRARY_IDENTIFIER="`echo "${UPCASE_MULLE_C_LIBRARY_NAME}" | tr '-' '_'`"
}


default_init_setup()
{
   log_entry "default_init_setup" "$@"

   local sharedir="$1"
   local projecttype="$2"

   __common_env

   local templatedir

   templatedir="` filepath_concat "${sharedir}" "${projecttype}" `"
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


# calls either init_setup eventually, if that is defined

_init_main()
{
   log_entry "_init_main" "$@"

   local OPTION_EMBEDDED="NO"

   case "$1" in
      --embedded)
         OPTION_EMBEDDED="YES"
         shift
      ;;
   esac

   local FLAG_FORCE="NO"
   local FLAG_OUTPUT_DEMO_FILES="YES"
   local OPTION_DYNAMIC_LINKED="NO"
   local OPTION_LANGUAGE="C"

   SHARE_DIR="`dirname -- "$0"`/project"
   SHARE_DIR="`absolutepath "${SHARE_DIR}" `"

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
            usage
         ;;

         -d|--directory)
            shift
            [ $# -eq 0 ] && usage

            mkdir_if_missing "$1" || return 1
            rexekutor cd "$1"
         ;;

         -p|--project-name)
            shift
            [ $# -eq 0 ] && usage

            PROJECT_NAME="$1"
         ;;

         -f|--force)
            FLAG_FORCE="YES"
         ;;

         -l|--language)
            shift
            [ $# -eq 0 ] && usage

            OPTION_LANGUAGE="$1"
         ;;

         --share-dir)
            shift
            [ $# -eq 0 ] && usage

            SHARE_DIR="$1"
         ;;

         --version)
            echo "${VERSION}"
            exit 0
         ;;

         -*)
            log_error "unknown options \"$1\""
            usage
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

   [ $# -ne 1 ] && usage

   local cmd="$1"

   #
   # if we are called from an external script, init_setup
   # may have been defined. We use this then instead
   #
   local init_callback

   init_callback="default_init_setup"
   if [ "`type -t "init_setup"`" = "function" ]
   then
      init_callback="init_setup"
   fi

   case "${cmd}" in
      library)
         ${init_callback} "${SHARE_DIR}" "library"
      ;;

      executable)
         ${init_callback}  "${SHARE_DIR}" "library"
      ;;

      version)
         echo "${VERSION}"
         exit 0
      ;;

      *)
         log_error "unknown command \"${cmd}\""
         usage
      ;;
   esac
}


init_main()
{
   log_entry "init_main" "$@"

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

   _init_main "$@"
}