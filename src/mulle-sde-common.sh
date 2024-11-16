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
MULLE_SDE_COMMON_SH='included'


sde::common::commalist_contains()
{
   log_entry "sde::common::commalist_contains" "$@"

   local list="$1"
   local key="$2"

   local i

   # is this faster than case ?
   .foreachitem i in ${list}
   .do
      if [ "${i}" = "${key}" ]
      then
         return 0
      fi
   .done

   return 1
}


sde::common::r_commalist_add()
{
   log_entry "sde::common::r_commalist_add" "$@"

   local list="$1"
   local value="$2"

   if sde::common::commalist_contains "${list}" "${value}"
   then
      log_info "\"${value}\" already set"
      return 0
   fi
   r_comma_concat "${list}" "${value}"
}


sde::common::r_commalist_remove()
{
   log_entry "sde::common::r_commalist_remove" "$@"

   local list="$1"
   local value="$2"

   if ! sde::common::commalist_contains "${list}" "${value}"
   then
      log_verbose "\"${value}\" already empty"
      return 0
   fi

   r_escaped_sed_replacement "${value}"
   value="${RVAL}"

   RVAL=",${list},"
   RVAL="${RVAL/,${value},/,}"
   r_remove_ugly "${RVAL}" ","
}



sde::common::commalist_print()
{
   log_entry "sde::common::commalist_print" "$@"

   local list="$1"

   local i

   .foreachitem i in ${list}
   .do
      printf "%s\n" "$i"
   .done
}



sde::common::exekutor_sourcetree_nofail()
{
   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
            "$@" || exit 1
}


sde::common::rexekutor_sourcetree_nofail()
{
   rexekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
            "$@" || exit 1
}



sde::common::print_platform_excludes()
{
   log_entry "sde::common::print_platform_excludes" "$@"

   local list="$1"

   .foreachitem i in ${list}
   .do
      case "$i" in
         no-platform-*)
            LC_ALL=C sed -e "s/^no-platform-//" <<< "${i}"
         ;;
      esac
   .done
}


sde::common::validate_platform_excludes()
{
   log_entry "sde::common::validate_platform_excludes" "$@"

   case "$1" in
      no-*)
         fail "exclude platform \"$1\" must not start with \"no-\""
      ;;

      platform-*)
         fail "exclude platform \"$1\" must not start with \"platform-\""
      ;;
   esac
}


sde::common::r_append_platform_excludes()
{
   log_entry "sde::common::r_append_platform_excludes" "$@"

   local list="$1"
   local add="$2"

   local i

   # is this faster than case ?
   .foreachitem i in ${add}
   .do
      sde::common::validate_platform_excludes "$i"
      i="no-platform-$i"

      sde::common::r_commalist_add "${list}" "$i"
      list="${RVAL}"
   .done

   RVAL="${list}"
}

sde::common::r_remove_platform_excludes()
{
   log_entry "sde::common::r_remove_platform_excludes" "$@"

   local list="$1"
   local remove="$2"

   local i

   # is this faster than case ?
   .foreachitem i in ${remove}
   .do
      sde::common::validate_platform_excludes "$i"
      i="no-platform-$i"

      sde::common::r_commalist_remove "${list}" "$i"
      list="${RVAL}"
   .done

   RVAL="${list}"
}


sde::common::_set_platform_excludes()
{
   log_entry "sde::common::_set_platform_excludes" "$@"

   local address="$1"
   local value="$2"
   local stdmarks="$3"
   local operation="${4:-}"

   case "${value}" in
      *$'\n'*)
         fail "Value can't contain newlines"
      ;;
   esac


   local marks

   marks="${stdmarks}"
   if [ ! -z "${operation}" ]
   then
      marks="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS:-}  \
                get "${address}" "marks" `"
   fi

   if [ ${operation} = 'REMOVE' ]
   then
      sde::common::r_remove_platform_excludes "${marks}" "${value}"
   else
      sde::common::r_append_platform_excludes "${marks}" "${value}"
   fi
   marks="${RVAL}"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS:-}  \
            set "${address}" "marks" "${marks}"
}


sde::common::remove_platform_excludes()
{
   log_entry "sde::common::remove_platform_excludes" "$@"

   sde::common::_set_platform_excludes "$1" "$2" "$3" "REMOVE"
}


sde::common::append_platform_excludes()
{
   log_entry "sde::common::append_platform_excludes" "$@"

   sde::common::_set_platform_excludes "$1" "$2" "$3" "APPEND"
}


sde::common::set_platform_excludes()
{
   log_entry "sde::common::set_platform_excludes" "$@"

   sde::common::_set_platform_excludes "$1" "$2" "$3"
}


sde::common::get_platform_excludes()
{
   log_entry "sde::common::get_platform_excludes" "$@"

   local address="$1"

   local marks

   marks="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               -s \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS:-} \
            get "${address}" "marks" `"
   [ $? -eq 0 ] || return 1

   sde::common::print_platform_excludes "${marks}"
}


