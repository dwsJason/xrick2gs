/*
 * xrick/src/scroller.c
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

#include <stdlib.h>

#include "system.h"
#include "game.h"
#include "scroller.h"
#include "debug.h"

#include "draw.h"
#include "maps.h"
#include "ents.h"

static U8 period;

#ifdef IIGS
#pragma noroot
segment "screen";
#endif

rect_t scroll_SCREENRECT = { 32, 8, 256, SYSVID_HEIGHT-8, NULL };

/*
 * Scroll up
 *
 */
U8
scroll_up(void)
{
  U8 i, j;
  ent_t *pEnt;
  U8* pSrc;
  U8* pDst;
  static U8 n = 0;

  /* last call: restore */
  if (n == 8) {
    n = 0;
    game_period = period;
    return SCROLL_DONE;
  }

  /* first call: prepare */
  if (n == 0) {
    period = game_period;
    game_period = SCROLL_PERIOD;
  }

  /* translate map */
  pDst = &map_map[MAP_ROW_SCRTOP][0];
  pSrc = pDst+32;

  for (i = MAP_ROW_SCRTOP; i < MAP_ROW_HBBOT; i++)
  {
	  memcpy(pDst, pSrc, (size_t)32);
	  pDst = pSrc;
	  pSrc += 32;
  }

  /* translate entities */
  for (pEnt = ent_ents; pEnt->n != 0xFF; ++pEnt) {
    if (pEnt->n) {
      pEnt->ysave -= 8;
      pEnt->trig_y -= 8;
      pEnt->y -= 8;
      if (pEnt->y & 0x8000) {  /* map coord. from 0x0000 to 0x0140 */
	IFDEBUG_SCROLLER(
	  sys_printf("xrick/scroller: entity %#04X is gone\n", i);
	  );
	pEnt->n = 0;
      }
    }
  }

  /* display */
  draw_map();
  ent_draw();
//  draw_drawStatus();
  map_frow++;

  /* loop */
  if (n++ == 7) {
    /* activate visible entities */
    ent_actvis(map_frow + MAP_ROW_HBTOP, map_frow + MAP_ROW_HBBOT);

    /* prepare map */
    map_expand();

    /* display */
    //draw_map();
    ent_draw();
//    draw_drawStatus();
  }

  game_rects = &scroll_SCREENRECT;

  return SCROLL_RUNNING;
}

/*
 * Scroll down
 *
 */
U8
scroll_down(void)
{
  U8 i, j;
  ent_t *pEnt;
  U8* pSrc;
  U8* pDst;
  static U8 n = 0;

  /* last call: restore */
  if (n == 8) {
    n = 0;
    game_period = period;
    return SCROLL_DONE;
  }

  /* first call: prepare */
  if (n == 0) {
    period = game_period;
    game_period = SCROLL_PERIOD;
  }

  /* translate map */
  pDst = &map_map[MAP_ROW_SCRBOT][0];
  pSrc = pDst-32;
  for (i = MAP_ROW_SCRBOT; i > MAP_ROW_HTTOP; i--)
  {
	  memcpy(pDst, pSrc, (size_t)32);
	  pDst = pSrc;
	  pSrc -= 32;
  }

  /* translate entities */
  for (pEnt = ent_ents; pEnt->n != 0xFF; ++pEnt) {
    if (pEnt->n) {
      pEnt->ysave += 8;
      pEnt->trig_y += 8;
      pEnt->y += 8;
      if (pEnt->y > 0x0140) {  /* map coord. from 0x0000 to 0x0140 */
	IFDEBUG_SCROLLER(
	  sys_printf("xrick/scroller: entity %#04X is gone\n", i);
	  );
	pEnt->n = 0;
      }
    }
  }

  /* display */
  draw_map();
  ent_draw();
//  draw_drawStatus();
  map_frow--;

  /* loop */
  if (n++ == 7) {
    /* activate visible entities */
    ent_actvis(map_frow + MAP_ROW_HTTOP, map_frow + MAP_ROW_HTBOT);

    /* prepare map */
    map_expand();

    /* display */
    //draw_map();
    ent_draw();
//    draw_drawStatus();
  }

  game_rects = &scroll_SCREENRECT;

  return SCROLL_RUNNING;
}

/* eof */
