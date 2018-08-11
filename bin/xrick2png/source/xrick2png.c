/*
#--------------------------------------------------------
# $File: xrick2png.c,v $          
#--------------------------------------------------------
*/


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "bctypes.h"
#include "xrick2png.h"
#include "png.h"

// For the 3 pics
#include "pics.h"

#include "sprites.h"
#include "tiles.h"

#include "img.h"
#include "img_icon.e"
#include "img_splash.e"

static void _usage()
{
	printf("xrick2png v%s\n\n", VERSION);
	printf("Usage:  xrick2png\n"
		   "Written by Jason Andersen\n"
		   "Copyright (c) 2018 Jason Andersen.\n"
		   "Unauthorized use prohibited\n");

		   exit(1);

} // usage	

//
// Save the RawBMP Pixel Data, as raw IIGS
// framebuffer data
//
void savePixelsGS(MYBMP *pBitmap, const char* pFilename)
{
	FILE* gsfile = fopen( pFilename, "wb" );

	if (gsfile)
	{
		unsigned char* pPixels = pBitmap->map;

		for (int y = 0; y < pBitmap->height; ++y)
		{
			for (int x = 0; x < pBitmap->width; x+=2)
			{
				unsigned char* pPixel = pPixels + (y*pBitmap->width) + x;

				unsigned char GS_PIXEL = 0;
				GS_PIXEL = (pPixel[0] << 4) | (pPixel[1] & 0xF);
				putc(GS_PIXEL, gsfile);
			}
		}

		fclose(gsfile);
	}
	else
	{
		fprintf(stderr,"\nERROR Unable to create output file: %s\n", pFilename);
		exit(1);
	}
}

//
// Save the RawBMP Data as a PNG
//
void savePng(MYBMP *pBitmap, const char* pFilename)
{
	png_structp png_ptr;
	png_infop info_ptr;

	// PNG Stuff
	png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, (png_voidp) NULL, NULL, NULL );

	if (!png_ptr)
	{
		fprintf(stderr,"\nERROR unable to png_create_write_struct\n");
		exit(1);
	}

	info_ptr = png_create_info_struct(png_ptr);

	if (!info_ptr)
	{
		png_destroy_write_struct(&png_ptr,(png_infopp)NULL);
		fprintf(stderr,"\nERROR enable to png_create_info_struct\n");
		exit(1);
	}
			
	// Save it as a PNG
	FILE *pngfile = fopen( pFilename, "wb" );
	if (pngfile)
	{
		int idx;
		png_bytep ptr = (png_bytep) pBitmap->map;
	
		png_bytep *row_pointers = png_malloc(png_ptr, pBitmap->height * sizeof(png_bytep));
		
		png_init_io( png_ptr, pngfile );

		png_set_filter( png_ptr, 0, PNG_FILTER_NONE );

		png_set_compression_level( png_ptr, Z_BEST_COMPRESSION );

		if (256 == pBitmap->num_colors)
		{
			png_set_IHDR( png_ptr,
						  info_ptr,
						  pBitmap->width,
						  pBitmap->height,
						  8, /*bit depth*/
						  PNG_COLOR_TYPE_PALETTE,
						  PNG_INTERLACE_NONE,
						  PNG_COMPRESSION_TYPE_DEFAULT,
						  PNG_FILTER_TYPE_DEFAULT );

			png_set_PLTE( png_ptr,
						  info_ptr,
						  (png_color*)pBitmap->palette, // (palette) Array of png color
						  256 );    // (num_palette) number of color entries in palette

			for (idx = 0; idx < pBitmap->height; idx++)
			{
				row_pointers[ idx ] = ptr;
				ptr+= pBitmap->width;	
			}

			png_set_rows(png_ptr, info_ptr, row_pointers);

			png_write_png(png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);
		}

		fclose(pngfile);	
	}
	else
	{
		fprintf(stderr,"\nERROR Unable to create output file: %s\n", pFilename);
		exit(1);
	}
}


/*
 * color tables
 */

#ifdef GFXPC
static U8 RED[] = { 0x00, 0x50, 0xf0, 0xf0, 0x00, 0x50, 0xf0, 0xf0 };
static U8 GREEN[] = { 0x00, 0xf8, 0x50, 0xf8, 0x00, 0xf8, 0x50, 0xf8 };
static U8 BLUE[] = { 0x00, 0x50, 0x50, 0x50, 0x00, 0xf8, 0xf8, 0xf8 };
#endif
#ifdef GFXST
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

