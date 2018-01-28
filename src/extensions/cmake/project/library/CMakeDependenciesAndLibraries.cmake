if( NOT __<|PROJECT_UPCASE_IDENTIFIER|>_CMAKE_DEPENDENCIES_AND_LIBRARIES_TXT__)
   set( __<|PROJECT_UPCASE_IDENTIFIER|>_CMAKE_DEPENDENCIES_AND_LIBRARIES_TXT__ ON)

   message( STATUS "# Include <|PROJECT_NAME|> CMakeDependenciesAndLibraries.txt")

   #
   # Put your find_library() statements here to import other libraries
   #
   # Add OS specific dependencies to OS_SPECIFIC_LIBRARIES
   # Add all other dependencies (rest) to C_DEPENDENCIES_LIBRARIES

   #
   # === MULLE-SDE START ===

   # `mulle-sde update` will generate these files

   include( _CMakeDependencies.cmake)
   include( _CMakeLibraries.cmake)

   # === MULLE-SDE END ===
   #

   # For the benefit of users of your library, provide the find_library
   # statement to find your library and add it to C_DEPENDENCY_LIBRARIES and
   # C_DEPENDENCY_NAMES
   #
   if( NOT <|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY)
      find_library( <|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY NAMES <|PROJECT_NAME|>)
      message(STATUS "<|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY is ${<|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY}")
      set( C_DEPENDENCY_LIBRARIES
         ${<|PROJECT_UPCASE_IDENTIFIER|>_LIBRARY}
         ${C_DEPENDENCY_LIBRARIES}
         CACHE INTERNAL "need to cache this"
      )
      set( C_DEPENDENCY_NAMES
         <|PROJECT_NAME|>
         ${C_DEPENDENCY_NAMES}
         CACHE INTERNAL "need to cache this too"
      )
   endif()

   #
   # For benefit of Windows
   #
   if( MSVC)
      set( <|PROJECT_UPCASE_IDENTIFIER|>_DEFINITIONS ${UPCASE_MULLE_C_LIBRARY_IDENTIFIER}_DEFINITIONS})
   endif()
endif()