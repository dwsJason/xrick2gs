/*
#--------------------------------------------------------
# $File: xrick2spr.c,v $          
#--------------------------------------------------------
*/


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "bctypes.h"
#include "xrick2spr.h"
#include "rawdata.h"

static void _usage()
{
	printf("xrick2spr v%s\n\n", VERSION);
	printf("Usage:  xrick2spr\n"
		   "Written by Jason Andersen\n"
		   "Copyright (c) 2018 Jason Andersen.\n"
		   "Unauthorized use prohibited\n");

		   exit(1);

} // usage	


//
// Parse command line options
//
int main(int argc, char **argv)
{
	// Check Arguments
	while (--argc > 0 && (*++argv)[0] == '-')
	{
		*argv+=1;
		 
		if (strcmp("v", *argv) == 0)
		{
			printf("xrick2spr v%s\n", VERSION);
			exit(0);
		}
		
		*argv+= strlen(*argv); // skip rest of string
					
	}

	if (argc) _usage();

	RAWDATA* pData = loadRaw("sprites_data.gs");

	if (pData)
	{
		// each frame 32 * 21 pixels, 0xd6 frames

		printf("%d %d\n", 16*21*0xd6, (int)pData->size );

	}


	printf("\nxrick2spr - Processing complete.\n");

	exit(0);

} // main	


// eof - xrick2png.c

