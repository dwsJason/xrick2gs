/**********************************************************************
 *                                                                    *
 *  Dc_Shared.h : Header de la bibliothèque de fonctions génériques.  *
 *                                                                    *
 **********************************************************************
 *   Auteur : Olivier ZARDINI  *  Brutal Deluxe  *  Date : Jan 2013   *
 **********************************************************************/

typedef unsigned int       DWORD;     /* Unsigned 32 bit */
typedef unsigned short      WORD;     /* Unsigned 16 bit */
typedef unsigned char       BYTE;     /* Unsigned 8 bit */

#if defined(WIN32) || defined(WIN64)
#define FOLDER_SEPARATOR_CHAR '\\'
#else
#define FOLDER_SEPARATOR_CHAR '/'
#endif

char **BuildFileTab(char *,int *);
WORD ExchangeByte(WORD);
char **BuildListFromFile(char *,int *);
void mem_free_list(int,char **);
unsigned char GetOneByte(char *);
WORD GetOneWord(char *);
DWORD Get24Bit(char *);
int RenameAllFiles(int,char **,char *,char *);
int my_stricmp(char *,char *);
int my_strnicmp(char *,char *,int);
int MatchHierarchy(char *,char *);

/********************************************************************/
