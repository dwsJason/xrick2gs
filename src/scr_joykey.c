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

#define J_KEY 0x26
#define K_KEY 0x28

extern U16 bUseJoy; 

/*
 * Display (J)oystick or (K)eyboard screen
 *
 * return: SCREEN_RUNNING, SCREEN_DONE, SCREEN_EXIT
 */
U8
screen_joykey(void)
{
	static U16 seq = 0;
	static U16 wait = 0;

	U16 bChosen = 0;

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

	if (control_status & CONTROL_EXIT)  /* check for exit request */
		return SCREEN_EXIT;

	if (KeyArray[ J_KEY ])
	{
		// Choose JoyStick
		bUseJoy = 1;
		bChosen = 1;
	}

	if (KeyArray[ K_KEY ])
	{
		// Choose Keyboard
		bUseJoy = 0;
		bChosen = 1;
	}

	if (bChosen) {  /* we're done */
		sysvid_clear();
		sysvid_setGamePalette();
		sysvid_clearPalette();
		wait_vsync();
		PresentPalette();
		PresentSCB();
		PresentFrameBuffer();
		seq = 0;
		wait = 0;
		return SCREEN_DONE;
	}

	return SCREEN_RUNNING;
}

/* eof */
