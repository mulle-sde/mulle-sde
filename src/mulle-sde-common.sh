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


sde::common::get_sourcetree_userinfo_field()
{
   log_entry "sde::common::get_sourcetree_userinfo_field" "$@"

   local address="$1"
   local field="$2"
   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS:-}  \
            get "${address}" "userinfo" `"

   if [ $? -ne 0 ]
   then
      return 1
   fi

   include "array"

   r_assoc_array_get "${userinfo}" "${field}"
   sde::common::commalist_print "${RVAL}"
}



sde::common::marks_compatible_with_marks()
{
   include "sourcetree::marks"

   sourcetree::marks::compatible_with_marks "$1" "$2"
}
