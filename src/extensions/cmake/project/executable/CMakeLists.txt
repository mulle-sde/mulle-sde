cmake_minimum_required( VERSION 3.0)

project( <|PROJECT_NAME|> <|PROJECT_LANGUAGE|>)

#
# Figure out where .mulle-sde might be (optional)
#
set( MULLE_VIRTUAL_ROOT "$ENV{MULLE_VIRTUAL_ROOT}")
if( NOT MULLE_VIRTUAL_ROOT)
   set( MULLE_VIRTUAL_ROOT "${PROJECT_SOURCE_DIR}")
endif()
message( STATUS "MULLE_VIRTUAL_ROOT is ${MULLE_VIRTUAL_ROOT}")

###

include( CMakeHeadersAndSources.txt)
include( CMakeDependenciesAndLibraries.txt)

###



add_executable( <|PROJECT_NAME|>
${SOURCES}
${PUBLIC_HEADERS}
${PRIVATE_HEADERS}
CMakeLists.txt
CMakeHeadersAndSources.txt
CMakeDependenciesAndLibraries.txt
)


target_link_libraries( <|PROJECT_NAME|>
${LIBRARIES}
)

###


install( TARGETS <|PROJECT_NAME|> DESTINATION "bin")


#
# output message of a day to locate output
# but if create-build-motd doesn't exist, it's no biggy
#
add_custom_target( __motd__ ALL
   COMMAND [ ! -x "\${MULLE_VIRTUAL_ROOT}/.mulle-sde/bin/create-build-motd" ] \
             || "\${MULLE_VIRTUAL_ROOT}/.mulle-sde/bin/create-build-motd" \
               "executable" "\${CMAKE_BINARY_DIR}" "<|PROJECT_NAME|>"
   COMMENT "Creating a motd file for mulle-craft" )

add_dependencies( __motd__ <|PROJECT_NAME|>)
