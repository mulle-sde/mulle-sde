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


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
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



######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
