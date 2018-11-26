/*
 * xrick/src/e_them.c
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
#include "e_them.h"

#include "e_rick.h"
#include "e_bomb.h"
#include "e_bullet.h"
#include "maps.h"
#include "util.h"

#define TYPE_1A (0x00)
#define TYPE_1B (0xff)

/*
 * public vars
 */
U32 e_them_rndseed = 0;

/*
 * local vars
 */
static U16 e_them_rndnbr = 0;

#ifdef IIGS
#pragma noroot
segment "e";
#endif

/*
 * Check if entity boxtests with a lethal e_them i.e. something lethal
 * in slot 0 and 4 to 8.
 *
 * ASM 122E
 *
 * e: entity slot number.
 * ret: TRUE/boxtests, FALSE/not
 */
U8
u_themtest(ent_t* pEnt)
{
  ent_t* pI;

  if ((ent_ents[0].n & ENT_LETHAL) && u_boxtest(pEnt, ent_ents))
    return TRUE;

  for (pI = &ent_ents[4]; pI < &ent_ents[9]; pI++)
    if ((pI->n & ENT_LETHAL) && u_boxtest(pEnt, pI))
      return TRUE;

  return FALSE;
}


/*
 * Go zombie
 *
 * ASM 237B
 */
void
e_them_gozombie(ent_t* pEnt)
{
#define offsx c1
  pEnt->n = 0x47;  /* zombie entity */
  pEnt->front = TRUE;
  pEnt->offsy = -0x0400;
#ifdef ENABLE_SOUND
  syssnd_play(WAV_DIE, 1);
#endif
  game_score += 50;
  if (pEnt->flags & ENT_FLG_ONCE) {
    /* make sure entity won't be activated again */
    map_marks[pEnt->mark].ent |= MAP_MARK_NACT;
  }
  pEnt->offsx = (pEnt->x >= 0x80 ? -0x02 : 0x02);
#undef offsx
}


/*
 * Action sub-function for e_them _t1a and _t1b
 *
 * Those two types move horizontally, and fall if they have to.
 * Type 1a moves horizontally over a given distance and then
 * u-turns and repeats; type 1b is more subtle as it does u-turns
 * in order to move horizontally towards rick.
 *
 * ASM 2242
 */
void
e_them_t1_action2(ent_t* pEnt, U8 type)
{
#define offsx c1
#define step_count c2
  U32 i;
  S16 x, y;
  U8 env0, env1;

  /* by default, try vertical move. calculate new y */
  i = (((S32)pEnt->y) << 8) + ((S32)pEnt->offsy) + ((U32)pEnt->ylow);
  y = i >> 8;

  /* deactivate if outside vertical boundaries */
  /* no need to test zero since e_them _t1a/b don't go up */
  /* FIXME what if they got scrolled out ? */
  if (y > 0x140) {
    pEnt->n = 0;
    return;
  }

  /* test environment */
  u_envtest(pEnt->x, y, FALSE, &env0, &env1);

  if (!(env1 & (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP))) {
    /* vertical move possible: falling */
    if (env1 & MAP_EFLG_LETHAL) {
      /* lethal entities kill e_them */
      e_them_gozombie(pEnt);
      return;
    }
    /* save, cleanup and return */
    pEnt->y = y;
    pEnt->ylow = i;
    pEnt->offsy += 0x0080;
    if (pEnt->offsy > 0x0800)
      pEnt->offsy = 0x0800;
    return;
  }

  /* vertical move not possible. calculate new sprite */
  pEnt->sprite = pEnt->sprbase
    + ent_sprseq[(pEnt->x & 0x1c) >> 3]
    + (pEnt->offsx < 0 ? 0x03 : 0x00);

  /* reset offsy */
  pEnt->offsy = 0x0080;

  /* align to ground */
  pEnt->y &= 0xfff8;
  pEnt->y |= 0x0003;

  /* latency: if not zero then decrease and return */
  if (pEnt->latency > 0) {
    pEnt->latency--;
    return;
  }

  /* horizontal move. calculate new x */
  if (pEnt->offsx == 0)  /* not supposed to move -> don't */
    return;

  x = pEnt->x + pEnt->offsx;
  if (pEnt->x < 0 || pEnt->x > 0xe8) {
    /*  U-turn and return if reaching horizontal boundaries */
    pEnt->step_count = 0;
    pEnt->offsx = -pEnt->offsx;
    return;
  }

  /* test environment */
  u_envtest(x, pEnt->y, FALSE, &env0, &env1);

  if (env1 & (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP)) {
    /* horizontal move not possible: u-turn and return */
    pEnt->step_count = 0;
    pEnt->offsx = -pEnt->offsx;
    return;
  }

  /* horizontal move possible */
  if (env1 & MAP_EFLG_LETHAL) {
    /* lethal entities kill e_them */
    e_them_gozombie(pEnt);
    return;
  }

  /* save */
  pEnt->x = x;

  /* depending on type, */
  if (type == TYPE_1B) {
    /* set direction to move horizontally towards rick */
    if ((pEnt->x & 0x1e) != 0x10)  /* prevents too frequent u-turns */
      return;
    pEnt->offsx = (pEnt->x < E_RICK_ENT.x) ? 0x02 : -0x02;
    return;
  }
  else {
    /* set direction according to step counter */
    pEnt->step_count++;
    /* FIXME why trig_x (b16) ?? */
    if ((pEnt->trig_x >> 1) > pEnt->step_count)
      return;
  }

  /* type is 1A and step counter reached its limit: u-turn */
  pEnt->step_count = 0;
  pEnt->offsx = -pEnt->offsx;
#undef offsx
#undef step_count
}


