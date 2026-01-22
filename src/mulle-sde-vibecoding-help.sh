# shellcheck shell=bash
#
# Vibecoding-aware help suggestions on command failure
#
MULLE_SDE_VIBECODING_HELP_SH='included'


# Map command names to howto topics (fuzzy match)
sde::vibecoding_help::r_map_command_to_howto()
{
   local cmd="$1"
   
   RVAL=""
   
   # Direct mappings
   case "${cmd}" in
      dependency|dep)
         RVAL="dependency"
      ;;
      library|lib|libraries)
         RVAL="library"
      ;;
      craft|recraft)
         RVAL="craft"
      ;;
      test|retest)
         RVAL="testing"
      ;;
      reflect)
         RVAL="reflect"
      ;;
      add)
         RVAL="add"
      ;;
      clean)
         RVAL="clean"
      ;;
      *)
         # Use command name as-is for fuzzy matching
         RVAL="${cmd}"
      ;;
   esac
}


# Find matching howto file
sde::vibecoding_help::r_find_howto()
{
   local keyword="$1"
   
   RVAL=""
   
   include "sde::howto"
   
   sde::howto::r_collect_howtos "" 'NO'
   local howtos="${RVAL}"
   
   [ -z "${howtos}" ] && return 1
   
   local h
   
   # Try exact match first
   .foreachpath h in ${howtos}
   .do
      r_basename "${h}"
      r_extensionless_basename "${RVAL}"
      if [ "${RVAL}" = "${keyword}" ]
      then
         RVAL="${h}"
         return 0
      fi
   .done
   
   # Try fuzzy match
   .foreachpath h in ${howtos}
   .do
      r_basename "${h}"
      r_extensionless_basename "${RVAL}"
      if grep -q -i "${keyword}" <<< "${RVAL}"
      then
         RVAL="${h}"
         return 0
      fi
   .done
   
   return 1
}


# Show help for command - howto if available, otherwise usage
sde::vibecoding_help::show_help()
{
   local cmd="$1"
   local error_pattern="${2:-}"
   
   sde::vibecoding_help::r_map_command_to_howto "${cmd}"
   local howto_keyword="${RVAL}"
   
   if sde::vibecoding_help::r_find_howto "${howto_keyword}"
   then
      log_info "📖 See: ${C_RESET_BOLD}mulle-sde howto show ${howto_keyword}"
   else
      # No howto found, show command usage
      log_info "💡 Try: ${C_RESET_BOLD}mulle-sde ${cmd} help"
   fi
}


# Main entry point: suggest help on command failure
# Called automatically after any command fails in vibecoding mode
sde::vibecoding_help::on_failure()
{
   log_entry "sde::vibecoding_help::on_failure" "$@"
   
   [ "${MULLE_VIBECODING}" != 'YES' ] && return 0
   
   local cmd="$1"
   local rval="${2:-1}"
   
   # Skip for help/usage commands
   case "${cmd}" in
      help|usage|commands|version)
         return 0
      ;;
   esac
   
   echo "" >&2
   log_info "❌ ${C_RESET_BOLD}Vibecoding Tip${C_INFO}: Command '${cmd}' failed (exit ${rval})"
   echo "" >&2
   
   sde::vibecoding_help::show_help "${cmd}"
   
   echo "" >&2
   
   # Always return 0 - we're just showing help, not changing the error
   return 0
}
