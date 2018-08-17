/*****************************************************************
 *                                                               *
 *    Dc_Gif.c : Module de gestion des fichiers GIF.             *
 *                                                               *
 *****************************************************************
 *  Auteur : Olivier ZARDINI  *  CooperTeam  *  Date : Jui 2005  *
 *****************************************************************/

//#include <io.h>

#include <fcntl.h>
#include <string.h>
#include <stdio.h>
//#include <conio.h>
#include <stdlib.h>

#include "Dc_Shared.h"
#include "Dc_Graphic.h"
#include "Dc_Gif.h"

#define MAXCOLORMAPSIZE	256
#define CM_RED 0
#define CM_GREEN 1
#define CM_BLUE 2
#define MAX_LZW_BITS 12

#define INTERLACE 0x40
#define LOCALCOLORMAP 0x80
#define BitSet(byte,bit) (((byte) & (bit))==(bit))
#define LM_to_uint(a,b)	(((b)<<8)|(a))

#define BITS   12
#define HSIZE  5003            /* 80% occupancy */

#define HashTabOf(i) global->htab[i]
#define CodeTabOf(i) global->codetab[i]
#define MAXCODE(n_bits) (((code_int) 1 << (global->n_bits)) - 1)

typedef unsigned char char_type;
typedef short int code_int;	/* was int */
typedef long int count_int;
typedef unsigned char pixval;

struct global_gif
{
  int n_bits;             /* number of bits/code */
  int maxbits;            /* user settable max # bits/code */
  code_int maxcode;       /* maximum code, given n_bits */
  code_int maxmaxcode;    /* should NEVER generate this code */
  count_int htab [HSIZE];
  unsigned short codetab [HSIZE];
  code_int free_ent;  /* first unused entry */
  int Width, Height;
  int curx, cury;
  long CountDown;
  unsigned long cur_accum;
  int cur_bits;

  unsigned char *buffer;
  int g_init_bits;
  FILE* g_outfile;

  int clear_flg;

  int ClearCode;
  int EOFCode;

  int a_count;
  char accum[256];
};

static unsigned long masks[] = 
{ 
  0x0000, 0x0001, 0x0003, 0x0007, 0x000F, 0x001F, 0x003F, 0x007F, 0x00FF,
  0x01FF, 0x03FF, 0x07FF, 0x0FFF, 0x1FFF, 0x3FFF, 0x7FFF, 0xFFFF 
};

#define TRUE  1
#define FALSE 0

struct 
{
  unsigned int Width;
  unsigned int Height;
  unsigned char ColorMap[3][MAXCOLORMAPSIZE];
  unsigned int BitPixel;
  unsigned int ColorResolution;
  unsigned int BackGround;
  unsigned int AspectRatio;
} GifScreen;

struct 
{
  int transparent;
  int delayTime;
  int inputFlag;
  int disposal;
} Gif89={-1,-1,-1,0};

int ZeroDataBlock=FALSE;

static int ReadColorMap(FILE *, int,unsigned char [3][MAXCOLORMAPSIZE]);
static int DoExtension(FILE *,int);
static int GetDataBlock(FILE *,unsigned char *);
static int GetCode(FILE *,int,int);
static int LZWReadByte(FILE *,int,int);
static int ReadImage(FILE *,unsigned char *,int,int,unsigned char [3][MAXCOLORMAPSIZE],int);
static void Putword(int,FILE *);
static void compress(int,FILE *,struct global_gif *);
static void cl_hash(register count_int,struct global_gif *);
static void output(code_int,struct global_gif *);
static void cl_block(struct global_gif *);
static void flush_char(struct global_gif *);

