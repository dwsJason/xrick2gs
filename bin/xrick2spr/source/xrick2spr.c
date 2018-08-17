/*
#--------------------------------------------------------
# $File: xrick2spr.c,v $          
#--------------------------------------------------------
*/


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "bctypes.h"
#include "xrick2spr.h"
#include "rawdata.h"

u16 GetBest16(unsigned char* pFrame, int width, int height)
{
	return 0;
}

void EncodePixel(unsigned char* pFrame, int width, int height, u16 pixel)
{
}

int CompileSprite(unsigned char* pFrame, int widthPixels, int heightPixels)
{
	int width  = (widthPixels+1)>>1;
	int height = heightPixels;

	// Make a copy of the frame, so that I can write back into it
	// While I'm at it expand the frame width by 4 pixels
	int srcWidth = width;
	width += 2;
	int sizeBytes = width * height;
	unsigned char *pSrc = (unsigned char*)malloc(sizeBytes);
	memset(pSrc,0, sizeBytes);

	// Copy 1 line at a time
	for (int y=0; y < height; ++y)
	{
		u8* pS = pFrame + (y*srcWidth);
		u8* pD = pSrc + (y*width);
		memcpy(pD,pS, srcWidth);
	}

	while (1)
	{
		u16 pixel = GetBest16(pSrc, width, height);

		if (pixel)
		{
			EncodePixel(pSrc, width, height, pixel);
		}
		else
		{
			break;
		}
	}

	return 0;
}

RAWDATA* gResult = NULL;

void AddString(RAWDATA* pRaw, char* pString)
{
	size_t len = strlen(pString);

	size_t newlen = len+pRaw->size;

	pRaw->data = (unsigned char*) realloc(pRaw->data, newlen);

	memcpy(pRaw->data + pRaw->size, pString, len);

	pRaw->size = newlen;
}

int AddLine(char*pLabel,char*pInst,char*pExp,int val,int clocks)
{
	if (gResult)
	{
		char temp[256];
		char pArg[256];

		memset(pArg,0,256);
		sprintf(pArg,pExp,val);

		sprintf(temp, "%8s %3s %s\n", pLabel,pInst,pArg);

		AddString(gResult, temp);
	}

	return clocks;
}

void CompileTile(RAWDATA *result, u8* pTile)
{
static int offsets[16] =
{
	(160 * 0) + 0, (160 * 0) + 2,
	(160 * 1) + 0, (160 * 1) + 2,
	(160 * 2) + 0, (160 * 2) + 2,
	(160 * 3) + 0, (160 * 3) + 2,
	(160 * 4) + 0, (160 * 4) + 2,
	(160 * 5) + 0, (160 * 5) + 2,
	(160 * 6) + 0, (160 * 6) + 2,
	(160 * 7) + 0, (160 * 7) + 2
};
	int clocks = 0;
	u16 *pData = (u16*) pTile;

	bool slots[16];

	memset(slots, 0, sizeof(bool) * 16);

	bool done = false;

	while (!done)
	{
		u16 pixel = 0;
		done = true;
		 
		// Load a cached Pixel
		for (int idx = 0; idx < 16; ++idx)
		{
			if (slots[idx])
				continue;

			done = false;
			pixel = pData[idx];
			clocks += AddLine("","LDA","#$%04X",pixel,3);
			break;
		}

		for (int outIdx = 0; outIdx < 16; ++outIdx)
		{
			if (slots[outIdx])
				continue;

			if (pixel == pData[outIdx])
			{
				clocks += AddLine("","STA","$%04X,Y",offsets[outIdx],6);
				slots[outIdx] = true;
			}
		}
	}

	clocks += AddLine("","RTL"," ;%d cycles",clocks+6,6);
}

RAWDATA* CompileTiles(RAWDATA* pTilesData, int bank)
{
	RAWDATA* result = (RAWDATA*)malloc(sizeof(RAWDATA));
	memset(result, 0, sizeof(RAWDATA));

	gResult = result;

	char temp_label[256];

	for (int tileNo = 0; tileNo < 256; ++tileNo)
	{
		sprintf(temp_label,"tile%d_%d\n", bank, tileNo);
		AddString(result, temp_label);
		CompileTile(result, &pTilesData->data[ tileNo * 32 ]);
	}

	return result;
}

static void _usage()
{
	printf("xrick2spr v%s\n\n", VERSION);
	printf("Usage:  xrick2spr\n"
		   "Written by Jason Andersen\n"
		   "Copyright (c) 2018 Jason Andersen.\n"
		   "Unauthorized use prohibited\n");

		   exit(1);

} // usage	


//
// Parse command line options
//
int main(int argc, char **argv)
{
	// Check Arguments
	while (--argc > 0 && (*++argv)[0] == '-')
	{
		*argv+=1;
		 
		if (strcmp("v", *argv) == 0)
		{
			printf("xrick2spr v%s\n", VERSION);
			exit(0);
		}
		
		*argv+= strlen(*argv); // skip rest of string
	}

	if (argc) _usage();

	#if 0
	RAWDATA* pData = loadRaw("sprites_data.gs");

	if (pData)
	{
		// each frame 32 * 21 pixels, 0xd6 frames
		//printf("%d %d\n", 16*21*0xd6, (int)pData->size);
		const int FRAMESIZE = 16*21;
		unsigned char* pFrame = pData->data;

		for (int frameIdx = 0; frameIdx < 0xd6; ++frameIdx)
		{
			int bytes = CompileSprite(pFrame, 32, 21);
			pFrame += FRAMESIZE;

			printf("Frame %d = %d bytes\n", frameIdx, bytes);
		}
	}
	#endif

	RAWDATA* pData = loadRaw("tiles_data0.gs");
	RAWDATA* pSource = CompileTiles(pData,0);
	saveRaw(pSource, "tiles_data0.txt");

	pData   = loadRaw("tiles_data1.gs");
	pSource = CompileTiles(pData,1);
	saveRaw(pSource, "tiles_data1.txt");

	pData   = loadRaw("tiles_data2.gs");
	pSource = CompileTiles(pData,2);
	saveRaw(pSource, "tiles_data2.txt");;

	printf("\nxrick2spr - Processing complete.\n");

	exit(0);

} // main	


// eof - xrick2png.c

