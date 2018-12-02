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
segment "system";
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
#include <Event.h>
#include <GSOS.h>
#include <Memory.h>
#include <Orca.h>
#include <Misctool.h>
#include <ADB.h>
#include <loader.h>
#endif

#ifdef __MSVC__
#include <memory.h> /* memset */
#endif

U8 *sysvid_fb; /* frame buffer */

rect_t SCREENRECT = {0, 0, 320, SYSVID_HEIGHT, NULL}; /* whole fb */

#ifndef IIGS
static SDL_Color palette[256];
static SDL_Surface *screen;
#endif

#ifdef IIGS
volatile char *VIDEO_REGISTER = (char*)0xC029;
volatile char *SHADOW_REGISTER = (char*)0xC035;
extern U8 tiles_lz4;
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

#ifdef IIGS
volatile unsigned long* tick;

typedef struct
{
  void* pLink;
  Word Count;
  Word Sig;
} taskHeader_t;

taskHeader_t dummyTask = {
	0,
	0,
	0xA55A
};

#endif

#ifdef IIGS
extern U8 xrickspr_00;
extern U8 xrickspr_01;
extern U8 xrickspr_02;
extern U8 xrickspr_03;

U8* compressedSprites[] =
{
	&xrickspr_00,
	&xrickspr_01,
	&xrickspr_02,
	&xrickspr_03
};

void PrepareSprites()
{
	int idx;
	U32* handles[4];

	for (idx = 0; idx < 4; ++idx)
	{
		printf("Alloc Sprites %d\n",idx);
		handles[idx] = (U32*)NewHandle(0x10000, userid(), 0xC014, 0); 
		if (toolerror())
		{
			printf("Unable to allocate 64k Sprites Bank %d\n", idx);
			printf("Game can't run\n");
			sys_sleep(5000);  // Wait 5 seconds
			exit(1);
		}
		printf("SUCCESS\n");
	}

	for (idx = 0; idx < 4; ++idx)
	{
		printf("Decompress Sprites %d\n", idx);
		LZ4_Unpack((char*)*handles[idx], compressedSprites[idx]);
	}

	SetSpriteBanks( (*handles[0])>>16,
					(*handles[1])>>16,
					(*handles[2])>>16,
					(*handles[3])>>16  );
}

struct LoadSegRec {
   Word userID;
   Pointer startAddr;
   Word LoadFileNo;
   Word LoadSegNo;
   Word LoadSegKind;
   };
typedef struct LoadSegRec LoadSegRec;

//
//  Summarize the LoadSegments
//
void GetLoadSegments()
{
	long* outData = (long*)0x011000; // hard coded address, so kegs can shit this out
	int idx;
static LoadSegRec result;

	outData[0] = 19;	// first value, the number of segments

	printf("$%08p GetLoadSegments\n", (Pointer)&GetLoadSegments);
	printf("$%04X userid\n", userid());

	for (idx = 1; idx < 255; ++idx)
	{
		// userid, loadfilenum, segnum, outptr
		memset(&result, 0, sizeof(LoadSegRec));
		GetLoadSegInfo(0,1,idx, (Pointer)&result);

		if (toolerror())
		{
			printf("toolerror = $%04X\n", toolerror());
			break;
		}
		else
		{
			Pointer pMem = *(Pointer*)result.startAddr;
			printf("Seg:%d userid=$%04X ptr=%08p\n", idx, result.userID, pMem);
			outData[idx] = (long)pMem;
		}

		//printf("Seg:%d $%08p\n", idx, *(Pointer)result.startAddr);
	}

	//sys_sleep(30000);  // Wait 30 seconds

}

#endif


/*
 * Initialise video
 */
