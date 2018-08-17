/********************************************************************
 *                                                                  *
 *    Dc_Code.c : Module de gestion des lignes de Code.             *
 *                                                                  *
 ********************************************************************
 *  Auteur : Olivier ZARDINI  *  Brutal Deluxe  *  Date : Jan 2013  *
 ********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include "Dc_Shared.h"
#include "Dc_Graphic.h"
#include "Dc_Memory.h"
#include "Dc_Gif.h"
#include "Dc_Code.h"

#define TYPE_LINE_EMPTY    0    /* Aucun point sur la ligne */
#define TYPE_LINE_RED      1    /* Au moins 1 zone rouge de 4 Bytes */
#define TYPE_LINE_LEFTRED  2    /* Au moins 1 zone rouge et rien à gauche de celle qui est la plus à gauche */
#define TYPE_LINE_MISC     3    /* Autre type de ligne */

#define SCREEN_WIDTH     160    /* Largeur en Byte de l'Ecran */

void BuildCodeLineWithMask(struct picture_256 *,struct picture_256 *,struct pattern *,struct pattern *,struct pattern *,int,int,int);
void BuildCodeLineWithStack(struct picture_256 *,struct picture_256 *,struct pattern *,struct pattern *,struct pattern *,int,int,int *,int *);
int GetLineType(int,struct picture_256 *,int *);
void AddOneLine(char *,char *,char *,char *,int,int);
int AssembleOneLine(char *,unsigned char *);

/**************************************************************/
/*  BuildCodeLine() :  Création des lignes de code du sprite. */
/**************************************************************/
void BuildCodeLine(struct picture_256 *current_picture, struct picture_256 *byte_picture, int sprite_number)
{
  int i, y, stack_x, stack_y, nb_codeline, nb_total_cycle, nb_total_byte, offset_line, current_line_type, offset_red;
  int max_length, delta_stack;
//  int result;
  struct pattern *pattern_1 = NULL;
  struct pattern *pattern_2 = NULL;
  struct pattern *pattern_3 = NULL;
  struct code_line *current_codeline;
  char buffer_label[256];
  char buffer_operand[256];
  char buffer_comment[256];
//  char buffer[100];
 
  /* Récupère les patterns les + utilisées */
  i = 1;
  my_Memory(MEMORY_GET_PATTERN,&i,&pattern_1);
  if(pattern_1 != NULL)
    pattern_2 = pattern_1->next;
  if(pattern_2 != NULL)
    pattern_3 = pattern_2->next;

  /* Init Mémoire */
  my_Memory(MEMORY_FREE_CODELINE,NULL,NULL);

  /** On commence par les lignes standards **/
  sprintf(buffer_label,"Spr_%03d",sprite_number);
  AddOneLine(buffer_label,"CLC","","",1,2);
  AddOneLine("","SEI","","; Disable Interrupts",1,2);
  AddOneLine("","PHD","","; Backup Direct Page",1,4);
  AddOneLine("","TSC","","; Backup Stack",1,2);
  AddOneLine("","STA","StackAddress","",3,4);
  AddOneLine("","LDAL","$E1C068","; Direct Page and Stack in Bank 01/",4,6);
  AddOneLine("","ORA","#$0030","",3,3);
  AddOneLine("","STAL","$E1C068","",4,6);

  /* Adresse d'affichage du Sprite vers la Pile */
  AddOneLine("","TYA","","; Y = Sprite Target Screen Address (upper left corner)",1,2);
  AddOneLine("","TCS","","; New Stack address",1,2);
  stack_x = 0;         /* Adresse X.Y de la Pile dans le Sprite */
  stack_y = 0;

  /** On positionne X, Y et D avec les Pattern les + utilisées **/
  if(pattern_1 != NULL)
    {
      sprintf(buffer_operand,"#$%04X",ExchangeByte(pattern_1->pattern_data));
      sprintf(buffer_comment,"; Pattern #1 : %d",pattern_1->nb_found);
      AddOneLine("","LDX",buffer_operand,buffer_comment,3,3);
    }
  if(pattern_2 != NULL)
    {
      sprintf(buffer_operand,"#$%04X",ExchangeByte(pattern_2->pattern_data));
      sprintf(buffer_comment,"; Pattern #2 : %d",pattern_2->nb_found);
      AddOneLine("","LDY",buffer_operand,buffer_comment,3,3);
    }
  if(pattern_3 != NULL)
    {
      sprintf(buffer_operand,"#$%04X",ExchangeByte(pattern_3->pattern_data));
      sprintf(buffer_comment,"; Pattern #3 : %d",pattern_3->nb_found);
      AddOneLine("","LDA",buffer_operand,buffer_comment,3,3);
      AddOneLine("","TCD","","",1,2);
    }
  AddOneLine("*--","","","",0,0);

  /************************************/
  /***  Création du code du Sprite  ***/
  /************************************/
  for(y=0; y<byte_picture->height; y++)
    {
      /* Début de la ligne */
      offset_line = y*byte_picture->width;

      /* Commentaire pour signaler la ligne traitée */
      sprintf(buffer_comment,"; Line %d",y);
      my_Memory(MEMORY_ADD_COMMENT,buffer_comment,NULL);

      /** On va sauter au dessus de toutes les lignes vides **/
      current_line_type = GetLineType(offset_line,byte_picture,&offset_red);
      if(current_line_type == TYPE_LINE_EMPTY)
        continue;

      /*** On va devoir repositionner la Pile sur la ligne courante (au début ou directement à la fin de la 1ère zone rouge) ***/
      if(stack_y != y)
        {
          /* On se postionne au début de la ligne x=0 de la ligne actuelle */
          if(current_line_type == TYPE_LINE_MISC || current_line_type == TYPE_LINE_RED)
            {
              /* Nombre de bytes entre l'ancienne position et la nouvelle */
              delta_stack = (0+y*SCREEN_WIDTH) - (stack_x+stack_y*SCREEN_WIDTH);

              /* Conserve la nouvelle position de la stack */
              stack_y = y;
              stack_x = 0;
            }
          /* On se positionne à droite de la 1ère zone Rouge de la ligne actuelle */
          else if(current_line_type == TYPE_LINE_LEFTRED)
            {
              /* Nombre de bytes entre l'ancienne position et la nouvelle */
              delta_stack = (offset_red+y*SCREEN_WIDTH) - (stack_x+stack_y*SCREEN_WIDTH);

              /* Conserve la nouvelle position de la stack */
              stack_y = y;
              stack_x = offset_red;
            }

          /** Code déplaçant le pointeur de pile **/
          AddOneLine("","TSC","","",1,2);
          sprintf(buffer_operand,"#$%04X",delta_stack);
          AddOneLine("","ADC",buffer_operand,"",3,3);
          AddOneLine("","TCS","","",1,2);
        }

      /*** Traitement des points en Orange (LDA/STA 16bit), Violet (LDA/AND/ORA/STA 16bit), Jaune (LDA/STA 8bit) et Bleu (LDA/AND/ORA/STA 8bit) ***/
      max_length = (byte_picture->width - stack_x) + ((stack_y == (byte_picture->height-1)) ? 0 : byte_picture->width);
      BuildCodeLineWithMask(current_picture,byte_picture,pattern_1,pattern_2,pattern_3,offset_line,stack_x,max_length);

      /*sprintf(buffer,"c:\\Temp\\sprite_tmp_%03d_1.gif",y);
      result = GIFWriteFileFrom256Color(buffer,byte_picture);
      if(result)
        printf("  - Error : Can't create Sprite BYTE temp file.\n");*/

      /** A t'on du Rouge sur la ligne courante ? **/
      current_line_type = GetLineType(offset_line,byte_picture,&offset_red);
      if(current_line_type == TYPE_LINE_RED || current_line_type == TYPE_LINE_LEFTRED)
        {
          /*** Traitement des points en Rouge (PHA/PEA 16bit) de la ligne ***/
          BuildCodeLineWithStack(current_picture,byte_picture,pattern_1,pattern_2,pattern_3,offset_line,y,&stack_x,&stack_y);

          /*sprintf(buffer,"c:\\Temp\\sprite_tmp_%03d_2.gif",y);
          result = GIFWriteFileFrom256Color(buffer,byte_picture);
          if(result)
            printf("  - Error : Can't create Sprite BYTE temp file.\n");*/
        }
    }

  /* Efface le commentaire à venir */
  strcpy(buffer_comment,"");
  my_Memory(MEMORY_ADD_COMMENT,buffer_comment,NULL);

  /** Fin du Code **/
  AddOneLine("*--","","","",0,0);
  AddOneLine("","LDAL","$E1C068","; Direct Page and Stack in Bank 00/",4,6);
  AddOneLine("","AND","#$FFCF","",3,3);
  AddOneLine("","STAL","$E1C068","",4,6);
  AddOneLine("","LDA","StackAddress","; Restore Stack",3,5);
  AddOneLine("","TCS","","",1,2);
  AddOneLine("","PLD","","; Restore Direct Page",1,5);
  AddOneLine("","CLI","","; Enable Interrupts",1,2);
  AddOneLine("","RTL","","",1,6);
  AddOneLine("","","","",0,0);
  AddOneLine("*-----------------------------------","","","",0,0);

  /** Détermine la taille du code et le nb de cycle **/
  nb_total_cycle = 0;
  nb_total_byte = 0;
  my_Memory(MEMORY_GET_CODELINE_NB,&nb_codeline,NULL);
  for(i=1; i<=nb_codeline; i++)
    {
      my_Memory(MEMORY_GET_CODELINE,&i,&current_codeline);
      nb_total_cycle += current_codeline->nb_cycle;
      nb_total_byte += current_codeline->nb_byte;
    }

  /* Met ces valeurs en commentaire de la première ligne du code */
  i = 1;
  my_Memory(MEMORY_GET_CODELINE,&i,&current_codeline);
  sprintf(current_codeline->comment,"; %dx%d, %d bytes, %d cycles",current_picture->width,current_picture->height,nb_total_byte,nb_total_cycle);
}


