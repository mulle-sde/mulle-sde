# shellcheck shell=bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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
sde::supermarks::__r_detect_language()
{
   log_entry "sde::supermarks::__r_detect_language" "$@"

   local remaining="$1"
   local marks="$2"

   if [ "${_type}" != 'EMBEDDED' ]
   then
      #
      # no-cmake-loader     : C code needs no ObjCLoader (if all-load is set)
      # no-cmake-searchpath : We don't flatten C source headers by default
      # no-all-load         : C libraries are usually cherry-picked for symbols
      # no-import           : use #include instead of #import
      # singlephase         : assume most C stuff is old fashioned
      #
      # DEPENDENCY_C_MARKS="no-import,no-all-load,no-cmake-loader,no-cmake-searchpath"

      if sourcetree::marks::disable "${remaining}" 'import'
      then
         r_comma_concat "${_supermarks}" 'C'
         _supermarks="${RVAL}"

         sourcetree::marks::r_clean_marks "${remaining}" 'import,cmake-loader,cmake-searchpath'
         remaining="${RVAL}"
      fi

      if sourcetree::marks::enable "${remaining}" 'all-load'
      then
         case ",${_supermarks}," in
            *,C,*)
               # c force load out
               if sourcetree::marks::enable "${remaining}" 'link'
               then
                  r_comma_concat "${_supermarks}" 'LinkForce'
                  _supermarks="${RVAL}"
               else
                  r_comma_concat "${_supermarks}" 'UnknownLanguage'
                  _supermarks="${RVAL}"
               fi
            ;;

            *)
               r_comma_concat "${_supermarks}" 'ObjC'
               _supermarks="${RVAL}"
            ;;
         esac
      fi
   fi
   sourcetree::marks::r_clean_marks "${remaining}" 'import'
   remaining="${RVAL}"
   sourcetree::marks::r_clean_marks "${remaining}" 'all-load'
   remaining="${RVAL}"

   log_setting "_type       : ${_type}"
   log_setting "_supermarks : ${_supermarks}"
   log_setting "remaining   : ${remaining}"

   RVAL="${remaining}"
}


# local __type
sde::supermarks::__r_detect_link()
{
   log_entry "sde::supermarks::__r_detect_link" "$@"

   local remaining="$1"
   local marks="$2"

   if [ "${_type}" = 'EMBEDDED' ]
   then
      RVAL="${remaining}"
      return 0
   fi

   if sourcetree::marks::enable "${marks}" "link"
   then
      if sourcetree::marks::compatible_with_marks "${marks}" "no-cmake-inherit"
      then
         r_comma_concat "${_supermarks}" 'LinkLeaf'
         _supermarks="${RVAL}"
      fi

      if sourcetree::marks::compatible_with_marks "${remaining}" \
            'all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header'
      then
         r_comma_concat "${_supermarks}" 'Startup'
         _supermarks="${RVAL}"
         sourcetree::marks::r_clean_marks "${remaining}" \
            'intermediate-link,dynamic-link,header'
         remaining="${RVAL}"
      else
         if sourcetree::marks::compatible_with_marks "${remaining}" \
               'no-dynamic-link,no-intermediate-link'
         then
            r_comma_concat "${_supermarks}" 'LinkStaticToExe'
            _supermarks="${RVAL}"
            sourcetree::marks::r_clean_marks "${remaining}" \
                                                  'descend'
            remaining="${RVAL}"
         fi
      fi
   fi

   sourcetree::marks::r_clean_marks "${remaining}" \
                                         'link,cmake-inherit,dynamic-link,intermediate-link'
   remaining="${RVAL}"

   log_setting "_type       : ${_type}"
   log_setting "_supermarks : ${_supermarks}"
   log_setting "remaining   : ${remaining}"

   RVAL="${remaining}"
}



sde::supermarks::__r_supermarks()
{
   log_entry "sde::supermarks::__r_supermarks" "$@"

   local remaining="$1"
   local marks="$2"

   if [ "${_type}" != 'EMBEDDED' ]
   then
      if sourcetree::marks::disable "${remaining}" 'public'
      then
         r_comma_concat "${_supermarks}" "HeaderPrivate"
         _supermarks="${RVAL}"
      fi
   fi
   sourcetree::marks::r_clean_marks "${remaining}" 'public'
   remaining="${RVAL}"

   if [ "${_type}" != 'EMBEDDED' ]
   then
      if sourcetree::marks::disable "${remaining}" 'header'
      then
         r_comma_concat "${_supermarks}" 'HeaderLess'
         _supermarks="${RVAL}"
      else
         if sourcetree::marks::disable "${remaining}" 'link'
         then
            r_comma_concat "${_supermarks}" 'HeaderOnly'
            _supermarks="${RVAL}"
         fi
      fi
   fi
   sourcetree::marks::r_clean_marks "${remaining}" 'header'
   remaining="${RVAL}"

   if [ "${_type}" != 'EMBEDDED' -a "${_type}" != 'LIBRARY' ]
   then
      if sourcetree::marks::enable "${remaining}" 'singlephase'
      then
         r_comma_concat "${_supermarks}" 'Serial'
         _supermarks="${RVAL}"
      fi
   fi
   sourcetree::marks::r_clean_marks "${remaining}" 'singlephase'
   remaining="${RVAL}"

   log_setting "_type       : ${_type}"
   log_setting "_supermarks : ${_supermarks}"
   log_setting "remaining   : ${remaining}"

   RVAL="${remaining}"
}


sde::supermarks::r_decompose_supermark()
{
   log_entry "sde::supermarks::r_decompose_supermark" "$@"

   local supermark="$1"

   RVAL=
   case "${supermark}" in
      'C')
         RVAL='no-all-load,no-import'
         return 0
      ;;

      'HeaderLess')
         RVAL='build,no-header,link'
         return 0
      ;;

      'HeaderOnly')
         RVAL='build,header,no-link'
         return 0
      ;;

      'HeaderPrivate')
         RVAL='no-public'
         return 0
      ;;

      'LinkForce')
         RVAL="link,no-all-load"
         return 0
      ;;

      'LinkLeaf')
         RVAL="link,no-cmake-inherit"
         return 0
      ;;

      'LinkStaticToExe')
         RVAL='link,no-dynamic-link,no-intermediate-link'
         return 0
      ;;

      'ObjC')
         RVAL="import,all-load"
         return 0
      ;;

      'Parallel')
         RVAL='no-singlephase'
         return 0
      ;;

      'Serial')
         RVAL='singlephase'
         return 0
      ;;

      'Startup')
         RVAL='all-load,singlephase,no-intermediate-link,no-dynamic-link,no-header,no-cmake-searchpath,no-cmake-loader'
         return 0
      ;;

      'UnknownLanguage')
         return 0
      ;;

   esac

   return 1
}


#
# this file is loaded into mulle-sourcetree as a plugin
#
sde::supermarks::initialize()
{
   include "sourcetree::supermarks"

   sourcetree::supermarks::add_detectors sde::supermarks::__r_detect_language \
                                         sde::supermarks::__r_detect_link \
                                         sde::supermarks::__r_supermarks

   sourcetree::supermarks::add_supermarks 'C' \
                                          'HeaderLess' \
                                          'HeaderOnly' \
                                          'HeaderPrivate' \
                                          'LinkForce' \
                                          'LinkLeaf' \
                                          'LinkStaticToExe' \
                                          'ObjC' \
                                          'Parallel' \
                                          'Serial' \
                                          'Startup' \
                                          'UnknownLanguage'

   sourcetree::supermarks::add_decomposers sde::supermarks::r_decompose_supermark
}


sde::supermarks::initialize

:

