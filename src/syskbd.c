/*
 * xrick/src/syskbd.c
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

#ifndef IIGS
#include <SDL.h>
#endif

#include "system.h"

#ifdef IIGS
#pragma noroot
segment "system";
#endif

#ifdef IIGS
U8 syskbd_up = 'W';
U8 syskbd_down = 'S';
U8 syskbd_left = 'A';
U8 syskbd_right = 'D';
U8 syskbd_pause = 'P';
U8 syskbd_end = '2';
U8 syskbd_xtra = '1';
U8 syskbd_fire = ' ';
#else
U8 syskbd_up = SDLK_o;
U8 syskbd_down = SDLK_k;
U8 syskbd_left = SDLK_z;
U8 syskbd_right = SDLK_x;
U8 syskbd_pause = SDLK_p;
U8 syskbd_end = SDLK_e;
U8 syskbd_xtra = SDLK_ESCAPE;
U8 syskbd_fire = SDLK_SPACE;
#endif

/* eof */