/***************************************************************************/
/*  BuildCodeLineWithMask() :  Création des lignes de code avec LDA / STA. */
/***************************************************************************/
void BuildCodeLineWithMask(struct picture_256 *current_picture, struct picture_256 *byte_picture, 
                           struct pattern *pattern_1, struct pattern *pattern_2, struct pattern *pattern_3, 
                           int offset_line, int stack_x, int max_length)
{
  int j, k, done, is_valid_register_a, is_valid_register_a_8bit, is_pattern_ora_f, nb_8bit_line;
  WORD pattern, pattern_and, pattern_ora, register_a;
  BYTE pattern_8bit, pattern_8bit_and, pattern_8bit_ora, register_a_8bit;
  char buffer_operand_value[256];
  char buffer_operand_address[256];
  char buffer_operand_and[256];
  char buffer_operand_ora[256];

  /* On ne peut pas garantir le contenu de A */
  is_valid_register_a = 0;
  is_valid_register_a_8bit = 0;
  register_a = 0x0000;
  register_a_8bit = 0x00;

  /***********************************/
  /***  16 bit : Orange (LDA/STA)  ***/
  /***********************************/
  for(j=0; j<max_length; j++)
    if(byte_picture->data[offset_line+stack_x+j] == 0x99)
      {
        /* Récupération des 4 points de l'image */
        pattern = ((WORD) current_picture->data[2*(offset_line+stack_x+j)+0]) << 12 | 
                  ((WORD) current_picture->data[2*(offset_line+stack_x+j)+1]) << 8  |
                  ((WORD) current_picture->data[2*(offset_line+stack_x+j)+2]) << 4  |
                  ((WORD) current_picture->data[2*(offset_line+stack_x+j)+3]);
        done = 0;

        /* Adresse relative à la pile (on gère le saut de ligne) */
        if(j < (byte_picture->width - stack_x))
          sprintf(buffer_operand_address,"$%02X,S",j);
        else
          sprintf(buffer_operand_address,"$%02X,S",SCREEN_WIDTH+(j-byte_picture->width));

        /** A contient déjà la pattern **/
        if(register_a == pattern && is_valid_register_a == 1)
          {
            AddOneLine("","STA",buffer_operand_address,"",2,5);
            done = 1;
          }

        /*** On utilise une pattern connue X, Y ou D ***/
        /* X */
        if(pattern_1 != NULL && done == 0)
          if(pattern == pattern_1->pattern_data)
            {
              AddOneLine("","TXA","","",1,2);
              AddOneLine("","STA",buffer_operand_address,"",2,5);
              done = 1;
            }
        /* Y */
        if(pattern_2 != NULL && done == 0)
          if(pattern == pattern_2->pattern_data)
            {
              AddOneLine("","TYA","","",1,2);
              AddOneLine("","STA",buffer_operand_address,"",2,5);
              done = 1;
            }
        /* D */
        if(pattern_3 != NULL && done == 0)
          if(pattern == pattern_3->pattern_data)
            {
              AddOneLine("","TDC","","",1,2);
              AddOneLine("","STA",buffer_operand_address,"",2,5);
              done = 1;
            }

        /** On va finalement devoir charger une constante **/
        if(done == 0)
          {
            sprintf(buffer_operand_value,"#$%04X",ExchangeByte(pattern));
            AddOneLine("","LDA",buffer_operand_value,"",3,3);
            AddOneLine("","STA",buffer_operand_address,"",2,5);
            done = 1;
          }

        /* A contient maintenant la Pattern */
        register_a = pattern;
        is_valid_register_a = 1;

        /* Met du Fond à la place des points déjà traités */
        byte_picture->data[offset_line+stack_x+j] = 0xFF;
        byte_picture->data[offset_line+stack_x+j+1] = 0xFF;

        /*** Maintenant qu'on a mis une pattern dans A, on regarde si on ne l'a pas un peu plus loin ***/
        for(k=j+1; k<max_length; k++)
          if(byte_picture->data[offset_line+stack_x+k] == 0x99)
            {
              /* Récupération des 4 points de l'image */
              pattern = ((WORD) current_picture->data[2*(offset_line+stack_x+k)+0]) << 12 | 
                        ((WORD) current_picture->data[2*(offset_line+stack_x+k)+1]) << 8  |
                        ((WORD) current_picture->data[2*(offset_line+stack_x+k)+2]) << 4  |
                        ((WORD) current_picture->data[2*(offset_line+stack_x+k)+3]);

              /** A contient déjà la pattern **/
              if(register_a == pattern)
                {
                  /* Adresse relative à la pile (on gère le saut de ligne) */
                  if(k < (byte_picture->width - stack_x))
                    sprintf(buffer_operand_address,"$%02X,S",k);
                  else
                    sprintf(buffer_operand_address,"$%02X,S",SCREEN_WIDTH+(k-byte_picture->width));

                  /* STA */
                  AddOneLine("","STA",buffer_operand_address,"",2,5);

                  /* Met du Fond à la place des points déjà traités */
                  byte_picture->data[offset_line+stack_x+k] = 0xFF;
                  byte_picture->data[offset_line+stack_x+k+1] = 0xFF;
                }
            }
      }

  /*******************************************/
  /***  16 bit : Violet (LDA/AND/ORA/STA)  ***/
  /*******************************************/
  for(j=0; j<max_length; j++)
    if(byte_picture->data[offset_line+stack_x+j] == 0xDD)
      {
        /* Récupération du mask 16 bit (on repère les points du décor) */
        pattern_and = (current_picture->data[2*(offset_line+stack_x+j)+0] == 0xFF ? 0xF000 : 0x0000) | 
                      (current_picture->data[2*(offset_line+stack_x+j)+1] == 0xFF ? 0x0F00 : 0x0000) |
                      (current_picture->data[2*(offset_line+stack_x+j)+2] == 0xFF ? 0x00F0 : 0x0000) |
                      (current_picture->data[2*(offset_line+stack_x+j)+3] == 0xFF ? 0x000F : 0x0000);
        sprintf(buffer_operand_and,"#$%04X",ExchangeByte(pattern_and));

        /* Récupération des points 16 bit de l'image (on repère les points du décor) */
        pattern_ora = (current_picture->data[2*(offset_line+stack_x+j)+0] == 0xFF ? 0x0000 : ((WORD) current_picture->data[2*(offset_line+stack_x+j)+0]) << 12) | 
                      (current_picture->data[2*(offset_line+stack_x+j)+1] == 0xFF ? 0x0000 : ((WORD) current_picture->data[2*(offset_line+stack_x+j)+1]) << 8 ) |
                      (current_picture->data[2*(offset_line+stack_x+j)+2] == 0xFF ? 0x0000 : ((WORD) current_picture->data[2*(offset_line+stack_x+j)+2]) << 4 ) |
                      (current_picture->data[2*(offset_line+stack_x+j)+3] == 0xFF ? 0x0000 : ((WORD) current_picture->data[2*(offset_line+stack_x+j)+3]) << 0 );
        sprintf(buffer_operand_ora,"#$%04X",ExchangeByte(pattern_ora));

        /* Les points du sprite sont t'ils tous F ? */
        if(pattern_ora == 0x0000)
          is_pattern_ora_f = 0;
        else
          {
            is_pattern_ora_f = 1;
            if(((pattern_ora >> 12) & 0x000F) != 0x0000)
              if(((pattern_ora >> 12) & 0x000F) != 0x000F)
                is_pattern_ora_f = 0;
            if(((pattern_ora >> 8) & 0x000F) != 0x0000)
              if(((pattern_ora >> 8) & 0x000F) != 0x000F)
                is_pattern_ora_f = 0;
            if(((pattern_ora >> 4) & 0x000F) != 0x0000)
              if(((pattern_ora >> 4) & 0x000F) != 0x000F)
                is_pattern_ora_f = 0;
            if(((pattern_ora >> 0) & 0x000F) != 0x0000)
              if(((pattern_ora >> 0) & 0x000F) != 0x000F)
                is_pattern_ora_f = 0;
          }

        /* Adresse relative à la pile (on gère le saut de ligne) */
        if(j < (byte_picture->width - stack_x))
          sprintf(buffer_operand_address,"$%02X,S",j);
        else
          sprintf(buffer_operand_address,"$%02X,S",SCREEN_WIDTH+(j-byte_picture->width));

        /** LDA / AND / ORA / STA **/
        AddOneLine("","LDA",buffer_operand_address,"",2,5);
        if(is_pattern_ora_f != 1)
          AddOneLine("","AND",buffer_operand_and,"",3,3);     /* Petite Optimiation, la couleur F est mise par le ORA */
        if(pattern_ora != 0x0000)
          AddOneLine("","ORA",buffer_operand_ora,"",3,3);     /* Petite Optimisation, la couleur 0 est mise par le AND */
        AddOneLine("","STA",buffer_operand_address,"",2,5);

        /* Met du Fond à la place des points déjà traités */
        byte_picture->data[offset_line+stack_x+j] = 0xFF;
        byte_picture->data[offset_line+stack_x+j+1] = 0xFF;

        /* On a perdu le contenu de A */
        is_valid_register_a = 0;
        is_valid_register_a_8bit = 0;
      }

  /** On passe A en 8 bit (on laisse X et Y en 16 sinon on perd une partie du registre) **/
  AddOneLine("","SEP","#$20","",2,3);
  nb_8bit_line = 0;

  /*********************************/
  /***  8 bit : Jaune (LDA/STA)  ***/
  /*********************************/
  for(j=0; j<max_length; j++)
    if(byte_picture->data[offset_line+stack_x+j] == 0xAA)
      {
        /* Récupération des points 8 bit de l'image */
        pattern_8bit = (current_picture->data[2*(offset_line+stack_x+j)+0] << 4) | current_picture->data[2*(offset_line+stack_x+j)+1];
        sprintf(buffer_operand_value,"#$%02X",pattern_8bit);

        /* Adresse relative à la pile (on gère le saut de ligne) */
        if(j < (byte_picture->width - stack_x))
          sprintf(buffer_operand_address,"$%02X,S",j);
        else
          sprintf(buffer_operand_address,"$%02X,S",SCREEN_WIDTH+(j-byte_picture->width));

        /** LDA / STA **/
        if(register_a_8bit != pattern_8bit || is_valid_register_a_8bit == 0)
          AddOneLine("","LDA",buffer_operand_value,"",2,2);
        AddOneLine("","STA",buffer_operand_address,"",2,3);

        /* A contient maintenant la valeur de la pattern */
        register_a_8bit = pattern_8bit;
        is_valid_register_a_8bit = 1;

        /* Met du Fond à la place des points déjà traités */
        byte_picture->data[offset_line+stack_x+j] = 0xFF;
        nb_8bit_line++;

        /*** Maintenant qu'on a mis une pattern dans A, on regarde s'il n'y en a pas d'autres identiques un peu plus loin ***/
        for(k=j+1; k<max_length; k++)
          if(byte_picture->data[offset_line+stack_x+k] == 0xAA)
            {
              /* Récupération des points 8 bit de l'image */
              pattern_8bit = (current_picture->data[2*(offset_line+stack_x+k)+0] << 4) | current_picture->data[2*(offset_line+stack_x+k)+1];

              /** On a la même valeur que dans A **/
              if(register_a_8bit == pattern_8bit)
                {
                  /* Adresse relative à la pile (on gère le saut de ligne) */
                  if(k < (byte_picture->width - stack_x))
                    sprintf(buffer_operand_address,"$%02X,S",k);
                  else
                    sprintf(buffer_operand_address,"$%02X,S",SCREEN_WIDTH+(k-byte_picture->width));

                  /* STA */
                  AddOneLine("","STA",buffer_operand_address,"",2,3);

                  /* Met du Fond à la place des points déjà traités */
                  byte_picture->data[offset_line+stack_x+k] = 0xFF;
                }
            }
      }

  /****************************************/
  /***  8 bit : Bleu (LDA/AND/ORA/STA)  ***/
  /****************************************/
  for(j=0; j<max_length; j++)
    if(byte_picture->data[offset_line+stack_x+j] == 0xBB)
      {
        /* Récupération du mask 8 bit (on repère les points du décor) */
        pattern_8bit_and = (current_picture->data[2*(offset_line+stack_x+j)+0] == 0xFF ? 0xF0 : 0x00) | 
                           (current_picture->data[2*(offset_line+stack_x+j)+1] == 0xFF ? 0x0F : 0x00);
        sprintf(buffer_operand_and,"#$%02X",pattern_8bit_and);

        /* Récupération des points 8 bit de l'image (on repère les points du décor) */
        pattern_8bit_ora = (current_picture->data[2*(offset_line+stack_x+j)+0] == 0xFF ? 0x00 : current_picture->data[2*(offset_line+stack_x+j)+0] << 4) | 
                           (current_picture->data[2*(offset_line+stack_x+j)+1] == 0xFF ? 0x00 : current_picture->data[2*(offset_line+stack_x+j)+1]     );
        sprintf(buffer_operand_ora,"#$%02X",pattern_8bit_ora);

        /* Les points du sprite sont t'ils tous F ? */
        if(pattern_8bit_ora == 0x00)
          is_pattern_ora_f = 0;
        else
          {
            is_pattern_ora_f = 1;
            if(((pattern_8bit_ora & 0xF0) != 0x00) && ((pattern_8bit_ora & 0xF0) != 0xF0))
              is_pattern_ora_f = 0;
            if(((pattern_8bit_ora & 0x0F) != 0x00) && ((pattern_8bit_ora & 0x0F) != 0x0F))
              is_pattern_ora_f = 0;
          }

        /* Adresse relative à la pile (on gère le saut de ligne) */
        if(j < (byte_picture->width - stack_x))
          sprintf(buffer_operand_address,"$%02X,S",j);
        else
          sprintf(buffer_operand_address,"$%02X,S",SCREEN_WIDTH+(j-byte_picture->width));

        /** LDA / AND / ORA / STA **/
        AddOneLine("","LDA",buffer_operand_address,"",2,4);
        if(is_pattern_ora_f != 1)
          AddOneLine("","AND",buffer_operand_and,"",2,2);     /* Petite Optimiation, la couleur F est mise par le ORA */
        if(pattern_8bit_ora != 0x00)
          AddOneLine("","ORA",buffer_operand_ora,"",2,2);     /* Petite Optimisation, la couleur 0 est mise par le AND */
        AddOneLine("","STA",buffer_operand_address,"",2,4);

        /* Met du Fond à la place des points déjà traités */
        byte_picture->data[offset_line+stack_x+j] = 0xFF;
        nb_8bit_line++;

        /* On a perdu le contenu de A */
        is_valid_register_a = 0;
        is_valid_register_a_8bit = 0;
      }

  /** On re-passe en 16 bit (si besoin) **/
  if(nb_8bit_line == 0)
    my_Memory(MEMORY_DROP_CODELINE,NULL,NULL);    /* On supprime la ligne faisant passer en 8 bit */
  else
    AddOneLine("","REP","#$30","",2,3);
}


