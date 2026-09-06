# shellcheck shell=bash
#
#   Copyright (c) 2025 Nat! - Mulle kybernetiK
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
MULLE_SDE_HOWTO_SH='included'


sde::howto::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto [cmd]

   Show HOWTOs for developent topics. AI friendly! HOWTOs for dependencies
   appear only after a successful \`mulle-sde craft\`.

   See also: mulle-sde api for API docs

Examples:
      mulle-sde howto list              # List howtos in current directory
      cd test && mulle-sde howto list   # List test-specific howtos
      mulle-sde howto testing           # Load the full testing guidance bundle
      mulle-sde howto test              # Alias for the testing bundle
      mulle-sde howto show leaks
      mulle-sde howto show 2
      mulle-sde howto show --keyword leak --keyword sanitizer
      mulle-sde howto roles
      mulle-sde howto topics --role coder
      mulle-sde howto files --role coder --topic mulle-event
      mulle-sde howto show --role coder --topic mulle-event
      mulle-sde howto load --role coder --topic mulle-event
      mulle-sde howto keywords
      mulle-sde howto grep sanitizer
      mulle-sde howto apropos "how do I debug memory leaks?"

Commands:
      list       : list available howto topics (default)
      show       : show howto file by number, name, or explicit role/topic selection
      roles      : list discovered role buckets
      topics     : list discovered topics for a role
      files      : list files in a role/topic bundle
      load       : load a role/topic bundle in stable order
      keywords   : list all keywords from all howto files
      grep       : search for pattern in howto files with local context
      apropos    : fuzzy topic search through howto content

   Use 'mulle-sde howto <cmd> --help' for command-specific help.

EOF
   exit 1
}


sde::howto::list_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto list [options] [keyword]

   List available howto topics, optionally filtered by keyword.
   By default, shows keywords for each topic.

Options:
      --all          : show all dependencies (default in vibecoding mode)
      --flat         : show only top-level dependencies (default otherwise)
      --no-keywords  : hide keywords column

Examples:
      mulle-sde howto list
      mulle-sde howto list --all
      mulle-sde howto list --flat
      mulle-sde howto list --no-keywords
      mulle-sde howto list leak

EOF
   exit 1
}


sde::howto::show_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto show [options] <number|name>
   ${MULLE_USAGE_NAME} howto show --role <role> [--topic <topic>] [--file <member>]

   Show howto content by number, exact name, fuzzy name, explicit role/topic selector,
   or keyword fallback when no exact name matches. When --role is given without --topic,
   all topics for that role are shown. Unqualified bundle lookups prefer
   the \`coder\` role when available.

Options:
      --keyword <word>  : treat as keyword search, show all matching howtos
                          (can be specified multiple times, all must match)
     --role <role>     : explicit role selector for bundle topics
     --topic <topic>   : explicit topic selector
     --file <member>   : explicit bundle member selector (default: index)
     --member <member> : alias for --file

Examples:
      mulle-sde howto show testing              # Load the full testing bundle
      mulle-sde howto show test                 # Alias for the testing bundle
      mulle-sde howto show 2                    # Show by number
      mulle-sde howto show leaks                # Exact or fuzzy match on filename
      mulle-sde howto show leak-checking        # Partial match works too
      mulle-sde howto show --keyword leak --keyword sanitizer
      mulle-sde howto show --topic testing
      mulle-sde howto show --role verifier        # Show all topics for a role
      mulle-sde howto show --role coder --topic mulle-event
      mulle-sde howto show --role coder --topic mulle-event --file quirks

   Legacy positional forms remain accepted for compatibility:
      mulle-sde howto show coder mulle-event
      mulle-sde howto show coder mulle-event quirks

EOF
   exit 1
}


sde::howto::keywords_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto keywords

   List all unique keywords from all howto files.

EOF
   exit 1
}


sde::howto::grep_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto grep <pattern>

   Search for pattern (case insensitive) in all howto files.
   Shows local context around matches, grouped by howto file.

Examples:
      mulle-sde howto grep sanitizer
      mulle-sde howto grep "memory leak"

EOF
   exit 1
}


sde::howto::apropos_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto apropos <question>

   Fuzzy howto-topic search. Unlike \`howto grep\`, this lists matching topics
   and bundles instead of dumping raw matching lines.

   Queries are split into meaningful keywords and matched against howto names,
   titles, keywords, and bundle members. Exact shortcuts like \`test\` resolve
   the same way as \`howto list\` / \`howto show\` before fuzzy matching.

   Alias: search

Examples:
   mulle-sde howto apropos "how do I debug memory leaks?"
   mulle-sde howto apropos "tracking"
   mulle-sde howto search "render queue"

EOF
   exit 1
}


sde::howto::roles_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto roles

   List discovered role buckets from bundled howtos.

Example:
   mulle-sde howto roles

EOF
   exit 1
}


sde::howto::topics_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto topics [--role <role>|<role>]

   List discovered topics. Without a role, topics are grouped by role.

Examples:
   mulle-sde howto topics
   mulle-sde howto topics --role coder
   mulle-sde howto topics --role debugger

   Legacy positional form remains accepted:
   mulle-sde howto topics coder

EOF
   exit 1
}


sde::howto::files_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto files --role <role> --topic <topic>

   List bundle members for a role/topic howto bundle.

Examples:
   mulle-sde howto files --role coder --topic mulle-event
   mulle-sde howto files --role debugger --topic gdb-stacktrace

   Legacy positional form remains accepted:
   mulle-sde howto files coder mulle-event

EOF
   exit 1
}


sde::howto::load_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} howto load --role <role> --topic <topic>

   Emit a role/topic howto bundle in stable order:
   index, quirks, patterns, then remaining files lexically.

Examples:
   mulle-sde howto load --role coder --topic mulle-event
   mulle-sde howto load --role debugger --topic gdb-stacktrace

   Legacy positional form remains accepted:
   mulle-sde howto load coder mulle-event

EOF
   exit 1
}


#
# Helper function to ensure dependencies are crafted if in vibecoding mode
# Returns 0 if dependencies are available or were successfully crafted
# Returns 1 if dependencies could not be built
#
sde::howto::ensure_dependencies_crafted()
{
   log_entry "sde::howto::ensure_dependencies_crafted" "$@"

   local purpose="${1:-howto information}"

   include "sde::vibecoding"

   # For test directories, use test craft instead
   if sde::is_test_directory "$PWD"
   then
      local state

      state="$(rexekutor mulle-craft ${MULLE_TECHNICAL_FLAGS:--s} quickstatus -p 2>/dev/null)" || state=""
      [ "${state}" = "complete" ] && return 0

      log_verbose "Crafting test dependencies to get ${purpose}..."
      rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS:--s} -DMULLE_VIBECODING=NO test craft
      return $?
   fi

   sde::vibecoding::ensure_dependencies_crafted "${purpose}"
}

#
# Howtos are installed by extensions into share/sde/howto/
# local howtos are created in asset/howto/
# howtos are also available via dependencies as ${DEPENDENCY_DIR}/.../share/${name}/howto
# similiar to how dependency toc works
#
# So we gather these in a predictable way and give them numbers
#
#
# Extract keywords from a howto file's HTML comment
# Returns keywords in RVAL as comma-separated string
#
sde::howto::r_extract_keywords()
{
   local file="$1"
   
   RVAL=""
   
   # Look for keywords comment line: <!-- keywords: word1, word2, word3 -->
   local keywords_line
   keywords_line="$(grep -i '^<!--[[:space:]]*[Kk]eywords:' "${file}" 2>/dev/null | head -n 1)"
   
   if [ ! -z "${keywords_line}" ]
   then
      # Extract keywords between "keywords:" and "-->"
      keywords_line="${keywords_line#*eywords:}"
      keywords_line="${keywords_line%-->*}"
      
      # Trim whitespace
      RVAL="$(echo "${keywords_line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    fi
}


#
# Collect howto roots for both legacy flat files and role/topic bundles.
# Returns colon-separated directories in precedence order.
#
sde::howto::r_collect_howto_roots()
{
   log_entry "sde::howto::r_collect_howto_roots" "$@"

   local roots=""
   local use_etc='NO'
   local global_use_etc='NO'
   local dependency_dir
   local search_dir
   local repo
   local platforms
   local searchpath=':Release:Debug:RelDebug'

   if [ -d "${HOME}/.mulle/etc/howto" ]
   then
      global_use_etc='YES'
      r_colon_concat "${roots}" "${HOME}/.mulle/etc/howto"
      roots="${RVAL}"
   fi

   if [ "${global_use_etc}" = 'NO' ] && [ -d "${HOME}/.mulle/share/sde/howto" ]
   then
      r_colon_concat "${roots}" "${HOME}/.mulle/share/sde/howto"
      roots="${RVAL}"
   fi

   if [ -d ".mulle/etc/howto" ]
   then
      use_etc='YES'
      r_colon_concat "${roots}" ".mulle/etc/howto"
      roots="${RVAL}"
   fi

   if [ "${use_etc}" = 'NO' ] && [ -d ".mulle/share/sde/howto" ]
   then
      r_colon_concat "${roots}" ".mulle/share/sde/howto"
      roots="${RVAL}"
   fi

   if [ -d "asset/howto" ]
   then
      r_colon_concat "${roots}" "asset/howto"
      roots="${RVAL}"
   fi

   local subdirs="demo:test"
   local subdir
   if [ ! -z "${MULLE_SDE_TEST_PATH}" ]
   then
      r_colon_concat "${subdirs}" "${MULLE_SDE_TEST_PATH}"
      subdirs="${RVAL}"
   fi

   .foreachpath subdir in ${subdirs}
   .do
      if [ -d "${subdir}/.mulle/etc/howto" ]
      then
         r_colon_concat "${roots}" "${subdir}/.mulle/etc/howto"
         roots="${RVAL}"
      fi

      if [ -d "${subdir}/.mulle/share/sde/howto" ]
      then
         r_colon_concat "${roots}" "${subdir}/.mulle/share/sde/howto"
         roots="${RVAL}"
      fi

      if [ -d "${subdir}/asset/howto" ]
      then
         r_colon_concat "${roots}" "${subdir}/asset/howto"
         roots="${RVAL}"
      fi
   .done

   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true

   if [ ! -z "${dependency_dir}" ] && [ -d "${dependency_dir}" ]
   then
      local platform_dirs=":"
      local platform
      local platform_dir

      platforms="$(rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS 2>/dev/null)" || true

      if [ ! -z "${platforms}" ]
      then
         for platform in ${platforms}
         do
            if [ -d "${dependency_dir}/${platform}" ]
            then
               r_colon_concat "${platform_dirs}" "${platform}"
               platform_dirs="${RVAL}"
            fi
         done
      fi

      .foreachpath platform_dir in ${platform_dirs}
      .do
         .foreachpath subdir in ${searchpath}
         .do
            if [ -z "${platform_dir}" ]
            then
               search_dir="${dependency_dir}/${subdir}/share"
            else
               search_dir="${dependency_dir}/${platform_dir}/${subdir}/share"
            fi

            if [ -d "${search_dir}" ]
            then
               shell_enable_nullglob
               for repo in "${search_dir}"/*
               do
                  [ -e "${repo}" ] || continue
                  if [ -d "${repo}/howto" ]
                  then
                     r_colon_concat "${roots}" "${repo}/howto"
                     roots="${RVAL}"
                  fi
               done
               shell_disable_nullglob
               .break
            fi
         .done
      .done
   fi

   RVAL="${roots}"
}


#
# Collect bundle entries as newline-separated records:
#   role;topic;member;filepath
#
sde::howto::r_collect_bundle_entries()
{
   log_entry "sde::howto::r_collect_bundle_entries" "$@"

   local roots
   local root
   local entries=""
   local files
   local howto
   local relpath
   local role
   local rest
   local topic
   local member

   sde::howto::r_collect_howto_roots
   roots="${RVAL}"

   .foreachpath root in ${roots}
   .do
      [ -d "${root}" ] || continue

      files="$(find "${root}" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)"
      [ -z "${files}" ] && continue

      while IFS= read -r howto
      do
         [ -z "${howto}" ] && continue

         relpath="${howto#${root}/}"
         case "${relpath}" in
            */*)
               role="${relpath%%/*}"
               rest="${relpath#*/}"
            ;;
            *)
               continue
            ;;
         esac

         case "${rest}" in
            */*)
               topic="${rest%%/*}"
               member="${rest#${topic}/}"
               member="${member%.md}"
            ;;
            *.md)
               topic="${rest%.md}"
               member="index"
            ;;
            *)
               continue
            ;;
         esac

         r_add_line "${entries}" "${role};${topic};${member};${howto}"
         entries="${RVAL}"
      done <<EOF
${files}
EOF
   .done

   RVAL="${entries}"
}


#
# Collect resolved bundle members for a role/topic in precedence order.
# Returns newline-separated records:
#   member;filepath
#
sde::howto::r_collect_bundle_member_map()
{
   log_entry "sde::howto::r_collect_bundle_member_map" "$@"

   local role="$1"
   local topic="$2"
   local entries
   local map=""
   local line
   local line_role
   local line_topic
   local member
   local filepath

   [ -z "${role}" ] && fail "Missing role"
   [ -z "${topic}" ] && fail "Missing topic"

   sde::howto::r_collect_bundle_entries
   entries="${RVAL}"

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue

      line_role="${line%%;*}"
      line="${line#*;}"
      line_topic="${line%%;*}"
      line="${line#*;}"
      member="${line%%;*}"
      filepath="${line#*;}"

      [ "${line_role}" = "${role}" ] || continue
      [ "${line_topic}" = "${topic}" ] || continue

      if ! grep -q "^${member};" <<< "${map}"
      then
         r_add_line "${map}" "${member};${filepath}"
         map="${RVAL}"
      fi
   done <<EOF
${entries}
EOF

   RVAL="${map}"
}


#
# Resolve a specific bundle member. If member is empty, defaults to "index".
# Returns the filepath in RVAL.
#
sde::howto::r_resolve_bundle_member()
{
   log_entry "sde::howto::r_resolve_bundle_member" "$@"

   local role="$1"
   local topic="$2"
   local member="${3:-index}"
   local map
   local line
   local line_member
   local filepath

   sde::howto::r_collect_bundle_member_map "${role}" "${topic}"
   map="${RVAL}"

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      line_member="${line%%;*}"
      filepath="${line#*;}"
      if [ "${line_member}" = "${member}" ]
      then
         RVAL="${filepath}"
         return 0
      fi
   done <<EOF
${map}
EOF

   RVAL=""
   return 1
}


sde::howto::r_resolve_bundle_shortcut()
{
   local identifier="$1"

   case "${identifier}" in
      test|testing)
         RVAL="verifier;testing"
         return 0
      ;;
   esac

   RVAL=""
   return 1
}


sde::howto::emit_howto_file()
{
   local filepath="$1"

   log_verbose "Showing howto from ${filepath}"
   rexekutor grep -v '^<!--' "${filepath}"
}


#
# Print bundle members in stable order:
#   index, quirks, patterns, then lexical remainder
#
sde::howto::_emit_bundle_map()
{
   local map="$1"
   local line
   local member
   local filepath
   local remainder=""

   for member in index quirks patterns
   do
      while IFS= read -r line
      do
         [ -z "${line}" ] && continue
         if [ "${line%%;*}" = "${member}" ]
         then
            filepath="${line#*;}"
            sde::howto::emit_howto_file "${filepath}"
            echo ""
         fi
      done <<EOF
${map}
EOF
   done

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      member="${line%%;*}"
      case "${member}" in
         index|quirks|patterns)
         ;;
         *)
            r_add_line "${remainder}" "${line}"
            remainder="${RVAL}"
         ;;
      esac
   done <<EOF
${map}
EOF

   if [ ! -z "${remainder}" ]
   then
      remainder="$(printf "%s\n" "${remainder}" | LC_ALL=C sort)"
      while IFS= read -r line
      do
         [ -z "${line}" ] && continue
         filepath="${line#*;}"
         sde::howto::emit_howto_file "${filepath}"
         echo ""
      done <<EOF
${remainder}
EOF
   fi
}


sde::howto::roles()
{
   log_entry "sde::howto::roles" "$@"

   if sde::is_test_directory "${PWD}"
   then
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"

      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde howto roles $*"
      return $?
   fi

   [ $# -ne 0 ] && sde::howto::roles_usage "Unexpected argument $1"

   local entries
   local roles=""
   local line
   local role

   sde::howto::r_collect_bundle_entries
   entries="${RVAL}"

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      role="${line%%;*}"
      if ! find_line "${roles}" "${role}"
      then
         r_add_line "${roles}" "${role}"
         roles="${RVAL}"
      fi
   done <<EOF
${entries}
EOF

   [ -z "${roles}" ] && return 0
   printf "%s\n" "${roles}" | LC_ALL=C sort
}


sde::howto::topics()
{
   log_entry "sde::howto::topics" "$@"

   if sde::is_test_directory "${PWD}"
   then
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"

      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde howto topics $*"
      return $?
   fi

   local role
   local OPTION_ROLE

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::topics_usage
         ;;

         --role)
            shift
            [ $# -eq 0 ] && sde::howto::topics_usage "Missing value for --role"
            OPTION_ROLE="$1"
         ;;

         -*)
            sde::howto::topics_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   local entries
   local line

   sde::howto::r_collect_bundle_entries
   entries="${RVAL}"

   if [ ! -z "${OPTION_ROLE}" ]
   then
      [ $# -ne 0 ] && sde::howto::topics_usage "Unexpected argument $1"
      role="${OPTION_ROLE}"
   else
      role="$1"
      [ $# -gt 1 ] && sde::howto::topics_usage "Too many arguments"
   fi

   sde::howto::r_collect_topics_for_role "${entries}" "${role}"
   local topics="${RVAL}"

   if [ ! -z "${role}" ]
   then
      [ -z "${topics}" ] && return 0
      printf "%s\n" "${topics}" | LC_ALL=C sort
      return 0
   fi

   local roles=""
   local line_role
   local current_topics
   local first_group='YES'

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      line_role="${line%%;*}"
      if ! find_line "${roles}" "${line_role}"
      then
         r_add_line "${roles}" "${line_role}"
         roles="${RVAL}"
      fi
   done <<EOF
${entries}
EOF

   [ -z "${roles}" ] && return 0

   roles="$(printf "%s\n" "${roles}" | LC_ALL=C sort)"
   while IFS= read -r line_role
   do
      [ -z "${line_role}" ] && continue
      if [ "${first_group}" = 'NO' ]
      then
         printf "\n"
      fi
      log_info "${line_role}"
      first_group='NO'
      sde::howto::r_collect_topics_for_role "${entries}" "${line_role}"
      current_topics="${RVAL}"
      if [ ! -z "${current_topics}" ]
      then
         while IFS= read -r line
         do
            [ -z "${line}" ] && continue
            printf "   %s\n" "${line}"
         done <<EOF
$(printf "%s\n" "${current_topics}" | LC_ALL=C sort)
EOF
      fi
   done <<EOF
${roles}
EOF
}


sde::howto::r_collect_topics_for_role()
{
   local entries="$1"
   local role="$2"
   local topics=""
   local line
   local line_role
   local topic

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      line_role="${line%%;*}"
      [ -z "${role}" -o "${line_role}" = "${role}" ] || continue
      line="${line#*;}"
      topic="${line%%;*}"
      if ! find_line "${topics}" "${topic}"
      then
         r_add_line "${topics}" "${topic}"
         topics="${RVAL}"
      fi
   done <<EOF
${entries}
EOF

   RVAL="${topics}"
}


sde::howto::files()
{
   log_entry "sde::howto::files" "$@"

   if sde::is_test_directory "${PWD}"
   then
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"

      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde howto files $*"
      return $?
   fi

   local role
   local topic
   local map
   local line
   local member
   local remainder=""
   local OPTION_ROLE
   local OPTION_TOPIC

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::files_usage
         ;;

         --role)
            shift
            [ $# -eq 0 ] && sde::howto::files_usage "Missing value for --role"
            OPTION_ROLE="$1"
         ;;

         --topic)
            shift
            [ $# -eq 0 ] && sde::howto::files_usage "Missing value for --topic"
            OPTION_TOPIC="$1"
         ;;

         -*)
            sde::howto::files_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   if [ ! -z "${OPTION_ROLE}${OPTION_TOPIC}" ]
   then
      [ $# -ne 0 ] && sde::howto::files_usage "Unexpected argument $1"
      role="${OPTION_ROLE}"
      topic="${OPTION_TOPIC}"
   else
      role="$1"
      topic="$2"
      [ $# -gt 2 ] && sde::howto::files_usage "Too many arguments"
   fi

   [ -z "${role}" ] && sde::howto::files_usage "Missing role"
   [ -z "${topic}" ] && sde::howto::files_usage "Missing topic"

   sde::howto::r_collect_bundle_member_map "${role}" "${topic}"
   map="${RVAL}"

   [ -z "${map}" ] && fail "No howto bundle '${role}/${topic}' found"

   for member in index quirks patterns
   do
      while IFS= read -r line
      do
         [ -z "${line}" ] && continue
         if [ "${line%%;*}" = "${member}" ]
         then
            printf "%s\n" "${member}"
         fi
      done <<EOF
${map}
EOF
   done

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      member="${line%%;*}"
      case "${member}" in
         index|quirks|patterns)
         ;;
         *)
            r_add_line "${remainder}" "${member}"
            remainder="${RVAL}"
         ;;
      esac
   done <<EOF
${map}
EOF

   if [ ! -z "${remainder}" ]
   then
      printf "%s\n" "${remainder}" | LC_ALL=C sort
   fi
}


sde::howto::load()
{
   log_entry "sde::howto::load" "$@"

   if sde::is_test_directory "${PWD}"
   then
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"

      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde howto load $*"
      return $?
   fi

   local role
   local topic
   local map
   local OPTION_ROLE
   local OPTION_TOPIC

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::load_usage
         ;;

         --role)
            shift
            [ $# -eq 0 ] && sde::howto::load_usage "Missing value for --role"
            OPTION_ROLE="$1"
         ;;

         --topic)
            shift
            [ $# -eq 0 ] && sde::howto::load_usage "Missing value for --topic"
            OPTION_TOPIC="$1"
         ;;

         -*)
            sde::howto::load_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac
      shift
   done

   if [ ! -z "${OPTION_ROLE}${OPTION_TOPIC}" ]
   then
      [ $# -ne 0 ] && sde::howto::load_usage "Unexpected argument $1"
      role="${OPTION_ROLE}"
      topic="${OPTION_TOPIC}"
   else
      role="$1"
      topic="$2"
      [ $# -gt 2 ] && sde::howto::load_usage "Too many arguments"
   fi

   [ -z "${role}" ] && sde::howto::load_usage "Missing role"
   [ -z "${topic}" ] && sde::howto::load_usage "Missing topic"

   sde::howto::r_collect_bundle_member_map "${role}" "${topic}"
   map="${RVAL}"

   [ -z "${map}" ] && fail "No howto bundle '${role}/${topic}' found"

   sde::howto::_emit_bundle_map "${map}"
}


#
# Helper function to check if file matches keyword
# Checks filename, title (first line), and keywords comment (second line)
#
sde::howto::r_matches_keyword()
{
   local file="$1"
   local keyword="$2"
   local display_name

   if [ -z "${keyword}" ]
   then
      return 0  # No keyword means match all
   fi

   # Check display name
   sde::howto::r_howto_display_name "${file}"
   display_name="${RVAL}"
   if rexekutor grep -q -i "${keyword}" <<< "${display_name}"
   then
      return 0
   fi

   # Check first two lines (title and keywords comment)
   local first_two_lines
   first_two_lines="$(head -n 2 "${file}" 2>/dev/null)"

   if rexekutor grep -q -i "${keyword}" <<< "${first_two_lines}"
   then
      return 0
   fi

   return 1
}


sde::howto::r_matches_apropos_word()
{
   local file="$1"
   local word="$2"

   if sde::howto::r_matches_keyword "${file}" "${word}"
   then
     return 0
   fi

   if rexekutor grep -q -i "${word}" "${file}" 2>/dev/null
   then
     return 0
   fi

   return 1
}


sde::howto::r_count_matching_howtos()
{
   local howtos="$1"
   local keyword="$2"
   local howto
   local count=0

   .foreachpath howto in ${howtos}
   .do
     if sde::howto::r_matches_keyword "${howto}" "${keyword}"
     then
        count=$((count + 1))
     fi
   .done

   RVAL="${count}"
}


sde::howto::r_resolve_display_howtos_for_query()
{
   local howtos="$1"
   local identifier="$2"
   local howto
   local name
   local shortcut_role
   local shortcut_topic
   local exact_matches=""

   if [ -z "${identifier}" ]
   then
      RVAL=""
      return 1
   fi

   if sde::howto::r_resolve_bundle_member 'coder' "${identifier}" 'index'
   then
      return 0
   fi

   if sde::howto::r_resolve_bundle_shortcut "${identifier}"
   then
      shortcut_role="${RVAL%%;*}"
      shortcut_topic="${RVAL#*;}"
      if sde::howto::r_resolve_bundle_member "${shortcut_role}" "${shortcut_topic}" 'index'
      then
         return 0
      fi
   fi

   .foreachpath howto in ${howtos}
   .do
      sde::howto::r_howto_display_name "${howto}"
      name="${RVAL}"
      if [ "${name}" = "${identifier}" ]
      then
         r_colon_concat "${exact_matches}" "${howto}"
         exact_matches="${RVAL}"
      fi
   .done

   if [ ! -z "${exact_matches}" ]
   then
      RVAL="${exact_matches}"
      return 0
   fi

   RVAL=""
   return 1
}


sde::howto::show_keyword_matches()
{
   local howtos="$1"
   local keywords="$2"
   local preferred_role="${3:-}"
   local found='NO'
   local howto
   local keyword
   local all_match
   local first_two_lines
   local matches=""
   local preferred_matches=""

   .foreachpath howto in ${howtos}
   .do
      all_match='YES'

      .foreachitem keyword in ${keywords}
      .do
         sde::howto::r_howto_display_name "${howto}"
         if ! grep -q -i "${keyword}" <<< "${RVAL}"
         then
            first_two_lines="$(head -n 2 "${howto}" 2>/dev/null)"

            if ! grep -q -i "${keyword}" <<< "${first_two_lines}"
            then
               all_match='NO'
               .break
            fi
         fi
      .done

      if [ "${all_match}" = 'YES' ]
      then
         r_colon_concat "${matches}" "${howto}"
         matches="${RVAL}"
         found='YES'

         if [ ! -z "${preferred_role}" ]
         then
            sde::howto::r_howto_role_from_path "${howto}"
            if [ "${RVAL}" = "${preferred_role}" ]
            then
               r_colon_concat "${preferred_matches}" "${howto}"
               preferred_matches="${RVAL}"
            fi
         fi
      fi
   .done

   if [ "${found}" = 'NO' ]
   then
      fail "No howto matching all keywords ${keywords:-\(\)} found"
   fi

   if [ ! -z "${preferred_matches}" ]
   then
      matches="${preferred_matches}"
   fi

   .foreachpath howto in ${matches}
   .do
      sde::howto::emit_howto_file "${howto}"
      echo ""
   .done
}


sde::howto::r_howto_role_from_path()
{
   local filepath="$1"
   local relpath

   relpath="${filepath##*howto/}"

   case "${relpath}" in
      */*)
         RVAL="${relpath%%/*}"
         return 0
      ;;
   esac

   RVAL=""
   return 1
}


sde::howto::r_dependency_reponame_from_howto_path()
{
   local filepath="$1"
   local repo_path

   case "${filepath}" in
      /*/share/*/howto/*)
         repo_path="${filepath%/howto/*}"
         r_basename "${repo_path}"
         return 0
      ;;
   esac

   RVAL=""
   return 1
}


sde::howto::r_howto_source_key()
{
   local filepath="$1"
   local subdir_path

   case "${filepath}" in
      "${HOME}/.mulle/etc/howto/"*|"${HOME}/.mulle/share/sde/howto/"*)
         RVAL="user"
      ;;
      .mulle/etc/howto/*|.mulle/share/sde/howto/*|asset/howto/*)
         RVAL="project"
      ;;
      /*)
         if sde::howto::r_dependency_reponame_from_howto_path "${filepath}"
         then
            RVAL="dependency:${RVAL}"
         else
            RVAL="absolute"
         fi
      ;;
      */.mulle/*/howto/*)
         subdir_path="${filepath%%/.mulle/*}"
         r_basename "${subdir_path}"
         RVAL="subdir:${RVAL}"
      ;;
      *)
         RVAL="project"
      ;;
   esac
}


sde::howto::r_howto_display_name()
{
   local filepath="$1"
   local relpath
   local name
   local role
   local topic
   local member
   local subdir_path

   relpath="${filepath##*howto/}"

   case "${relpath}" in
      */*/*.md)
         role="${relpath%%/*}"
         relpath="${relpath#*/}"
         topic="${relpath%%/*}"
         member="${relpath#${topic}/}"
         member="${member%.md}"
         if [ "${member}" = 'index' ]
         then
            name="${topic}/${role}"
         else
            name="${topic}/${role}/${member}"
         fi
      ;;

      */*.md)
         role="${relpath%%/*}"
         name="${relpath#*/}"
         name="${name%.md}"
         name="${name}/${role}"
      ;;

      *.md)
         r_basename "${filepath}"
         r_extensionless_basename "${RVAL}"
         name="${RVAL}"
      ;;

      *)
         name="${relpath}"
      ;;
   esac

   case "${filepath}" in
      /*)
      ;;
      */.mulle/*/howto/*)
         subdir_path="${filepath%%/.mulle/*}"
         r_basename "${subdir_path}"
         name="${RVAL}/${name}"
      ;;
   esac

   RVAL="${name}"
}


sde::howto::r_howto_topic_display_name()
{
   local filepath="$1"
   local relpath
   local name
   local role
   local topic
   local subdir_path

   relpath="${filepath##*howto/}"

   case "${relpath}" in
      */*/*.md)
         role="${relpath%%/*}"
         relpath="${relpath#*/}"
         topic="${relpath%%/*}"
         name="${topic}/${role}"
      ;;

      */*.md)
         role="${relpath%%/*}"
         name="${relpath#*/}"
         name="${name%.md}"
         name="${name}/${role}"
      ;;

      *.md)
         r_basename "${filepath}"
         r_extensionless_basename "${RVAL}"
         name="${RVAL}"
      ;;

      *)
         name="${relpath}"
      ;;
   esac

   case "${filepath}" in
      /*)
      ;;
      */.mulle/*/howto/*)
         subdir_path="${filepath%%/.mulle/*}"
         r_basename "${subdir_path}"
         name="${RVAL}/${name}"
      ;;
   esac

   RVAL="${name}"
}


sde::howto::r_howto_display_label()
{
   local howto="$1"

   case "${howto}" in
      "${HOME}/.mulle/etc/howto/"*|"${HOME}/.mulle/share/sde/howto/"*)
         RVAL="(user)"
      ;;
      .mulle/etc/howto/*)
         RVAL="(local)"
      ;;
      .mulle/share/sde/howto/*)
         RVAL=""
      ;;
      asset/howto/*)
         RVAL="(local)"
      ;;
      /*)
         if sde::howto::r_dependency_reponame_from_howto_path "${howto}"
         then
            RVAL="(${RVAL})"
         else
            RVAL=""
         fi
      ;;
      *)
         RVAL=""
      ;;
   esac
}


#
# Display a sorted colon-separated list of howto paths with numbering.
# count numbers reflect position in the full sorted list; only items matching
# keyword are printed (so numbers may not be contiguous when filtering).
#
sde::howto::_display_sorted_list()
{
   local howtos="$1"
   local keyword="$2"
   local show_keywords="$3"

   local count=0
   local howto
   local name
   local display_name
   local label
   local keywords_str
   local subdir_path

   .foreachpath howto in ${howtos}
   .do
      count=$((count + 1))

      if sde::howto::r_matches_keyword "${howto}" "${keyword}"
      then
         sde::howto::r_howto_display_name "${howto}"
         name="${RVAL}"
         display_name="${name}"
         sde::howto::r_howto_display_label "${howto}"
         label="${RVAL}"

         if [ "${show_keywords}" = 'YES' ]
         then
            sde::howto::r_extract_keywords "${howto}"
            keywords_str="${RVAL}"
            if [ ! -z "${keywords_str}" ]
            then
               if [ ! -z "${label}" ]
               then
                  printf "%2d. %-30s [%s] %s\n" "${count}" "${display_name}" "${keywords_str}" "${label}"
               else
                  printf "%2d. %-30s [%s]\n" "${count}" "${display_name}" "${keywords_str}"
               fi
            else
               if [ ! -z "${label}" ]
               then
                  printf "%2d. %-30s %s\n" "${count}" "${display_name}" "${label}"
               else
                  printf "%2d. %s\n" "${count}" "${display_name}"
               fi
            fi
         else
            if [ ! -z "${label}" ]
            then
               printf "%2d. %-30s %s\n" "${count}" "${display_name}" "${label}"
            else
               printf "%2d. %s\n" "${count}" "${display_name}"
            fi
         fi
      fi
   .done
}


#
# Collect all howtos in predictable order
# Parameters:
#   $1 - optional keyword filter
#   $2 - 'YES' to display, 'NO' to just collect
# Returns howtos in RVAL
#
sde::howto::r_collect_howtos()
{
   log_entry "sde::howto::r_collect_howtos" "$@"

   local keyword="$1"
   local display="${2:-NO}"
   local show_keywords="${3:-NO}"
   local filter_toplevel="${4:-NO}"
   
   # If in test directory, inherit from parent project (subshell is OK here, no crafting)
   if sde::is_test_directory "${PWD}"
   then
      log_debug "In test directory, moving to parent for howtos"
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      
      (cd "${parent_dir}" 2>/dev/null && sde::howto::r_collect_howtos "$@")
      return $?
   fi
   
   log_debug "keyword: '${keyword}'"
   log_debug "display: '${display}'"
   log_debug "show_keywords: '${show_keywords}'"
   log_debug "filter_toplevel: '${filter_toplevel}'"
   
   local howtos
   local howto
   local count=0
   local name
   local use_etc='NO'
   local global_use_etc='NO'
   local reponame

   shell_enable_nullglob
   
   # Collect from global ~/.mulle/etc/howto (global user overrides)
   log_debug "Checking ~/.mulle/etc/howto"
   if [ -d "${HOME}/.mulle/etc/howto" ]
   then
      global_use_etc='YES'
      log_debug "Found ~/.mulle/etc/howto"
      for howto in "${HOME}"/.mulle/etc/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"

            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug "~/.mulle/etc/howto does not exist"
   fi
   
   # Collect from global ~/.mulle/share/sde/howto (global installed)
   log_debug "global_use_etc=${global_use_etc}"
   log_debug "Checking ~/.mulle/share/sde/howto"
   if [ "${global_use_etc}" = 'NO' ] && [ -d "${HOME}/.mulle/share/sde/howto" ]
   then
      log_debug "Found ~/.mulle/share/sde/howto"
      for howto in "${HOME}"/.mulle/share/sde/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"

            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug "~/.mulle/share/sde/howto does not exist or global_use_etc='YES'"
   fi
   
   # Collect from .mulle/etc/howto (local overrides)
   log_debug "Checking .mulle/etc/howto"
   if [ -d ".mulle/etc/howto" ]
   then
      use_etc='YES'
      log_debug "Found .mulle/etc/howto, using etc instead of share"
      for howto in .mulle/etc/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"

            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug ".mulle/etc/howto does not exist"
   fi
   
   # Collect from .mulle/share/sde/howto (installed by extensions)
   log_debug "use_etc=${use_etc}"
   log_debug "Checking .mulle/share/sde/howto"
   if [ "${use_etc}" = 'NO' ] && [ -d ".mulle/share/sde/howto" ]
   then
      log_debug "Found .mulle/share/sde/howto"
      for howto in .mulle/share/sde/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            count=$((count + 1))
            log_debug "File exists, count=${count}"

            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug ".mulle/share/sde/howto does not exist or use_etc='YES'"
   fi
   
   # Collect from asset/howto/ (local project)
   log_debug "Checking asset/howto"

   local seen_basenames=""

   if [ -d "asset/howto" ]
   then
      log_debug "Found asset/howto"

      for howto in asset/howto/*.md
      do
         log_debug "Checking file: ${howto}"
         if [ -f "${howto}" ]
         then
            # Track basename for deduplication
            r_basename "${howto}"
            r_extensionless_basename "${RVAL}"
            name="${RVAL}"
            r_add_line "${seen_basenames}" "${name}"
            seen_basenames="${RVAL}"

            count=$((count + 1))
            log_debug "File exists, count=${count}"

            r_colon_concat "${howtos}" "${howto}"
            howtos="${RVAL}"
         fi
      done
   else
      log_debug "asset/howto does not exist"
   fi

   # Build seen_basenames from all collected howtos so far
   local basename

   .foreachpath howto in ${howtos}
   .do
      r_basename "${howto}"
      r_extensionless_basename "${RVAL}"
      basename="${RVAL}"

      if ! find_line "${seen_basenames}" "${basename}"
      then
         r_add_line "${seen_basenames}" "${basename}"
         seen_basenames="${RVAL}"
      fi
   .done

   # Collect from subdirectories (demo, test, and MULLE_SDE_TEST_PATH)
   log_debug "Checking subdirectories for howtos"

   local subdirs="demo:test"

   if [ ! -z "${MULLE_SDE_TEST_PATH}" ]
   then
      r_colon_concat "${subdirs}" "${MULLE_SDE_TEST_PATH}"
      subdirs="${RVAL}"
   fi

   local subdir
   .foreachpath subdir in ${subdirs}
   .do
      log_debug "Checking subdir: ${subdir}"
      if [ -d "${subdir}" ]
      then
         log_debug "Found ${subdir}"
         # Check each directory separately to avoid zsh glob errors
         if [ -d "${subdir}/.mulle/share/sde/howto" ]
         then
            for howto in "${subdir}"/.mulle/share/sde/howto/*.md
            do
               log_debug "Checking file: ${howto}"
               if [ -f "${howto}" ]
               then
                  r_basename "${howto}"
                  r_extensionless_basename "${RVAL}"
                  basename="${RVAL}"

                  # Skip if we already have this basename
                  if ! find_line "${seen_basenames}" "${basename}"
                  then
                     count=$((count + 1))
                     log_debug "File exists, count=${count}"
                     r_add_line "${seen_basenames}" "${basename}"
                     seen_basenames="${RVAL}"

                     r_colon_concat "${howtos}" "${howto}"
                     howtos="${RVAL}"
                  fi
               fi
            done
         fi

         if [ -d "${subdir}/.mulle/etc/howto" ]
         then
            for howto in "${subdir}"/.mulle/etc/howto/*.md
            do
               log_debug "Checking file: ${howto}"
               if [ -f "${howto}" ]
               then
                  r_basename "${howto}"
                  r_extensionless_basename "${RVAL}"
                  basename="${RVAL}"

                  # Skip if we already have this basename
                  if ! find_line "${seen_basenames}" "${basename}"
                  then
                     count=$((count + 1))
                     log_debug "File exists, count=${count}"
                     r_add_line "${seen_basenames}" "${basename}"
                     seen_basenames="${RVAL}"

                     r_colon_concat "${howtos}" "${howto}"
                     howtos="${RVAL}"
                  fi
               fi
            done
         fi
      fi
   .done

   
   # Collect from dependencies
   log_debug "Getting dependency-dir"
   local dependency_dir
   
   dependency_dir="$(rexekutor mulle-sde ${MULLE_TECHNICAL_FLAGS} dependency-dir 2>/dev/null)" || true
   
   log_debug "dependency_dir='${dependency_dir}'"
   
   # Get top-level dependencies if filtering
   local toplevel_deps
   if [ "${filter_toplevel}" = 'YES' ]
   then
      toplevel_deps="$(mulle-sourcetree -s list 2>/dev/null | tail -n +3)" || toplevel_deps=""
      log_debug "toplevel_deps='${toplevel_deps}'"
   fi

   if [ ! -z "${dependency_dir}" ] && [ -d "${dependency_dir}" ]
   then
      log_debug "Searching dependencies in ${dependency_dir}"

      local platforms
      local searchpath=':Release:Debug:RelDebug'
      local repo
      local search_dir
      
      # Check if we have platform-specific directories
      platforms="$(rexekutor mulle-sde environment get MULLE_SOURCETREE_PLATFORMS 2>/dev/null)" || true

      log_debug "platforms='${platforms}'"
      log_debug "searchpath='${searchpath}'"

      # Build list of platform directories to check (platform subdirs + root)
      local platform_dirs=":"  # Always check root (no platform subdir)

      if [ ! -z "${platforms}" ]
      then
         local platform
         for platform in ${platforms}
         do
            # Only add platform dir if it actually exists
            if [ -d "${dependency_dir}/${platform}" ]
            then
               r_colon_concat "${platform_dirs}" "${platform}"
               platform_dirs="${RVAL}"
               log_debug "Found platform directory: ${platform}"
            fi
         done
      fi

      log_debug "platform_dirs='${platform_dirs}'"

      .foreachpath platform_dir in ${platform_dirs}
      .do
         .foreachpath subdir in ${searchpath}
         .do
            if [ -z "${platform_dir}" ]
            then
               search_dir="${dependency_dir}/${subdir}/share"
            else
               search_dir="${dependency_dir}/${platform_dir}/${subdir}/share"
            fi

            log_debug "Checking ${search_dir}"
            if [ -d "${search_dir}" ]
            then
               shell_enable_nullglob
               for repo in "${search_dir}"/*
               do
                  [ -e "${repo}" ] || continue
                  log_debug "Checking repo: ${repo}"
                  if [ -d "${repo}/howto" ]
                  then
                     r_basename "${repo}"
                     reponame="${RVAL}"

                     # Filter by top-level if needed
                     if [ "${filter_toplevel}" = 'YES' ]
                     then
                        if ! echo "${toplevel_deps}" | grep -q "^${reponame}$"
                        then
                           log_debug "Skipping non-toplevel dependency: ${reponame}"
                           continue
                        fi
                     fi

                     log_debug "Found ${repo}/howto"
                     for howto in "${repo}/howto"/*.md
                     do
                        log_debug "Checking file: ${howto}"
                        if [ -f "${howto}" ]
                        then
                           r_basename "${howto}"
                           r_extensionless_basename "${RVAL}"
                           name="${RVAL}"

                           if ! find_line "${seen_basenames}" "${name}:${reponame}"
                           then
                              count=$((count + 1))
                              log_debug "File exists, count=${count}"

                              r_add_line "${seen_basenames}" "${name}:${reponame}"
                              seen_basenames="${RVAL}"

                              r_colon_concat "${howtos}" "${howto}"
                              howtos="${RVAL}"
                           fi
                        fi
                     done
                  fi
               done
               .break
            fi
         .done
      .done
   else
      log_debug "No dependency_dir or doesn't exist"
   fi

   shell_disable_nullglob

   log_debug "Total count: ${count}"
   log_debug "Collected howtos: ${howtos}"

   # Sort howtos for consistent ordering
   local sorted_howtos
   if [ ! -z "${howtos}" ]
   then
      # Convert colon-separated to newline-separated, sort, then back to colon-separated
      sorted_howtos="$(echo "${howtos}" | tr ':' '\n' | sort | tr '\n' ':')"
      # Remove trailing colon
      sorted_howtos="${sorted_howtos%:}"
   fi

   RVAL="${sorted_howtos}"

   if [ "${display}" = 'YES' ]
   then
      sde::howto::_display_sorted_list "${sorted_howtos}" "${keyword}" "${show_keywords}"
   fi

    return ${count}
}


sde::howto::r_collect_bundle_entries_filtered()
{
   log_entry "sde::howto::r_collect_bundle_entries_filtered" "$@"

   local filter_toplevel="${1:-NO}"
   local entries
   local filtered=""
   local line
   local filepath
   local repo
   local toplevel_deps=""

   if [ "${filter_toplevel}" = 'YES' ]
   then
      toplevel_deps="$(mulle-sourcetree -s list 2>/dev/null | tail -n +3)" || toplevel_deps=""
   fi

   sde::howto::r_collect_bundle_entries
   entries="${RVAL}"

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue

      if [ "${filter_toplevel}" = 'YES' ]
      then
         filepath="${line##*;}"
         case "${filepath}" in
            /*)
               if sde::howto::r_dependency_reponame_from_howto_path "${filepath}"
               then
                  repo="${RVAL}"
                  if ! printf "%s\n" "${toplevel_deps}" | grep -F -x -q "${repo}"
                  then
                     continue
                  fi
               fi
            ;;
         esac
      fi

      r_add_line "${filtered}" "${line}"
      filtered="${RVAL}"
   done <<EOF
${entries}
EOF

   RVAL="${filtered}"
}


sde::howto::r_collect_bundle_topic_howtos()
{
   log_entry "sde::howto::r_collect_bundle_topic_howtos" "$@"

   local filter_toplevel="${1:-NO}"
   local entries
   local map=""
   local line
   local filepath
   local role
   local topic
   local member
   local source_key
   local existing_line
   local existing_source_key
   local existing_role
   local existing_topic
   local existing_member
   local tmp
   local howtos=""
   local sorted_howtos=""
   local count=0

   sde::howto::r_collect_bundle_entries_filtered "${filter_toplevel}"
   entries="${RVAL}"

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue

      role="${line%%;*}"
      tmp="${line#*;}"
      topic="${tmp%%;*}"
      tmp="${tmp#*;}"
      member="${tmp%%;*}"
      filepath="${tmp#*;}"

      sde::howto::r_howto_source_key "${filepath}"
      source_key="${RVAL}"
      existing_line=""
      existing_member=""

      while IFS= read -r line
      do
         [ -z "${line}" ] && continue

         existing_source_key="${line%%;*}"
         tmp="${line#*;}"
         existing_role="${tmp%%;*}"
         tmp="${tmp#*;}"
         existing_topic="${tmp%%;*}"
         tmp="${tmp#*;}"
         existing_member="${tmp%%;*}"

         if [ "${existing_source_key}" = "${source_key}" ] &&
            [ "${existing_role}" = "${role}" ] &&
            [ "${existing_topic}" = "${topic}" ]
         then
            existing_line="${line}"
            break
         fi
      done <<EOF
${map}
EOF

      if [ -z "${existing_line}" ]
      then
         r_add_line "${map}" "${source_key};${role};${topic};${member};${filepath}"
         map="${RVAL}"
      else
         if [ "${existing_member}" != 'index' ] && [ "${member}" = 'index' ]
         then
            tmp=""
            while IFS= read -r line
            do
               [ -z "${line}" ] && continue
               [ "${line}" = "${existing_line}" ] && continue
               r_add_line "${tmp}" "${line}"
               tmp="${RVAL}"
            done <<EOF
${map}
EOF
            map="${tmp}"
            r_add_line "${map}" "${source_key};${role};${topic};${member};${filepath}"
            map="${RVAL}"
         fi
      fi
   done <<EOF
${entries}
EOF

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue
      filepath="${line##*;}"
      count=$((count + 1))
      r_colon_concat "${howtos}" "${filepath}"
      howtos="${RVAL}"
   done <<EOF
${map}
EOF

   if [ ! -z "${howtos}" ]
   then
      sorted_howtos="$(echo "${howtos}" | tr ':' '\n' | sort | tr '\n' ':')"
      sorted_howtos="${sorted_howtos%:}"
   fi

   RVAL="${sorted_howtos}"
   return ${count}
}


sde::howto::r_collect_display_howtos()
{
   log_entry "sde::howto::r_collect_display_howtos" "$@"

   local filter_toplevel="${1:-NO}"
   local howtos
   local bundle_howtos
   local filepath
   local seen_paths=""
   local count
   local sorted_howtos=""

   sde::howto::r_collect_howtos "" 'NO' 'NO' "${filter_toplevel}"
   count=$?
   howtos="${RVAL}"

   .foreachpath filepath in ${howtos}
   .do
      r_add_line "${seen_paths}" "${filepath}"
      seen_paths="${RVAL}"
   .done

   sde::howto::r_collect_bundle_topic_howtos "${filter_toplevel}"
   bundle_howtos="${RVAL}"

   .foreachpath filepath in ${bundle_howtos}
   .do
      if ! find_line "${seen_paths}" "${filepath}"
      then
         count=$((count + 1))
         r_add_line "${seen_paths}" "${filepath}"
         seen_paths="${RVAL}"
         r_colon_concat "${howtos}" "${filepath}"
         howtos="${RVAL}"
      fi
   .done

   if [ ! -z "${howtos}" ]
   then
      sorted_howtos="$(echo "${howtos}" | tr ':' '\n' | sort | tr '\n' ':')"
      sorted_howtos="${sorted_howtos%:}"
   fi

   RVAL="${sorted_howtos}"
   return ${count}
}


sde::howto::r_collect_search_howtos()
{
   log_entry "sde::howto::r_collect_search_howtos" "$@"

   local filter_toplevel="${1:-NO}"
   local howtos
   local entries
   local line
   local filepath
   local role
   local topic
   local member
   local source_key
   local seen_paths=""
   local seen_keys=""
   local count
   local sorted_howtos=""
   local key
   local tmp

   sde::howto::r_collect_howtos "" 'NO' 'NO' "${filter_toplevel}"
   count=$?
   howtos="${RVAL}"

   .foreachpath filepath in ${howtos}
   .do
      r_add_line "${seen_paths}" "${filepath}"
      seen_paths="${RVAL}"
   .done

   sde::howto::r_collect_bundle_entries_filtered "${filter_toplevel}"
   entries="${RVAL}"

   while IFS= read -r line
   do
      [ -z "${line}" ] && continue

      role="${line%%;*}"
      tmp="${line#*;}"
      topic="${tmp%%;*}"
      tmp="${tmp#*;}"
      member="${tmp%%;*}"
      filepath="${tmp#*;}"

      sde::howto::r_howto_source_key "${filepath}"
      source_key="${RVAL}"
      key="${source_key};${role};${topic};${member}"

      if ! find_line "${seen_keys}" "${key}"
      then
         r_add_line "${seen_keys}" "${key}"
         seen_keys="${RVAL}"

         if ! find_line "${seen_paths}" "${filepath}"
         then
            count=$((count + 1))
            r_add_line "${seen_paths}" "${filepath}"
            seen_paths="${RVAL}"
            r_colon_concat "${howtos}" "${filepath}"
            howtos="${RVAL}"
         fi
      fi
   done <<EOF
${entries}
EOF

   if [ ! -z "${howtos}" ]
   then
      sorted_howtos="$(echo "${howtos}" | tr ':' '\n' | sort | tr '\n' ':')"
      sorted_howtos="${sorted_howtos%:}"
   fi

   RVAL="${sorted_howtos}"
   return ${count}
}


sde::howto::list()
{
   log_entry "sde::howto::list" "$@"

   local keyword
   local show_keywords='YES'
   local OPTION_ALL
   local vibecoding

   # Get vibecoding setting from environment
   vibecoding="$(mulle-env --search-here environment get MULLE_VIBECODING 2>/dev/null)" || vibecoding="${MULLE_VIBECODING}"

   # Default based on vibecoding mode
   if [ "${vibecoding}" = 'YES' ]
   then
      OPTION_ALL='YES'
   else
      OPTION_ALL='NO'
   fi
   
   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::list_usage
         ;;

         --all|--full)
            OPTION_ALL='YES'
         ;;

         --flat)
            OPTION_ALL='NO'
         ;;

         --no-keywords)
            show_keywords='NO'
         ;;
         
         -*)
            sde::howto::list_usage "Unknown option $1"
         ;;
         
         *)
            keyword="$1"
         ;;
      esac
      shift
   done
   
   # Show current directory context
   local pwd_basename

   r_basename "${PWD}"
   pwd_basename="${RVAL}"

   # Ensure dependencies are crafted
   if ! sde::howto::ensure_dependencies_crafted "additional howto information"
   then
      log_warning "Dependencies not yet crafted. Run 'mulle-sde craft' to get howtos from dependencies."
   fi
   
   log_info "Howtos"
   
   # as we are not immediately running in a subshell
   # DEPENDENCY_DIR might not be available though, so that's not an error
   # we just skip that
   
   # Invert OPTION_ALL to filter_toplevel logic
   local filter_toplevel
   if [ "${OPTION_ALL}" = 'YES' ]
   then
      filter_toplevel='NO'
   else
      filter_toplevel='YES'
   fi

    sde::howto::r_collect_display_howtos "${filter_toplevel}"
    local count=$?
    local howtos="${RVAL}"

    if [ ! -z "${keyword}" ]
    then
       if sde::howto::r_resolve_display_howtos_for_query "${howtos}" "${keyword}"
       then
          howtos="${RVAL}"
          count=1
       fi
    fi

    sde::howto::_display_sorted_list "${howtos}" "${keyword}" "${show_keywords}"

    local displayed_count="${count}"
    if [ ! -z "${keyword}" ]
    then
       sde::howto::r_count_matching_howtos "${howtos}" "${keyword}"
       displayed_count="${RVAL}"
    fi

    if [ ${displayed_count} -eq 0 ]
    then
      if [ ! -z "${keyword}" ]
      then
         fail "No howto files found matching '${keyword}'"
      fi
      log_info "No howto files found"
   fi

   # Hint about AI skills found in any dot-dir under the project root
   local _dotdir
   local _skillsdirs

   _skillsdirs=""
   for _dotdir in "${MULLE_VIRTUAL_ROOT:-.}"/.*
   do
      if [ -d "${_dotdir}/skills" ]
      then
         _skillsdirs="${_skillsdirs} ${_dotdir##*/}/skills"
      fi
   done

   if [ -n "${_skillsdirs}" ]
   then
      log_info "Agent skills available in:${_skillsdirs}"
   fi

   return 0
}


sde::howto::keywords()
{
   log_entry "sde::howto::keywords" "$@"
   
   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::keywords_usage
         ;;

         -*)
            sde::howto::keywords_usage "Unknown option $1"
         ;;
         
         *)
            sde::howto::keywords_usage "Unexpected argument $1"
         ;;
      esac
      shift
   done
   
    # Collect all searchable howtos silently
    sde::howto::r_collect_search_howtos 'NO'
    local count=$?
    local howtos="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      log_info "No howto files found"
      return 1
   fi
   
   # Collect all keywords
   local all_keywords
   local howto
   local keywords_line
   
   .foreachpath howto in ${howtos}
   .do
      # Look for keywords comment line: <!-- keywords: word1 word2 word3 -->
      keywords_line="$(grep -i '^<!--[[:space:]]*[Kk]eywords:' "${howto}" 2>/dev/null | head -n 1)"
      
      if [ ! -z "${keywords_line}" ]
      then
         # Extract keywords between "keywords:" and "-->"
         # Remove <!-- and --> using case-insensitive pattern
         keywords_line="${keywords_line#*eywords:}"
         keywords_line="${keywords_line%-->*}"
         
         # Trim whitespace and add to collection
         keywords_line="$(echo "${keywords_line}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
         
         if [ ! -z "${keywords_line}" ]
         then
            r_concat "${all_keywords}" "${keywords_line}"
            all_keywords="${RVAL}"
         fi
      fi
   .done
   
   if [ -z "${all_keywords}" ]
   then
      log_info "No keywords found in howto files"
      return 0
   fi
   
   # Split by spaces and commas, sort unique
   echo "${all_keywords}" | tr ' ,' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' | sort -u
   
   return 0
}


sde::howto::grep()
{
   log_entry "sde::howto::grep" "$@"
   
   local pattern
   
   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::grep_usage
         ;;

         -*)
            sde::howto::grep_usage "Unknown option $1"
         ;;
         
         *)
            [ ! -z "${pattern}" ] && sde::howto::grep_usage "Too many arguments"
            pattern="$1"
         ;;
      esac
      shift
   done
   
   [ -z "${pattern}" ] && sde::howto::grep_usage "Missing pattern for grep"
   
    # Collect all searchable howtos silently
    sde::howto::r_collect_search_howtos 'NO'
    local count=$?
    local howtos="${RVAL}"
   
   if [ ${count} -eq 0 ]
   then
      log_info "No howto files found"
      return 1
   fi
   
   # Grep through all files with local context, grouped by file
   local howto
   local found='NO'
   local first='YES'
   local matches
   local display_name
   local label

   .foreachpath howto in ${howtos}
   .do
     matches="$(rexekutor grep -n -C 1 -i "${pattern}" "${howto}" 2>/dev/null)"
     [ -z "${matches}" ] && .continue

     if [ "${first}" = 'NO' ]
     then
        printf "\n"
     fi
     first='NO'
     found='YES'

     sde::howto::r_howto_display_name "${howto}"
     display_name="${RVAL}"
     sde::howto::r_howto_display_label "${howto}"
     label="${RVAL}"

     if [ ! -z "${label}" ]
     then
        log_info "${display_name} ${label}"
     else
        log_info "${display_name}"
     fi
     printf "%s\n" "${matches}"
   .done
   
   if [ "${found}" = 'NO' ]
   then
      log_info "No matches found for '${pattern}'"
      return 1
   fi
   
   return 0
}


sde::howto::apropos()
{
   log_entry "sde::howto::apropos" "$@"

   local question

   # Parse options
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::apropos_usage
         ;;

         -*)
            sde::howto::apropos_usage "Unknown option $1"
         ;;

         *)
            [ ! -z "${question}" ] && sde::howto::apropos_usage "Too many arguments"
            question="$1"
         ;;
      esac
      shift
   done

   [ -z "${question}" ] && sde::howto::apropos_usage "Missing question"

    # Collect all searchable howtos silently
    sde::howto::r_collect_search_howtos 'NO'
    local count=$?
    local howtos="${RVAL}"

   if [ ${count} -eq 0 ]
   then
      log_info "No howto files found"
      return 1
   fi

   local display_howtos
   local display_count
   local keywords
   local word
   local howto
   local score
   local seen=""
   local topic_matches=""
   local key
   local display_name
   local label
   local keywords_str
   local result_path
   local number=0

   sde::howto::r_collect_display_howtos 'NO'
   display_count=$?
   display_howtos="${RVAL}"

   if [ ${display_count} -gt 0 ]
   then
      if sde::howto::r_resolve_display_howtos_for_query "${display_howtos}" "${question}"
      then
         log_info "Howtos"
         sde::howto::_display_sorted_list "${RVAL}" "" 'YES'
         return 0
      fi
   fi

   keywords="$(echo "${question}" | \
      tr '[:upper:]' '[:lower:]' | \
      sed 's/[^a-z0-9 ]/ /g' | \
      tr -s ' ' '\n' | \
      grep -v -E '^(how|do|i|a|an|the|is|are|to|in|for|of|with|what|where|when|why|can|could|should|would|explain|show|tell|me|about)$' | \
      tr '\n' ' ' | \
      sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

   if [ -z "${keywords}" ]
   then
      log_warning "Could not extract meaningful keywords from question"
      keywords="${question}"
   fi

   .foreachpath howto in ${howtos}
   .do
      score=0
      .foreachitem word in ${keywords}
      .do
         if sde::howto::r_matches_apropos_word "${howto}" "${word}"
         then
            score=$((score + 1))
         fi
      .done

      [ ${score} -eq 0 ] && .continue

      sde::howto::r_howto_topic_display_name "${howto}"
      display_name="${RVAL}"
      sde::howto::r_howto_source_key "${howto}"
      key="${RVAL};${display_name}"
      if find_line "${seen}" "${key}"
      then
         .continue
      fi

      r_add_line "${seen}" "${key}"
      seen="${RVAL}"
      r_add_line "${topic_matches}" "${howto}"
      topic_matches="${RVAL}"
   .done

   if [ -z "${topic_matches}" ]
   then
      log_info "No howto topics found for '${question}'"
      return 1
   fi

   log_info "Howtos"
   while IFS= read -r result_path
   do
      [ -z "${result_path}" ] && continue

      number=$((number + 1))
      sde::howto::r_howto_topic_display_name "${result_path}"
      display_name="${RVAL}"
      sde::howto::r_howto_display_label "${result_path}"
      label="${RVAL}"

      sde::howto::r_extract_keywords "${result_path}"
      keywords_str="${RVAL}"

      if [ ! -z "${keywords_str}" ]
      then
         if [ ! -z "${label}" ]
         then
            printf "%2d. %-30s [%s] %s\n" "${number}" "${display_name}" "${keywords_str}" "${label}"
         else
            printf "%2d. %-30s [%s]\n" "${number}" "${display_name}" "${keywords_str}"
         fi
      else
         if [ ! -z "${label}" ]
         then
            printf "%2d. %-30s %s\n" "${number}" "${display_name}" "${label}"
         else
            printf "%2d. %s\n" "${number}" "${display_name}"
         fi
      fi
   done <<EOF
$(printf "%s\n" "${topic_matches}" | LC_ALL=C sort)
EOF

   return 0
}


sde::howto::show()
{
   log_entry "sde::howto::show" "$@"

   # If in test directory, run in parent project using mudo
   if sde::is_test_directory "${PWD}"
   then
      log_debug "In test directory, running show in parent via mudo"
      local parent_dir
      r_dirname "${PWD}"
      parent_dir="${RVAL}"
      
      rexekutor mudo -e sh -c "cd '${parent_dir}' && mulle-sde howto show $*"
      return $?
   fi

   local OPTION_KEYWORDS
   local OPTION_ROLE
   local OPTION_TOPIC
   local OPTION_FILE
   local option_name
   local role
   local topic
   local member
   local bundle_path
   local coder_bundle_path
   local shortcut_role
   local shortcut_topic
   local shortcut_map

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::show_usage
         ;;

         --keyword)
            shift
            [ $# -eq 0 ] && sde::howto::show_usage "Missing value for --keyword"
            r_comma_concat "${OPTION_KEYWORDS}" "$1"
            OPTION_KEYWORDS="${RVAL}"
         ;;

         --role)
            shift
            [ $# -eq 0 ] && sde::howto::show_usage "Missing value for --role"
            OPTION_ROLE="$1"
         ;;

         --topic)
            shift
            [ $# -eq 0 ] && sde::howto::show_usage "Missing value for --topic"
            OPTION_TOPIC="$1"
         ;;

         --file|--member)
            option_name="$1"
            shift
            [ $# -eq 0 ] && sde::howto::show_usage "Missing value for ${option_name}"
            OPTION_FILE="$1"
         ;;

         -*)
            sde::howto::show_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local identifier="$1"
   local using_selector='NO'

   if [ ! -z "${OPTION_ROLE}${OPTION_TOPIC}${OPTION_FILE}" ]
   then
     using_selector='YES'
   fi

   # If keywords specified, use those instead of identifier
   if [ ! -z "${OPTION_KEYWORDS}" ]
   then
     [ ! -z "${OPTION_ROLE}${OPTION_TOPIC}${OPTION_FILE}" ] && sde::howto::show_usage "--keyword can not be combined with --role, --topic, or --file"
     [ $# -ne 0 ] && sde::howto::show_usage "Unexpected argument $1"
      identifier="${OPTION_KEYWORDS}"
   elif [ "${using_selector}" = 'NO' ]
   then
      [ -z "${identifier}" ] && sde::howto::show_usage "Missing argument (number or filename)"
   fi

   if [ -z "${OPTION_KEYWORDS}" ] && [ "${using_selector}" = 'YES' ]
   then
     topic="${OPTION_TOPIC}"
      role="${OPTION_ROLE}"
      member="${OPTION_FILE:-index}"

      [ $# -ne 0 ] && sde::howto::show_usage "Unexpected argument $1"

      if [ ! -z "${role}" ] && [ -z "${topic}" ]
      then
         # --role without --topic: show all topics for that role
         local entries
         local topics
         local a_topic
         local map

         sde::howto::r_collect_bundle_entries
         entries="${RVAL}"
         sde::howto::r_collect_topics_for_role "${entries}" "${role}"
         topics="${RVAL}"

         [ -z "${topics}" ] && fail "No howto topics found for role '${role}'"

         while IFS= read -r a_topic
         do
            [ -z "${a_topic}" ] && continue
            sde::howto::r_collect_bundle_member_map "${role}" "${a_topic}"
            map="${RVAL}"
            [ -z "${map}" ] && continue
            sde::howto::_emit_bundle_map "${map}"
         done <<< "${topics}"
         return 0
      fi

      [ -z "${topic}" ] && sde::howto::show_usage "Missing topic"

      if [ ! -z "${role}" ]
      then
         if sde::howto::r_resolve_bundle_member "${role}" "${topic}" "${member}"
         then
            bundle_path="${RVAL}"
            sde::howto::emit_howto_file "${bundle_path}"
            return 0
         fi
      else
         [ ! -z "${OPTION_FILE}" ] && sde::howto::show_usage "Missing role"
         if sde::howto::r_resolve_bundle_member 'coder' "${topic}" 'index'
         then
           bundle_path="${RVAL}"
           sde::howto::emit_howto_file "${bundle_path}"
           return 0
         fi
         if sde::howto::r_resolve_bundle_shortcut "${topic}"
         then
            shortcut_role="${RVAL%%;*}"
            shortcut_topic="${RVAL#*;}"

            sde::howto::r_collect_bundle_member_map "${shortcut_role}" "${shortcut_topic}"
            shortcut_map="${RVAL}"

            if [ ! -z "${shortcut_map}" ]
            then
               sde::howto::_emit_bundle_map "${shortcut_map}"
               return 0
            fi
         fi
         identifier="${topic}"
      fi
   elif [ -z "${OPTION_KEYWORDS}" ] && [ $# -ge 2 ]
   then
      role="$1"
      topic="$2"
      member="${3:-index}"

      [ $# -gt 3 ] && sde::howto::show_usage "Too many arguments"

      if sde::howto::r_resolve_bundle_member "${role}" "${topic}" "${member}"
      then
         bundle_path="${RVAL}"
         sde::howto::emit_howto_file "${bundle_path}"
         return 0
      fi
   fi

   if [ -z "${OPTION_KEYWORDS}" ] && [ $# -eq 1 ]
   then
     if sde::howto::r_resolve_bundle_member 'coder' "${identifier}" 'index'
     then
        coder_bundle_path="${RVAL}"
        sde::howto::emit_howto_file "${coder_bundle_path}"
        return 0
     fi

     if sde::howto::r_resolve_bundle_shortcut "${identifier}"
     then
        shortcut_role="${RVAL%%;*}"
        shortcut_topic="${RVAL#*;}"

        sde::howto::r_collect_bundle_member_map "${shortcut_role}" "${shortcut_topic}"
        shortcut_map="${RVAL}"

        if [ ! -z "${shortcut_map}" ]
        then
           sde::howto::_emit_bundle_map "${shortcut_map}"
           return 0
        fi
     fi
   fi

    # Collect searchable or display howtos silently
    if [ ! -z "${OPTION_KEYWORDS}" ]
    then
       sde::howto::r_collect_search_howtos 'NO'
    else
       sde::howto::r_collect_display_howtos 'NO'
    fi
    local count=$?
    local howtos="${RVAL}"

   # If keywords specified, show all matching files
   if [ ! -z "${OPTION_KEYWORDS}" ]
   then
      sde::howto::show_keyword_matches "${howtos}" "${OPTION_KEYWORDS}"
      return 0
   fi
   
   # Normal mode: find by number or exact filename
   local found='NO'
   local index=0
   local howto
   local name
   local subdir_part
   local name_part
   
   # Check if identifier is a number
   case "${identifier}" in
      [0-9]*)
         # It's a number - find by index
         .foreachpath howto in ${howtos}
         .do
            index=$((index + 1))
            if [ ${index} -eq ${identifier} ]
            then
               sde::howto::emit_howto_file "${howto}"
               found='YES'
               .break
            fi
         .done
      ;;
      
      *)
         # It's a filename - try exact match first, then fuzzy match
         # Check if it's in subdir/name format
         case "${identifier}" in
            */*)
                .foreachpath howto in ${howtos}
                .do
                   sde::howto::r_howto_display_name "${howto}"
                   name="${RVAL}"
                   if [ "${name}" = "${identifier}" ]
                   then
                      sde::howto::emit_howto_file "${howto}"
                      found='YES'
                      .break
                   fi
                .done
             ;;
            
            *)
                # No slash - try exact match on basename first
                .foreachpath howto in ${howtos}
                .do
                   sde::howto::r_howto_display_name "${howto}"
                   name="${RVAL}"

                  # Try exact match first
                  if [ "${name}" = "${identifier}" ]
                  then
                     sde::howto::emit_howto_file "${howto}"
                     found='YES'
                     .break
                  fi
               .done
               
               # If no exact match, try fuzzy match (substring)
                if [ "${found}" = 'NO' ]
                then
                   .foreachpath howto in ${howtos}
                   .do
                      sde::howto::r_howto_display_name "${howto}"
                      name="${RVAL}"

                      # Check if identifier is contained in display name
                      if grep -q -i "${identifier}" <<< "${name}"
                      then
                         sde::howto::emit_howto_file "${howto}"
                        found='YES'
                        .break
                     fi
                  .done
               fi
            ;;
         esac
      ;;
   esac
   
   if [ "${found}" = 'NO' ]
   then
      case "${identifier}" in
         [0-9]*)
            fail "No howto with number ${identifier} found (total: ${count})"
         ;;
         *)
             # Try searching by keyword before giving up
             sde::howto::r_collect_display_howtos 'NO'
             local keyword_howtos="${RVAL}"

             sde::howto::r_count_matching_howtos "${keyword_howtos}" "${identifier}"
             local keyword_count="${RVAL}"

             if [ ${keyword_count} -gt 0 ]
             then
                sde::howto::show_keyword_matches "${keyword_howtos}" "${identifier}" 'coder'
                return 0
            else
               fail "No howto named '${identifier}' found"
            fi
         ;;
      esac
   fi
}


sde::howto::main()
{
   log_entry "sde::howto::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sde::howto::usage
         ;;

         --)
            shift
            break
         ;;

         -*)
            sde::howto::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd

   if [ $# -ne 0 ]
   then
      cmd="$1"
      shift
   fi

   case "${cmd:-list}" in
      'help')
         sde::howto::usage
      ;;

      'list')
         sde::howto::list "$@"
      ;;

      'show'|'cat')
         sde::howto::show "$@"
      ;;

      'roles')
         sde::howto::roles "$@"
      ;;

      'topics')
         sde::howto::topics "$@"
      ;;

      'files')
         sde::howto::files "$@"
      ;;

      'load')
         sde::howto::load "$@"
      ;;

      'keywords')
         sde::howto::keywords "$@"
      ;;
      
      'grep')
         sde::howto::grep "$@"
      ;;
      
      'apropos'|'search')
         sde::howto::apropos "$@"
      ;;

      *)
         sde::howto::show "${cmd}" "$@"
      ;;
   esac
}