/**************************************************************************/
/*  GIFWriteFileFrom256Color() :  Création d'une image GIF 256 couleurs.  */
/**************************************************************************/
int GIFWriteFileFrom256Color(char *file_path, struct picture_256 *current_picture_256)
{
  FILE *fp;
  int B;
  int RWidth, RHeight;
  int LeftOfs, TopOfs;
  int Resolution;
  int ColorMapSize;
  int InitCodeSize;
  int i;
  int BitsPerPixel = 8;
  struct global_gif global;

  /* Init des variables 'globales' */
  memset(&global,0,sizeof(struct global_gif));
  global.maxbits = BITS;
  global.maxmaxcode = (code_int)1 << BITS;

  /* Création du fichier */
  fp = fopen(file_path,"wb");
  if(fp == NULL)
    {
      return(1);
    }

  /* Valeurs de l'entête */
  ColorMapSize = 1 << BitsPerPixel;
  global.buffer = current_picture_256->data;
  RWidth = global.Width = current_picture_256->width;
  RHeight = global.Height = current_picture_256->height;
  LeftOfs = TopOfs = 0;
  global.cur_accum = 0;
  global.cur_bits = 0;
  Resolution = BitsPerPixel;
  global.CountDown = (long)global.Width * (long)global.Height;
  InitCodeSize = (BitsPerPixel <= 1) ? 2 : BitsPerPixel;
  global.curx = global.cury = 0;

  /* Ecriture de l'entête */
  fwrite("GIF87a",1,6,fp);
  Putword(RWidth,fp);
  Putword(RHeight,fp);

  B=0x80;
  B |=(Resolution -1) << 5;
  B |=(BitsPerPixel - 1);
  fputc(B,fp);

  /* Couleur de fond = 0 */
  fputc(0,fp);
  fputc(0,fp);
  for(i=0; i<ColorMapSize; ++i)
    {
      fputc(current_picture_256->palette_red[i],fp);
      fputc(current_picture_256->palette_green[i],fp);
      fputc(current_picture_256->palette_blue[i],fp);
    }

  fputc(',',fp);
  Putword(LeftOfs,fp);
  Putword(TopOfs,fp);
  Putword(global.Width,fp);
  Putword(global.Height,fp);
  fputc(0x00,fp);

  /* Taille des données initale */
  fputc(InitCodeSize,fp);

  /* Compression des données */
  compress(InitCodeSize+1,fp,&global);

  /* Un zéro pour finir la série */
  fputc(0,fp);

  /* On place le terminateur */
  fputc(';',fp);

  /* Fermeture du fichier */
  fclose(fp);

  return(0);
}


/***************************************************************************/
/*  GIFReadFileToRGB() : Ouverture / Décompression d'une image GIF -> RGB. */
/***************************************************************************/
struct picture_true *GIFReadFileToRGB(char *path)
{
  int error;
  unsigned char *bigBuf;
  unsigned char buffer[16];
  unsigned char c;
  unsigned char localColorMap[3][MAXCOLORMAPSIZE];
  int useGlobalColormap;
  int bitPixel;
//  int imageCount=0;
  char version[4];
  FILE *fd;
  int nb_read;
  int width=0;
  int height=0;
  long bufsize;
  struct picture_true *current_picture;

  /* Ouverture du fichier GIF */
  fd=fopen(path,"rb");
  if(fd == NULL)
    return(NULL);

  /** Lecture de la signature "GIF" **/
  nb_read = fread(buffer,1,6,fd);
  if(nb_read != 6)
    {
      fclose(fd);
      return(NULL);
    }
  if(strncmp((char *)buffer,"GIF",3))
    {
      fclose(fd);
      return(NULL);
    }	

  /** Analyse de la version (87a/89a) **/
  strncpy(version,(char *)&buffer[3],3);
  version[3]='\0';
  if(strcmp(version,"87a") && strcmp(version,"89a")) 
    {
      fclose(fd);
      return(NULL);
    }	

