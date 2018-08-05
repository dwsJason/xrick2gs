/*
 * xrick/src/sysvid.c
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

#ifdef IIGS
#pragma noroot
#endif

#include <stdlib.h> /* malloc */

#ifndef IIGS
#include <SDL.h>
#endif

#include "system.h"
#include "game.h"
#include "img.h"
#include "debug.h"

#ifdef IIGS
#include <GSOS.h>
#include <Memory.h>
#include <Orca.h>
#include <Misctool.h>
#endif

#ifdef __MSVC__
#include <memory.h> /* memset */
#endif

segment "system";

U8 *sysvid_fb; /* frame buffer */
rect_t SCREENRECT = {0, 0, SYSVID_WIDTH, SYSVID_HEIGHT, NULL}; /* whole fb */

#ifndef IIGS
static SDL_Color palette[256];
static SDL_Surface *screen;
#endif

#ifdef IIGS
volatile char *VIDEO_REGISTER = (char*)0xC029;
volatile char *SHADOW_REGISTER = (char*)0xC035;
#endif

static U32 videoFlags;

static U8 zoom = SYSVID_ZOOM; /* actual zoom level */
static U8 szoom = 0;  /* saved zoom level */
static U8 fszoom = 0;  /* fullscreen zoom level */

#include "img_icon.e"

/*
 * color tables
 */

#ifdef GFXPC
static U8 RED[] = { 0x00, 0x50, 0xf0, 0xf0, 0x00, 0x50, 0xf0, 0xf0 };
static U8 GREEN[] = { 0x00, 0xf8, 0x50, 0xf8, 0x00, 0xf8, 0x50, 0xf8 };
static U8 BLUE[] = { 0x00, 0x50, 0x50, 0x50, 0x00, 0xf8, 0xf8, 0xf8 };
#endif
#if defined(GFXST) || defined(GFXGS)
static U8 RED[] = { 0x00, 0xd8, 0xb0, 0xf8,
                    0x20, 0x00, 0x00, 0x20,
                    0x48, 0x48, 0x90, 0xd8,
                    0x48, 0x68, 0x90, 0xb0,
                    /* cheat colors */
                    0x50, 0xe0, 0xc8, 0xf8,
                    0x68, 0x50, 0x50, 0x68,
                    0x80, 0x80, 0xb0, 0xe0,
                    0x80, 0x98, 0xb0, 0xc8
};
static U8 GREEN[] = { 0x00, 0x00, 0x6c, 0x90,
                      0x24, 0x48, 0x6c, 0x48,
                      0x6c, 0x24, 0x48, 0x6c,
                      0x48, 0x6c, 0x90, 0xb4,
		      /* cheat colors */
                      0x54, 0x54, 0x9c, 0xb4,
                      0x6c, 0x84, 0x9c, 0x84,
                      0x9c, 0x6c, 0x84, 0x9c,
                      0x84, 0x9c, 0xb4, 0xcc
};
static U8 BLUE[] = { 0x00, 0x00, 0x68, 0x68,
                     0x20, 0xb0, 0xd8, 0x00,
                     0x20, 0x00, 0x00, 0x00,
                     0x48, 0x68, 0x90, 0xb0,
		     /* cheat colors */
                     0x50, 0x50, 0x98, 0x98,
                     0x68, 0xc8, 0xe0, 0x50,
                     0x68, 0x50, 0x50, 0x50,
                     0x80, 0x98, 0xb0, 0xc8};
#endif

/*
 * Initialize screen
 */
#ifndef IIGS
static
SDL_Surface *initScreen(U16 w, U16 h, U8 bpp, U32 flags)
{
  return SDL_SetVideoMode(w, h, bpp, flags);
}
#endif

void
sysvid_setPalette(img_color_t *pal, U16 n)
{
#ifndef IIGS
  U16 i;

  for (i = 0; i < n; i++) {
    palette[i].r = pal[i].r;
    palette[i].g = pal[i].g;
    palette[i].b = pal[i].b;
  }
  SDL_SetColors(screen, (SDL_Color *)&palette, 0, n);
#endif
}

