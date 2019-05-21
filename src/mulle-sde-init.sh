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
# Rebuild if files of certain extensions are modified
#
MULLE_SDE_INIT_SH="included"


sde_init_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   INIT_USAGE_NAME="${INIT_USAGE_NAME:-${MULLE_USAGE_NAME} init}"

   COMMON_OPTIONS="\
   --existing         : skip demo file installation.
   --no-sourcetree    : do not add dependencies and libraries to project
   -d <dir>           : directory to populate (working directory)
   -D <key>=<val>     : specify an environment variable
   -e <extra>         : specify extra extensions. Multiple uses are possible
   -m <meta>          : specify meta extensions
   -n <name>          : project name
   -o <oneshot>       : specify oneshot extensions. Multiple uses are possible"

   HIDDEN_OPTIONS="\
   --allow-<name>     : reenable specific pieces of initialization (see source)
   --no-<name>        : turn off specific pieces of initialization (see source)
   -b <buildtool>     : specify the buildtool extension to use
   -r <runtime>       : specify runtime extension to use
   -v <vendor>        : extension vendor to use (mulle-sde)
   --source-dir <dir> : specify source directory location (src)"

   cat <<EOF >&2
Usage:
   ${INIT_USAGE_NAME} [options] <type>

   List available extensions with \`mulle-sde extension show\`. Pick a meta
   extension to install. Choose a project type like "library", "executable"
   or "none".

   Example:

      mulle-sde init -d ./my-project -m mulle-sde/c-developer executable

   You can use \`mulle-sde extension add\` to add extra and oneshot extensions.
   at a later date.

Options:
EOF
   (
      echo "${COMMON_OPTIONS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
      then
         echo "${HIDDEN_OPTIONS}"
      fi
   ) | LC_ALL=C sort

   echo "      (\`${MULLE_USAGE_NAME} -v init help\` for more options)"
   exit 1
}


_copy_extension_dir()
{
   log_entry "_copy_extension_dir" "$@"

   local directory="$1"
   local overwrite="${2:-YES}"
   local writeprotect="${3:-NO}"

   if [ ! -d "${directory}" ]
   then
      log_debug "Nothing to copy as \"${directory}\" is not there"
      return
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      flags=-v
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten.
   #
   if [ "${overwrite}" = 'NO' ]
   then
      flags="${flags} -n"  # don't clobber
   fi

   log_fluff "Installing from \"${directory}\""

   local name

   r_fast_basename "${directory}"
   name="${RVAL}"

   local destination

   case "${name}" in
      etc|share)
         destination=".mulle"
      ;;

      *)
         fail "Unsupported destination directory \"${name}\""
      ;;
   esac

   # need L flag since homebrew creates relative links
   exekutor cp -RLa ${flags} "${directory}" "${destination}/"
}


_check_file()
{
   local filename="$1"

   if [ ! -f "${filename}" ]
   then
      log_debug "\"${filename}\" does not exist"
      return 1
   fi
   log_fluff "File \"${filename}\" found"
   return 0
}


_check_dir()
{
   local dirname="$1"

   if [ ! -d "${dirname}" ]
   then
      log_debug "\"${dirname}\" does not exist ($PWD)"
      return 1
   fi
   log_fluff "Directory \"${dirname}\" found"
   return 0
}


_copy_env_extension_dir()
{
   log_entry "_copy_env_extension_dir" "$@"

   local directory="$1"

   _check_dir "${directory}/share" || return 0

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      flags=-v
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten.
   #

   log_fluff "Installing from \"${directory}\""

   # need L flag since homebrew creates relative links
   exekutor cp -RLa ${flags} "${directory}/share" ".mulle/share/env/"
}


_append_to_motd()
{
   log_entry "_append_to_motd" "$@"

   local extensiondir="$1"

   _check_file "${extensiondir}/motd" || return 0

   local text

   text="`LC_ALL=C egrep -v '^#' "${extensiondir}/motd" `"
   if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
   then
      log_fluff "Append \"${extensiondir}/motd\" to motd"
      _MOTD="`add_line "${_MOTD}" "${text}" `"
   fi
}


_template_file_arguments()
{
   log_entry "_template_file_arguments" "$@"

   local projectdir="$1"
   local force="$2"
   local onlyfilename="$3"

   #
   # copy and expand stuff from project folder. Be extra careful not to
   # clobber project files, except if -f is given
   #
   _arguments="--embedded \
               --template-dir '${projectdir}' \
\
               --name '${PROJECT_NAME}' \
               --language '${PROJECT_LANGUAGE}' \
               --dialect '${PROJECT_DIALECT}' \
               --extensions '${PROJECT_EXTENSIONS}' \
               --source-dir '${PROJECT_SOURCE_DIR}'"

   if [ "${force}" = 'YES' ]
   then
      _arguments="${_arguments} -f"
   fi

   if [ ! -z "${onlyfilename}" ]
   then
      _arguments="${_arguments} --file '${onlyfilename}'"
   fi

   _arguments="${_arguments} ${OPTION_USERDEFINES}"
}


_copy_extension_template_files()
{
   log_entry "_copy_extension_template_files" "$@"

   local extensiondir="$1"; shift
   local subdirectory="$1"; shift
   local projecttype="$1"; shift
   local force="$1"; shift
   local onlyfilename="$1"; shift
   local file_seds="$1"; shift

   local projectdir

   projectdir="${extensiondir}/${subdirectory}/${projecttype}"

   _check_dir "${projectdir}" || return 0

   #
   # copy and expand stuff from project folder. Be extra careful not to
   # clobber project files, except if -f is given
   #
   log_fluff "Copying \"${projectdir}\" with template expansion"

   local _arguments

   _template_file_arguments "${projectdir}" "${force}" "${onlyfilename}"

   #
   # If force is set, we copy in the "incoming" order and overwrite whatever
   # is there.
   # If force is not set, the destination will not be overwritten so the
   # first file wins. In this case we reverse the order
   #
   if [ "${force}" = 'YES' ]
   then
      TEMPLATE_DIRECTORIES="${TEMPLATE_DIRECTORIES}
${_arguments}"
   else
      TEMPLATE_DIRECTORIES="${_arguments}
${TEMPLATE_DIRECTORIES}"
   fi
}


install_inheritfile()
{
   log_entry "install_inheritfile" "$@"

   local inheritfilename="$1" ; shift
   local projecttype="$1" ; shift
   local defaultexttype="$1" ; shift
   local marks="$1" ; shift
   local onlyfilename="$1"; shift
   local force="$1" ; shift

   local text

   text="`LC_ALL=C egrep -v '^#' "${inheritfilename}"`"

   log_debug "text: $text"

   #
   # read needs IFS set for each iteration, whereas
   # for only for the first iteration.
   # shell programming...
   #
   local line
   local depmarks

   while IFS=$'\n' read -r line
   do
      local extension
      local exttype
      local depmarks

      log_debug "read \"${line}\""

      case "${line}" in
         "")
            continue
         ;;

         *\;*)
            IFS=";" read extension exttype depmarks <<< "${line}"

            depmarks="`comma_concat "${marks}" "${depmarks}"`"
         ;;

         *)
            extension="${line}"
            depmarks="${marks}"
            exttype=
         ;;
      esac

      local extname
      local vendor

      vendor="${extension%%/*}"
      extname="${extension##*/}"

      exttype="${exttype:-${defaultexttype}}"
      if [ "${exttype}" = "meta" ]
      then
         fail "A meta extension mistakenly tries to inherit another meta \
extension (\"${inheritfilename}\")"
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
               fail "A \"${defaultexttype}\" extension tries to inherit \
\"${inheritfilename}\" - a \"${exttype}\" extension"
            fi
         ;;
      esac

      _install_extension "${projecttype}" \
                         "${exttype}" \
                         "${vendor}" \
                         "${extname}" \
                         "${marks}" \
                         "${onlyfilename}" \
                         "${force}" \
                         "$@"
   done <<< "${text}"
}


environment_mset_log()
{
   log_entry "environment_mset_log" "$@"

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


environmenttext_to_mset()
{
   log_entry "environmenttext_to_mset" "$@"

   local text="$1"

   # add lf for read
   text="${text}
"

   local line
   local comment

   IFS=$'\n'
   while read -r line
   do
      line="`tr -d '\0015' <<< "${line}"`"

      log_debug "line: ${line}"
      case "${line}" in
         *\#\#*)
            fail "environment line \"${line}\": comment must not contain ##"
         ;;

         *\\\n*)
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
         echo "'${line}'"
      else
         echo "'${line}##${comment}'"
         comment=
      fi
   done <<< "${text}"
   IFS="${DEFAULT_IFS}"
}


add_to_libraries()
{
   log_entry "add_to_libraries" "$@"

   local filename="$1"
   local projecttype="$2"

   if [ -z "${MULLE_SDE_LIBRARY_SH}" ]
   then
      # shellcheck source=src/mulle-sde-library.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-library.sh"
   fi

   if [ -e "${projecttype}-${filename}" ]
   then
      filename="${projecttype}-${filename}"
   fi

   local line

   IFS=$'\n'
   for line in `egrep -v '^#' "${filename}"`
   do
      IFS="${DEFAULT_IFS}"

      #
      # we "eval" the line so that install time environment variables
      # can be picked up
      #
      if [ ! -z "${line}" ]
      then
         MULLE_VIRTUAL_ROOT="${PWD}" \
         MULLE_SOURCETREE_FLAGS="-N ${MULLE_SOURCETREE_FLAGS}" \
            eval sde_library_add_main --if-missing ${line} || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


add_to_dependencies()
{
   log_entry "add_to_dependencies" "$@"

   local filename="$1"
   local projecttype="$2"

   if [ -z "${MULLE_SDE_DEPENDENCY_SH}" ]
   then
      # shellcheck source=src/mulle-sde-dependency.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-dependency.sh"
   fi

   if [ -e "${projecttype}-${filename}" ]
   then
      filename="${projecttype}-${filename}"
   fi

   local line

   IFS=$'\n'
   for line in `egrep -v '^#' "${filename}"`
   do
      IFS="${DEFAULT_IFS}"

      #
      # we "eval" the line so that install time environment variables
      # can be picked up
      #
      if [ ! -z "${line}" ]
      then
         MULLE_VIRTUAL_ROOT="`pwd -P`" \
         MULLE_SOURCETREE_FLAGS="-N ${MULLE_SOURCETREE_FLAGS}" \
            eval sde_dependency_add_main --if-missing ${line} || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


add_to_environment()
{
   log_entry "add_to_environment" "$@"

   local filename="$1"

   local environment
   local text

   _check_file "${filename}" || return 0

   log_debug "Environment: `cat "${filename}"`"

   # add an empty linefeed for read
   text="`cat "${filename}" `"
   environment="`environmenttext_to_mset "${text}"`" || exit 1
   if [ -z "${environment}" ]
   then
      return
   fi

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      environment_mset_log "${environment}"
   fi

   # remove lf for command line
   environment="`tr '\n' ' ' <<< "${environment}"`"
   MULLE_VIRTUAL_ROOT="`pwd -P`" \
      eval_exekutor "'${MULLE_ENV:-mulle-env}'" \
                           --search-nearest \
                           -s \
                           "${MULLE_TECHNICAL_FLAGS}" \
                           "${MULLE_ENV_FLAGS}" \
                           --no-protect \
                        environment \
                           --scope extension \
                           mset "${environment}" || exit 1
}


_add_to_tools()
{
   log_entry "_add_to_tools" "$@"

   local filename="$1"
   local os="$2"

   local line
   local quoted_args

   IFS=$'\n'
   for line in `egrep -v '^#' "${filename}"`
   do
      r_concat "${quoted_args}" "'${line}'"
      quoted_args="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"

   [ -z "${quoted_args}" ] && return

   log_verbose "Tools: \"${quoted_args}\" ${os:+ (}${os}${os:+)}"

   MULLE_VIRTUAL_ROOT="`pwd -P`" \
      eval_exekutor "'${MULLE_ENV:-mulle-env}'" \
                           --search-nearest \
                           "${MULLE_TECHNICAL_FLAGS}" \
                           "${MULLE_ENV_FLAGS}" \
                           --no-protect \
                        tool \
                           --os "'${os:-DEFAULT}'" \
                           --extension \
                           add \
                              --no-compile-link \
                              --if-missing \
                              --csv \
                              ${quoted_args}

   if [ $? -eq 1 ] # only 1 is error, 2 is ok
   then
      fail "Addition of tools \"${quoted_args}\" failed"
   fi
}


add_to_tools()
{
   log_entry "add_to_tools" "$@"

   local filename="$1"

   local os
   local file

   for file in "${filename}" "${filename}".*
   do
      if _check_file "${file}"
      then
         r_path_extension "${file}"
         os="${RVAL}"
         _add_to_tools "${file}" "${os}"
      fi
   done
}


run_init()
{
   log_entry "run_init" "$@"

   local executable="$1"
   local projecttype="$2"
   local vendor="$3"
   local extname="$4"
   local marks="$5"
   local force="$6"

   if [ ! -x "${executable}" ]
   then
      if _check_file "${executable}"
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
   log_info "Running init script \"${RVAL}\""

   eval_exekutor OPTION_UPGRADE="${OPTION_UPGRADE}" \
                 OPTION_REINIT="${OPTION_REINIT}" \
                 OPTION_INIT_TYPE="${OPTION_INIT_TYPE}" \
                 PROJECT_DIALECT="${PROJECT_DIALECT}" \
                 PROJECT_EXTENSIONS="${PROJECT_EXTENSIONS}" \
                 PROJECT_LANGUAGE="${PROJECT_LANGUAGE}" \
                 PROJECT_NAME="${PROJECT_NAME}" \
                 PROJECT_TYPE="${PROJECT_TYPE}" \
                 MULLE_VIRTUAL_ROOT="`pwd -P`" \
                     "${executable}" "${INIT_FLAGS}" "${flags}" \
                                                 "${auxflags}" \
                                                 --marks "'${marks}'" \
                                                 "${projecttype}" ||
      fail "init script \"${RVAL}\" failed"
}


is_disabled_by_marks()
{
   local marks="$1"; shift
   local description="$1"; shift

   # make sure all individual marks are enlosed by ','
   # now we can check against an , enclosed pattern

   while [ ! -z "$1" ]
   do
      case ",${marks}," in
         *,$1,*)
            log_fluff "${description} is disabled by \"$1\""
            return 0
         ;;
      esac

      # log_debug "\"${description}\" not disabled by \"$1\""
      shift
   done

   return 1
}


is_directory_disabled_by_marks()
{
   local marks="$1"
   local directory="$2"

   if ! _check_dir "${directory}"
   then
      return 0 # disabled
   fi

   is_disabled_by_marks "$@"
}


is_file_disabled_by_marks()
{
   local marks="$1"
   local filename="$2"

   if ! _check_file "${filename}"
   then
      return 0 # disabled
   fi

   is_disabled_by_marks "$@"
}


is_sourcetree_file_disabled_by_marks()
{
   local marks="$1"
   local filename="$2"
   local projecttype="$3"

   if ! _check_file "${filename}"
   then
      if ! _check_file "${projecttype}-${filename}"
      then
         return 0 # disabled
      fi
   fi

   is_disabled_by_marks "$@"
}


#
# sourcetree files can be different for libary projects
# and executable projects
#
install_sourcetree_files()
{
   log_entry "install_sourcetree_files" "$@"

   local extensiondir="$1"
   local vendor="$2"
   local extname="$3"
   local marks="$4"
   local projecttype="$5"

   if ! is_sourcetree_file_disabled_by_marks "${marks}" \
                                             "${extensiondir}/dependencies" \
                                             "no-sourcetree" \
                                             "no-sourcetree-${vendor}-${extname}" \
                                             "${projecttype}"
   then
      add_to_dependencies "${extensiondir}/dependencies" "${projecttype}"
   fi

   if ! is_sourcetree_file_disabled_by_marks "${marks}" \
                                             "${extensiondir}/libraries" \
                                             "no-sourcetree" \
                                             "no-sourcetree-${vendor}-${extname}" \
                                             "${projecttype}"
   then
      add_to_libraries "${extensiondir}/libraries" "${projecttype}"
   fi
}


assert_sane_extension_values()
{
   log_entry "assert_sane_extension_values" "$@"

   local exttype="$1"
   local vendor="$2"
   local extname="$3"

   case "${extname}" in
      "")
         fail "empty extension name"
      ;;
      *[^a-z-_0-9]*)
         fail "illegal extension name \"${extname}\" (lowercase only pls)"
      ;;
   esac
   case "${vendor}" in
      "")
         fail "empty vendor name"
      ;;
      *[^a-z-_0-9]*)
         fail "illegal vendor name \"${vendor}\" (lowercase only pls)"
      ;;
   esac
   case "${exttype}" in
      "")
         fail "empty extension type"
      ;;
      *[^a-z-_0-9]*)
         fail "illegal extension type \"${exttype}\" (lowercase only pls)"
      ;;
   esac
}


install_version()
{
   log_entry "install_version" "$@"

   local vendor="$1"
   local extname="$2"
   local extensiondir="$3"

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}/version/${vendor}"

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' ]
   then
      flags=-v
   fi

   exekutor cp ${flags} "${extensiondir}/version" \
                        "${MULLE_SDE_SHARE_DIR}/version/${vendor}/${extname}"
   return 0 # why ?
}


_copy_extension_template_directory()
{
   log_entry "_copy_extension_template_directory" "$@"

   local extensiondir="$1"; shift
   local subdirectory="$1"; shift
   local projecttype="$1"; shift
   local force="$1"; shift

   local first
   local second

   first="all"
   second="${projecttype}"

   _copy_extension_template_files "${extensiondir}" \
                                  "${subdirectory}" \
                                  "${first}" \
                                  "${force}" \
                                  "$@"

   _copy_extension_template_files "${extensiondir}" \
                                  "${subdirectory}" \
                                  "${second}" \
                                  "${force}" \
                                  "$@"
}


_delete_leaf_files_or_directories()
{
   log_entry "_delete_leaf_files_or_directories" "$@"

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

   directory="`physicalpath "${directory}"`"

   local i

   # https://stackoverflow.com/questions/1574403/list-all-leaf-subdirectories-in-linux
   IFS=$'\n'
   for i in `rexekutor find "${directory}" -mindepth 1 \
                                           -execdir sh \
                                           -c 'test -z "$(find "{}" -mindepth 1)" && echo ${PWD}/{}' \;`
   do
      IFS="${DEFAULT_IFS}"

      local relpath

      r_simplified_path "${i#${directory}/}"
      relpath="${RVAL}"

      if [ ! -d "${relpath}" ]
      then
         r_fast_basename "${relpath}"
         if [ "${RVAL}" != ".gitignore" ]
         then
            log_warning "Not deleting files at present (${relpath})"
            continue
         fi
         r_fast_dirname "${relpath}"
         relpath="${RVAL}"
      fi

      r_fast_basename "${relpath}"
      if [ "${RVAL}" != "share" ]
      then
         log_warning "Only deleting folders called \"share\" at present (${relpath})"
         continue
      fi

      rmdir_safer "${relpath}"
   done
   IFS="${DEFAULT_IFS}"
}


_delete_extension_template_directory()
{
   log_entry "_delete_extension_template_directory" "$@"

   local extensiondir="$1"
   local subdirectory="$2"
   local projecttype="$3"

   _delete_leaf_files_or_directories "${extensiondir}" "${subdirectory}" "${projecttype}"
   _delete_leaf_files_or_directories "${extensiondir}" "${subdirectory}" all
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
_install_extension()
{
   log_entry "_install_extension" "$@"

   local projecttype="$1"; shift
   local exttype="$1"; shift
   local vendor="$1"; shift
   local extname="$1"; shift
   local marks="$1"; shift
   local onlyfilename="$1"; shift
   local force="$1"; shift

   # user can turn off extensions by passing ""
   if [ -z "${extname}" ]
   then
      log_debug "Empty extension name, so nothing to do"
      return
   fi

   # just to catch idiots early
   assert_sane_extension_values "${exttype}" "${vendor}" "${extname}"

   if egrep -q -s "^${vendor}/${extname};" <<< "${_INSTALLED_EXTENSIONS}"
   then
      if ! [ "${OPTION_ADD}" = 'YES' -a "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         log_fluff "Extension \"${vendor}/${extname}\" is already installed"
         return
      fi
   else
      if [ "${exttype}" != "oneshot" ]
      then
         _INSTALLED_EXTENSIONS="`add_line "${_INSTALLED_EXTENSIONS}" "${vendor}/${extname};${exttype}"`"
      fi
   fi

   local extensiondir
   local searchpath

   if ! r_find_get_quoted_searchpath "${vendor}"
   then
      fail "Could not find any installed extensions of vendor \"${vendor}\"!!"
   fi
   searchpath="${RVAL}"

   if ! r_find_extension_in_searchpath "${vendor}" "${extname}" "${searchpath}"
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

   if ! _check_file "${extensiondir}/version"
   then
      fail "Extension \"${vendor}/${extname}\" is unversioned."
   fi

   case "${exttype}" in
      runtime)
         local tmp

         #
         # do this only once for the first runtime extension
         #
         if [ "${LANGUAGE_SET}" != 'YES' ]
         then
            if _check_file "${extensiondir}/language"
            then
               tmp="`egrep -v '^#' "${extensiondir}/language"`"
               IFS=";" read PROJECT_LANGUAGE PROJECT_DIALECT PROJECT_EXTENSIONS <<< "${tmp}"

               [ -z "${PROJECT_LANGUAGE}" ] && fail "missing language in \"${extensiondir}/language\""
               PROJECT_DIALECT="${PROJECT_DIALECT:-${PROJECT_LANGUAGE}}"
               if [ -z "${PROJECT_EXTENSIONS}" ]
               then
                  PROJECT_EXTENSIONS="`tr A-Z a-z <<< "${PROJECT_DIALECT}"`"
               fi

               log_fluff "Project language set to \"${PROJECT_DIALECT}\""
               log_fluff "Project dialect set to \"${PROJECT_DIALECT}\""
               log_fluff "Project extensions set to \"${PROJECT_EXTENSIONS}\""

               LANGUAGE_SET='YES'
           fi
         fi
      ;;

      meta|extra|oneshot|buildtool)
      ;;

      *)
         internal_fail "Unknown extension type \"${exttype}\""
      ;;
   esac

   if is_disabled_by_marks "${marks}" "${vendor}/${extname}" \
                                      "no-extension" \
                                      "no-extension/${vendor}/${extname}"
   then
      return
   fi

   local verb

   verb="Installing"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      verb="Upgrading"
   fi

   #
   # file is called inherit, so .gitignoring dependencies doesn't kill it
   #
   if ! is_file_disabled_by_marks "${marks}" \
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

      if ! is_disabled_by_marks "${marks}" "${filename}" \
                                           "no-inheritmarks" \
                                           "no-inheritmarks/${vendor}/${extname}"
      then
         if _check_file "${filename}"
         then
            log_fluff "${verb} dependencies for ${exttype} extension \"${vendor}/${extname}\""

            IFS=$'\n'
            for line in `egrep -v '^#' "${filename}"`
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

      install_inheritfile "${extensiondir}/inherit" \
                          "${projecttype}" \
                          "${exttype}" \
                          "${inheritmarks}" \
                          "${onlyfilename}" \
                          "${force}" \
                          "$@"
   fi


   if [ -z "${onlyfilename}" ]
   then
      log_verbose "${verb} \"${vendor}/${extname}\""
   fi

   local verb

   verb="Installed"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      verb="Upgraded"
   fi


   # install version first
   if [ "${exttype}" != "oneshot" -a -z "${onlyfilename}" ]
   then
      install_version "${vendor}" "${extname}" "${extensiondir}"
   fi

   # meta only inherits stuff and doesn't add (except version)
   if [ "${exttype}" = "meta" ]
   then
      if [ -z "${onlyfilename}" ]
      then
         log_info "${verb} ${exttype} extension \"${vendor}/${extname}\""
      fi
      return
   fi

   if [ -z "${onlyfilename}" ]
   then
      #
      # mulle-env stuff
      #
      if ! is_disabled_by_marks "${marks}" "${extensiondir}/environment" \
                                           "no-env" \
                                           "no-env/${vendor}/${extname}"
      then
         if [ "${projecttype}" != 'none' ]
         then
            add_to_environment "${extensiondir}/environment"
         else
            log_debug "${extensiondir}/environment not installed because project type is \"none\""
         fi

         add_to_tools "${extensiondir}/tool"

         _copy_env_extension_dir "${extensiondir}/env" ||
            fail "Could not copy \"${extensiondir}/env\""

         _append_to_motd "${extensiondir}"
      fi
   fi

   #
   # Project directory:
   #
   #  no-demo
   #  no-project
   #  no-clobber
   #
   if [ "${projecttype}" != 'none' -o "${exttype}" = 'extra' ]
   then
      if [ -z "${onlyfilename}" ]
      then
         # part of project really
         if ! is_directory_disabled_by_marks "${marks}" \
                                             "${extensiondir}/delete" \
                                             "no-delete" \
                                             "no-delete/${vendor}/${extname}"
         then
            _delete_extension_template_directory "${extensiondir}" \
                                                 "delete" \
                                                 "${projecttype}"
         fi
      fi

      if ! is_directory_disabled_by_marks "${marks}" \
                                          "${extensiondir}/demo" \
                                          "no-demo" \
                                          "no-demo/${vendor}/${extname}"
      then
         _copy_extension_template_directory "${extensiondir}" \
                                            "demo" \
                                            "${projecttype}" \
                                            "${force}" \
                                            "${onlyfilename}" \
                                            "$@"
      fi

      local subdirectory

      if [ -d "${extensiondir}/${OPTION_INIT_TYPE}" ]
      then
         subdirectory="${OPTION_INIT_TYPE}"
      else
         subdirectory="project"
      fi

      if ! is_directory_disabled_by_marks "${marks}" \
                                          "${extensiondir}/project" \
                                          "no-project" \
                                          "no-project/${vendor}/${extname}"
      then
         _copy_extension_template_directory "${extensiondir}" \
                                            "project" \
                                            "${projecttype}" \
                                            "${force}" \
                                            "${onlyfilename}" \
                                            "$@"
      fi

      #
      # the clobber folder is like project but may always overwrite
      # this is used for refreshing cmake/share and such, where the user should
      # not edit. A feature now obsoleted by "delete"
      #
      if ! is_directory_disabled_by_marks "${marks}" \
                                          "${extensiondir}/clobber" \
                                          "no-clobber" \
                                          "no-clobber/${vendor}/${extname}"
      then
         _copy_extension_template_directory "${extensiondir}" \
                                            "clobber" \
                                            "${projecttype}" \
                                            'YES' \
                                            "${onlyfilename}" \
                                            "$@"
      fi
   else
      log_warning "Not installing project or demo files, as project type is \"none\""
   fi

   if [ -z "${onlyfilename}" ]
   then
      #
      # used to install this only with project, but it was too surprising
      # turn it off with no-sourcetree
      #
      install_sourcetree_files "${extensiondir}" \
                               "${vendor}" \
                               "${extname}" \
                               "${marks}" \
                               "${projecttype}"
   fi


   if [ ! -z "${onlyfilename}" ]
   then
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
   if ! is_directory_disabled_by_marks "${marks}" \
                                       "${extensiondir}/share" \
                                       "no-share" \
                                       "no-share/${vendor}/${extname}"
   then
      _copy_extension_dir "${extensiondir}/share" 'YES' 'YES' ||
         fail "Could not copy \"${extensiondir}/share\""
   fi

   #
   # etc is also disabled by no-share
   #
   if ! is_directory_disabled_by_marks "${marks}" \
                                       "${extensiondir}/etc" \
                                       "no-share" \
                                       "no-share/${vendor}/${extname}"
   then
      _copy_extension_dir "${extensiondir}/etc" 'YES' 'NO' ||
         fail "Could not copy \"${extensiondir}/etc\""
   fi


   local executable

   executable="${extensiondir}/init"
   if ! is_file_disabled_by_marks "${marks}" \
                                  "${executable}" \
                                  "no-init" \
                                  "no-init/${vendor}/${extname}"
   then
      run_init "${executable}" "${projecttype}" \
                               "${exttype}" \
                               "${vendor}" \
                               "${extname}" \
                               "${marks}" \
                               "${force}"
   fi

   executable="${extensiondir}/init-${OPTION_INIT_TYPE}"
   if ! is_file_disabled_by_marks "${marks}" \
                                  "${executable}" \
                                  "no-init" \
                                  "no-init/${vendor}/${extname}"
   then
      run_init "${executable}" "${projecttype}" \
                               "${exttype}" \
                               "${vendor}" \
                               "${extname}" \
                               "${marks}" \
                               "${force}"
   fi

   log_verbose "${C_RESET_BOLD}${verb} ${exttype} extension \"${vendor}/${extname}\""
}


# Will exit on error. Always returns 0
install_extension()
{
   log_entry "install_extension" "$@"

#   local projecttype="$1"
#   local exttype="$2"
   local vendor="$3"
   local extname="$4"
#   local marks="$5"
   local onlyfilename="$6"
#   local force="$7"

   local TEMPLATE_DIRECTORIES

   _install_extension "$@"

   if [ -z "${MULLE_SDE_TEMPLATE_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-template.sh" || internal_fail "include fail"
   fi

   [ -z "${TEMPLATE_DIRECTORIES}" ] && return

   if [ -z "${onlyfilename}" ]
   then
      log_info "Installing project files for \"${vendor}/${extname}\""
   fi

   #
   # using the --embedded option, the template generator keeps state in
   # CONTENTS_SED and FILENAME_SED, since that is expensive to recalculate
   #
   (
      local CONTENTS_SED
      local FILENAME_SED

      log_debug "TEMPLATE_DIRECTORIES: ${TEMPLATE_DIRECTORIES}"

      set -o noglob ; IFS=$'\n'
      for arguments in ${TEMPLATE_DIRECTORIES}
      do
         IFS="${DEFAULT_IFS}"; set +o noglob

         if [ ! -z "${arguments}" ]
         then
            eval _template_main "${arguments}" || exit 1
         fi
      done
   ) || exit 1
}



install_motd()
{
   log_entry "install_motd" "$@"

   local text="$1"

   motdfile=".mulle/share/env/motd"

   if [ -z "${text}" ]
   then
      return
   fi

   # just clobber it
   local directory

   directory=".mulle/share/env"
   remove_file_if_present "${motdfile}"
   redirect_exekutor "${motdfile}" echo "${text}"
}


_install_simple_extension()
{
   log_entry "_install_simple_extension" "$@"

   local exttype="$1"; shift

   local extras="$1"
   local projecttype="$2"
   local marks="$3"
   local onlyfilename="$4"
   local force="$5"

   # optionally install "extra" extensions
   # f.e. a "git" extension could auto-init the project and create
   # a .gitignore file
   #
   #
   local extra
   local extra_vendor
   local extra_name

   IFS=$'\n'; set -o noglob
   for extra in ${extras}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

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

      install_extension "${projecttype}" \
                        "${exttype}" \
                        "${extra_vendor}" \
                        "${extra_name}" \
                        "${marks}" \
                        "${onlyfilename}" \
                        "${force}"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


# Will exit on error. Always returns 0
install_extra_extensions()
{
   log_entry "install_extra_extensions" "$@"

   _install_simple_extension "extra" "$@"
}


# Will exit on error. Always returns 0
install_oneshot_extensions()
{
   log_entry "install_oneshot_extensions" "$@"

   _install_simple_extension "oneshot" "$@"
}


#
# for reinit and .git it's nice to store the installed extensions in
# a separate file instead of the environment
#
recall_installed_extensions()
{
   log_entry "recall_installed_extensions" "$@"

   local EGREP

   # can sometimes happen, bail early then.
   EGREP="`command -v egrep`"
   if [ -z "${EGREP}" ]
   then
      fail "egrep not in PATH: ${PATH}"
   fi

   #
   # also read old format
   # use mulle-env so we can get at it from the outside
   #
   if _check_file "${OPTION_EXTENSION_FILE}"
   then
      exekutor "${EGREP}" -v '^#' < "${OPTION_EXTENSION_FILE}"
      return $?
   fi

   local value

   value="${MULLE_SDE_INSTALLED_EXTENSIONS}"
   if [ -z "${value}" ]
   then
      value="`rexekutor "${MULLE_ENV:-mulle-env}" \
                              --search-nearest \
                              ${MULLE_TECHNICAL_FLAGS} \
                              ${MULLE_ENV_FLAGS} \
                              --no-protect \
                           environment \
                              --scope extension \
                              get MULLE_SDE_INSTALLED_EXTENSIONS`"
   fi

   if [ ! -z "${value}" ]
   then
      echo "${value}" \
         | sed -e "s/--\\([a-z]*\\)\\ '\\([^']*\\)'/\\2;\\1,/g" \
         | tr ',' '\n'
   fi
}


memorize_installed_extensions()
{
   log_entry "memorize_installed_extensions" "$@"

   local extensions="$1"

   local filename

   filename="${MULLE_SDE_SHARE_DIR}/extension"

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   redirect_exekutor "${filename}" echo "${extensions}" || exit 1
}


env_set_var()
{
   local key="$1"
   local value="$2"
   local scope="${3:-extension}"

   log_verbose "Environment: ${key}=\"${value}\""

   exekutor "${MULLE_ENV:-mulle-env}" \
                     --search-nearest \
                     -s \
                     ${MULLE_ENV_FLAGS} \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --no-protect \
                  environment \
                     --scope "${scope}" \
                     set "${key}" "${value}" || internal_fail "failed env set"
}


#
# also pre-compute variations needed for scripts
#
memorize_project_name()
{
   log_entry "memorize_project_name" "$@"

   local PROJECT_NAME="$1"

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"      || return 1
   fi
   if [ -z "${MULLE_SDE_PROJECTNAME_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-projectname.sh" || internal_fail "missing file"
   fi

   set_projectname_variables "${PROJECT_NAME}"

   env_set_var PROJECT_NAME                "${PROJECT_NAME}" "project"
   env_set_var PROJECT_IDENTIFIER          "${PROJECT_IDENTIFIER}" "project"
   env_set_var PROJECT_DOWNCASE_IDENTIFIER "${PROJECT_DOWNCASE_IDENTIFIER}" "project"
   env_set_var PROJECT_UPCASE_IDENTIFIER   "${PROJECT_UPCASE_IDENTIFIER}" "project"
}


install_extensions()
{
   log_entry "install_extensions" "$@"

   local marks="$1"
   local onlyfilename="$2"
   local force="$3"

   [ -z "${PROJECT_TYPE}" ] && internal_fail "missing PROJECT_TYPE"
   [ -z "${PROJECT_NAME}" ] && internal_fail "missing PROJECT_NAME"

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
         shopt -s nullglob
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
   install_extension "${PROJECT_TYPE}" \
                     "meta" \
                     "${meta_vendor}" \
                     "${meta_name}" \
                     "${marks}" \
                     "${onlyfilename}" \
                     "${force}"
   install_extension "${PROJECT_TYPE}" \
                     "runtime" \
                     "${runtime_vendor}" \
                     "${runtime_name}" \
                     "${marks}" \
                     "${onlyfilename}" \
                     "${force}"
   install_extension "${PROJECT_TYPE}" \
                     "buildtool" \
                     "${buildtool_vendor}" \
                     "${buildtool_name}" \
                     "${marks}" \
                     "${onlyfilename}" \
                     "${force}"

   install_extra_extensions "${OPTION_EXTRAS}" \
                            "${PROJECT_TYPE}" \
                            "${marks}" \
                            "${onlyfilename}" \
                            "${force}"

   install_oneshot_extensions "${OPTION_ONESHOTS}" \
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
   # also remember version and given project name, which we may need to
   # create files later after init
   #
   env_set_var "MULLE_SDE_INSTALLED_VERSION" "${MULLE_EXECUTABLE_VERSION}" "plugin"

   memorize_installed_extensions "${_INSTALLED_EXTENSIONS}"
}


install_project()
{
   log_entry "install_project" "$@"

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
   PROJECT_NAME="${projectname}"
   if [ -z "${PROJECT_NAME}" ]
   then
      r_fast_basename "${PWD}"
      PROJECT_NAME="${RVAL}"
   fi

   PROJECT_LANGUAGE="${language}"
   PROJECT_DIALECT="${dialect}"
   PROJECT_EXTENSIONS="${extensions}"

   # check that PROJECT_NAME looks usable as an identifier
   case "${PROJECT_NAME}" in
      *\ *)
         fail "Project name  \"${PROJECT_NAME}\" contains spaces"
      ;;

      [a-zA-Z_]*)
      ;;

      *)
         fail "Project name \"${PROJECT_NAME}\" must start with a letter or underscore"
      ;;
   esac

   #
   # the project language is actually determined by the runtime
   # extension
   #
   PROJECT_SOURCE_DIR="${projectsourcedir:-src}"
   PROJECT_TYPE="${projecttype}"

   local has_project_scope

   #
   # MEMO: we can only memorize if the scope project is known
   #
   local scopes

   scopes="`rexekutor mulle-env -s environment scopes --all`"
   log_debug "scopes: ${scopes}"

   if find_line "${scopes}" "project"
   then
      has_project_scope='YES'
      # put these first, so extensions can draw on these in their definitions
      #
      memorize_project_name "${PROJECT_NAME}"

      env_set_var PROJECT_TYPE "${PROJECT_TYPE}" "project"

      if [ "${PROJECT_TYPE}" != "none" ]
      then
         env_set_var PROJECT_SOURCE_DIR "${PROJECT_SOURCE_DIR}" "project"
      fi
   else
      log_warning "Can not save project settings as the environment style is not
\"mulle\" and \"project\" is not defined in ¸\`mulle-env environment scopes --all\`"
   fi

   local _MOTD
   local _INSTALLED_EXTENSIONS

   _MOTD=""

   if [ -z "${onlyfilename}" ]
   then
      log_info "Installing project extensions in ${C_RESET_BOLD}${PWD}${C_INFO}"
   fi

   install_extensions "${marks}" "${onlyfilename}" "${force}"

   if [ ! -z "${onlyfilename}" ]
   then
      return
   fi

   #
   # setup the initial environment-global.sh (if missing) with some
   # values that the user may want to edit
   #
   if [ "${has_project_scope}" = 'YES' ]
   then
      [ ! -z "${PROJECT_LANGUAGE}" ]    && env_set_var PROJECT_LANGUAGE "${PROJECT_LANGUAGE}" "project"
      [ ! -z "${PROJECT_DIALECT}" ]     && env_set_var PROJECT_DIALECT "${PROJECT_DIALECT}" "project"
      [ ! -z "${PROJECT_EXTENSIONS}" ]  && env_set_var PROJECT_EXTENSIONS "${PROJECT_EXTENSIONS}" "project"
   fi

   if [ -z "${_INSTALLED_EXTENSIONS}" -a "${OPTION_UPGRADE}" != 'YES' ]
   then
      case "${OPTION_ENV_STYLE}" in
         */tight|*/relax|*/restrict)
            log_warning "No extensions were installed and the style is ${OPTION_ENV_STYLE}.
${C_INFO}Check the available command line tools with:
   ${C_RESET_BOLD}mulle-sde tool list${C_INFO}
add more with:
   ${C_RESET_BOLD}mulle-sde add <toolname>${C_INFO}"
         ;;
      esac
   fi

   case ",${marks}," in
      *',no-motd,'*)
         return 0
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

   install_motd "${_MOTD}"
}


add_environment_variables()
{
   log_entry "add_environment_variables" "$@"

   local defines="$1"

   [ -z "${defines}" ] && return 0

   if [ "${OPTION_UPGRADE}" = 'YES' -a "${_INFOED_ENV_RELOAD}" != 'YES' ]
   then
      _INFOED_ENV_RELOAD='YES'
      log_warning "Use ${C_RESET_BOLD}mulle-env-reload${C_INFO} to get environment \
changes into your subshell"
   fi

   MULLE_VIRTUAL_ROOT="`pwd -P`" \
      eval_exekutor "'${MULLE_ENV:-mulle-env}'" \
                           --search-nearest \
                           "${MULLE_ENV_FLAGS}" \
                           "${MULLE_TECHNICAL_FLAGS}" \
                           --no-protect \
                        environment \
                           --scope extension \
                           mset "${defines}" || exit 1
}


__sde_init_add()
{
   log_entry "__sde_init_add" "$@"

   [ "$#" -eq 0 ] || sde_init_usage "extranous arguments \"$*\""

   [ "${OPTION_REINIT}" = 'YES' -o "${OPTION_UPGRADE}" = 'YES' ] && \
      fail "--add and --reinit/--upgrade exclude each other"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" ]
   then
      fail "You must init first, before you can add an 'extra' extension"
   fi

   if [ ! -z "${OPTION_RUNTIME}" -o \
        ! -z "${OPTION_BUILDTOOL}" -o \
        ! -z "${OPTION_META}" ]
   then
      fail "Only 'extra' extensions can be added"
   fi

   if [ -z "${OPTION_EXTRAS}" -a -z "${OPTION_ONESHOTS}" ]
   then
      fail "You must specify an extra or oneshot extension to be added"
   fi

   [ -z "${PROJECT_TYPE}" ] && fail "PROJECT_TYPE is not defined"

   add_environment_variables "${OPTION_DEFINES}"

   local _INSTALLED_EXTENSIONS

   _INSTALLED_EXTENSIONS="`recall_installed_extensions`" || exit 1
   log_debug "Installed extensions: ${_INSTALLED_EXTENSIONS}"

   if ! install_extra_extensions "${OPTION_EXTRAS}" \
                                 "${PROJECT_TYPE}" \
                                 "${OPTION_MARKS}" \
                                 "" \
                                 "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      return 1
   fi

   memorize_installed_extensions "${_INSTALLED_EXTENSIONS}"

   install_oneshot_extensions "${OPTION_ONESHOTS}" \
                              "${PROJECT_TYPE}" \
                              "${OPTION_MARKS}" \
                              "" \
                              "${MULLE_FLAG_MAGNUM_FORCE}"
}


mset_quoted_env_line()
{
   local line="$1"

   local key
   local value

   key="${line%%=*}"
   value="${line#*=}"

   case "${value}" in
      \"*\")
         echo "${line}"
      ;;

      *)
         echo "${key}=\"${value}\""
      ;;
   esac
}


__get_installed_extensions()
{
   log_entry "__get_installed_extensions" "$@"

   local extensions

   if [ -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      log_warning "Last upgrade failed. Restoring the last configuration."
      rmdir_safer "${MULLE_SDE_SHARE_DIR}" &&
      exekutor mv "${MULLE_SDE_SHARE_DIR}.old" "${MULLE_SDE_SHARE_DIR}" &&
      rmdir_safer "${MULLE_SDE_SHARE_DIR}.old"
   fi

   extensions="`recall_installed_extensions`" || exit 1
   if [ -z "${extensions}" ]
   then
      log_fluff "No extensions found"
      return 1
   fi

   log_debug "Found extension: ${extensions}"

   local extension

   IFS=$'\n'; set -o noglob
   for extension in ${extensions}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

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
            OPTION_EXTRAS="`add_line "${OPTION_EXTRAS}" "${extension%;*}" `"
            log_debug "Reinit extra extension: ${extension%;*}"
         ;;

         *\;*)
            log_warning "Garbled memorized extension \"${extension}\""
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


remove_from_marks()
{
   log_entry "remove_from_marks" "$@"

   local marks="$1"
   local mark="$2"

   local i
   local newmarks=""

   IFS=","; set -o noglob
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ "${mark}" != "${i}" ]
      then
         r_comma_concat "${newmarks}" "${i}"
         newmarks="${RVAL}"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   echo "${newmarks}"
}


#
# call this before__get_installed_extensions
#
read_project_environment()
{
   log_entry "read_project_environment" "$@"

   if [ -f ".mulle/share/env/environment-project.sh" ]
   then
      log_fluff "Reading project settings"
      . ".mulle/share/env/environment-project.sh"
   fi

   if [ -z "${PROJECT_TYPE}" ]
   then
      if [ -f ".mulle/share/env.old/environment-project.sh" ]
      then
         log_warning "Reading OLD project settings from \".mulle/share/env.old/environment-project.sh\""
         . ".mulle/share/env/environment-project.sh"
      fi
   fi

   [ -z "${PROJECT_TYPE}" ] && \
     fail "Could not find required PROJECT_TYPE in environment. \
If you reinited the environment. Try:
   ${C_RESET}${C_BOLD}mulle-sde environment --project set PROJECT_TYPE library"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "PROJECT_DIALECT=\"${PROJECT_DIALECT}\""
      log_trace2 "PROJECT_EXTENSIONS=\"${PROJECT_EXTENSIONS}\""
      log_trace2 "PROJECT_LANGUAGE=\"${PROJECT_LANGUAGE}\""
      log_trace2 "PROJECT_NAME=\"${PROJECT_NAME}\""
      log_trace2 "PROJECT_SOURCE_DIR=\"${PROJECT_SOURCE_DIR}\""
      log_trace2 "PROJECT_TYPE=\"${PROJECT_TYPE}\""
   fi
}


run_user_post_init_script()
{
   log_entry "run_user_post_init_script" "$@"

   local scriptfile

   scriptfile="${HOME}/bin/post-mulle-sde-init"
   if [ ! -e "${scriptfile}" ]
   then
      log_fluff "\"${scriptfile}\" does not exist"
      return
   fi

   if [ ! -x "${scriptfile}" ]
   then
      fail "\"${scriptfile}\" exists but is not executable"
   fi

   log_warning "Running post-init script \"${scriptfile}\""
   log_info "You can suppress this behavior with --no-post-init"

   exekutor "${scriptfile}" "$@" || exit 1
}


warn_if_unknown_mark()
{
   log_entry "warn_if_unknown_mark" "$@"

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


__sde_init_main()
{
   log_entry "__sde_init_main" "$@"

   if [ "${OPTION_REINIT}" = 'YES' -o "${OPTION_UPGRADE}" = 'YES' ]
   then
      if [ -z "${OPTION_PROJECT_FILE}" ]
      then
         rexekutor "${MULLE_ENV:-mulle-env}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           ${MULLE_ENV_FLAGS} \
                           --no-protect \
                           upgrade || exit 1
      fi

      if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
      then
         fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
      fi

      read_project_environment

      if ! __get_installed_extensions
      then
         case "${PROJECT_TYPE}" in
            "none")
               if [ "${PWD}" != "${MULLE_USER_PWD}" ]
               then
                  log_verbose "Nothing to upgrade in ${C_RESET_BOLD}${PWD#${MULLE_USER_PWD}/}${C_VERBOSE}, as no extensions have been installed."
               else
                  log_verbose "Nothing to upgrade, as no extensions have been installed."
               fi
               return 0
            ;;
         esac

         fail "Could not retrieve previous extension information.
This may hurt, but you have to init again."
      fi
   else
      [ $# -eq 0 ] && sde_init_usage "Missing project type"
      [ $# -eq 1 ] || sde_init_usage "Superflous arguments \"$*\""

      PROJECT_TYPE="$1"
   fi

   case "${PROJECT_TYPE}" in
      "")
         fail "Project type is empty"
      ;;

      executable|extension|framework|library|none|unknown)
      ;;

      show)
         [ -z "${MULLE_SDE_EXTENSION_SH}" ] && \
            . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh"
         sde_extension_show_main meta
         return $?
      ;;

      *)
         if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
         then
            fail "\"${PROJECT_TYPE}\" is not a standard project type.
${C_INFO}Use -f to use \"${PROJECT_TYPE}\""
         fi
      ;;
   esac

   #
   # An upgrade is an "inplace" refresh of the extensions
   #
   if [ "${OPTION_REINIT}" != 'YES' -a \
        "${OPTION_UPGRADE}" != 'YES' -a \
        -d "${MULLE_SDE_SHARE_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         if _check_file "${MULLE_SDE_SHARE_DIR}/.init"
         then
            fail "There is already a ${MULLE_SDE_SHARE_DIR} folder in \"$PWD\". \
It looks like an init gone bad."
         fi

         fail "There is already a ${MULLE_SDE_SHARE_DIR} folder in \"$PWD\".
${C_INFO}In case you wanted to upgrade it:
${C_RESET_BOLD}   mulle-sde upgrade"
      fi
   fi

   local purge_mulle_on_error='NO'

   if [ ! -d ".mulle" ]
   then
      purge_mulle_on_error='YES'
   fi

   #
   # if we init env now, then extensions can add environment
   # variables and tools
   #
   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      local flags

      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
      then
         flags="-f"
      fi

      exekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} \
                     ${flags} \
                     --no-protect \
                     --style "${OPTION_ENV_STYLE}" \
                  init \
                     --no-blurb
      case $? in
         0)
         ;;

         2)
            log_fluff "mulle-env warning noted, but ignored"
         ;;

         *)
            if [ "${purge_mulle_on_error}" = 'YES' -a -d .mulle ]
            then
               internal_fail "mulle-env should have cleaned up after itself after init failure"
            fi
            exit 1
         ;;
      esac
   else
      if [ "${OPTION_UPGRADE}" = 'YES' -a -z "${OPTION_PROJECT_FILE}" ]
      then
         log_fluff "Erasing share/env contents to be written by upgrade anew"

         if ! is_disabled_by_marks "${marks}" "no-env"
         then
            # should be part of mulle-env to clear a scope
            remove_file_if_present ".mulle/share/env/environment-extension.sh"

            local file

            shopt -s nullglob
            for file in ".mulle/share/env/tool-extension" ".mulle/share/env/tool-extension".*
            do
               shopt -u nullglob
               remove_file_if_present "${file}"
            done
            shopt -u nullglob
         fi
      else
         log_debug "Not touching files as OPTION_UPGRADE is ${OPTION_UPGRADE} and OPTION_PROJECT_FILE is ${OPTION_PROJECT_FILE}"
      fi
   fi

   local purge_sde_on_error='NO'
   local purge_env_on_error='NO'
   local purge_sourcetree_on_error='NO'

   add_environment_variables "${OPTION_DEFINES}"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" ]
   then
      purge_sde_on_error='YES'
   fi
   if [ ! -d ".mulle/share/env" ]
   then
      purge_env_on_error='YES'
   fi
   if [ ! -d ".mulle/etc/sourcetree" ]
   then
      purge_sourcetree_on_error='YES'
   fi

   if [ -z "${OPTION_PROJECT_FILE}" ]
   then
      mkdir_if_missing "${MULLE_SDE_SHARE_DIR}" || exit 1
      redirect_exekutor "${MULLE_SDE_SHARE_DIR}/.init" echo "Start init `date` in $PWD on ${MULLE_HOSTNAME}"

      #
      # always wipe these for clean upgrades
      # except if we are just updating a specific project file
      # (i.e. CMakeLists.txt). Keep "extension" file around in case something
      # goes wrong. Also temporarily keep old share
      #
      rmdir_safer "${MULLE_SDE_SHARE_DIR}.old"
      if [ -d "${MULLE_SDE_SHARE_DIR}" ]
      then
         exekutor mv "${MULLE_SDE_SHARE_DIR}" "${MULLE_SDE_SHARE_DIR}.old"
      fi
      rmdir_safer "${MULLE_SDE_VAR_DIR}"
   fi

   # rmdir_safer ".mulle-env"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      if ! ( install_extensions "${OPTION_MARKS}" \
                                "${OPTION_PROJECT_FILE}" \
                                "${MULLE_FLAG_MAGNUM_FORCE}"
      )
      then
         if [ ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
         then
            fail "Things went really bad, can't restore old configuration"
         fi

         log_info "The upgrade failed. Restoring old configuration."
         rmdir_safer "${MULLE_SDE_SHARE_DIR}"
         exekutor mv "${MULLE_SDE_SHARE_DIR}.old" "${MULLE_SDE_SHARE_DIR}"
         remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"
         exit 1
      fi

      # upgrade identifiers if missing
      #
      # TODO: compare old version to new, and run custom pre/postscripts
      #
      memorize_project_name "${PROJECT_NAME}"

      if [ -z "${OPTION_PROJECT_FILE}" ]
      then
         #
         # repair patternfiles as a "bonus" with -add option
         #
         exekutor "${MULLE_MATCH:-mulle-match}" ${MULLE_TECHNICAL_FLAGS} \
                    ${MULLE_MATCH_FLAGS} patternfile repair --add
      fi
   else
      if ! (
         install_project "${OPTION_NAME:-${PROJECT_NAME}}" \
                         "${PROJECT_TYPE}" \
                         "${OPTION_PROJECT_SOURCE_DIR:-${PROJECT_SOURCE_DIR}}" \
                         "${OPTION_MARKS}" \
                         "${OPTION_PROJECT_FILE}" \
                         "${MULLE_FLAG_MAGNUM_FORCE}" \
                         "${OPTION_LANGUAGE}"  \
                         "${OPTION_DIALECT}"  \
                         "${OPTION_EXTENSIONS}"
      )
      then
         log_error "Cleaning up after error"

         if [ "${purge_mulle_on_error}" = 'YES' ]
         then
            rmdir_safer ".mulle"
         else
            if [ "${purge_sde_on_error}" = 'YES' ]
            then
               rmdir_safer "${MULLE_SDE_SHARE_DIR}"
               rmdir_safer "${MULLE_SDE_ETC_DIR}"
            fi
            if [ "${purge_env_on_error}" = 'YES' ]
            then
               rmdir_safer ".mulle/share/env"
               rmdir_safer ".mulle/etc/env"
            fi
            if [ "${purge_sourcetree_on_error}" = 'YES' ]
            then
               rmdir_safer ".mulle/share/sourcetree"
               rmdir_safer ".mulle/etc/sourcetree"
            fi
         fi
         if [ "${PURGE_PWD_ON_ERROR}" = 'YES' ]
         then
            rmdir_safer "${PWD}"
         fi
         exit 1
      fi
   fi

   if [ -z "${OPTION_PROJECT_FILE}" ]
   then
      rmdir_safer "${MULLE_SDE_SHARE_DIR}.old"
      remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"
      # only remove if empty
      exekutor rmdir "${MULLE_SDE_SHARE_DIR}" 2>  /dev/null
   fi

   if [ "${OPTION_INIT_ENV}" = 'YES'  ]
   then
      if [ "${OPTION_INIT_TYPE}" = "subproject" ]
      then
         exekutor "${MULLE_ENV:-mulle-env}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        ${MULLE_ENV_FLAGS} \
                        --no-protect \
                     tweak \
                        climb
      fi

      if [ "${OPTION_POST_INIT}" = 'YES' ]
      then
         run_user_post_init_script "${PROJECT_LANGUAGE}" \
                                   "${PROJECT_DIALECT}" \
                                   "${PROJECT_TYPE}"
      fi

      if [ -z "${OPTION_PROJECT_FILE}" ]
      then
         if [ "${OPTION_BLURB}" = 'YES' ]
         then
            log_info "Enter the environment:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} \"${PWD#${MULLE_USER_PWD}/}\"${C_INFO}"
         fi
      fi
   fi
}


###
### parameters and environment variables
###
_sde_init_main()
{
   log_entry "_sde_init_main" "$@"

   local OPTION_NAME
   local OPTION_EXTRAS
   local OPTION_ONESHOTS
   local OPTION_COMMON="sde"
   local OPTION_META=""
   local OPTION_RUNTIME=""
   local OPTION_BUILDTOOL=""
   local OPTION_VENDOR="mulle-sde"
   local OPTION_INIT_ENV='YES'
   local OPTION_ENV_STYLE="mulle/relax"
   local OPTION_BLURB='YES'
   local OPTION_TEMPLATE_FILES='YES'
   local OPTION_INIT_FLAGS
   local OPTION_MARKS=""
   local OPTION_DIALECT
   local OPTION_EXTENSIONS
   local OPTION_LANGUAGE
   local OPTION_DEFINES
   local OPTION_UPGRADE
   local OPTION_ADD
   local OPTION_REINIT
   local OPTION_EXTENSION_FILE=".mulle/share/sde/extension"
   local OPTION_PROJECT_FILE
   local OPTION_PROJECT_SOURCE_DIR
   local OPTION_POST_INIT='YES'
   local OPTION_UPGRADE_SUBPROJECTS
   local PURGE_PWD_ON_ERROR='NO'

   local OPTION_INIT_TYPE="project"

   local line
   local mark

   #
   # handle options
   #
   while :
   do
      case "$1" in
         -h|--help|help)
            sde_init_usage
         ;;

         -D?*)
            line="`mset_quoted_env_line "${1:2}"`"
            OPTION_DEFINES="`concat "${OPTION_DEFINES}" "'${line}'" `"
         ;;

         -D)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            line="`mset_quoted_env_line "$1"`"
            OPTION_DEFINES="`concat "${OPTION_DEFINES}" "'${line}'" `"
         ;;

         -a|--add)
            OPTION_ADD='YES'
         ;;

         -b|--buildtool)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_BUILDTOOL="$1"
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            exekutor mkdir -p "$1" 2> /dev/null
            exekutor cd "$1" || fail "can't change to \"$1\""
            PURGE_PWD_ON_ERROR='YES'
         ;;

         -e|--extra)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_EXTRAS="`add_line "${OPTION_EXTRAS}" "$1" `"
         ;;

         --existing)
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "no-demo"`"
            # TODO: reinit by removing .mulle in conjunction
            # with reinit ?
         ;;

         --extension-file)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_EXTENSION_FILE="$1"
         ;;

         -i|--init-flags)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_INIT_FLAGS="$1"
         ;;

         --oneshot-name)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            ONESHOT_NAME="$1"
            export ONESHOT_NAME
         ;;

         -o|--oneshot)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_ONESHOTS="`add_line "${OPTION_ONESHOTS}" "$1" `"
         ;;

         -m|--meta)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_META="$1"
         ;;

         -n|--name|--project-name)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_NAME="$1"
         ;;

         # little hack
         --project-file|--upgrade-project-file)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_PROJECT_FILE="$1"
            OPTION_UPGRADE='YES'
            OPTION_BLURB='NO'
            # different marks, we upgrade project/demo/clobber!
            OPTION_MARKS="no-env,no-init,no-share,no-sourcetree"
            OPTION_INIT_ENV='NO'
         ;;

         --project-dialect)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_DIALECT="$1"
         ;;

         --project-language)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_LANGUAGE="$1"
         ;;

         --project-extensions)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_EXTENSIONS="$1"
         ;;

         # only used for one-shotting none project types
         --project-type)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            PROJECT_TYPE="$1"
         ;;

         --project-source-dir|--source-dir)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_PROJECT_SOURCE_DIR="$1"
         ;;

         -r|--runtime)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_RUNTIME="$1"
         ;;

         -s|--style)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_ENV_STYLE="$1"
         ;;

         --subproject)
            OPTION_INIT_TYPE="subproject"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_VENDOR="$1"
         ;;

         --reinit)
            OPTION_REINIT='YES'
            OPTION_BLURB='NO'
            r_comma_concat "${OPTION_MARKS}" "no-demo"
            r_comma_concat "${RVAL}" "no-project"
            r_comma_concat "${RVAL}" "no-sourcetree"
            OPTION_MARKS="${RVAL}"
            OPTION_INIT_ENV='NO'
         ;;

         --upgrade)
            OPTION_UPGRADE='YES'
            OPTION_BLURB='NO'
            r_comma_concat "${OPTION_MARKS}" "no-demo"
            r_comma_concat "${RVAL}" "no-sourcetree"
            OPTION_MARKS="${RVAL}"
            OPTION_INIT_ENV='NO'
         ;;

         --no-blurb)
            OPTION_BLURB='NO'
         ;;

         --no-env)
            OPTION_INIT_ENV='NO'
         ;;

         --no-post-init)
            OPTION_POST_INIT='NO'
         ;;

         --no-*)
            mark="${1:5}"
            warn_if_unknown_mark "${mark}" "no-${mark}"
            r_comma_concat "${OPTION_MARKS}" "no-${mark}"
            OPTION_MARKS="${RVAL}"
         ;;

         --allow-*)
            mark="${1:8}"
            warn_if_unknown_mark "${mark}" "allow-mark"
            OPTION_MARKS="`remove_from_marks "${OPTION_MARKS}" "no-${mark}"`"
         ;;

         -*)
            sde_init_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done


   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      # empty it now
      MULLE_VIRTUAL_ROOT=""
   fi