  /* Récupération des valeurs de l'entête */
  nb_read = fread(buffer,1,7,fd);
  if(nb_read != 7)
    {
      fclose(fd);
      return(NULL);
    }
  GifScreen.Width = LM_to_uint(buffer[0],buffer[1]);
  GifScreen.Height = LM_to_uint(buffer[2],buffer[3]);
  GifScreen.BitPixel = 2 << (buffer[4] & 0x07);
  GifScreen.ColorResolution = (((buffer[4] & 0x70) >> 3) + 1);
  GifScreen.BackGround = buffer[5];
  GifScreen.AspectRatio = buffer[6];

  /* Récupération de la palette (si elle est présente) */
  if(BitSet(buffer[4],LOCALCOLORMAP))
    {
      error = ReadColorMap(fd,GifScreen.BitPixel,GifScreen.ColorMap);
      if(error)
        {
          fclose(fd);
          return(NULL);                                             
        }
    }

  /** On ne traite que la première des images du fichier **/
  for(;;)
    {	
      /* Lecture du TAG */
      nb_read = fread(&c,1,1,fd);
      if(nb_read != 1)
        {
          fclose(fd);
          return(NULL);
        }
	
      if(c == '!')
        {
          nb_read = fread(&c,1,1,fd);
          if(nb_read != 1)
            {
              fclose(fd);
              return(NULL);
            }
          DoExtension(fd,c);
          continue;
        }
	
      if(c != ',')
        continue;

      /* read image header */
      nb_read = fread(buffer,1,9,fd);
      if(nb_read != 9)
        {
          fclose(fd);
          return(NULL);
        }
	
      useGlobalColormap = !BitSet(buffer[8],LOCALCOLORMAP);
      bitPixel = 1<<((buffer[8]&0x07)+1);

      /** On récupère la taille de l'image **/
      width = LM_to_uint(buffer[4],buffer[5]);
      height = LM_to_uint(buffer[6],buffer[7]);		
      if(width <= 0 || height <= 0)
        {
          fclose(fd);
          return(NULL);
        }
      
      /* Allocation mémoire */
      bufsize = width*height*3;
      bigBuf = (unsigned char *) calloc(bufsize,1);
      if(bigBuf == NULL)
        {
          fclose(fd);
          return(NULL);
        }

      /** Utilisation d'une palette locale ? **/
      if(!useGlobalColormap)
        {
          /* Lecture de la palette locale */
          error = ReadColorMap(fd,bitPixel,localColorMap);
          if(error)
            {
              free(bigBuf);
              fclose(fd);
              return(NULL);
            }

          /* Lecture des points */
          error = ReadImage(fd,bigBuf,width,height,localColorMap,BitSet(buffer[8],INTERLACE));
          if(error)
            {
              free(bigBuf);
              fclose(fd);
              return(NULL);
            }
        }
      else
        {
          /* Lecture des points */
          error = ReadImage(fd,bigBuf,width,height,GifScreen.ColorMap,BitSet(buffer[8],INTERLACE));
          if(error)
            {
              free(bigBuf);
              fclose(fd);
              return(NULL);
            }
        }
      break;
    }

  /* Fermeture du fichier */
  fclose(fd);

  /** On retourne l'image dans une structure **/
  current_picture = (struct picture_true *) calloc(1,sizeof(struct picture_true));
  if(current_picture == NULL)
    {
      free(bigBuf);
      return(NULL);
    }
  current_picture->height = height;
  current_picture->width = width;
  current_picture->data = bigBuf;

  /* OK */
  return(current_picture);
}


/************************************************************************************/
/*  GIFReadFileToRGB() : Ouverture / Décompression d'une image GIF -> 256 couleurs. */
/************************************************************************************/
struct picture_256 *GIFReadFileTo256Color(char *file_path)
{
  struct picture_true *current_picture_true;
  struct picture_256 *current_picture_256;

  /** Chargement de l'image en True Color **/
  current_picture_true = GIFReadFileToRGB(file_path);
  if(current_picture_true == NULL)
    return(NULL);

  /** Conversion en 256 Couleurs **/
  current_picture_256 = ConvertTrueColorTo256(current_picture_true);

  /* Libération mémoire */
  mem_free_picture_true(current_picture_true);

