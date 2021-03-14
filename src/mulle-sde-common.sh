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


commalist_contains()
{
   log_entry "commalist_contains" "$@"

   local list="$1"
   local key="$2"

   local i

   # is this faster than case ?
   set -o noglob ; IFS=","
   for i in ${list}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob
      if [ "${i}" = "${key}" ]
      then
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"; set +o noglob
   return 1
}


r_commalist_add()
{
   log_entry "commalist_add" "$@"

   local list="$1"
   local value="$2"

   if commalist_contains "${list}" "${value}"
   then
      log_info "\"${value}\" already set"
      return 0
   fi
   r_comma_concat "${list}" "${value}"
}


commalist_print()
{
   log_entry "commalist_print" "$@"

   local list="$1"

   local i

   # is this faster than case ?
   set -o noglob; IFS=","
   for i in ${list}
   do
      printf "%s\n" "$i"
   done

   IFS="${DEFAULT_IFS}"; set +o noglob
}


sde_sourcetree_platform_excludes_print()
{
   log_entry "sde_sourcetree_platform_excludes_add" "$@"

   local list="$1"

   set -o noglob ; IFS=","
   for i in ${list}
   do
      case "$i" in
         no-platform-*)
            LC_ALL=C sed -e "s/^no-platform-//" <<< "${i}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


sde_sourcetree_platform_excludes_validate()
{
   log_entry "sde_sourcetree_platform_excludes_validate" "$@"

   case "$1" in
      no-*)
         fail "exclude platform \"$1\" must not start with \"no-\""
      ;;

      platform-*)
         fail "exclude platform \"$1\" must not start with \"platform-\""
      ;;
   esac
}


sde_sourcetree_platform_excludes_add()
{
   log_entry "sde_sourcetree_platform_excludes_add" "$@"

   local list="$1"
   local add="$2"

   local i

   # is this faster than case ?
   set -o noglob ; IFS=","
   for i in ${add}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      sde_sourcetree_platform_excludes_validate "$1"
      i="no-platform-$i"

      if commalist_contains "${list}" "$i"
      then
         continue
      fi

      r_comma_concat "${list}" "$i"
      list="${RVAL}"
   done

   IFS="${DEFAULT_IFS}"; set +o noglob

   printf "%s\n" "${list}"
}


_sde_set_sourcetree_platform_excludes()
{
   log_entry "_sde_set_sourcetree_platform_excludes" "$@"

   local address="$1"
   local value="$2"
   local stdmarks="$3"
   local append="${4:-NO}"

   local marks

   marks="${stdmarks}"
   if [ "${append}" = 'YES' ]
   then
      marks="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                  -V \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_SOURCETREE_FLAGS}  \
                get "${address}" "marks" `"
   fi

   marks="`sde_sourcetree_platform_excludes_add "${marks}" "${value}" `"
   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               -V \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS}  \
            set "${address}" "marks" "${marks}"
}


sde_append_sourcetree_platform_excludes()
{
   log_entry "sde_append_sourcetree_platform_excludes" "$@"

   _sde_set_sourcetree_platform_excludes "$1" "$2" "$3" 
 }


sde_set_sourcetree_platform_excludes()
{
   log_entry "sde_set_sourcetree_platform_excludes" "$@"

   _sde_set_sourcetree_platform_excludes "$1" "$2" "$3" 
}


sde_get_sourcetree_platform_excludes()
{
   log_entry "sde_get_sourcetree_platform_excludes" "$@"

   local address="$1"

   local marks

   marks="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               -V -s \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_SOURCETREE_FLAGS} \
            get "${address}" "marks" `"
   [ $? -eq 0 ] || return 1

   sde_sourcetree_platform_excludes_print "${marks}"
}



_sde_set_sourcetree_userinfo_field()
{
   log_entry "_sde_set_sourcetree_userinfo_field" "$@"

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
                     -V \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS}  \
                 get "${address}" "userinfo" `" || return 1

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || exit 1
   fi

   if [ "${append}" = 'YES' ]
   then
      r_assoc_array_get "${userinfo}" "${field}"
      r_commalist_add "${RVAL}" "${value}"
      value="${RVAL}"
   fi

   r_assoc_array_set "${userinfo}" "${field}" "${value}"
   userinfo="${RVAL}"

   exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
                      -V \
                     ${MULLE_TECHNICAL_FLAGS}  \
                     ${MULLE_SOURCETREE_FLAGS}  \
                  set "${address}" "userinfo" "${userinfo}"
}


sde_set_sourcetree_userinfo_field()
{
   log_entry "sde_set_sourcetree_userinfo_field" "$@"

   _sde_set_sourcetree_userinfo_field "$1" "$2" "$3" 'YES' "$4"
}


sde_append_sourcetree_userinfo_field()
{
   log_entry "sde_append_sourcetree_userinfo_field" "$@"

   _sde_set_sourcetree_userinfo_field "$1" "$2" "$3" 'NO' "$4"
}


sde_get_sourcetree_userinfo_field()
{
   log_entry "sde_get_sourcetree_userinfo_field" "$@"

   local address="$1"
   local field="$2"
   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE:-mulle-sourcetree}" \
               -V \
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
   commalist_print "${RVAL}"
}


sde_include_nodemarks_if_needed()
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


sde_marks_compatible_with_marks()
{
   sde_include_nodemarks_if_needed

   nodemarks_compatible_with_nodemarks "$1" "$2"
}
