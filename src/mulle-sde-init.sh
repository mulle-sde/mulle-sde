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
   -d <dir>           : directory to populate (working directory)
   -D <key>=<val>     : specify an environment variable
   -e <extra>         : specify extra extensions. Multiple uses are possible
   -m <meta>          : specify meta extensions
   -n <name>          : project name
   -o <oneshot>       : specify oneshot extensions. Multiple uses are possible"

   HIDDEN_OPTIONS="\
   --allow-<name>     : reenable specific pieces of initialization (see source code)
   --no-<name>        : turn off specific pieces of initialization (see source code)
   -b <buildtool>     : specify the buildtool extension to use
   -r <runtime>       : specify runtime extension to use
   -v <vendor>        : extension vendor to use (mulle-sde)
   --source-dir <dir> : specify source directory location (src)"

   cat <<EOF >&2
Usage:
   ${INIT_USAGE_NAME} [options] <type>

   Use \`mulle-sde extension list\` to see, which extensions are available on your
   system. Pick a meta extension to install. Check what project types are
   present for your chosen extension with \`mulle-sde extension usage\`.

   Now you can create a mulle-sde project of your chosen type:

      mulle-sde init -d ./my-project -m mulle-sde/c-cmake executable

   To use an existing project with mulle-sde:

      cd my-project ; mulle-sde init --existing -m mulle-sde/c-cmake executable

   You can use \`mulle-sde extension add\` to add extra and oneshot extensions.
   at a later date.

Options:
EOF
   (
      echo "${COMMON_OPTIONS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
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

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      flags=-v
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten.
   #
   if [ "${overwrite}" = "NO" ]
   then
      flags="${flags} -n"  # don't clobber
   fi

   log_fluff "Installing from \"${directory}\""

   local name

   name="`fast_basename "${directory}"`"
   if [ -d "${MULLE_SDE_DIR}/${name}" ]
   then
      find "${MULLE_SDE_DIR}/${name}" -type f -exec chmod ug+w {} \;
   fi

   # need L flag since homebrew creates relative links
   exekutor cp -RLa ${flags} "${directory}" "${MULLE_SDE_DIR}/" &&
   if [ "${writeprotect}" = "YES" ]
   then
      #
      # for git its not nice to write protect directories like share,
      # in case you checkout an old version. So just protect single files
      #
      find "${MULLE_SDE_DIR}/${name}" -type f -exec chmod ugo-w {} \;
   fi
}


_copy_env_extension_dir()
{
   log_entry "_copy_env_extension_dir" "$@"

   local directory="$1"

   if [ ! -d "${directory}/share" ]
   then
      log_debug "Nothing to copy as \"${directory}/share\" is not there"
      return
   fi

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      flags=-v
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten.
   #

   log_fluff "Installing from \"${directory}\""

   if [ -d ".mulle-env/share" ]
   then
      find ".mulle-env/share" -type f -exec chmod ug+w {} \;
   fi

   # need L flag since homebrew creates relative links
   exekutor cp -RLa ${flags} "${directory}/share" ".mulle-env/" &&

   find ".mulle-env/share" -type f -exec chmod ugo-w {} \;
}



_append_to_motd()
{
   log_entry "_append_to_motd" "$@"

   local extensiondir="$1"

   if [ ! -f "${extensiondir}/motd" ]
   then
      log_debug "Nothing to append to MOTD as \"${extensiondir}/motd\" is not there ($PWD)"
      return
   fi

   local text

   text="`LC_ALL=C egrep -v '^#' "${extensiondir}/motd" `"
   if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
   then
      log_fluff "Append \"${extensiondir}/motd\" to motd"
      _MOTD="`add_line "${_MOTD}" "${text}" `"
   fi
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

   if [ ! -d "${projectdir}" ]
   then
      log_debug "\"${projectdir}\" is not there ($PWD)"
      return
   fi

   #
   # copy and expand stuff from project folder. Be extra careful not to
   # clobber project files, except if -f is given
   #
   if [ -z "${MULLE_SDE_INITSUPPORT_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-template.sh" || internal_fail "include fail"
   fi

   local flags
   local arguments

   arguments="--embedded \
              --template-dir '${projectdir}' \
              --name '${PROJECT_NAME}' \
              --language '${PROJECT_LANGUAGE}' \
              --dialect '${PROJECT_DIALECT}' \
              --extensions '${PROJECT_EXTENSIONS}' \
              --source-dir '${PROJECT_SOURCE_DIR}'"

   if [ "${force}" = "YES" -o ! -z "${onlyfilename}" ]
   then
      arguments="${arguments} -f"
   fi

   if [ ! -z "${onlyfilename}" ]
   then
      arguments="${arguments} --file '${onlyfilename}'"
   fi
   arguments="${arguments} ${OPTION_USERDEFINES}"

   log_fluff "Copying \"${projectdir}\" with template expansion"

   # put in own shell to avoid side effects
   (
      eval _template_main "${arguments}"
   ) || fail "template generation failed"
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

   IFS="
"
   while read -r line
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

      IFS="${DEFAULT_IFS}"

      local extname
      local vendor

      vendor="${extension%%/*}"
      extname="${extension##*/}"

      exttype="${exttype:-${defaultexttype}}"
      if [ "${exttype}" = "meta" ]
      then
         fail "A meta extension tried to inherit meta extension (\"${inheritfilename}\")"
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

      install_extension "${projecttype}" \
                        "${exttype}" \
                        "${vendor}" \
                        "${extname}" \
                        "${marks}" \
                        "${onlyfilename}" \
                        "${force}" \
                        "$@" || return 1
      IFS="
"
    done <<< "${text}"

   IFS="${DEFAULT_IFS}"
}


environment_mset_log()
{
   log_entry "environment_mset_log" "$@"

   local environment="$1"

   local line
   local key
   local value

   IFS="
"
   while read -r line
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

   IFS="
"
   while read -r line
   do
      log_debug "line: ${line}"
      case "${line}" in
         *\#\#*)
            fail "environment line \"${line}\": comment must not contain ##"
         ;;

         *\\\n*)
            fail "environment line \"${line}\": comment must not contain \\n (two characters)"
         ;;

         \#\ *)
            comment="`concat "${comment}" "${line:2}" "\\n"`"
            continue
         ;;

         \#*)
            comment="`concat "${comment}" "${line:1}" "\\n"`"
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

   [ ! -f "${filename}" ] && log_fluff "\"${filename}\" does not exist" && return

   if [ -z "${MULLE_SDE_LIBRARY_SH}" ]
   then
      # shellcheck source=src/mulle-sde-library.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-library.sh"
   fi

   local line

   IFS="
"
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
         MULLE_SOURCETREE_FLAGS="-e -N ${MULLE_SOURCETREE_FLAGS}" \
            eval sde_library_add_main --if-missing ${line} || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


add_to_dependencies()
{
   log_entry "add_to_dependencies" "$@"

   local filename="$1"

   if [ -z "${MULLE_SDE_DEPENDENCY_SH}" ]
   then
      # shellcheck source=src/mulle-sde-dependency.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-dependency.sh"
   fi

   [ ! -f "${filename}" ] && log_fluff "\"${filename}\" does not exist" && return

   local line

   IFS="
"
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
         MULLE_SOURCETREE_FLAGS="-e -N ${MULLE_SOURCETREE_FLAGS}" \
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

   [ ! -f "${filename}" ] && return

   log_debug "environment: `cat "${filename}"`"

   # add an empty linefeed for read
   text="`cat "${filename}"`"
   environment="`environmenttext_to_mset "${text}"`" || exit 1
   if [ -z "${environment}" ]
   then
      return
   fi

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
   then
      environment_mset_log "${environment}"
   fi

   # remove lf for command line
   environment="`tr '\n' ' ' <<< "${environment}"`"
   MULLE_VIRTUAL_ROOT="`pwd -P`" \
      eval_exekutor "'${MULLE_ENV}'" -s "${MULLE_ENV_FLAGS}" environment \
                           --share mset "${environment}" || exit 1
}


add_to_tools()
{
   log_entry "add_to_tools" "$@"

   local filename="$1"
   local scope="$2"

   if [ -f "${filename}.${MULLE_UNAME}" ]
   then
      filename="${filename}.${MULLE_UNAME}"
   else
      [ ! -f "${filename}" ] && log_fluff "\"${filename}\" does not exist" && return
   fi

   local line

   IFS="
"
   for line in `egrep -v '^#' "${filename}"`
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${line}" ]
      then
         log_verbose "Adding \"${line}\" to tool"
         MULLE_VIRTUAL_ROOT="`pwd -P`" \
            exekutor "${MULLE_ENV}" ${MULLE_ENV_FLAGS} tool --share ${scope} \
                                                       add "${line}" || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


run_init()
{
   log_entry "run_init" "$@"

   local executable="$1"
   local projectytpe="$2"
   local vendor="$3"
   local extname="$4"
   local marks="$5"
   local force="$6"

   if [ ! -x "${extensiondir}/init" ]
   then
      if [ -f "${extensiondir}/init" ]
      then
         fail "\"${extensiondir}/init\" must have execute permissions"
      else
         log_fluff "No init executable \"${extensiondir}/init\" found"
         return
      fi
   fi

   local flags
   local escaped

   # i need this for testing sometimes
   case "${OPTION_INIT_FLAGS}" in
      *,${vendor}/${extname}=*|${vendor}/${extname}=*)
         escaped="`escaped_sed_pattern "${vendor}/${extname}"`"

         flags="`sed -n -e "s/.*${escaped}=\\([^,]*\\).*/\\1/p" <<< "${OPTION_INIT_FLAGS}"`"
      ;;
   esac

   local auxflags

   if [ "${force}" = "YES" ]
   then
      auxflags="-f"
   fi

   log_warning "Running init script \"${executable}\""

   eval_exekutor OPTION_UPGRADE="${OPTION_UPGRADE}" \
                 OPTION_REINIT="${OPTION_REINIT}"
                     "${executable}" "${INIT_FLAGS}" "${flags}" \
                                                 "${auxflags}" \
                                                 --marks "'${marks}'" \
                                                 "${projecttype}" ||
      fail "init script \"${executable}\" failed"
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

      log_debug "\"${description}\" not disabled by \"$1\""
      shift
   done

   return 1
}


install_sourcetree_files()
{
   log_entry "install_sourcetree_files" "$@"

   local extensiondir="$1"
   local vendor="$2"
   local extname="$3"
   local marks="$4"

   if is_disabled_by_marks "${marks}" "${extensiondir}/dependency|library" \
                                      "no-sourcetree" \
                                      "no-sourcetree-${vendor}-${extname}"
   then
      return
   fi

   add_to_dependencies "${extensiondir}/dependency"
   add_to_libraries "${extensiondir}/library"
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

   mkdir_if_missing "${MULLE_SDE_DIR}/share/version/${vendor}"

   local flags

   if [ "${MULLE_FLAG_LOG_EXEKUTOR}" = "YES" ]
   then
      flags=-v
   fi

   exekutor cp ${flags} "${extensiondir}/version" \
                        "${MULLE_SDE_DIR}/share/version/${vendor}/${extname}"
   return 0 # why ?
}


_copy_extension_template_directory()
{
   log_entry "_copy_extension_template_directory" "$@"

   local extensiondir="$1"; shift
   local subdirectory="$1"; shift
   local projecttype="$1"; shift
   local force="$1"; shift


   local first="${projecttype}"
   local second="all"

   if [ "${force}" = "YES" ]
   then
      first="all"
      second="${projecttype}"
   fi

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
#
install_extension()
{
   log_entry "install_extension" "$@"

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
      log_fluff "Extension \"${vendor}/${extname}\" is already installed"
      return
   fi
   if [ "${exttype}" != "oneshot" ]
   then
      _INSTALLED_EXTENSIONS="`add_line "${_INSTALLED_EXTENSIONS}" "${vendor}/${extname};${exttype}"`"
   fi

   local extensiondir

   if ! extensiondir="`find_extension "${vendor}" "${extname}"`"
   then
      log_error "Could not find extension \"${extname}\" by \
vendor \"${vendor}\""
      return 1
   fi

   if [ ! -f "${extensiondir}/version" ]
   then
      fail "Extension \"${vendor}/${extname}\" is unversioned."
   fi

   case "${exttype}" in
      runtime)
         local tmp

         #
         # do this only once for the first runtime extension
         #
         if [ "${LANGUAGE_SET}" != "YES" ] && [ -f "${extensiondir}/language" ]
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
            log_fluff "Dialect extensions set to \"${PROJECT_EXTENSIONS}\""
            LANGUAGE_SET="YES"
         else
            log_fluff "No language file \"${extensiondir}/language\" found"
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

   if [ -z "${onlyfilename}" ]
   then
      local verb

      verb="Installing"
      if [ "${OPTION_UPGRADE}" = "YES" ]
      then
         verb="Upgrading"
      fi
      log_info "${verb} ${exttype} extension \"${vendor}/${extname}\""
   fi

   #
   # file is called inherit, so .gitignoring dependencies doesn't kill it
   #
   if ! is_disabled_by_marks "${marks}" "${extensiondir}/inherit" \
                                        "no-inherit" \
                                        "no-inherit/${vendor}/${extname}"
   then
      if [ -f "${extensiondir}/inherit" ]
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
            if [ -f "${filename}" ]
            then
               IFS="
"
               for line in `egrep -v '^#' "${filename}"`
               do
                  IFS="${DEFAULT_IFS}"
                  if [ ! -z "${line}" ]
                  then
                     inheritmarks="`comma_concat "${inheritmarks}" "${line}"`"
                  fi
               done
               IFS="${DEFAULT_IFS}"
            else
               log_fluff "No inheritmarks file \"${filename}\" found"
            fi
         fi

         install_inheritfile "${extensiondir}/inherit" \
                             "${projecttype}" \
                             "${exttype}" \
                             "${inheritmarks}" \
                             "${onlyfilename}" \
                             "${force}" \
                             "$@"  || exit 1
      else
         log_fluff "No inherit file \"${extensiondir}/inherit\" found"
      fi
   fi

   log_fluff "Installing ${exttype} extension \"${vendor}/${extname}\" for real now :P"

   # install version first
   if [ "${exttype}" != "oneshot" ]
   then
      install_version "${vendor}" "${extname}" "${extensiondir}"
   fi

   # meta only inherits stuff and doesn't add (except version)
   if [ "${exttype}" = "meta" ]
   then
      return
   fi

   #
   # mulle-env stuff
   #
   if ! is_disabled_by_marks "${marks}" "${extensiondir}/environment|tool|optionaltool" \
                                        "no-env" \
                                        "no-env/${vendor}/${extname}"
   then
      add_to_environment "${extensiondir}/environment"
      add_to_tools "${extensiondir}/tool"
      add_to_tools "${extensiondir}/optionaltool" "--optional"

      _copy_env_extension_dir "${extensiondir}/env" ||
         fail "Could not copy \"${extensiondir}/env\""

      _append_to_motd "${extensiondir}"
   fi

   #
   # project directory
   #  no-demo
   #  no-project
   #  no-clobber
   #
   if ! is_disabled_by_marks "${marks}" "${extensiondir}/demo" \
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

   # let project clobber demo
   if ! is_disabled_by_marks "${marks}" "${extensiondir}/project" \
                                        "no-project" \
                                        "no-project/${vendor}/${extname}"
   then
      _copy_extension_template_directory "${extensiondir}" \
                                         "project" \
                                         "${projecttype}" \
                                         "${force}" \
                                         "${onlyfilename}" \
                                         "$@"

      # install these only along with project
      install_sourcetree_files "${extensiondir}" \
                               "${vendor}" \
                               "${extname}" \
                               "${marks}"
   fi

   #
   # the clobber folder is like project but may always overwrite
   # this is used for refreshing cmake/share and such, where the user should
   # not edit
   #
   if ! is_disabled_by_marks "${marks}" "${extensiondir}/clobber" \
                                        "no-clobber" \
                                        "no-clobber/${vendor}/${extname}"
   then
      _copy_extension_template_directory "${extensiondir}" \
                                         "clobber" \
                                         "${projecttype}" \
                                         "YES" \
                                         "${onlyfilename}" \
                                         "$@"
   fi

   #
   # extension specific stuff . it's after project, so that you can do
   # magic in init, on a fairly complete project
   #
   #  no-share
   #  no-init
   #  no-sourcetree
   #
   if ! is_disabled_by_marks "${marks}" "${extensiondir}/share" \
                                        "no-share" \
                                        "no-share/${vendor}/${extname}"
   then
      _copy_extension_dir "${extensiondir}/share" "YES" "YES" ||
         fail "Could not copy \"${extensiondir}/share\""
   fi


   if ! is_disabled_by_marks "${marks}" "${extensiondir}/init" \
                                        "no-init" \
                                        "no-init/${vendor}/${extname}"
   then
      run_init "${extensiondir}/init" "${projecttype}" \
                                      "${exttype}" \
                                      "${vendor}" \
                                      "${extname}" \
                                      "${marks}" \
                                      "${force}"
   fi

}


install_motd()
{
   log_entry "install_motd" "$@"

   local text="$1"

   motdfile=".mulle-env/share/motd"

   if [ -z "${text}" ]
   then
      return
   fi

   # just clobber it
   local directory

   directory=".mulle-env/share"
   remove_file_if_present "${motdfile}"
   redirect_exekutor "${motdfile}" echo "${text}"
   exekutor chmod a-w "${motdfile}" || exit 1
}


fix_permissions()
{
   log_entry "fix_permissions" "$@"

   (
      shopt -s nullglob

      chmod +x "${MULLE_SDE_DIR}/bin"/* 2> /dev/null
      chmod +x "${MULLE_SDE_DIR}/libexec"/* 2> /dev/null
   )
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
   # Extra extensions must be fully qualified.
   #
   local extra
   local extra_vendor
   local extra_name

   IFS="
"; set -o noglob
   for extra in ${extras}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      case "${extra}" in
         "")
            continue
         ;;

         */*)
            extra_vendor="${extra%%/*}"
            extra_name="${extra##*/}"
         ;;

         *)
            fail "Extension \"${extra}\" must be fully qualified <vendor>/<extension>"
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
                        "${force}" || return 1
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


install_extra_extensions()
{
   log_entry "install_extra_extensions" "$@"

   _install_simple_extension "extra" "$@"
}


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

   #
   # also read old format
   # use mulle-env so we can get at it from the outside
   #
   if [ -f "${OPTION_EXTENSION_FILE}" ]
   then
      exekutor egrep -v '^#' < "${OPTION_EXTENSION_FILE}"
      return $?
   fi

   local value

   value="${MULLE_SDE_INSTALLED_EXTENSIONS}"
   if [ -z "${value}" ]
   then
      value="`rexekutor "${MULLE_ENV}" ${MULLE_TECHNICAL_FLAGS} \
                                        ${MULLE_ENV_FLAGS} environment get \
                                          MULLE_SDE_INSTALLED_EXTENSIONS`"
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

   mkdir_if_missing "${MULLE_SDE_DIR}/share"
   redirect_exekutor "${MULLE_SDE_DIR}/share/extension" echo "${extensions}"
}


install_extensions()
{
   log_entry "install_extensions" "$@"

   local marks="$1"
   local onlyfilename="$2"
   local force="$3"

   [ -z "${PROJECT_TYPE}" ] && internal_fail "missing PROJECT_NAME"
   [ -z "${PROJECT_NAME}" ] && internal_fail "missing PROJECT_NAME"

   # set to src as default for older projects
   PROJECT_SOURCE_DIR="${PROJECT_SOURCE_DIR:-src}"

   local runtime_vendor
   local buildtool_vendor
   local meta_name
   local runtime_name
   local buildtool_name

   local option
   local tmp

   local _INSTALLED_EXTENSIONS

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
                     "${force}" &&
   install_extension "${PROJECT_TYPE}" \
                     "runtime" \
                     "${runtime_vendor}" \
                     "${runtime_name}" \
                     "${marks}" \
                     "${onlyfilename}" \
                     "${force}" &&
   install_extension "${PROJECT_TYPE}" \
                     "buildtool" \
                     "${buildtool_vendor}" \
                     "${buildtool_name}" \
                     "${marks}" \
                     "${onlyfilename}" \
                     "${force}" || exit 1

   install_extra_extensions "${OPTION_EXTRAS}" \
                            "${PROJECT_TYPE}" \
                            "${marks}" \
                            "${onlyfilename}" \
                            "${force}" || exit 1

   install_oneshot_extensions "${OPTION_ONESHOTS}" \
                              "${PROJECT_TYPE}" \
                              "${marks}" \
                              "${onlyfilename}" \
                              "${force}" || exit 1

   fix_permissions

   #
   # remember type and installed extensions
   # also remember version and given project name, which we may need to
   # create files later after init
   #
   log_verbose "Environment: MULLE_SDE_INSTALLED_VERSION=\"${MULLE_EXECUTABLE_VERSION}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --share \
      set MULLE_SDE_INSTALLED_VERSION "${MULLE_EXECUTABLE_VERSION}" || \
            internal_fail "failed env set"

   memorize_installed_extensions "${_INSTALLED_EXTENSIONS}"
}


install_project()
{
   log_entry "install_project" "$@"

   local projecttype="$1"
   local marks="$2"
   local onlyfilename="$3"
   local force="$4"

   local PROJECT_LANGUAGE
   local PROJECT_DIALECT      # for objc
   local PROJECT_SOURCE_DIR
   local PROJECT_TYPE
   local LANGUAGE_SET

   LANGUAGE_SET="NO"
   PROJECT_NAME="${OPTION_NAME}"
   if [ -z "${PROJECT_NAME}" ]
   then
      PROJECT_NAME="`fast_basename "${PWD}"`"
   fi

   #
   # the project language is actually determined by the runtime
   # extension
   #
   PROJECT_LANGUAGE="${OPTION_LANGUAGE:-none}"
   PROJECT_SOURCE_DIR="${OPTION_PROJECT_SOURCE_DIR:-src}"
   PROJECT_TYPE="${projecttype}"

   #
   # put these first, so extensions can draw on these in their definitions
   #
   log_verbose "Environment: PROJECT_NAME=\"${PROJECT_NAME}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --project \
      set PROJECT_NAME "${PROJECT_NAME}" || internal_fail "failed env set"

   log_verbose "Environment: PROJECT_TYPE=\"${PROJECT_TYPE}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --project \
      set PROJECT_TYPE "${PROJECT_TYPE}" || internal_fail "failed env set"

   log_verbose "Environment: PROJECT_SOURCE_DIR=\"${PROJECT_SOURCE_DIR}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --project \
      set PROJECT_SOURCE_DIR "${PROJECT_SOURCE_DIR}" || internal_fail "failed env set"

   local _MOTD

   _MOTD=""


   install_extensions "$2" "$3" "$4"

   if [ ! -z "${onlyfilename}" ]
   then
      return
   fi

   #
   # setup the initial environment-global.sh (if missing) with some
   # values that the user may want to edit
   #
   log_verbose "Environment: PROJECT_LANGUAGE=\"${PROJECT_LANGUAGE}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --project \
      set PROJECT_LANGUAGE "${PROJECT_LANGUAGE}" || internal_fail "failed env set"

   log_verbose "Environment: PROJECT_DIALECT=\"${PROJECT_DIALECT}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --project \
      set PROJECT_DIALECT "${PROJECT_DIALECT}" || internal_fail "failed env set"

   log_verbose "Environment: PROJECT_EXTENSIONS=\"${PROJECT_EXTENSIONS}\""
   exekutor "${MULLE_ENV}" -s ${MULLE_ENV_FLAGS} environment --project \
      set PROJECT_EXTENSIONS "${PROJECT_EXTENSIONS}" || internal_fail "failed env set"


   case "${marks}" in
      no-motd|*,no-motd,*|*,no-motd)
      ;;

      *)
         if [ ! -z "${_MOTD}" ]
         then
            _MOTD="
"
         fi

         local motd

         motd="`printf "%b" "${C_INFO}Ready to build with:${C_RESET}${C_BOLD}
   mulle-sde craft${C_RESET}" `"

         _MOTD="${_MOTD}${motd}"

         install_motd "${_MOTD}"
      ;;
   esac
}


