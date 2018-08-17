/*****************************************************************
 *                                                               *
 *    Dc_Gif.h : Header de gestion des fichiers GIF.             *
 *                                                               *
 *****************************************************************
 *  Auteur : Olivier ZARDINI  *  CooperTeam  *  Date : Jui 2005  *
 *****************************************************************/

#define GR_ERR_NOERROR           0
#define GR_ERR_MEMORY        (-100)
#define GR_ERR_BADFORMAT     (-160)
#define GR_ERR_OPENFILE      (-210)

struct picture_true *GIFReadFileToRGB(char *);
struct picture_256 *GIFReadFileTo256Color(char *);
int GIFWriteFileFrom256Color(char *,struct picture_256 *);

/****************************************************************/