/****************************************************************************/
/*  BuildCodeLineWithStack() :  Création des lignes de code avec PHA / PEA. */
/****************************************************************************/
void BuildCodeLineWithStack(struct picture_256 *current_picture, struct picture_256 *byte_picture, 
                            struct pattern *pattern_1, struct pattern *pattern_2, struct pattern *pattern_3, 
                            int offset_line, int line_y, int *stack_x_rtn, int *stack_y_rtn)
{
  int i, j, length, stack_x, stack_y, delta_stack, done, is_valid_register_a;
  WORD pattern;
  WORD register_a = 0;
  struct pattern *pattern_red;
  char buffer_operand[256];

  /* Init */
  stack_x = *stack_x_rtn;
  stack_y = *stack_y_rtn;
  is_valid_register_a = 0;

  /************************************************************************/
  /***  Traite toutes les zones rouges de la ligne (de gauche à droite) ***/
  for(i=0; i<byte_picture->width; i++)
    {
      /** On a trouvé une zone rouge **/
      if(byte_picture->data[i+offset_line] == 0xCC)    /* Rouge */
        {
          /* Init */
          is_valid_register_a = 0;

          /* Recherche la fin */
          for(j=i; j<byte_picture->width; j++)
            if(byte_picture->data[j+offset_line] != 0xCC)
              break;
          length = j-i;

          /** Il faut peut être déplacer le pointeur de Pile à la fin de cette zone rouge **/
          delta_stack = ((i+length-1)+line_y*SCREEN_WIDTH) - (stack_x+stack_y*SCREEN_WIDTH);
          if(delta_stack > 0)
            {
              /* Code déplacant le pointeur de Pile */
              AddOneLine("","TSC","","",1,2);
              sprintf(buffer_operand,"#$%04X",delta_stack);
              AddOneLine("","ADC",buffer_operand,"",3,3);
              AddOneLine("","TCS","","",1,2);

              /* Met à jour la variable */
              stack_x += delta_stack;
            }

          /*** Recherche dans cette zone Rouge une pattern au moins répétée 3 fois et qui n'est pas déjà dans X, Y ou D ! ***/
          my_Memory(MEMORY_FREE_REDPATTERN,NULL,NULL);
          for(j=0; j<length; j+=2)
            {
              /* Récupération des 4 points de l'image */
              pattern = ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+0]) << 12 | 
                        ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+1]) << 8  |
                        ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+2]) << 4  |
                        ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+3]);

              /* On ne veut pas celles déjà connues */
              if(pattern_1 != NULL)
                if(pattern == pattern_1->pattern_data)
                  continue;
              if(pattern_2 != NULL)
                if(pattern == pattern_2->pattern_data)
                  continue;
              if(pattern_3 != NULL)
                if(pattern == pattern_3->pattern_data)
                  continue;

              /* Conserve dans une Table */
              my_Memory(MEMORY_ADD_REDPATTERN,&pattern,NULL);
            }
          /* Tri le tableau */
          my_Memory(MEMORY_SORT_REDPATTERN,NULL,NULL);

          /** Le LDA/PHA n'est 'rentable' qui si on fait au moins 4 PHA dans la zone rouge (19 cycles / 20 cycles pour le PEA) ! **/
          j = 1;
          my_Memory(MEMORY_GET_REDPATTERN,&j,&pattern_red);
          if(pattern_red != NULL)
            if(pattern_red->nb_found >= 3)    /* Si on l'a 3 fois, on ne gagne rien pour les cycles (15 partout) mais sur les bytes (6/9) */
              {
                sprintf(buffer_operand,"#$%04X",ExchangeByte(pattern_red->pattern_data));
                AddOneLine("","LDA",buffer_operand,"",3,3);
                register_a = pattern_red->pattern_data;
                is_valid_register_a = 1;
              }

          /*** Génération du code pour cette zone (PHA, PHX, PHY, PHD et PEA) ***/
          for(j=0; j<length; j+=2)
            {
              /* Récupération des 4 points de l'image */
              pattern = ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+0]) << 12 | 
                        ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+1]) << 8  |
                        ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+2]) << 4  |
                        ((WORD) current_picture->data[2*(offset_line+i+length-2-j)+3]);
              done = 0;

              /*** On utilise une pattern connue X, Y ou D ***/
              /* X */
              if(pattern_1 != NULL && done == 0)
                if(pattern == pattern_1->pattern_data)
                  {
                    AddOneLine("","PHX","","",1,4);
                    done = 1;
                  }
              /* Y */
              if(pattern_2 != NULL && done == 0)
                if(pattern == pattern_2->pattern_data)
                  {
                    AddOneLine("","PHY","","",1,4);
                    done = 1;
                  }
              /* D */
              if(pattern_3 != NULL && done == 0)
                if(pattern == pattern_3->pattern_data)
                  {
                    AddOneLine("","PHD","","",1,4);
                    done = 1;
                  }
              /** A : Remplis tout au début via un LDA **/
              if(pattern == register_a && is_valid_register_a == 1)
                {
                  AddOneLine("","PHA","","",1,4);
                  done = 1;
                }

              /** On va finalement devoir charger une constante **/
              if(done == 0)
                {
                  /* PEA */
                  sprintf(buffer_operand,"$%04X",ExchangeByte(pattern));
                  AddOneLine("","PEA",buffer_operand,"",3,5);
                }
            }

          /** Met à jour la position actuelle de la Pile **/
          stack_x -= length;
          stack_y = line_y;

          /** Met du Background sur les points traités **/
          for(j=0; j<length; j++)
            byte_picture->data[i+j+offset_line] = 0xFF;     /* Background */

          /* On passe à la Zone suivante */
          i += length -1;   /* -1 Car i++ */
        }
    }

  /** Renvoie la nouvelle position de la Pile **/
  *stack_x_rtn = stack_x;
  *stack_y_rtn = stack_y;
}


