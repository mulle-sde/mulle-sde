cmake_minimum_required( VERSION 3.13...99.99)

project( mulle-sde VERSION 3.5.1 LANGUAGES NONE)

execute_process( COMMAND ./mulle-sde version
                 WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_SDE_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_SDE_VERSION is ${MULLE_SDE_VERSION} according to mulle-sde")


set( PROJECT_VERSION "${MULLE_SDE_VERSION}")


set( SCRIPTS
mulle-sde
mulle-sde-cd
mulle-sde-sandbox.linux
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


# mulle-env fatal error: No plugin "mulle" found in
# "/opt/homebrew/Cellar/mulle-bashfunctions/6.5.1/share/mulle-env/plugins
# /usr/local/share/mulle-env/plugins
# /usr/share/mulle-env/plugins
# /opt/homebrew/Cellar/mulle-env/5.3.3/libexec/mulle-env/plugins".

# if we were to install under homebrew, get homebrew prefix, though quite frankly
# probably useless. Also we don't use cmake in homebrew currently, everything
# is running through bin/installer
#
#IF( DEFINED ENV{HOMEBREW_CELLAR})
#   execute_process(
#     COMMAND brew --prefix
#     OUTPUT_VARIABLE MULLE_BREW_PREFIX
#     OUTPUT_STRIP_TRAILING_WHITESPACE
#   )
#endif()
#
#if( MULLE_BREW_PREFIX)
#   set( PLUGIN_INSTALL_DIR "${MULLE_BREW_PREFIX}/share/mulle-env/plugins")
#else()
#   set( PLUGIN_INSTALL_DIR "/usr/local/share/mulle-env/plugins")
#endif()
#
#install( FILES ${PLUGIN_SCRIPTS}
#         PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
#                    GROUP_EXECUTE GROUP_READ
#                    WORLD_EXECUTE WORLD_READ
#         DESTINATION "${PLUGIN_INSTALL_DIR}")
#
######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)