  /* Renvoie l'image */
  return(current_picture_256);
}


/************************************************************************/
/*  ReadColorMap()  													*/
/************************************************************************/
static int ReadColorMap(FILE *fd, int number, unsigned char buffer[3][MAXCOLORMAPSIZE])
{
  int i;
  int nb_read;
  unsigned char rgb[3*MAXCOLORMAPSIZE];

  /* Lecture de la palette */
  nb_read = fread(rgb,3,number,fd);
  if(nb_read != number)
    return(1);

  /* On place les compasantes RVB */
  for(i=0; i<number; i++)
    {
      buffer[CM_RED][i]=rgb[i*3+0];
      buffer[CM_GREEN][i]=rgb[i*3+1];
      buffer[CM_BLUE][i]=rgb[i*3+2];
	}

  return(0);
}


/********************************************************************/
/*  																*/
/********************************************************************/
static int DoExtension(FILE *fd, int label)
{
  static char buffer[256];

  switch(label)
    {
      case 0x01 :
        break;
      case 0xff :
        break;
      case 0xfe :
        while(GetDataBlock(fd,(unsigned char *)buffer)!=0);
        return(FALSE);
        break;
      case 0XF9 :
        GetDataBlock(fd,(unsigned char *)buffer);
        Gif89.disposal = (buffer[0]>>2)&0x7;
        Gif89.inputFlag = (buffer[0]>>1)&0x1;
        Gif89.delayTime = LM_to_uint(buffer[1],buffer[2]);
        if((buffer[0]&0x1)!=0)
          Gif89.transparent=buffer[3];

        while(GetDataBlock(fd,(unsigned char *)buffer)!=0);
        return(FALSE);
        break;
      default :
        sprintf(buffer,"UNKNOWN (0x%02x)",label);
        break;
    }
	
  while(GetDataBlock(fd,(unsigned char *)buffer)!=0);

  return(FALSE);
}


/*************************************************************/
/*  														 */
/*************************************************************/
static int GetDataBlock(FILE *fd, unsigned char *buffer)
{
  int nb_read;
  unsigned char count;

  nb_read = fread(&count,1,1,fd);
  if(nb_read != 1)
    return(-1);

  ZeroDataBlock=count==0;

  if((count != 0) && (fread(buffer,1,count,fd) != count))
    return(-1);

  return(count);
}


/*********************************************************************/
/*  																 */
/*********************************************************************/
static int GetCode(FILE *fd, int code_size, int flag)
{
  static unsigned char buf[280];
  static int curbit, lastbit, done, last_byte;
  int i,j,ret;
  unsigned char count;

  if(flag)
    {
      curbit=0;
      lastbit=0;
      done=FALSE;
      return(0);
    }

  if((curbit+code_size) >=lastbit)
    {
      if(done)
        {
          if(curbit >=lastbit)
            return(0);
          return(-1);
        }
      buf[0]=buf[last_byte-2];
      buf[1]=buf[last_byte-1];

      if((count=GetDataBlock(fd,&buf[2]))==0)
        done=TRUE;

      last_byte = 2+count;

      curbit = (curbit - lastbit) + 16;

      lastbit = (2+count)*8;
    }
  ret=0;
  for(i=curbit,j=0; j<code_size; i++,j++)
    ret |= ((buf[i/8]&(1<<(i% 8)))!=0)<<j;

  curbit += code_size;

  return(ret);
}