/*******************************************************************************/
/*  GetLineType() :  Détermine le type de ligne (EMPTY, RED, LEFTRED ou MISC). */
/*******************************************************************************/
int GetLineType(int offset_line, struct picture_256 *byte_picture, int *offset_red_rtn)
{
  int i, j, has_red, has_misc;

  /** Relève les points de la ligne **/
  for(i=0,has_red=0,has_misc=0; i<byte_picture->width; i++)
    if(byte_picture->data[offset_line+i] == 0xFF)          /* Background */
      continue;
    else if(byte_picture->data[offset_line+i] == 0xCC)     /* Rouge */
      has_red = 1;
    else                                              /* Autre */
      has_misc = 1;

  /** Renvoie le type de ligne **/
  if(has_red == 1)
    {
      /* On renvoie le offset_red = le point à droite de la 1ère zone rouge = @ de la pile pour la série de PHA/PEA */
      for(i=0; i<byte_picture->width; i++)
        if(byte_picture->data[offset_line+i] == 0xCC)     /* Rouge */
          {
            for(j=i; j<byte_picture->width; j++)
              if(byte_picture->data[offset_line+j] != 0xCC)
                break;
            *offset_red_rtn = j-1;
            break;
          }

      /* On doit trancher en RED et LEFTRED (rien à gauche de la 1ère zone rouge) */
      for(i=0; i<byte_picture->width; i++)
        if(byte_picture->data[offset_line+i] == 0xFF)          /* Background */
          continue;
        else if(byte_picture->data[offset_line+i] == 0xCC)     /* Rouge */
          return(TYPE_LINE_LEFTRED);
        else                                              /* Autre */
          return(TYPE_LINE_RED);

      /* Never here */
      return(TYPE_LINE_RED);
    }
  else if(has_misc == 1)
    return(TYPE_LINE_MISC);
  else
    return(TYPE_LINE_EMPTY);
}


