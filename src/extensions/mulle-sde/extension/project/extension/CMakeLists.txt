cmake_minimum_required( VERSION 3.0)

project( <|PROJECT_NAME|> NONE)

set( PROJECT_VERSION 0.0.0)


set( SCRIPTS
)

set( EXTENSIONS
src/extensions
)


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


INSTALL( DIRECTORY ${EXTENSIONS}
DESTINATION "share/<|VENDOR_NAME|>")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
