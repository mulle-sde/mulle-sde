# shellcheck shell=bash
#
#   Copyright (c) 2024 Nat! - Mulle kybernetiK
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
# Rebuild if files of certain files are modified
#
MULLE_SDE_RUN_SH='included'


sde::run::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} run [options] [arguments] ...

   Run the main executable of the given project, with the arguments given.
   The executable will not run within the mulle-sde environment!

Options:
   -- pass remaining options as arguments

EOF
   exit 1
}


sde::run::freshest_files()
{
   log_entry "sde::run::freshest_files" "$@"

   local files="$1"

   local filename
   local sortlines

   .foreachline filename in ${files}
   .do
      # guard for executables read from motd that find didn't check
      if [ -f "${filename}" ]
      then
         r_add_line "${sortlines}" "`modification_timestamp "${filename}"` ${filename#${MULLE_USER_PWD}/}"
         sortlines="${RVAL}"
      fi
   .done

   sort -rn <<< "${sortlines}" | sed 's/[0-9]* //'
}


sde::run::main()
{
   local executable

   local projecttype

   projecttype="`mulle-sde env get PROJECT_TYPE`"
   if [ "${projecttype}" != "executable" ]
   then
      fail "\"mulle-sde run\" works only in executable projects"
   fi

   local kitchen_dir

   kitchen_dir="`mulle-sde kitchen-dir`"
   if ! [ -d "${kitchen_dir}" ]
   then
      log_info "Run craft first to produce product"
      mulle-sde craft || exit 1
   fi

   if ! [ -d "${kitchen_dir}" ]
   then
      fail "Couldn't figure out kitchen-dir. VERY OBSCURE!!"
   fi

   local motd_files
   local executables
   local filename

   motd_files="`rexekutor find "${kitchen_dir}" -name '.motd' \
                                                -type f \
                                                -not -path "${kitchen_dir}/.craftorder/*" `"

   motd_files="`sde::run::freshest_files "${motd_files}"`"

   log_setting "kitchen_dir : ${kitchen_dir}"
   log_setting "motd_files  : ${motd_files}"

   if [ ! -z "${motd_files}" ]
   then
      r_line_at_index "${motd_files}" 0
      filename="${RVAL}"

      executables="`rexekutor sed -n  -e "s/"$'\033'"[^"$'\033'"]*$//g" \
                                      -e 's/^.*[[:blank:]][[:blank:]][[:blank:]]\(.*\)/\1/p' \
                                     "${filename}" `"

      hexdump -C <<< "${executables}"
   fi

   log_setting "executables  : ${executables}"

   if [ -z "${executables}" ]
   then
      #
      # fallback code, if we have no motd, or couldn't parse it
      # then look for PROJECT_NAME.exe or
      # PROJECT_NAME
      #
      local projectname

      projectname="`mulle-sde env get PROJECT_TYPE`"
      executables="`rexekutor find "${kitchen_dir}" \( -name "${projectname}" \
                                                    -o -name "${projectname}.exe" \
                                                    \) \
                                                   -type f \
                                                   -perm 111 \
                                                   -not -path "${kitchen_dir}/.craftorder/*" `"

      executables="`sde::run::freshest_files "${executables}"`"
      if [ -z "${executables}" ]
      then
         fail "Could not figure what product was build.
${C_RESET_BOLD}${projectname}${C_ERROR} or ${C_RESET_BOLD}${projectname}.exe${C_ERROR} not found in ${C_RESET_BOLD}${kitchendir#${MULLE_USER_PWD}/}"
      fi

      # we pick the first of whatever
      r_line_at_index "${executables}"
      executables="${RVAL}"
   fi

   local row
   local executable

   rexekutor mudo mulle-menu --title "Choose executable:" \
                             --final-title "" \
                             --options "${executables}"
   row=$?

   if [ $row -gt 128 ]
   then
      return 1
   fi
   r_line_at_index "${executables}" $row
   executable="${RVAL}"

   exekutor mudo "${executable}" "$@"
}

