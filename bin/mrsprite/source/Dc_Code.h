/********************************************************************
 *                                                                  *
 *    Dc_Code.h : Header de gestion des lignes de Code.             *
 *                                                                  *
 ********************************************************************
 *  Auteur : Olivier ZARDINI  *  Brutal Deluxe  *  Date : Jan 2013  *
 ********************************************************************/

#define BANK_TOTAL_SIZE   65536
#define BANK_HEADER_SIZE  9

/*
4B AB 0A AA 7C 07 00 00 00
              PHK
              PLB
              ASL
              TAX
              JMP  TableSprite,X
StackAddress  HEX  0000
TableSprite   DA  
*/

struct code_line
{
  char label[32];
  char opcode[16];
  char operand[16];
  char comment[256];

  int nb_byte;
  int nb_cycle;

  struct code_line *next;
};

struct code_file
{
  int index;       /* Numéro du sprite */

  int size;        /* Taille du code objet */
  unsigned char object[65536];

  int bank_number;   /* Numero du bank */
  int index_bank;    /* Numero du Spirte dans le bank */

  struct code_file *next;
};

// prototype
struct picture_256;

void BuildCodeLine(struct picture_256 *,struct picture_256 *,int);
int LoadSpriteCode(char *);
int BuildCodeBank(char *,char *,int *);
int CreateMainCode(char *,char *,int);

/********************************************************************/