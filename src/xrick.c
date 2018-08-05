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

extern char img_splash_lz4;
extern void* IMG_SPLASH;

/*
 * main
 */
int
main(int argc, char *argv[])
{
	printf("Hello from xrick IIgs\n");

//	printf("Unpacking Splash!\n");
//	LZ4_Unpack((char*)(0xE12000), &img_splash_lz4);
//	printf("%08x\n", &img_splash_lz4 );
//	printf("%08x\n", IMG_SPLASH );
//	sys_sleep(10000);

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