void
sysvid_init(void)
{
#ifdef IIGS
	handle hndl;   // "generic memory handle"
	U32* directPageHandle;
	U32* tilesPageHandle;

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

	GetLoadSegments();

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
	printf("Allocate Direct Page space 512 bytes\n");
	directPageHandle = (U32*)NewHandle( 0x200, userid(), 0xC005, 0 );
	if (toolerror())
	{
		printf("Unable to allocate 512 bytes Direct Page\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);
	}
	printf("SUCCESS\n");

	//BlitFieldHndl   = NewHandle(0x10000, userid(), 0xC014, 0);
	printf("Allocate Bank for 8x8 Tiles\n");
	tilesPageHandle = (U32*)NewHandle(0x10000, userid(), 0xC014, 0); 
	if (toolerror())
	{
		printf("Unable to allocate 64k Tiles Bank\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);
	}
	printf("SUCCESS\n");
	SetTileBank((*tilesPageHandle)>>16);

	printf("Decompressing Tiles\n");
	LZ4_Unpack((char*)*tilesPageHandle, &tiles_lz4);

	PrepareSprites();

	printf("MiscTool Startup\n");
	MTStartUp();	// MiscTool Startup, for the Heartbeat
	if (toolerror())
	{
		printf("Unable to Start MiscTool\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);
	}

	printf("ADBTool Startup\n");
	ADBStartUp();
	if (toolerror())
	{
		printf("Unable to Start ADBTool\n");
		printf("Game can't run\n");
		sys_sleep(5000);  // Wait 5 seconds
		exit(1);
	}

	//  Hook in the Keyboard Driver
	AddKeyboardDriver();
	#if 0
	printf("Event Manager Startup\n");
	EMStartUp((Word)*directPageHandle,
			  (Word)0, // default 20
			  (Integer)0,
			  (Integer)320,
			  (Integer)0,
			  (Integer)200,
			  (Word)userid());
	#endif
	printf("Enable Tick Timer\n");
	SetHeartBeat((pointer)&dummyTask); // Force the Tick Timer On
	DelHeartBeat((pointer)&dummyTask); // Clear the dummy task from the list
	// Address of GetTick internal tick variable
	tick = (unsigned long*)GetAddr(tickCnt);

	// Framebuffer
	sysvid_fb = (U8*)0x12000;

	// SHR ON
	*VIDEO_REGISTER|=0xC0;

	// ENABLE Shadowing of SHR
	*SHADOW_REGISTER&=~0x08; // Shadow Enable
	// DISABLE Shadowing of SHR
	*SHADOW_REGISTER|=0x08; // Shadow Disable

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
#ifdef IIGS
	int result;
	//PresentFrameBuffer();
	while (rects)
	{
		#if 0
		printf("%d,%d,%d,%d\n",
			   rects->x,
			   rects->y,
			   rects->width,
			   rects->height
		);
		#endif
		result = BlitRect(rects->x, rects->y, rects->width, rects->height);
		rects = rects->next;
	}
#endif
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
  size_t length = SYSVID_WIDTH * SYSVID_HEIGHT;
  memset(sysvid_fb, 0, length);
#endif
}

void sysvid_clearPalette(void)
{
#ifdef IIGS
	size_t offset = SYSVID_WIDTH * SYSVID_HEIGHT;
	size_t length = 768;
	U8* ptr = sysvid_fb + offset;
	memset(ptr, 0, length);
#endif
}

void sysvid_FadeIn()
{
#ifdef IIGS
	size_t offset = SYSVID_WIDTH * SYSVID_HEIGHT;
	size_t length = 200;
	U8* ptr = sysvid_fb + offset;
	int idx;

	for (idx = 0;idx<16; ++idx)
	{
		memset(ptr, idx, length);
		wait_vsync();
		PresentSCB();
	}
#endif
}

void sysvid_FadeOut()
{
#ifdef IIGS
	size_t offset = SYSVID_WIDTH * SYSVID_HEIGHT;
	size_t length = 200;
	U8* ptr = sysvid_fb + offset;
	int idx;

	for (idx = 15;idx>=0; --idx)
	{
		memset(ptr, idx, length);
		wait_vsync();
		PresentSCB();
	}
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



