cmake_minimum_required( VERSION 3.0)

project( <|ONESHOT_NAME|> NONE)

file( GLOB BUILDINFO_DIRS
   <|ONESHOT_NAME|>*
)

foreach( DIR ${BUILDINFO_DIRS} )
   install( DIRECTORY "${DIR}" DESTINATION "share/mulle-craft")
endforeach()
