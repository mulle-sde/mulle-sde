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
   [ "$#" -ne 0 ] && log_error "$1"

   #
   # can't remember what that was good for...
   #
   if [ -z "${TEMPLATE_USAGE_TEXT}" ]
   then
      TEMPLATE_USAGE_TEXT="`LC_ALL=C sed -e '/^#/d' -e '/^/   /' "${TEMPLATE_DIR}/../../usage" 2> /dev/null `"
   fi

   cat <<EOF >&2
Template Usage:
${TEMPLATE_USAGE_TEXT:-   Copy template files into the project.}

Options:
   -d <dir>   : use "dir" instead of working directory
   -n <name>  : give project a name
   -l <lang>  : specify project's main language
   -t <dir>   : template directory to copy and expand from
   -s <seds>  : sed expressions to use for template substitution
EOF
   exit 1
}


emit_projectname_seds()
{
#   log_entry "emit_projectname_seds" "$@"

   local o="$1"
   local c="$2"

   local escaped_pn
   local escaped_pi
   local escaped_pui
   local escaped_pdi

   # verify minimal set
   [ -z "${PROJECT_NAME}" ] && internal_fail "PROJECT_NAME is empty"
   [ -z "${PROJECT_IDENTIFIER}" ] && internal_fail "PROJECT_IDENTIFIER is empty"

   escaped_pn="` escaped_sed_pattern "${PROJECT_NAME}" `"
   escaped_pi="` escaped_sed_pattern "${PROJECT_IDENTIFIER}" `"
   escaped_pui="` escaped_sed_pattern "${PROJECT_UPCASE_IDENTIFIER}" `"
   escaped_pdi="` escaped_sed_pattern "${PROJECT_DOWNCASE_IDENTIFIER}" `"

   local cmdline

   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_NAME${c}/${escaped_pn}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_IDENTIFIER${c}/${escaped_pi}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_DOWNCASE_IDENTIFIER${c}/${escaped_pdi}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_UPCASE_IDENTIFIER${c}/${escaped_pui}/g'"`"

   echo "${cmdline}"
}


emit_projectlanguage_seds()
{
#   log_entry "emit_projectlanguage_seds" "$@"

   local o="$1"
   local c="$2"

   local escaped_pl
   local escaped_pdl
   local escaped_pul

   [ -z "${PROJECT_LANGUAGE}" ] && internal_fail "PROJECT_LANGUAGE is empty"

   local project_upcase_language
   local project_downcase_language

   project_downcase_language="`tr A-Z a-z <<< "${PROJECT_LANGUAGE}" `"
   project_upcase_language="`tr a-z A-Z <<< "${PROJECT_LANGUAGE}" `"

   escaped_pl="` escaped_sed_pattern "${PROJECT_LANGUAGE}" `"
   escaped_pul="` escaped_sed_pattern "${project_upcase_language}" `"
   escaped_pdl="` escaped_sed_pattern "${project_downcase_language}" `"

   local cmdline

   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_LANGUAGE${c}/${escaped_pl}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_UPCASE_LANGUAGE${c}/${escaped_pul}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_DOWNCASE_LANGUAGE${c}/${escaped_pdl}/g'"`"

   echo "${cmdline}"
}


emit_projectdialect_seds()
{
#   log_entry "emit_projectdialect_seds" "$@"

   local o="$1"
   local c="$2"

   [ -z "${PROJECT_DIALECT}" ] && internal_fail "PROJECT_DIALECT is empty"

   local project_upcase_dialect
   local project_downcase_dialect

   project_downcase_dialect="`tr A-Z a-z <<< "${PROJECT_DIALECT}" `"
   project_upcase_dialect="`tr a-z A-Z <<< "${PROJECT_DIALECT}" `"

   local escaped_pl
   local escaped_pdl
   local escaped_pul

   escaped_pl="` escaped_sed_pattern "${PROJECT_DIALECT}" `"
   escaped_pul="` escaped_sed_pattern "${project_upcase_dialect}" `"
   escaped_pdl="` escaped_sed_pattern "${project_downcase_dialect}" `"

   local cmdline

   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_DIALECT${c}/${escaped_pl}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_UPCASE_DIALECT${c}/${escaped_pul}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_DOWNCASE_DIALECT${c}/${escaped_pdl}/g'"`"

   #
   # support only first of PROJECT_EXTENSIONS as "primary"
   #
   local extensions
   local escaped_de

   extensions="${PROJECT_EXTENSIONS:-${project_downcase_dialect}}"
   escaped_de="` escaped_sed_pattern "${extensions%%:*}" `"

   cmdline="`concat "${cmdline}" "-e 's/${o}PROJECT_EXTENSION${c}/${escaped_de}/g'"`"

   echo "${cmdline}"
}


