/********************************************************************
 *                                                                  *
 *    Dc_Graphic.h : Header de gestion des fichiers Graphiques.     *
 *                                                                  *
 ********************************************************************
 *  Auteur : Olivier ZARDINI  *  Brutal Deluxe  *  Date : Nov 2012  *
 ********************************************************************/

#define TOO_MANY_COLOR          1
#define ERR_GRAPHIC_FOPEN       2
#define ERR_ALLOC               3
#define ERR_GRAPHIC_BADFORMAT   4
#define ERR_GRAPHIC_WRITEFILE   5

struct picture_256
{
  int width;
  int height;

  int nb_color;
  int palette_red[256];
  int palette_green[256];
  int palette_blue[256];

  unsigned char *data;

  /* Stat */
  int *tab_nb_color;     /* Nombre de couleur sur la ligne */
  int *tab_color_line;   /* Nombre de points utilisant chaque couleur */
};

struct picture_true
{
  int width;
  int height;

  unsigned char *data;
};

DWORD DecodeRGBColor(char *);
int ExtractAllSprite(char *,DWORD,DWORD);
int CreateMirrorPicture(char *,DWORD);
int CreateFlipPicture(char *,DWORD);
int CreateOddPicture(char *,DWORD);
int RemoveDuplicatedPictures(int,char **);
int CreateWallPaper(int,char **,DWORD,DWORD);
int CreateSpriteCode(char *,DWORD,int,DWORD *,int);
int Compute8BitColors(int,int,int,unsigned char *,int *);
struct picture_256 *ConvertTrueColorTo256(struct picture_true *);
void PlotTrueColor(int,int,unsigned char,unsigned char,unsigned char,struct picture_true *);
int PlotNumber(int,int,int,unsigned char,unsigned char,unsigned char,struct picture_true *);
struct picture_256 *CreateEmptyPicture(int,int,int,int *,int *,int *,unsigned char);
void mem_free_picture_256(struct picture_256 *);
void mem_free_picture_true(struct picture_true *);

/********************************************************************/