/**********************************************************************/
/*  AddOneLine() :  Création d'une ligne de code et ajout à la liste. */
/**********************************************************************/
void AddOneLine(char *label, char *opcode, char *operand, char *comment, int nb_byte, int nb_cycle)
{
  struct code_line *current_codeline;

  /* Allocation mémoire */
  current_codeline = (struct code_line *) calloc(1,sizeof(struct code_line));
  if(current_codeline == NULL)
    {
      printf("  Error : Impossible to allocate memory for structure code_line.\n");
      return;
    }

  /* Remplissage */
  strcpy(current_codeline->label,label);
  strcpy(current_codeline->opcode,opcode);
  strcpy(current_codeline->operand,operand);
  strcpy(current_codeline->comment,comment);
  current_codeline->nb_byte = nb_byte;
  current_codeline->nb_cycle = nb_cycle;

  /* Déclaration */
  my_Memory(MEMORY_ADD_CODELINE,current_codeline,NULL);
}


/********************************************************************/
/*  LoadSpriteCode() :  Chargement/Compilation d'un fichier source. */
/********************************************************************/
int LoadSpriteCode(char *file_path)
{
  int i, index, nb_line, found, object_size;
  char **tab_line;
  struct code_file *current_codefile;
  char *next_sep;
  char buffer[1024];
  unsigned char object[256];

  /** Isole le numero du Sprite dans le nom **/
  for(i=strlen(file_path),found=0; i>=0; i--)
    if(file_path[i] == '_')
      {
        strcpy(buffer,&file_path[i+1]);
        next_sep = strchr(buffer,'.');
        if(next_sep != NULL)
          *next_sep = '\0';
        else 
          break;
        index = atoi(buffer);
        if(index < 0)
          break;
        found = 1;
        break;
      }
  if(found == 0)
    {
      printf("  Error : Impossible to extract Sprite Index number from Source file name '%s'.\n",file_path);
      return(1);
    }

  /** Chargement en mémoire du fichier Source **/
  tab_line = BuildListFromFile(file_path,&nb_line);
  if(tab_line == NULL)
    {
      printf("  Error : Impossible to load Source file '%s'.\n",file_path);
      return(1);
    }

  /* Allocation mémoire */
  current_codefile = (struct code_file *) calloc(1,sizeof(struct code_file));
  if(current_codefile == NULL)
    {
      mem_free_list(nb_line,tab_line);
      printf("  Error : Impossible to load Source file '%s'.\n",file_path);
      return(1);
    }
  current_codefile->index = index;

  /** Assemblage des lignes en code objet **/
  for(i=0; i<nb_line; i++)
    {
      /* Assemble 1 ligne */
      object_size = AssembleOneLine(tab_line[i],object);
      if(object_size == 0)
        continue;

      /* Stocke le code objet */
      memcpy(&current_codefile->object[current_codefile->size],&object[0],object_size);
      current_codefile->size += object_size;
    }

  /* Libération mémoire du Source */
  mem_free_list(nb_line,tab_line);

  /* Déclaration de la structure */
  my_Memory(MEMORY_ADD_CODEFILE,current_codefile,NULL);

  /* OK */
  return(0);
}


