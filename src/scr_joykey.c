/*
 * xrickgs/src/scr_joykey.c
 */

#include "system.h"
#include "game.h"
#include "screens.h"

#include "draw.h"
#include "control.h"
#include "img.h"

#ifdef IIGS
segment "screen";
#pragma noroot
#endif

extern char joys_lz4;


/*
 * Display (J)oystick or (K)eyboard screen
 *
 * return: SCREEN_RUNNING, SCREEN_DONE, SCREEN_EXIT
 */
U8
screen_joykey(void)
{
	static U8 seq = 0;
	static U8 wait = 0;

	if (seq == 0) {
		sysvid_clearPalette();
		wait_vsync();
		PresentPalette();
		PresentSCB();
		draw_img(&joys_lz4);
		PresentFrameBuffer();
		wait_vsync();
		PresentPalette();
		PresentSCB();
		seq = 1;
	}

	switch (seq) {
	case 1:  /* wait */
		if (wait++ > 0x2) {
			seq = 2;
			wait = 0;
		}
		break;

	case 2:  /* wait */
		if (wait++ > 0x20) {
			seq = 99;
			wait = 0;
		}
	}

	if (control_status & CONTROL_EXIT)  /* check for exit request */
		return SCREEN_EXIT;

	#if 0
	if (seq == 99) {  /* we're done */
		sysvid_clear();
		sysvid_setGamePalette();
		sysvid_clearPalette();
		wait_vsync();
		PresentPalette();
		PresentSCB();
		PresentFrameBuffer();
		seq = 0;
		return SCREEN_DONE;
	}
	#endif

	return SCREEN_RUNNING;
}

/* eof */

