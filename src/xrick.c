/*
 * xrick/src/xrick.c
 *
 * Copyright (C) 1998-2002 BigOrno (bigorno@bigorno.net). All rights reserved.
 *
 * The use and distribution terms for this software are contained in the file
 * named README, which can be found in the root of this distribution. By
 * using this software in any fashion, you are agreeing to be bound by the
 * terms of this license.
 *
 * You must not remove this notice, or any other, from this software.
 */

#include "system.h"
#include "game.h"

#ifndef IIGS
#include <SDL.h>
#endif

//extern void waitkey();
//extern void fbuffer();

/*
 * main
 */
int
main(int argc, char *argv[])
{
	printf("Hello from xrick IIgs\n");
//	waitkey();
//	fbuffer();

	#if 0
handle hndl;                            /* "generic" handle */
/* Create new member array of minimum size. */
hndl = NewHandle(1024L, myID, 0xC010, NULL);
if (toolerror()) {
   HandleError(toolerror(), memryErr);
   return FALSE;
   }

//   PushLong  #0                   ;/* Ask Shadowing Screen ($8000 bytes from $01/2000)*/
//           PushLong  #$8000
//            PushWord  myID
//            PushWord  #%11000000_00000011
//            PushLong  #$012000
//            _NewHandle
//            PLA
//            PLA
   #endif


	sys_init(argc, argv);
	if (sysarg_args_data)
		data_setpath(sysarg_args_data);
	else
		data_setpath("data.zip");
	game_run();
	data_closepath();
	sys_shutdown();
	return 0;
}

/* eof */
