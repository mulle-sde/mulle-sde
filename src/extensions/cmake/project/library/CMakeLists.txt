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

set( <|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY ON)

include( CMakeDependenciesAndLibraries.txt)
include( CMakeHeadersAndSources.txt)


include_directories( ${INCLUDE_DIRS})

set( PUBLIC_HEADERS
${PUBLIC_HEADERS}
"CMakeDependenciesAndLibraries.txt"
"_CMakeDependencies.txt"
"_CMakeLibraries.txt"
)

### Library

add_library( "<|PROJECT_NAME|>"
${SOURCES}
${PUBLIC_HEADERS}
${PRIVATE_HEADERS}
CMakeLists.txt
CMakeHeadersAndSources.txt
)

if( BUILD_SHARED_LIBS)
   target_link_libraries( <|PROJECT_NAME|>
${C_DEPENDENCIES_LIBRARIES}
${OS_SPECIFIC_LIBRARIES}
)
endif()

### Install

install( TARGETS "<|PROJECT_NAME|>" DESTINATION "lib")
install( FILES ${PUBLIC_HEADERS}  DESTINATION "include/<|PROJECT_NAME|>")
install( FILES ${PRIVATE_HEADERS} DESTINATION "include/<|PROJECT_NAME|>/private")
