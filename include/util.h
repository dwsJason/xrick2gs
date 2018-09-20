/*
 * xrick/include/util.h
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

#ifndef _UTIL_H
#define _UTIL_H

#include "ents.h"

extern void u_envtest(S16, S16, U8, U8 *, U8 *);
extern U8 u_boxtest(ent_t*, ent_t*);
extern U8 u_fboxtest(ent_t*, S16, S16);
extern U8 u_trigbox(ent_t* pEnt, S16, S16);

#endif

/* eof */