/*
 * ASM 21CF
 */
void
e_them_t1_action(ent_t* pEnt, U8 type)
{
  e_them_t1_action2(pEnt, type);

  /* lethal entities kill them */
  if (u_themtest(pEnt)) {
    e_them_gozombie(pEnt);
    return;
  }

  /* bullet kills them */
  if (E_BULLET_ENT.n &&
      u_fboxtest(pEnt, E_BULLET_ENT.x + (e_bullet_offsx < 0 ? 0 : 0x18),
		 E_BULLET_ENT.y)) {
    E_BULLET_ENT.n = 0;
    e_them_gozombie(pEnt);
    return;
  }

  /* bomb kills them */
  if (e_bomb_lethal && e_bomb_hit(pEnt)) {
    e_them_gozombie(pEnt);
    return;
  }

  /* rick stops them */
  if (E_RICK_STTST(E_RICK_STSTOP) &&
      u_fboxtest(pEnt, e_rick_stop_x, e_rick_stop_y))
    pEnt->latency = 0x14;

  /* they kill rick */
  if (e_rick_boxtest(pEnt))
    e_rick_gozombie();
}


/*
 * Action function for e_them _t1a type (stays within boundaries)
 *
 * ASM 2452
 */
void
e_them_t1a_action(ent_t* pEnt)
{
  e_them_t1_action(pEnt, TYPE_1A);
}


/*
 * Action function for e_them _t1b type (runs for rick)
 *
 * ASM 21CA
 */
void
e_them_t1b_action(ent_t* pEnt)
{
  e_them_t1_action(pEnt, TYPE_1B);
}


/*
 * Action function for e_them _z (zombie) type
 *
 * ASM 23B8
 */
void
e_them_z_action(ent_t* pEnt)
{
#define offsx c1
  U32 i;

  /* calc new sprite */
  pEnt->sprite = pEnt->sprbase
    + ((pEnt->x & 0x04) ? 0x07 : 0x06);

  /* calc new y */
  i = (((S32)pEnt->y) << 8) + ((S32)pEnt->offsy) + ((U32)pEnt->ylow);

  /* deactivate if out of vertical boundaries */
  if (pEnt->y < 0 || pEnt->y > 0x0140) {
    pEnt->n = 0;
    return;
  }

  /* save */
  pEnt->offsy += 0x0080;
  pEnt->ylow = i;
  pEnt->y = i >> 8;

  /* calc new x */
  pEnt->x += pEnt->offsx;

  /* must stay within horizontal boundaries */
  if (pEnt->x < 0)
    pEnt->x = 0;
  if (pEnt->x > 0xe8)
    pEnt->x = 0xe8;
#undef offsx
}


/*
 * Action sub-function for e_them _t2.
 *
 * Must document what it does.
 *
 * ASM 2792
 */
