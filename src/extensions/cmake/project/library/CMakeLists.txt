cmake_minimum_required( VERSION 3.0)

project( <|PROJECT_NAME|> <|PROJECT_UPCASE_LANGUAGE|>)


### mulle-sde environment

set( MULLE_VIRTUAL_ROOT "$ENV{MULLE_VIRTUAL_ROOT}")
if( NOT MULLE_VIRTUAL_ROOT)
   set( MULLE_VIRTUAL_ROOT "${PROJECT_SOURCE_DIR}")
endif()
set( DEPENDENCIES_DIR "${MULLE_VIRTUAL_ROOT}/dependencies")
set( ADDICTIONS_DIR "${MULLE_VIRTUAL_ROOT}/addictions")

https://github.com/madler/zlib/archive/v1.2.11.tar.gz
include_directories( BEFORE SYSTEM
${DEPENDENCIES_DIR}/include
${ADDICTIONS_DIR}/include
)
set( CMAKE_LIBRARY_PATH "${DEPENDENCIES_DIR}/lib"
"${ADDICTIONS_DIR}/lib"
${CMAKE_LIBRARY_PATH}
)
set( CMAKE_FRAMEWORK_PATH "${DEPENDENCIES_DIR}/Frameworks"
"${ADDICTIONS_DIR}/Frameworks"
${CMAKE_FRAMEWORK_PATH}
)


### Files

set( <|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY ON)

include( CMakeDependenciesAndLibraries.cmake)
include( CMakeHeadersAndSources.cmake)


include_directories( ${INCLUDE_DIRS})

set( PUBLIC_HEADERS
${PUBLIC_HEADERS}
"CMakeDependenciesAndLibraries.cmake"
"_CMakeDependencies.cmake"
"_CMakeLibraries.cmake"
)

### Library

add_library( "<|PROJECT_NAME|>"
${SOURCES}
${PUBLIC_HEADERS}
${PRIVATE_HEADERS}
CMakeLists.txt
CMakeHeadersAndSources.cmake
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
