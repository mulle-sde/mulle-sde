# shellcheck shell=bash
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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_INIT_SH='included'


sde::init::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   INIT_USAGE_NAME="${INIT_USAGE_NAME:-${MULLE_USAGE_NAME} init}"

   COMMON_OPTIONS="\
   --existing             : skip demo file installation.
   --style <tool/env>     : specify environment style, see mulle-env init -h
   -d <dir>               : directory to populate (working directory)
   -D <key>=<val>         : specify an environment variable
   -e <extra>             : specify extra extensions. Multiple uses are possible
   -m <meta>              : specify meta extensions
   -n <name>              : project name"

   HIDDEN_OPTIONS="\
   --addiction-dir <dir>  : specify addiction directory (addiction)
   --allow-<name>         : reenable specific initializations (see source)
   --dependency-dir <dir> : specify dependency directory (dependency)
   --kitchen-dir <dir>    : specify kitchen directory (kitchen)
   --no-<name>            : turn off specific initializations (see source)
   --no-comment-files     : don't write template info into generated files
   --no-sourcetree        : do not add sourcetree to project
   --source-dir <dir>     : specify source directory location (src)
   --stash-dir <dir>      : specify stash directory (stash)
   -b <buildtool>         : specify the buildtool extension to use
   -o <oneshot>           : specify oneshot extensions. Multiples possible
   -r <runtime>           : specify runtime extension to use
   -v <vendor>            : extension vendor to use (mulle-sde)"

   cat <<EOF >&2
