/*
#--------------------------------------------------------
# $File: xrick2png.h,v $          
# $Author: jandersen $           
# $Revision: #1 $         
#--------------------------------------------------------
	
*/

#ifndef _xrick2png_h
#define _xrick2png_h

//#define VERSION "1.00"

//  MYBMP Structure
typedef struct MYBMP {
	signed int width;         // width in pixels
    signed int height;        // height in pixels
		   int num_colors;
    unsigned char *map;        // pointer to pixel map
	unsigned char *palette;    // pointer to palette data
} MYBMP;

#endif // _dg2png_h

// EOF - xrick2png.h


