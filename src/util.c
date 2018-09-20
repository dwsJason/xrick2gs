/*
 * xrick/src/util.c
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

#include <stdlib.h>  /* NULL */

#include "system.h"
#include "config.h"
#include "game.h"
#include "util.h"

#include "ents.h"
#include "e_rick.h"
#include "maps.h"

/*
 * Full box test.
 *
 * ASM 1199
 *
 * e: entity to test against.
 * x,y: coordinates to test.
 * ret: TRUE/(x,y) is within e's space, FALSE/not.
 */
U8
u_fboxtest(ent_t* pEnt, S16 x, S16 y)
{
  if (pEnt->x >= x ||
      pEnt->x + pEnt->w < x ||
      pEnt->y >= y ||
      pEnt->y + pEnt->h < y)
    return FALSE;
  else
    return TRUE;
}




/*
 * Box test (then whole e2 is checked agains the center of e1).
 *
 * ASM 113E
 *
 * e1: entity to test against (corresponds to DI in asm code).
 * e2: entity to test (corresponds to SI in asm code).
 * ret: TRUE/intersect, FALSE/not.
 */
U8
u_boxtest(ent_t* pEnt1, ent_t* pEnt2)
{
  /* rick is special (may be crawling) */
  if (pEnt1 == &ent_ents[E_RICK_NO])
    return e_rick_boxtest(pEnt2);

  /*
   * entity 1: x+0x05 to x+0x011, y to y+0x14
   * entity 2: x to x+ .w, y to y+ .h
   */
  if (pEnt1->x + 0x11 < pEnt2->x ||
      pEnt1->x + 0x05 > pEnt2->x + pEnt2->w ||
      pEnt1->y + 0x14 < pEnt2->y ||
      pEnt1->y > pEnt2->y + pEnt2->h - 1)
    return FALSE;
  else
    return TRUE;
}


/*
 * Compute the environment flag.
 *
 * ASM 0FBC if !crawl, else 103E
 *
 * x, y: coordinates where to compute the environment flag
 * crawl: is rick crawling?
 * rc0: anything CHANGED to the environment flag for crawling (6DBA)
 * rc1: anything CHANGED to the environment flag (6DAD)
 */
void
u_envtest(S16 x, S16 y, U8 crawl, U8 *rc0, U8 *rc1)
{
  U8 i, xx;

  /* prepare for ent #0 test */
  ent_ents[ENT_ENTSNUM].x = x;
  ent_ents[ENT_ENTSNUM].y = y;

  i = 1;
  if (!crawl) i++;
  if (y & 0x0004) i++;

  x += 4;
  xx = (U8)x; /* FIXME? */

  x = x >> 3;  /* from pixels to tiles */
  y = y >> 3;  /* from pixels to tiles */

  *rc0 = *rc1 = 0;

  if (xx & 0x07) {  /* tiles columns alignment */
    if (crawl) {
      *rc0 |= (map_eflg[map_map[y][x]] &
	   (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP));
      *rc0 |= (map_eflg[map_map[y][x + 1]] &
	   (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP));
      *rc0 |= (map_eflg[map_map[y][x + 2]] &
	   (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP));
      y++;
    }
    do {
      *rc1 |= (map_eflg[map_map[y][x]] &
	       (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_FGND|
		MAP_EFLG_LETHAL|MAP_EFLG_01));
      *rc1 |= (map_eflg[map_map[y][x + 1]] &
	       (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_FGND|
		MAP_EFLG_LETHAL|MAP_EFLG_CLIMB|MAP_EFLG_01));
      *rc1 |= (map_eflg[map_map[y][x + 2]] &
	       (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_FGND|
		MAP_EFLG_LETHAL|MAP_EFLG_01));
      y++;
    } while (--i > 0);

    *rc1 |= (map_eflg[map_map[y][x]] &
	     (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP|MAP_EFLG_FGND|
	      MAP_EFLG_LETHAL|MAP_EFLG_01));
    *rc1 |= (map_eflg[map_map[y][x + 1]]);
    *rc1 |= (map_eflg[map_map[y][x + 2]] &
	     (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP|MAP_EFLG_FGND|
	      MAP_EFLG_LETHAL|MAP_EFLG_01));
  }
  else {
    if (crawl) {
      *rc0 |= (map_eflg[map_map[y][x]] &
	   (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP));
      *rc0 |= (map_eflg[map_map[y][x + 1]] &
	   (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP));
      y++;
    }
    do {
      *rc1 |= (map_eflg[map_map[y][x]] &
	       (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_FGND|
		MAP_EFLG_LETHAL|MAP_EFLG_CLIMB|MAP_EFLG_01));
      *rc1 |= (map_eflg[map_map[y][x + 1]] &
	       (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_FGND|
		MAP_EFLG_LETHAL|MAP_EFLG_CLIMB|MAP_EFLG_01));
      y++;
    } while (--i > 0);

    *rc1 |= (map_eflg[map_map[y][x]]);
    *rc1 |= (map_eflg[map_map[y][x + 1]]);
  }

  /*
   * If not lethal yet, and there's an entity on slot zero, and (x,y)
   * boxtests this entity, then raise SOLID flag. This is how we make
   * sure that no entity can move over the entity that is on slot zero.
   *
   * Beware! When game_cheat2 is set, this means that a block can
   * move over rick without killing him -- but then rick is trapped
   * because the block is solid.
   */
  if (!(*rc1 & MAP_EFLG_LETHAL)
      && ent_ents[0].n
      && u_boxtest(&ent_ents[ENT_ENTSNUM], &ent_ents[0])) {
    *rc1 |= MAP_EFLG_SOLID;
  }

  /* When game_cheat2 is set, the environment can not be lethal. */
#ifdef ENABLE_CHEATS
  if (game_cheat2) *rc1 &= ~MAP_EFLG_LETHAL;
#endif
}


/*
 * Check if x,y is within e trigger box.
 *
 * ASM 126F
 * return: FALSE if not in box, TRUE if in box.
 */
U8
u_trigbox(ent_t* pEnt, S16 x, S16 y)
{
  U16 xmax, ymax;

  //printf("u_trigbox e=%d x=%d y=%d ", e, x, y);

  xmax = pEnt->trig_x + (ent_entdata[pEnt->n & 0x7F].trig_w << 3);
  ymax = pEnt->trig_y + (ent_entdata[pEnt->n & 0x7F].trig_h << 3);

  if (xmax > 0xFF) xmax = 0xFF;

  if (x <= pEnt->trig_x || x > xmax ||
      y <= pEnt->trig_y || y > ymax)
    return FALSE;
  else
    return TRUE;
}


/* eof */
