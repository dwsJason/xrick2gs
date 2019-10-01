/*
 * xrick/src/sysevt.c
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

/*
 * 20021010 SDLK_n replaced by SDLK_Fn because some non-US keyboards
 *          requires that SHIFT be pressed to input numbers.
 */

#ifndef IIGS
#include <SDL.h>
#endif

#include "system.h"
#include "config.h"
#include "game.h"
#include "debug.h"

#include "control.h"
#include "draw.h"

#define SYSJOY_RANGE 3280

#define SETBIT(x,b) x |= (b)
#define CLRBIT(x,b) x &= ~(b)

#ifndef IIGS
static SDL_Event event;
#endif

#ifdef IIGS
segment "system";
#pragma noroot

#define LARROW 0x3B
#define RARROW 0x3C
#define DARROW 0x3D
#define UARROW 0x3E

#define SPACEBAR 0x31

#define ESC 0x35
#define Z_KEY 0x06
#define Q_KEY 0x0C

#define A_KEY 0x00
#define S_KEY 0x01
#define D_KEY 0x02
#define W_KEY 0x0D
#define I_KEY 0x22
#define J_KEY 0x26
#define K_KEY 0x28
#define L_KEY 0x25

#define KEY_1 0x12
#define KEY_2 0x13
#define KEY_3 0x14
#define KEY_4 0x15
#define KEY_5 0x17
#define KEY_6 0x16
#define KEY_7 0x1A
#define KEY_8 0x1C
#define KEY_9 0x19
#define KEY_0 0x1D


// If the IIGs, we just automatically support all the things
void ReadPaddles();
extern U16 paddle0;
extern U16 paddle1;
extern U16 paddle_button0;
 
U16 bUseJoy = 0; 

#define TOLERANCE 48
#define JOY_LEFT  (128-TOLERANCE)
#define JOY_RIGHT (128+TOLERANCE)
#define JOY_UP    (128-TOLERANCE)
#define JOY_DOWN  (128+TOLERANCE)

int last_key7 = 0;
int last_key8 = 0;
int last_key9 = 0;

#endif

/*
 * Process an event
 */
