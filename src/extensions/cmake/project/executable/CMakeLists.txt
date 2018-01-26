cmake_minimum_required( VERSION 3.0)

project( <|PROJECT_NAME|> <|PROJECT_LANGUAGE|>)


### mulle-sde environment

set( MULLE_VIRTUAL_ROOT "$ENV{MULLE_VIRTUAL_ROOT}")
if( NOT MULLE_VIRTUAL_ROOT)
   set( MULLE_VIRTUAL_ROOT "${PROJECT_SOURCE_DIR}")
endif()
include_directories( BEFORE SYSTEM
${MULLE_VIRTUAL_ROOT}/dependencies/include
${MULLE_VIRTUAL_ROOT}/addictions/include
)
set( CMAKE_LIBRARY_PATH "${MULLE_VIRTUAL_ROOT}/dependencies/lib"
"${MULLE_VIRTUAL_ROOT}/addictions/lib"
${CMAKE_LIBRARY_PATH}
)
set( CMAKE_FRAMEWORK_PATH "${MULLE_VIRTUAL_ROOT}/dependencies/Frameworks"
"${MULLE_VIRTUAL_ROOT}/addictions/Frameworks"
${CMAKE_FRAMEWORK_PATH}
)


### Files

include( CMakeHeadersAndSources.txt)
include( CMakeDependenciesAndLibraries.txt)

### Executable

add_executable( <|PROJECT_NAME|>
${SOURCES}
${PUBLIC_HEADERS}
${PRIVATE_HEADERS}
CMakeLists.txt
CMakeHeadersAndSources.txt
CMakeDependenciesAndLibraries.txt
)


target_link_libraries( <|PROJECT_NAME|>
${C_DEPENDENCIES_LIBRARIES}
${OS_SPECIFIC_LIBRARIES}
)


### Install

install( TARGETS <|PROJECT_NAME|> DESTINATION "bin")


#
# Output message of a day to locate output.
# But if create-build-motd doesn't exist, it's no biggy
#
add_custom_target( __motd__ ALL
   COMMAND [ ! -x "${MULLE_VIRTUAL_ROOT}/.mulle-sde/bin/create-build-motd" ] || "${MULLE_VIRTUAL_ROOT}/.mulle-sde/bin/create-build-motd" "executable" "${CMAKE_BINARY_DIR}" "<|PROJECT_NAME|>"
   COMMENT "Creating a motd file for mulle-craft"
)
add_dependencies( __motd__ <|PROJECT_NAME|>)
