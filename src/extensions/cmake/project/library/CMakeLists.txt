cmake_minimum_required( VERSION 3.0)

project( <|PROJECT_NAME|> <|PROJECT_LANGUAGE|>)

#
# Figure out where .mulle-sde might be (optional)
#
set( MULLE_VIRTUAL_ROOT "\$ENV{MULLE_VIRTUAL_ROOT}")
if( NOT MULLE_VIRTUAL_ROOT)
   set( MULLE_VIRTUAL_ROOT "\${PROJECT_SOURCE_DIR}")
endif()
message( STATUS "MULLE_VIRTUAL_ROOT is \${MULLE_VIRTUAL_ROOT}")

###

set( <|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY ON)

include( CMakeDependenciesAndLibraries.txt)
include( CMakeHeadersAndSources.txt)

###

include_directories( ${INCLUDE_DIRS})

set( PUBLIC_HEADERS
${PUBLIC_HEADERS}
"CMakeDependenciesAndLibraries.txt"
"_CMakeDependencies.txt"
"_CMakeLibraries.txt"
)


add_library( "<|PROJECT_NAME|>"
${SOURCES}
${PUBLIC_HEADERS}
${PRIVATE_HEADERS}
CMakeLists.txt
CMakeHeadersAndSources.txt
)

install( TARGETS "<|PROJECT_NAME|>" DESTINATION "lib")
install( FILES ${PUBLIC_HEADERS}  DESTINATION "include/<|PROJECT_NAME|>")
install( FILES ${PRIVATE_HEADERS} DESTINATION "include/<|PROJECT_NAME|>/private")