emit_author_date_seds()
{
#   log_entry "emit_author_date_seds" "$@"

   local o="$1"
   local c="$2"

   local nowdate
   local nowtime
   local nowyear

   nowdate="`date "+%d.%m.%Y"`"
   nowtime="`date "+%H:%M:%S"`"
   nowyear="`date "+%Y"`"

   local escaped_a
   local escaped_d
   local escaped_o
   local escaped_t
   local escaped_u
   local escaped_y

   escaped_a="` escaped_sed_pattern "${AUTHOR:-${USER}}" `"
   escaped_d="` escaped_sed_pattern "${nowdate}" `"
   escaped_o="` escaped_sed_pattern "${ORGANIZATION}" `"
   escaped_t="` escaped_sed_pattern "${nowtime}" `"
   escaped_u="` escaped_sed_pattern "${USER}" `"
   escaped_y="` escaped_sed_pattern "${nowyear}" `"

   local cmdline

   cmdline="`concat "${cmdline}" "-e 's/${o}AUTHOR${c}/${escaped_a}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}DATE${c}/${escaped_d}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}ORGANIZATION${c}/${escaped_o}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}TIME${c}/${escaped_t}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}USER${c}/${escaped_u}/g'"`"
   cmdline="`concat "${cmdline}" "-e 's/${o}YEAR${c}/${escaped_y}/g'"`"

   echo "${cmdline}"
}


template_filename_replacement_command()
{
  log_entry "template_filename_replacement_command" "$@"

   local cmdline

   cmdline="sed"

   local seds

   seds="`emit_projectname_seds`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   seds="`emit_projectlanguage_seds`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   seds="`emit_projectdialect_seds`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   #
   # get VENDOR_NAME for file replacement
   # or by the user
   #
   seds="`MULLE_VIRTUAL_ROOT="${PWD}" \
             rexekutor "${MULLE_ENV}" -s \
                           ${MULLE_ENV_FLAGS} environment \
                                 get --output-sed VENDOR_NAME`" || exit 1
   seds="`tr '\n' ' ' <<< "${seds}"`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   log_debug "${cmdline}"

   echo "${cmdline}"
}


template_contents_replacement_command()
{
   log_entry "template_contents_replacement_command" "$@"

   local cmdline

   cmdline="sed"

   local seds

   seds="`emit_projectname_seds "<|" "|>"`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   seds="`emit_projectlanguage_seds "<|" "|>"`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   seds="`emit_projectdialect_seds "<|" "|>"`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   seds="`emit_author_date_seds "<|" "|>"`"
   cmdline="`concat "${cmdline}" "${seds}"`"

   #
   # get current environment (as maybe already set by an extensions)
   # or by the user
   #
   seds="`MULLE_VIRTUAL_ROOT="${PWD}" \
             rexekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS}  \
                  environment list --output-sed  \
                                   --sed-key-prefix '<|' \
                                   --sed-key-suffix '|>'`" || exit 1

   log_debug "seds from environment: ${seds}"
   seds="`tr '\n' ' ' <<< "${seds}"`"

   cmdline="`concat "${cmdline}" "${seds}"`"

   log_debug "${cmdline}"

   echo "${cmdline}"
}


copy_and_expand_template()
{
   log_entry "copy_and_expand_template" "$@"

   local templatedir="$1"
   local dstfile="$2"
   local filename_sed="$3"
   local template_sed="$4"

   if [ -e "${dst}" -a "${FLAG_FORCE}" != "YES" ]
   then
      log_fluff "\"${dst}\" already exists, so skipping it"
      return
   fi

   local templatefile

   templatefile="`filepath_concat "${templatedir}" "${dstfile}" `"

   [ ! -f "${templatefile}" ] && internal_fail "\"${templatefile}\" is missing"

   local text

   log_debug "Generating text from template \"${templatefile}\""
   text="`LC_ALL=C eval_exekutor "${template_sed}" < "${templatefile}" `"

   local expanded_dstfile

   expanded_dstfile="`LC_ALL=C eval_exekutor "${filename_sed}" <<< "${dstfile}" `"

   if [ "${expanded_dstfile}" != "${dstfile}" ]
   then
      log_fluff "Expanded \"${dstfile}\" to \"${expanded_dstfile}\""
   fi

   mkdir_if_missing "`fast_dirname "${expanded_dstfile}" `"
   if [ -f "${expanded_dstfile}" ]
   then
      exekutor chmod ug+w "${expanded_dstfile}"
   fi

   log_debug "Writing expanded file \"${expanded_dstfile}\""

   redirect_exekutor "${expanded_dstfile}" echo "${text}"

   local permissions

   permissions="`lso "${templatefile}"`"
   chmod "${permissions}" "${expanded_dstfile}"
}


