/*
 * xrick/include/system.h
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

#ifndef _SYSTEM_H
#define _SYSTEM_H

#include "config.h"

/*
 * If compiling w/gcc, then we can use attributes. UNUSED(x) flags a
 * parameter or a variable as potentially being unused, so that gcc doesn't
 * complain about it.
 *
 * Note: from OpenAL code: Darwin OS cc is based on gcc and has __GNUC__
 * defined, yet does not support attributes. So in theory we should exclude
 * Darwin target here.
 */
#ifdef __GNUC__
#define UNUSED(x) x __attribute((unused))
#else
#define UNUSED(x) x
#endif

/*
 * Detect Microsoft Visual C
 */
#ifdef _MSC_VER
#define __MSVC__
/*
 * FIXME disable "integral size mismatch in argument; conversion supplied" warning
 * as long as the code has not been cleared -- there are so many of them...
 */

#pragma warning( disable : 4761 )
#endif

/*
 * Detect Microsoft Windows
 */
#ifdef WIN32
#define __WIN32__
#endif

#ifdef __ORCAC__
/* Apple IIgs */
typedef unsigned char U8;         /*  8 bits unsigned */
typedef unsigned int U16;   /* 16 bits unsigned */
typedef unsigned long U32;         /* 32 bits unsigned */
typedef signed char S8;           /*  8 bits signed   */
typedef signed int S16;     /* 16 bits signed   */
typedef signed long S32;           /* 32 bits signed   */
#else
/* there are true at least on x86 platforms */
typedef unsigned char U8;         /*  8 bits unsigned */
typedef unsigned short int U16;   /* 16 bits unsigned */
typedef unsigned int U32;         /* 32 bits unsigned */
typedef signed char S8;           /*  8 bits signed   */
typedef signed short int S16;     /* 16 bits signed   */
typedef signed int S32;           /* 32 bits signed   */
#endif

/* this must be after typedefs because it relies on types defined above */
#include "rects.h"
#include "img.h"

/*
 * main section
 */
extern void sys_init(int, char **);
extern void sys_shutdown(void);
extern void sys_panic(char *, ...);
extern void sys_printf(char *, ...);
extern U32 sys_gettime(void);
extern void sys_sleep(int);

/*
 * video section
 */
#define SYSVID_ZOOM 2
#define SYSVID_MAXZOOM 4
#ifdef IIGS
#define SYSVID_WIDTH 160
#else
#define SYSVID_WIDTH 320
#endif
#define SYSVID_HEIGHT 200

extern void sysvid_init(void);
extern void sysvid_shutdown(void);
extern void sysvid_update(rect_t *);
extern void sysvid_clear(void);
extern void sysvid_clearPalette(void);
extern void sysvid_FadeIn(void);
extern void sysvid_FadeOut(void);
extern void sysvid_zoom(S8);
extern void sysvid_toggleFullscreen(void);
extern void sysvid_setGamePalette(void);
extern void sysvid_setPalette(img_color_t *, U16);
extern void sysvid_wait_vblank();
/*
 * events section
 */
extern void sysevt_poll(void);
extern void sysevt_wait(void);

/*
 * keyboard section
 */
extern U8 syskbd_up;
extern U8 syskbd_down;
extern U8 syskbd_left;
extern U8 syskbd_right;
extern U8 syskbd_pause;
extern U8 syskbd_end;
extern U8 syskbd_xtra;
extern U8 syskbd_fire;

/*
 * sound section
 */
#ifdef ENABLE_SOUND

#ifdef IIGS
typedef int sound_t;

/*
 * Output from the Mr.Audio Bank packer
 */
enum {
	SND_BOMBSHHT,
	SND_BONUS,
	SND_BOX,
	SND_BULLET,
	SND_CRAWL,
	SND_DIE,
	SND_ENT0,
	SND_ENT1,
	SND_ENT2,
	SND_ENT3,
	SND_ENT4,
	SND_ENT6,
	SND_ENT8,
	SND_EXPLODE,
	SND_JUMP,
	SND_PAD,
	SND_SBONUS1,
	SND_SBONUS2,
	SND_STICK,
	SND_WALK,
};


#else
typedef struct {
#ifdef DEBUG
  char *name;
#endif
  U8 *buf;
  U32 len;
  U8 dispose;
} sound_t;
#endif

extern void syssnd_init(void);
extern void syssnd_shutdown(void);
extern void syssnd_vol(S8);
extern void syssnd_toggleMute(void);
#ifdef IIGS
extern S8 syssnd_play(sound_t, S8);
extern void syssnd_stopsound(sound_t);
extern int syssnd_isplaying(sound_t);
extern void syssnd_free(sound_t);
#else
extern S8 syssnd_play(sound_t *, S8);
extern void syssnd_stopsound(sound_t *);
extern int syssnd_isplaying(sound_t *);
extern void syssnd_free(sound_t *);
extern sound_t *syssnd_load(char *name);
#endif
extern void syssnd_pause(U8, U8);
extern void syssnd_stopchan(S8);
extern void syssnd_stopall();
#endif

/*
 * args section
 */
extern int sysarg_args_period;
extern int sysarg_args_map;
extern int sysarg_args_submap;
extern int sysarg_args_fullscreen;
extern int sysarg_args_zoom;
#ifdef ENABLE_SOUND
extern int sysarg_args_nosound;
extern int sysarg_args_vol;
#endif
extern char *sysarg_args_data;

extern void sysarg_init(int, char **);

/*
 * joystick section
 */
#ifdef ENABLE_JOYSTICK
extern void sysjoy_init(void);
extern void sysjoy_shutdown(void);
#endif

#ifdef IIGS
// GS Hardware Registers
extern volatile char *VIDEO_REGISTER;

// GS Specific Stuff
extern int LZ4_Unpack(char* pDest, char* pPackedSource);
extern volatile unsigned long* tick;

// GS Rendering Stuff
extern void SetTileBank(short bank);
extern void DrawTile(int offset, U16 tileNo);
extern void SetSpriteBanks(short b0, short b1, short b2, short b3);
extern void DrawSprite(int offset, int SpriteNo);

// Code for presenting backpage
extern void PresentPalette(void);
extern void PresentSCB(void);
extern void PresentFrameBuffer(void);
extern int BlitRect(U16 x, U16 y, U16 width, U16 height);
extern void wait_vsync(void);

// ADB Support Code
extern char KeyArray[128];
extern void RemoveKeyboardDriver();
extern void AddKeyboardDriver();
#endif

#endif

/* eof */