sde::common::_set_userinfo_field()
{
   log_entry "sde::common::_set_userinfo_field" "$@"

   local address="$1"
   local field="$2"
   local value="$3"
   local operation="${4:-}"

   case "${value}" in
      *$'\n'*)
         fail "Value can't contain newlines"
      ;;
   esac

   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS:-}  \
                 get "${address}" "userinfo" `" || return 1

   include "array"

   case "${operation}" in
      'APPEND')
         r_assoc_array_get "${userinfo}" "${field}"
         sde::common::r_commalist_add "${RVAL}" "${value}"
         value="${RVAL}"
      ;;

      'REMOVE')
         r_assoc_array_get "${userinfo}" "${field}"
         sde::common::r_commalist_remove "${RVAL}" "${value}"
         value="${RVAL}"
      ;;
   esac

   r_assoc_array_set "${userinfo}" "${field}" "${value}"
   userinfo="${RVAL}"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                      --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS:-}  \
                  set "${address}" "userinfo" "${userinfo}"
}


sde::common::set_sourcetree_userinfo_field()
{
   log_entry "sde::common::set_sourcetree_userinfo_field" "$@"

   sde::common::_set_userinfo_field "$1" "$2" "$3" ''
}


sde::common::append_sourcetree_userinfo_field()
{
   log_entry "sde::common::append_sourcetree_userinfo_field" "$@"

   sde::common::_set_userinfo_field "$1" "$2" "$3" 'APPEND'
}

sde::common::remove_sourcetree_userinfo_field()
{
   log_entry "sde::common::remove_sourcetree_userinfo_field" "$@"

   sde::common::_set_userinfo_field "$1" "$2" "$3" 'REMOVE'
}


sde::common::r_get_sourcetree_userinfo_field()
{
   log_entry "sde::common::r_get_sourcetree_userinfo_field" "$@"

   local address="$1"
   local field="$2"

   shift 2

   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS:-}  \
            get "$@" "${address}" "userinfo" `"

   if [ $? -ne 0 ]
   then
      return 1
   fi

   include "array"

   r_assoc_array_get "${userinfo}" "${field}"
}


sde::common::get_sourcetree_userinfo_field()
{
   log_entry "sde::common::get_sourcetree_userinfo_field" "$@"

   sde::common::r_get_sourcetree_userinfo_field "$@"
   sde::common::commalist_print "${RVAL}"
}