static void
processEvent()
{
#ifdef IIGS
#if 0
	int x;

	for (x = 0; x < 128; ++x)
	{
		if (KeyArray[ x ])
		{
			printf("Key %d\n", x);
		}
	}
#endif
#if 0
	U8* pScreen = (U8*)0x400;
	int idx;

	while (1)
	{
		for (idx = 0; idx < 128; ++idx)
		{
			pScreen[idx] = KeyArray[idx];
		}
	}
#endif

	control_status = 0;

	if (bUseJoy)
	{
		ReadPaddles();

		if (paddle0 <= JOY_LEFT)
		{
			control_status |= CONTROL_LEFT;
			if (!(control_last & CONTROL_LEFT))
				control_last |= CONTROL_LEFT;
		}
		else
		{
			control_last &= ~CONTROL_LEFT;
		}
		if (paddle0 >= JOY_RIGHT)
		{
			control_status |= CONTROL_RIGHT;
			if (!(control_last & CONTROL_RIGHT))
				control_last |= CONTROL_RIGHT;
		}
		else
		{
			control_last &= ~CONTROL_RIGHT;
		}

		if (paddle1 <= JOY_UP)
		{
			control_status |= CONTROL_UP;
			if (!(control_last & CONTROL_UP))
				control_last |= CONTROL_UP;
		}
		else
		{
			control_last &= ~CONTROL_UP;
		}
		if (paddle1 >= JOY_DOWN)
		{
			control_status |= CONTROL_DOWN;
			if (!(control_last & CONTROL_DOWN))
				control_last |= CONTROL_DOWN;
		}
		else
		{
			control_last &= ~CONTROL_DOWN;
		}

		if (paddle_button0 >= 128)
		{
			control_status |= CONTROL_FIRE;
			if (!(control_last & CONTROL_FIRE))
			{
				control_last |= CONTROL_FIRE;
			}
		}
		else
		{
			control_last &= ~CONTROL_FIRE;
		}
	}
	else
	{
		// ADB Keyboard Driver
		if (KeyArray[ A_KEY ] || KeyArray[ J_KEY ])
		{
			control_status |= CONTROL_LEFT;
			if (!(control_last & CONTROL_LEFT))
			{
				control_last |= CONTROL_LEFT;
				KeyArray[ D_KEY ] = 0;
				KeyArray[ L_KEY ] = 0;
			}
		}
		else
		{
			control_last &= ~CONTROL_LEFT;
		}
		if (KeyArray[ D_KEY ] || KeyArray[ L_KEY ])
		{
			control_status |= CONTROL_RIGHT;
			if (!(control_last & CONTROL_RIGHT))
			{
				control_last |= CONTROL_RIGHT;
				KeyArray[ A_KEY ] = 0;
				KeyArray[ J_KEY ] = 0;
			}
		}
		else
		{
			control_last &= ~CONTROL_RIGHT;
		}
		if (KeyArray[ S_KEY ] || KeyArray[ K_KEY ])
		{
			control_status |= CONTROL_DOWN;
			if (!(control_last & CONTROL_DOWN))
			{
				control_last |= CONTROL_DOWN;
				KeyArray[ W_KEY ] = 0;
				KeyArray[ I_KEY ] = 0;
			}
		}
		else
		{
			control_last &= ~CONTROL_DOWN;
		}
		if (KeyArray[ W_KEY ] || KeyArray[ I_KEY ])
		{
			control_status |= CONTROL_UP;
			if (!(control_last & CONTROL_UP))
			{
				control_last |= CONTROL_UP;
				KeyArray[ S_KEY ] = 0;
				KeyArray[ K_KEY ] = 0;
			}
		}
		else
		{
			control_last &= ~CONTROL_UP;
		}
		if (KeyArray[ SPACEBAR ])
		{
			control_status |= CONTROL_FIRE;
			if (!(control_last & CONTROL_FIRE))
			{
				control_last |= CONTROL_FIRE;
			}
		}
		else
		{
			control_last &= ~CONTROL_FIRE;
		}
	}

	if (KeyArray[ ESC ])
	{
		control_status |= CONTROL_END;
		control_last |= CONTROL_END;
	}
	else
	{
		control_last &= ~CONTROL_END;
	}
	if (KeyArray[ Q_KEY ])
	{
		control_status |= CONTROL_EXIT;
		control_last   |= CONTROL_EXIT;
	}
	else
	{
		control_last &= ~CONTROL_EXIT;
	}

#ifdef ENABLE_CHEATS
	if (KeyArray[ KEY_7 ])
	{
		if (!last_key7)
		{
			last_key7 = 1;
			game_toggleCheat(1);
		}
	}
	else
	{
		last_key7 = 0;
	}
	if (KeyArray[ KEY_8 ])
	{
		if (!last_key8)
		{
			last_key8 = 1;
			game_toggleCheat(2);
		}
	}
	else
	{
		last_key8 = 0;
	}
	if (KeyArray[ KEY_9 ])
	{
		if (!last_key9)
		{
			last_key9 = 1;
			//game_toggleCheat(3);
			if (game_cheat2)
			{
				game_toggleCheat(2);
			}
			e_rick_gozombie();
		}
	}
	else
	{
		last_key9 = 0;
	}
#endif
#endif

#ifndef IIGS
	U16 key;
#ifdef ENABLE_FOCUS
	SDL_ActiveEvent *aevent;
#endif

  switch (event.type) {
  case SDL_KEYDOWN:
    key = event.key.keysym.sym;
    if (key == syskbd_up || key == SDLK_UP) {
      SETBIT(control_status, CONTROL_UP);
      control_last = CONTROL_UP;
    }
    else if (key == syskbd_down || key == SDLK_DOWN) {
      SETBIT(control_status, CONTROL_DOWN);
      control_last = CONTROL_DOWN;
    }
    else if (key == syskbd_left || key == SDLK_LEFT) {
      SETBIT(control_status, CONTROL_LEFT);
      control_last = CONTROL_LEFT;
    }
    else if (key == syskbd_right || key == SDLK_RIGHT) {
      SETBIT(control_status, CONTROL_RIGHT);
      control_last = CONTROL_RIGHT;
    }
    else if (key == syskbd_pause) {
      SETBIT(control_status, CONTROL_PAUSE);
      control_last = CONTROL_PAUSE;
    }
    else if (key == syskbd_end) {
      SETBIT(control_status, CONTROL_END);
      control_last = CONTROL_END;
    }
    else if (key == syskbd_xtra) {
      SETBIT(control_status, CONTROL_EXIT);
      control_last = CONTROL_EXIT;
    }
    else if (key == syskbd_fire) {
      SETBIT(control_status, CONTROL_FIRE);
      control_last = CONTROL_FIRE;
    }
    else if (key == SDLK_F1) {
      sysvid_toggleFullscreen();
    }
    else if (key == SDLK_F2) {
      sysvid_zoom(-1);
    }
    else if (key == SDLK_F3) {
      sysvid_zoom(+1);
    }
#ifdef ENABLE_SOUND
    else if (key == SDLK_F4) {
      syssnd_toggleMute();
    }
    else if (key == SDLK_F5) {
      syssnd_vol(-1);
    }
    else if (key == SDLK_F6) {
      syssnd_vol(+1);
    }
#endif
#ifdef ENABLE_CHEATS
    else if (key == SDLK_F7) {
      game_toggleCheat(1);
    }
    else if (key == SDLK_F8) {
      game_toggleCheat(2);
    }
    else if (key == SDLK_F9) {
      game_toggleCheat(3);
    }
#endif
    break;
  case SDL_KEYUP:
    key = event.key.keysym.sym;
    if (key == syskbd_up || key == SDLK_UP) {
      CLRBIT(control_status, CONTROL_UP);
      control_last = CONTROL_UP;
    }
    else if (key == syskbd_down || key == SDLK_DOWN) {
      CLRBIT(control_status, CONTROL_DOWN);
      control_last = CONTROL_DOWN;
    }
    else if (key == syskbd_left || key == SDLK_LEFT) {
      CLRBIT(control_status, CONTROL_LEFT);
      control_last = CONTROL_LEFT;
    }
    else if (key == syskbd_right || key == SDLK_RIGHT) {
      CLRBIT(control_status, CONTROL_RIGHT);
      control_last = CONTROL_RIGHT;
    }
    else if (key == syskbd_pause) {
      CLRBIT(control_status, CONTROL_PAUSE);
      control_last = CONTROL_PAUSE;
    }
    else if (key == syskbd_end) {
      CLRBIT(control_status, CONTROL_END);
      control_last = CONTROL_END;
    }
    else if (key == syskbd_xtra) {
      CLRBIT(control_status, CONTROL_EXIT);
      control_last = CONTROL_EXIT;
    }
    else if (key == syskbd_fire) {
      CLRBIT(control_status, CONTROL_FIRE);
      control_last = CONTROL_FIRE;
    }
    break;
  case SDL_QUIT:
    /* player tries to close the window -- this is the same as pressing ESC */
    SETBIT(control_status, CONTROL_EXIT);
    control_last = CONTROL_EXIT;
    break;
#ifdef ENABLE_FOCUS
  case SDL_ACTIVEEVENT: {
    aevent = (SDL_ActiveEvent *)&event;
    IFDEBUG_EVENTS(
      printf("xrick/events: active %x %x\n", aevent->gain, aevent->state);
      );
    if (aevent->gain == 1)
      control_active = TRUE;
    else
      control_active = FALSE;
    }
  break;
#endif
#ifdef ENABLE_JOYSTICK
  case SDL_JOYAXISMOTION:
    IFDEBUG_EVENTS(sys_printf("xrick/events: joystick\n"););
    if (event.jaxis.axis == 0) {  /* left-right */
      if (event.jaxis.value < -SYSJOY_RANGE) {  /* left */
	SETBIT(control_status, CONTROL_LEFT);
	CLRBIT(control_status, CONTROL_RIGHT);
      }
      else if (event.jaxis.value > SYSJOY_RANGE) {  /* right */
	SETBIT(control_status, CONTROL_RIGHT);
	CLRBIT(control_status, CONTROL_LEFT);
      }
      else {  /* center */
	CLRBIT(control_status, CONTROL_RIGHT);
	CLRBIT(control_status, CONTROL_LEFT);
      }
    }
    if (event.jaxis.axis == 1) {  /* up-down */
      if (event.jaxis.value < -SYSJOY_RANGE) {  /* up */
	SETBIT(control_status, CONTROL_UP);
	CLRBIT(control_status, CONTROL_DOWN);
      }
      else if (event.jaxis.value > SYSJOY_RANGE) {  /* down */
	SETBIT(control_status, CONTROL_DOWN);
	CLRBIT(control_status, CONTROL_UP);
      }
      else {  /* center */
	CLRBIT(control_status, CONTROL_DOWN);
	CLRBIT(control_status, CONTROL_UP);
      }
    }
    break;
  case SDL_JOYBUTTONDOWN:
    SETBIT(control_status, CONTROL_FIRE);
    break;
  case SDL_JOYBUTTONUP:
    CLRBIT(control_status, CONTROL_FIRE);
    break;
#endif
  default:
    break;
  }
#endif //IIGS
}

/*
 * Process events, if any, then return
 */
void
sysevt_poll(void)
{
#ifndef IIGS
  while (SDL_PollEvent(&event))
#endif
    processEvent();
}

/*
 * Wait for an event, then process it and return
 */
void
sysevt_wait(void)
{
#ifdef IIGS
	printf("sysevt_wait\n");
#endif
#ifndef IIGS
  SDL_WaitEvent(&event);
  processEvent();
#endif
}

/* eof */