void
e_them_t2_action2(ent_t* pEnt)
{
#define flgclmb c1
#define offsx c2
  U32 i;
  S16 x, y, yd;
  U8 env0, env1;

  /*
   * vars required by the Black Magic (tm) performance at the
   * end of this function.
   */
  static U16 bx;
  static U8 *bl = (U8*)&bx;
  U8 *bh = bl+1;
  static U16 cx;
  static U8 *cl = (U8*)&cx;
  U8 *ch = cl+1;
  static U16 *sl = (U16*)&e_them_rndseed;
  U16 *sh = sl+1;

  /*sys_printf("e_them_t2 ------------------------------\n");*/

  /* latency: if not zero then decrease */
  if (pEnt->latency > 0) pEnt->latency--;

  /* climbing? */
  if (pEnt->flgclmb != TRUE) goto climbing_not;

  /* CLIMBING */

  /*sys_printf("e_them_t2 climbing\n");*/

  /* latency: if not zero then return */
  if (pEnt->latency > 0) return;

  /* calc new sprite */
  pEnt->sprite = pEnt->sprbase + 0x08 +
    (((pEnt->x ^ pEnt->y) & 0x04) ? 1 : 0);

  /* reached rick's level? */
  if ((pEnt->y & 0xfe) != (E_RICK_ENT.y & 0xfe)) goto ymove;

  xmove:
    /* calc new x and test environment */
    pEnt->offsx = (pEnt->x < E_RICK_ENT.x) ? 0x02 : -0x02;
    x = pEnt->x + pEnt->offsx;
    u_envtest(x, pEnt->y, FALSE, &env0, &env1);
    if (env1 & (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP))
      return;
    if (env1 & MAP_EFLG_LETHAL) {
      e_them_gozombie(pEnt);
      return;
    }
    pEnt->x = x;
    if (env1 & (MAP_EFLG_VERT|MAP_EFLG_CLIMB))  /* still climbing */
      return;
    goto climbing_not;  /* not climbing anymore */

  ymove:
    /* calc new y and test environment */
    yd = pEnt->y < E_RICK_ENT.y ? 0x02 : -0x02;
    y = pEnt->y + yd;
    if (y < 0 || y > 0x0140) {
      pEnt->n = 0;
      return;
    }
    u_envtest(pEnt->x, y, FALSE, &env0, &env1);
    if (env1 & (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP)) {
      if (yd < 0)
	goto xmove;  /* can't go up */
      else
	goto climbing_not;  /* can't go down */
    }
    /* can move */
    pEnt->y = y;
    if (env1 & (MAP_EFLG_VERT|MAP_EFLG_CLIMB))  /* still climbing */
      return;

    /* NOT CLIMBING */

 climbing_not:
    /*sys_printf("e_them_t2 climbing NOT\n");*/

    pEnt->flgclmb = FALSE;  /* not climbing */

    /* calc new y (falling) and test environment */
    i = (((U32)pEnt->y) << 8) + pEnt->offsy + pEnt->ylow;
    y = i >> 8;
    u_envtest(pEnt->x, y, FALSE, &env0, &env1);
    if (!(env1 & (MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP))) {
      /*sys_printf("e_them_t2 y move OK\n");*/
      /* can go there */
      if (env1 & MAP_EFLG_LETHAL) {
	e_them_gozombie(pEnt);
	return;
      }
      if (y > 0x0140) {  /* deactivate if outside */
	pEnt->n = 0;
	return;
      }
      if (!(env1 & MAP_EFLG_VERT)) {
	/* save */
	pEnt->y = y;
	pEnt->ylow = i;
	pEnt->offsy += 0x0080;
	if (pEnt->offsy > 0x0800)
	  pEnt->offsy = 0x0800;
	return;
      }
      if (((pEnt->x & 0x07) == 0x04) && (y < E_RICK_ENT.y)) {
	/*sys_printf("e_them_t2 climbing00\n");*/
	pEnt->flgclmb = TRUE;  /* climbing */
	return;
      }
    }

    /*sys_printf("e_them_t2 ymove nok or ...\n");*/
    /* can't go there, or ... */
    pEnt->y = (pEnt->y & 0xf8) | 0x03;  /* align to ground */
    pEnt->offsy = 0x0100;
    if (pEnt->latency != 00)
      return;

    if ((env1 & MAP_EFLG_CLIMB) &&
	((pEnt->x & 0x0e) == 0x04) &&
	(pEnt->y > E_RICK_ENT.y)) {
      /*sys_printf("e_them_t2 climbing01\n");*/
      pEnt->flgclmb = TRUE;  /* climbing */
      return;
    }

    /* calc new sprite */
    pEnt->sprite = pEnt->sprbase +
      ent_sprseq[(pEnt->offsx < 0 ? 4 : 0) +
		((pEnt->x & 0x0e) >> 3)];
    /*sys_printf("e_them_t2 sprite %02x\n", pEnt->sprite);*/


    /* */
    if (pEnt->offsx == 0)
      pEnt->offsx = 2;
    x = pEnt->x + pEnt->offsx;
    /*sys_printf("e_them_t2 xmove x=%02x\n", x);*/
    if (x < 0xe8) {
      u_envtest(x, pEnt->y, FALSE, &env0, &env1);
      if (!(env1 & (MAP_EFLG_VERT|MAP_EFLG_SOLID|MAP_EFLG_SPAD|MAP_EFLG_WAYUP))) {
	pEnt->x = x;
	if ((x & 0x1e) != 0x08)
	  return;

	/*
	 * Black Magic (tm)
	 *
	 * this is obviously some sort of randomizer to define a direction
	 * for the entity. it is an exact copy of what the assembler code
	 * does but I can't explain.
	 */
	bx = e_them_rndnbr + *sh + *sl + 0x0d;
	cx = *sh;
	*bl ^= *ch;
	*bl ^= *cl;
	*bl ^= *bh;
	e_them_rndnbr = bx;

	pEnt->offsx = (*bl & 0x01) ? -0x02 : 0x02;

	/* back to normal */

	return;

      }
    }

    /* U-turn */
    /*sys_printf("e_them_t2 u-turn\n");*/
    if (pEnt->offsx == 0)
      pEnt->offsx = 2;
    else
      pEnt->offsx = -pEnt->offsx;
#undef offsx
}

