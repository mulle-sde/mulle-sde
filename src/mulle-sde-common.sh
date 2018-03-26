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


commalist_add()
{
   log_entry "commalist_add" "$@"

   local list="$1"
   local value="$2"

   if commalist_contains "${list}" "${value}"
   then
      log_info "\"${value}\" already set"
      return 0
   fi
   comma_concat "${list}" "${value}"
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
      echo "$i"
   done

   IFS="${DEFAULT_IFS}"; set +o noglob
}


os_excludes_print()
{
   log_entry "os_excludes_add" "$@"

   local list="$1"

   set -o noglob ; IFS=","
   for i in ${list}
   do
      case "$i" in
         no-os-*)
            LC_ALL=C sed -e "s/^no-os-//" <<< "${i}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


os_excludes_validate()
{
   log_entry "os_excludes_validate" "$@"

   case "$1" in
      no-*)
         fail "exclude-os \"$1\" must not start with \"no-\""
      ;;
      os-*)
         fail "exclude-os \"$1\" must not start with \"os-\""
      ;;
   esac
}


os_excludes_add()
{
   log_entry "os_excludes_add" "$@"

   local list="$1"
   local add="$2"

   local i

   # is this faster than case ?
   set -o noglob ; IFS=","
   for i in ${add}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      os_excludes_validate "$1"
      i="no-os-$i"

      if commalist_contains "${list}" "$i"
      then
         continue
      fi

      list="`comma_concat "${list}" "$i" `"
   done

   IFS="${DEFAULT_IFS}"; set +o noglob

   echo "${list}"
}


_sourcetree_set_os_excludes()
{
   log_entry "_sourcetree_set_os_excludes" "$@"

   local address="$1"
   local value="$2"
   local stdmarks="$3"
   local append="${4:-NO}"
   local byurl="$5"

   local mode

   if [ "${byurl}" = "YES " ]
   then
      mode="--url-addressing"
   fi

   local marks

   marks="${stdmarks}"
   if [ "${append}" = "YES" ]
   then
      marks="`exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} ${mode} \
                get "${address}" "marks" `"
   fi

   marks="`os_excludes_add "${marks}" "${value}" `"
   exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} ${mode} \
      set "${address}" "marks" "${marks}"
}


sourcetree_append_os_excludes()
{
   log_entry "sourcetree_append_os_excludes" "$@"

   _sourcetree_set_os_excludes "$1" "$2" "$3" "YES"
 }


sourcetree_set_os_excludes()
{
   log_entry "sourcetree_set_os_excludes" "$@"

   _sourcetree_set_os_excludes "$1" "$2" "$3" "NO"
}


sourcetree_get_os_excludes()
{
   log_entry "sourcetree_get_os_excludes" "$@"

   local address="$1"
   local byurl="$2"

   local mode

   if [ "${byurl}" = "YES " ]
   then
      mode="--url-addressing"
   fi

   local marks

   marks="`exekutor "${MULLE_SOURCETREE}" -s ${MULLE_SOURCETREE_FLAGS} ${mode} \
            get "${address}" "marks" `"
   [ $? -eq 0 ] || return 1

   os_excludes_print "${marks}"
}


sourcetree_get_os_excludes_by_url()
{
   log_entry "sourcetree_get_os_excludes_by_url" "$@"

   local address="$1"
   local byurl="$2"

   local mode

   if [ "${byurl}" = "YES " ]
   then
      mode="--url-addressing"
   fi

   local marks

   marks="`exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} ${mode} \
              get "${address}" "marks" `"
   [ $? -eq 0 ] || return 1

   os_excludes_print "${marks}"
}


_sourcetree_set_userinfo_field()
{
   log_entry "_sourcetree_set_userinfo_field" "$@"

   local address="$1"
   local field="$2"
   local value="$3"
   local append="${4:-NO}"
   local byurl="$5"

   local mode

   if [ "${byurl}" = "YES " ]
   then
      mode="--url-addressing"
   fi

   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} ${mode} \
                 get "${address}" "userinfo" `" || return 1

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || exit 1
   fi

   if [ "${append}" = "YES" ]
   then
      aliases="`assoc_array_get "${userinfo}" "${field}" `"
      value="`commalist_add "${aliases}" "${value}" `"
   fi

   userinfo="`assoc_array_set "${userinfo}" "${field}" "${value}" `"
   exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} \
      set "${address}" "userinfo" "${userinfo}"
}


sourcetree_set_userinfo_field()
{
   log_entry "sourcetree_set_userinfo_field" "$@"

   _sourcetree_set_userinfo_field "$1" "$2" "$3" "YES" "$4"
 }


sourcetree_append_userinfo_field()
{
   log_entry "sourcetree_append_userinfo_field" "$@"

   _sourcetree_set_userinfo_field "$1" "$2" "$3" "NO" "$4"
}


sourcetree_get_userinfo_field()
{
   log_entry "sourcetree_append_userinfo_field" "$@"

   local address="$1"
   local field="$2"
   local byurl="$3"

   local mode

   if [ "${byurl}" = "YES " ]
   then
      mode="--url-addressing"
   fi

   local userinfo

   userinfo="`exekutor "${MULLE_SOURCETREE}" ${MULLE_SOURCETREE_FLAGS} ${mode} \
            get "${address}" "userinfo" `"
   if [ $? -ne 0 ]
   then
      return 1
   fi

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || exit 1
   fi

   local list

   list="`assoc_array_get "${userinfo}" "${field}"`"
   commalist_print "${list}"
}