add_environment_variables()
{
   log_entry "add_environment_variables" "$@"

   local defines="$1"

   [ -z "${defines}" ] && return 0

   if [ "${OPTION_UPGRADE}" = "YES" -a "${_INFOED_ENV_RELOAD}" != "YES" ]
   then
      _INFOED_ENV_RELOAD="YES"
      log_warning "Use ${C_RESET_BOLD}mulle-env-reload${C_INFO} to get environment \
changes into your subshell"
   fi

   MULLE_VIRTUAL_ROOT="`pwd -P`" \
      eval_exekutor "'${MULLE_ENV}'" "${MULLE_ENV_FLAGS}" environment \
                           --share mset "${defines}" || exit 1
}


__sde_init_add()
{
   log_entry "_sde_init_add" "$@"

   [ "$#" -eq 0 ] || sde_init_usage "extranous arguments \"$*\""

   [ -z "${PROJECT_TYPE}" ] && fail "PROJECT_TYPE is not defined"
   [ -z "${PROJECT_SOURCE_DIR}" ] && fail "PROJECT_SOURCE_DIR is not defined"

   if [ ! -d "${MULLE_SDE_DIR}" ]
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

   add_environment_variables "${OPTION_DEFINES}"

   local _INSTALLED_EXTENSIONS

   _INSTALLED_EXTENSIONS="`recall_installed_extensions`"
   if [ -z "${_INSTALLED_EXTENSIONS}" ]
   then
      fail "Refusing to add as there are apparently no extensions defined here yet ? (MULLE_SDE_INSTALLED_EXTENSIONS is empty)"
   fi
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

   if [ -d "${MULLE_SDE_DIR}/share.old" ]
   then
      log_warning "Last upgrade failed. Restoring the last configuration."
      rmdir_safer "${MULLE_SDE_DIR}/share" &&
      exekutor mv "${MULLE_SDE_DIR}/share.old" "${MULLE_SDE_DIR}/share" &&
      rmdir_safer "${MULLE_SDE_DIR}/share.old"
   fi

   extensions="`recall_installed_extensions`"
   if [ -z "${extensions}" ]
   then
      log_fluff "No extensions found"
      return 1
   fi

   log_debug "Found extension: ${extensions}"

   local extension

   IFS="
"; set -o noglob
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
         newmarks="`comma_concat "${newmarks}" "${i}"`"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   echo "${newmarks}"
}


