#! /bin/sh
#
# Example shelll script to generate CMakeLists.txt
#
DIR="${1:-.}"
[ $# -ne 0 ] && shift


SUFFIX="${1:-_standalone}"
[ $# -ne 0 ] && shift

#
# create first target with project headers
#
mulle-cmake-staticlibrary-target.sh --name a "${DIR}" -- src/a > "${DIR}"/CMakeLists.txt

#
# now turn header generation off
#
NO_HEADER=YES; export NO_HEADER

#
# add platform specific libraries
# in this example it just pthreads
#
case "`uname`" in
   Darwin)
      libraries="-lpthread"
      ;;

   FreeBSD)
      libraries="-lpthread"
      ;;

   Linux)
      libraries="-lpthread"
      ;;

   *)
      libraries="-lpthread"
      ;;
esac

#
# b depends on a, so note the dependency explicity
#
mulle-cmake-sharedlibrary-target.sh --dependency a --name b    "${DIR}" -- src/b   -- ${libraries} >> "${DIR}"/CMakeLists.txt
mulle-cmake-executable-target.sh    --dependency b --name demo "${DIR}" -- src/exe -- ${libraries} >> "${DIR}"/CMakeLists.txt