/*******************************************************/
/*  AssembleOneLine() :  Assemble une ligne du Source. */
/*******************************************************/
int AssembleOneLine(char *one_line, unsigned char *object)
{
  WORD one_word;
  DWORD one_dword;
  char *next_sep;
  char opcode[256] = "";
  char operand[256] = "";

  /* Ligne vide */
  if(strlen(one_line) < 3)
    return(0);

  /* Ligne commentaire */
  if(one_line[0] == '*')
    return(0);

  /* Saute le premier \t pour tomber sur l'Opcode */
  if(one_line[0] != '\t')
    return(0);
  next_sep = strchr(&one_line[1],'\t');
  if(next_sep == NULL)
    strcpy(opcode,&one_line[1]);
  else
    {
      memcpy(opcode,&one_line[1],next_sep-&one_line[1]);
      opcode[next_sep-&one_line[1]] = '\0';
    }

  /* Isole l'Operand */
  if(next_sep)
    {
      next_sep++;
      strcpy(operand,next_sep);
      next_sep = strchr(operand,'\t');
      if(next_sep)
        *next_sep = '\0';
    }

  /****************************/
  /***  Assemblage du code  ***/
  /****************************/
  /** 1 Byte **/
  if(!my_stricmp(opcode,"CLC"))
    {
      object[0] = 0x18;
      return(1);
    }
  else if(!my_stricmp(opcode,"RTL"))
    {
      object[0] = 0x6B;
      return(1);
    }
  else if(!my_stricmp(opcode,"CLI"))
    {
      object[0] = 0x58;
      return(1);
    }
  else if(!my_stricmp(opcode,"SEI"))
    {
      object[0] = 0x78;
      return(1);
    }
  else if(!my_stricmp(opcode,"TSC"))
    {
      object[0] = 0x3B;
      return(1);
    }
  else if(!my_stricmp(opcode,"TCS"))
    {
      object[0] = 0x1B;
      return(1);
    }
  else if(!my_stricmp(opcode,"TXA"))
    {
      object[0] = 0x8A;
      return(1);
    }
  else if(!my_stricmp(opcode,"TYA"))
    {
      object[0] = 0x98;
      return(1);
    }
  else if(!my_stricmp(opcode,"TCD"))
    {
      object[0] = 0x5B;
      return(1);
    }
  else if(!my_stricmp(opcode,"TDC"))
    {
      object[0] = 0x7B;
      return(1);
    }
  else if(!my_stricmp(opcode,"PHA"))
    {
      object[0] = 0x48;
      return(1);
    }
  else if(!my_stricmp(opcode,"PHD"))
    {
      object[0] = 0x0B;
      return(1);
    }
  else if(!my_stricmp(opcode,"PHX"))
    {
      object[0] = 0xDA;
      return(1);
    }
  else if(!my_stricmp(opcode,"PHY"))
    {
      object[0] = 0x5A;
      return(1);
    }
  else if(!my_stricmp(opcode,"PLD"))
    {
      object[0] = 0x2B;
      return(1);
    }
  /** SEP / REP **/
  else if(!my_stricmp(opcode,"SEP"))
    {
      object[0] = 0xE2;
      object[1] = GetOneByte(operand);
      return(2);
    }
  else if(!my_stricmp(opcode,"REP"))
    {
      object[0] = 0xC2;
      object[1] = GetOneByte(operand);
      return(2);
    }
  /** PEA **/
  else if(!my_stricmp(opcode,"PEA"))
    {
      if(strlen(operand) == 5)
        {
          object[0] = 0xF4;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
    }
  /** ADC **/
  else if(!my_stricmp(opcode,"ADC"))
    {
      if(strlen(operand) == 6)
        {
          object[0] = 0x69;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
    }
  /** LDX **/
  else if(!my_stricmp(opcode,"LDX"))
    {
      if(operand[0] == '#' && operand[1] == '$' && strlen(operand) == 6)   /* Constante 16 bit */
        {
          object[0] = 0xA2;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
    }
  /** LDY **/
  else if(!my_stricmp(opcode,"LDY"))
    {
      if(operand[0] == '#' && operand[1] == '$' && strlen(operand) == 6)   /* Constante 16 bit */
        {
          object[0] = 0xA0;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
    }
  /** LDA **/
  else if(!my_stricmp(opcode,"LDA"))
    {
      if(operand[0] == '#' && operand[1] == '$' && strlen(operand) == 4)        /* Constante 8 bit */
        {
          object[0] = 0xA9;
          object[1] = GetOneByte(operand);
          return(2);
        }
      else if(operand[0] == '#' && operand[1] == '$' && strlen(operand) == 6)   /* Constante 16 bit */
        {
          object[0] = 0xA9;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
      else if(strlen(operand) == 5 && !my_stricmp(&operand[3],",S"))   /* Stack Relative $XX,S */
        {
          object[0] = 0xA3;
          object[1] = GetOneByte(operand);
          return(2);
        }
      else if(!my_stricmp(operand,"StackAddress"))     /* Stack Address */
        {
          object[0] = 0xAD;
          object[1] = 0x07;    /* Adresse où on stocke l'adresse de la Pile */
          object[2] = 0x00;
          return(3);
        }
    }
  /** LDAL **/
  else if(!my_stricmp(opcode,"LDAL") && strlen(operand) == 7)
    {
      object[0] = 0xAF;
      one_dword = Get24Bit(operand);
      object[1] = (unsigned char)  (one_dword & 0x000000FF);
      object[2] = (unsigned char) ((one_dword & 0x0000FF00) >> 8);
      object[3] = (unsigned char) ((one_dword & 0x00FF0000) >> 16);
      return(4);
    }
  /** STA **/
  else if(!my_stricmp(opcode,"STA"))
    {
      if(strlen(operand) == 5 && !my_stricmp(&operand[3],",S"))   /* Stack Relative $XX,S */
        {
          object[0] = 0x83;
          object[1] = GetOneByte(operand);
          return(2);
        }
      else if(!my_stricmp(operand,"StackAddress"))     /* Stack Address */
        {
          object[0] = 0x8D;
          object[1] = 0x07;    /* Adresse où on stocke l'adresse de la Pile */
          object[2] = 0x00;
          return(3);
        }
    }
  /** STAL **/
  else if(!my_stricmp(opcode,"STAL") && strlen(operand) == 7)
    {
      object[0] = 0x8F;
      one_dword = Get24Bit(operand);
      object[1] = (unsigned char)  (one_dword & 0x000000FF);
      object[2] = (unsigned char) ((one_dword & 0x0000FF00) >> 8);
      object[3] = (unsigned char) ((one_dword & 0x00FF0000) >> 16);
      return(4);
    }
  /** AND **/
  else if(!my_stricmp(opcode,"AND"))
    {
      if(strlen(operand) == 4)
        {
          object[0] = 0x29;
          object[1] = GetOneByte(operand);
          return(2);
        }
      else if(strlen(operand) == 6)
        {
          object[0] = 0x29;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
    }
  /** ORA **/
  else if(!my_stricmp(opcode,"ORA"))
    {
      if(strlen(operand) == 4)
        {
          object[0] = 0x09;
          object[1] = GetOneByte(operand);
          return(2);
        }
      else if(strlen(operand) == 6)
        {
          object[0] = 0x09;
          one_word = GetOneWord(operand);
          object[1] = (unsigned char) (one_word & 0x00FF);
          object[2] = (unsigned char) ((one_word & 0xFF00) >> 8);
          return(3);
        }
    }

  /* Never Here */
  printf("  Error : Unknown Source Code Line '%s'.\n",one_line);
  return(0);
}


/*******************************************************/
/*  BuildCodeBank() :  Construction des fichiers Bank. */
/*******************************************************/
int BuildCodeBank(char *file_folder_path, char *bank_name, int *nb_bank_rtn)
{
  int i, j, k, nb_codefile, total_size, nb_bank, bank_free_size, offset, bank_size, nb_store;
  WORD code_offset;
  FILE *fd;
  struct code_file *current_codefile;
  unsigned char **tab_bank;
  char file_bank_path[1024];
  unsigned char header_code[] = {0x4B,0xAB,0x0A,0xAA,0x7C,0x09,0x00,0x00,0x00};

  /* On fait le total */
  nb_store = 0;
  my_Memory(MEMORY_GET_CODEFILE_NB,&nb_codefile,NULL);
  for(i=1,total_size=0; i<=nb_codefile; i++)
    {
      my_Memory(MEMORY_GET_CODEFILE,&i,&current_codefile);
      total_size += current_codefile->size;
      current_codefile->bank_number = -1;
    }

  /* Nombre de bank nécessaires */
  nb_bank = (total_size / BANK_TOTAL_SIZE) + 1;

  /** Allocation mémoire (on réserve 1 bank en plus) **/
  tab_bank = (unsigned char **) calloc(nb_bank+1,sizeof(unsigned char *));
  if(tab_bank == NULL)
    {
      printf("  Error : Impossible to allocate memory for Bank.\n");
      return(1);
    }
  for(i=0; i<nb_bank+1; i++)
    {
      tab_bank[i] = (unsigned char *) calloc(BANK_TOTAL_SIZE,sizeof(unsigned char));
      if(tab_bank[i] == NULL)
        {
          for(j=0; j<i; j++)
            free(tab_bank[j]);
          free(tab_bank);
          printf("  Error : Impossible to allocate memory for Bank.\n");
          return(2);
        }
    }

  /***********************************/
  /**  Remplissage des Banks prévus **/
  /***********************************/
  for(i=0; i<nb_bank; i++)
    {
      /* Init */
      bank_free_size = BANK_TOTAL_SIZE - BANK_HEADER_SIZE;
      offset = BANK_TOTAL_SIZE;

      /** On place le code d'entête **/
      memcpy(&tab_bank[i][0],header_code,BANK_HEADER_SIZE);

      /** On ajoute tous les Codes possibles dans ce Bank **/
      for(k=0,j=1; j<=nb_codefile; j++)
        {
          my_Memory(MEMORY_GET_CODEFILE,&j,&current_codefile);
          if(current_codefile->bank_number == -1)
            if(bank_free_size-2 > current_codefile->size)
              {
                /* Copie le code dans le banc */
                offset -= current_codefile->size;
                memcpy(&tab_bank[i][offset],current_codefile->object,current_codefile->size);

                /* Place le pointeur vers le début pour le JMP ,X */
                code_offset = (WORD) offset;
                memcpy(&tab_bank[i][BANK_HEADER_SIZE+k*sizeof(WORD)],&code_offset,sizeof(WORD));
                k++;

                /* Met à jour la taille restante du banc */
                bank_free_size -= (sizeof(WORD) + current_codefile->size);

                /* Ce code a été placé dans ce Bank */
                current_codefile->bank_number = i;
                current_codefile->index_bank = k-1;
                nb_store++;
              }
        }

      /** On va compacter ce bank = faire remonter le code **/
      if(bank_free_size > 0)
        {
          /* On remonte */
          memmove(&tab_bank[i][BANK_HEADER_SIZE+k*sizeof(WORD)],&tab_bank[i][BANK_HEADER_SIZE+k*sizeof(WORD)+bank_free_size],BANK_TOTAL_SIZE-(BANK_HEADER_SIZE+k*sizeof(WORD)+bank_free_size));

          /* On recalcule les offset */
          for(j=0; j<k; j++)
            {
              memcpy(&code_offset,&tab_bank[i][BANK_HEADER_SIZE+j*sizeof(WORD)],sizeof(WORD));
              code_offset -= (WORD) bank_free_size;
              memcpy(&tab_bank[i][BANK_HEADER_SIZE+j*sizeof(WORD)],&code_offset,sizeof(WORD));
            }

          /* Taille utilisée */
          bank_size = BANK_TOTAL_SIZE - bank_free_size;
        }
      else
        bank_size = BANK_TOTAL_SIZE;

      /** Création du fichier Bank **/
      strcpy(file_bank_path,file_folder_path);
      for(j=strlen(file_bank_path); j>=0; j--)
        if(file_bank_path[j] == FOLDER_SEPARATOR_CHAR)   /* \ or / */
          {
            file_bank_path[j+1] = '\0';
            break;
          }
      sprintf(&file_bank_path[strlen(file_bank_path)],"%s%02d.bin",bank_name,i);
      fd = fopen(file_bank_path,"wb");
      if(fd == NULL)
        printf("  Error : Impossible to create Bank file '%s'.\n",file_bank_path);
      else
        {
          fwrite(tab_bank[i],bank_size,1,fd);
          fclose(fd);
        }
    }

  /* Nombre de banc utilisés */
  *nb_bank_rtn = nb_bank;

  /**************************************************/
  /** Cas particulier, il reste encore des données **/
  /**************************************************/
  if(nb_store < nb_codefile)
    {
      /** On utilise le dernier Banc réservé exprès au cas où **/
      /* Init */
      bank_free_size = BANK_TOTAL_SIZE - BANK_HEADER_SIZE;
      offset = BANK_TOTAL_SIZE;

      /** On place le code d'entête **/
      memcpy(&tab_bank[nb_bank][0],header_code,BANK_HEADER_SIZE);

      /** On ajoute tous les Codes possibles dans ce Bank **/
      for(k=0,j=1; j<=nb_codefile; j++)
        {
          my_Memory(MEMORY_GET_CODEFILE,&j,&current_codefile);
          if(current_codefile->bank_number == -1)
            if(bank_free_size-2 > current_codefile->size)
              {
                /* Copie le code dans le banc */
                offset -= current_codefile->size;
                memcpy(&tab_bank[nb_bank][offset],current_codefile->object,current_codefile->size);

                /* Place le pointeur vers le début pour le JMP ,X */
                code_offset = (WORD) offset;
                memcpy(&tab_bank[nb_bank][BANK_HEADER_SIZE+k*sizeof(WORD)],&code_offset,sizeof(WORD));
                k++;

                /* Met à jour la taille restante du banc */
                bank_free_size -= (sizeof(WORD) + current_codefile->size);

                /* Ce code a été placé dans ce Bank */
                current_codefile->bank_number = nb_bank;
                current_codefile->index_bank = k-1;
                nb_store++;
              }
        }

      /** On va compacter ce bank = faire remonter le code **/
      if(bank_free_size > 0)
        {
          /* On remonte */
          memmove(&tab_bank[nb_bank][BANK_HEADER_SIZE+k*sizeof(WORD)],&tab_bank[nb_bank][BANK_HEADER_SIZE+k*sizeof(WORD)+bank_free_size],BANK_TOTAL_SIZE-(BANK_HEADER_SIZE+k*sizeof(WORD)+bank_free_size));

          /* On recalcule les offset */
          for(j=0; j<k; j++)
            {
              memcpy(&code_offset,&tab_bank[nb_bank][BANK_HEADER_SIZE+j*sizeof(WORD)],sizeof(WORD));
              code_offset -= (WORD) bank_free_size;
              memcpy(&tab_bank[nb_bank][BANK_HEADER_SIZE+j*sizeof(WORD)],&code_offset,sizeof(WORD));
            }

          /* Taille utilisée */
          bank_size = BANK_TOTAL_SIZE - bank_free_size;
        }
      else
        bank_size = BANK_TOTAL_SIZE;

      /** Création du fichier Bank **/
      strcpy(file_bank_path,file_folder_path);
      for(j=strlen(file_bank_path); j>=0; j--)
        if(file_bank_path[j] == FOLDER_SEPARATOR_CHAR)    /* \ or / */
          {
            file_bank_path[j+1] = '\0';
            break;
          }
      sprintf(&file_bank_path[strlen(file_bank_path)],"%s%02d.bin",bank_name,nb_bank);
      fd = fopen(file_bank_path,"wb");
      if(fd == NULL)
        printf("  Error : Impossible to create Bank file '%s'.\n",file_bank_path);
      else
        {
          fwrite(tab_bank[i],bank_size,1,fd);
          fclose(fd);
        }

      /* Nombre de banc utilisés */
      *nb_bank_rtn = nb_bank+1;
    }

  /* Libération mémoire des Bank */
  for(i=0; i<nb_bank+1; i++)
    free(tab_bank[i]);
  free(tab_bank);

  /* OK */
  return(0);
}


/****************************************************/
/*  CreateMainCode() :  Création du Code principal. */
/****************************************************/
int CreateMainCode(char *file_folder_path, char *bank_name, int nb_bank)
{
  int i, j, nb_codefile;
  FILE *fd;
  struct code_file *current_codefile;
  char file_source_path[1024];

  /** Création du fichier Source **/
  strcpy(file_source_path,file_folder_path);
  for(i=strlen(file_source_path); i>=0; i--)
    if(file_source_path[i] == FOLDER_SEPARATOR_CHAR)   /* \ or / */
      {
        file_source_path[i+1] = '\0';
        break;
      }
  sprintf(&file_source_path[strlen(file_source_path)],"%sSrc.txt",bank_name);
  fd = fopen(file_source_path,"w");
  if(fd == NULL)
    printf("  Error : Impossible to create Source file '%s'.\n",file_source_path);

  /* Nombre de Sprites */
  my_Memory(MEMORY_GET_CODEFILE_NB,&nb_codefile,NULL);

  /* Début du Source */
  fprintf(fd,"Draw%s\tASL\t\t; A=Sprite Number ($0000-$%04X)\n",bank_name,nb_codefile-1);
  fprintf(fd,"\tTAX\t\t; Y=Target Screen Address ($2000-$9D00)\n");
  fprintf(fd,"\tLDA\t%sNum,X\t; Relative Sprite Number Table\n",bank_name);
  fprintf(fd,"\tJMP\t(%sBank,X)\t; Bank Number Table\n",bank_name);
  fprintf(fd,"\n");

  /** Table des Numéros Relatifs des Sprite dans leur Banc **/
  fprintf(fd,"%sNum\tHEX\t",bank_name);
  for(i=1,j=0; i<=nb_codefile; i++)
    {
      if(j == 8)
        {
          j = 0;
          fprintf(fd,"\n\tHEX\t");
        }
      my_Memory(MEMORY_GET_CODEFILE,&i,&current_codefile);
      fprintf(fd,"%s%04X",(j==0 || i==1)?"":",",(unsigned int)ExchangeByte((WORD)current_codefile->index_bank));
      j++;
    }
  fprintf(fd,"\n");
  fprintf(fd,"\n");

  /** Table des Numéros de Banc des Sprites **/
  fprintf(fd,"%sBank\tDA\t",bank_name);
  for(i=1,j=0; i<=nb_codefile; i++)
    {
      if(j == 8)
        {
          j = 0;
          fprintf(fd,"\n\tDA\t");
        }
      my_Memory(MEMORY_GET_CODEFILE,&i,&current_codefile);
      fprintf(fd,"%s%sBank%02d",(j==0 || i==1)?"":",",bank_name,current_codefile->bank_number);
      j++;
    }
  fprintf(fd,"\n");
  fprintf(fd,"\n");

  /** Saut vers les bancs **/
  for(i=0; i<nb_bank; i++)
    {
      fprintf(fd,"%sBank%02d\tJSL\t$AA0000\n",bank_name,i);
      fprintf(fd,"\tPHK\n");
      fprintf(fd,"\tPLB\n");
      fprintf(fd,"\tRTS\n\n");
    }

  fprintf(fd,"*------------------------------------------------\n");

  /* Fermeture du fichier */
  fclose(fd);

  /* OK */
  return(0);
}

/********************************************************************/
