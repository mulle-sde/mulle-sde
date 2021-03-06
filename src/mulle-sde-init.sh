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
   --no-sourcetree    : do not add sourcetree to project
   --style <tool/env> : specify environment style, see mulle-env init -h
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
   ${INIT_USAGE_NAME} [options] [type]

   Initializes a mulle-sde project in the current directory. This will
   minimally create a .mulle folder if the project type is left out. Choose a
   project type like "library" or "executable" if you are starting a new
   project.

   Typically you specifiy a meta-extension in the options. Extensions are
   plugins that contain scripts and files to setup the project for the desired
   programming language and build system. And a meta-extension is a wrapper
   around multiple such extensions.
   To see available (meta-)extensions use \`mulle-sde extension show\`.

   Optionally choose a directory to create and install
   into with the \'-d\' option:

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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES' -o "${MULLE_FLAG_LOG_EXEKUTOR}" = 'YES'  ]
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

   log_verbose "Installing files from \"${directory#${MULLE_USER_PWD}/}\" into \"${destination#${MULLE_USER_PWD}/}\" ($PWD)"

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

   log_fluff "Installing env files from \"${directory}\""

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

   log_debug "Inherits: $text"

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

      log_debug "Inheriting: \"${line}\""

      case "${line}" in
         "")
            continue
         ;;

         *\;*)
            IFS=";" read extension exttype depmarks <<< "${line}"

            r_comma_concat "${marks}" "${depmarks}"
            depmarks="${RVAL}"
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

   while IFS=$'\n' read -r line
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
         r_escaped_singlequotes "${comment}"
         echo "'${line}##${RVAL}'"
         comment=
      fi
   done <<< "${text}"
}


r_sde_githubname()
{
   log_entry "r_sde_githubname" "$@"

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
   local name
   local filtered
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

   r_dirname "${directory}"
   r_basename "${RVAL}"
   name="${RVAL}"

   # github don't like underscores, so we adapt here
   name="${name//_/-}"

   # is it a github identifier (engl.) ?
   filtered="`tr -d -c 'A-Z0-9a-z-' <<< "${name}"`"
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

   RVAL="${LOGNAME:-unknown}"
   return
}


import_template_generate()
{
   if [ -z "${MULLE_TEMPLATE_GENERATE_SH}" ]
   then
      MULLE_TEMPLATE_LIBEXEC_DIR="`mulle-template libexec-dir`" || fail "mulle-template not in PATH ($PATH)"
      . "${MULLE_TEMPLATE_LIBEXEC_DIR}/mulle-template-generate.sh" || internal_fail "include fail"
   fi
}


#
# expensive
#
read_template_expanded_file()
{
   log_entry "read_template_expanded_file" "$@"

   local filename="$1"

   import_template_generate

   #
   # CLUMSY HACKS:
   # for the benefit of test we have to define some stuff now
   #
   local PREFERRED_STARTUP_LIBRARY="${PREFERRED_STARTUP_LIBRARY:-Foundation-startup}"
   local GITHUB_USER="${GITHUB_USER:-${LOGNAME}}"
   local PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER

   r_uppercase "${PREFERRED_STARTUP_LIBRARY}"
   PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER="${RVAL//-/_}"

   PREFERRED_STARTUP_LIBRARY="${PREFERRED_STARTUP_LIBRARY}" \
   PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER="${PREFERRED_STARTUP_LIBRARY_UPCASE_IDENTIFIER}" \
   GITHUB_USER="${GITHUB_USER}" \
   PROJECT_LANGUAGE="${PROJECT_LANGUAGE:-c}" \
   PROJECT_DIALECT="${PROJECT_DIALECT:-objc}" \
      r_template_contents_replacement_seds "<|" "|>" "template_is_interesting_key"

   eval_rexekutor "'${SED:-sed}'" "${RVAL}" "${filename}" | egrep -v '^#'
}


add_to_sourcetree()
{
   log_entry "add_to_sourcetree" "$@"

   local filename="$1"
   local projecttype="$2"

   #
   # specialty for sourcetree, could expand this in general to
   # other files
   #
   if [ -e "${filename}-${projecttype}" ]
   then
      filename="${filename}-${projecttype}"
   fi

   local line
   local lines

   lines="`read_template_expanded_file "${filename}"`"

   set -o noglob; IFS=$'\n'
   for line in ${lines}
   do
      set +o noglob; IFS="${DEFAULT_IFS}"

      if [ ! -z "${line}" ]
      then
         MULLE_VIRTUAL_ROOT="`physicalpath "${PWD}" `" \
            eval_exekutor mulle-sourcetree -N \
                        "${MULLE_TECHNICAL_FLAGS}" \
                      add \
                        "${line}" || exit 1
      fi
   done
   set +o noglob; IFS="${DEFAULT_IFS}"
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

   shopt -s nullglob
   for file in "${filename}" "${filename}".*
   do
      shopt -u nullglob
      if _check_file "${file}"
      then
         r_path_extension "${file}"
         os="${RVAL}"
         _add_to_tools "${file}" "${os}"
      fi
   done
   shopt -u nullglob
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
   (
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
                    ONESHOT_FILENAME="${ONESHOT_FILENAME}" \
                    ONESHOT_IDENTIFIER="${ONESHOT_IDENTIFIER}" \
                    MULLE_VIRTUAL_ROOT="`pwd -P`" \
                        "${executable}" \
                              "${INIT_FLAGS}" \
                              "${MULLE_TECHNICAL_FLAGS}" \
                              "${flags}" \
                              "${auxflags}" \
                           --marks "'${marks}'" \
                                   "${projecttype}"
   ) || fail "init script \"${RVAL}\" failed"
}


is_disabled_by_marks()
{
   log_entry "is_disabled_by_marks" "$@"

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
   log_entry "is_directory_disabled_by_marks" "$@"

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
   log_entry "is_file_disabled_by_marks" "$@"

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
   log_entry "is_sourcetree_file_disabled_by_marks" "$@"

   local marks="$1"
   local filename="$2"
   local projecttype="$3"

   if ! _check_file "${filename}"
   then
      if ! _check_file "${filename}-${projecttype}"
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
                                             "${extensiondir}/sourcetree" \
                                             "no-sourcetree" \
                                             "no-sourcetree-${vendor}-${extname}" \
                                             "${projecttype}"
   then
      add_to_sourcetree "${extensiondir}/sourcetree" "${projecttype}"
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


#
# In mulle-sde-init when we are using template files we are installing
# into `src` (as of now). If no src is defined we use PWD, basically just
# for testing though.
#
_copy_extension_template_files()
{
   log_entry "_copy_extension_template_files" "$@"

   local extensiondir="$1"; shift
   local subdirectory="$1"; shift
   local projecttype="$1"; shift
   local force="$1"; shift
   local onlyfilename="$1"; shift
   local file_seds="$1"; shift

   local sourcedir

   sourcedir="${extensiondir}/${subdirectory}/${projecttype}"

   _check_dir "${sourcedir}" || return 0

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

   arguments="${arguments} '${sourcedir}' '${dstdir}'"

   #
   # Normally the base projet files will be copied first, then we can not
   # inherit properly because they are already there and we can not clobber
   # them. So we collect _TEMPLATE_DIRECTORIES in reverse order.
   #
   # If force is set, the dlast file file will win, in this case we use the
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
   second="${projecttype:-none}"

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
         r_basename "${relpath}"
         if [ "${RVAL}" != ".gitignore" ]
         then
            log_warning "Not deleting files at present (${relpath})"
            continue
         fi
         r_dirname "${relpath}"
         relpath="${RVAL}"
      fi

      r_basename "${relpath}"
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


set_projectlanguage()
{
   set_projectlanguage_variables

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

   # duplicate check
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
         log_debug "memorize extension ${vendor}/${extname} as installed"
         r_add_line "${_INSTALLED_EXTENSIONS}" "${vendor}/${extname};${exttype}"
         _INSTALLED_EXTENSIONS="${RVAL}"
      fi
   fi

   # just to catch idiots early
   assert_sane_extension_values "${exttype}" "${vendor}" "${extname}"

   local extensiondir
   local searchpath

   if ! r_find_get_quoted_searchpath "${vendor}"
   then
      r_extension_get_searchpath
      searchpath="${RVAL}"

      fail "Could not find any extensions of vendor \"${vendor}\" (${searchpath})!
${C_INFO}Show available extensions with:
   ${C_RESET}${C_BOLD}mulle-sde extension show all"
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

               set_projectlanguage

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
   # file is called inherit,
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
      log_verbose "${verb} ${exttype} extension ${C_RESET_BOLD}${vendor}/${extname}"
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
         if [ ! -z "${projecttype}" ]
         then
            add_to_environment "${extensiondir}/environment-${projecttype}"
         fi
         add_to_environment "${extensiondir}/environment"

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


      if [ ! -z "${OPTION_INIT_TYPE}" -a  -d "${extensiondir}/${OPTION_INIT_TYPE}-oneshot" ]
      then
         subdirectory="${OPTION_INIT_TYPE}-oneshot"
      else
         subdirectory="project-oneshot"
      fi

      if ! is_directory_disabled_by_marks "${marks}" \
                                          "${extensiondir}/${subdirectory}" \
                                          "no-project-oneshot" \
                                          "no-project-oneshot/${vendor}/${extname}"
      then
         _copy_extension_template_directory "${extensiondir}" \
                                            "${subdirectory}" \
                                            "${projecttype}" \
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

      if ! is_directory_disabled_by_marks "${marks}" \
                                          "${extensiondir}/${subdirectory}" \
                                          "no-project" \
                                          "no-project/${vendor}/${extname}"
      then
         _copy_extension_template_directory "${extensiondir}" \
                                            "${subdirectory}" \
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
      log_verbose "Not installing project or demo files for \"${extname}\", as project-type is \"none\""
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
   if ! is_directory_disabled_by_marks "${marks}" \
                                       "${extensiondir}/share" \
                                       "no-share" \
                                       "no-share/${vendor}/${extname}"
   then
      _copy_extension_dir "${extensiondir}/share" 'YES' 'YES' ||
         fail "Could not copy \"${extensiondir}/share\""
   fi

#   #
#   # etc is also disabled by no-share
#   #
#   if ! is_directory_disabled_by_marks "${marks}" \
#                                       "${extensiondir}/etc" \
#                                       "no-share" \
#                                       "no-share/${vendor}/${extname}"
#   then
#      _copy_extension_dir "${extensiondir}/etc" 'YES' 'NO' ||
#         fail "Could not copy \"${extensiondir}/etc\""
#   fi

   RVAL="${extensiondir}"
}


#
# could do this once
#
define_hacky_template_variables()
{
   log_entry "define_additional_template_variables" "$@"

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
install_extension()
{
   log_entry "install_extension" "$@"

   local projecttype="$1"
   local exttype="$2"
   local vendor="$3"
   local extname="$4"
   local marks="$5"
   local onlyfilename="$6"
   local force="$7"

   local _TEMPLATE_DIRECTORIES # will be set by _install_extension

   local extensiondir

   verb="Installing"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      verb="Ugrading"
   fi

   log_verbose "${verb} extension dependencies of ${C_RESET_BOLD}${vendor}/${extname}"

   _install_extension "$@"
   extensiondir="${RVAL}"

   #
   # Now install collected templates
   #
   import_template_generate

   [ -z "${_TEMPLATE_DIRECTORIES}" ] && return

   if [ -z "${onlyfilename}" ]
   then
      log_verbose "Installing project files for \"${vendor}/${extname}\""
   fi

   (
      export_projectname_environment "${PROJECT_NAME}"
      export_projectlanguage_environment "${PROJECT_LANGUAGE}"

      #
      # Read what extensions added to the project so far. environment-project
      # is under our mulle-sde control and it's not complete yet.
      #
      if [ -f ".mulle/share/env/environment-extension.sh" ]
      then
         . ".mulle/share/env/environment-extension.sh"
      fi

      define_hacky_template_variables

      #
      # using the --embedded option, the template generator keeps state in
      # CONTENTS_SED and FILENAME_SED, since that is expensive to recalculate
      #
      local CONTENTS_SED
      local FILENAME_SED

      log_debug "_TEMPLATE_DIRECTORIES: ${_TEMPLATE_DIRECTORIES}"

      set -o noglob; IFS=$'\n'
      for arguments in ${_TEMPLATE_DIRECTORIES}
      do
         IFS="${DEFAULT_IFS}"; set +o noglob

         if [ ! -z "${arguments}" ]
         then
            eval_rexekutor template_generate_main "${arguments}" || exit 1
         fi
      done
   ) || exit 1

   if [ -z "${onlyfilename}" ]
   then
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

      # happens for oneshot extensions
      if [ ! -z "${OPTION_INIT_TYPE}" ]
      then
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
      fi
   fi

   local verb

   verb="Installed"
   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      verb="Ugraded"
   fi

   log_verbose "${verb} ${exttype} extension ${C_RESET_BOLD}${vendor}/${extname}"
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
   redirect_exekutor "${motdfile}" printf "%s\n" "${text}"
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

   local extensionfile="$1"

   local EGREP

   # can sometimes happen, bail early then.
   EGREP="`command -v egrep`"
   if [ -z "${EGREP}" ]
   then
      fail "egrep not in PATH: ${PATH}"
   fi

   if _check_file "${extensionfile}"
   then
      exekutor "${EGREP}" -v '^#' < "${extensionfile}"
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


memorize_installed_extensions()
{
   log_entry "memorize_installed_extensions" "$@"

   local extensions="$1"

   local filename

   filename="${MULLE_SDE_SHARE_DIR}/extension"

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   redirect_exekutor "${filename}" printf "%s\n" "${extensions}" || exit 1
}


env_set_var()
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
                     set "${key}" "${value}" || internal_fail "failed env set"
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


   if [ ! -z "${onlyfilename}" ]
   then
      return
   fi

   #
   # remember type and installed extensions
   #
   memorize_installed_extensions "${_INSTALLED_EXTENSIONS}"

   # oneshots aren't memorized
   install_oneshot_extensions "${OPTION_ONESHOTS}" \
                              "${PROJECT_TYPE}" \
                              "${marks}" \
                              "" \
                              "${force}"
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
   export PROJECT_NAME

   if [ ! -z "${language}" ]
   then
      PROJECT_LANGUAGE="${language}"
      PROJECT_DIALECT="${dialect}"
      PROJECT_EXTENSIONS="${extensions}"

      set_projectlanguage
   fi

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
   project_add_envscope_if_missing

   PROJECT_TYPE="${projecttype}"
   PROJECT_SOURCE_DIR="${projectsourcedir}"

   env_set_var PROJECT_TYPE "${PROJECT_TYPE}" "project"
   if [ ! -z "${PROJECT_SOURCE_DIR}" ]
   then
      #
      # For projects that are not "none", we use save PROJECT_SOURCE_DIR
      #
      env_set_var PROJECT_SOURCE_DIR "${PROJECT_SOURCE_DIR}" "project"
   fi

   export PROJECT_SOURCE_DIR
   export PROJECT_TYPE

   #
   # TODO: this is clumsy and needs to be rewritten
   # put these first, so extensions can draw on these in their definitions
   #
   set_projectname_variables "${PROJECT_NAME}"
   save_projectname_variables "--no-protect"

   local _MOTD
   local _INSTALLED_EXTENSIONS

   _MOTD=""

   if [ -z "${onlyfilename}" ]
   then
      log_verbose "Installing project extensions in ${C_RESET_BOLD}${PWD}${C_INFO}"
   fi

   install_extensions "${marks}" "${onlyfilename}" "${force}"

   if [ ! -z "${onlyfilename}" ]
   then
      return
   fi

   save_projectlanguage_variables "--no-protect"

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
                           "${MULLE_TECHNICAL_FLAGS}" \
                           --no-protect \
                        environment \
                           --scope extension \
                           mset "${defines}" || exit 1
}


sde_run_add()
{
   log_entry "sde_run_add" "$@"

   [ "$#" -eq 0 ] || sde_init_usage "extranous arguments \"$*\""

   [ "${OPTION_REINIT}" = 'YES' -o "${OPTION_UPGRADE}" = 'YES' ] && \
      fail "--add and --reinit/--upgrade exclude each other"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" ]
   then
      fail "You must init first, before you can add an 'extra' extension!
${C_VERBOSE}(\"${MULLE_SDE_SHARE_DIR#${MULLE_USER_PWD}/}\" not present)"
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

   add_environment_variables "${OPTION_DEFINES}"

   local _INSTALLED_EXTENSIONS

   _INSTALLED_EXTENSIONS="`recall_installed_extensions "${OPTION_EXTENSION_FILE}"`" || exit 1
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


r_mset_quoted_env_line()
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


__get_installed_extensions()
{
   log_entry "mulle-objc/travis" "$@"

   local extensionfile="$1"

   local extensions

   if [ -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      log_warning "Last upgrade failed. Restoring the last configuration."
      rmdir_safer "${MULLE_SDE_SHARE_DIR}" &&
      exekutor mv "${MULLE_SDE_SHARE_DIR}.old" "${MULLE_SDE_SHARE_DIR}" &&
      rmdir_safer "${MULLE_SDE_SHARE_DIR}.old"
   fi

   extensions="`recall_installed_extensions "${extensionfile}"`" || exit 1
   if [ -z "${extensions}" ]
   then
      log_fluff "No extensions found"
      return 1
   fi

   log_debug "Found extensions: ${extensions}"

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

   printf "%s\n" "${newmarks}"
}


#
# call this before__get_installed_extensions
#
read_project_environment()
{
   log_entry "read_project_environment" "$@"

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


# stupid old code
_sde_validate_projecttype()
{
   local projecttype="$1"

   case "${projecttype}" in
      "")
         fail "Project type is empty"
      ;;

      executable|extension|framework|library|none|unknown)
      ;;


      *)
         if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
         then
            fail "\"${projecttype}\" is not a standard project type.
${C_INFO}Use -f to use \"${projecttype}\""
         fi
      ;;
   esac
}


_sde_run_upgrade()
{
   log_entry "_sde_run_upgrade" "$@"

   rexekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
                     --no-protect \
                     upgrade || exit 1

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
   fi

   read_project_environment

   if ! __get_installed_extensions "${OPTION_EXTENSION_FILE}"
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


   _sde_validate_projecttype "${PROJECT_TYPE}"


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

   add_environment_variables "${OPTION_DEFINES}"


   # rmdir_safer ".mulle-env"
   if ! install_extensions "${OPTION_MARKS}" \
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

   #
   # repair patternfiles as a "bonus" with -add option
   #
   exekutor "${MULLE_MATCH:-mulle-match}" \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_MATCH_FLAGS} \
              patternfile repair --add

   remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"

   # only remove if empty
   exekutor rmdir "${MULLE_SDE_SHARE_DIR}" 2>  /dev/null
   exekutor rmdir "${MULLE_MATCH_SHARE_DIR}" 2>  /dev/null

   return 0
}


_sde_run_upgrade_projectfile()
{
   log_entry "_sde_run_upgrade_projectfile" "$@"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
   fi

   read_project_environment

   if ! __get_installed_extensions "${OPTION_EXTENSION_FILE}"
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


   _sde_validate_projecttype "${PROJECT_TYPE}"
   add_environment_variables "${OPTION_DEFINES}"


   # rmdir_safer ".mulle-env"
   if ! install_extensions "${OPTION_MARKS}" \
                           "${OPTION_PROJECT_FILE}" \
                           "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      return 1
   fi

   return 0
}


_sde_pre_initenv()
{
   log_entry "_sde_pre_initenv" "$@"

   #
   # if we init env now, then extensions can add environment
   # variables and tools
   #
   local flags

   if [ "${MULLE_FLAG_MAGNUM_FORCE}" = 'YES' ]
   then
      flags="-f"
   fi

   exekutor "${MULLE_ENV:-mulle-env}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${flags} \
                  --no-protect \
                  --style "${OPTION_ENV_STYLE}" \
               init \
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
            internal_fail "mulle-env should have cleaned up after itself after init failure"
         fi
         exit 1
      ;;
   esac
}


_sde_post_initenv()
{
   log_entry "_sde_post_initenv" "$@"

   if [ "${OPTION_INIT_TYPE}" = "subproject" ]
   then
      exekutor "${MULLE_ENV:-mulle-env}" \
                     ${MULLE_TECHNICAL_FLAGS} \
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

   if [ "${OPTION_BLURB}" = 'YES' ]
   then
      log_info "Enter the environment:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} \"${PWD#${MULLE_USER_PWD}/}\"${C_INFO}"
   fi
}


_sde_run_reinit()
{
   log_entry "_sde_run_reinit" "$@"

   if [ ! -d "${MULLE_SDE_SHARE_DIR}" -a ! -d "${MULLE_SDE_SHARE_DIR}.old" ]
   then
      fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_SHARE_DIR} is missing)"
   fi

   if [ -z "${OPTION_PROJECT_FILE}" ]
   then
      rexekutor "${MULLE_ENV:-mulle-env}" \
                        ${MULLE_TECHNICAL_FLAGS} \
                        --no-protect \
                        upgrade || exit 1
   fi


   read_project_environment

   [ $# -eq 0 ] && sde_init_usage "Missing project type"
   [ $# -eq 1 ] || sde_init_usage "Superflous arguments \"$*\""

   PROJECT_TYPE="$1"

   _sde_validate_projecttype "${PROJECT_TYPE}"

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      _sde_pre_initenv
   fi

   add_environment_variables "${OPTION_DEFINES}"

   # rmdir_safer ".mulle-env"
   case "${OPTION_PROJECT_SOURCE_DIR}" in
      DEFAULT)
         if [ "${PROJECT_TYPE}" != "none" ]
         then
            OPTION_PROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR:-src}"
         fi
      ;;
   esac

   case "${OPTION_NAME}" in
      DEFAULT)
         OPTION_NAME="${PROJECT_NAME}"
         if [ -z "${OPTION_NAME}" ]
         then
            r_basename "${PWD}"
            OPTION_NAME="${RVAL}"
         fi
      ;;
   esac

   if ! install_project "${OPTION_NAME}" \
                       "${PROJECT_TYPE}" \
                       "${OPTION_PROJECT_SOURCE_DIR}" \
                       "${OPTION_MARKS}" \
                       "${OPTION_PROJECT_FILE}" \
                       "${MULLE_FLAG_MAGNUM_FORCE}" \
                       "${OPTION_LANGUAGE}"  \
                       "${OPTION_DIALECT}"  \
                       "${OPTION_EXTENSIONS}"
   then
      return 1
   fi

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      _sde_pre_initenv
   fi

   return 0
}



_sde_run_init()
{
   log_entry "_sde_run_init" "$@"

   [ $# -le 1 ] || sde_init_usage "Superflous arguments \"$*\""

   PROJECT_TYPE="${1:-none}"

   _sde_validate_projecttype "${PROJECT_TYPE}"

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      _sde_pre_initenv
   fi

   add_environment_variables "${OPTION_DEFINES}"


   case "${OPTION_PROJECT_SOURCE_DIR}" in
      DEFAULT)
         if [ "${PROJECT_TYPE}" != "none" ]
         then
            OPTION_PROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR:-src}"
         fi
      ;;
   esac

   case "${OPTION_NAME}" in
      DEFAULT)
         OPTION_NAME="${PROJECT_NAME}"
         if [ -z "${OPTION_NAME}" ]
         then
            r_basename "${PWD}"
            OPTION_NAME="${RVAL}"
         fi
      ;;
   esac

   if ! install_project "${OPTION_NAME}" \
                        "${PROJECT_TYPE}" \
                        "${OPTION_PROJECT_SOURCE_DIR}" \
                        "${OPTION_MARKS}" \
                        "${OPTION_PROJECT_FILE}" \
                        "${MULLE_FLAG_MAGNUM_FORCE}" \
                        "${OPTION_LANGUAGE}"  \
                        "${OPTION_DIALECT}"  \
                        "${OPTION_EXTENSIONS}"
   then
      return 1
   fi

   if [ "${OPTION_INIT_ENV}" = 'YES' ]
   then
      _sde_post_initenv
   fi

   return 0
}


#
# These funtions should save state and revert to previous state if the
# init/upgrade failed.
#
sde_check_dot_init()
{
   log_entry "sde_check_dot_init" "$@"

   if [ -d "${MULLE_SDE_SHARE_DIR}" ]
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
}


sde_save_mulle_in_old()
{
   log_entry "sde_save_mulle_in_old" "$@"

   rmdir_safer ".mulle.old"
   exekutor mv ".mulle" ".mulle.old"

   # copy stuff we may need for the upgrade back,
   mkdir_if_missing ".mulle" || exit 1
   exekutor cp -Ra ".mulle.old/etc" ".mulle" || exit 1
   exekutor cp -Ra ".mulle.old/share" ".mulle" || exit 1

   mkdir_if_missing "${MULLE_MATCH_VAR_DIR}" || exit 1
   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}" || exit 1
}


sde_restore_mulle_from_old()
{
   log_entry "sde_restore_mulle_from_old" "$@"

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


sde_run_init()
{
   log_entry "sde_run_init" "$@"

   log_verbose "Init start"

   sde_check_dot_init

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   redirect_exekutor "${MULLE_SDE_SHARE_DIR}/.init" echo "Start init `date` in $PWD on ${MULLE_HOSTNAME}"

   local rval
   (
      _sde_run_init "$@"
   )
   rval="$?"

   if [ $rval != 0 ]
   then
      rmdir_safer ".mulle"

      if [ "${PURGE_PWD_ON_ERROR}" = 'YES' ]
      then
         rmdir_safer "${PWD}"
      fi
   fi

   # remove if empty
   exekutor rmdir "${MULLE_SDE_SHARE_DIR}" 2>  /dev/null
   exekutor rmdir "${MULLE_MATCH_SHARE_DIR}" 2>  /dev/null

   remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"

   log_verbose "Init end"

   return $rval
}



sde_run_reinit()
{
   # reinit, save the old
   log_entry "sde_run_reinit" "$@"

   log_verbose "Reinit start"

   sde_check_dot_init

   sde_save_mulle_in_old

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   redirect_exekutor "${MULLE_SDE_SHARE_DIR}/.init" echo "Start reinit `date` in $PWD on ${MULLE_HOSTNAME}"

   local rval
   (
      _sde_run_reinit "$@"
   )
   rval="$?"

   # rmdir_safer ".mulle-env"
   if [ $rval -ne 0 ]
   then
      log_info "The reinit failed. Restoring old configuration."

      sde_restore_mulle_from_old
   else
      rmdir_safer ".mulle.old"
   fi

   # remove if empty
   exekutor rmdir "${MULLE_SDE_SHARE_DIR}" 2>  /dev/null
   exekutor rmdir "${MULLE_MATCH_SHARE_DIR}" 2>  /dev/null

   remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"

   log_verbose "Reinit end"

   return $rval
}


sde_run_upgrade_projectfile()
{
   log_entry "sde_run_upgrade_projectfile" "$@"

   log_verbose "Upgrade projectfile start"
   # probably nothing to do here (could save source but we don't)
   local rval
   (
      _sde_run_upgrade_projectfile "$@"
   )
   rval="$?"

   log_verbose "Upgrade projectfile end"
   return $rval
}


sde_run_upgrade()
{
   log_entry "sde_run_upgrade" "$@"

   log_verbose "Upgrade start"

   if [ -d ".mulle.old" -a ! -d ".mulle" ]
   then
      fail "Old .mulle.old folder of a possibly failed upgrade present, remove it manually"
   fi

   if [ ! -d ".mulle" ]
   then
      fail "No .mulle folder present, nothing to upgrade"
   fi

   #
   # always wipe these for clean upgrades
   # except if we are just updating a specific project file
   # (i.e. CMakeLists.txt). Keep "extension" file around in case something
   # goes wrong. Also temporarily keep old share
   #
   sde_save_mulle_in_old

   mkdir_if_missing "${MULLE_SDE_SHARE_DIR}"
   redirect_exekutor "${MULLE_SDE_SHARE_DIR}/.init" echo "Start upgrade `date` in $PWD on ${MULLE_HOSTNAME}"

   local rval
   (
      _sde_run_upgrade "$@"
   )
   rval="$?"

   # rmdir_safer ".mulle-env"
   if [ $rval -ne 0 ]
   then
      log_info "The upgrade failed. Restoring old configuration."

      sde_restore_mulle_from_old
   else
      rmdir_safer ".mulle.old"
   fi

   remove_file_if_present "${MULLE_SDE_SHARE_DIR}/.init"

   log_verbose "Upgrade end"

   return $rval
}


sde_protect_unprotect()
{
   log_entry "sde_protect_unprotect" "$@"

   local title="$1"
   local mode="$2"

   MULLE_SDE_PROTECT_PATH="`"${MULLE_ENV:-mulle-env}" environment get MULLE_SDE_PROTECT_PATH 2> /dev/null`"

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

   IFS=':'
   for i in ${MULLE_SDE_PROTECT_PATH}
   do
      IFS="${DEFAULT_IFS}"
      [ ! -e "${i}" ] && continue

      # can only read protect files, because otherwise git freaks out
      exekutor find "${i}" -type f -exec chmod ${mode} {} \;
   done
   IFS="${DEFAULT_IFS}"
}


sde_init_include()
{
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
}


###
### parameters and environment variables
###
_sde_init_main()
{
   log_entry "_sde_init_main" "$@"

   local OPTION_NAME='DEFAULT'
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
   local OPTION_PROJECT_SOURCE_DIR='DEFAULT'
   local OPTION_POST_INIT='YES'
   local OPTION_UPGRADE_SUBPROJECTS
   local PURGE_PWD_ON_ERROR='NO'
   local TEMPLATE_HEADER_FILE
   local TEMPLATE_FOOTER_FILE
   local OPTION_INIT_TYPE="project"
   local OPTION_REFLECT='YES'
   local line
   local mark

   sde_init_include

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
            r_mset_quoted_env_line "${1:2}"
            r_concat "${OPTION_DEFINES}" "'${RVAL}'"
            OPTION_DEFINES="${RVAL}"
         ;;

         -D)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            r_mset_quoted_env_line "$1"
            r_concat "${OPTION_DEFINES}" "'${RVAL}'"
            OPTION_DEFINES="${RVAL}"
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

         -o|--oneshot)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_ONESHOTS="`add_line "${OPTION_ONESHOTS}" "$1" `"
         ;;

         --oneshot-name)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            ONESHOT_FILENAME="$1"
            export ONESHOT_FILENAME
         ;;

         --oneshot-class)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            ONESHOT_CLASS="$1"
            export ONESHOT_CLASS
         ;;

         --oneshot-category)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            ONESHOT_CATEGORY="$1"
            export ONESHOT_CATEGORY
         ;;

         --template-header-file)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            TEMPLATE_HEADER_FILE="$1" # same name as in mulle-template
         ;;

         --template-footer-file)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            TEMPLATE_FOOTER_FILE="$1" # same name as in mulle-template
         ;;

         -m|--meta)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            OPTION_META="$1"
         ;;

         -n|--name|--project-name)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            [ "$1" = 'DEFAULT' ] && fail "DEFAULT is not a usable project-name during init (rename to it later)"
            OPTION_NAME="$1"
         ;;

         # little hack
         --github|--github-user)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            GITHUB_USER="$1"
            export GITHUB_USER
         ;;

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
            export PROJECT_TYPE
         ;;

         --project-source-dir|--source-dir)
            [ $# -eq 1 ] && sde_init_usage "Missing argument to \"$1\""
            shift

            [ "$1" = 'DEFAULT' ] && fail "DEFAULT is not a usable PROJECT_SOURCE_DIR value during init (rename to it later)"

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
            r_comma_concat "${RVAL}" "no-project-oneshot"
            r_comma_concat "${RVAL}" "no-sourcetree"
            OPTION_MARKS="${RVAL}"
            OPTION_INIT_ENV='NO'
         ;;

         --reflect)
            OPTION_REFLECT='YES'
         ;;

         --no-reflect)
            OPTION_REFLECT='NO'
         ;;

         --upgrade)
            OPTION_UPGRADE='YES'
            OPTION_BLURB='NO'
            r_comma_concat "${OPTION_MARKS}" "no-demo"
            r_comma_concat "${RVAL}" "no-project-oneshot"
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

         # keep these down here, so they don't catch flags prematurely
         --allow-*)
            mark="${1:8}"
            warn_if_unknown_mark "${mark}" "allow-mark"
            OPTION_MARKS="`remove_from_marks "${OPTION_MARKS}" "no-${mark}"`"
         ;;

         --no-*)
            mark="${1:5}"
            warn_if_unknown_mark "${mark}" "no-${mark}"
            r_comma_concat "${OPTION_MARKS}" "no-${mark}"
            OPTION_MARKS="${RVAL}"
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

   if [ -z "${MULLE_SDE_PROJECT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-project.sh" || internal_fail "missing file"
   fi

   # export to environment
   set_oneshot_variables "${ONESHOT_FILENAME}" "${ONESHOT_CLASS}" "${ONESHOT_CATEGORY}"
   export_oneshot_environment "${ONESHOT_FILENAME}" "${ONESHOT_CLASS}" "${ONESHOT_CATEGORY}"

   # old version will be used for migrate
   local oldversion

   if [ "${OPTION_UPGRADE}" = 'YES' ]
   then
      oldversion="`rexekutor mulle-env --search-as-is -s environment get MULLE_SDE_INSTALLED_VERSION 2> /dev/null`"
      log_debug "Old version: ${oldversion}"

      case "${oldversion}" in
         [0-9]*\.[0-9]*\.[0-9]*)
            # check that old version is not actually newer than what we have
            # shellcheck source=mulle-case.sh
            [ -z "${MULLE_VERSION_SH}" ] &&  . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh"

            r_version_distance "${MULLE_EXECUTABLE_VERSION}" "${oldversion}"
            if [ "${RVAL}" -gt 0 ]
            then
               fail "Can't upgrade! The environment  was created by a newer mulle-sde version ${oldversion}.
${C_INFO}You have mulle-sde version ${MULLE_EXECUTABLE_VERSION}"
            fi
         ;;

         "")
            [ ! -d .mulle/share/sde ] &&  fail "There is no mulle-sde project here"

            oldversion="0.0.0"
            log_warning "Can not get previous installed version from MULLE_SDE_INSTALLED_VERSION, assuming 0.0.0"
         ;;

         *)
            internal_fail "Unparsable version info in MULLE_SDE_INSTALLED_VERSION (${MULLE_SDE_INSTALLED_VERSION})"
         ;;
      esac
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

   log_fluff "Setup environment"

   # fake an environment so mulle-env gives us proper environment variables
   # remove temp file if done

   sde_protect_unprotect "Unprotect" "ug+w"
   ### BEGIN
      local tmp_file

      if [ ! -f ".mulle/share/env/environment.sh" ]
      then
         mkdir_if_missing .mulle/share/env
         exekutor touch .mulle/share/env/environment.sh
         tmp_file='YES'
      fi

      # get environments for some tools we manage share files and want
      # to upgrade
      eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env sde` || exit 1
      eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env match` || exit 1
      eval_rexekutor `rexekutor "${MULLE_ENV:-mulle-env}" --search-as-is mulle-tool-env env` || exit 1

      if [ "${tmp_file}" = 'YES' ]
      then
         remove_file_if_present .mulle/share/env/environment.sh
      fi

      # figure out a GITHUB user name for later
      r_sde_githubname
      GITHUB_USER="${RVAL}"

      log_debug "GITHUB_USER set to \"${GITHUB_USER}\""

      if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
      then
         log_trace2 "MULLE_MATCH_ETC_DIR=\"${MULLE_MATCH_ETC_DIR}\""
         log_trace2 "MULLE_MATCH_SHARE_DIR=\"${MULLE_MATCH_SHARE_DIR}\""
         log_trace2 "MULLE_SDE_ETC_DIR=\"${MULLE_SDE_ETC_DIR}\""
         log_trace2 "MULLE_SDE_PROTECT_PATH=\"${MULLE_SDE_PROTECT_PATH}\""
         log_trace2 "MULLE_SDE_SHARE_DIR=\"${MULLE_SDE_SHARE_DIR}\""
         log_trace2 "MULLE_SDE_VAR_DIR=\"${MULLE_SDE_VAR_DIR}\""
         log_trace2 "MULLE_VIRTUAL_ROOT=\"${MULLE_VIRTUAL_ROOT}\""
         log_trace2 "GITHUB_USER=\"${GITHUB_USER}\""
         log_trace2 "PWD=\"${PWD}\""
      fi

      (
         if [ "${OPTION_ADD}" = 'YES' ]
         then
            sde_run_add "$@"
         else
            if [ "${OPTION_UPGRADE}" = 'YES' ]
            then
               if [ -z "${OPTION_PROJECT_FILE}" ]
               then
                  sde_run_upgrade "$@" || exit $?
               else
                  sde_run_upgrade_projectfile "$@" || exit $?
               fi
            else
               if [ "${OPTION_REINIT}" = 'YES' ]
               then
                  sde_run_reinit "$@" || exit $?
               else
                  sde_run_init "$@" || exit $?
               fi
            fi

            # we use the protected version of mulle-env here, because it doesn't
            # matter and we can circumvent a protection bug
            # we protect afterwards anyway
            #
            exekutor "${MULLE_ENV:-mulle-env}" \
                        --search-as-is \
                        -s \
                        ${MULLE_TECHNICAL_FLAGS} \
                     environment \
                        --scope "plugin" \
                        set "MULLE_SDE_INSTALLED_VERSION" \
                            "${MULLE_EXECUTABLE_VERSION}" || internal_fail "failed env set"
         fi
      )
      rval=$?

      #
      # for these post processing steps load up the environment if present
      #
      if [ $rval -eq 0 ]
      then
         (
            if [ "${OPTION_UPGRADE}" = 'YES' ]
            then
               # shellcheck source=src/mulle-sde-migrate.sh
               . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-migrate.sh"

               sde_migrate "${oldversion}" "${MULLE_EXECUTABLE_VERSION}"  || exit 1
            fi

            if [ "${OPTION_REFLECT}" = 'YES' ]
            then
               exekutor "${MULLE_SDE:-mulle-sde}" \
                           ${MULLE_TECHNICAL_FLAGS} \
                           -N \
                        reflect || exit 1
            fi
         )
         rval=$?
      fi
   ### END

   sde_protect_unprotect "Protect" "a-w"

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



