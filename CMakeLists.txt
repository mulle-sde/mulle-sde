cmake_minimum_required( VERSION 3.0)

project( mulle-sde NONE)

execute_process( COMMAND ./mulle-sde version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_SDE_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_SDE_VERSION is ${MULLE_SDE_VERSION} according to mulle-sde")


set( PROJECT_VERSION "${MULLE_SDE_VERSION}")


set( SCRIPTS
mulle-sde
)

set( LIBRARY_SCRIPTS
src/mulle-sde-build.sh
src/mulle-sde-common.sh
src/mulle-sde-dependencies.sh
src/mulle-sde-extensions.sh
src/mulle-sde-init.sh
src/mulle-sde-initsupport.sh
src/mulle-sde-libraries.sh
src/mulle-sde-monitor.sh
src/mulle-sde-subprojects.sh
src/mulle-sde-tools.sh
src/mulle-sde-updatesupport.sh
)

set( COMMON_EXTENSION_BIN
"src/extensions/common/bin/is-test-file"
"src/extensions/common/bin/create-build-motd"
"src/extensions/common/bin/source-directory-names"
"src/extensions/common/bin/test-directory-names"
)

set( EXTENSIONS
src/extensions
)

set( C_EXTENSION_BIN
src/extensions/c/bin/is-header-or-source
src/extensions/c/bin/classify-headers
src/extensions/c/bin/classify-sources
)

set( C_EXTENSION_PROJECT
src/extensions/c/bin/is-header-or-source
src/extensions/c/bin/classify-headers
src/extensions/c/bin/classify-sources
)

set( CMAKE_EXTENSION_BIN
src/extensions/cmake/bin/did-update-src
src/extensions/cmake/bin/did-update-sourcetree
)


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-sde")


INSTALL( DIRECTORY ${EXTENSIONS}
DESTINATION "share/mulle-sde")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage)
include( CPack)
