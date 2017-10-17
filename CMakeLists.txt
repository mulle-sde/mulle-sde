cmake_minimum_required( VERSION 3.0)

# use C, because otherwise a CXX compiler is required
project( mulle-sde C)


include( CMakeSourcesAndHeaders.txt)


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")