//
// Load the Data into the BMP
//
MYBMP* loadPic(U32* pPicData, int width, int height)
{
	MYBMP *pBitmap = (MYBMP*)malloc(sizeof(MYBMP));
	memset(pBitmap, 0, sizeof(MYBMP));

	pBitmap->width  = width;
	pBitmap->height = height;

#ifdef GFXST

	pBitmap->map = (unsigned char*) malloc(width*height);
	pBitmap->num_colors = 256;
	pBitmap->palette = (unsigned char*) malloc(256*3);

	int x; int y; int k;

	unsigned char* pMap = pBitmap->map;

	for (y = 0; y < height; ++y)
	{
		unsigned char *pB = pMap;
		for (x = 0; x < width; x+=8)
		{
			u32 v = *pPicData++;
			for (k = 8; k--; v >>=4)
			{
				pB[k] = v & 0xF;
			}
			pB+=8;
		}
		pMap += width;
	}

	// palette
	memset(pBitmap->palette, 0, 256*3);

	int pIdx = 0;
	for (int idx=0; idx < 32; ++idx)
	{
		pBitmap->palette[pIdx++] = RED[idx];
		pBitmap->palette[pIdx++] = GREEN[idx];
		pBitmap->palette[pIdx++] = BLUE[idx];
	}

#endif

	return pBitmap;
}

MYBMP* loadImage(img_t *pImage)
{
	MYBMP *pBitmap = (MYBMP*)malloc(sizeof(MYBMP));
	memset(pBitmap, 0, sizeof(MYBMP));

	int width  = pImage->w;
	int height = pImage->h;

	pBitmap->width  = width;
	pBitmap->height = height;

	pBitmap->map = (unsigned char*) pImage->pixels;
	pBitmap->num_colors = 256;
	pBitmap->palette = (unsigned char*) malloc(256*3);

	// palette
	memset(pBitmap->palette, 0, 256*3);

	U8* pPal = pBitmap->palette;

	for (int idx = 0; idx < pImage->ncolors; ++idx)
	{
		pPal[0] = pImage->colors[idx].r;
		pPal[1] = pImage->colors[idx].g;
		pPal[2] = pImage->colors[idx].b;
		pPal+=3;
	}

	return pBitmap;
}


//
// Parse command line options
//
int main(int argc, char **argv)
{
	MYBMP *pBitmap;

	// Check Arguments
	while (--argc > 0 && (*++argv)[0] == '-')
	{
		*argv+=1;
		 
		if (strcmp("v", *argv) == 0)
		{
			printf("xrick2png v%s\n", VERSION);
			exit(0);
		}
		
		*argv+= strlen(*argv); // skip rest of string
					
	}
	// At this point only one or 2 arguments left
	// unput filename, and output base name

	if (argc) _usage();

	pBitmap = loadPic( pic_haf, 0x140, 0x20 );
	savePng(pBitmap, "haf.png");
	savePixelsGS(pBitmap, "haf.gs");

	pBitmap = loadPic( pic_congrats, 0x140, 0x20 );
	savePng(pBitmap, "congrats.png");
	savePixelsGS(pBitmap, "congrats.gs");

	pBitmap = loadPic( pic_splash, 320, 200 );
	savePng(pBitmap, "splash.png");

	pBitmap = loadImage( IMG_SPLASH );
	savePng(pBitmap, "img_splash.png");

	pBitmap = loadImage( IMG_ICON );
	savePng(pBitmap, "img_icon.png");

	pBitmap = loadPic((U32*)&sprites_data[0][0], 32, 21 * 0xd6);
	savePng(pBitmap, "sprites_data.png");
	savePixelsGS(pBitmap, "sprites_data.gs");

	pBitmap = loadPic((U32*)&tiles_data[0][0], 8, 8 * 0x100);
	savePng(pBitmap, "tiles_data.png");
	savePixelsGS(pBitmap, "tiles_data.gs");


	printf("\nxrick2png - Processing complete.\n");

	exit(0);

} // main	


// eof - xrick2png.c
