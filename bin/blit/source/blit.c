/*
#--------------------------------------------------------
# $File: blit.c,v $          
#--------------------------------------------------------
*/


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#include "bctypes.h"
#include "blit.h"
#include "rawdata.h"

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

//
// Call it with A = 0
// And the S set to the DPage Table in memory
//
void CompileBlockTRB(RAWDATA *result, int x, int width)
{
	int clocks = 0;

	//clocks += AddLine("","TCD","       ; Set DP ",0,2);
	//clocks += AddLine("","TXA","       ; Zero out A", 0,2);
	clocks += AddLine("","PLD","       ; Set DP", 0,4);


	for (int y = 0; y < 8; ++y)
	{
		int p = y * 160;

		//for (int xs = x; xs < (x+width) ; xs+=4)
		for (int xs = 0; xs < 320; xs+=4)
		{
			int xbyte = (xs>>1) + p;

			if ((0 == (xbyte&0xFF)) && y)
			{
				clocks += AddLine("","PLD","       ; Set DP", 0,4);

				//clocks += AddLine("","TDC","       ; Set DP ",0,2);
				//clocks += AddLine("","ADC","#$100",0,3);
				//clocks += AddLine("","TCD","       ; Set DP ",0,2);
				//clocks += AddLine("","TXA","       ; Zero out A", 0,2);
			}

			if ((xs>=x)&&(xs<(x+width)))
			{
				clocks += AddLine("","TRB","$%02X",xbyte&0xFF,7);
			}
		}
	}

//	clocks += AddLine("","RTL"," ;%d cycles",clocks+6,6);
	clocks += AddLine("","JMP","BRET   ;%d cycles",clocks+3,3);
}

RAWDATA* CompileTRB()
{
	RAWDATA* result = (RAWDATA*)malloc(sizeof(RAWDATA));
	memset(result, 0, sizeof(RAWDATA));

	char temp_label[256];

	gResult = result;

	int screen_width = 320;
	int width = 320;
	int pixel_step = 8; 	// x position granularity
	int pixel_block = 8;   // min width

	while (width >= pixel_block)
	{
		for (int x = 0; x <= (screen_width - width); x+=pixel_step)
		{
			printf(temp_label,"blit%d_%d\n", x, width);
			sprintf(temp_label,"blit%d_%d\n", x, width);
			AddString(result, temp_label);
			CompileBlockTRB(result, x, width);
		}
		width -= pixel_block;
	}

	return result;
}


//A = ADC(A,delta,C);
int ADC(int A, int delta, int* C)
{
	u32 uA = A &0xFFFF;
	u32 uD = delta&0xFFFF;

	int result = A + delta + *C;

	u32 uResult = uA+uD+*C;

	*C = (uResult>>16) & 1;

	return result;
}


/*
    	lda #$2000
    	tcd
    	lda #$20FF
    	tcs
    	pei $fe
    	pei $fc
    	pei $f8
    	....
    	....
    	pei $02
    	pei $00
    	inc
    	tcd
    	adc #$FF
    	tcs
    	..........
 
    	For regions less than the page width, go line by line
 
    	call with X
 
*/
void CompileBlockPEI(RAWDATA *result, int x, int width)
{
	int clocks = 0;
	int A = 0;  	 // What's in the accumulator
	int C = 0;

	clocks += AddLine("","TCD","       ; Set DP $%04X",A,2);
	clocks += AddLine("","ADC","#%d",((x+width)>>1)-1,3);
	A+=((x+width)>>1)-1;
	int S=A;
	clocks += AddLine("","TCS","       ; Set S  $%04X",A,2);

	int dp = 0;

	for (int y = 0; y < 8; ++y)
	{
		int p = y * 160;

		for (int xs = 316; xs >= 0; xs-=4)
		{
			int xbyte = (xs>>1) + p;

			if ((xs>=x)&&(xs<(x+width)))
			{
				if ((dp & 0xFF00) != (xbyte & 0xFF00))
				{
					int delta = (xbyte&0xFF00) - (A+C); //(dp & 0xFF00);

					A = ADC(A,delta,&C);

					clocks += AddLine("","ADC","#%d",delta,3);
					clocks += AddLine("","TCD","       ; Set DP $%04X",A,2);
				}
				clocks += AddLine("", "PEI", "$%02X", xbyte & 0xFF, 6);
				dp = xbyte;
			}
		}

		if (y < 7)
		{
			S+=160;
			int delta = S - (A+C);

			A = ADC(A,delta,&C);

			clocks += AddLine("", "ADC", "#%d", delta, 3);
			clocks += AddLine("","TCS","       ; Set S  $%04X",A,2);
		}
	}

//	clocks += AddLine("","RTL"," ;%d cycles",clocks+6,6);
	clocks += AddLine("","JMP","BRET   ;%d cycles",clocks+3,3);
}

RAWDATA* CompilePEI()
{
	RAWDATA* result = (RAWDATA*)malloc(sizeof(RAWDATA));
	memset(result, 0, sizeof(RAWDATA));

	char temp_label[256];

	gResult = result;

	int screen_width = 320;
	int width = 320;
	int pixel_step = 8; 	// x position granularity
	int pixel_block = 8;   // min width

	while (width >= pixel_block)
	{
		for (int x = 0; x <= (screen_width - width); x+=pixel_step)
		{
			printf(temp_label,"blit%d_%d\n", x, width);
			sprintf(temp_label,"blit%d_%d\n", x, width);
			AddString(result, temp_label);
			CompileBlockPEI(result, x, width);
		}
		width -= pixel_block;
	}

	return result;
}


static void _usage()
{
	printf("blit v%s\n\n", VERSION);
	printf("Usage:  blit\n"
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
			printf("blit v%s\n", VERSION);
			exit(0);
		}
		
		*argv+= strlen(*argv); // skip rest of string
	}

	if (argc) _usage();

	RAWDATA* pBlitTRB = CompileTRB();
	saveRaw(pBlitTRB, "trb.txt");

	RAWDATA* pBlitPEI = CompilePEI();
	saveRaw(pBlitPEI, "pei.txt");

	printf("\nblit - Processing complete.\n");

	exit(0);

} // main	

// eof - blit.c

