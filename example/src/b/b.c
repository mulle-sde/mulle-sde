#include "a.h"
#include <pthread.h>


int   b_version()
{
   if( ! pthread_self())
     return( 0);
   return( a_version());
}