void
sysvid_restorePalette()
{
#ifndef IIGS
  SDL_SetColors(screen, (SDL_Color *)&palette, 0, 256);
#endif
}

void
sysvid_setGamePalette()
{
  U8 i;
  img_color_t pal[256];

  for (i = 0; i < 32; ++i) {
    pal[i].r = RED[i];
    pal[i].g = GREEN[i];
    pal[i].b = BLUE[i];
  }
  sysvid_setPalette(pal, 32);
}

/*
 * Initialize video modes
 */
void
sysvid_chkvm(void)
{
#ifndef IIGS
  SDL_Rect **modes;
  U8 i, mode = 0;

  IFDEBUG_VIDEO(sys_printf("xrick/video: checking video modes\n"););

  modes = SDL_ListModes(NULL, videoFlags|SDL_FULLSCREEN);

  if (modes == (SDL_Rect **)0)
    sys_panic("xrick/video: SDL can not find an appropriate video mode\n");

  if (modes == (SDL_Rect **)-1) {
    /* can do what you want, everything is possible */
    IFDEBUG_VIDEO(sys_printf("xrick/video: SDL says any video mode is OK\n"););
    fszoom = 1;
  }
  else {
    IFDEBUG_VIDEO(sys_printf("xrick/video: SDL says, use these modes:\n"););
    for (i = 0; modes[i]; i++) {
      IFDEBUG_VIDEO(sys_printf("  %dx%d\n", modes[i]->w, modes[i]->h););
      if (modes[i]->w <= modes[mode]->w && modes[i]->w >= SYSVID_WIDTH &&
	  modes[i]->h * SYSVID_WIDTH >= modes[i]->w * SYSVID_HEIGHT) {
	mode = i;
	fszoom = modes[mode]->w / SYSVID_WIDTH;
      }
    }
    if (fszoom != 0) {
      IFDEBUG_VIDEO(
        sys_printf("xrick/video: fullscreen at %dx%d w/zoom=%d\n",
		   modes[mode]->w, modes[mode]->h, fszoom);
	);
    }
    else {
      IFDEBUG_VIDEO(
        sys_printf("xrick/video: can not compute fullscreen zoom, use 1\n");
	);
      fszoom = 1;
    }
  }
#endif
}

/*
 * Initialise video
 */
