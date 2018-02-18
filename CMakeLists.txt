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
src/mulle-sde-dependency.sh
src/mulle-sde-extension.sh
src/mulle-sde-init.sh
src/mulle-sde-library.sh
src/mulle-sde-monitor.sh
src/mulle-sde-plugin.sh
src/mulle-sde-subproject.sh
src/mulle-sde-template.sh
src/mulle-sde-tool.sh
src/mulle-sde-update.sh
src/mulle-sde-upgrade.sh
)

set( EXTENSIONS
src/extensions
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
include( CMakePackage.cmake)
include( CPack)
