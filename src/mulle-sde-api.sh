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
MULLE_SDE_API_SH="included"


sde::api::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} api <cmd>

   Show API documentation (TOC.md files) from dependencies. AI friendly!

Examples:
      mulle-sde api list
      mulle-sde api show 2
      mulle-sde api show mulle-core
      mulle-sde api find header zlib.h
      mulle-sde api find library libz.a

Commands:
      list           : list available API documentation from dependencies
      show <name>    : show API doc by number or dependency name
      find <type> <name> : find header or library file in dependencies
      
Find types:
      header         : find header file (e.g., zlib.h)
      library        : find library file (e.g., libz.a)
      symbol         : find symbol in headers (quick hack, may not work well)
      
EOF
   exit 1
}


#
# Collect API documentation from dependencies
# API docs are in share/<name>/dox/TOC.md or share/<name>/TOC.md
# Returns list of paths in RVAL and count as return code
#
sde::api::r_collect_apis()
{
   log_entry "sde::api::r_collect_apis" "$@"
   
   local display="${1:-NO}"
   
   log_debug "display: '${display}'"
   
   local apis
   local count=0
   local dependency_dir
   
   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true
   
   log_debug "dependency_dir='${dependency_dir}'"
   
   if [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ]
   then
      log_debug "No dependency_dir or doesn't exist"
      RVAL=""
      return 0
   fi
   
   local searchpath=':Release:Debug:RelDebug'
   local subdir
   local repo
   local api
   
   .foreachpath subdir in ${searchpath}
   .do
      log_debug "Checking ${dependency_dir}/${subdir}/share"
      if [ -d "${dependency_dir}/${subdir}/share" ]
      then
         for repo in "${dependency_dir}/${subdir}/share"/*
         do
            log_debug "Checking repo: ${repo}"
            if [ -d "${repo}" ]
            then
               r_basename "${repo}"
               local reponame="${RVAL}"
               
               # Try share/<name>/dox/TOC.md first
               api="${repo}/dox/TOC.md"
               if [ -f "${api}" ]
               then
                  count=$((count + 1))
                  log_debug "Found ${api}, count=${count}"
                  
                  if [ "${display}" = 'YES' ]
                  then
                     printf "%2d. %-30s\n" "${count}" "${reponame}"
                  fi
                  
                  r_colon_concat "${apis}" "${api}"
                  apis="${RVAL}"
                  continue
               fi
               
               # Try share/<name>/TOC.md as fallback
               api="${repo}/TOC.md"
               if [ -f "${api}" ]
               then
                  count=$((count + 1))
                  log_debug "Found ${api}, count=${count}"
                  
                  if [ "${display}" = 'YES' ]
                  then
                     printf "%2d. %-30s\n" "${count}" "${reponame}"
                  fi
                  
                  r_colon_concat "${apis}" "${api}"
                  apis="${RVAL}"
               fi
            fi
         done
         
         # Only search first existing subdir
         .break
      fi
   .done
   
   log_debug "Total count: ${count}"
   log_debug "Collected apis: ${apis}"
   
   RVAL="${apis}"
   return ${count}
}


sde::api::list()
{
   log_entry "sde::api::list" "$@"
   
   sde::api::r_collect_apis 'YES'
   local count=$?
   
   if [ ${count} -eq 0 ]
   then
      log_info "No API documentation found (dependencies not yet crafted?)"
      return 1
   fi
   
   return 0
}


sde::api::show()
{
   log_entry "sde::api::show" "$@"

   local identifier="$1"
   
   [ -z "${identifier}" ] && sde::api::usage "Missing argument (number or dependency name)"
   
   # Collect all APIs silently
   sde::api::r_collect_apis 'NO'
   local count=$?
   local apis="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      log_info "No API documentation found (dependencies not yet crafted?)"
      return 1
   fi
   
   # Find and show the requested API
   local found='NO'
   local index=0
   local api
   
   # Check if identifier is a number
   case "${identifier}" in
      [0-9]*)
         # It's a number - find by index
         .foreachpath api in ${apis}
         .do
            index=$((index + 1))
            if [ ${index} -eq ${identifier} ]
            then
               rexekutor cat "${api}"
               found='YES'
               .break
            fi
         .done
      ;;
      
      *)
         # It's a name - search by dependency name
         .foreachpath api in ${apis}
         .do
            # Extract dependency name from path
            # api is like: /path/to/dependency/Release/share/mulle-core/dox/TOC.md
            local dir
            dir="$(dirname "${api}")"  # .../mulle-core/dox or .../mulle-core
            dir="$(dirname "${dir}")"  # .../mulle-core
            r_basename "${dir}"
            local name="${RVAL}"
            
            if [ "${name}" = "${identifier}" ]
            then
               rexekutor cat "${api}"
               found='YES'
               .break
            fi
         .done
      ;;
   esac
   
   if [ "${found}" = 'NO' ]
   then
      case "${identifier}" in
         [0-9]*)
            fail "No API doc with number ${identifier} found (total: ${count})"
         ;;
         *)
            fail "No API doc for dependency '${identifier}' found"
         ;;
      esac
   fi
}


sde::api::r_find_symbol()
{
   log_entry "sde::api::r_find_symbol" "$@"

   local dir="$1"
   local name="$2"
   local follow="$3"
   
   local found
   
   found="$(rexekutor find ${follow} "${dir}" -name "*.h" -exec grep -l "${name}" {} \; 2> /dev/null)"
   
   RVAL="${found}"
}


sde::api::find()
{
   log_entry "sde::api::find" "$@"

   [ $# -eq 0 ] && sde::api::usage "Missing type argument"

   local type=$1
   shift

   [ $# -eq 0 ] && sde::api::usage "Missing name argument"

   local name=$1
   shift

   [ $# -ne 0 ] && sde::api::usage "Superflous arguments $*"

   local dependency_dir
   
   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true

   if [ -z "${dependency_dir}" ] || [ ! -d "${dependency_dir}" ]
   then
      fail "Need to craft dependencies first"
   fi

   (
      eval `mulle-platform env`

      local follow
      local paths
      local pattern

      case "${type}" in
         'h'|'header'|'s'|'symbol')
            prefixes=
            suffixes=".h"
            paths="${dependency_dir}/Debug/include:${dependency_dir}/Release/include:${dependency_dir}/include"
         ;;

         'l'|'library')
            paths="${dependency_dir}/Debug/lib:${dependency_dir}/Release/lib:${dependency_dir}/lib"
            # We'll search for library files with proper prefix and suffix
         ;;

         *)
            sde::api::usage "Unknown type \"${type}\""
         ;;
      esac

      local dir
      local abs_dir
      local found

      .foreachpath dir in ${paths}
      .do
         r_absolutepath "${dir}"
         abs_dir="${RVAL}"

         if [ ! -d "${abs_dir}" ]
         then
            .continue
         fi

         case "${type}" in
            's'|'symbol')
               sde::api::r_find_symbol "${abs_dir}" "${name}" ${follow}
               found="${RVAL}"
            ;;

            'l'|'library')
               # Search for library files with proper naming
               # User can pass "mulle-core" or "libmulle-core.a"
               # Try to match with platform-specific prefix and suffixes
               
               # First try exact match (files only)
               found="$(rexekutor find ${follow} "${abs_dir}" -type f -name "${name}" -print 2> /dev/null | head -1)"
               
               if [ -z "${found}" ]
               then
                  # Try with prefix and static suffix
                  found="$(rexekutor find ${follow} "${abs_dir}" -type f -name "${MULLE_PLATFORM_LIBRARY_PREFIX}${name}${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}" -print 2> /dev/null | head -1)"
               fi
               
               if [ -z "${found}" ]
               then
                  # Try with prefix and dynamic suffix
                  found="$(rexekutor find ${follow} "${abs_dir}" -type f -name "${MULLE_PLATFORM_LIBRARY_PREFIX}${name}${MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC}*" -print 2> /dev/null | head -1)"
               fi
               
               if [ -z "${found}" ]
               then
                  # Try wildcard match
                  found="$(rexekutor find ${follow} "${abs_dir}" -type f -name "*${name}*${MULLE_PLATFORM_LIBRARY_SUFFIX_STATIC}" -print 2> /dev/null | head -1)"
               fi
               
               if [ -z "${found}" ]
               then
                  # Try wildcard match with dynamic
                  found="$(rexekutor find ${follow} "${abs_dir}" -type f -name "*${name}*${MULLE_PLATFORM_LIBRARY_SUFFIX_DYNAMIC}*" -print 2> /dev/null | head -1)"
               fi
            ;;

            *)
               found="$(rexekutor find ${follow} "${abs_dir}" -name "${name}" -print 2> /dev/null)"
            ;;
         esac

         if [ ! -z "${found}" ]
         then
            printf "%s\n" "${found}"
            return
         fi
      .done

      log_warning "Nothing found"
   )
}


sde::api::main()
{
   log_entry "sde::api::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::api::usage
         ;;

         -*)
            sde::api::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"
   if [ $# -ne 0 ]
   then
      cmd="$1"
      shift
   fi

   case "${cmd}" in
      'help')
         sde::api::usage
      ;;

      'list')
         sde::api::list "$@"
      ;;

      'show')
         sde::api::show "$@"
      ;;
      
      'find')
         sde::api::find "$@"
      ;;
      
      *)
         sde::api::usage "Unknown command '${cmd}'"
      ;;
   esac
}