void
sysvid_init(void)
{
#ifdef IIGS
	handle hndl;   // "generic memory handle"

//   PushLong  #0                   ;/* Ask Shadowing Screen ($8000 bytes from $01/2000)*/
//           PushLong  #$8000
//            PushWord  myID
//            PushWord  #%11000000_00000011
//            PushLong  #$012000
//            _NewHandle
//            PLA
//            PLA

	// Allocate Bank 01 memory  + 4K before and after (25 lines pre flow)
	// $012000-$019BFF pixel data
	// $019D00-$019DC7 SCB data
	// $019E00-$019FFF Clut data
	// $900 bytes afer, (14 lines buffer on the bottom, which will wreck SCB+CLUT
	//
	printf("Allocate Bank $01 memory\n");
	hndl = NewHandle(0x9600, userid(), 0xC003, (pointer) 0x011000);
	if (toolerror())
	{
		printf("Unable to allocate backpage at 0x012000\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);

	}
	printf("SUCCESS\n");

	// Allocate Bank E1 memory - Actual Video memory
	printf("Allocate Bank $E1 memory\n");
	hndl = NewHandle(0x8000, userid(), 0xC003, (pointer) 0xE12000);
	if (toolerror())
	{
		printf("Unable to allocate display buffer at 0xE12000\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);
	}
	printf("SUCCESS\n");

	// Allocate Some Direct Page memory
	//directPage = NewHandle( 0x200, userid(), 0xC005, 0 );
	//BlitFieldHndl   = NewHandle(0x10000, userid(), 0xC014, 0);
	sysvid_fb = (U8*)0x12000;

	// SHR ON
	*VIDEO_REGISTER|=0xC0;

	// ENABLE Shadowing of SHR
	*SHADOW_REGISTER&=~0x08; // Shadow Enable


#endif
#ifndef IIGS
  SDL_Surface *s;
  U8 *mask, tpix;
  U32 len, i;

  IFDEBUG_VIDEO(printf("xrick/video: start\n"););

  /* SDL */
  if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_TIMER) < 0)
    sys_panic("xrick/video: could not init SDL\n");

  /* various WM stuff */
  SDL_WM_SetCaption("xrick", "xrick");
  SDL_ShowCursor(SDL_DISABLE);
  s = SDL_CreateRGBSurfaceFrom(IMG_ICON->pixels, IMG_ICON->w, IMG_ICON->h, 8, IMG_ICON->w, 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff);
  SDL_SetColors(s, (SDL_Color *)IMG_ICON->colors, 0, IMG_ICON->ncolors);

  tpix = *(IMG_ICON->pixels);
  IFDEBUG_VIDEO(
    sys_printf("xrick/video: icon is %dx%d\n",
	       IMG_ICON->w, IMG_ICON->h);
    sys_printf("xrick/video: icon transp. color is #%d (%d,%d,%d)\n", tpix,
	       IMG_ICON->colors[tpix].r,
	       IMG_ICON->colors[tpix].g,
	       IMG_ICON->colors[tpix].b);
    );
	/*

	* old dirty stuff to implement transparency. SetColorKey does it
	* on Windows w/out problems. Linux? FIXME!

  len = IMG_ICON->w * IMG_ICON->h;
  mask = (U8 *)malloc(len/8);
  memset(mask, 0, len/8);
  for (i = 0; i < len; i++)
    if (IMG_ICON->pixels[i] != tpix) mask[i/8] |= (0x80 >> (i%8));
	*/
  /*
   * FIXME
   * Setting a mask produces strange results depending on the
   * Window Manager. On fvwm2 it is shifted to the right ...
   */
  /*SDL_WM_SetIcon(s, mask);*/
	SDL_SetColorKey(s,
                    SDL_SRCCOLORKEY,
                    SDL_MapRGB(s->format,IMG_ICON->colors[tpix].r,IMG_ICON->colors[tpix].g,IMG_ICON->colors[tpix].b));

  SDL_WM_SetIcon(s, NULL);

  /* video modes and screen */
  videoFlags = SDL_HWSURFACE|SDL_HWPALETTE;
  sysvid_chkvm();  /* check video modes */
  if (sysarg_args_zoom)
    zoom = sysarg_args_zoom;
  if (sysarg_args_fullscreen) {
    videoFlags |= SDL_FULLSCREEN;
    szoom = zoom;
    zoom = fszoom;
  }
  screen = initScreen(SYSVID_WIDTH * zoom,
		      SYSVID_HEIGHT * zoom,
		      8, videoFlags);

  /*
   * create v_ frame buffer
   */
  sysvid_fb = malloc(SYSVID_WIDTH * SYSVID_HEIGHT);
  if (!sysvid_fb)
    sys_panic("xrick/video: sysvid_fb malloc failed\n");

  IFDEBUG_VIDEO(printf("xrick/video: ready\n"););
#endif
}

/*
 * Shutdown video
 */
void
sysvid_shutdown(void)
{
#ifndef IIGS
  free(sysvid_fb);
  sysvid_fb = NULL;

  SDL_Quit();
#endif
}

/*
 * Update screen
 * NOTE errors processing ?
 */
