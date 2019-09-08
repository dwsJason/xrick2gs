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


#include <Memory.h>
extern char credits_lz4;

/*
 * main
 */
int
main(int argc, char *argv[])
{
	printf("Hello from xrick IIgs\n");
//	tHandle = (U32*)NewHandle(0x10000, userid(), 0xC014, 0); 
//	LZ4_Unpack((char*)*tHandle, &samerica_lz4);

//	NTPprepare((void*)*tHandle);
//	NTPplay(1);
	// Keep the Screen on
	*VIDEO_REGISTER|=0xC0;
	// Blank the screen, so you don't see trash in the Frame Buffer
	memset((void*)0xE19D00, (int)0, (size_t)200);
	memset((void*)0xE19E00, (int)0, (size_t)32);
	// Display the Credits
	LZ4_Unpack((char*)(0xE12000), &credits_lz4);
//	printf("%08x\n", &img_splash_lz4 );
//	printf("%08x\n", IMG_SPLASH );

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
