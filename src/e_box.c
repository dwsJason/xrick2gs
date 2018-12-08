/*
 * xrick/src/e_box.c
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
#include "ents.h"
#include "e_box.h"

#include "e_bullet.h"
#include "e_bomb.h"
#include "e_rick.h"
#include "maps.h"
#include "util.h"

#ifdef IIGS
#pragma noroot
segment "e";
#endif

/*
 * FIXME this is because the same structure is used
 * for all entities. Need to replace this w/ an inheritance
 * solution.
 */
#define cnt c1

/*
 * Constants
 */
#define SEQ_INIT 0x0A

/*
 * Prototypes
 */
static void explode(ent_t*);

/*
 * Entity action
 *
 * ASM 245A
 */
void
e_box_action(ent_t* pEnt)
{
	static U8 sp[] = {0x24, 0x25, 0x26, 0x27, 0x28};  /* explosion sprites sequence */

	if (pEnt->n & ENT_LETHAL) {
		/*
		 * box is lethal i.e. exploding
		 * play sprites sequence then stop
		 */
		pEnt->sprite = sp[pEnt->cnt >> 1];
		if (--pEnt->cnt == 0) {
			pEnt->n = 0;
			map_marks[pEnt->mark].ent |= MAP_MARK_NACT;
		}
	} else {
		/*
		 * not lethal: check to see if triggered
		 */
		if (e_rick_boxtest(pEnt)) {
			/* rick: collect bombs or bullets and stop */
#ifdef ENABLE_SOUND
			syssnd_play(WAV_BOX, 1);
#endif
			if (pEnt->n == 0x10)
				game_bombs = GAME_BOMBS_INIT;
			else  /* 0x11 */
				game_bullets = GAME_BULLETS_INIT;

			game_status_dirty = 1;
			pEnt->n = 0;
			map_marks[pEnt->mark].ent |= MAP_MARK_NACT;
		}
		else if (E_RICK_STTST(E_RICK_STSTOP) &&
				u_fboxtest(pEnt, e_rick_stop_x, e_rick_stop_y)) {
			/* rick's stick: explode */
			explode(pEnt);
		}
		else if (E_BULLET_ENT.n && u_fboxtest(pEnt, e_bullet_xc, e_bullet_yc)) {
			/* bullet: explode (and stop bullet) */
			E_BULLET_ENT.n = 0;
			explode(pEnt);
		}
		else if (e_bomb_lethal && e_bomb_hit(pEnt)) {
			/* bomb: explode */
			explode(pEnt);
		}
	}
}


/*
 * Explode when
 */
static void explode(ent_t* pEnt)
{
	pEnt->cnt = SEQ_INIT;
	pEnt->n |= ENT_LETHAL;
#ifdef ENABLE_SOUND
	syssnd_play(WAV_EXPLODE, 1);
#endif
}

/* eof */