# MEMO: oneshot extensions are bad. Create mulle-sde ´file' command to
#       add templated files
#
#   #
#   # Special: one-shot extensions can be installed anywhere.
#   # No project or environment required or even setup
#   #
#   if [ "${OPTION_UPGRADE}" != 'YES' -a \
#        ! -z "${OPTION_ONESHOTS}" -a \
#        -z "${OPTION_META}" -a \
#        -z "${OPTION_RUNTIME}" -a \
#        -z "${OPTION_BUILDTOOL}" ]
#   then
#      OPTION_INIT_ENV='NO'
#   fi

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

   if [ -z "${MULLE_PATH_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || exit 1
   fi

   if [ -z "${MULLE_FILE_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || exit 1
   fi

   if [ -z "${MULLE_SDE_EXTENSION_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh" || exit 1
   fi

   MULLE_SDE_ETC_DIR=".mulle/etc/sde"
   MULLE_SDE_SHARE_DIR=".mulle/share/sde"
   MULLE_SDE_VAR_DIR=".mulle/var/${MULLE_HOSTNAME}/sde"

   MULLE_SDE_PROTECT_PATH="`mulle-env environment get MULLE_SDE_PROTECT_PATH 2> /dev/null`"

   #
   # unprotect known share directories during installation
   # TODO: this should be a setting somewhere
   #
   r_colon_concat .mulle/share:cmake/share "${MULLE_SDE_PROTECT_PATH}"
   MULLE_SDE_PROTECT_PATH="${RVAL}"

   local i

   log_fluff "Unprotect ${MULLE_SDE_PROTECT_PATH}"

   IFS=":"
   for i in ${MULLE_SDE_PROTECT_PATH}
   do
      IFS="${DEFAULT_IFS}"
      [ ! -e "${i}" ] && continue

      exekutor chmod -R ug+wX "${i}"
   done
   IFS="${DEFAULT_IFS}"

   (
      if [ "${OPTION_ADD}" = 'YES' ]
      then
         __sde_init_add "$@"
      else
         __sde_init_main "$@"
      fi
   )
   rval=$?

   #
   # only write-protect individual files because of git
   #
   MULLE_SDE_PROTECT_PATH="`mulle-env environment get MULLE_SDE_PROTECT_PATH 2> /dev/null`"
   r_colon_concat .mulle/share:cmake/share "${MULLE_SDE_PROTECT_PATH}"
   MULLE_SDE_PROTECT_PATH="${RVAL}"

   log_fluff "Protect ${MULLE_SDE_PROTECT_PATH}"

   IFS=":"
   for i in ${MULLE_SDE_PROTECT_PATH}
   do
      IFS="${DEFAULT_IFS}"
      [ ! -e "${i}" ] && continue

      exekutor find "${i}" -type f -exec chmod a-w {} \;
   done
   IFS="${DEFAULT_IFS}"

   return $rval
}


sde_init_main()
{
   log_entry "sde_init_main" "$@"

   local RERUN='NO'

   _sde_init_main "$@"
   rval="$?"

   if [ "${RERUN}" = 'YES' ]
   then
      exec_command_in_subshell init "$@"
   fi

   return $rval
}