read_project_environment()
{
   if [ -z "${PROJECT_TYPE}" ]
   then
      PROJECT_TYPE="`exekutor "${MULLE_ENV}" ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} environment get PROJECT_TYPE`"
   fi

   # backwards compatibility
   if [ -z "${PROJECT_TYPE}" ]
   then
      PROJECT_TYPE="`exekutor "${MULLE_ENV}" ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} environment --scope aux get PROJECT_TYPE`"
   fi

   [ -z "${PROJECT_TYPE}" ] && \
     fail "Could not find required PROJECT_TYPE in environment. \
If you reinited the environment. Try:
   ${C_RESET}${C_BOLD}mulle-sde -e environment --project set PROJECT_TYPE library"


   if [ -z "${PROJECT_NAME}" ]
   then
      PROJECT_NAME="`exekutor "${MULLE_ENV}" ${MULLE_TECHNICAL_FLAGS} \
                     ${MULLE_ENV_FLAGS} environment get PROJECT_NAME`"
   fi
}


###
### parameters and environment variables
###
sde_init_main()
{
   log_entry "sde_init_main" "$@"

   local OPTION_NAME
   local OPTION_EXTRAS
   local OPTION_ONESHOTS
   local OPTION_COMMON="sde"
   local OPTION_META=""
   local OPTION_RUNTIME=""
   local OPTION_BUILDTOOL=""
   local OPTION_VENDOR="mulle-sde"
   local OPTION_INIT_ENV="YES"
   local OPTION_ENV_STYLE="mulle/wild" # wild is least culture shock initially
   local OPTION_BLURB="YES"
   local OPTION_TEMPLATE_FILES="YES"
   local OPTION_INIT_FLAGS
   local OPTION_MARKS=""
   local OPTION_DEFINES
   local OPTION_UPGRADE
   local OPTION_ADD
   local OPTION_REINIT
   local OPTION_EXTENSION_FILE=".mulle-sde/share/extension"
   local OPTION_PROJECT_FILE
   local OPTION_PROJECT_SOURCE_DIR

   local line

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
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            line="`mset_quoted_env_line "$1"`"
            OPTION_DEFINES="`concat "${OPTION_DEFINES}" "'${line}'" `"
         ;;

         -a|--add)
            OPTION_ADD="YES"
         ;;

         -b|--buildtool)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_BUILDTOOL="$1"
         ;;

         -d|--directory)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            exekutor mkdir -p "$1" 2> /dev/null
            exekutor cd "$1" || fail "can't change to \"$1\""
         ;;

         -e|--extra)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_EXTRAS="`add_line "${OPTION_EXTRAS}" "$1" `"
         ;;

         --oneshot-name)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            ONESHOT_NAME="$1"
            export ONESHOT_NAME
         ;;

         -o|--oneshot)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_ONESHOTS="`add_line "${OPTION_ONESHOTS}" "$1" `"
         ;;

         -i|--init-flags)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_INIT_FLAGS="$1"
         ;;

         -m|--meta)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_META="$1"
         ;;

         # little hack
         --upgrade-project-file)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_PROJECT_FILE="$1"
            OPTION_UPGRADE="YES"
            OPTION_BLURB="NO"
            # different marks, we upgrade project/demo/clobber!
            OPTION_MARKS="no-env,no-init,no-share,no-sourcetree"
            OPTION_INIT_ENV="NO"
         ;;


         -n|--name|--project-name)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_NAME="$1"
         ;;

         --source-dir|--project-source-dir)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_PROJECT_SOURCE_DIR="$1"
         ;;

         -r|--runtime)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_RUNTIME="$1"
         ;;

         -s|--style)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_ENV_STYLE="$1"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_VENDOR="$1"
         ;;

         --existing)
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "no-demo"`"
         ;;

         --extension-file)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_EXTENSION_FILE="$1"
         ;;

         --reinit)
            OPTION_REINIT="YES"
            OPTION_BLURB="NO"
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "no-project"`"
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "no-demo"`"
         ;;

         --upgrade)
            OPTION_UPGRADE="YES"
            OPTION_BLURB="NO"
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "no-demo"`"
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "no-sourcetree"`"
            OPTION_INIT_ENV="NO"
         ;;

         --no-blurb)
            OPTION_BLURB="NO"
         ;;

         --no-env)
            OPTION_INIT_ENV="NO"
         ;;

         --no-*)
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "${1:2}"`"
         ;;

         --allow-*)
            OPTION_MARKS="`remove_from_marks "${OPTION_MARKS}" "no-${1:8}"`"
         ;;

         -*)
            sde_init_usage "unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ "${OPTION_INIT_ENV}" = "YES" ]
   then
      [ -z "${MULLE_VIRTUAL_ROOT}" ] || \
         fail "You can not run init inside an environment shell"
   fi

   if [ "${OPTION_UPGRADE}" = "YES" ]
   then
      [ -z "${MULLE_VIRTUAL_ROOT}" ] && \
         fail "An extension upgrade must run inside an environment shell"
   fi

   [ "${OPTION_REINIT}" = "YES" -a "${OPTION_UPGRADE}" = "YES" ] && \
      fail "--reinit and --upgrade exclude each other"

   if [ -z "${MULLE_PATH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"
   fi

   if [ -z "${MULLE_FILE}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"
   fi

   if [ -z "${MULLE_SDE_EXTENSION_SH}" ]
   then
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-extension.sh" || exit 1
   fi

   if [ "${MULLE_SDE_ETC_DIR}" = "${MULLE_SDE_DIR}/etc" ]
   then
      MULLE_SDE_ETC_DIR=".mulle-sde/etc"
   fi
   MULLE_SDE_DIR=".mulle-sde"

   if [ "${OPTION_ADD}" = "YES" ]
   then
      [ "${OPTION_REINIT}" = "YES" -o "${OPTION_UPGRADE}" = "YES" ] && \
      fail "--add and --reinit/--upgrade exclude each other"

      __sde_init_add "$@"
      return $?
   fi

   if [ "${OPTION_REINIT}" = "YES" -o "${OPTION_UPGRADE}" = "YES" ]
   then
      [ ! -d "${MULLE_SDE_DIR}" ] && fail "\"${PWD}\" is not a mulle-sde project (${MULLE_SDE_DIR} is missing)"

      if ! __get_installed_extensions
      then
         fail "Could not retrieve previous extension information"
      fi

      if [ -z "${OPTION_NAME}" ]
      then
         OPTION_NAME="`exekutor "${MULLE_ENV}" ${MULLE_TECHNICAL_FLAGS} \
                         ${MULLE_ENV_FLAGS} environment get PROJECT_NAME`"
      fi

      # once useful to repair lost files
      read_project_environment
   else
      [ $# -eq 0 ] && sde_init_usage "missing project type"
      [ $# -eq 1 ] || sde_init_usage "extranous arguments \"$*\""

      PROJECT_TYPE="$1"
   fi

   case "${PROJECT_TYPE}" in
      "")
         fail "project type is \"\""
      ;;

      empty|library|executable|extension)
      ;;

      *)
         log_warning "\"${PROJECT_TYPE}\" is not a standard project type.
Some files may be missing and the project may not be craftable."
      ;;
   esac

   #
   # An upgrade is an "inplace" refresh of the extensions
   #
   if [ "${OPTION_REINIT}" != "YES" -a "${OPTION_UPGRADE}" != "YES" -a \
        -d "${MULLE_SDE_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != "YES" ]
      then
         if [ -f "${MULLE_SDE_DIR}/.init" ]
         then
            fail "There is already a ${MULLE_SDE_DIR} folder in \"$PWD\". \
It looks like an init gone bad."
         fi

         fail "There is already a ${MULLE_SDE_DIR} folder in \"$PWD\". \
Use \`mulle-sde upgrade\` for maintainance"
      fi
   fi

   #
   # if we init env now, then extensions can add environment
   # variables and tools
   #
   if [ "${OPTION_INIT_ENV}" = "YES" ]
   then
      local flags

      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "YES" ]
      then
         flags="-f"
      fi

      exekutor "${MULLE_ENV}" ${MULLE_ENV_FLAGS} ${flags} \
                                 --style "${OPTION_ENV_STYLE}" \
                                 init --no-blurb
      case $? in
         0)
         ;;

         2)
            log_fluff "mulle-env warning noted, but ignored"
         ;;

         *)
            exit 1
         ;;
      esac
   fi

   add_environment_variables "${OPTION_DEFINES}"

   mkdir_if_missing "${MULLE_SDE_DIR}" || exit 1
   redirect_exekutor "${MULLE_SDE_DIR}/.init" echo "Start init: `date`"

   #
   # always wipe these for clean upgrades
   # except if we are just updating a specific project file
   # (i.e. CMakeLists.txt). Keep "extension" file around in case something
   # goes wrong. Also temporarily keep old share
   #
   if [ -z "${OPTION_PROJECT_FILE}" ]
   then
      rmdir_safer "${MULLE_SDE_DIR}/share.old"
      if [ -d "${MULLE_SDE_DIR}/share" ]
      then
         exekutor mv "${MULLE_SDE_DIR}/share" "${MULLE_SDE_DIR}/share.old"
      fi
      rmdir_safer ".mulle-sde/var"
   fi

   # rmdir_safer ".mulle-env"
   if [ "${OPTION_UPGRADE}" = "YES" ]
   then
      if ! install_extensions "${OPTION_MARKS}" \
                              "${OPTION_PROJECT_FILE}" \
                              "${MULLE_FLAG_MAGNUM_FORCE}"
      then
         if [ -d "${MULLE_SDE_DIR}/share.old" ]
         then
            log_info "The upgrade failed. Restoring old configuration."
            rmdir_safer "${MULLE_SDE_DIR}/share"
            exekutor mv "${MULLE_SDE_DIR}/share.old" "${MULLE_SDE_DIR}/share"
            remove_file_if_present "${MULLE_SDE_DIR}/.init"
         else
            fail "Things went really bad, can't restore old configuration"
         fi
      fi
   else
      install_project "${PROJECT_TYPE}" \
                      "${OPTION_MARKS}" \
                      "${OPTION_PROJECT_FILE}" \
                      "${MULLE_FLAG_MAGNUM_FORCE}"
   fi

   rmdir_safer "${MULLE_SDE_DIR}/share.old"
   remove_file_if_present "${MULLE_SDE_DIR}/.init"

   if [ "${OPTION_BLURB}" = "YES" ]
   then
      log_info "Enter the environment:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} \"${PWD}\"${C_INFO}"
   fi
}