sde::common::list_sourcetree_userinfo_fields()
{
   log_entry "sde::common::list_sourcetree_userinfo_field" "$@"

   local address="$1"

   shift 1

   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS:-}  \
            get "$@" "${address}" "userinfo" `"

   if [ $? -ne 0 ]
   then
      return 1
   fi

   include "array"

   assoc_array_all_keys "${userinfo}"
}



sde::common::marks_compatible_with_marks()
{
   include "sourcetree::marks"

   sourcetree::marks::compatible_with_marks "$1" "$2"
}



sde::common::update_git_if_needed()
{
   log_entry "sde::common::update_git_if_needed" "$@"

   local directory="$1"
   local repository_url="$2"
   local branch="${3:-master}"

   local git_dir

   git_dir="${directory}/.git"

   local last_touch

   include "file"

   last_touch="`modification_timestamp "${git_dir}" 2> /dev/null`"
   if [ -z "${last_touch}" ] # missing
   then
      if [ -d "${directory}" -o -z "${repository_url}" ]
      then
         return # nothing we can do, use as is
      fi

      local name

      r_basename "${directory}"
      name="${RVAL}"

      local parent_dir

      r_mkdir_parent_if_missing "${directory}"
      parent_dir="${RVAL}"

      (
         exekutor cd "${parent_dir}"                \
         && exekutor git clone --depth 1            \
                               --single-branch      \
                               --branch "${branch}" \
                               "${repository_url}"  \
                               "${name}"
      )
      return $?
   fi

   local refresh_date

   refresh_date=$(( $last_touch + ${GIT_REFRESH_SECONDS:-86400} ))
   if [ `timestamp_now` -lt ${refresh_date} ]
   then
      return
   fi

   (
      exekutor cd "${directory}" \
      && exekutor git pull \
      && exekturo touch "${git_dir}"
   )
}


sde::common::maybe_exec_external_command()
{
   log_entry "sde::common::maybe_exec_external_command" "$@"

   local cmd="$1"
   local name="$2"
   local directory="$3"
   local show_readme="$4"

   shift 4

   local alias_name
   local escaped_name

   r_escaped_sed_pattern "${name}"
   escaped_name="${name}"

   if [ -f "${directory}/aliases.txt" ]
   then
      alias_name="`grep -v -E '^#' "${directory}/aliases.txt" \
                  | sed -n "/^[[:alnum:]_]/ s/^${escaped_name}[[:space:]]*=[[:space:]]*//p" \
                  | head -1 `"
      if [ ! -z "${alias_name}" ]
      then
         log_info "Alias \"${alias_name}\" found for \"${name}\""
         name="${alias_name}"
      fi
   fi

#   local version=""
#
#   if [ ! -z "${version}" ]
#   then
#      fail "Can't deal with versions yet"
#   fi

   if [ "${show_readme}" = 'YES' ]
   then
      local readme

      readme="${directory}/${name}/README.md"
      if [ -f "${readme}" ]
      then
         cat "${readme}"
      fi
   fi

   local name1
   local name2

   case "${name}" in
      lib*)
         name1="${name#lib}"
         name2="${name}"
      ;;

      *)
         name1="${name}"
         name2="lib${name}"
      ;;
   esac


   local executable

   if [ ! -z "${name1}" ]
   then
      if [ -f "${directory}/${name1}/${cmd}" ]
      then
         executable="${directory}/${name1}/${cmd}"
      fi
   fi

   if [ -z "${executable}" -a ! -z "${name2}" ]
   then
      if [ -f "${directory}/${name2}/${cmd}" ]
      then
         executable="${directory}/${name2}/${cmd}"
      fi
   fi

   if [ ! -z "${executable}" ]
   then
      # use sh to execute, need not be executable bit set then
      # also forces bash shell for compatibility...
      export MULLE_UNAME="${MULLE_UNAME}"
      export MULLE_USERNAME="${MULLE_USERNAME}"
      export MULLE_HOSTNAME="${MULLE_HOSTNAME}"

      exekutor exec sh "${executable}" "$@"
      exit 1
   else
      log_verbose "No external command for \"${name}\" found"
   fi
}


sde::common::export_sourcetree_node()
{
   log_entry "sde::common::export_sourcetree_node" "$@"

   local type="$1"         # dependency or library
   local address="$2"
   local default_marks="$3"

   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid
   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   if ! eval_text="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS:-}  \
            get "${address}" all `"
   then
      fail "No ${type} found for \"${address}\""
   fi

   eval "${eval_text}"

   log_setting "_address=${_address}"
   log_setting "_branch=${_branch}"
   log_setting "_fetchoptions=${_fetchoptions}"
   log_setting "_marks=${_marks}"
   log_setting "_nodetype=${_nodetype}"
   log_setting "_raw_userinfo=${_raw_userinfo}"
   log_setting "_tag=${_tag}"
   log_setting "_url=${_url}"
   log_setting "_userinfo=${_userinfo}"
   log_setting "_uuid=${_uuid}"
   log_setting "_evaledurl=${_evaledurl}"
   log_setting "_evalednodetype${_evalednodetype}"
   log_setting "_evaledbranch=${_evaledbranch}"
   log_setting "_evaledtag=${_evaledtag}"
   log_setting "_evaledfetchoptions=${_evaledfetchoptions}"

   printf "mulle-sde ${type} add --address '${_address}' \\\\\n  --nodetype '${_nodetype}'"
   if [ ! -z "${_evaledbranch}" ]
   then
      printf " \\\\\n   --branch '${_branch}'"
   else
      if [ ! -z "${_evaledtag}" ]
      then
         printf " \\\\\n   --tag '${_tag}'"
      fi
   fi
   if [ ! -z "${_fetchoptions}" ]
   then
      printf " \\\\\n   --fetchoptions '${_fetchoptions}'"
   fi
   if [ ! -z "${_url}" ]
   then
      printf "  \\\\\n  '${_url}'"
   fi
   printf "\n"


   #
   # now we figure out which marks are changed compared to the default
   # dependency marks and issue mark and unmark commands
   #
   if [ "${_marks}" != "${default_marks}" ]
   then
      include "sourcetree::marks"

      local mark

      .foreachitem mark in ${default_marks}
      .do
         if sourcetree::marks::contain "${_marks}" "${mark}"
         then
            .continue
         fi
         printf "mulle-sde dependency unmark '${_address}' '${mark}'\n"
      .done

      .foreachitem mark in ${_marks}
      .do
         if sourcetree::marks::contain "${default_marks}" "${mark}"
         then
            .continue
         fi
         printf "mulle-sde dependency mark '${_address}' '${mark}'\n"
      .done
   fi

   #
   # finally copy over userinfo settings we know about
   #
   local fields
   local field

   include "array"

   fields="`assoc_array_all_keys "${_userinfo}" `"
   .foreachline field in ${fields}
   .do
      sde::common::r_get_sourcetree_userinfo_field "${_address}" "${field}"
      r_escaped_singlequotes "${RVAL}"
      printf "mulle-sde ${type} set '${_address}' '${field}' '${RVAL}'\n"
   .done
}