Usage:
   ${INIT_USAGE_NAME} [options] [type]

   Initializes a mulle-sde project in the current directory. This will create a
   ".mulle" folder if no 'type' is given and nothing else. Or choose a
   directory to create and install into with the '-d' option.

   If you choose a 'type' like "library" or "executable", you would typically
   also specifiy a meta-extension with the -m option to set the desired project
   language and build system.

   Extensions are plugins that contain scripts and files to setup the project.
   A meta-extension combines multiple extensions.

   Example:
      mulle-sde init -d ./my-project -m mulle-sde/c-developer executable

   Use \`mulle-sde extension add\` to add extra and oneshot extensions at a
   later date.

Options:
EOF
   (
      printf "%s\n" "${COMMON_OPTIONS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
      then
         printf "%s\n" "${HIDDEN_OPTIONS}"
      fi
   ) | LC_ALL=C sort
   echo "      (\`${MULLE_USAGE_NAME} -v init help\` for more options)" >&2

   cat <<EOF >&2
Environment:
   MULLE_SDE_EXTENSION_PATH      : Overrides searchpath for extensions
   MULLE_SDE_EXTENSION_BASE_PATH : Augments searchpath for extensions

EOF

   sde::extension::show_main meta >&2

   exit 1
}


sde::init::_copy_extension_dir()
{
   log_entry "sde::init::_copy_extension_dir" "$@"

   local directory="$1"
   local overwrite="${2:-YES}"
   # local writeprotect="${3:-NO}"

   if [ ! -d "${directory}" ]
   then
      log_debug "Nothing to copy as \"${directory}\" is not there"
      return
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' -o "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES'  ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten.
   #
   if [ "${overwrite}" = 'NO' ]
   then
      flags="${flags} -n"  # don't clobber
   fi

   local name

   r_basename "${directory}"
   name="${RVAL}"

   local destination

   case "${name}" in
      share)
         destination=".mulle"
      ;;

      *)
         fail "Unsupported destination directory \"${name}\""
      ;;
   esac

   _log_verbose "Installing files from \"${directory#"${MULLE_USER_PWD}/"}\" \
into \"${destination#"${MULLE_USER_PWD}/"}\" ($PWD)"

   # need L flag since homebrew creates relative links
   exekutor cp -RLp ${flags} "${directory}" "${destination}/"
}


sde::init::_check_file()
{
   log_entry "sde::init::_check_file" "$@"

   local filename="$1"

   if [ ! -f "${filename}" ]
   then
      log_debug "\"${filename}\" does not exist"
      return 1
   fi
   log_fluff "File \"${filename}\" FOUND"
   return 0
}


sde::init::_check_dir()
{
   log_entry "sde::init::_check_dir" "$@"

   local dirname="$1"

   if [ ! -d "${dirname}" ]
   then
      log_debug "\"${dirname}\" does not exist ($PWD)"
      return 1
   fi

   if [ -e "${dirname}/.empty" ]
   then
      log_debug "\"${dirname}\" has .empty file ($PWD)"
      return 1
   fi

   log_fluff "Directory \"${dirname}\" FOUND"
   return 0
}


sde::init::_copy_env_extension_dir()
{
   log_entry "sde::init::_copy_env_extension_dir" "$@"

   local directory="$1"

   sde::init::_check_dir "${directory}/share" || return 0

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten.
   #

   log_fluff "Installing env files from \"${directory}\""

   # need L flag since homebrew creates relative links
   exekutor cp -RLa ${flags} "${directory}/share" ".mulle/share/env/"
}


sde::init::_append_to_motd()
{
   log_entry "sde::init::_append_to_motd" "$@"

   local extensiondir="$1"

   sde::init::_check_file "${extensiondir}/motd" || return 0

   local text

   text="`LC_ALL=C grep -E -v '^#' "${extensiondir}/motd" `"
   if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
   then
      log_fluff "Append \"${extensiondir}/motd\" to motd"
      r_add_line "${_MOTD}" "${text}"
      _MOTD="${RVAL}"
   fi
}


sde::init::install_inheritfile()
{
   log_entry "sde::init::install_inheritfile" "$@"

   local inheritfilename="$1"
   local projecttype="$2"
   local defaultexttype="$3"
   local marks="$4"
   local onlyfilename="$5"
   local force="$6"

   shift 6

   local text

   text="`LC_ALL=C grep -E -v '^#' "${inheritfilename}"`"

   #
   # read needs IFS set for each iteration, whereas
   # for only for the first iteration.
   # shell programming...
   #
   local line
   local depmarks
   local extension
   local exttype
   local extname
   local vendor

   while IFS=$'\n' read -r line
   do
      log_debug "Inheriting: \"${line}\""

      case "${line}" in
         "")
            continue
         ;;

         *\;*)
            IFS=";" read -r extension exttype depmarks <<< "${line}"

            r_comma_concat "${marks}" "${depmarks}"
            depmarks="${RVAL}"
         ;;

         *)
            extension="${line}"
            depmarks="${marks}"
            exttype=
         ;;
      esac

      case "${extension}" in
         */*)
            vendor="${extension%%/*}"
            extname="${extension##*/}"
         ;;

         *)
            _internal_fail "\"${inheritfilename}\": missing vendor for \"${extension}\" (need vendor/extension)"
         ;;
      esac

      [ -z "${vendor}" ] &&  _internal_fail "\"${inheritfilename}\": missing vendor for \"${extension}\""
      [ -z "${extname}" ] &&  _internal_fail "\"${inheritfilename}\": missing extenson name for \"${extension}\""

      exttype="${exttype:-${defaultexttype}}"
      if [ "${exttype}" = "meta" ]
      then
         :
         # in this case we locate the
         # fail "A meta extension mistakenly tries to inherit another meta \
#extension (\"${inheritfilename}\")"
      fi

      #
      # extra types can be inherited from anybody
      #
      case "${defaultexttype}" in
         meta)
         ;;

         *)
            if [ "${exttype}" != "${defaultexttype}" -a "${exttype}" != "extra" ]
            then
               fail "A \"${defaultexttype}\" extension \"${vendor}/${extname}\" tries to inherit \
\"${inheritfilename}\" - a \"${exttype}\" extension"
            fi
         ;;
      esac

      # why are we using _install here ?
      sde::init::_install_extension "${projecttype}" \
                                    "${exttype}" \
                                    "${vendor}" \
                                    "${extname}" \
                                    "${marks}" \
                                    "${onlyfilename}" \
                                    "${force}" \
                                    "$@"
   done <<< "${text}"
}


sde::init::environment_mset_log()
{
   log_entry "sde::init::environment_mset_log" "$@"

   local environment="$1"

   local line
   local key
   local value

   while IFS=$'\n' read -r line
   do
      log_debug "line: ${line}"

      key="${line%%=*}"
      value="${line#${key}=}"
      value="${value%##*}"

      case "${value}" in
         *\')
            log_verbose "Environment: ${key:1}=${value%?}"
         ;;

         *)
            log_verbose "Environment: ${key:1}=${value}"
         ;;
      esac
   done <<< "${environment}"
   IFS="${DEFAULT_IFS}"
}


sde::init::environment_text_to_mset()
{
   log_entry "sde::init::environment_text_to_mset" "$@"

   local text="$1"

   local output

   # add lf for read
   text="${text}
"

   local line
   local comment
   local sep

   while IFS=$'\n' read -r line
   do
      line="${line//$'\r'/}"

      log_debug "line: ${line}"
      case "${line}" in
         *\#\#*)
            fail "environment line \"${line}\": comment must not contain ##"
         ;;

         *\\n*)
            fail "environment line \"${line}\": comment must not contain \\n (two characters)"
         ;;

         \#\ *)
            r_concat "${comment}" "${line:2}" "\\n"
            comment="${RVAL}"
            continue
         ;;

         \#*)
            r_concat "${comment}" "${line:1}" "\\n"
            comment="${RVAL}"
            continue
         ;;

         "")
            continue
         ;;

         *=\"*\"|*+=\"*\")
         ;;

         *)
            fail "environment line \"${line}\": must be of form <key>=\"<value>\""
         ;;
      esac

      #
      # use "${x%##*}" to retrieve line
      # use "${x##*##}" to retrieve comment
      #
      if [ -z "${comment}" ]
      then
         output="${output}${sep}'${line}'"
      else
         r_escaped_singlequotes "${comment}"
         output="${output}${sep}'${line}##${RVAL}'"
         comment=
      fi
      sep=$'\n'
   done <<< "${text}"

   RVAL="${output}"
}


sde::init::r_githubname()
{
   log_entry "sde::init::r_githubname" "$@"

   if [ ! -z "${GITHUB_USER}" ]
   then
      RVAL="${GITHUB_USER}"
      return
   fi

   #
   # assume structure is mulle-c/mulle-allocator and we are
   # right in mulle-allocator, use mulle-c as github name,
   # unless its prefixed with "src"
   #
   local directory

   # clumsy fix if called from test directory
   directory="${PWD}"
   r_basename "${directory}"
   case "${RVAL}" in
      test*)
         r_dirname "${directory}"
         directory="${RVAL}"
      ;;
   esac

   local name
   r_dirname "${directory}"
   r_basename "${RVAL}"
   name="${RVAL}"

   # github don't like underscores, so we adapt here
   name="${name//_/-}"

   local filtered

   # is it a github identifier (engl.) ?
   r_identifier "${name}"
   filtered="${RVAL}"

   if [ "${filtered}" = "${name}" ]
   then
      case "${name}" in
         ""|tmp*|temp*|src*|-*|*-)
         ;;

         *)
            RVAL="${name}"
            return
         ;;
      esac
   fi

   RVAL="${MULLE_USERNAME}"
}



#
# expensive
#
sde::init::read_template_expanded_file()
{
   log_entry "sde::init::read_template_expanded_file" "$@"

   local filename="$1"

   include "template::generate"

   [ -z "${GITHUB_USER}" ] && _internal_fail "GITHUB_USER undefined"

   #
   # CLUMSY HACKS:
   # for the benefit of test we have to define some stuff now
   #
   local PREFERRED_STARTUP_LIBRARY="${PREFERRED_STARTUP_LIBRARY:-Foundation-startup}"
   local PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER

   r_uppercase "${PREFERRED_STARTUP_LIBRARY}"
   PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER="${RVAL//-/_}"

   local scriptfile

   scriptfile="`PREFERRED_STARTUP_LIBRARY="${PREFERRED_STARTUP_LIBRARY}" \
      PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER="${PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER}" \
      GITHUB_USER="${GITHUB_USER}" \
      PROJECT_NAME="${PROJECT_NAME}" \
      PROJECT_IDENTIFIER="${PROJECT_IDENTIFIER}" \
      PROJECT_UPCASE_IDENTIFIER="${PROJECT_UPCASE_IDENTIFIER}" \
      PROJECT_DOWNCASE_IDENTIFIER="${PROJECT_DOWNCASE_IDENTIFIER}" \
      PROJECT_PREFIXLESS_NAME="${PROJECT_PREFIXLESS_NAME}" \
      PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER="${PROJECT_PREFIXLESS_DOWNCASE_IDENTIFIER}" \
      PROJECT_LANGUAGE="${PROJECT_LANGUAGE:-c}" \
      PROJECT_DIALECT="${PROJECT_DIALECT:-objc}" \
         template::generate::main csed-script `" || exit 1

   eval_rexekutor sed -f "${scriptfile}" "${filename}" | grep -E -v '^#'

   remove_file_if_present "${scriptfile}"
}


sde::init::add_to_sourcetree()
{
   log_entry "sde::init::add_to_sourcetree" "$@"

   local filename="$1"
   local projecttype="$2"


   local configname

#   r_basename "${filename}" # wrong
   configname="config"

   #
   # specialty for sourcetree, could expand this in general to
   # other files
   #
   if [ -e "${filename}-${projecttype}" ]
   then
      filename="${filename}-${projecttype}"
   fi


   local lines

   lines="`sde::init::read_template_expanded_file "${filename}" | grep -E -v '^#' `"
   if [ -z "${lines}" ]
   then
      log_warning "\"${filename}\" contains no dependency information"
      return
   fi

   local oldfile
   local previous_contents

   oldfile="${PWD}/.mulle.old/share/sourcetree/${configname}"
   if [ -e "${oldfile}" ]
   then
      log_fluff "Found previous share sourcetree \"${oldfile}\" file, trying to preserve UUIDs"
      previous_contents="`rexekutor mulle-sourcetree list --config-file "${oldfile}" \
                                                          -ll \
                                                          --output-no-header`"
   else
      log_debug "No previous sourcetree at \"${oldfile}\" ($PWD)"
      previous_contents=
   fi

#   log_debug "lines=${lines}"
#   log_debug
#   log_debug
#   log_debug "------------------------------------------------"
#   log_debug
#   log_debug

   MULLE_VIRTUAL_ROOT="" \
      exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     -N \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_SOURCETREE_FLAGS:-} \
                     --use-fallback \
                  eval-add \
                     --config-name "${configname}" \
                     -- \
                     "${lines}" || exit 1

   if [ -z "${previous_contents}" ]
   then
      return
   fi


   # we would like to preserve the UUIDs of the original if possible, so
   # we don't get uselessly changed files in the next commit

   local contents
   local newfile

   newfile="${PWD}/.mulle/share/sourcetree/${configname}"
   contents="`mulle-sourcetree list --config-file "${newfile}" \
                                    -ll \
                                    --output-no-header`"

   if [ "${contents}" = "${previous_contents}" ]
   then
      log_debug "Could preserve it"
      exekutor cp -p "${oldfile}" "${newfile}"
   fi
}


sde::init::add_to_environment()
{
   log_entry "sde::init::add_to_environment" "$@"

   local filename="$1"
   local projecttype="$2"
   local scope="$3"

   local environment
   local text

   if sde::init::_check_file "${filename}-${projecttype}"
   then
      filename="${filename}-${projecttype}"
   else
      sde::init::_check_file "${filename}" || return 0
   fi

   text="`cat "${filename}" `"

   log_debug "Environment: ${text}"

   # add an empty linefeed for read
   sde::init::environment_text_to_mset "${text}"
   environment="${RVAL}"

   if [ -z "${environment}" ]
   then
      return
   fi

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      sde::init::environment_mset_log "${environment}"
   fi

   # remove lf for command line
   environment="${environment//$'\n'/ }"
   (
      MULLE_VIRTUAL_ROOT="`pwd -P`" \
         eval_exekutor "'${MULLE_ENV:-mulle-env}'" \
                              --search-nearest \
                              -s \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              --no-protect \
                           environment \
                              --scope "${scope:-extension}" \
                              mset "${environment}"
   ) || exit 1
}


sde::init::_add_to_tools()
{
   log_entry "sde::init::_add_to_tools" "$@"

   local filename="$1"
   local os="$2"

   local line
   local quoted_args

   IFS=$'\n'
   for line in `grep -E -v '^#' "${filename}"`
   do
      r_concat "${quoted_args}" "'${line}'"
      quoted_args="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"

   [ -z "${quoted_args}" ] && return

   log_verbose "Tools: \"${quoted_args}\" ${os:+ (}${os}${os:+)}"

   (
      MULLE_VIRTUAL_ROOT="`pwd -P`" \
         eval_exekutor "'${MULLE_ENV:-mulle-env}'" \
                              --search-nearest \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              -s \
                              --no-protect \
                           tool \
                              --os "'${os:-DEFAULT}'" \
                              --extension \
                              add \
                                 --no-compile-link \
                                 --if-missing \
                                 --csv \
                                 ${quoted_args}
   )

   if [ $? -eq 1 ] # only 1 is error, 2 is ok
   then
      fail "Addition of tools \"${quoted_args}\" failed"
   fi
}


sde::init::add_to_tools()
{
   log_entry "sde::init::add_to_tools" "$@"

   local filename="$1"

   local os
   local file

   shell_enable_nullglob
   for file in "${filename}" "${filename}".*
   do
      shell_disable_nullglob
      if sde::init::_check_file "${file}"
      then
         r_path_extension "${file}"
         os="${RVAL}"
         sde::init::_add_to_tools "${file}" "${os}"
      fi
   done
   shell_disable_nullglob
}


sde::init::run_init()
{
   log_entry "sde::init::run_init" "$@"

   local executable="$1"
   local projecttype="$2"
   local vendor="$3"
   local extname="$4"
   local marks="$5"
   local force="$6"

   if [ ! -x "${executable}" ]
   then
      if sde::init::_check_file "${executable}"
      then
         fail "\"${executable}\" must have execute permissions"
      fi
      return
   fi

   local flags
   local escaped

   # i need this for testing sometimes
   case "${OPTION_INIT_FLAGS}" in
      *,${vendor}/${extname}=*|${vendor}/${extname}=*)
         r_escaped_sed_pattern "${vendor}/${extname}"
         escaped="${RVAL}"

         flags="`sed -n -e "s/.*${escaped}=\\([^,]*\\).*/\\1/p" <<< "${OPTION_INIT_FLAGS}"`"
      ;;
   esac

   local auxflags

   if [ "${force}" = 'YES' ]
   then
      auxflags="-f"
   fi

   #
   # TODO: small database with sha256 sums, that the user has "allowed"
   #       if not in database query Y/n like mulle-bootstrap used to
   #
   r_simplified_path "${executable}"
   log_debug "Adding init script \"${RVAL}\" to delayed init calls"

   local eval_cmdline

   eval_cmdline="\
OPTION_UPGRADE='${OPTION_UPGRADE}' \
OPTION_REINIT='${OPTION_REINIT}' \
OPTION_INIT_TYPE='${OPTION_INIT_TYPE}' \
GITHUB_USER='${GITHUB_USER}' \
PROJECT_DIALECT='${PROJECT_DIALECT}' \
PROJECT_EXTENSIONS='${PROJECT_EXTENSIONS}' \
PROJECT_LANGUAGE='${PROJECT_LANGUAGE}' \
PROJECT_NAME='${PROJECT_NAME}' \
PROJECT_TYPE='${PROJECT_TYPE}' \
ONESHOT_FILENAME='${ONESHOT_FILENAME}' \
ONESHOT_IDENTIFIER='${ONESHOT_IDENTIFIER}' \
MULLE_VIRTUAL_ROOT='$(pwd -P)' \
 '${executable}' \
       ${INIT_FLAGS} \
       ${MULLE_TECHNICAL_FLAGS} \
       ${flags} \
       ${auxflags} \
    --marks '${marks}' \
            '${projecttype}'"

   r_add_line "${_EXTENSION_INITS}" "${eval_cmdline}"
   _EXTENSION_INITS="${RVAL}"
}


sde::init::is_disabled_by_marks()
{
   log_entry "sde::init::is_disabled_by_marks" "$@"

   local marks="$1"
   local description="$2"

   shift 2

   [ -z "${description}" ] && _internal_fail "description must not be empty"

   # make sure all individual marks are enlosed by ','
   # now we can check against an , enclosed pattern
   while [ ! -z "$1" ]
   do
      case ",${marks}," in
         *,$1,*)
            log_fluff "${description} is disabled by \"${marks}\""
            return 0
         ;;
      esac

      # log_debug "\"${description}\" not disabled by \"$1\""
      shift
   done

   return 1
}


sde::init::is_directory_disabled_by_marks()
{
   log_entry "sde::init::is_directory_disabled_by_marks" "$@"

   local marks="$1"
   local directory="$2"
   shift 2

   if ! sde::init::_check_dir "${directory}"
   then
      log_fluff "Directory \"${directory}\" not present"
      return 0 # disabled
   fi

   sde::init::is_disabled_by_marks "${marks}" "${directory}" "$@"
}


sde::init::is_file_disabled_by_marks()
{
   log_entry "sde::init::is_file_disabled_by_marks" "$@"

   local marks="$1"
   local filename="$2"
   shift 2

   if ! sde::init::_check_file "${filename}"
   then
      log_fluff "File \"${filename}\" not present"
      return 0 # disabled
   fi

   sde::init::is_disabled_by_marks "${marks}" "${filename}" "$@"
}


sde::init::is_sourcetree_file_disabled_by_marks()
{
   log_entry "sde::init::is_sourcetree_file_disabled_by_marks" "$@"

   local marks="$1"
   local filename="$2"
   local projecttype="$3"
   shift 3

   if ! sde::init::_check_file "${filename}"
   then
      if ! sde::init::_check_file "${filename}-${projecttype}"
      then
         log_fluff "${filename} and ${filename}-${projecttype} not present"
         return 0 # disabled
      fi
   fi

   sde::init::is_disabled_by_marks "${marks}" "${filename}" "$@"
}


#
# sourcetree files can be different for libary projects
# and executable projects
#
sde::init::install_sourcetree_files()
{
   log_entry "sde::init::install_sourcetree_files" "$@"

   local extensiondir="$1"
   local vendor="$2"
   local extname="$3"
   local marks="$4"
   local projecttype="$5"

   if ! sde::init::is_sourcetree_file_disabled_by_marks "${marks}" \
                                                        "${extensiondir}/sourcetree" \
                                                        "${projecttype}" \
                                                        "no-sourcetree" \
                                                        "no-sourcetree-${vendor}-${extname}"
   then
      sde::init::add_to_sourcetree "${extensiondir}/sourcetree" "${projecttype}"
   fi
}


sde::init::assert_sane_extension_values()
{
   log_entry "sde::init::assert_sane_extension_values" "$@"

   local exttype="$1"
   local vendor="$2"
   local extname="$3"

   case "${extname}" in
      "")
         fail "empty extension name"
      ;;
      *[^a-z_0-9.-]*)
         fail "illegal extension name \"${extname}\" (lowercase only pls)"
      ;;
   esac
   case "${vendor}" in
      "")
         fail "empty vendor name"
      ;;
      *[^a-z_0-9.-]*)
         fail "illegal vendor name \"${vendor}\" (lowercase only pls)"
      ;;
   esac
   case "${exttype}" in
      "")
         fail "empty extension type"
      ;;
      *[^a-z_0-9.-]*)
         fail "illegal extension type \"${exttype}\" (lowercase only pls)"
      ;;
   esac
}


sde::init::install_version()
{
   log_entry "sde::init::install_version" "$@"

   local vendor="$1"
   local extname="$2"
   local extensiondir="$3"

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}/version/${vendor}"

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
         ;;

         *)
            flags=-v
         ;;
      esac
   fi

   exekutor cp ${flags} "${extensiondir}/version" \
                        "${MULLE_SDE_SHARE_DIR}/version/${vendor}/${extname}"
   return 0 # why ?
}


#
# In mulle-sde-init when we are using template files we are installing
# into `src` (as of now). If no src is defined we use PWD, basically just
# for testing though.
#
sde::init::_copy_extension_template_files()
{
   log_entry "sde::init::_copy_extension_template_files" "$@"

   local sourcedir="$1"
   local subdirectory="$2"
   local projecttype="$3"
   local extension="$4"
   local force="$5"
   local onlyfilename="$6"

   shift 6

   #
   # copy and expand stuff from project folder. Be extra careful not to
   # clobber project files, except if -f is given
   #
   log_fluff "Copying \"${sourcedir}\" with template expansion"

   local arguments
   local dstdir

   dstdir="${PWD}"

   arguments="write --embedded --without-template-dir --no-boring-environment"
   if [ ! -z "${onlyfilename}" ]
   then
      arguments="${arguments} --file '${onlyfilename}'"
   fi

   if [ "${force}" = 'YES' ]
   then
      arguments="${arguments} --overwrite"
   fi

   if [ "${OPTION_COMMENT_FILES}" = 'YES' ]
   then
      local comment

      comment="extension : ${extension}\\n\
directory : ${subdirectory}/${projecttype}\\n\
template  : .../<|TEMPLATE_FILE|>\\n\
Suppress this comment with \`export MULLE_SDE_GENERATE_FILE_COMMENTS=NO\`"

      arguments="${arguments} --comment '${comment}'"
   fi

   arguments="${arguments} '${sourcedir}' '${dstdir}'"

   #
   # Normally the base project files would be copied first. But then we can not
   # inherit properly as they are already there and we can not clobber
   # them. So we collect _TEMPLATE_DIRECTORIES in reverse order.
   #
   # If force is set, the last file file will win, in this case we use the
   # "natural" order
   #
   if [ "${force}" = 'YES' ]
   then
      _TEMPLATE_DIRECTORIES="${_TEMPLATE_DIRECTORIES}
${arguments}"
      return
   fi

   _TEMPLATE_DIRECTORIES="${arguments}
${_TEMPLATE_DIRECTORIES}"
}


sde::init::_copy_extension_template_directory()
{
   log_entry "sde::init::_copy_extension_template_directory" "$@"

   local extensiondir="$1"
   local subdirectory="$2"
   local projecttype="$3"
   local extension="$4"

   shift 4

   local second
   local seconddir
   local inherit

   if [ "${projecttype}" != 'all' ]
   then
      inherit='all'
   fi

   second="${projecttype:-none}"
   seconddir="${extensiondir}/${subdirectory}/${second}"
   if sde::init::_check_dir "${seconddir}"
   then
      local inheritfile

      inheritfile="${seconddir}/.inherit"
      if [ -f "${inheritfile}" ]
      then
         log_fluff "Inherit file \"${inheritfile}\" found"
         inherit="`rexekutor grep -E '^#' "${inheritfile}" `"
      fi
   else
      seconddir=
   fi

   local first

   .for first in ${inherit}
   .do
      log_fluff "Projecttype \"${second}\" inherits templates from \"${first}\""
      sde::init::_copy_extension_template_directory "${extensiondir}" \
                                                    "${subdirectory}" \
                                                    "${first}" \
                                                    "${extension}" \
                                                    "$@"
   .done

   if [ ! -z "${seconddir}" ]
   then
      sde::init::_copy_extension_template_files "${seconddir}" \
                                                "${subdirectory}" \
                                                "${second}" \
                                                "${extension}" \
                                                "$@"
   fi
}


sde::init::_delete_leaf_files_or_directories()
{
   log_entry "sde::init::_delete_leaf_files_or_directories" "$@"

   local extensiondir="$1"
   local subdirectory="$2"
   local projecttype="$3"

   local directory

   r_filepath_concat "${extensiondir}" "${subdirectory}"
   r_filepath_concat "${RVAL}" "${projecttype}"
   directory="${RVAL}"
   if [ ! -d "${directory}" ]
   then
      return 0
   fi

   case "${MULLE_UNAME}" in
      'sunos')
         log_warning "Won't delete empty folders on sunos, as the find is too gimped"
         return
      ;;
   esac

   r_physicalpath "${directory}"
   directory="${RVAL}"

   local i

   # https://stackoverflow.com/questions/1574403/list-all-leaf-subdirectories-in-linux
   local relpath
   local lines

   lines="`rexekutor find "${directory}" -mindepth 1 \
                                         -execdir sh \
                                         -c 'test -z "$(find "{}" -mindepth 1)" && echo ${PWD}/{}' \;`"
   .foreachline i in ${lines}
   .do
      r_simplified_path "${i#${directory}/}"
      relpath="${RVAL}"

      if [ ! -d "${relpath}" ]
      then
         r_basename "${relpath}"
         if [ "${RVAL}" != ".gitignore" ]
         then
            log_warning "Not deleting files at present (${relpath})"
            .continue
         fi
         r_dirname "${relpath}"
         relpath="${RVAL}"
      fi

      r_basename "${relpath}"
      if [ "${RVAL}" != "share" ]
      then
         log_warning "Only deleting folders called \"share\" at present (${relpath})"
         .continue
      fi

      rmdir_safer "${relpath}"
   .done
}


sde::init::_delete_extension_template_directory()
{
   log_entry "sde::init::_delete_extension_template_directory" "$@"

   local extensiondir="$1"
   local subdirectory="$2"
   local projecttype="$3"

   sde::init::_delete_leaf_files_or_directories "${extensiondir}" \
                                                "${subdirectory}" \
                                                "${projecttype}"
   sde::init::_delete_leaf_files_or_directories "${extensiondir}" \
                                                "${subdirectory}" \
                                                'all'
}


sde::init::set_projectlanguage()
{
   sde::project::set_language_variables

   log_fluff "Project language set to \"${PROJECT_LANGUAGE}\""
   log_fluff "Project dialect set to \"${PROJECT_DIALECT}\""
   log_fluff "Project extensions set to \"${PROJECT_EXTENSIONS}\""

   export PROJECT_EXTENSIONS

   export PROJECT_DOWNCASE_DIALECT
   export PROJECT_UPCASE_DIALECT
   export PROJECT_DIALECT

   export PROJECT_LANGUAGE
   export PROJECT_DOWNCASE_LANGUAGE
   export PROJECT_UPCASE_LANGUAGE
}


sde::init::extension_has_been_installed()
{
   log_entry "sde::init::extension_has_been_installed" "$@"

   local vendor="$1"
   local extname="$2"

   if [ -z "${vendor}" -a -z "${extname}" ]
   then
      return 0
   fi

   # duplicate check
   if grep -E -q -s "^${vendor}/${extname};" <<< "${_INSTALLED_EXTENSIONS}"
   then
      if ! [ "${OPTION_ADD}" = 'YES' -a "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         log_fluff "Extension \"${vendor}/${extname}\" is already installed"
         return 0
      fi
   fi
   return 1
}


sde::init::set_extension_has_been_installed()
{
   local exttype="$1"
   local vendor="$2"
   local extname="$3"

   # oneshots can appear multiple times ?.
   if [ "${exttype}" != "oneshot" ]
   then
      log_debug "memorize extension ${vendor}/${extname} as installed"
      r_add_line "${_INSTALLED_EXTENSIONS}" "${vendor}/${extname};${exttype}"
      _INSTALLED_EXTENSIONS="${RVAL}"
   fi
}


#
# With "marks" you control what should be installed:
#
# no-extension    | turn off extensions (could be useful for selective upgrade)
# no-inherit      | control what to inherit (possibly useless)
#
# no-env          | mulle-env specifica
#
# no-share        | extension files
# no-init         | extension init
#
# no-sourcetree   | mulle-sourcetree specifica
#
# no-project
# no-clobber
# no-demo
#
# Each of these marks can be further qualified by /<vendor>/<name>
#
# e.g.   no-project/mulle-sde/cmake
#
# Will exit on error. Always returns 0
#
sde::init::_install_extension()
{
   log_entry "sde::init::_install_extension" "$@"

   local projecttype="$1"
   local exttype="$2"
   local vendor="$3"
   local extname="$4"
   local marks="$5"
   local onlyfilename="$6"
   local force="$7"

   shift 7

   [ -z "${projecttype}" ] && _internal_fail "Empty project type"

   # user can turn off extensions by passing ""
   if [ -z "${extname}" ]
   then
      log_debug "Empty extension name, so nothing to do"
      RVAL=
      return
   fi

   case "${exttype}" in
      oneshot|runtime|meta|extra|buildtool)
      ;;

      *)
         _internal_fail "Unknown extension type \"${exttype}\""
      ;;
   esac

   # just to catch idiots early
   sde::init::assert_sane_extension_values "${exttype}" "${vendor}" "${extname}"

   if sde::init::extension_has_been_installed "${vendor}" "${extname}"
   then
      RVAL=
      return 1
   fi
   sde::init::set_extension_has_been_installed "${exttype}" "${vendor}" "${extname}"

   local extensiondir
   local searchpath

   if ! sde::extension::r_find_get_vendor_searchpath "${vendor}"
   then
      sde::extension::r_get_searchpath

      fail "Could not find any extensions of vendor \"${vendor}\" (${searchpath})!
${C_INFO}Show available extensions with:
   ${C_RESET}${C_BOLD}mulle-sde extension show all"
   fi

   searchpath="${RVAL}"

   if ! sde::extension::r_find_in_searchpath "${vendor}" "${extname}" "${searchpath}"
   then
      fail "Could not find extension \"${extname}\" (vendor \"${vendor}\") in
${searchpath}
${C_INFO}Show available extensions with:
   ${C_RESET}${C_BOLD}mulle-sde extension show all

${C_INFO}Possible ways to fix this:
   ${C_VERBOSE}Either download the required extension from vendor \"${vendor}\" or edit
      ${C_RESET}${C_BOLD}.mulle/share/sde/extension
   ${C_INFO}if the extension has been renamed or is unavailable."
   fi
   extensiondir="${RVAL}"

   if ! sde::init::_check_file "${extensiondir}/version"
   then
      fail "Extension \"${vendor}/${extname}\" is unversioned."
   fi

   local actualexttype

   actualexttype="`grep -E -v '^#' "${extensiondir}/type" `"
   if [ "${exttype}" != "${actualexttype}" ]
   then
      case "${actualexttype}" in
         oneshot)
            fail "Install oneshot extensions with the pimp command"
         ;;

         *)
            fail "Expected a \"${exttype}\" extension but found only a \"${actualexttype}\" extension
for \"${vendor}/${extname}\"."
         ;;
      esac
   fi

   case "${exttype}" in
      runtime)
         local tmp

         #
         # do this only once for the first runtime extension
         #
         if [ "${LANGUAGE_SET}" != 'YES' ]
         then
            if sde::init::_check_file "${extensiondir}/language"
            then
               tmp="`grep -E -v '^#' "${extensiondir}/language"`"
               IFS=";" read -r PROJECT_LANGUAGE PROJECT_DIALECT PROJECT_EXTENSIONS <<< "${tmp}"

               [ -z "${PROJECT_LANGUAGE}" ] && fail "missing language in \"${extensiondir}/language\""

               sde::init::set_projectlanguage

               LANGUAGE_SET='YES'
           fi
         fi
   esac


   if sde::init::is_disabled_by_marks "${marks}" \
                                      "${vendor}/${extname}" \
                                      "no-extension" \
                                      "no-extension/${vendor}/${extname}"
   then
      return
   fi

   local verb
   local verb_past

   verb="Installing"
   verb_past="Installed"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      verb="Upgrading"
      verb_past="Upgraded"
   fi

   #
   # file is called inherit,
   #
   if ! sde::init::is_file_disabled_by_marks "${marks}" \
                                             "${extensiondir}/inherit" \
                                             "no-inherit" \
                                             "no-inherit/${vendor}/${extname}"
   then
      #
      # inheritmarks are a way to tune the inherited marks. WHAT DOES THAT MEAN ?
      # That means an extension that has a dependency file, can have a
      # inheritmarks file with no-sourcetree and all inherited extensions will have
      # dependency turned off! The marks are always added!
      #
      local inheritmarks
      local line
      local filename

      filename="${extensiondir}/inheritmarks"
      inheritmarks="${marks}"

      if ! sde::init::is_disabled_by_marks "${marks}" \
                                           "${filename}" \
                                           "no-inheritmarks" \
                                           "no-inheritmarks/${vendor}/${extname}"
      then
         if sde::init::_check_file "${filename}"
         then
            log_fluff "${verb} dependencies for ${exttype} extension \"${vendor}/${extname}\""

            IFS=$'\n'
            for line in `grep -E -v '^#' "${filename}"`
            do
               IFS="${DEFAULT_IFS}"
               if [ ! -z "${line}" ]
               then
                  r_comma_concat "${inheritmarks}" "${line}"
                  inheritmarks="${RVAL}"
               fi
            done
            IFS="${DEFAULT_IFS}"
         fi
      fi

      sde::init::install_inheritfile "${extensiondir}/inherit" \
                                     "${projecttype}" \
                                     "${exttype}" \
                                     "${inheritmarks}" \
                                     "${onlyfilename}" \
                                     "${force}" \
                                     "$@"
   fi


   if [ -z "${onlyfilename}" ]
   then
      _log_verbose "${C_INFO}${verb} ${exttype} extension \
${C_RESET_BOLD}${vendor}/${extname}${C_VERBOSE}${C_INFO} for project type ${C_RESET_BOLD}${projecttype:-none}"
   fi


   # install version first
   if [ "${exttype}" != "oneshot" -a -z "${onlyfilename}" ]
   then
      sde::init::install_version "${vendor}" "${extname}" "${extensiondir}"
   fi

   # meta only inherits stuff and doesn't add (except version)
   if [ "${exttype}" = "meta" ]
   then
      if [ -z "${onlyfilename}" ]
      then
         log_info "${verb_past} ${exttype} extension \"${vendor}/${extname}\""
      fi
      return
   fi

   if [ -z "${onlyfilename}" ]
   then
      #
      # mulle-env stuff
      #
      if ! sde::init::is_disabled_by_marks "${marks}" \
                                           "${extensiondir}/environment" \
                                           "no-env" \
                                           "no-env/${vendor}/${extname}"
      then
## the -init and -upgrade idea was IMO a mistake, because after an init/upgrade
## the state would be different than just an init, which is really unexpected
##         if [ "${OPTION_UPGRADE}" = 'YES' ]
##         then
##            sde::init::add_to_environment "${extensiondir}/environment-upgrade" \
##                                          "${projecttype}"
##         else
##            sde::init::add_to_environment "${extensiondir}/environment-init" \
##                                          "${projecttype}"
##         fi
         sde::init::add_to_environment "${extensiondir}/environment" \
                                       "${projecttype}"

         #
         # same for post-environment
         #
##         if [ "${OPTION_UPGRADE}" = 'YES' ]
##         then
##            sde::init::add_to_environment "${extensiondir}/post-environment-upgrade" \
##                                          "${projecttype}" \
##                                          "post-extension"
##         else
##            sde::init::add_to_environment "${extensiondir}/post-environment-init" \
##                                          "${projecttype}" \
##                                          "post-extension"
##         fi
         sde::init::add_to_environment "${extensiondir}/post-environment" \
                                       "${projecttype}" \
                                       "post-extension"

         sde::init::add_to_tools "${extensiondir}/tool"

         sde::init::_copy_env_extension_dir "${extensiondir}/env" ||
            fail "Could not copy \"${extensiondir}/env\""

         sde::init::_append_to_motd "${extensiondir}"


         local executable

         executable="${extensiondir}/init"
         if ! sde::init::is_file_disabled_by_marks "${marks}" \
                                                   "${executable}" \
                                                   "no-init" \
                                                   "no-init/${vendor}/${extname}"
         then
            sde::init::run_init "${executable}" "${projecttype}" \
                                                "${exttype}" \
                                                "${vendor}" \
                                                "${extname}" \
                                                "${marks}" \
                                                "${force}"
         fi

         # happens for oneshot extensions
         if [ ! -z "${OPTION_INIT_TYPE}" ]
         then
            executable="${extensiondir}/init-${OPTION_INIT_TYPE}"
            if ! sde::init::is_file_disabled_by_marks "${marks}" \
                                                      "${executable}" \
                                                      "no-init" \
                                                      "no-init/${vendor}/${extname}"
            then
               sde::init::run_init "${executable}" "${projecttype}" \
                                                   "${exttype}" \
                                                   "${vendor}" \
                                                   "${extname}" \
                                                   "${marks}" \
                                                   "${force}"
            fi
         fi
      fi
   fi

   #
   # Project directory:
   #
   #  no-demo
   #  no-project
   #  no-clobber
   #
   if [ "${projecttype}" != 'none' ] || [ "${exttype}" = 'extra' -o "${exttype}" = 'oneshot' ]
   then
      if [ -z "${onlyfilename}" ]
      then
         # part of project really
         if ! sde::init::is_directory_disabled_by_marks "${marks}" \
                                                        "${extensiondir}/delete" \
                                                        "no-delete" \
                                                        "no-delete/${vendor}/${extname}"
         then
            sde::init::_delete_extension_template_directory "${extensiondir}" \
                                                            "delete" \
                                                            "${projecttype}"
         fi
      fi

      if ! sde::init::is_directory_disabled_by_marks "${marks}" \
                                                     "${extensiondir}/demo" \
                                                     "no-demo" \
                                                     "no-demo/${vendor}/${extname}"
      then
         sde::init::_copy_extension_template_directory "${extensiondir}" \
                                                       "demo" \
                                                       "${projecttype}" \
                                                       "${vendor}/${extname}" \
                                                       "${force}" \
                                                       "${onlyfilename}" \
                                                       "$@"
      fi

      local subdirectory


      if [ ! -z "${OPTION_INIT_TYPE}" -a -d "${extensiondir}/${OPTION_INIT_TYPE}-oneshot" ]
      then
         subdirectory="${OPTION_INIT_TYPE}-oneshot"
      else
         subdirectory="project-oneshot"
      fi

      if ! sde::init::is_directory_disabled_by_marks "${marks}" \
                                                     "${extensiondir}/${subdirectory}" \
                                                     "no-project-oneshot" \
                                                     "no-project-oneshot/${vendor}/${extname}"
      then
         sde::init::_copy_extension_template_directory "${extensiondir}" \
                                                       "${subdirectory}" \
                                                       "${projecttype}" \
                                                       "${vendor}/${extname}" \
                                                       "${force}" \
                                                       "${onlyfilename}" \
                                                       "$@"
      fi

      if [ ! -z "${OPTION_INIT_TYPE}" -a -d "${extensiondir}/${OPTION_INIT_TYPE}" ]
      then
         subdirectory="${OPTION_INIT_TYPE}"
      else
         subdirectory="project"
      fi

      if ! sde::init::is_directory_disabled_by_marks "${marks}" \
                                                     "${extensiondir}/${subdirectory}" \
                                                     "no-project" \
                                                     "no-project/${vendor}/${extname}"
      then
         sde::init::_copy_extension_template_directory "${extensiondir}" \
                                                       "${subdirectory}" \
                                                       "${projecttype}" \
                                                       "${vendor}/${extname}" \
                                                       "${force}" \
                                                       "${onlyfilename}" \
                                                       "$@"
      fi

      #
      # the clobber folder is like project but may always overwrite
      # this is used for refreshing cmake/share and such, where the user should
      # not edit. A feature now obsoleted by "delete"
      #
      if ! sde::init::is_directory_disabled_by_marks "${marks}" \
                                                     "${extensiondir}/clobber" \
                                                     "no-clobber" \
                                                     "no-clobber/${vendor}/${extname}"
      then
         sde::init::_copy_extension_template_directory "${extensiondir}" \
                                                       "clobber" \
                                                       "${projecttype}" \
                                                       "${vendor}/${extname}" \
                                                       'YES' \
                                                       "${onlyfilename}" \
                                                       "$@"
      fi
   else
      log_verbose "Not installing project or demo files for \"${extname}\", as project-type is \"none\""
   fi

   if [ -z "${onlyfilename}" ]
   then
      #
      # used to install this only with project, but it was too surprising
      # turn it off with no-sourcetree
      #
      sde::init::install_sourcetree_files "${extensiondir}" \
                                          "${vendor}" \
                                          "${extname}" \
                                          "${marks}" \
                                          "${projecttype}"
   fi


   if [ ! -z "${onlyfilename}" ]
   then
      RVAL=""
      return
   fi

   #
   # extension specific stuff . it's after project, so that you can do
   # magic in init, on a fairly complete project
   #
   #  no-share
   #  no-init
   #  no-sourcetree
   #
   if ! sde::init::is_directory_disabled_by_marks "${marks}" \
                                                  "${extensiondir}/share" \
                                                  "no-share" \
                                                  "no-share/${vendor}/${extname}"
   then
      sde::init::_copy_extension_dir "${extensiondir}/share" 'YES' 'YES' ||
         fail "Could not copy \"${extensiondir}/share\""
   fi
#   #
#   # etc is also disabled by no-share
#   #
#   if ! sde::init::is_directory_disabled_by_marks "${marks}" \
#                                       "${extensiondir}/etc" \
#                                       "no-share" \
#                                       "no-share/${vendor}/${extname}"
#   then
#      sde::init::_copy_extension_dir "${extensiondir}/etc" 'YES' 'NO' ||
#         fail "Could not copy \"${extensiondir}/etc\""
#   fi

   RVAL="${extensiondir}"
}


#
# could do this once
#
sde::init::define_hacky_template_variables()
{
   log_entry "sde::init::define_hacky_template_variables" "$@"

   PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS:-${PROJECT_DOWNCASE_DIALECT}}"
   export PROJECT_EXTENSIONS

   PROJECT_EXTENSION="${PROJECT_EXTENSION:-${PROJECT_EXTENSIONS%%:*}}"
   export PROJECT_EXTENSION

   case "${PROJECT_DIALECT}" in
      objc)
         INCLUDE_COMMAND=import
      ;;

      *)
         INCLUDE_COMMAND=include
      ;;
   esac
   export INCLUDE_COMMAND
}



# Will exit on error. Always returns 0
sde::init::install_extension()
{
   log_entry "sde::init::install_extension" "$@"

   local projecttype="$1"
   local exttype="$2"
   local vendor="$3"
   local extname="$4"
   local marks="$5"
   local onlyfilename="$6"
   local force="$7"

   local _TEMPLATE_DIRECTORIES # will be set by sde::init::_install_extension
   local _EXTENSION_INITS

   if sde::init::extension_has_been_installed "${vendor}" "${extname}"
   then
      return
   fi

   local verb
   local verb_past

   verb="Installing"
   verb_past="Installed"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      verb="Upgrading"
      verb_past="Upgraded"
   fi

   log_verbose "${verb} extension dependencies of ${C_RESET_BOLD}${vendor}/${extname}"

   # this will memorize if extension has been installed
   local extensiondir

   sde::init::_install_extension "$@"
   extensiondir="${RVAL}"

   #
   # Now install collected templates
   #
   include "template::generate"

   if [ ! -z "${_TEMPLATE_DIRECTORIES}" ]
   then
      if [ -z "${onlyfilename}" ]
      then
         log_verbose "${verb} project files for \"${vendor}/${extname}\""
      fi

      (
         sde::project::export_name_environment "${PROJECT_NAME}"
         sde::project::export_language_environment "${PROJECT_LANGUAGE}"

         #
         # Read what extensions added to the project so far. environment-project
         # is under our mulle-sde control and it's not complete yet.
         #
         if [ -f ".mulle/share/env/environment-extension.sh" ]
         then
            . ".mulle/share/env/environment-extension.sh"
         fi

         sde::init::define_hacky_template_variables

         #
         # using the --embedded option, the template generator keeps state in
         # CONTENTS_SED and FILENAME_SED, since that is expensive to recalculate
         #
         local CONTENTS_SED
         local FILENAME_SED
         local fsed_file
         local csed_file

         #
         # we use files because command lines can be fairly large
         #
         csed_file="`template::generate::main csed-script`" || exit 1
         fsed_file="`template::generate::main fsed-script`" || exit 1

         CONTENTS_SED="-f '${csed_file}'"
         FILENAME_SED="-f '${fsed_file}'"

         log_debug "_TEMPLATE_DIRECTORIES: ${_TEMPLATE_DIRECTORIES}"

         local arguments

         .foreachline arguments in ${_TEMPLATE_DIRECTORIES}
         .do
            if [ ! -z "${arguments}" ]
            then
               # memo: arguments are fully created including comments in
               # sde::init::_copy_extension_template_files
               eval_exekutor template::generate::main "${arguments}" || exit 1
            fi
         .done

         remove_file_if_present "${fsed_file}"
         remove_file_if_present "${csed_file}"
      ) || exit 1
   fi

   #
   # Inits are always run last
   #

   if [ -z "${onlyfilename}" ]
   then
      (
         local cmdline

         .foreachline cmdline in ${_EXTENSION_INITS}
         .do
            if [ ! -z "${cmdline}" ]
            then
               # memo: arguments are fully created including comments in
               # sde::init::_copy_extension_template_files
               eval_exekutor "${cmdline}" || exit 1
            fi
         .done
      ) || exit
   fi

   log_verbose "${verb_past} ${exttype} extension ${C_RESET_BOLD}${vendor}/${extname}"
}


sde::init::install_motd()
{
   log_entry "sde::init::install_motd" "$@"

   local text="$1"

   motdfile=".mulle/share/env/motd"

   if [ -z "${text}" ]
   then
      return
   fi

   remove_file_if_present "${motdfile}"
   redirect_exekutor "${motdfile}" printf "%s\n" "${text}"
}


sde::init::_install_simple_extension()
{
   log_entry "sde::init::_install_simple_extension" "$@"

   local exttype="$1"; shift

   local extras="$1"
   local projecttype="$2"
   local marks="$3"
   local onlyfilename="$4"
   local force="$5"

   projecttype="${projecttype:-${PROJECT_TYPE}}"
   if [ -z "${projecttype}" -a "${exttype}" = "oneshot" ]
   then
      projecttype="executable"
   fi

   sde::init::validate_projecttype "${projecttype}" "${force}"

   # optionally install "extra" extensions
   # f.e. a "git" extension could auto-init the project and create
   # a .gitignore file
   #
   #
   local extra
   local extra_vendor
   local extra_name

   if [ -z "${PROJECT_NAME}" -a "${exttype}" = "oneshot" ]
   then
      r_basename "${MULLE_USER_PWD}"
      PROJECT_NAME="${RVAL}"
   fi

   sde::project::assert_name "${PROJECT_NAME}"
   sde::project::set_name_variables "${PROJECT_NAME}"
   sde::init::add_environment_variables "${OPTION_DEFINES}"

   .foreachline extra in ${extras}
   .do
      case "${extra}" in
         "")
         ;;

         */*)
            extra_vendor="${extra%%/*}"
            extra_name="${extra##*/}"
         ;;

         *)
            log_fluff "Use default vendor \"mulle-sde\""

            extra_vendor="mulle-sde"
            extra_name="${extra}"
         ;;
      esac

      [ -z "${extra_name}" ]   && fail "Missing extension name \"${extra}\""
      [ -z "${extra_vendor}" ] && fail "Missing extension vendor \"${extra}\""

      sde::init::install_extension "${projecttype}" \
                                   "${exttype}" \
                                   "${extra_vendor}" \
                                   "${extra_name}" \
                                   "${marks}" \
                                   "${onlyfilename}" \
                                   "${force}"
   .done
}


# Will exit on error. Always returns 0
sde::init::install_extra_extensions()
{
   log_entry "sde::init::install_extra_extensions" "$@"

   sde::init::_install_simple_extension "extra" "$@"
}


# Will exit on error. Always returns 0
sde::init::install_oneshot_extensions()
{
   log_entry "sde::init::install_oneshot_extensions" "$@"

   sde::init::_install_simple_extension "oneshot" "$@"
}


#
# for reinit and .git it's nice to store the installed extensions in
# a separate file instead of the environment
#
sde::init::recall_installed_extensions()
{
   log_entry "sde::init::recall_installed_extensions" "$@"

   local extensionfile="$1"


   # can sometimes happen, bail early then.
   if sde::init::_check_file "${extensionfile}"
   then
      exekutor grep -E -v '^#' < "${extensionfile}"
      # deal with empty file (maybe due to edits)
      case $? in
         0|1)
            return 0
         ;;

         *)
            return 1
         ;;
      esac
   fi

   log_debug "Checking MULLE_SDE_INSTALLED_EXTENSIONS environment variable"

   #
   # also read old format
   # use mulle-env so we can get at it from the outside
   #
   local value

   value="${MULLE_SDE_INSTALLED_EXTENSIONS}"
   if [ -z "${value}" ]
   then
      value="`rexekutor "${MULLE_ENV:-mulle-env}" \
                              --search-as-is \
                              ${MULLE_TECHNICAL_FLAGS} \
                              --no-protect \
                           environment \
                              --scope extension \
                              get MULLE_SDE_INSTALLED_EXTENSIONS`"
   fi

   if [ ! -z "${value}" ]
   then
      printf "%s\n" "${value}" \
         | sed -e "s/--\\([a-z]*\\)\\ '\\([^']*\\)'/\\2;\\1,/g" \
         | tr ',' '\n'
   fi
}


sde::init::memorize_installed_extensions()
{
   log_entry "sde::init::memorize_installed_extensions" "$@"

   local extensions="$1"
   local filename="$2"

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   redirect_exekutor "${filename}" printf "%s\n" "${extensions}" || exit 1
}


sde::init::set_environment_var()
{
   local key="$1"
   local value="$2"
   local scope="${3:-extension}"

   log_verbose "Environment: ${key}=\"${value}\""

   exekutor "${MULLE_ENV:-mulle-env}" \
                     --search-as-is \
                     -s \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --no-protect \
                  environment \
                     --scope "${scope}" \
                     set "${key}" "${value}" || _internal_fail "failed env set"
}


# everything in here should exit on error not return 1
sde::init::install_extensions()
{
   log_entry "sde::init::install_extensions" "$@"

   local marks="$1"
   local onlyfilename="$2"
   local force="$3"

   [ -z "${PROJECT_TYPE}" ] && _internal_fail "missing PROJECT_TYPE"
   [ -z "${PROJECT_NAME}" ] && _internal_fail "missing PROJECT_NAME"

   # this is OK for none
   # [ -z "${PROJECT_SOURCE_DIR}" ] && log "missing PROJECT_SOURCE_DIR"

   # set to src as default for older projects

   local runtime_vendor
   local buildtool_vendor
   local meta_name
   local runtime_name
   local buildtool_name

   local option
   local tmp

   if [ ! -z "${OPTION_META}" ]
   then
      if [ ! -z "${OPTION_RUNTIME}" -o ! -z "${OPTION_BUILDTOOL}" ]
      then
         log_warning "Specifying --meta together with --runtime or --buildtool is unusual"
      fi

      case "${OPTION_META}" in
         */*)
            meta_vendor="${OPTION_META%%/*}"
            meta_name="${OPTION_META##*/}"
         ;;

         *)
            meta_vendor="${OPTION_VENDOR}"
            meta_name="${OPTION_META}"
         ;;
      esac
   fi

   if [ ! -z "${OPTION_RUNTIME}" ]
   then
      case "${OPTION_RUNTIME}" in
         */*)
            runtime_vendor="${OPTION_RUNTIME%%/*}"
            runtime_name="${OPTION_RUNTIME##*/}"
         ;;

         *)
            runtime_vendor="${OPTION_VENDOR}"
            runtime_name="${OPTION_RUNTIME}"
         ;;
      esac
   fi

   if [ ! -z "${OPTION_BUILDTOOL}" ]
   then
      case "${OPTION_BUILDTOOL}" in
         */*)
            buildtool_vendor="${OPTION_BUILDTOOL%%/*}"
            buildtool_name="${OPTION_BUILDTOOL##*/}"
         ;;

         *)
            buildtool_vendor="${OPTION_VENDOR}"
            buildtool_name="${OPTION_BUILDTOOL}"
         ;;
      esac
   fi

   if [ ! -z "${onlyfilename}" ]
   then
      (
         shell_enable_nullglob
         for i in ${onlyfilename}
         do
            if [ -f "${i}" ]
            then
               remove_file_if_present "${i}.bak"
               exekutor mv "${i}" "${i}.bak"
            fi
         done
      )
   fi

   #
   # buildtool is the most likely to fail, due to a mistyped
   # projectdir, if that happens, we have done the least pollution yet
   #
   sde::init::install_extension "${PROJECT_TYPE}" \
                                "meta" \
                                "${meta_vendor}" \
                                "${meta_name}" \
                                "${marks}" \
                                "${onlyfilename}" \
                                "${force}"
   sde::init::install_extension "${PROJECT_TYPE}" \
                                "runtime" \
                                "${runtime_vendor}" \
                                "${runtime_name}" \
                                "${marks}" \
                                "${onlyfilename}" \
                                "${force}"
   sde::init::install_extension "${PROJECT_TYPE}" \
                                "buildtool" \
                                "${buildtool_vendor}" \
                                "${buildtool_name}" \
                                "${marks}" \
                                "${onlyfilename}" \
                                "${force}"

   sde::init::install_extra_extensions "${OPTION_EXTRAS}" \
                                       "${PROJECT_TYPE}" \
                                       "${marks}" \
                                       "${onlyfilename}" \
                                       "${force}"


   if [ ! -z "${onlyfilename}" ]
   then
      return
   fi

   #
   # remember type and installed extensions
   #
   sde::init::memorize_installed_extensions "${_INSTALLED_EXTENSIONS}" \
                                            "${OPTION_EXTENSION_FILE}"

   # oneshots aren't memorized
   sde::init::install_oneshot_extensions "${OPTION_ONESHOTS}" \
                                         "${PROJECT_TYPE}" \
                                         "${marks}" \
                                         "" \
                                         "${force}"
}


sde::init::install_project()
{
   log_entry "sde::init::install_project" "$@"

   local projectname="$1"
   local projecttype="$2"
   local projectsourcedir="$3"
   local marks="$4"
   local onlyfilename="$5"
   local force="$6"
   local language="$7"
   local dialect="$8"
   local extensions="$9"

   local PROJECT_NAME
   local PROJECT_LANGUAGE
   local PROJECT_EXTENSIONS
   local PROJECT_DIALECT      # for objc
   local PROJECT_SOURCE_DIR
   local PROJECT_TYPE
   local LANGUAGE_SET

   LANGUAGE_SET='NO'

   sde::project::assert_name "${projectname}"

   PROJECT_NAME="${projectname}"
   export PROJECT_NAME

   if [ ! -z "${language}" ]
   then
      PROJECT_LANGUAGE="${language}"
      PROJECT_DIALECT="${dialect}"
      PROJECT_EXTENSIONS="${extensions}"

      sde::init::set_projectlanguage
   fi

   #
   # the project language is actually determined by the runtime
   # extension
   #
   sde::project::add_envscope_if_missing

   PROJECT_TYPE="${projecttype}"
   PROJECT_SOURCE_DIR="${projectsourcedir}"

   sde::init::set_environment_var PROJECT_TYPE "${PROJECT_TYPE}" "project"
   if [ ! -z "${PROJECT_SOURCE_DIR}" ]
   then
      #
      # For projects that are not "none", we use save PROJECT_SOURCE_DIR
      #
      sde::init::set_environment_var PROJECT_SOURCE_DIR "${PROJECT_SOURCE_DIR}" "project"
   fi

   export PROJECT_SOURCE_DIR
   export PROJECT_TYPE

   local _MOTD
   local _INSTALLED_EXTENSIONS

   _MOTD=""

   if [ -z "${onlyfilename}" ]
   then
      log_info "Installing extensions in ${C_RESET_BOLD}${PWD#"${MULLE_USER_PWD}/"}${C_INFO}"
   fi

   #
   # TODO: this is clumsy and needs to be rewritten
   # put these first, so extensions can draw on these in their definitions
   #
   # sets PROJECT_IDENTIFIER, PROJECT_UPCASE_IDENTIFIER PROJECT_DOWNCASE_IDENTIFIER
   sde::project::set_name_variables "${PROJECT_NAME}"
   sde::project::save_name_variables "--no-protect"

   sde::init::install_extensions "${marks}" "${onlyfilename}" "${force}"

   if [ ! -z "${onlyfilename}" ]
   then
      return
   fi

   sde::project::save_language_variables "--no-protect"

   if [ -z "${_INSTALLED_EXTENSIONS}" -a "${OPTION_UPGRADE}" != 'YES' ]
   then
      case "${OPTION_ENV_STYLE}" in
         */tight|*/relax|*/restrict)
            _log_warning "No extensions were installed and the style is ${OPTION_ENV_STYLE}.
${C_INFO}Check the available command line tools with:
   ${C_RESET_BOLD}mulle-sde tool list${C_INFO}
add more with:
   ${C_RESET_BOLD}mulle-sde add <toolname>${C_INFO}"
         ;;
      esac
   fi

   case ",${marks}," in
      *',no-motd,'*)
         return
      ;;
   esac

   # only install motd if we have a buildtool extension ?
   case "${_INSTALLED_EXTENSIONS}" in
      *';buildtool'*)

         local motd

         motd="`printf "%b\n%b" \
                       "${C_INFO}Run external commands with ${C_RESET_BOLD}mudo" \
                       "${C_INFO}Project is ready to ${C_RESET_BOLD}craft${C_RESET}"`"

         if [ -z "${_MOTD}" ]
         then
            _MOTD="${motd}"
         else
            _MOTD="${_MOTD}
${motd}"
         fi
      ;;
   esac

   sde::init::install_motd "${_MOTD}"
}


sde::init::add_environment_variables()
{
   log_entry "sde::init::add_environment_variables" "$@"

   local defines="$1"

   [ -z "${defines}" ] && return 0

   if [ "${OPTION_UPGRADE}" = 'YES' -a "${_INFOED_ENV_RELOAD}" != 'YES' ]
   then
      _INFOED_ENV_RELOAD='YES'
      _log_warning "Use ${C_RESET_BOLD}mulle-env-reload${C_INFO} to get environment \
changes into your subshell"
   fi

   (
      MULLE_VIRTUAL_ROOT="`pwd -P`" \
         eval_exekutor "'${MULLE_ENV:-mulle-env}'" \
                              --search-nearest \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              --no-protect \
                           environment \
                              --scope extension \
                              mset "${defines}"
   ) || exit 1
}


sde::init::run_add()
{
   log_entry "sde::init::run_add" "$@"

   [ $# -ne 0 ] && sde::init::usage "Superflous arguments \"$*\""

   [ "${OPTION_REINIT}" = 'YES' -o "${OPTION_UPGRADE}" = 'YES' ] && \
      fail "--add and --reinit/--upgrade exclude each other"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" ]
   then
      fail "You must init first, before you can add an 'extra' extension!
${C_VERBOSE}(\"${MULLE_SDE_SHARE_DIR#"${MULLE_USER_PWD}/"}\" not present)"
   fi

   if [ ! -z "${OPTION_RUNTIME}" -o \
        ! -z "${OPTION_BUILDTOOL}" -o \
        ! -z "${OPTION_META}" ]
   then
      fail "Only 'extra' and 'oneshot' extensions can be added"
   fi

   if [ -z "${OPTION_EXTRAS}" -a -z "${OPTION_ONESHOTS}" ]
   then
      fail "You must specify an extra or oneshot extension to be added"
   fi

   [ -z "${PROJECT_TYPE}" ] && fail "PROJECT_TYPE is not defined"

   sde::init::add_environment_variables "${OPTION_DEFINES}"

   local _INSTALLED_EXTENSIONS

   _INSTALLED_EXTENSIONS="`sde::init::recall_installed_extensions "${OPTION_EXTENSION_FILE}"`" || exit 1
   log_debug "Installed extensions: ${_INSTALLED_EXTENSIONS}"

   if ! sde::init::install_extra_extensions "${OPTION_EXTRAS}" \
                                            "${PROJECT_TYPE}" \
                                            "${OPTION_MARKS}" \
                                            "" \
                                            "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      return 1
   fi

   sde::init::memorize_installed_extensions "${_INSTALLED_EXTENSIONS}" \
                                            "${OPTION_EXTENSION_FILE}"

   sde::init::install_oneshot_extensions "${OPTION_ONESHOTS}" \
                                         "${PROJECT_TYPE}" \
                                         "${OPTION_MARKS}" \
                                         "" \
                                         "${MULLE_FLAG_MAGNUM_FORCE}"
}


sde::init::r_mset_quoted_env_line()
{
   local line="$1"

   local key
   local value

   key="${line%%=*}"
   value="${line#*=}"

   case "${value}" in
      \"*\")
         RVAL="${line}"
      ;;

      *)
         RVAL="${key}=\"${value}\""
      ;;
   esac
}


sde::init::get_installed_extensions()
{
   log_entry "mulle-objc/travis" "$@"

   local extensionfile="$1"

   local extensions

   extensions="`sde::init::recall_installed_extensions "${extensionfile}"`" || exit 1
   if [ -z "${extensions}" ]
   then
      log_fluff "No installed extensions found"
      return 1
   fi

   log_debug "Found installed extensions: ${extensions}"

   local extension

   .foreachline extension in ${extensions}
   .do
      case "${extension}" in
         *\;meta)
            if [ -z "${OPTION_META}" ]
            then
               OPTION_META="${extension%;*}"
               log_debug "Reinit meta extension: ${OPTION_META}"
               OPTION_BUILDTOOL=
               OPTION_RUNTIME=
            fi
         ;;

         *\;buildtool)
            if [ -z "${OPTION_META}" -a -z "${OPTION_BUILDTOOL}" ]
            then
               OPTION_BUILDTOOL="${extension%;*}"
               log_debug "Reinit buildtool extension: ${OPTION_BUILDTOOL}"
            fi
         ;;

         *\;runtime)
            if [ -z "${OPTION_META}" -a -z "${OPTION_RUNTIME}" ]
            then
               OPTION_RUNTIME="${extension%;*}"
               log_debug "Reinit runtime extension: ${OPTION_RUNTIME}"
            fi
         ;;

         *\;extra)
            r_add_line "${OPTION_EXTRAS}" "${extension%;*}"
            OPTION_EXTRAS="${RVAL}"
            log_debug "Reinit extra extension: ${extension%;*}"
         ;;

         *\;*)
            log_warning "Garbled memorized extension \"${extension}\""
         ;;
      esac
   .done
}


sde::init::remove_from_marks()
{
   log_entry "sde::init::remove_from_marks" "$@"

   local marks="$1"
   local mark="$2"

   local i
   local newmarks=""

   .foreachitem i in ${marks}
   .do
      if [ "${mark}" != "${i}" ]
      then
         r_comma_concat "${newmarks}" "${i}"
         newmarks="${RVAL}"
      fi
   .done

   printf "%s\n" "${newmarks}"
}


#
# call this before__get_installed_extensions
#
sde::init::read_project_environment()
{
   log_entry "sde::init::read_project_environment" "$@"

   if [ -f ".mulle/etc/env/environment-project.sh" ]
   then
      log_fluff "Reading project settings"
      . ".mulle/etc/env/environment-project.sh"
   fi

   if [ -z "${PROJECT_TYPE}" ]
   then
      if [ -f ".mulle/share/env.old/environment-project.sh" ]
      then
         log_warning "Reading OLD project settings from \".mulle/share/env.old/environment-project.sh\""
         . ".mulle/share/env/environment-project.sh"
      else
         if [ -f ".mulle/share/env/environment-project.sh" ]
         then
            log_fluff "Reading v2 project settings"
            . ".mulle/share/env/environment-project.sh"
         fi
      fi
   fi

   [ -z "${PROJECT_TYPE}" ] && \
     fail "Could not find required PROJECT_TYPE in environment.
If you reinited the environment. Try:
   ${C_RESET}${C_BOLD}mulle-sde environment --project set PROJECT_TYPE library"

   log_setting "PROJECT_DIALECT=\"${PROJECT_DIALECT}\""
   log_setting "PROJECT_EXTENSIONS=\"${PROJECT_EXTENSIONS}\""
   log_setting "PROJECT_LANGUAGE=\"${PROJECT_LANGUAGE}\""
   log_setting "PROJECT_NAME=\"${PROJECT_NAME}\""
   log_setting "PROJECT_SOURCE_DIR=\"${PROJECT_SOURCE_DIR}\""
   log_setting "PROJECT_TYPE=\"${PROJECT_TYPE}\""
}


sde::init::run_user_post_init_script()
{
   log_entry "sde::init::run_user_post_init_script" "$@"

   local scriptfile

   scriptfile="${HOME}/bin/post-mulle-sde-init"
   if [ -e "${scriptfile}" ]
   then
      if [ ! -x "${scriptfile}" ]
      then
         fail "\"${scriptfile}\" exists but is not executable"
      fi
   else
      log_fluff "\"${scriptfile}\" does not exist"

      if ! scriptfile="`command -v post-mulle-sde-init`"
      then
         log_fluff "\"post-mulle-sde-init\" not found in PATH"
         return
      fi
   fi

   log_warning "Running post-init script \"${scriptfile}\""
   log_info "You can suppress this behavior with --no-post-init"

   MULLE_TECHNICAL_FLAGS="${MULLE_TECHNICAL_FLAGS}" \
      exekutor "${scriptfile}" "$@" || exit 1
}


sde::init::warn_if_unknown_mark()
{
   log_entry "sde::init::warn_if_unknown_mark" "$@"

   local mark="$1"
   local description="$2"

      case "${mark}" in
      'extension'|'inherit'|'env'|'share'|'init'|'sourcetree'|'project')
         return
      ;;
      'clobber'|'demo'|'motd')
         return
      ;;
   esac

   log_warning "Unknown mark \"$2\""
}


# stupid old code
sde::init::validate_projecttype()
{
   local projecttype="$1"
   local force="$2"

   # if we are upgrading, just don't check this
   if [ "${OPTION_UPGRADE}" = 'YES' -o "${OPTION_ADD}" = 'YES' ]
   then
      return
   fi

   case "${projecttype}" in
      "")
         fail "Project type is empty"
      ;;

      none|unknown)
      ;;

      bundle|executable|extension|framework|library)
         # need a meta extension
         # except if we force it (for a test)
         if [ -z "${OPTION_META}" -a "${force}" != 'YES' ]
         then
            log_info "Defaulting to ${C_BOLD}${C_MAGENTA}foundation/objc-developer${C_INFO} as meta extension"
            OPTION_META="foundation/objc-developer"
         fi
      ;;

      *)
         if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
         then
            fail "\"${projecttype}\" is not a standard project type like \"library\" or \"executable\".
${C_INFO}Use -f to use \"${projecttype}\""
         fi
      ;;
   esac
}


sde::init::_run_upgrade()
{
   log_entry "sde::init::_run_upgrade" "$@"

   [ $# -ne 0 ] && sde::init::usage "Superflous arguments \"$*\""

   rexekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --no-protect \
                     upgrade || exit 1

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
   fi

   sde::init::read_project_environment
   sde::init::validate_projecttype "${PROJECT_TYPE}" "${MULLE_FLAG_MAGNUM_FORCE}"

   if ! sde::init::get_installed_extensions "${OPTION_EXTENSION_FILE}"
   then
      case "${PROJECT_TYPE}" in
         "none")
            if [ "${PWD}" != "${MULLE_USER_PWD}" ]
            then
               _log_verbose "Nothing to upgrade in \
${C_RESET_BOLD}${PWD#"${MULLE_USER_PWD}/"}${C_VERBOSE}, as no extensions have \
been installed."
            else
               log_verbose "Nothing to upgrade, as no extensions have been installed."
            fi
            return 0
         ;;
      esac

      fail "Could not retrieve previous extension information.
This may hurt, but you have to init again."
   fi

   log_fluff "Erasing share/env contents to be written by upgrade anew"

   if ! sde::init::is_disabled_by_marks "${marks}" "no-env"
   then
      # should be part of mulle-env to clear a scope
      remove_file_if_present ".mulle/share/env/environment-extension.sh"

      local file

      .for file in ".mulle/share/env/tool-extension" ".mulle/share/env/tool-extension".*
      .do
         remove_file_if_present "${file}"
      .done

      # some old cruft that we need to clean, before things get reinstalled
      rmdir_safer ".mulle/share/env/libexec"
   fi

   # clean .mulle/share/sde

   #
   # TODO: should probably also move everything else except mulle-env, which
   #       we still need
   #
   sde::project::assert_name "${PROJECT_NAME}"
   sde::project::set_name_variables "${PROJECT_NAME}"
   sde::init::add_environment_variables "${OPTION_DEFINES}"

   # rmdir_safer ".mulle-env"
   if ! sde::init::install_extensions "${OPTION_MARKS}" \
                                      "${OPTION_PROJECT_FILE}" \
                                      "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      return 1
   fi

   # upgrade identifiers if missing
   #
   # TODO: compare old version to new, and run custom pre/postscripts
   #
   # Not doing this anymore, as project moved to etc
   # memorize_project_name "${PROJECT_NAME}"

   case ",${marks}," in
      *',no-motd,'*)
      ;;

      *)
         case "${_INSTALLED_EXTENSIONS}" in
            *';buildtool'*)

               local motd

               motd="`printf "%b\n%b" \
                             "${C_INFO}Run external commands with ${C_RESET_BOLD}mudo" \
                             "${C_INFO}Project is ready to ${C_RESET_BOLD}craft${C_RESET}"`"

               if [ -z "${_MOTD}" ]
               then
                  _MOTD="${motd}"
               else
                  _MOTD="${_MOTD}
${motd}"
               fi
            ;;
         esac
         sde::init::install_motd "${_MOTD}"
      ;;
   esac


   #
   # repair patternfiles as a "bonus" with -add option
   #
   exekutor "${MULLE_MATCH:-mulle-match}" \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_MATCH_FLAGS} \
              patternfile repair --add

   return 0
}


sde::init::_run_upgrade_projectfile()
{
   log_entry "sde::init::_run_upgrade_projectfile" "$@"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
   fi

   sde::init::read_project_environment

   sde::init::validate_projecttype "${PROJECT_TYPE}" "${MULLE_FLAG_MAGNUM_FORCE}"

   if ! sde::init::get_installed_extensions "${OPTION_EXTENSION_FILE}"
   then
      case "${PROJECT_TYPE}" in
         "none")
            if [ "${PWD}" != "${MULLE_USER_PWD}" ]
            then
               _log_verbose "Nothing to upgrade in \
${C_RESET_BOLD}${PWD#"${MULLE_USER_PWD}/"}${C_VERBOSE}, as no extensions have \
been installed."
            else
               log_verbose "Nothing to upgrade, as no extensions have been installed."
            fi
            return 0
         ;;
      esac

      fail "Could not retrieve previous extension information.
This may hurt, but you have to init again."
   fi

   sde::project::assert_name "${PROJECT_NAME}"
   sde::project::set_name_variables "${PROJECT_NAME}"
   sde::init::add_environment_variables "${OPTION_DEFINES}"

   # rmdir_safer ".mulle-env"
   if ! sde::init::install_extensions "${OPTION_MARKS}" \
                           "${OPTION_PROJECT_FILE}" \
                           "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      return 1
   fi

   return 0
}


sde::init::r_initenv_style()
{
   log_entry "sde::init::r_initenv_style" "$@"

   local style="$1"
   local projecttype="$2"

   if [ "${style}" = 'DEFAULT' ]
   then
      if [ "${projecttype}" = 'none' ]
      then
         RVAL="mulle/wild"
      else
         RVAL="mulle/relax"
      fi
   else
      RVAL="${style}"
   fi
}


sde::init::_pre_initenv()
{
   log_entry "sde::init::_pre_initenv" "$@"

   local style="$1"
   local projecttype="$2"
   local command="${3:-init}"

   sde::init::r_initenv_style "${style}" "${projecttype}"
   style="${RVAL}"

   #
   # if we init env now, then extensions can add environment
   # variables and tools
   #
   local flags

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="-f"
   fi

   log_info "Initialize environment"

   exekutor "${MULLE_ENV:-mulle-env}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${flags} \
                  --no-protect \
                  --style "${style}" \
               ${command} \
                  --no-blurb
   case $? in
      0)
      ;;

      4)
         log_fluff "mulle-env warning noted, but ignored"
      ;;

      *)
         if [ "${purge_mulle_on_error}" = 'YES' -a -d .mulle ]
         then
            _internal_fail "mulle-env should have cleaned up after itself after init failure"
         fi
         exit 1
      ;;
   esac
}


sde::init::_post_initenv()
{
   log_entry "sde::init::_post_initenv" "$@"

   local projecttype="$1"

   if [ "${projecttype}" = 'none' ]
   then
      sde::project::env_set_var "MULLE_SDE_CRAFT_TARGET" "craftorder" --no-protect
      OPTION_BLURB='NO'
   fi

   if [ "${OPTION_INIT_TYPE}" = "subproject" ]
   then
      exekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --no-protect \
                  tweak \
                     climb
   fi

   if [ "${OPTION_BLURB}" = 'YES' ]
   then
      _log_info "Enter the environment:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} \"${PWD#"${MULLE_USER_PWD}/"}\"${C_INFO}"
   fi
}


sde::init::_run_common()
{
   log_entry "sde::init::_run_common" "$@"

   local projecttype="${1:-none}"

   [ $# -ne 1 ] && shift && sde::init::usage "Superflous arguments \"$*\""

   sde::init::validate_projecttype "${projecttype}" "${MULLE_FLAG_MAGNUM_FORCE}"

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      if [ "${OPTION_REINIT}" = 'YES' ]
      then
         if [ -z "${OPTION_PROJECT_FILE}" ]
         then
            sde::init::_pre_initenv "${OPTION_ENV_STYLE}" "${projecttype}" "reinit"
         fi
      else
         sde::init::_pre_initenv "${OPTION_ENV_STYLE}" "${projecttype}"
      fi
   fi

   case "${OPTION_PROJECT_SOURCE_DIR}" in
      DEFAULT)
         if [ "${projecttype}" != "none" ]
         then
            OPTION_PROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR:-src}"
         else
            OPTION_PROJECT_SOURCE_DIR=""
         fi
      ;;
   esac

   local projectname

   case "${OPTION_NAME}" in
      DEFAULT)
         projectname="${PROJECT_NAME}"
         if [ -z "${projectname}" ]
         then
            r_basename "${PWD}"
            RVAL="${RVAL//[^a-zA-Z0-9-]/_}"
            projectname="${RVAL}"
         fi
      ;;

      "")
         fail "project name is empty"
      ;;

      *)
         projectname="${OPTION_NAME}"
      ;;
   esac

   sde::project::assert_name "${projectname}"

   sde::init::add_environment_variables "${OPTION_DEFINES}"

   if ! sde::init::install_project "${projectname}" \
                                   "${projecttype}" \
                                   "${OPTION_PROJECT_SOURCE_DIR}" \
                                   "${OPTION_MARKS}" \
                                   "${OPTION_PROJECT_FILE}" \
                                   "${MULLE_FLAG_MAGNUM_FORCE}" \
                                   "${OPTION_LANGUAGE}"  \
                                   "${OPTION_DIALECT}"  \
                                   "${OPTION_EXTENSIONS}"
   then
      _internal_fail "sde::init::install_project should exit not return errors"
   fi

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      sde::init::_post_initenv "${projecttype}"
   fi

   if [ "${OPTION_POST_INIT}" = 'YES' ]
   then
      sde::init::run_user_post_init_script "${PROJECT_LANGUAGE}" \
                                "${PROJECT_DIALECT}" \
                                "${projecttype}"
   fi
}


sde::init::_run_reinit()
{
   log_entry "sde::init::_run_reinit" "$@"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
   fi

   sde::init::read_project_environment

   sde::init::_run_common "$@"
}



sde::init::_run_init()
{
   log_entry "sde::init::_run_init" "$@"

   sde::init::_run_common "$@"
}


#
# These funtions should save state and revert to previous state if the
# init/upgrade failed.
#
sde::init::check_dot_init()
{
   log_entry "sde::init::check_dot_init" "$@"

   if [ -d "${MULLE_SDE_SHARE_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         if sde::init::_check_file "${MULLE_SDE_SHARE_DIR}/.init"
         then
            fail "There is already a ${MULLE_SDE_SHARE_DIR} folder in \"${PWD}\". \
It looks like an init gone bad."
         fi

         fail "There is already a ${MULLE_SDE_SHARE_DIR} folder in \"${PWD}\".
${C_INFO}In case you wanted to upgrade it:
${C_RESET_BOLD}   mulle-sde upgrade"
      fi
   fi
}


sde::init::save_mulle_in_old_and_setup_new()
{
   log_entry "sde::init::save_mulle_in_old_and_setup_new" "$@"

   rmdir_safer ".mulle.old"

   exekutor mv ".mulle" ".mulle.old"  || fail  "Could not move old .mulle folder ($PWD#${MULLE_USER_PWD}/})"

   # order is important on mingw, first share than etc
   # for symlinks
   if ! \
   (
      set -e
      mkdir_if_missing ".mulle"
      exekutor cp -Rp ".mulle.old/share" ".mulle"
      if [ -d ".mulle.old/etc" ]
      then
         exekutor cp -Rp ".mulle.old/etc" ".mulle"
      fi

      mkdir_if_missing "${MULLE_MATCH_VAR_DIR}"
      mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   )
   then
      exekutor mv ".mulle.old" ".mulle"
      fail  "Could not create new .mulle folder ($PWD#${MULLE_USER_PWD}/})"
   fi
}


sde::init::restore_mulle_from_old()
{
   log_entry "sde::init::restore_mulle_from_old" "$@"

   if [ ! -d ".mulle.old" ]
   then
      fail "Things went really bad, can't restore old configuration"
   fi

   if [ -d ".mulle.old" ]
   then
      rmdir_safer ".mulle"
      exekutor mv ".mulle.old" ".mulle" || exit 1
      log_info "Restored old configuration"
   fi
}


sde::init::start()
{
   log_entry "sde::init::start" "$@"

   # we clobber these just to be safe

   rmdir_safer "${MULLE_CRAFT_VAR_DIR}"
   rmdir_safer "${MULLE_MATCH_VAR_DIR}"
   rmdir_safer "${MULLE_MONITOR_VAR_DIR}"
   rmdir_safer "${MULLE_SOURCETREE_VAR_DIR}"
   rmdir_safer "${MULLE_SDE_VAR_DIR}"

   # we clobber these and let extension fill them back up
   rmdir_safer "${MULLE_CRAFT_SHARE_DIR}"
   rmdir_safer "${MULLE_MATCH_SHARE_DIR}"
   rmdir_safer "${MULLE_MONITOR_SHARE_DIR}"
   rmdir_safer "${MULLE_SOURCETREE_SHARE_DIR}"

   # we like to keep the extension file around so don't clobber completely
   # if there is none, don't clobber .old
   if [ -f "${MULLE_SDE_SHARE_DIR}/extension" ]
   then
      rmdir_safer "${MULLE_SDE_SHARE_DIR}.old"
      exekutor mv "${MULLE_SDE_SHARE_DIR}" "${MULLE_SDE_SHARE_DIR}.old"
   fi

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   if [ -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      exekutor cp "${MULLE_SDE_SHARE_DIR}.old/extension" "${MULLE_SDE_SHARE_DIR}/extension"
   fi

   redirect_exekutor "${MULLE_SDE_SHARE_DIR}/.init" \
      echo "${1:-Init} start `date` in $PWD on ${MULLE_HOSTNAME}"
}


sde::init::end()
{
   log_entry "sde::init::end" "$@"

#   # remove if empty ??? Needed anymore ??
#   exekutor rmdir "${MULLE_MATCH_SHARE_DIR}" 2>  /dev/null
#   exekutor rmdir "${MULLE_CRAFT_SHARE_DIR}" 2>  /dev/null
#   exekutor rmdir "${MULLE_SOURCETREE_SHARE_DIR}" 2>  /dev/null
#   exekutor rmdir "${MULLE_MONITOR_SHARE_DIR}" 2>  /dev/null

   rmdir_safer "${MULLE_SDE_SHARE_DIR}.old"
   remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"
}



sde::init::run()
{
   log_entry "sde::init::run" "$@"

   sde::init::check_dot_init

   log_verbose "Init start"

   sde::init::start

   local rval
   (
      sde::init::_run_init "$@"
   )
   rval="$?"

   if [ $rval != 0 ]
   then
      rmdir_safer ".mulle"

      if [ "${PURGE_PWD_ON_ERROR}" = 'YES' ]
      then
         local dir

         dir="${PWD}"
         cd /
         rmdir_safer "${dir}"
      fi
   fi

   sde::init::end

   log_verbose "Init end"

   return $rval
}



sde::init::run_reinit()
{
   # reinit, save the old
   log_entry "sde::init::run_reinit" "$@"

   log_verbose "Reinit start"

   sde::init::check_dot_init

   sde::init::save_mulle_in_old_and_setup_new

   sde::init::start "Reinit"

   local rval
   (
      sde::init::_run_reinit "$@"
   )
   rval="$?"

   # rmdir_safer ".mulle-env"
   if [ $rval -ne 0 ]
   then
      log_info "The reinit failed. Restoring old configuration."

      sde::init::restore_mulle_from_old
   else
      rmdir_safer ".mulle.old"
   fi

   sde::init::end

   log_verbose "Reinit end"

   return $rval
}


sde::init::run_upgrade()
{
   log_entry "sde::init::run_upgrade" "$@"

   if [ -d ".mulle.old" -a ! -d ".mulle" ]
   then
      fail "Old .mulle.old folder of a possibly failed upgrade present, restore or remove it manually"
   fi

   if [ ! -d ".mulle" ]
   then
      fail "No .mulle folder present, nothing to upgrade"
   fi

   log_verbose "Upgrade start"

   #
   # always wipe these for clean upgrades
   # except if we are just updating a specific project file
   # (i.e. CMakeLists.txt). Keep "extension" file around in case something
   # goes wrong. Also temporarily keep old share
   #
   sde::init::save_mulle_in_old_and_setup_new

   sde::init::start "Upgrade"

   local rval
   (
      sde::init::_run_upgrade "$@"
   )
   rval="$?"

   # rmdir_safer ".mulle-env"
   if [ $rval -ne 0 ]
   then
      log_info "The upgrade failed. Restoring old configuration for \"${PWD#"${MULLE_USER_PWD}/"}\""

      sde::init::restore_mulle_from_old
   else
      rmdir_safer ".mulle.old"
   fi

   sde::init::end "Upgrade"

   log_verbose "Upgrade end"

   return $rval
}


# this must not use start init /end init
sde::init::run_upgrade_projectfile()
{
   log_entry "sde::init::run_upgrade_projectfile" "$@"

   log_verbose "Upgrade projectfile start"
   # probably nothing to do here (could save source but we don't)
   local rval
   (
      sde::init::_run_upgrade_projectfile "$@"
   )
   rval="$?"

   log_verbose "Upgrade projectfile end"
   return $rval
}


sde::init::protect_unprotect()
{
   log_entry "sde::init::protect_unprotect" "$@"

   local title="$1"
   local mode="$2"

   if ! MULLE_SDE_PROTECT_PATH="` "${MULLE_ENV:-mulle-env}" ${MULLE_ENV_FLAGS} \
                                 environment \
                                    get MULLE_SDE_PROTECT_PATH 2> /dev/null `"
   then
      log_fluff "MULLE_SDE_PROTECT_PATH is empty" # tests have none for
   fi

   #
   # unprotect known share directories during installation
   # TODO: this should be a setting somewhere
   #
   case ":${MULLE_SDE_PROTECT_PATH}:" in
      *:.mulle/share:*)
      ;;

      *)
         r_colon_concat ".mulle/share" "${MULLE_SDE_PROTECT_PATH}"
         MULLE_SDE_PROTECT_PATH="${RVAL}"
      ;;
   esac

   case ":${MULLE_SDE_PROTECT_PATH}:" in
      *:cmake/share:*)
      ;;

      *)
         r_colon_concat "cmake/share" "${MULLE_SDE_PROTECT_PATH}"
         MULLE_SDE_PROTECT_PATH="${RVAL}"
      ;;
   esac

   local i

   log_fluff "${title} ${MULLE_SDE_PROTECT_PATH}"

   .foreachpath i in ${MULLE_SDE_PROTECT_PATH}
   .do
      [ ! -e "${i}" ] && .continue

      # can only read protect files, because otherwise git freaks out
      exekutor find "${i}" -type f -exec chmod "${mode}" {} \;
   .done
}


sde::init::r_get_old_version()
{
   log_entry "sde::init::r_get_old_version" "$@"

   local oldversion

   oldversion="`rexekutor "${MULLE_ENV:-mulle-env}" \
                  -f \
                  --search-as-is \
                  -s \
               environment get MULLE_SDE_INSTALLED_VERSION 2> /dev/null`"
   log_debug "Old version: ${oldversion}"

   case "${oldversion}" in
      [0-9]*\.[0-9]*\.[0-9]*)
         # check that old version is not actually newer than what we have
         # shellcheck source=mulle-case.sh
         [ -z "${MULLE_VERSION_SH}" ] \
         &&  . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh"

         r_version_distance "${MULLE_EXECUTABLE_VERSION}" "${RVAL}"
         if [ "${RVAL}" -gt 0 ]
         then
            fail "Can't upgrade! The environment  was created by a newer \
mulle-sde version ${RVAL}.
${C_INFO}You have mulle-sde version ${MULLE_EXECUTABLE_VERSION}"
         fi
      ;;

      "")
         [ ! -d .mulle/share/sde ] \
         && fail "There is no mulle-sde project in \"${PWD#"${MULLE_USER_PWD}/"}\""

         oldversion="0.0.0"
         _log_warning "Can not get previous installed version from \
MULLE_SDE_INSTALLED_VERSION, assuming 0.0.0"
      ;;

      *)
         _internal_fail "Unparsable version info in \
MULLE_SDE_INSTALLED_VERSION (${oldversion})"
      ;;
   esac

   RVAL="${oldversion}"
}


sde::init::include()
{
   include "path"
   include "file"
   include "sde::extension"
   include "sde::project"
}


###
### parameters and environment variables
###
sde::init::_main()
{
   log_entry "sde::init::_main" "$@"

   local OPTION_ADD
   local OPTION_BLURB='YES'
   local OPTION_BUILDTOOL=""
   local OPTION_COMMON="sde"
   local OPTION_DEFINES
   local OPTION_DIALECT
   local OPTION_ENV_STYLE='DEFAULT'
   local OPTION_EXTENSION_FILE=".mulle/share/sde/extension"
   local OPTION_EXTENSIONS
   local OPTION_EXTRAS
   local OPTION_INIT_ENV='YES'
   local OPTION_INIT_FLAGS
   local OPTION_INIT_TYPE="project"
   local OPTION_LANGUAGE
   local OPTION_MARKS=""
   local OPTION_META=""
   local OPTION_NAME='DEFAULT'
   local OPTION_ONESHOTS
   local OPTION_POST_INIT='YES'
   local OPTION_PROJECT_FILE
   local OPTION_PROJECT_SOURCE_DIR='DEFAULT'
   local OPTION_REFLECT='YES'
   local OPTION_CLEAN='DEFAULT'
   local OPTION_REINIT
   local OPTION_RUNTIME=""
   local OPTION_TEMPLATE_FILES='YES'
   local OPTION_UPGRADE
   local OPTION_UPGRADE_SUBPROJECTS
   local OPTION_VENDOR="mulle-sde"
   local OPTION_IF_MISSING
   local PURGE_PWD_ON_ERROR='NO'
   local OPTION_COMMENT_FILES="${MULLE_SDE_GENERATE_FILE_COMMENTS:-YES}" # on by default, else I forget this option exists :)
   local TEMPLATE_FOOTER_FILE
   local TEMPLATE_HEADER_FILE
   local line
   local mark

   sde::init::include

   # don't accidentally inherit stuff from the environment
   # this is otherwise super hard to debug (sigh)
   if [ "$1" = "--add" -o "$1" = "-a" ]
   then
      shift
      OPTION_ADD='YES'
   else
      sde::project::clear_variables
   fi

   sde::project::clear_oneshot_variables

   OPTION_META="${MULLE_SDE_DEFAULT_META_EXTENSION}"
   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde::init::usage
         ;;

         -D?*)
            sde::init::r_mset_quoted_env_line "${1:2}"
            r_concat "${OPTION_DEFINES}" "'${RVAL}'"
            OPTION_DEFINES="${RVAL}"
         ;;

         -D)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            sde::init::r_mset_quoted_env_line "$1"
            r_concat "${OPTION_DEFINES}" "'${RVAL}'"
            OPTION_DEFINES="${RVAL}"
         ;;


         -a|--add)
            fail "$1 must be the very first option (sorry)"
         ;;

         -b|--buildtool)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_BUILDTOOL="$1"
         ;;

         -c)
            OPTION_META="mulle-c/c-developer"
         ;;

         --clean)
            OPTION_CLEAN='YES'
         ;;

         --no-clean)
            OPTION_CLEAN='NO'
         ;;

         -objc)
            OPTION_META="foundation/objc-developer"
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            exekutor mkdir -p "$1" 2> /dev/null
            exekutor cd "$1" || fail "can't change to \"$1\""
            PURGE_PWD_ON_ERROR='YES'
         ;;

         -e|--extra)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_add_line "${OPTION_EXTRAS}" "$1"
            OPTION_EXTRAS="${RVAL}"
         ;;

         --existing)
            r_comma_concat "${OPTION_MARKS}" "no-demo"
            OPTION_MARKS="${RVAL}"
            # TODO: reinit by removing .mulle in conjunction
            # with reinit ?
         ;;

         --extension-file)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_EXTENSION_FILE="$1"
         ;;

         -f)
            MULLE_FLAG_MAGNUM_FORCE='YES'  ## do it again for extension cmd
         ;;

         -i|--init-flags)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_INIT_FLAGS="$1"
         ;;

         --if-missing)
            OPTION_IF_MISSING="$1"
         ;;

         -o|--oneshot)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_add_line "${OPTION_ONESHOTS}" "$1"
            OPTION_ONESHOTS="${RVAL}"
         ;;

         --oneshot-name)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            ONESHOT_FILENAME="$1"
            export ONESHOT_FILENAME
         ;;

         --oneshot-class)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            ONESHOT_CLASS="$1"
            export ONESHOT_CLASS
         ;;

         --oneshot-category)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            ONESHOT_CATEGORY="$1"
            export ONESHOT_CATEGORY
         ;;

         --template-header-file)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            TEMPLATE_HEADER_FILE="$1" # same name as in mulle-template
         ;;

         --template-footer-file)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            TEMPLATE_FOOTER_FILE="$1" # same name as in mulle-template
         ;;

         -m|--meta)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_META="$1"
         ;;

         -n|--name|--project-name)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            [ "$1" = 'DEFAULT' ] && fail "DEFAULT is not a usable project-name during init (rename to it later)"
            OPTION_NAME="$1"
         ;;

         # little hack
         --github|--github-user)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            GITHUB_USER="$1"
            export GITHUB_USER
         ;;

         --project-file|--upgrade-project-file)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_PROJECT_FILE="$1"
            OPTION_UPGRADE='YES'
            OPTION_BLURB='NO'
            # different marks, we upgrade project/demo/clobber!
            OPTION_MARKS="no-env,no-init,no-share,no-sourcetree"
            OPTION_INIT_ENV='NO'
         ;;

         --project-dialect)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_DIALECT="$1"
         ;;

         --project-language)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_LANGUAGE="$1"
         ;;

         --project-extensions)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_EXTENSIONS="$1"
         ;;

         # only used for one-shotting none project types
         --project-type)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            PROJECT_TYPE="$1"
            export PROJECT_TYPE
         ;;

         --project-source-dir|--source-dir)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            [ "$1" = 'DEFAULT' ] && fail "DEFAULT is not a usable \
PROJECT_SOURCE_DIR value during init (rename to it later)"

            OPTION_PROJECT_SOURCE_DIR="$1"
         ;;

         -r|--runtime)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_RUNTIME="$1"
         ;;

         -s|--style)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_ENV_STYLE="$1"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            OPTION_VENDOR="$1"
         ;;

         --comment-files)
            OPTION_COMMENT_FILES='YES'
         ;;

         --no-comment-files)
            OPTION_COMMENT_FILES='NO'
         ;;

         --no-env)
            OPTION_INIT_ENV='NO'
         ;;

         --no-post-init)
            OPTION_POST_INIT='NO'
         ;;

         --reinit)
            OPTION_REINIT='YES'
            OPTION_BLURB='NO'
            r_comma_concat "${OPTION_MARKS}" "no-demo"
            # r_comma_concat "${RVAL}" "no-project"
            # r_comma_concat "${RVAL}" "no-project-oneshot"
            OPTION_MARKS="${RVAL}"
            OPTION_INIT_ENV='YES'
         ;;

         --reflect)
            OPTION_REFLECT='YES'
         ;;

         --no-reflect)
            OPTION_REFLECT='NO'
         ;;

         --subproject)
            OPTION_INIT_TYPE="subproject"
         ;;

         --upgrade)
            OPTION_UPGRADE='YES'
            OPTION_BLURB='NO'
            r_comma_concat "${OPTION_MARKS}" "no-demo"
            r_comma_concat "${RVAL}" "no-project-oneshot"
            OPTION_MARKS="${RVAL}"
            OPTION_INIT_ENV='NO'
         ;;

         --no-blurb)
            OPTION_BLURB='NO'
         ;;

         # keep these down here, so they don't catch flags prematurely
         --allow-*)
            mark="${1:8}"
            sde::init::warn_if_unknown_mark "${mark}" "allow-mark"
            OPTION_MARKS="`sde::init::remove_from_marks "${OPTION_MARKS}" "no-${mark}"`"
         ;;

         --no-*)
            mark="${1:5}"
            sde::init::warn_if_unknown_mark "${mark}" "no-${mark}"
            r_comma_concat "${OPTION_MARKS}" "no-${mark}"
            OPTION_MARKS="${RVAL}"
         ;;

         --addiction-dir)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_escaped_doublequotes "$1"
            r_concat "${OPTION_DEFINES}" "'MULLE_CRAFT_ADDICTION_DIRNAME=\"$1\"'"
            OPTION_DEFINES="${RVAL}"
         ;;

         --dependency-dir)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_escaped_doublequotes "$1"
            r_concat "${OPTION_DEFINES}" "'MULLE_CRAFT_DEPENDENCY_DIRNAME=\"$1\"'"
            OPTION_DEFINES="${RVAL}"
         ;;

         --kitchen-dir)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_escaped_doublequotes "$1"
            r_concat "${OPTION_DEFINES}" "'MULLE_CRAFT_KITCHEN_DIRNAME=\"$1\"'"
            OPTION_DEFINES="${RVAL}"
         ;;

         --stash-dir)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_escaped_doublequotes "$1"
            r_concat "${OPTION_DEFINES}" "'MULLE_SOURCETREE_STASH_DIRNAME=\"$1\"'"
            OPTION_DEFINES="${RVAL}"
         ;;

         --source-dir)
            [ $# -eq 1 ] && sde::init::usage "Missing argument to \"$1\""
            shift

            r_escaped_doublequotes "$1"
            r_concat "${OPTION_DEFINES}" "'MULLE_PROJECT_DIR=\"$1\"'"
            OPTION_DEFINES="${RVAL}"
         ;;

         -*)
            sde::init::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   # export to environment
   sde::project::set_oneshot_variables "${ONESHOT_FILENAME}" "${ONESHOT_CLASS}" "${ONESHOT_CATEGORY}"
   sde::project::export_oneshot_environment "${ONESHOT_FILENAME}" "${ONESHOT_CLASS}" "${ONESHOT_CATEGORY}"

   # old version will be used for migrate
   local oldversion

   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      sde::init::r_get_old_version
      oldversion="${RVAL}"
   fi

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      # empty it now
      MULLE_VIRTUAL_ROOT=""
   fi

   if [ "${OPTION_ADD}" = 'YES' ]
   then
      # todo: make this nicer
      if [ -z "${MULLE_VIRTUAL_ROOT}" ]
      then
         RERUN='YES'
         return 32
      fi
   fi

   [ "${OPTION_REINIT}" = 'YES' -a "${OPTION_UPGRADE}" = 'YES' ] && \
      fail "--reinit and --upgrade exclude each other"

   log_verbose "Setup environment"

   # fake an environment so mulle-env gives us proper environment variables
   # remove temp file if done

   sde::init::protect_unprotect "Unprotect" "ug+w"

   ### BEGIN
      local tmp_file

      #
      # this is done so that mulle-env works, even if nothing is there
      #
      if [ ! -f ".mulle/share/env/environment.sh" ]
      then
         mkdir_if_missing ".mulle/share/env"
         exekutor touch ".mulle/share/env/environment.sh"
         tmp_file='YES'
      fi

      # get environments for some tools we manage share files and want
      # to upgrade
      eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sde` \
      && eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env match` \
      && eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env craft`  \
      && eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env monitor`  \
      && eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sourcetree`  \
      && eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env env` \
      || exit 1

      if [ "${tmp_file}" = 'YES' ]
      then
         remove_file_if_present ".mulle/share/env/environment.sh"
      fi

      if [ -d "${MULLE_SDE_SHARE_DIR}" -a "${OPTION_IF_MISSING}" = 'YES' ]
      then
         sde::init::protect_unprotect "Protect" "a-w"
         return 0
      fi

      # figure out a GITHUB user name for later
      sde::init::r_githubname
      GITHUB_USER="${RVAL}"

      log_debug "GITHUB_USER set to \"${GITHUB_USER}\""

      log_setting "MULLE_MATCH_ETC_DIR        : \"${MULLE_MATCH_ETC_DIR}\""
      log_setting "MULLE_MATCH_SHARE_DIR      : \"${MULLE_MATCH_SHARE_DIR}\""
      log_setting "MULLE_CRAFT_SHARE_DIR      : \"${MULLE_CRAFT_SHARE_DIR}\""
      log_setting "MULLE_SOURCETREE_SHARE_DIR : \"${MULLE_SOURCETREE_SHARE_DIR}\""
      log_setting "MULLE_SDE_ETC_DIR          : \"${MULLE_SDE_ETC_DIR}\""
      log_setting "MULLE_SDE_PROTECT_PATH     : \"${MULLE_SDE_PROTECT_PATH}\""
      log_setting "MULLE_SDE_SHARE_DIR        : \"${MULLE_SDE_SHARE_DIR}\""
      log_setting "MULLE_SDE_VAR_DIR          : \"${MULLE_SDE_VAR_DIR}\""
      log_setting "MULLE_VIRTUAL_ROOT         : \"${MULLE_VIRTUAL_ROOT}\""
      log_setting "GITHUB_USER                : \"${GITHUB_USER}\""
      log_setting "PROJECT_NAME               : \"${PROJECT_NAME}\""
      log_setting "PWD                        : \"${PWD}\""

      (
         if [ "${OPTION_ADD}" = 'YES' ]
         then
            sde::init::run_add "$@"
         else
            if [ "${OPTION_UPGRADE}" = 'YES' ]
            then
               if [ -z "${OPTION_PROJECT_FILE}" ]
               then
                  sde::init::run_upgrade "$@" || exit $?
               else
                  sde::init::run_upgrade_projectfile "$@" || exit $?
               fi
            else

               if [ "${OPTION_REINIT}" = 'YES' ]
               then
                  sde::init::run_reinit "$@" || exit $?
               else
                  sde::init::run "$@" || exit $?
               fi
            fi

            # we use the protected version of mulle-env here, because it doesn't
            # matter and we can circumvent a protection bug
            # we protect afterwards anyway
            #
            exekutor "${MULLE_ENV:-mulle-env}" \
                        --search-as-is \
                        -s \
                        -f \
                        ${MULLE_TECHNICAL_FLAGS} \
                     environment \
                        --scope "plugin" \
                        set "MULLE_SDE_INSTALLED_VERSION" \
                            "${MULLE_EXECUTABLE_VERSION}" || _internal_fail "failed env set"
         fi
      )
      rval=$?

      #
      # for these post processing steps load up the environment if present
      #
      if [ $rval -eq 0 ]
      then
      (
         if [ "${OPTION_UPGRADE}" = 'YES' -a "${oldversion}" != "${MULLE_EXECUTABLE_VERSION}" ]
         then
            # shellcheck source=src/mulle-sde-migrate.sh
            if [ -z "${MULLE_SDE_MIGRATE_SH}" ]
            then
               . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-migrate.sh"
            fi

            _log_info "Migrating from ${C_MAGENTA}${C_BOLD}${oldversion}${C_INFO} to \
${C_MAGENTA}${C_BOLD}${MULLE_EXECUTABLE_VERSION}${C_INFO}"
            sde::migrate::do "${oldversion}" "${MULLE_EXECUTABLE_VERSION}"  || exit 1
         fi

         # need -f option to clean "test" without warning
         if [ "${OPTION_CLEAN}" != 'NO' ]
         then
            exekutor "${MULLE_SDE:-mulle-sde}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        -N \
                        -f \
                     clean tidy || exit 1
         fi

         if [ "${OPTION_REFLECT}" = 'YES' ]
         then
            exekutor "${MULLE_SDE:-mulle-sde}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        -N \
                     reflect || exit 1
         fi
      )
      fi
      rval=$?
   ### END

   sde::init::protect_unprotect "Protect" "a-w"

   return $rval
}


sde::init::main()
{
   log_entry "sde::init::main" "$@"

   local RERUN='NO'

   sde::init::_main "$@"
   rval="$?"

   if [ "${RERUN}" = 'YES' ]
   then
      sde::exec_command_in_subshell "CD" init "$@"
   fi

   return $rval
}
