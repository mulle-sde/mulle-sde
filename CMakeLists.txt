cmake_minimum_required( VERSION 3.15)

project( mulle-sde VERSION 3.2.7 LANGUAGES NONE)

execute_process( COMMAND ./mulle-sde version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_SDE_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_SDE_VERSION is ${MULLE_SDE_VERSION} according to mulle-sde")


set( PROJECT_VERSION "${MULLE_SDE_VERSION}")


set( SCRIPTS
mulle-sde
mulle-sde-cd
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)

set( EXTENSIONS
src/mulle-sde
)

file( GLOB PLUGIN_SCRIPTS
   "src/mulle-env/plugins/*.sh"
)


install( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


install( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-sde")

install( DIRECTORY ${EXTENSIONS}
   DESTINATION "share/mulle-sde/extensions"
   USE_SOURCE_PERMISSIONS
   PATTERN "*._DS_Store" EXCLUDE
   PATTERN "*.ignore" EXCLUDE
)

#
# this tries to fix the "mulle" plugin not properly added to mulle-env
# looks hacky, but cody said:
# The best practice for Homebrew packages is to use the Cellar path.
# You can get the exact path of your installed mulle-env using:
# brew --prefix mulle-env
#
IF( DEFINED ENV{HOMEBREW_CELLAR})
   execute_process(
     COMMAND brew --prefix mulle-env
     OUTPUT_VARIABLE MULLE_ENV_PREFIX
     OUTPUT_STRIP_TRAILING_WHITESPACE
   )
endif()

if( MULLE_ENV_PREFIX)
   set( PLUGIN_INSTALL_DIR "${MULLE_ENV_PREFIX}/libexec/mulle-env/plugins")
else()
   set( PLUGIN_INSTALL_DIR "share/mulle-env/plugins")
endif()

install( FILES ${PLUGIN_SCRIPTS}
         PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                    GROUP_EXECUTE GROUP_READ
                    WORLD_EXECUTE WORLD_READ
         DESTINATION "${PLUGIN_INSTALL_DIR}")

######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