/**************************************************************************/
/*  ReadImage() 														  */
/**************************************************************************/
static int ReadImage(FILE *fd, unsigned char* bigMemBuf,int width, int height,
                     unsigned char cmap[3][MAXCOLORMAPSIZE], int interlace)
{
  unsigned char c;
  int color;
  int nb_read;
  int xpos=0, ypos=0, pass=0;
  long curidx;

  nb_read = fread(&c,1,1,fd);
  if(nb_read != 1)
    return(1);

  if(LZWReadByte(fd,TRUE,c)<0)
    return(1);
	
  while((color=LZWReadByte(fd,FALSE,c))>=0)
    {
      curidx= (xpos + ypos*width)*3;
        
      *(bigMemBuf+curidx) = cmap[0][color];
      *(bigMemBuf+curidx+1) = cmap[1][color];
      *(bigMemBuf+curidx+2) = cmap[2][color];				

      xpos++;
      if(xpos==width)
        {
          xpos=0;
          if(interlace)
            {
              switch(pass)
                {
                  case 0:
                  case 1:
                    ypos += 8;
                    break;
                  case 2:
                    ypos += 4;
                    break;
                  case 3:
                    ypos += 2;
                    break;
                }

              if(ypos>=height)
                {
                  pass++;
                  switch(pass)
                    {
                      case 1:
                        ypos=4;
                        break;
                      case 2:
                        ypos=2;
                        break;
                      case 3:
                        ypos=1;
                        break;
                      default :
                        LZWReadByte(fd,FALSE,c);
                        return(0);
                    }
                }
            }
          else
            ypos++;
        }

      if(ypos >= height)
        break;
    }

  LZWReadByte(fd,FALSE,c);
  return(0);
}


/*********************************************************************/
/*  LZWReadByte()   												 */
/*********************************************************************/
static int LZWReadByte(FILE *fd, int flag, int input_code_size)
{
  static int fresh=FALSE;
  int code, incode;
  static int code_size, set_code_size;
  static int max_code, max_code_size;
  static int firstcode, oldcode;
  static int clear_code, end_code;

  static unsigned short next[1<<MAX_LZW_BITS];
  static unsigned char vals[1<<MAX_LZW_BITS];
  static unsigned char stack[1<<(MAX_LZW_BITS+1)];
  static unsigned char *sp;

  register int i;

  if(flag)
    {
      set_code_size=input_code_size;
      code_size=set_code_size+1;
      clear_code=1<<set_code_size;
      end_code = clear_code+1;
      max_code = clear_code+2;
      max_code_size=2*clear_code;

      GetCode(fd,0,TRUE);

      fresh=TRUE;

      for(i=0; i<clear_code; i++)
        {
          next[i]=0;
          vals[i]=i;
        }

      for(; i<(1<<MAX_LZW_BITS); i++)
        next[i]=vals[0]=0;
	
      sp=stack;

      return(0);
    } 
  else if(fresh)
    {
      fresh=FALSE;
      do{
          firstcode=oldcode=GetCode(fd,code_size,FALSE);
        } while(firstcode==clear_code);
      return(firstcode);
    }

  if(sp > stack)
    return(*--sp);

  while((code= GetCode(fd,code_size,FALSE)) >=0)
    {
      if(code==clear_code)
        {
          for(i=0; i<clear_code; i++)
            {
              next[i]=0;
              vals[i]=i;
            }
          for(; i<(1<<MAX_LZW_BITS); i++)	
            next[i]=vals[i]=0;
          code_size=set_code_size+1;
          max_code_size=2*clear_code;
          max_code=clear_code+2;
          sp=stack;
          firstcode=oldcode=GetCode(fd,code_size,FALSE);
          return(firstcode);
        } 
      else if(code == end_code)
        {
          int count;
          unsigned char buf[260];

          if(ZeroDataBlock)
            return(-2);

          while((count=GetDataBlock(fd,buf)) >0);
          if(count!=0)
            return(-2);
        }

      incode = code;

      if(code >= max_code)
        {
          *sp++=firstcode;
          code=oldcode;
        }

      while(code >= clear_code)
        {
          *sp++=vals[code];
          if(code==(int)next[code])
            return(-1);
          code=next[code];
        }

      *sp++ = firstcode=vals[code];

      if((code=max_code) < (1<<MAX_LZW_BITS))
        {
          next[code]=oldcode;
          vals[code]=firstcode;
          max_code++;

          if((max_code >= max_code_size) &&
             (max_code_size < (1<<MAX_LZW_BITS)))
            {
              max_code_size*=2;
              code_size++;
            }
        }

      oldcode=incode;

      if(sp > stack)
        return *--sp;
    }
  return(code);
}

