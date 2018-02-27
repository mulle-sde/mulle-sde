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

   INIT_USAGE_NAME="${INIT_USAGE_NAME:-${MULLE_EXECUTABLE_NAME} init}"

   COMMON_OPTIONS="\
   -D <key>=<val> : specify an environment variable
   -d <dir>       : directory to populate (working directory)
   -e <extra>     : specify extra extensions. Multiple -e <extra> are possible
   -m <meta>      : specify meta extensions
   -p <name>      : project name"

   HIDDEN_OPTIONS="\
   -b <buildtool> : specify the buildtool extension to use
   --no-demo      : do not install gratuitous demo files, like main.c
   -r <runtime>   : specify runtime extension to use
   -v <vendor>    : extension vendor to use (mulle-sde)"

   cat <<EOF >&2
Usage:
   ${INIT_USAGE_NAME} [options] <type>

   See with \`mulle-sde extension list\`  what extensions are available on
   your system. Pick a meta extension to install. Check with
   \`mulle-sde extension usage\` what types are available from your chosen
   extension.  Create a mulle-sde project with your chosen type.

   e.g.  mulle-sde init -m mulle-sde:c-cmake executable

   Use \`mulle-sde extension add\` to add extra extensions.

Options:
EOF
   (
      echo "${COMMON_OPTIONS}"
      if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
      then
         echo "${HIDDEN_OPTIONS}"
      fi
   ) | sort

   echo "      (\`${MULLE_EXECUTABLE_NAME} -v init help\` for more options)"
   exit 1
}


_copy_extension_dir()
{
   log_entry "_copy_extension_dir" "$@"

   local directory="$1"
   local overwrite="${2:-YES}"
   local writeprotect="${3:-NO}"

   local flags

   if [ "${MULLE_FLAG_LOG_FLUFF}" = "YES" ]
   then
      flags=-v
   fi

   #
   # the extensions have "overwrite" semantics, so that previous
   # files are overwritten. So force is not interesting here
   # except for "etc" stuff, which is considered to be sacred as it
   # can be edited by the user
   #
   if [ "${overwrite}" = "NO" ]
   then
      flags="${flags} -n"  # don't clobber
   fi

   if [ -d "${directory}" ]
   then
      log_fluff "Installing from \"${directory}\""

      local name

      name="`fast_basename "${directory}"`"
      if [ -d "${MULLE_SDE_DIR}/${name}" ]
      then
         exekutor chmod -R a+wX "${MULLE_SDE_DIR}/${name}"
      fi
      exekutor cp -Ra ${flags} "${directory}" "${MULLE_SDE_DIR}/" &&
      if [ "${writeprotect}" = "YES" ]
      then
         exekutor chmod -R a-w "${MULLE_SDE_DIR}/${name}"
      fi
   fi
}


_append_to_motd()
{
   log_entry "_append_to_motd" "$@"

   local extensiondir="$1"

   local text

   if [ -f "${extensiondir}/motd" ]
   then
      text="`LC_ALL=C egrep -v '^#' "${extensiondir}/motd" `"
      if [ ! -z "${text}" -a "${text}" != "${_MOTD}" ]
      then
         log_fluff "Append \"${extensiondir}/motd\" to motd"
         _MOTD="`add_line "${_MOTD}" "${text}" `"
      fi
   fi
}


_copy_extension_template_files()
{
   log_entry "_copy_extension_template_files" "$@"

   local extensiondir="$1"; shift
   local projecttype="$1"; shift
   local subdirectory="$1"; shift
   local force="$1"; shift
   local file_seds="$1"; shift

   local projectdir

   projectdir="${extensiondir}/${subdirectory}/${projecttype}"
   if [ ! -d "${projectdir}" ]
   then
      projectdir="${extensiondir}/${subdirectory}/all"
   fi

   #
   # copy and expand stuff from project folder. Be extra careful not to
   # clobber project files, except if -f is given
   #
   if [ -d "${projectdir}" ]
   then
      if [ -z "${MULLE_SDE_INITSUPPORT_SH}" ]
      then
         . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-template.sh" || internal_fail "include fail"
      fi

      if [ "${force}" = "YES" ]
      then
         force="-f"
      else
         force=""
      fi

      # put in own shell to avoid side effects
      (
         eval _template_main --embedded \
                             '${force}' \
                             --template-dir "'${projectdir}'" \
                             --name "'${PROJECT_NAME}'" \
                             --language "'${PROJECT_LANGUAGE}'" \
                             --dialect "'${PROJECT_DIALECT}'" \
                             "${OPTION_USERDEFINES}"
      ) || fail "template generation failed"
   else
      log_fluff "No project files to copy, as \"${projectdir}\" is not there ($PWD)"
   fi
}


_run_extension_init()
{
   log_entry "_run_extension_init" "$@"

   local extensiondir="$1"
   local flags="$2"
   local projecttype="$3"

   if [ -x "${extensiondir}/init" ]
   then
      log_warning "Running init script \"${extensiondir}/init\""
      eval_exekutor "${extensiondir}/init" ${INIT_FLAGS} "${flags}" "${projecttype}" \
        || fail "init script \"${extensiondir}/init\" failed"
   else
      log_fluff "No init script \"${extensiondir}/init\" found"
   fi
}


install_dependency_extension()
{
   log_entry "install_dependency_extension" "$@"

   local projecttype="$1"; shift
   local exttype="$1"; shift
   local dependency="$1"; shift
   local marks="$1"; shift
   local force="$1"; shift

   local extension
   local addmarks
   local extname
   local vendor

   extension="${dependency%%;*}"
   addmarks="${dependency##*;}"

   vendor="${extension%%:*}"
   extname="${extension##*:}"

   marks="`comma_concat "${marks}" "${addmarks}"`"

   install_extension "${projecttype}" \
                     "${exttype}" \
                     "${extname}" \
                     "${vendor:-mulle-sde}" \
                     "${marks}" \
                     "${force}" \
                     "$@"
}


install_inheritfile()
{
   log_entry "install_inheritfile" "$@"

   local inheritfilename="$1" ; shift
   local projecttype="$1" ; shift
   local defaultexttype="$1" ; shift
   local marks="$1" ; shift
   local force="$1" ; shift

   local text

   text="`LC_ALL=C egrep -s -v '^#' "${inheritfilename}"`"

   log_debug "text: $text"

   #
   # read needs IFS set for each iteration, whereas
   # for only for the first iteration.
   # shell programming...
   #
   local line

   IFS="
"
   while read -r line
   do
      local dependency
      local exttype

      case "${line}" in
         "")
            continue
         ;;

         *\;*)
            dependency="${line%%;*}"
            exttype="${line##*;}"
         ;;

         *)
            dependency="${line}"
         ;;
      esac

      log_debug "read \"${line}\" -> \"${dependency}\";\"${exttype}\""

      IFS="${DEFAULT_IFS}"

      install_dependency_extension "${projecttype}" \
                                   "${exttype:-${defaultexttype}}" \
                                   "${dependency}" \
                                   "${marks}" \
                                   "${force}" \
                                   "$@"
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
      key="${1%%=*}"
      value="${1#${key}=}"
      value="${value%##*}"

      log_verbose "Environment: ${key:1}=${value%?}"

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
      case "${line}" in
         *\#\#*)
            fail "environment line \"${line}\": comment must not contain ##"
         ;;

         *\\\n*)
            fail "environment line \"${line}\": comment must not contain \\n (two characters)"
         ;;

         \#\ *)
            comment="`concat "${comment:2}" "${line}" "\\n"`"
            continue
         ;;

         \#*)
            comment="`concat "${comment:1}" "${line}" "\\n"`"
            continue
         ;;

         "")
            continue
         ;;

         *=\"*\")
         ;;

         *)
            fail "environment line \"${line}\": must be of form <key>=\"<value>\""
         ;;
      esac

      # use "${x%##*}" to retrieve line
      # use "${x##*##}" to retrieve comment
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

   if [ -z "${MULLE_SDE_LIBRARY_SH}" ]
   then
      # shellcheck source=src/mulle-sde-library.sh
      . "${MULLE_SDE_LIBEXEC_DIR}/mulle-sde-library.sh"
   fi

   local line

   IFS="
"
   for line in `egrep -s -v -e '^#' "${filename}"`
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

   local line

   IFS="
"
   for line in `egrep -s -v -e '^#' "${filename}"`
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
            eval sde_dependency_add_main --if-missing ${line} || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


add_to_tools()
{
   log_entry "add_to_dependencies" "$@"

   local filename="$1"

   if [ -f "${filename}.${MULLE_UNAME}" ]
   then
      filename="${filename}.${MULLE_UNAME}"
   fi

   local line

   IFS="
"
   for line in `egrep -s -v -e '^#' "${filename}"`
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${line}" ]
      then
         log_verbose "Adding \"${line}\" to tools"
         MULLE_VIRTUAL_ROOT="${PWD}" \
            exekutor "${MULLE_ENV}" tool add "${line}" || exit 1
      fi
   done
   IFS="${DEFAULT_IFS}"
}


install_extension()
{
   log_entry "install_extension" "$@"

   local projecttype="$1"; shift
   local exttype="$1"; shift
   local extname="$1"; shift
   local vendor="$1"; shift
   local marks="$1"; shift
   local force="$1"; shift

   # user can turn off extensions by passing ""
   if [ -z "${extname}" ]
   then
      return
   fi

   if fgrep -q -s -x "${vendor}:${extname}" <<< "${_INSTALLED_EXTENSIONS}"
   then
      log_fluff "Extension \"${vendor}:${extname}\" is already installed"
      return
   fi
   _INSTALLED_EXTENSIONS="`add_line "${_INSTALLED_EXTENSIONS}" "${vendor}:${extname}"`"

   local extensiondir

   if ! extensiondir="`find_extension "${vendor}" "${extname}"`"
   then
      log_error "Could not find extension \"${extname}\" by \
vendor \"${vendor}\""
      return 1
   fi

   if [ ! -f "${extensiondir}/share/version/${vendor}/${extname}" ]
   then
      fail "Extension \"${vendor}:${extname}\" is unversioned."
   fi

   case "${exttype}" in
      runtime)
         local tmp

         if [ -f "${extensiondir}/language" ]
         then
            tmp="`egrep -v -e '^#' < "${extensiondir}/language"`"
            if [ ! -z "${tmp}" ]
            then
               PROJECT_LANGUAGE="${tmp}"
               log_fluff "Project language set to \"${PROJECT_LANGUAGE}\""
            fi
         else
            log_fluff "No language file \"${extensiondir}/language\" found"
         fi

         if [ -f "${extensiondir}/dialect" ]
         then
            tmp="`egrep -v -e '^#' < "${extensiondir}/dialect"`"
            if [ ! -z "${tmp}" ]
            then
               PROJECT_DIALECT="${tmp}"
               log_fluff "Project dialect set to \"${PROJECT_DIALECT}\""
            fi
         else
            log_fluff "No language file \"${extensiondir}/dialect\" found"
         fi
      ;;

      meta|extra|buildtool)
      ;;

      *)
         internal_fail "Unknown extension type \"${exttype}\""
      ;;
   esac

   log_info "Installing ${exttype} extension \"${vendor}:${extname}\""

   #
   # it's called inherit, so .ignoringdependencies doesn't kill it
   # when syncing f.e.
   #
   case "${marks}" in
      *no-inherit*|*no-${exttype}-inherit*)
         log_fluff "${vendor}:${extname}: ignoring \
 \"${extensiondir}/inherit\" due to no-dependency mark"
      ;;

      *)
         if [ -f "${extensiondir}/inherit" ]
         then
            install_inheritfile "${extensiondir}/inherit" \
                                "${projecttype}" \
                                "${exttype}" \
                                "${marks}" \
                                "${force}" \
                                "$@"
         else
            log_fluff "No inherit file \"${extensiondir}/inherit\" found"
         fi
      ;;
   esac

   local environment
   local text

   if [ -f "${extensiondir}/environment" ]
   then
      log_debug "environment: `cat "${extensiondir}/environment"`"

      # add an empty linefeed for read
      text="`cat "${extensiondir}/environment"`"
      environment="`environmenttext_to_mset "${text}"`" || exit 1
      if [ ! -z "${environment}" ]
      then
         if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
         then
            environment_mset_log "${environment}"
         fi
         MULLE_VIRTUAL_ROOT="${PWD}" \
            eval_exekutor "'${MULLE_ENV}'" "${MULLE_ENV_FLAGS}" environment \
                                 --share mset "${environment}" || exit 1
      fi
   else
      log_fluff "No environment file \"${extensiondir}/environment\" found"
   fi

   if [ -f "${extensiondir}/dependency" ]
   then
      add_to_dependencies "${extensiondir}/dependency"
   else
      log_fluff "No dependency file \"${extensiondir}/dependency\" found"
   fi

   if [ -f "${extensiondir}/library" ]
   then
      add_to_libraries "${extensiondir}/library"
   else
      log_fluff "No library file \"${extensiondir}/library\" found"
   fi

   if [ -f "${extensiondir}/tool" ]
   then
      add_to_tools "${extensiondir}/tool"
   else
      log_fluff "No tool file \"${extensiondir}/tool\" found"
   fi

   case "${marks}" in
      *no-share*|*no-${exttype}-share*)
         log_fluff "${vendor}:${extname}: ignoring ${MULLE_SDE_DIR}/share directories \
due to marks"
      ;;

      *)
         #
         # make share protected, so that files aren't accidentally
         # edited
         #
         _copy_extension_dir "${extensiondir}/share" "YES" "YES" ||
            fail "Could not copy \"${extensiondir}/share\""
      ;;
   esac

   case "${marks}" in
      *no-init*|*no-${exttype}-init*)
         log_fluff "${vendor}:${extname}: ignoring an init script due to marks"
      ;;

      *)
         local flags
         local escaped

         # i need this for testing somtimes
         case "${OPTION_INIT_FLAGS}" in
            *,${vendor}:${extname}=*|${vendor}:${extname}=*)
               escaped="`escaped_sed_pattern "${vendor}:${extname}"`"

               flags="`sed -n -e "s/.*${escaped}=\\([^,]*\\).*/\\1/p" <<< "${OPTION_INIT_FLAGS}"`"
            ;;
         esac

         _run_extension_init "${extensiondir}" "${flags}" "${projecttype}"
      ;;
   esac

   # project and other custom stuff
   case "${marks}" in
      *no-project*|*no-${exttype}-project*)
         log_fluff "${vendor}:${extname}: ignoring any project files due to marks"
      ;;

      *)
         _copy_extension_template_files "${extensiondir}" \
                                        "${projecttype}" \
                                        "project" \
                                        "${force}" \
                                        "$@"
      ;;
   esac

   # demo main.c files stuff like this
   case "${marks}" in
      *no-demo*|*no-${exttype}-demo*)
         log_fluff "${vendor}:${extname}: ignoring any demo files due to marks"
      ;;

      *)
         _copy_extension_template_files "${extensiondir}" \
                                        "${projecttype}" \
                                        "demo" \
                                        "${force}" \
                                        "$@"
      ;;
   esac

   case "${marks}" in
      *no-motd*|*no-${exttype}-motd*)
         log_fluff "${vendor}:${extname}: ignoring any motd info due to \
marks"
      ;;

      *)
         _append_to_motd "${extensiondir}"
      ;;
   esac
}


install_motd()
{
   log_entry "install_motd" "$@"

   local text="$1"

   motdfile=".mulle-env/etc/motd"

   if [ -z "${text}" ]
   then
      return
   fi

   # just clobber it
   redirect_exekutor ".mulle-env/etc/motd" echo "${text}"
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


install_extra_extensions()
{
   log_entry "install_extra_extensions" "$@"

   local projecttype="$1"
   local marks="$2"
   local force="$3"

   #
   # optionally install "extra" extensions
   # f.e. a "git" extension could auto-init the project and create
   # a .gitignore file
   #
   # Extra extensions must be fully qualified.
   #
   local extra
   local extra_vendor
   local extra_name
   local option

   IFS="
"; set -o noglob
   for extra in ${OPTION_EXTRAS}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      case "${extra}" in
         "")
            continue
         ;;

         *:*)
            extra_vendor="${extra%%:*}"
            extra_name="${extra##*:}"
         ;;

         *)
            fail  "Extra extension \"${extra}\" must be fully qualifier <vendor>:<extension>"
         ;;
      esac

      [ -z "${extra_name}" ]   && fail "Missing extension name \"${extra}\""
      [ -z "${extra_vendor}" ] && fail "Missing extension vendor \"${extra}\""

      install_extension "${projecttype}" \
                        "extra" \
                        "${extra_name}" \
                        "${extra_vendor}" \
                        "${marks}" \
                        "${force}"

      option="--extra `colon_concat "${extra_vendor}" "${extra_name}"`"
      cmdline_options="`concat "${cmdline_options}" "${option}"`"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


install_project()
{
   log_entry "install_project" "$@"

   local projecttype="$1"
   local marks="$2"
   local force="$3"

   local runtime_vendor
   local buildtool_vendor
   local meta_name
   local runtime_name
   local buildtool_name

   local cmdline_options
   local option

   if [ ! -z "${OPTION_META}" ]
   then
      if [ ! -z "${OPTION_RUNTIME}" -o ! -z "${OPTION_BUILDTOOL}" ]
      then
         log_warning "Specifying --meta together with --runtime or --buildtool is unusual"
      fi

      case "${OPTION_META}" in
         *:*)
            meta_vendor="${OPTION_META%%:*}"
            meta_name="${OPTION_META##*:}"
         ;;

         *)
            meta_vendor="${OPTION_VENDOR}"
            meta_name="${OPTION_META}"
         ;;
      esac

      option="--meta `colon_concat "${meta_vendor}" "${meta_name}"`"
      cmdline_options="`concat "${cmdline_options}" "${option}"`"
   fi

   if [ ! -z "${OPTION_RUNTIME}" ]
   then
      case "${OPTION_RUNTIME}" in
         *:*)
            runtime_vendor="${OPTION_RUNTIME%%:*}"
            runtime_name="${OPTION_RUNTIME##*:}"
         ;;

         *)
            runtime_vendor="${OPTION_VENDOR}"
            runtime_name="${OPTION_RUNTIME}"
         ;;
      esac

      option="--meta `colon_concat "${runtime_vendor}" "${runtime_name}"`"
      cmdline_options="`concat "${cmdline_options}" "${option}"`"
   fi

   if [ ! -z "${OPTION_BUILDTOOL}" ]
   then
      case "${OPTION_BUILDTOOL}" in
         *:*)
            buildtool_vendor="${OPTION_BUILDTOOL%%:*}"
            buildtool_name="${OPTION_BUILDTOOL##*:}"
         ;;

         *)
            buildtool_vendor="${OPTION_VENDOR}"
            buildtool_name="${OPTION_BUILDTOOL}"
         ;;
      esac

      option="--meta `colon_concat "${buildtool_vendor}" "${buildtool_name}"`"
      cmdline_options="`concat "${cmdline_options}" "${option}"`"
   fi

   local PROJECT_NAME
   local PROJECT_LANGUAGE
   local PROJECT_DIALECT      # for objc

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

   local _MOTD
   local _INSTALLED_EXTENSIONS

   _MOTD=""

   #
   # always wipe these during init
   # if you want to "add" an extra extension, then you need to reinit with
   # all extensions, otherwise it's not reproducable
   #
   # https://github.com/mulle-sde/mulle-sde/wiki/.mulle-sde-directory
   #
   rmdir_safer "${MULLE_SDE_DIR}/var"

   # we wipe this, if we aren't adding
   rmdir_safer "${MULLE_SDE_DIR}/share"

   #
   # buildtool is the most likely to fail, due to a mistyped
   # projectdir, if that happens, we have done the least pollution yet
   #
   install_extension "${projecttype}" \
                     "meta" \
                     "${meta_name}" \
                     "${meta_vendor}" \
                     "${marks}" \
                     "${force}" &&
   install_extension "${projecttype}" \
                     "runtime" \
                     "${runtime_name}" \
                     "${runtime_vendor}" \
                     "${marks}" \
                     "${force}" &&
   install_extension "${projecttype}" \
                     "buildtool" \
                     "${buildtool_name}" \
                     "${buildtool_vendor}" \
                     "${marks}" \
                     "${force}" || exit 1

   install_extra_extensions "${projecttype}" "${marks}" "${force}"

   #
   # remember type and installed extensions
   # also remember version and given project name, which we may need to
   # create files later after init
   #
   log_verbose "Environment: MULLE_SDE_INSTALLED_VERSION=\"${MULLE_EXECUTABLE_VERSION}\""
   exekutor "${MULLE_ENV}" environment --share set MULLE_SDE_INSTALLED_VERSION "${MULLE_EXECUTABLE_VERSION}"

   #
   # setup the initial environment-all.sh (if missing) with some
   # values that the user may want to edit
   #
   log_verbose "Environment: MULLE_SDE_INSTALLED_EXTENSIONS=\"${cmdline_options}"\"
   exekutor "${MULLE_ENV}" environment --share set MULLE_SDE_INSTALLED_EXTENSIONS "${cmdline_options}"

   log_verbose "Environment: PROJECT_NAME=\"${PROJECT_NAME}\""
   exekutor "${MULLE_ENV}" environment --share set PROJECT_NAME "${PROJECT_NAME}"

   log_verbose "Environment: PROJECT_LANGUAGE=\"${PROJECT_LANGUAGE}\""
   exekutor "${MULLE_ENV}" environment --share set PROJECT_LANGUAGE "${PROJECT_LANGUAGE}"

   log_verbose "Environment: PROJECT_DIALECT=\"${PROJECT_DIALECT}\""
   exekutor "${MULLE_ENV}" environment --share set PROJECT_DIALECT "${PROJECT_DIALECT}"

   log_verbose "Environment: PROJECT_TYPE=\"${projecttype}\""
   exekutor "${MULLE_ENV}" environment --share set PROJECT_TYPE "${projecttype}"


   fix_permissions

   case "${marks}" in
      *no-motd*)
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
   log_entry "sde_init_main" "$@"

   local defines="$1"

   MULLE_VIRTUAL_ROOT="${PWD}" \
      eval_exekutor "'${MULLE_ENV}'" "${MULLE_ENV_FLAGS}" environment \
                           mset "${defines}" || exit 1
}


_sde_init_add()
{
   [ "$#" -eq 0 ] || sde_init_usage "extranous arguments \"$*\""

   [ -z "${PROJECT_TYPE}" ] && fail "PROJECT_TYPE is not defined"

   if [ ! -d "${MULLE_SDE_DIR}" ]
   then
      fail "You must init first, before you can add and extra extension"
   fi

   if [ ! -z "${OPTION_RUNTIME}" -o \
        ! -z "${OPTION_BUILDTOOL}" -o \
        ! -z "${OPTION_META}" ]
   then
      fail "Only extra extensions can be added"
   fi

   if [ -z "${OPTION_EXTRA}" ]
   then
      fail "You must specify an extra extensions to be added"
   fi

   add_environment_variables "${OPTION_DEFINES}"

   install_extra_extensions "${PROJECT_TYPE}" \
                            "${OPTION_MARKS}" \
                            "${MULLE_FLAG_MAGNUM_FORCE}"
}


###
### parameters and environment variables
###
sde_init_main()
{
   log_entry "sde_init_main" "$@"

   local OPTION_NAME
   local OPTION_EXTRAS
   local OPTION_COMMON="sde"
   local OPTION_META=""
   local OPTION_RUNTIME=""
   local OPTION_BUILDTOOL=""
   local OPTION_VENDOR="mulle-sde"
   local OPTION_INIT_ENV="YES"
   local OPTION_ENV_STYLE="mulle:wild" # wild is least culture shock initially
   local OPTION_BLURB=""
   local OPTION_TEMPLATE_FILES="YES"
   local OPTION_INIT_FLAGS
   local OPTION_MARKS=""
   local OPTION_DEFINES
   local OPTION_UPGRADE
   local OPTION_ADD

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
            keyvalue="`sed s'/^-D//' <<< "$1"`"
            OPTION_DEFINES="`concat "${OPTION_DEFINES}" "'${1:2}'" `"
         ;;

         -D)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_DEFINES="`concat "${OPTION_DEFINES}" "'$1'" `"
         ;;

         -a|--add)
            OPTION_ADD="YES"
         ;;

         -b|--buildtool)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_BUILDTOOL="`tr 'A-Z' 'a-z' <<< "$1" `"
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

            local extra

            extra="`tr 'A-Z' 'a-z' <<< "$1" `"
            OPTION_EXTRAS="`add_line "${OPTION_EXTRAS}" "${extra}" `"
         ;;

         -i|--init-flags)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_INIT_FLAGS="$1"
         ;;

         -m|--meta)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_META="`tr 'A-Z' 'a-z' <<< "$1" `"
         ;;

         -p|--project-name)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_NAME="$1"
         ;;

         -r|--runtime)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_RUNTIME="`tr 'A-Z' 'a-z' <<< "$1" `"
         ;;

         -v|--vendor)
            [ $# -eq 1 ] && sde_init_usage "missing argument to \"$1\""
            shift

            OPTION_VENDOR="$1"
         ;;

         --upgrade)
            OPTION_UPGRADE="YES"
         ;;

         --no-blurb)
            OPTION_BLURB="--no-blurb"
         ;;

         --no-env)
            OPTION_INIT_ENV="NO"
         ;;

         --no-*)
            OPTION_MARKS="`concat "${OPTION_MARKS}" "${1:2}"`"
         ;;

         --style|--env-style)
            [ $# -eq 1 ] && sde_init_usage  "missing argument to \"$1\""
            shift

            OPTION_ENV_STYLE="$1"
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
      _sde_init_add "$@"
      return $?
   fi

   local projecttype
   local env_blurb

   projecttype="$1"
   [ -z "${projecttype}" ] && sde_init_usage "missing project type"
   [ "$#" -eq 1 ] || sde_init_usage "extranous arguments \"$*\""
   shift

   if [ "${OPTION_UPGRADE}" != "YES" -a -d "${MULLE_SDE_DIR}" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "YES" ]
      then
         rmdir_safer "${MULLE_SDE_DIR}"
         # rmdir_safer ".mulle-env"
      else
         fail "There is already a ${MULLE_SDE_DIR} folder here. \
Use \`mulle-sde upgrade\` for maintainance"
      fi
   fi

   #
   # if we init env now, then extensions can add environment variables
   # and tools
   #

   if [ "${OPTION_INIT_ENV}" = "YES" ]
   then
      exekutor "${MULLE_ENV}" ${MULLE_ENV_FLAGS} init --no-blurb \
                             --style "${OPTION_ENV_STYLE}"
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

   case "${projecttype}" in
      empty|library|executable|extension)
      ;;

      *)
         log_warning "\"${projecttype}\" is not a standard project type.
Some files may be missing and the project may not be craftable."
      ;;
   esac


   install_extra_extensions "${projecttype}" "${marks}" "${force}"

   if ! install_project "${projecttype}" \
                        "${OPTION_MARKS}" \
                        "${MULLE_FLAG_MAGNUM_FORCE}"
   then
      exit 1
   fi

   if [ "${OPTION_BLURB}" != "NO" ]
   then
      log_info "Enter the environment:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} \"${PWD}\"${C_INFO}"
   fi
}
