cmake_minimum_required( VERSION 3.0)

# use C, because otherwise a CXX compiler is required
project( mulle-sde C)

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
src/mulle-sde-init.sh
src/mulle-sde-monitor.sh
)

set( C_EXTENSION_SCRIPTS
src/extensions/c/init
)

set( CMAKE_EXTENSION_SCRIPTS
src/extensions/cmake/did-update-src
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


INSTALL( FILES ${C_EXTENSION_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-sde/extensions/c")

INSTALL( FILES ${CMAKE_EXTENSION_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-sde/extensions/cmake")