static void Putword(int w, FILE *fp)
{
  fputc(w & 0xff,fp);
  fputc((w / 256) & 0xff,fp);
}


static void compress(int init_bits, FILE *outfile, struct global_gif *global)
{
  register long fcode;
  register code_int i /* = 0 */;
  register int c;
  register code_int ent;
  register code_int disp;
  register int hshift;

  /*
   * Set up the globals:  g_init_bits - initial number of bits
   *                      g_outfile   - pointer to output file
   */
  global->g_init_bits = init_bits;
  global->g_outfile = outfile;

  /* Set up the necessary values */
  global->clear_flg = 0;
  global->maxcode = MAXCODE(n_bits = global->g_init_bits);

  global->ClearCode = (1 << (init_bits - 1));
  global->EOFCode = global->ClearCode + 1;
  global->free_ent = global->ClearCode + 2;

  /* Char Init */
  global->a_count=0;

  /** Next Pixel **/
  if(global->CountDown == 0)
    ent = EOF;
  else
    {
      global->CountDown--;
      ent = *(global->buffer + global->curx + global->cury*global->Width);

      /* Bump the current X position */
      global->curx++;
      if(global->curx == global->Width)
        {
          global->curx = 0;
          global->cury++;
        }
    }

  hshift = 0;
  for(fcode = (long) HSIZE; fcode < 65536L; fcode *= 2L)
    ++hshift;
  hshift = 8 - hshift;                /* set hash code range bound */

  cl_hash((count_int) HSIZE,global);            /* clear hash table */

  output((code_int)global->ClearCode,global);

  while(1)
    {
      /** Next Pixel **/
      if(global->CountDown == 0)
        break;
      else
        {
          global->CountDown--;
          c = *(global->buffer + global->curx + global->cury*global->Width);

          /* Bump the current X position */
          global->curx++;
          if(global->curx == global->Width)
            {
              global->curx = 0;
              global->cury++;
            }
        }

      fcode = (long) (((long) c << global->maxbits) + ent);
      i = (((code_int)c << hshift) ^ ent);    /* xor hashing */

      if(HashTabOf(i) == fcode)
        {
          ent = CodeTabOf(i);
          continue;
        }
      else if((long)HashTabOf (i) < 0)      /* empty slot */
        goto nomatch;
      disp = HSIZE - i;           /* secondary hash (after G. Knott) */
      if(i == 0)
        disp = 1;
probe:
      if((i -= disp) < 0)
        i += HSIZE;

      if(HashTabOf(i) == fcode)
        {
          ent = CodeTabOf(i);
          continue;
        }
      if((long)HashTabOf(i) > 0)
        goto probe;
nomatch:
      /**************/
      /**  Output  **/
      global->cur_accum &= masks[global->cur_bits];

      if(global->cur_bits > 0)
        global->cur_accum |= ((long)((code_int)ent) << global->cur_bits);
      else
        global->cur_accum = (code_int) ent;
      global->cur_bits += global->n_bits;

      while(global->cur_bits >= 8)
        {
          /* Char Out */
          global->accum[global->a_count++] = (unsigned int)(global->cur_accum & 0xff);
          if(global->a_count >=254)
            flush_char(global);

          global->cur_accum >>= 8;
          global->cur_bits -= 8;
        }

      /* If the next entry is going to be too big for the code size, */
      /* then increase it, if possible. */
      if(global->free_ent > global->maxcode || global->clear_flg)
        {
          if(global->clear_flg)
            {
              global->maxcode = MAXCODE (n_bits = global->g_init_bits);
              global->clear_flg = 0;
            } 
          else
            {
              ++global->n_bits;
              if(global->n_bits == global->maxbits)
                global->maxcode = global->maxmaxcode;
              else
                global->maxcode = MAXCODE(n_bits);
            }
        }
	
      if(((code_int) ent) == global->EOFCode)
        {
          /* At EOF, write the rest of the buffer. */
          while(global->cur_bits > 0)
            {
              /* Char Out */
              global->accum[global->a_count++] = (unsigned int)(global->cur_accum & 0xff);
              if(global->a_count >=254)
                flush_char(global);

              global->cur_accum >>= 8;
              global->cur_bits -= 8;
            }

          flush_char(global);
          fflush(global->g_outfile);	
        }

      ent = c;
      if(global->free_ent < global->maxmaxcode)
        {
          CodeTabOf(i) = global->free_ent++; /* code -> hashtable */
          HashTabOf(i) = fcode;
        } 
      else
        cl_block(global);
    }

  /* Put out the final code. */
  output((code_int)ent,global);
  output((code_int)global->EOFCode,global);
}


