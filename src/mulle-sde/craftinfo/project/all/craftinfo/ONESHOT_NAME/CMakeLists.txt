cmake_minimum_required( VERSION 3.0)

project( <|ONESHOT_NAME|> NONE)


# install scripts build scripts if any into "${DEPENDENCY_DIR}/bin"

file( GLOB SCRIPTS
   bin/*
)

file( GLOB BORING_FILES
   bin/*.example
   bin/*~
   bin/*.bak
   bin/*.old
)

foreach( BORING_FILE ${BORING_FILES} )
   list( REMOVE_ITEM SCRIPTS "${BORING_FILE}")
endforeach()

if( SCRIPTS)
	install( FILES "${SCRIPTS}" DESTINATION "bin"
	         PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
	                     GROUP_EXECUTE GROUP_READ
	                     WORLD_EXECUTE WORLD_READ
	)
endif()

# install craftinfos

file( GLOB DEFINITION_DIRS
   definition*
)

if( DEFINITION_DIRS)
	foreach( DIR ${DEFINITION_DIRS} )
	   install( DIRECTORY "${DIR}" DESTINATION "share/mulle-craft/<|ONESHOT_NAME|>"
	            USE_SOURCE_PERMISSIONS
	            PATTERN "*._DS_Store" EXCLUDE
	   )
	endforeach()
else()
   message( FATAL_ERROR "Remove craftinfo \"<|ONESHOT_NAME|>\" as it is empty with:\n   mulle-sourcetree remove craftinfo/<|ONESHOT_NAME|>\n   rm -rf craftinfo/<|ONESHOT_NAME|>")
endif()

