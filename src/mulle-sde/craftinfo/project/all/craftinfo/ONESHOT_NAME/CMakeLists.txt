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

file( GLOB BUILDINFO_DIRS
   mulle-make*
)

if( BUILDINFO_DIRS)
	foreach( DIR ${BUILDINFO_DIRS} )
	   install( DIRECTORY "${DIR}" DESTINATION "share/mulle-craft/<|ONESHOT_NAME|>"
	            USE_SOURCE_PERMISSIONS
	            PATTERN "*._DS_Store" EXCLUDE
	   )
	endforeach()
endif()