static void output(code_int code, struct global_gif *global)
{
  global->cur_accum &= masks[ global->cur_bits ];

  if(global->cur_bits > 0)
    global->cur_accum |= ((long)code << global->cur_bits);
  else
    global->cur_accum = code;

  global->cur_bits += global->n_bits;

  while(global->cur_bits >= 8)
    {
      /* Char Out */
      global->accum[global->a_count++] = (unsigned int)(global->cur_accum & 0xff);
      if(global->a_count >=254)
        flush_char(global);

      global->cur_accum >>= 8;
      global->cur_bits -= 8;
    }

  /*
   * If the next entry is going to be too big for the code size,
   * then increase it, if possible.
   */
  if(global->free_ent > global->maxcode || global->clear_flg)
    {
      if(global->clear_flg)
        {
          global->maxcode = MAXCODE (n_bits = global->g_init_bits);
          global->clear_flg = 0;
        } 
      else
        {
          ++global->n_bits;
          if(global->n_bits == global->maxbits)
            global->maxcode = global->maxmaxcode;
          else
            global->maxcode = MAXCODE(n_bits);
        }
    }
	
  if(code == global->EOFCode)
    {
      /* At EOF, write the rest of the buffer. */
      while(global->cur_bits > 0)
        {
          /* Char Out */
          global->accum[global->a_count++] = (unsigned int)(global->cur_accum & 0xff);
          if(global->a_count >=254)
            flush_char(global);

          global->cur_accum >>= 8;
          global->cur_bits -= 8;
        }

      flush_char(global);
      fflush(global->g_outfile);	
    }
}


static void cl_block(struct global_gif *global)
{
  cl_hash((count_int)HSIZE,global);
  global->free_ent=global->ClearCode+2;
  global->clear_flg=1;

  output((code_int)global->ClearCode,global);
}


static void cl_hash(register count_int hsize, struct global_gif *global)
{
  register count_int *htab_p = global->htab+hsize;

  register long i;
  register long m1 = -1L;

  i = hsize - 16;

  do{
      *(htab_p-16) = m1;
      *(htab_p-15) = m1;
      *(htab_p-14) = m1;
      *(htab_p-13) = m1;
      *(htab_p-12) = m1;
      *(htab_p-11) = m1;
      *(htab_p-10) = m1;
      *(htab_p-9) = m1;
      *(htab_p-8) = m1;
      *(htab_p-7) = m1;
      *(htab_p-6) = m1;
      *(htab_p-5) = m1;
      *(htab_p-4) = m1;
      *(htab_p-3) = m1;
      *(htab_p-2) = m1;
      *(htab_p-1) = m1;

      htab_p-=16;
	} while((i-=16) >=0);

  for(i+=16; i>0; i--)
    *--htab_p=m1;
}


static void flush_char(struct global_gif *global)
{
  if(global->a_count > 0)
    {
      fputc(global->a_count,global->g_outfile);
      fwrite(global->accum,1,global->a_count,global->g_outfile);
      global->a_count=0;
    }
}

/**************************************************************************/