/*
 * Action function for e_them _t2 type
 *
 * ASM 2718
 */
void
e_them_t2_action(ent_t* pEnt)
{
  e_them_t2_action2(pEnt);

  /* they kill rick */
  if (e_rick_boxtest(pEnt))
    e_rick_gozombie();

  /* lethal entities kill them */
  if (u_themtest(pEnt)) {
    e_them_gozombie(pEnt);
    return;
  }

  /* bullet kills them */
  if (E_BULLET_ENT.n &&
      u_fboxtest(pEnt, E_BULLET_ENT.x + (e_bullet_offsx < 0 ? 00 : 0x18),
		 E_BULLET_ENT.y)) {
    E_BULLET_ENT.n = 0;
    e_them_gozombie(pEnt);
    return;
  }

  /* bomb kills them */
  if (e_bomb_lethal && e_bomb_hit(pEnt)) {
    e_them_gozombie(pEnt);
    return;
  }

  /* rick stops them */
  if (E_RICK_STTST(E_RICK_STSTOP) &&
      u_fboxtest(pEnt, e_rick_stop_x, e_rick_stop_y))
    pEnt->latency = 0x14;
}


/*
 * Action sub-function for e_them _t3
 *
 * FIXME always starts asleep??
 *
 * Waits until triggered by something, then execute move steps from
 * ent_mvstep with sprite from ent_sprseq. When done, either restart
 * or disappear.
 *
 * Not always lethal ... but if lethal, kills rick.
 *
 * ASM: 255A
 */
