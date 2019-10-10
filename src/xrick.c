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

#include <orca.h>

/* According to the ORCA/C Documentation
 
    The Tool Locater, Memory Manager, Loader and
	SANE are started by all C programs. 

*/

void scr_credit();
void IIGShutdown();
/*
 * main
 */
int
main(int argc, char *argv[])
{
	atexit( IIGShutdown );	// Make Sure cleanup stuff is done

	// Get the credit screen up ASAP
	scr_credit();

	printf("Hello from xrick IIgs\n");

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