default_template_setup()
{
   log_entry "default_template_setup" "$@"

   local templatedir="$1"
   local onlyfile="$5"

   if [ ! -d "${templatedir}" ]
   then
      log_fluff "\"${templatedir}\" does not exist."
      return 0
   fi

   local template_sed
   local filename_sed

   local filename

   # too funny, IFS="" is wrong IFS="\n" is also wrong. Only hardcoded LF works

   IFS="
"
   for filename in `( cd "${templatedir}" ; find . -type f -print )`
   do
      IFS="${DEFAULT_IFS}"

      # suppress OS X uglies
      case "${filename}" in
         .*/*.DS_Store)
            continue
         ;;
      esac

      if [ -z "${onlyfile}" -o "${filename}" = "./${onlyfile}" ]
      then
         if [ -z "${filename_sed}" ]
         then
            filename_sed="`template_filename_replacement_command`"
            template_sed="`template_contents_replacement_command`"
         fi

         copy_and_expand_template "${templatedir}" \
                                  "${filename}" \
                                  "${filename_sed}" \
                                  "${template_sed}"
      else
         log_debug "Ignoring \"${filename}\"..."
      fi
      IFS="
"
   done
   IFS="${DEFAULT_IFS}"
}


#
# could call template_setup eventually, if that is defined
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
   local TEMPLATE_DIR
   local PROJECT_NAME
   local PROJECT_LANGUAGE
   local PROJECT_DIALECT
   local PROJECT_EXTENSIONS
   local PROJECT_UPCASE_IDENTIFIER
   local PROJECT_DOWNCASE_IDENTIFIER
   local OPTION_FILE

   local template_callback

   template_callback="default_template_setup"

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
         -h*|--help|help)
            template_usage
         ;;

         -d|--directory)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift

            mkdir_if_missing "$1" || return 1
            exekutor cd "$1"
         ;;

         -n|--name|--project-name)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift

            PROJECT_NAME="$1"
         ;;

         -f|--force)
            FLAG_FORCE="YES"
         ;;

         --file)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift

            OPTION_FILE="$1"
         ;;

         --dialect|--project-dialect)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift

            PROJECT_DIALECT="$1"
         ;;

         -l|--language|--project-language)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift

            PROJECT_LANGUAGE="$1"
         ;;

         --extensions|--project-extensions)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift

            PROJECT_EXTENSIONS="$1"
         ;;

         --callback)
            [ $# -eq 1 ] && template_usage "missing argument to \"$1\""
            shift
            template_callback="$1"
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
      FLAG_FORCE="YES" # ignore existing dst, since we are doing nothing
   fi

   if [ "${OPTION_EMBEDDED}" = "NO" ]
   then
      options_setup_trace "${MULLE_TRACE}"
   fi

   [ $# -ne 0 ] && log_error "superflous parameter \"$*\"" && template_usage

   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   set_projectname_environment "none"

   PROJECT_LANGUAGE="${PROJECT_LANGUAGE:-none}"
   PROJECT_DIALECT="${PROJECT_DIALECT:-${PROJECT_LANGUAGE}}"
   if [ -z "${PROJECT_EXTENSIONS}" ]
   then
      PROJECT_EXTENSIONS="`tr A-Z a-z <<< "${PROJECT_EXTENSIONS}"`"
   fi

   log_debug "PROJECT_NAME=${PROJECT_NAME}"
   log_debug "PROJECT_DIALECT=${PROJECT_DIALECT}"
   log_debug "PROJECT_LANGUAGE=${PROJECT_LANGUAGE}"
   log_debug "PROJECT_EXTENSIONS=${PROJECT_EXTENSIONS}"

   if [ -z "${TEMPLATE_DIR}" ]
   then
      TEMPLATE_DIR="`dirname -- "$0"`/project"
      TEMPLATE_DIR="`absolutepath "${TEMPLATE_DIR}" `"
   fi

   case "${cmd}" in
      version)
         echo "${VERSION}"
         exit 0
      ;;

      *)
         "${template_callback}" "${TEMPLATE_DIR}" \
                                "${PROJECT_NAME}" \
                                "${PROJECT_LANGUAGE}" \
                                "${PROJECT_EXTENSIONS}" \
                                "${OPTION_FILE}"
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


sde_template_main()
{
   #
   # hackish,  undocumented just for development
   #
   template_main --template-dir /tmp --callback expand_template_variables "$@"
}