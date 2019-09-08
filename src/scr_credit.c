//
// Early Splash Screen, on the GS Version
// Since it takes a while to initialize
//
#include "system.h"
#include "game.h"


#ifdef IIGS
segment "screen";
#pragma noroot
#endif

#include <Memory.h>

extern char credits_lz4;

void scr_credit()
{
	// Keep the Screen on
	*VIDEO_REGISTER|=0xC0;
	// Blank the screen, so you don't see trash in the Frame Buffer
	memset((void*)0xE19E00, (int)0, (size_t)32);
	memset((void*)0xE19D00, (int)0, (size_t)200);
	// Display the Credits
	LZ4_Unpack((char*)(0xE12000), &credits_lz4);
}
