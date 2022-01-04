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
MULLE_SDE_COMMON_SH="included"


sde::common::commalist_contains()
{
   log_entry "sde::common::commalist_contains" "$@"

   local list="$1"
   local key="$2"

   local i

   # is this faster than case ?
   shell_disable_glob ; IFS=","
   for i in ${list}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob
      if [ "${i}" = "${key}" ]
      then
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"; shell_enable_glob
   return 1
}


sde::common::r_commalist_add()
{
   log_entry "commalist_add" "$@"

   local list="$1"
   local value="$2"

   if sde::common::commalist_contains "${list}" "${value}"
   then
      log_info "\"${value}\" already set"
      return 0
   fi
   r_comma_concat "${list}" "${value}"
}


sde::common::commalist_print()
{
   log_entry "sde::common::commalist_print" "$@"

   local list="$1"

   local i

   # is this faster than case ?
   shell_disable_glob; IFS=","
   for i in ${list}
   do
      printf "%s\n" "$i"
   done

   IFS="${DEFAULT_IFS}"; shell_enable_glob
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
   log_entry "sde::common::_append_platform_excludes" "$@"

   local list="$1"

   shell_disable_glob ; IFS=","
   for i in ${list}
   do
      case "$i" in
         no-platform-*)
            LC_ALL=C sed -e "s/^no-platform-//" <<< "${i}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
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


sde::common::_append_platform_excludes()
{
   log_entry "sde::common::_append_platform_excludes" "$@"

   local list="$1"
   local add="$2"

   local i

   # is this faster than case ?
   shell_disable_glob ; IFS=","
   for i in ${add}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      sde::common::validate_platform_excludes "$1"
      i="no-platform-$i"

      if sde::common::commalist_contains "${list}" "$i"
      then
         continue
      fi

      r_comma_concat "${list}" "$i"
      list="${RVAL}"
   done

   IFS="${DEFAULT_IFS}"; shell_enable_glob

   printf "%s\n" "${list}"
}


sde::common::_set_platform_excludes()
{
   log_entry "sde::common::_set_platform_excludes" "$@"

   local address="$1"
   local value="$2"
   local stdmarks="$3"
   local append="${4:-NO}"

   local marks

   marks="${stdmarks}"
   if [ "${append}" = 'YES' ]
   then
      marks="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  --virtual-root \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS}  \
                get "${address}" "marks" `"
   fi

   marks="`sde::common::_append_platform_excludes "${marks}" "${value}" `"
   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               --virtual-root \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS}  \
            set "${address}" "marks" "${marks}"
}


sde::common::append_platform_excludes()
{
   log_entry "sde::common::append_platform_excludes" "$@"

   sde::common::_set_platform_excludes "$1" "$2" "$3"
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
               ${MULLE_SOURCETREE_FLAGS} \
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
   local append="${4:-NO}"

   case "${value}" in
      *$'\n'*)
         fail "Value can't contain newlines"
      ;;
   esac

   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                     --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS}  \
                 get "${address}" "userinfo" `" || return 1

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || return 1
   fi

   if [ "${append}" = 'YES' ]
   then
      r_assoc_array_get "${userinfo}" "${field}"
      sde::common::r_commalist_add "${RVAL}" "${value}"
      value="${RVAL}"
   fi

   r_assoc_array_set "${userinfo}" "${field}" "${value}"
   userinfo="${RVAL}"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                      --virtual-root \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS}  \
                  set "${address}" "userinfo" "${userinfo}"
}


sde::common::set_sourcetree_userinfo_field()
{
   log_entry "sde::common::set_sourcetree_userinfo_field" "$@"

   sde::common::_set_userinfo_field "$1" "$2" "$3" 'YES' "$4"
}


sde::common::append_sourcetree_userinfo_field()
{
   log_entry "sde::common::append_sourcetree_userinfo_field" "$@"

   sde::common::_set_userinfo_field "$1" "$2" "$3" 'NO' "$4"
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
               ${MULLE_SOURCETREE_FLAGS}  \
            get "${address}" "userinfo" `"

   if [ $? -ne 0 ]
   then
      return 1
   fi

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || exit 1
   fi

   r_assoc_array_get "${userinfo}" "${field}"
   sde::common::commalist_print "${RVAL}"
}


sde::common::include_nodemarks_if_needed()
{
   if [ -z "${MULLE_SOURCETREE_NODEMARKS_SH}" ]
   then
      if [ -z "${MULLE_SOURCETREE_LIBEXEC_DIR}" ]
      then
         MULLE_SOURCETREE_LIBEXEC_DIR="`"${MULLE_SOURCETREE:-mulle-sourcetree}" libexec-dir`"
      fi
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodemarks.sh" || exit 1
   fi
}


sde::common::marks_compatible_with_marks()
{
   sde::common::include_nodemarks_if_needed

   sourcetree::nodemarks::compatible_with_nodemarks "$1" "$2"
}