void
e_them_t3_action2(ent_t* pEnt)
{
#define sproffs c1
#define step_count c2
  U8 i;
  S16 x, y;

  while (1) {

    /* calc new sprite */
    i = ent_sprseq[pEnt->sprbase + pEnt->sproffs];
    if (i == 0xff)
      i = ent_sprseq[pEnt->sprbase];
    pEnt->sprite = i;

    if (pEnt->sproffs != 0) {  /* awake */

      /* rotate sprseq */
      if (ent_sprseq[pEnt->sprbase + pEnt->sproffs] != 0xff)
	pEnt->sproffs++;
      if (ent_sprseq[pEnt->sprbase + pEnt->sproffs] == 0xff)
	pEnt->sproffs = 1;

      if (pEnt->step_count < ent_mvstep[pEnt->step_no].count) {
	/*
	 * still running this step: try to increment x and y while
	 * checking that they remain within boudaries. if so, return.
	 * else switch to next step.
	 */
	pEnt->step_count++;
	x = pEnt->x + ((S16)(ent_mvstep[pEnt->step_no].dx));

	/* check'n save */
	if (x > 0 && x < 0xe8) {
	  pEnt->x = x;
	  /*FIXME*/
	  /*
	  y = ent_mvstep[pEnt->step_no].dy;
	  if (y < 0)
	    y += 0xff00;
	  y += pEnt->y;
	  */
	  y = pEnt->y + ((S16)(ent_mvstep[pEnt->step_no].dy));
	  if (y > 0 && y < 0x0140) {
	    pEnt->y = y;
	    return;
	  }
	}
      }

      /*
       * step is done, or x or y is outside boundaries. try to
       * switch to next step
       */
      pEnt->step_no++;
      if (ent_mvstep[pEnt->step_no].count != 0xff) {
	/* there is a next step: init and loop */
	pEnt->step_count = 0;
      }
      else {
	/* there is no next step: restart or deactivate */
	if (!E_RICK_STTST(E_RICK_STZOMBIE) &&
	    !(pEnt->flags & ENT_FLG_ONCE)) {
	  /* loop this entity */
	  pEnt->sproffs = 0;
	  pEnt->n &= ~ENT_LETHAL;
	  if (pEnt->flags & ENT_FLG_LETHALR)
	    pEnt->n |= ENT_LETHAL;
	  pEnt->x = pEnt->xsave;
	  pEnt->y = pEnt->ysave;
	  if (pEnt->y < 0 || pEnt->y > 0x140) {
	    pEnt->n = 0;
	    return;
	  }
	}
	else {
	  /* deactivate this entity */
	  pEnt->n = 0;
	  return;
	}
      }
    }
    else {  /* pEnt->sprseq1 == 0 -- waiting */

      /* ugly GOTOs */

      if (pEnt->flags & ENT_FLG_TRIGRICK) {  /* reacts to rick */
	/* wake up if triggered by rick */
	if (u_trigbox(pEnt, E_RICK_ENT.x + 0x0C, E_RICK_ENT.y + 0x0A))
	  goto wakeup;
      }

      if (pEnt->flags & ENT_FLG_TRIGSTOP) {  /* reacts to rick "stop" */
	/* wake up if triggered by rick "stop" */
	if (E_RICK_STTST(E_RICK_STSTOP) &&
	    u_trigbox(pEnt, e_rick_stop_x, e_rick_stop_y))
	  goto wakeup;
      }

      if (pEnt->flags & ENT_FLG_TRIGBULLET) {  /* reacts to bullets */
	/* wake up if triggered by bullet */
	if (E_BULLET_ENT.n && u_trigbox(pEnt, e_bullet_xc, e_bullet_yc)) {
	  E_BULLET_ENT.n = 0;
	  goto wakeup;
	}
      }

      if (pEnt->flags & ENT_FLG_TRIGBOMB) {  /* reacts to bombs */
	/* wake up if triggered by bomb */
	if (e_bomb_lethal && u_trigbox(pEnt, e_bomb_xc, e_bomb_yc))
	  goto wakeup;
      }

      /* not triggered: keep waiting */
      return;

      /* something triggered the entity: wake up */
      /* initialize step counter */
    wakeup:
      if E_RICK_STTST(E_RICK_STZOMBIE)
	return;
#ifdef ENABLE_SOUND
		/*
		* FIXME the sound should come from a table, there are 10 of them
		* but I dont have the table yet. must rip the data off the game...
		* FIXME is it 8 of them, not 10?
		* FIXME testing below...
		*/
		syssnd_play(WAV_ENTITY[(pEnt->trigsnd & 0x1F) - 0x14], 1);
		/*syssnd_play(WAV_ENTITY[0], 1);*/
#endif
      pEnt->n &= ~ENT_LETHAL;
      if (pEnt->flags & ENT_FLG_LETHALI)
	pEnt->n |= ENT_LETHAL;
      pEnt->sproffs = 1;
      pEnt->step_count = 0;
      pEnt->step_no = pEnt->step_no_i;
      return;
    }
  }
#undef step_count
}


/*
 * Action function for e_them _t3 type
 *
 * ASM 2546
 */
void
e_them_t3_action(ent_t* pEnt)
{
  e_them_t3_action2(pEnt);

  /* if lethal, can kill rick */
  if ((pEnt->n & ENT_LETHAL) &&
      !E_RICK_STTST(E_RICK_STZOMBIE) && e_rick_boxtest(pEnt)) {  /* CALL 1130 */
    e_rick_gozombie();
  }
}

/* eof */