void
sysvid_update(rect_t *rects)
{
#ifndef IIGS
  static SDL_Rect area;
  U16 x, y, xz, yz;
  U8 *p, *q, *p0, *q0;

  if (rects == NULL)
    return;

  if (SDL_LockSurface(screen) == -1)
    sys_panic("xrick/panic: SDL_LockSurface failed\n");

  while (rects) {
    p0 = sysvid_fb;
    p0 += rects->x + rects->y * SYSVID_WIDTH;
    q0 = (U8 *)screen->pixels;
    q0 += (rects->x + rects->y * SYSVID_WIDTH * zoom) * zoom;

    for (y = rects->y; y < rects->y + rects->height; y++) {
      for (yz = 0; yz < zoom; yz++) {
	p = p0;
	q = q0;
	for (x = rects->x; x < rects->x + rects->width; x++) {
	  for (xz = 0; xz < zoom; xz++) {
	    *q = *p;
	    q++;
	  }
	  p++;
	}
	q0 += SYSVID_WIDTH * zoom;
      }
      p0 += SYSVID_WIDTH;
    }

    IFDEBUG_VIDEO2(
    for (y = rects->y; y < rects->y + rects->height; y++)
      for (yz = 0; yz < zoom; yz++) {
	p = (U8 *)screen->pixels + rects->x * zoom + (y * zoom + yz) * SYSVID_WIDTH * zoom;
	*p = 0x01;
	*(p + rects->width * zoom - 1) = 0x01;
      }

    for (x = rects->x; x < rects->x + rects->width; x++)
      for (xz = 0; xz < zoom; xz++) {
	p = (U8 *)screen->pixels + x * zoom + xz + rects->y * zoom * SYSVID_WIDTH * zoom;
	*p = 0x01;
	*(p + ((rects->height * zoom - 1) * zoom) * SYSVID_WIDTH) = 0x01;
      }
    );

    area.x = rects->x * zoom;
    area.y = rects->y * zoom;
    area.h = rects->height * zoom;
    area.w = rects->width * zoom;
    SDL_UpdateRects(screen, 1, &area);

    rects = rects->next;
  }

  SDL_UnlockSurface(screen);
#endif
}


/*
 * Clear screen
 * (077C)
 */
void
sysvid_clear(void)
{
#ifndef IIGS
  memset(sysvid_fb, 0, SYSVID_WIDTH * SYSVID_HEIGHT);
#else
  size_t length = SYSVID_WIDTH /2 * SYSVID_HEIGHT;
  //printf("sysvid_clear: target = %08p\n", sysvid_fb);
  //printf("sysvid_clear: length = %08p\n", length);
  //sys_sleep(10000);
  memset(sysvid_fb, 0, length);
#endif
}


/*
 * Zoom
 */
void
sysvid_zoom(S8 z)
{
#ifndef IIGS
  if (!(videoFlags & SDL_FULLSCREEN) &&
      ((z < 0 && zoom > 1) ||
       (z > 0 && zoom < SYSVID_MAXZOOM))) {
    zoom += z;
    screen = initScreen(SYSVID_WIDTH * zoom,
			SYSVID_HEIGHT * zoom,
			screen->format->BitsPerPixel, videoFlags);
    sysvid_restorePalette();
    sysvid_update(&SCREENRECT);
  }
#endif
}

/*
 * Toggle fullscreen
 */
void
sysvid_toggleFullscreen(void)
{
#ifndef IIGS
  videoFlags ^= SDL_FULLSCREEN;

  if (videoFlags & SDL_FULLSCREEN) {  /* go fullscreen */
    szoom = zoom;
    zoom = fszoom;
  }
  else {  /* go window */
    zoom = szoom;
  }
  screen = initScreen(SYSVID_WIDTH * zoom,
		      SYSVID_HEIGHT * zoom,
		      screen->format->BitsPerPixel, videoFlags);
  sysvid_restorePalette();
  sysvid_update(&SCREENRECT);
#endif
}

void sysvid_wait_vblank()
{
#ifdef IIGS
	volatile const S8* VSTATUS = (S8*) 0xC019;

	#if 1
	// While already in vblank wait
	while ((*VSTATUS & 0x80) == 0)
	{
		// Wait for VBLANK to END
	}
	while ((*VSTATUS & 0x80) != 0)
	{
		// Wait for VBLANK to BEGIN
	}
	#else
	// While already in vblank wait
	while (VSTATUS[0] >= 0)
	{
		// Wait for VBLANK to END
	}
	while (VSTATUS[0] < 0)
	{
		// Wait for VBLANK to BEGIN
	}
	#endif
#endif
}


/* eof */



