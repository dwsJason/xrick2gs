/********************************************************************
 *                                                                  *
 *    Dc_Graphic.c : Module de gestion des fichiers Graphiques.     *
 *                                                                  *
 ********************************************************************
 *  Auteur : Olivier ZARDINI  *  Brutal Deluxe  *  Date : Nov 2012  *
 ********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <ctype.h>

#include "Dc_Gif.h"
#include "Dc_Shared.h"
#include "Dc_Memory.h"
#include "Dc_Code.h"
#include "Dc_Graphic.h"

struct picture_256 *BuildSpritePicture(int,int,int,int,int,unsigned char,struct picture_256 *);
struct picture_256 *BuildByteImage(struct picture_256 *,char *,int);
int IsEmptyRow(int,int,int,int,struct picture_256 *);
int IsEmptyColumn(int,int,int,int,struct picture_256 *);
int ComputeDensity(struct picture_256 *,int,int,int);
int IsSpriteAdjacent(int,int,int *,int,int);

/*****************************************************************/
/*  DecodeRGBColor() :  Conversion d'une couleur Texte en DWORD. */
/*****************************************************************/
DWORD DecodeRGBColor(char *color_text)
{
  int i;
  DWORD color;

  /* Vérification */
  if(strlen(color_text) != strlen("FF00FF"))
    return(0xFFFFFFFF);
  for(i=0; i<(int)strlen("FF00FF"); i++)
    if(!((color_text[i] >= '0' && color_text[i] <= '9') || (toupper(color_text[i]) >= 'A' && toupper(color_text[i]) <= 'F')))
      return(0xFFFFFFFF);

  /* Conversion */
  sscanf(color_text,"%06X",&color);

  /* Renvoi la couleur */
  return(color);
}


/*************************************************************/
/*  ExtractAllSprite() :  Extrait les Sprites de la planche. */
/*************************************************************/
int ExtractAllSprite(char *file_path, DWORD bg_color, DWORD frame_color)
{
  int i, j, x, y, nb, result, bg_index, frame_index, found;
  int uleft_x, uleft_y, lright_x, lright_y;
  int sprite_width, sprite_height, sprite_index;
  int frame_width, frame_height, frame_uleft_x, frame_uleft_y;
  DWORD color;
  struct picture_256 *current_picture;
  struct picture_256 *work_picture;  
  struct picture_256 *sprite_picture;
  char sprite_file_path[1024];
  
  /** Charge l'image Gif en mémoire **/
  current_picture = GIFReadFileTo256Color(file_path);
  if(current_picture == NULL)
    {
      printf("  Error : Can't load GIF file '%s'.\n",file_path);
      return(1);
    }
  work_picture = GIFReadFileTo256Color(file_path);
  if(current_picture == NULL)
    {
      printf("  Error : Can't load GIF file '%s'.\n",file_path);
      mem_free_picture_256(current_picture);
      return(1);
    }
    
  /** Recherche l'indice de la couleur de fond / couleur de bordure **/
  for(i=0,bg_index=-1,frame_index=-1; i<current_picture->nb_color; i++)
    {
      color = current_picture->palette_red[i]<<16 | current_picture->palette_green[i]<<8 | current_picture->palette_blue[i];
      if(color == bg_color)
        bg_index = i;
      if(color == frame_color)
        frame_index = i;
    }

  /* Erreur */
  if(bg_index == -1)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't find background color %06X in palette.\n",bg_color);
      return(2);
    }

  /* Couleur de Bordure */
  if(frame_index == -1)
    {
      /* Ajoute la couleur de la bordure à la table des couleurs */
      frame_index = current_picture->nb_color;
      current_picture->palette_red[current_picture->nb_color] = (frame_color>>16) & 0xFF;
      current_picture->palette_green[current_picture->nb_color] = (frame_color>>8) & 0xFF;
      current_picture->palette_blue[current_picture->nb_color] = (frame_color) & 0xFF;
      current_picture->nb_color++;
    }

  /******************************************************/
  /***  Recherche des Sprites entourés par une Frame  ***/
  /******************************************************/
  /*** On efface les points Frame de l'image Current ***/
  for(j=0; j<current_picture->height; j++)
    for(i=0; i<current_picture->width; i++)
      if(current_picture->data[i+j*current_picture->width] == frame_index)
        current_picture->data[i+j*current_picture->width] = bg_index;

  /*** Recherche des Sprites Frame ***/
  for(sprite_index=0; ; sprite_index++)
    {
      /** Recherche un point de l'image qui est du Frame **/
      found = 0;
      for(j=0; j<work_picture->height; j++)
        {
          for(i=0; i<work_picture->width; i++)
            if(work_picture->data[i+j*work_picture->width] == frame_index)
              {
                found = 1;
                break;
              }
          if(found == 1)
            break;
        }
      /* Il n'y a plus de Sprite Frame dans l'image Work */
      if(found == 0)
        break;

      /** Zone rectangulaire Frame **/
      frame_uleft_x = i;
      frame_uleft_y = j;
      /* Largeur */
      for(i=frame_uleft_x; i<work_picture->width; i++)
        if(work_picture->data[i+frame_uleft_y*work_picture->width] != frame_index)
          break;
      frame_width = i - frame_uleft_x;
      /* Hauteur */
      for(j=frame_uleft_y; j<work_picture->height; j++)
        if(work_picture->data[frame_uleft_x+j*work_picture->width] != frame_index)
          break;
      frame_height = j - frame_uleft_y;

      /*** Réduction de la zone du Sprite ***/
      uleft_x = frame_uleft_x + 1;
      uleft_y = frame_uleft_y + 1;
      lright_x = frame_uleft_x + frame_width - 2;
      lright_y = frame_uleft_y + frame_height - 2;

#if 0
      /** Descend **/
      for(y=uleft_y,nb=0; y<lright_y; y++)
        {
          /* Que du fond sur la ligne ? */
          for(x=uleft_x,found=0; x<lright_x; x++)
            if(work_picture->data[x+y*work_picture->width] != bg_index)
              {
                found = 1;
                break;
              }
          if(found == 1)
            break;
          nb++;
        }
      uleft_y += nb;

      /** Monte **/
      for(y=lright_y,nb=0; y>uleft_y; y--)
        {
          /* Que du fond sur la ligne ? */
          for(x=uleft_x,found=0; x<lright_x; x++)
            if(work_picture->data[x+y*work_picture->width] != bg_index)
              {
                found = 1;
                break;
              }
          if(found == 1)
            break;
          nb++;
        }
      lright_y -= nb;

      /** -> Droite **/
      for(x=uleft_x,nb=0; x<lright_x; x++)
        {
          /* Que du fond sur la colonne ? */
          for(y=uleft_y,found=0; y<lright_y; y++)
            if(work_picture->data[x+y*work_picture->width] != bg_index)
              {
                found = 1;
                break;
              }
          if(found == 1)
            break;
          nb++;
        }
      uleft_x += nb;

      /** <- Gauche **/
      for(x=lright_x,nb=0; x>uleft_x; x--)
        {
          /* Que du fond sur la colonne ? */
          for(y=uleft_y,found=0; y<lright_y; y++)
            if(work_picture->data[x+y*work_picture->width] != bg_index)
              {
                found = 1;
                break;
              }
          if(found == 1)
            break;
          nb++;
        }
      lright_x -= nb;
#endif

      /** On aligne la largeur du Sprite sur 4 points **/
      sprite_width = lright_x - uleft_x + 1;
      if(sprite_width % 4 != 0)
        sprite_width += (4 - sprite_width%4);
      sprite_height = lright_y - uleft_y + 1;       
       
      /** Création du Sprite sur le Disque **/
      strcpy(sprite_file_path,file_path);
      sprintf(&sprite_file_path[strlen(sprite_file_path)-4],"_spr_%03d.gif",sprite_index);
      sprite_picture = BuildSpritePicture(uleft_x,uleft_y,lright_x-uleft_x+1,sprite_height,sprite_width,(unsigned char)bg_index,work_picture);
      if(sprite_picture == NULL)
        {
          mem_free_picture_256(work_picture);
          mem_free_picture_256(current_picture);
          printf("  Error : Can't build sprite picture.\n");
          return(5);
        }
      result = GIFWriteFileFrom256Color(sprite_file_path,sprite_picture);
      if(result)
        {
          mem_free_picture_256(work_picture);        
          mem_free_picture_256(current_picture);
          printf("  Error : Can't create sprite picture '%s'.\n",sprite_file_path);
          return(5);
        }
      mem_free_picture_256(sprite_picture);
       
      /** On efface le Sprite de l'image Work **/
      for(j=0; j<frame_height; j++)
        for(i=0; i<frame_width; i++)
          work_picture->data[i+frame_uleft_x+(j+frame_uleft_y)*work_picture->width] = bg_index;
       
      /** On dessine le cadre autour du Sprite sur l'image Current **/
      for(i=0; i<sprite_width+2; i++)
        {
          if((uleft_x-1+i) >= 0 && (uleft_x-1+i) < current_picture->width && (uleft_y-1) >= 0)
            current_picture->data[uleft_x-1+i + (uleft_y-1)*current_picture->width] = (unsigned char) frame_index;
          if((uleft_x-1+i) >= 0 && (uleft_x-1+i) < current_picture->width && (lright_y+1) < current_picture->height)
            current_picture->data[uleft_x-1+i + (lright_y+1)*current_picture->width] = (unsigned char) frame_index;
        }
      for(i=0; i<sprite_height+2; i++)
        {
          if((uleft_y-1+i) >= 0 && (uleft_y-1+i) < current_picture->height && (uleft_x-1) >= 0)
            current_picture->data[uleft_x-1 + (uleft_y-1+i)*current_picture->width] = (unsigned char) frame_index;
          if((uleft_y-1+i) >= 0 && (uleft_y-1+i) < current_picture->height && (uleft_x+sprite_width) < current_picture->width)
            current_picture->data[uleft_x+sprite_width + (uleft_y-1+i)*current_picture->width] = (unsigned char) frame_index;
        }
    }

  /********************************************/
  /***  Recherche des Sprites dans l'image  ***/
  /********************************************/
  for(; ; sprite_index++)
    {
      /** Recherche un point de l'image qui n'est pas du fond **/
      found = 0;
      for(j=0; j<work_picture->height; j++)
        {
          for(i=0; i<work_picture->width; i++)
            if(work_picture->data[i+j*work_picture->width] != bg_index)
              {
                found = 1;
                break;
              }
          if(found == 1)
            break;
        }
      /* Il n'y a plus de Sprite dans l'image Work */
      if(found == 0)
        break;
        
      /* On va étendre le rectangle du Sprite */
      uleft_x = i;
      uleft_y = j;
      lright_x = i;
      lright_y = j;
      
      /*** On part du rectangle de référence et on trace un rectangle englobant ***/
      while(1)
        {
          found = 0;

          /* Haut */
          if(uleft_y > 0)
            {
              for(i=(uleft_x==0)?0:uleft_x-1; i<((lright_x+1)>work_picture->width?work_picture->width:lright_x+1); i++)
                if(work_picture->data[i+(uleft_y-1)*work_picture->width] != bg_index)
                  {
                    found = 1;
                    uleft_y--;
                    break;
                  }
            }

          /* Bas */
          if(lright_y < work_picture->height-1)
            {
              for(i=(uleft_x==0)?0:uleft_x-1; i<((lright_x+1)>work_picture->width?work_picture->width:lright_x+1); i++)
                if(work_picture->data[i+(lright_y+1)*work_picture->width] != bg_index)
                  {
                    found = 1;
                    lright_y++;
                    break;
                  }
            }

          /* Gauche */
          if(uleft_x > 0)
            {
              for(j=(uleft_y==0)?0:uleft_y-1; j<((lright_y+1)>work_picture->height?work_picture->height:lright_y+1); j++)
                if(work_picture->data[(uleft_x-1)+j*work_picture->width] != bg_index)
                  {
                    found = 1;
                    uleft_x--;
                    break;
                  }
            }

          /* Droite */
          if(lright_x < work_picture->width-1)
            {
              for(j=(uleft_x==0)?0:uleft_y-1; j<((lright_y+1)>work_picture->height?work_picture->height:lright_y+1); j++)
                if(work_picture->data[(lright_x+1)+j*work_picture->width] != bg_index)
                  {
                    found = 1;
                    lright_x++;
                    break;
                  }
            }

          /* On a que du décor autour du sprite */
          if(found == 0)
            break;
        }

      /** On aligne la largeur du Sprite sur 4 points **/
      sprite_width = lright_x - uleft_x + 1;
      if(sprite_width % 4 != 0)
        sprite_width += (4 - sprite_width%4);
      sprite_height = lright_y - uleft_y + 1;       
       
      /** Création du Sprite sur le Disque **/
      strcpy(sprite_file_path,file_path);
      sprintf(&sprite_file_path[strlen(sprite_file_path)-4],"_spr_%03d.gif",sprite_index);
      sprite_picture = BuildSpritePicture(uleft_x,uleft_y,lright_x-uleft_x+1,sprite_height,sprite_width,(unsigned char)bg_index,work_picture);
      if(sprite_picture == NULL)
        {
          mem_free_picture_256(work_picture);
          mem_free_picture_256(current_picture);
          printf("  Error : Can't build sprite picture.\n");
          return(5);
        }
      result = GIFWriteFileFrom256Color(sprite_file_path,sprite_picture);
      if(result)
        {
          mem_free_picture_256(work_picture);        
          mem_free_picture_256(current_picture);
          printf("  Error : Can't create sprite picture '%s'.\n",sprite_file_path);
          return(5);
        }
      mem_free_picture_256(sprite_picture);
       
      /** On efface le Sprite de l'image Work **/
      for(j=0; j<lright_y - uleft_y + 1; j++)
        for(i=0; i<lright_x - uleft_x + 1; i++)
          work_picture->data[i+uleft_x+(j+uleft_y)*work_picture->width] = bg_index;
       
      /** On dessine le cadre autour du Sprite sur l'image Current **/
      for(i=0; i<sprite_width+2; i++)
        {
          if((uleft_x-1+i) >= 0 && (uleft_x-1+i) < current_picture->width && (uleft_y-1) >= 0)
            current_picture->data[uleft_x-1+i + (uleft_y-1)*current_picture->width] = (unsigned char) frame_index;
          if((uleft_x-1+i) >= 0 && (uleft_x-1+i) < current_picture->width && (lright_y+1) < current_picture->height)
            current_picture->data[uleft_x-1+i + (lright_y+1)*current_picture->width] = (unsigned char) frame_index;
        }
      for(i=0; i<sprite_height+2; i++)
        {
          if((uleft_y-1+i) >= 0 && (uleft_y-1+i) < current_picture->height && (uleft_x-1) >= 0)
            current_picture->data[uleft_x-1 + (uleft_y-1+i)*current_picture->width] = (unsigned char) frame_index;
          if((uleft_y-1+i) >= 0 && (uleft_y-1+i) < current_picture->height && (uleft_x+sprite_width) < current_picture->width)
            current_picture->data[uleft_x+sprite_width + (uleft_y-1+i)*current_picture->width] = (unsigned char) frame_index;
        } 
    }

  /* Libération de l'image de travail */
  mem_free_picture_256(work_picture);

  /** Enregistre l'image avec les frames **/
  strcpy(sprite_file_path,file_path);
  strcpy(&sprite_file_path[strlen(sprite_file_path)-4],"_frame.gif");
  result = GIFWriteFileFrom256Color(sprite_file_path,current_picture);
  if(result)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't create frame picture '%s'.\n",sprite_file_path);
      return(5);
    }
    
  /* Libération mémoire */
  mem_free_picture_256(current_picture);

  /* OK */
  return(0);
}


/*******************************************************************/
/* BuildSpritePicture() :  Construit l'image avec juste le sprite. */
/*******************************************************************/
struct picture_256 *BuildSpritePicture(int x, int y, int sprite_width, int sprite_height, int picture_width, unsigned char bg_index, struct picture_256 *current_picture)
{
  int i, j;
  struct picture_256 *sprite_picture;

  /* Allocation structure */
  sprite_picture = (struct picture_256 *) calloc(1,sizeof(struct picture_256));
  if(sprite_picture == NULL)
    return(NULL);
  sprite_picture->data = (unsigned char *) calloc(picture_width*sprite_height,sizeof(unsigned char));
  if(sprite_picture->data == NULL)
    {
      free(sprite_picture);
      return(NULL);
    }
  memset(sprite_picture->data,bg_index,picture_width*sprite_height);

  /* Initialisation */
  sprite_picture->width = picture_width;
  sprite_picture->height = sprite_height;

  /** On place les points **/
  for(i=0; i<sprite_width; i++)
    for(j=0; j<sprite_height; j++)
      sprite_picture->data[i+j*sprite_picture->width] = (unsigned char) current_picture->data[x+i+(j+y)*current_picture->width];

  /* On place les couleurs */
  sprite_picture->nb_color = current_picture->nb_color;
  memcpy(&sprite_picture->palette_red[0],&current_picture->palette_red[0],256*sizeof(int));
  memcpy(&sprite_picture->palette_green[0],&current_picture->palette_green[0],256*sizeof(int));
  memcpy(&sprite_picture->palette_blue[0],&current_picture->palette_blue[0],256*sizeof(int));

  /* Renvoi l'image */
  return(sprite_picture);
}


/**********************************************************/
/*  CreateMirrorPicture() :  Création de l'image mirroir. */
/**********************************************************/
int CreateMirrorPicture(char *file_path, DWORD bg_color)
{
  int i, j, x, c, result, bg_index, found;
  DWORD color;
  struct picture_256 *current_picture;
  struct picture_256 *mirror_picture;
  char sprite_file_path[1024];
  
  /** Charge l'image Gif en mémoire **/
  current_picture = GIFReadFileTo256Color(file_path);
  if(current_picture == NULL)
    {
      printf("  Error : Can't load GIF file '%s'.\n",file_path);
      return(1);
    }
    
  /** Recherche l'indice de la couleur de fond **/
  for(i=0,bg_index=-1; i<current_picture->nb_color; i++)
    {
      color = current_picture->palette_red[i]<<16 | current_picture->palette_green[i]<<8 | current_picture->palette_blue[i];
      if(color == bg_color)
        bg_index = i;
    }

  /* Erreur */
  if(bg_index == -1)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't find background color %06X in palette.\n",bg_color);
      return(2);
    }

  /** On recherche la colonne la + à droite ayant des points **/
  found = 0;
  for(x=current_picture->width-1; x>=0; x--)
    {
      for(j=0; j<current_picture->height; j++)
        if(current_picture->data[x+j*current_picture->width] != (unsigned char) bg_index)
          {
            found = 1;
            break;
          }
      if(found == 1)
        break;
    }
  if(found == 0)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't create mirror for empty picture.\n");
      return(3);
    }

  /** Création de l'image mirroir **/
  mirror_picture = CreateEmptyPicture(current_picture->width,current_picture->height,current_picture->nb_color,&current_picture->palette_red[0],&current_picture->palette_green[0],&current_picture->palette_blue[0],(unsigned char)bg_index);
  if(mirror_picture == NULL)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't allocate memory for mirror picture.\n");
      return(4);
    }

  /*** On transfert les pixels en mode mirroir ***/
  for(i=x,c=0; i>=0; i--,c++)
    for(j=0; j<current_picture->height; j++)
      mirror_picture->data[c+j*current_picture->width] = current_picture->data[i+j*current_picture->width];

  /* Libération de l'image d'origine */
  mem_free_picture_256(current_picture);

  /** Enregistre l'image mirroir **/
  strcpy(sprite_file_path,file_path);
  strcpy(&sprite_file_path[strlen(sprite_file_path)-4],"m.gif");
  result = GIFWriteFileFrom256Color(sprite_file_path,mirror_picture);
  if(result)
    {
      mem_free_picture_256(mirror_picture);
      printf("  Error : Can't create mirror picture '%s'.\n",sprite_file_path);
      return(5);
    }
    
  /* Libération mémoire */
  mem_free_picture_256(mirror_picture);

  /* OK */
  return(0);
}


/*********************************************************/
/*  CreateFlipPicture() :  Création de l'image inversée. */
/*********************************************************/
int CreateFlipPicture(char *file_path, DWORD bg_color)
{
  int i, j, result, bg_index;
  DWORD color;
  struct picture_256 *current_picture;
  struct picture_256 *flip_picture;
  char sprite_file_path[1024];
  
  /** Charge l'image Gif en mémoire **/
  current_picture = GIFReadFileTo256Color(file_path);
  if(current_picture == NULL)
    {
      printf("  Error : Can't load GIF file '%s'.\n",file_path);
      return(1);
    }
    
  /** Recherche l'indice de la couleur de fond **/
  for(i=0,bg_index=-1; i<current_picture->nb_color; i++)
    {
      color = current_picture->palette_red[i]<<16 | current_picture->palette_green[i]<<8 | current_picture->palette_blue[i];
      if(color == bg_color)
        bg_index = i;
    }

  /* Erreur */
  if(bg_index == -1)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't find background color %06X in palette.\n",bg_color);
      return(2);
    }

  /** Création de l'image mirroir **/
  flip_picture = CreateEmptyPicture(current_picture->width,current_picture->height,current_picture->nb_color,&current_picture->palette_red[0],&current_picture->palette_green[0],&current_picture->palette_blue[0],(unsigned char)bg_index);
  if(flip_picture == NULL)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't allocate memory for flip picture.\n");
      return(4);
    }

  /*** On transfert les pixels en mode inversé ***/
  for(j=0; j<current_picture->height; j++)
    for(i=0; i<current_picture->width; i++)
      flip_picture->data[i+(current_picture->height-j-1)*current_picture->width] = current_picture->data[i+j*current_picture->width];

  /* Libération de l'image d'origine */
  mem_free_picture_256(current_picture);

  /** Enregistre l'image inversée **/
  strcpy(sprite_file_path,file_path);
  strcpy(&sprite_file_path[strlen(sprite_file_path)-4],"f.gif");
  result = GIFWriteFileFrom256Color(sprite_file_path,flip_picture);
  if(result)
    {
      mem_free_picture_256(flip_picture);
      printf("  Error : Can't create flip picture '%s'.\n",sprite_file_path);
      return(5);
    }
    
  /* Libération mémoire */
  mem_free_picture_256(flip_picture);

  /* OK */
  return(0);
}


/*******************************************************/
/*  CreateOddPicture() :  Création de l'image impaire. */
/*******************************************************/
int CreateOddPicture(char *file_path, DWORD bg_color)
{
  int i, j, result, bg_index, found;
  DWORD color;
  struct picture_256 *current_picture;
  struct picture_256 *odd_picture;
  char sprite_file_path[1024];
  
  /** Charge l'image Gif en mémoire **/
  current_picture = GIFReadFileTo256Color(file_path);
  if(current_picture == NULL)
    {
      printf("  Error : Can't load GIF file '%s'.\n",file_path);
      return(1);
    }
    
  /** Recherche l'indice de la couleur de fond **/
  for(i=0,bg_index=-1; i<current_picture->nb_color; i++)
    {
      color = current_picture->palette_red[i]<<16 | current_picture->palette_green[i]<<8 | current_picture->palette_blue[i];
      if(color == bg_color)
        bg_index = i;
    }

  /* Erreur */
  if(bg_index == -1)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't find background color %06X in palette.\n",bg_color);
      return(2);
    }

  /** Détermine la taille de l'image : Doit on ajouter 4 points de plus ? **/
  found = 0;
  for(j=0; j<current_picture->height; j++)
    if(current_picture->data[current_picture->width-1+j*current_picture->width] != (unsigned char) bg_index)
      {
        found = 1;
        break;
      }

  /** Création de l'image mirroir **/
  odd_picture = CreateEmptyPicture(current_picture->width+4*found,current_picture->height,current_picture->nb_color,&current_picture->palette_red[0],&current_picture->palette_green[0],&current_picture->palette_blue[0],(unsigned char)bg_index);
  if(odd_picture == NULL)
    {
      mem_free_picture_256(current_picture);
      printf("  Error : Can't allocate memory for odd picture.\n");
      return(4);
    }

  /*** On transfert les pixels en mode impaire ***/
  for(j=0; j<current_picture->height; j++)
    for(i=0; i<current_picture->width-1+found; i++)
      odd_picture->data[i+1+j*odd_picture->width] = current_picture->data[i+j*current_picture->width];

  /* Libération de l'image d'origine */
  mem_free_picture_256(current_picture);

  /** Enregistre l'image inversée **/
  strcpy(sprite_file_path,file_path);
  strcpy(&sprite_file_path[strlen(sprite_file_path)-4],"o.gif");
  result = GIFWriteFileFrom256Color(sprite_file_path,odd_picture);
  if(result)
    {
      mem_free_picture_256(odd_picture);
      printf("  Error : Can't create odd picture '%s'.\n",sprite_file_path);
      return(5);
    }
    
  /* Libération mémoire */
  mem_free_picture_256(odd_picture);

  /* OK */
  return(0);
}


/********************************************************/
/*  CreateEmptyPicture() :  Création d'une image vide.  */
/********************************************************/
struct picture_256 *CreateEmptyPicture(int width, int height, int nb_color, int *palette_red, int *palette_green, int *palette_blue, unsigned char bg_index)
{
  struct picture_256 *current_picture;

  /** Allocation mémoire **/
  current_picture = (struct picture_256 *) calloc(1,sizeof(struct picture_256));
  if(current_picture == NULL)
    return(NULL);
  current_picture->width = width;
  current_picture->height = height;
  current_picture->data = (unsigned char *) calloc(current_picture->width*current_picture->height,sizeof(unsigned char));
  if(current_picture->data == NULL)
    {
      free(current_picture);
      return(NULL);
    }
  memset(current_picture->data,bg_index,current_picture->width*current_picture->height);

  /** Copie les couleurs **/
  current_picture->nb_color = nb_color;
  memcpy(&current_picture->palette_red[0],palette_red,256*sizeof(int));
  memcpy(&current_picture->palette_green[0],palette_green,256*sizeof(int));
  memcpy(&current_picture->palette_blue[0],palette_blue,256*sizeof(int));

  /* Renvoie l'image */
  return(current_picture);
}


/*************************************************************************/
/*  IsEmptyRow() :  Vérifie si une ligne est composée de pixels du fond. */
/*************************************************************************/
int IsEmptyRow(int x, int y, int length, int bg_index, struct picture_256 *current_picture)
{
  int i;

  /* Passe en revue tous les points de la ligne */
  for(i=0; i<length; i++)
    if((x+i < current_picture->width) && y < current_picture->height)
      if(current_picture->data[x+i + y*current_picture->width] != (unsigned char) bg_index)
        return(0);

  /* OK */
  return(1);
}


/******************************************************************************/
/*  IsEmptyColumn() :  Vérifie si une colonne est composée de pixels du fond. */
/******************************************************************************/
int IsEmptyColumn(int x, int y, int length, int bg_index, struct picture_256 *current_picture)
{
  int j;

  /* Passe en revue tous les points de la colonne */
  for(j=0; j<length; j++)
    if((x < current_picture->width) && y+j < current_picture->height)
      if(current_picture->data[x + (y+j)*current_picture->width] != (unsigned char) bg_index)
        return(0);

  /* OK */
  return(1);
}


/*********************************************************************************************************/
/*  IsSpriteAdjacent() :  Regarde si les cases autour ont déjà été marquées comme appartenant au sprite. */
/*********************************************************************************************************/
int IsSpriteAdjacent(int width, int height, int *density_tab, int tab_width, int tab_height)
{
  /** On regarde les 4 cases autour **/
  /* A gauche */
  if(width > 0)
    if(density_tab[(width-1)+height*tab_width] == -1)
      return(1);

  /* A droite */
  if(width < (tab_width-1))
    if(density_tab[(width+1)+height*tab_width] == -1)
      return(1);

  /* En haut */
  if(height > 0)
    if(density_tab[width+(height-1)*tab_width] == -1)
      return(1);

  /* En bas */
  if(height < (tab_height-1))
    if(density_tab[width+(height+1)*tab_width] == -1)
      return(1);

  /* Non */
  return(0);
}

/*****************************************************************************/
/*  ComputeDensity() :  Calcule le nombre de point qui ne sont pas du foond. */
/*****************************************************************************/
int ComputeDensity(struct picture_256 *current_picture, int width, int height, int bg_index)
{
  int i, j, density;

  /* Init */
  density = 0;

  /** Calcule la densité de point **/
  for(i=0; i<16; i++)
    for(j=0; j<16; j++)
      if((16*width + i < current_picture->width) && (16*height + j < current_picture->height))
        if(current_picture->data[16*width + i + (height*16+j)*current_picture->width] != (unsigned char) bg_index)
          density++;

  /* Renvoi la densité */
  return(density);
}


/******************************************************************/
/*  RemoveDuplicatedPictures() :  Supprime les images en doubles. */
/******************************************************************/
int RemoveDuplicatedPictures(int nb_file, char **tab_file)
{
  int i, j, result;
  struct picture_true **picture_tab;

  /* Allocation mémoire */
  picture_tab = (struct picture_true **) calloc(nb_file,sizeof(struct picture_true *));
  if(picture_tab == NULL)
    {
      printf("  Error : Can't allocate memory for table picture_tab.\n");
      return(1);
    }

  /** Charge tous les fichiers **/
  for(i=0; i<nb_file; i++)
    {
      /* On charge les fichiers comme des images True Color */
      picture_tab[i] = GIFReadFileToRGB(tab_file[i]);
      if(picture_tab[i] == NULL)
        {
           printf("  Error : Can't load file '%s'.\n",tab_file[i]);
          continue;
        }
    }

  /** Compare les fichiers entre eux **/
  for(i=0; i<nb_file; i++)
    for(j=i+1; j<nb_file; j++)
      if(picture_tab[i] != NULL && picture_tab[j] != NULL)
        {
          /* Compare les deux fichiers */
          if(picture_tab[i]->width == picture_tab[j]->width && picture_tab[i]->height == picture_tab[j]->height)
            {
              result = memcmp(picture_tab[i]->data,picture_tab[j]->data,picture_tab[i]->width*picture_tab[i]->height*3);
              if(result == 0)
                {
                  /* On peut supprimer j */
                  mem_free_picture_true(picture_tab[j]);
                  picture_tab[j] = NULL;
                  printf("  - Delete duplicated file '%s'.\n",tab_file[j]);
                  remove(tab_file[j]);
                }
            }
        }

  /* Libération mémoire */
  for(i=0; i<nb_file; i++)
    if(picture_tab[i] != NULL)
      mem_free_picture_true(picture_tab[i]);
  free(picture_tab);

  /* OK */
  return(0);
}


/**************************************************************************/
/*  CreateWallPaper() : Création d'une image regroupant tous les sprites. */
/**************************************************************************/
int CreateWallPaper(int nb_file, char **tab_file, DWORD color_bg, DWORD color_frame)
{
  int i, j, k, found, result, max_width, max_height, nb_picture_per_line, nb_line, nb_picture, sprite_number, offset;
  int box_width, box_height, box_uleft_x, box_uleft_y, pict_uleft_x, pict_uleft_y;
  unsigned char bg_red, bg_green, bg_blue, frame_red, frame_green, frame_blue;
  struct picture_true **picture_tab;
  struct picture_true *wall_picture;
  struct picture_256 *current_picture;
  char file_path[1024];

  /* Couleur de fond */
  bg_red = (unsigned char) (0x000000FF & (color_bg >> 16));
  bg_green = (unsigned char) (0x000000FF & (color_bg >> 8));
  bg_blue = (unsigned char) (0x000000FF & color_bg);

  /* Couleur de frame */
  frame_red = (unsigned char) (0x000000FF & (color_frame >> 16));
  frame_green = (unsigned char) (0x000000FF & (color_frame >> 8));
  frame_blue = (unsigned char) (0x000000FF & color_frame);

  /* Allocation mémoire */
  picture_tab = (struct picture_true **) calloc(nb_file,sizeof(struct picture_true *));
  if(picture_tab == NULL)
    {
      printf("  Error : Can't allocate memory for table picture_tab.\n");
      return(1);
    }

  /** Charge tous les fichiers **/
  max_width = 0;
  max_height = 0;
  nb_picture = 0;
  for(i=0; i<nb_file; i++)
    {
      /* On charge les fichiers comme des images True Color */
      picture_tab[i] = GIFReadFileToRGB(tab_file[i]);
      if(picture_tab[i] == NULL)
        {
          printf("  Error : Can't load file '%s'.\n",tab_file[i]);
          continue;
        }

      /* Récupère les tailles Max */
      if(picture_tab[i]->width > max_width)
        max_width = picture_tab[i]->width;
      if(picture_tab[i]->height > max_height)
        max_height = picture_tab[i]->height;

      /* Nombre d'image */
      nb_picture++;
    }

  /* Nombre d'image sur une ligne / Nombre de ligne d'image */
  nb_picture_per_line = 10;
  if(max_width*20 < 1024)
    nb_picture_per_line = 20;
  nb_line = nb_picture / nb_picture_per_line;
  if(nb_line*nb_picture_per_line < nb_picture)
    nb_line++;

  /** Allocation de l'image Wall **/
  wall_picture = (struct picture_true *) calloc(1,sizeof(struct picture_true));
  if(wall_picture == NULL)
    {
      printf("  Error : Can't allocate memory for picture wall_picture.\n");
      for(i=0; i<nb_file; i++)
        mem_free_picture_true(picture_tab[i]);
      free(picture_tab);
      return(1);
    }
  wall_picture->width = nb_picture_per_line*(max_width + 4);
  wall_picture->height = nb_line*(max_height+4+9);
  wall_picture->data = (unsigned char *) calloc(1,3*wall_picture->width*wall_picture->height);
  if(wall_picture->data == NULL)
    {
      printf("  Error : Can't allocate memory for picture wall_picture.\n");
      free(wall_picture);
      for(i=0; i<nb_file; i++)
        mem_free_picture_true(picture_tab[i]);
      free(picture_tab);
      return(1);
    }
  /* On met la couleur de fond */
  for(i=0; i<wall_picture->width*wall_picture->height; i++)
    {
      wall_picture->data[3*i+0] = bg_red;
      wall_picture->data[3*i+1] = bg_green;
      wall_picture->data[3*i+2] = bg_blue;
    }
  box_width = max_width+2;
  box_height = max_height+2+9;

  /*** Création du contenu de l'image ***/
  nb_picture = 0;
  for(j=0; j<nb_line; j++)
    {
      for(i=0; i<nb_picture_per_line; i++)
        {
          /* On attend une image valide */
          while(picture_tab[nb_picture] == NULL)
            {
              nb_picture++;
              if(nb_picture >= nb_file)
                break;
            }

          /* Coin en haut à gauche de la box */
          box_uleft_x = 2 + i*box_width;
          box_uleft_y = 2 + j*box_height;

          /* Coin en haut à gauche de l'image dans la box */
          pict_uleft_x = (max_width - picture_tab[nb_picture]->width)/2;   /* On centre l'image dans la Box */
          pict_uleft_y = max_height - picture_tab[nb_picture]->height;     /* On place l'image en bas de la box */

          /** Copie l'image dans la box **/
          for(k=0; k<picture_tab[nb_picture]->height; k++)
            memcpy(&wall_picture->data[3*(box_uleft_x+pict_uleft_x + (box_uleft_y+pict_uleft_y+k)*wall_picture->width)],&picture_tab[nb_picture]->data[3*k*picture_tab[nb_picture]->width],3*picture_tab[nb_picture]->width);

          /** Trace les contours de la Frame **/
          for(k=0; k<2+picture_tab[nb_picture]->width; k++)
            {
              PlotTrueColor(box_uleft_x+pict_uleft_x-1+k,box_uleft_y+pict_uleft_y-1,frame_red,frame_green,frame_blue,wall_picture);
              PlotTrueColor(box_uleft_x+pict_uleft_x-1+k,box_uleft_y+pict_uleft_y+picture_tab[nb_picture]->height,frame_red,frame_green,frame_blue,wall_picture);
            }
          for(k=0; k<2+picture_tab[nb_picture]->height; k++)
            {
              PlotTrueColor(box_uleft_x+pict_uleft_x-1,box_uleft_y+pict_uleft_y-1+k,frame_red,frame_green,frame_blue,wall_picture);
              PlotTrueColor(box_uleft_x+pict_uleft_x+picture_tab[nb_picture]->width,box_uleft_y+pict_uleft_y-1+k,frame_red,frame_green,frame_blue,wall_picture);
            }

          /** Place le numéro de l'image en dessous **/
          sprite_number = 0;
          strcpy(file_path,tab_file[nb_picture]);
          file_path[strlen(file_path)-4] = '\0';
          for(k=strlen(file_path); k>=0; k--)
            if(file_path[k] == '_')
              {
                sprite_number = atoi(&file_path[k+1]);
                break;
              }
          if(nb_picture >= 100)
            {
              /* 3 chiffres */
              offset = PlotNumber(sprite_number/100,box_uleft_x+box_width/2-8,box_uleft_y+box_height-8,frame_red,frame_green,frame_blue,wall_picture);
              offset += PlotNumber(sprite_number/10-10*(sprite_number/100),box_uleft_x+box_width/2-8+offset+1,box_uleft_y+box_height-8,frame_red,frame_green,frame_blue,wall_picture);
              offset += PlotNumber(sprite_number-10*(sprite_number/10),box_uleft_x+box_width/2-8+offset+2,box_uleft_y+box_height-8,frame_red,frame_green,frame_blue,wall_picture);
            }
          else if(nb_picture >= 10)
            {
              /* 2 chiffres */
              offset = PlotNumber(sprite_number/10,box_uleft_x+box_width/2-5,box_uleft_y+box_height-8,frame_red,frame_green,frame_blue,wall_picture);
              offset += PlotNumber(sprite_number-10*(sprite_number/10),box_uleft_x+box_width/2-5+offset+1,box_uleft_y+box_height-8,frame_red,frame_green,frame_blue,wall_picture);
            }
          else
            {
              /* 1 chiffre */
              offset = PlotNumber(sprite_number,box_uleft_x+box_width/2-2,box_uleft_y+box_height-8,frame_red,frame_green,frame_blue,wall_picture);
            }

          /* Image suivante */
          nb_picture++;
          if(nb_picture == nb_file)
            break;
        }

      /* Fin */
      if(nb_picture == nb_file)
        break;
    }

  /** Conversion True Color -> 256 Couleurs **/
  current_picture = ConvertTrueColorTo256(wall_picture);
  if(current_picture == NULL)
    {
      printf("  - Error : Can't convert Wall picture to 256 colors.\n");
      mem_free_picture_true(wall_picture);
      for(i=0; i<nb_file; i++)
        mem_free_picture_true(picture_tab[i]);
      free(picture_tab);
      return(1);
    }

  /** Création de l'image GIF **/
  strcpy(file_path,tab_file[0]);
  for(i=strlen(file_path),found=0; i>=0; i--)
    if(file_path[i] == FOLDER_SEPARATOR_CHAR)            /* \ or / */
      {
        for(; i<(int)strlen(file_path); i++)
          if(file_path[i] == '_')
            {
              strcpy(&file_path[i],"_Wall.gif");
              found = 1;
              break;
            }
        break;
      }
  if(found == 0)
    strcpy(&file_path[strlen(file_path)-4],"_Wall.gif");
  result = GIFWriteFileFrom256Color(file_path,current_picture);
  if(result)
    printf("  - Error : Can't create Wall picture '%s'.\n",file_path);

  /* Libération mémoire */
  mem_free_picture_256(current_picture);
  mem_free_picture_true(wall_picture);
  for(i=0; i<nb_file; i++)
    mem_free_picture_true(picture_tab[i]);
  free(picture_tab);

  /* OK */
  return(0);
}


/*******************************************************************/
/*  CreateSpriteCode() : Création du code d'affichage d'un sprite. */
/*******************************************************************/
int CreateSpriteCode(char *file_path, DWORD color_bg, int nb_palette_color, DWORD *palette_16, int verbose)
{
  int i, j, nb_codeline, sprite_number, nb_bytes, nb_cycles, nb_max_cycles;
  FILE *fd;
  DWORD color;
  struct picture_256 *current_picture;
  struct picture_256 *byte_picture;
  struct code_line *current_codeline;
  unsigned char index_map[256];
  char code_file_path[1024];
  char buffer[1024];

  /** Extrait le numéro du sprite du nom _nb.gif **/
  sprite_number = 0;
  for(i=(int)strlen(file_path)-1; i>=0; i--)
    if(file_path[i] == '_')
      {
        strcpy(buffer,&file_path[i+1]);
        for(i=0; i<(int)strlen(buffer); i++)
          if(buffer[i] == '.')
            {
              buffer[i] = '\0';
              break;
            }
        for(i=0; i<(int)strlen(buffer); i++)
          if(buffer[i] != '0')
            {
              sprite_number = atoi(&buffer[i]);
              break;
            }
        break;
      }

  /** Charge l'image Gif en mémoire **/
  current_picture = GIFReadFileTo256Color(file_path);
  if(current_picture == NULL)
    {
      printf("  Error : Can't load GIF file '%s'.\n",file_path);
      return(1);
    }

  /* Init */
  for(i=0; i<256; i++)
    index_map[i] = 0xAA;

  /** Remappage de la palette avec les couleurs 0x00-0x0F et la couleur de fond en 0xFF **/
  for(i=0; i<current_picture->nb_color; i++)
    {
      color = ((DWORD)current_picture->palette_red[i]) << 16 | ((DWORD)current_picture->palette_green[i]) << 8 | ((DWORD)current_picture->palette_blue[i]);
      if(color == color_bg)
        {
          index_map[i] = 0xFF;
          continue;
        }
      for(j=0; j<nb_palette_color; j++)
        if(color == palette_16[j])
          {
            index_map[i] = j;
            break;
          }
    }
  /* Couleur de Fond */
  current_picture->palette_red[0xFF] = (unsigned char) (color_bg>>16);
  current_picture->palette_green[0xFF] = (unsigned char) (color_bg>>8);
  current_picture->palette_blue[0xFF] = (unsigned char) (color_bg);

  /** Remappage de l'image avec les couleurs 0x00-0x0F et la couleur de fond en 0xFF **/
  for(i=0; i<current_picture->width*current_picture->height; i++)
    if(index_map[current_picture->data[i]] == 0xAA)
      {
        printf("  Error : Picture color %02X%02X%02X is unknown.\n",current_picture->palette_red[current_picture->data[i]],current_picture->palette_green[current_picture->data[i]],current_picture->palette_blue[current_picture->data[i]]);
        mem_free_picture_256(current_picture);
        return(1);
      }
    else
      current_picture->data[i] = index_map[current_picture->data[i]];

  /*** Construit l'image simplifiée BYTE du sprite ***/
  byte_picture = BuildByteImage(current_picture,file_path,verbose);
  if(byte_picture == NULL)
    {
      printf("  Error : Imposible to create BYTE Picture.\n");
      mem_free_picture_256(current_picture);
      return(1);
    }

  /*** Création des lignes de code ***/
  BuildCodeLine(current_picture,byte_picture,sprite_number);

  /** Création du fichier contenant le code **/
  strcpy(code_file_path,file_path);
  strcpy(&code_file_path[strlen(code_file_path)-4],".txt");
  fd = fopen(code_file_path,"w");
  if(fd == NULL)
    {
      printf("  Error : Can't create Code file '%s'.\n",code_file_path);
      mem_free_picture_256(current_picture);
      return(1);
    }

  /** Ecriture des lignes de code dans le fichier Source **/
  nb_bytes = 0;
  nb_cycles = 0;
  my_Memory(MEMORY_GET_CODELINE_NB,&nb_codeline,NULL);
  for(i=1; i<=nb_codeline; i++)
    {
      my_Memory(MEMORY_GET_CODELINE,&i,&current_codeline);
      fprintf(fd,"%s\t%s\t%s%s%s\n",current_codeline->label,current_codeline->opcode,current_codeline->operand,
                                    strlen(current_codeline->comment)>0?"\t":"",strlen(current_codeline->comment)>0?current_codeline->comment:"");
      nb_bytes += current_codeline->nb_byte;
      nb_cycles += current_codeline->nb_cycle;
    }

  /* Fermeture du fichier */
  fclose(fd);

  /* Statistiques */
  nb_max_cycles = 5 + byte_picture->height*(3+(byte_picture->width/2)*31-1+41) - 1;
  printf("     => %d*%d pixels, %d bytes (%d), %d cycles (%d).\n",2*byte_picture->width,byte_picture->height,nb_bytes,2*byte_picture->width*byte_picture->height,nb_cycles,nb_max_cycles);

  /* Libération mémoire */
  mem_free_picture_256(byte_picture);
  mem_free_picture_256(current_picture);

  /* OK */
  return(0);
}


/***************************************************************/
/*  BuildByteImage() :  Construit une version BYTE de l'image. */
/***************************************************************/
struct picture_256 *BuildByteImage(struct picture_256 *current_picture, char *sprite_path, int verbose)
{
  int x, y, i, j, next_x, is_full_red, is_full_red_left, is_full_red_right, is_full_red_around, is_full_blue;
  int total, nb_ff, nb_bb, nb_cc, nb_99, nb_aa, nb_dd, nb_pattern, nb_red, nb_blue, nb_modif;
  int pattern_coef_1, pattern_coef_2, score;
  int length, result;
  struct picture_256 *byte_picture;
  struct pattern *current_pattern;
  char file_path[1024];
  WORD pattern;

  /* Init */
  nb_ff = 0;
  nb_bb = 0;
  nb_cc = 0;

  /* Allocation mémoire */
  byte_picture = (struct picture_256 *) calloc(1,sizeof(struct picture_256));
  if(byte_picture == NULL)
    return(NULL);
  byte_picture->height = current_picture->height;
  byte_picture->width = current_picture->width/2;
  byte_picture->data = (unsigned char *) calloc(byte_picture->width*byte_picture->height,sizeof(unsigned char));
  if(byte_picture->data == NULL)
    {
      free(byte_picture);
      return(NULL);
    }

  /** Couleurs **/
  byte_picture->nb_color = 256;
  /* 0xFF : Background (Byte contenant 2 points de fond) */
  byte_picture->palette_red[0xFF] = current_picture->palette_red[0xFF];
  byte_picture->palette_green[0xFF] = current_picture->palette_green[0xFF];
  byte_picture->palette_blue[0xFF] = current_picture->palette_blue[0xFF];
  /* 0xBB : Blue (Byte contenant 1 point du décor et 1 point du sprite) */
  byte_picture->palette_red[0xBB] = 0x00;
  byte_picture->palette_green[0xBB] = 0x00;
  byte_picture->palette_blue[0xBB] = 0xFF;
  /* 0xCC : Red (Byte contenant 2 points de sprite) */
  byte_picture->palette_red[0xCC] = 0xFF;
  byte_picture->palette_green[0xCC] = 0x00;
  byte_picture->palette_blue[0xCC] = 0x00;
  /* 0xAA : Yellow (Byte contenant 2 points de sprite mais en 8 bit) */
  byte_picture->palette_red[0xAA] = 0xFF;
  byte_picture->palette_green[0xAA] = 0xFF;
  byte_picture->palette_blue[0xAA] = 0x00;
  /* 0xDD : Violet= fusion Rouge+Bleu ou Bleu+Bleu (2 Bytes consécutifs contenant 3 points de sprite et 1 point de décor OU Bleu+Bleu => LDA / AND / ORA / STA sur 16 bits) */
  byte_picture->palette_red[0xDD] = 0xFF;
  byte_picture->palette_green[0xDD] = 0x00;
  byte_picture->palette_blue[0xDD] = 0xFF;
  /* 0x99 : Orange (4 points rouges seuls deviennent 4 Orange, car ce n'est pas assez intéressant pour la Pile) */
  byte_picture->palette_red[0x99] = 0xFF;
  byte_picture->palette_green[0x99] = 0x7F;
  byte_picture->palette_blue[0x99] = 0x00;
  /* 0xEE : VertFluo= Erreur pour les rouges CC */
  byte_picture->palette_red[0xEE] = 0x00;
  byte_picture->palette_green[0xEE] = 0xFF;
  byte_picture->palette_blue[0xEE] = 0x00;

  /*** On va remapper les points (FF:Background, BB:Blue, CC:Red) ***/
  for(y=0; y<byte_picture->height; y++)
    for(x=0; x<byte_picture->width; x++)
      {
        if(current_picture->data[2*x+y*current_picture->width] == 0xFF && current_picture->data[2*x+1+y*current_picture->width] == 0xFF)
          {
            byte_picture->data[x+y*byte_picture->width] = 0xFF;
            nb_ff++;
          }
        else if((current_picture->data[2*x+y*current_picture->width] == 0xFF && current_picture->data[2*x+1+y*current_picture->width] != 0xFF) ||
                (current_picture->data[2*x+y*current_picture->width] != 0xFF && current_picture->data[2*x+1+y*current_picture->width] == 0xFF))
          {
            byte_picture->data[x+y*byte_picture->width] = 0xBB;
            nb_bb++;
          }
        else
          {
            byte_picture->data[x+y*byte_picture->width] = 0xCC;
            nb_cc++;
          }
      }

  /** Création de l'image BYTE Red / Blue **/
  if(verbose)
    {
      strcpy(file_path,sprite_path);
      strcpy(&file_path[strlen(file_path)-4],"_B_rb.gif");
      result = GIFWriteFileFrom256Color(file_path,byte_picture);
      if(result)
        printf("  - Error : Can't create Sprite BYTE rb file '%s'.\n",file_path);
      total = nb_ff+nb_bb+nb_cc;
      printf("  - Sprite BYTE rb    : %dx%d Total=%d, Red=%d (%d%%), Blue=%d (%d%%), Background=%d (%d%%).\n",byte_picture->width,byte_picture->height,total,nb_cc,(nb_cc*100)/total,nb_bb,(nb_bb*100)/total,nb_ff,(nb_ff*100)/total);
    }

  /*** On va établir les statistiques sur les fréquences d'utilisation des zones rouges 16 bit (2 BYTES, 4 points) ***/
  my_Memory(MEMORY_FREE_PATTERN,NULL,NULL);
  for(y=0; y<byte_picture->height; y++)
    for(x=0; x<byte_picture->width; x++)
      {
        /* Début d'un bloc rouge */
        if(byte_picture->data[x+y*byte_picture->width] == 0xCC)
          {
            /* Longueur du bloc rouge */
            for(i=x,length=0; i<byte_picture->width; i++)
              if(byte_picture->data[i+y*byte_picture->width] == 0xCC)
                length++;
              else
                break;

            /** Il faut au moins 2 BYTES **/
            if(length >= 2)
              {
                /* Si la longueur est paire : 1 passage */
                if(length%2 == 0)
                  {
                    for(j=0; j<length; j+=2)
                      {
                        pattern = ((WORD) current_picture->data[2*(x+j)+0+y*current_picture->width] << 12) | 
                                  ((WORD) current_picture->data[2*(x+j)+1+y*current_picture->width] << 8) | 
                                  ((WORD) current_picture->data[2*(x+j)+2+y*current_picture->width] << 4)  | 
                                  ((WORD) current_picture->data[2*(x+j)+3+y*current_picture->width]);
                        my_Memory(MEMORY_ADD_PATTERN,&pattern,NULL);
                        my_Memory(MEMORY_ADD_PATTERN,&pattern,NULL);
                      }
                  }
                else
                  {
                    /** Deux passages, on sacrifie 1 BYTE à chaque fois (le premier et le dernier) **/
                    for(j=1; j<length-1; j+=2)
                      {
                        pattern = ((WORD) current_picture->data[2*(x+j)+0+y*current_picture->width] << 12) | 
                                  ((WORD) current_picture->data[2*(x+j)+1+y*current_picture->width] << 8) | 
                                  ((WORD) current_picture->data[2*(x+j)+2+y*current_picture->width] << 4)  | 
                                  ((WORD) current_picture->data[2*(x+j)+3+y*current_picture->width]);
                        my_Memory(MEMORY_ADD_PATTERN,&pattern,NULL);
                      }
                    for(j=0; j<length-1; j+=2)
                      {
                        pattern = ((WORD) current_picture->data[2*(x+j)+0+y*current_picture->width] << 12) | 
                                  ((WORD) current_picture->data[2*(x+j)+1+y*current_picture->width] << 8) | 
                                  ((WORD) current_picture->data[2*(x+j)+2+y*current_picture->width] << 4)  | 
                                  ((WORD) current_picture->data[2*(x+j)+3+y*current_picture->width]);
                        my_Memory(MEMORY_ADD_PATTERN,&pattern,NULL);
                      }
                  }
              }

            /* Bloc suivant */
            x+=length-1;  /* car x++ */
          }
      }
  my_Memory(MEMORY_SORT_PATTERN,NULL,NULL);

  /* Affiche les statistiques Pattern */
  my_Memory(MEMORY_GET_PATTERN_NB,&nb_pattern,NULL);
  if(verbose)
    printf("  - Nb Pattern   : %d\n",nb_pattern);
  for(i=1; i<=nb_pattern; i++)
    {
      my_Memory(MEMORY_GET_PATTERN,&i,&current_pattern);
      if(i < 5)
        if(verbose)
          printf("    - Pattern[%d] : %04X (%d)\n",i-1,current_pattern->pattern_data,current_pattern->nb_found/2);
    }

  /*** On va remapper les points pour ajouter Yellow (Rouge BYTE tout seul no combinablme avec un autre Rouge) et Violet (Fusion d'un Rouge tout seul et d'un bleu tout seul) ***/
  for(y=0; y<byte_picture->height; y++)
    {
      /** On analyse chaque ligne séparément les unes des autres. On parcours de Droite à gauche **/
      for(x=byte_picture->width-1; x>=0; x--)
        {
          /** On travaille sur un bloc continue de pixels, de droite à gauche [i|.|.|.|.|x] **/
          if(byte_picture->data[x+y*byte_picture->width] != 0xFF)
            {
              /* Cherche la fin du bloc */
              for(i=x; i>=0; i--)
                if(byte_picture->data[i+y*byte_picture->width] == 0xFF)
                  break;
              length = x-i;
              i++;
              next_x = i;

              /**************************************************/
              /*** On va simplifier le bloc en le re-taillant ***/
              nb_modif = 1;
              while(nb_modif && length > 1)
                {
                  nb_modif = 0;

                  /** Le bloc a deux Bleu à gauche **/
                  if(byte_picture->data[i+y*byte_picture->width] == 0xBB && byte_picture->data[i+1+y*byte_picture->width] == 0xBB)
                    {
                      /* Transforme les 2 bleus BB en 2 violet DD */
                      byte_picture->data[i+y*byte_picture->width] = 0xDD;
                      byte_picture->data[i+1+y*byte_picture->width] = 0xDD;

                      /* Retaille le bloc */
                      i += 2;
                      length -= 2;
                      nb_modif = 1;
                      continue;
                    }

                  /** Le bloc a deux Bleu à droite **/
                  if(byte_picture->data[x+y*byte_picture->width] == 0xBB && byte_picture->data[x-1+y*byte_picture->width] == 0xBB)
                    {
                      /* Transforme les 2 bleus BB en 2 violet DD */
                      byte_picture->data[x+y*byte_picture->width] = 0xDD;
                      byte_picture->data[x-1+y*byte_picture->width] = 0xDD;

                      /* Retaille le bloc */
                      x -= 2;
                      length -= 2;
                      nb_modif = 1;
                      continue;
                    }
                }
              if(length == 0)
                {
                  x = next_x;
                  continue;
                }

              /**********************************/
              /***** Bloc de faible taille ******/
              /* On ne fait rien avec les blocs bleu de taille 1 (les rouges eux passent en Yellow) */
              if(length == 1 && byte_picture->data[x+y*byte_picture->width] == 0xBB)
                {
                  x = next_x;
                  continue;
                }

              /* Bloc de Taille 2 Blue/Red ou Red/Blue => Violet DD */
              if(length == 2 && byte_picture->data[i+y*byte_picture->width] != byte_picture->data[i+1+y*byte_picture->width])  
                {
                  byte_picture->data[i+y*byte_picture->width] =  0xDD;
                  byte_picture->data[i+1+y*byte_picture->width] =  0xDD;
                  x = next_x;
                  continue;
                }

              /*********************************************/
              /*** On recherche des compositions connues ***/

              /* Regarde la composition du bloc : que du rouge CC ? */
              for(is_full_red=1,nb_red=0,j=0; j<length; j++)
                {
                  if(byte_picture->data[i+j+y*byte_picture->width] != 0xCC)
                    {
                      is_full_red = 0;
                      break;
                    }
                  else
                    nb_red++;
                }
              if(nb_red == 0)
                is_full_red = 0;

              /* Regarde la composition du bloc : que du rouge CC avec un seul bleu BB à Gauche ? */
              is_full_red_left = 0;
              if(byte_picture->data[i+y*byte_picture->width] == 0xBB)
                {
                  for(is_full_red_left=1,nb_red=0,j=1; j<length; j++)
                    {
                      if(byte_picture->data[i+j+y*byte_picture->width] != 0xCC)
                        {
                          is_full_red_left = 0;
                          break;
                        }
                      else
                        nb_red++;
                    }
                  if(nb_red == 0)
                    is_full_red_left = 0;
                }
              /* Regarde la composition du bloc : que du rouge CC avec un seul bleu BB à Droite ? */
              is_full_red_right = 0;
              if(byte_picture->data[i+length-1+y*byte_picture->width] == 0xBB)
                {
                  for(is_full_red_right=1,nb_red=0,j=0; j<length-1; j++)
                    {
                      if(byte_picture->data[i+j+y*byte_picture->width] != 0xCC)
                        {
                          is_full_red_right = 0;
                          break;
                        }
                      else
                        nb_red++;
                    }
                  if(nb_red == 0)
                    is_full_red_right = 0;
                }
              /* Regarde la composition du bloc : que du rouge CC avec un bleu BB à Gauche et un bleu BB à Droite ? */
              is_full_red_around = 0;
              if(byte_picture->data[i+y*byte_picture->width] == 0xBB && byte_picture->data[i+length-1+y*byte_picture->width] == 0xBB)
                {
                  for(is_full_red_around=1,nb_red=0,j=1; j<length-1; j++)
                    {
                      if(byte_picture->data[i+j+y*byte_picture->width] != 0xCC)
                        {
                          is_full_red_around = 0;
                          break;
                        }
                      else
                        nb_red++;
                    }
                  if(nb_red == 0)
                    is_full_red_around = 0;
                }

              /* Regarde la composition du bloc : que du bleu BB ? */
              for(is_full_blue=1,nb_blue=0,j=0; j<length; j++)
                {
                  if(byte_picture->data[i+j+y*byte_picture->width] != 0xBB)
                    {
                      is_full_blue = 0;
                      break;
                    }
                  else
                    nb_blue++;
                }
              if(nb_blue == 0)
                is_full_blue = 0;

              /** Cas 1 : Que du rouge et une longueur paire **/
              if(is_full_red == 1 && length%2 == 0)
                {
                  /* Rien à faire le bloc FullRed est validé */
                }
              /** Cas 2 : Que du Rouge mais une longueur = 1 => il faut mettre du jaune à la place du rouge **/
              else if(is_full_red == 1 && length == 1)
                {
                  byte_picture->data[x+y*byte_picture->width] = 0xAA;
                }
              /** Cas 3 : Que du Rouge mais une longueur impaire > 1 => il faut mettre du jaune soit au début, soit à la fin **/
              else if(is_full_red == 1 && length%2 != 0)
                {
                  /** On calcule les 2 possibilités en tenant compte des stats des pattern **/
                  /* Passage 1 : On ne prend pas le premier */
                  for(pattern_coef_1=0,j=1; j<length-1; j+=2)
                    {
                      pattern = ((WORD) current_picture->data[2*(i+j)+0+y*current_picture->width] << 12) | 
                                ((WORD) current_picture->data[2*(i+j)+1+y*current_picture->width] << 8)  | 
                                ((WORD) current_picture->data[2*(i+j)+2+y*current_picture->width] << 4)  | 
                                ((WORD) current_picture->data[2*(i+j)+3+y*current_picture->width]);
                      my_Memory(MEMORY_GET_PATTERN_SCORE,&pattern,&score);
                      pattern_coef_1 += score;
                    }
                  /* Passage 2 : On ne prend pas le dernier */
                  for(pattern_coef_2=0,j=0; j<length-1; j+=2)
                    {
                      pattern = ((WORD) current_picture->data[2*(i+j)+0+y*current_picture->width] << 12) | 
                                ((WORD) current_picture->data[2*(i+j)+1+y*current_picture->width] << 8)  | 
                                ((WORD) current_picture->data[2*(i+j)+2+y*current_picture->width] << 4)  | 
                                ((WORD) current_picture->data[2*(i+j)+3+y*current_picture->width]);
                      my_Memory(MEMORY_GET_PATTERN_SCORE,&pattern,&score);
                      pattern_coef_2 += score;
                    }
                  /** On met en jaune AA celui qui permet d'utiliser les pattern les plus utilisées **/
                  if(pattern_coef_1 > pattern_coef_2)
                    byte_picture->data[i+y*byte_picture->width] = 0xAA;   /* AA à Gauche */
                  else
                    byte_picture->data[x+y*byte_picture->width] = 0xAA;   /* AA à Droite */
                }
              /** Cas 4 : Que du Rouge + un Bleu à gauche **/
              else if(is_full_red_left == 1)
                {
                  /* Longueur Impaire => il faut fusionner à gauche (le bleu BB + rouge CC passe en violet DD) */
                  if(nb_red%2 == 1)
                    {
                      byte_picture->data[i+y*byte_picture->width] = 0xDD;     /* DD à Gauche */
                      byte_picture->data[i+1+y*byte_picture->width] = 0xDD;   /* DD à Gauche */
                    }
                  else
                    ;    /* Rien à faire */
                }
              /** Cas 5 : Que du Rouge avec + un Bleu à droite **/
              else if(is_full_red_right == 1)
                {
                  /* Longueur Impaire => il faut fusionner à droite (le rouge CC +le bleu BB passe en violet DD) */
                  if(nb_red%2 == 1)
                    {
                      byte_picture->data[i+length-1+y*byte_picture->width] = 0xDD;   /* DD à Droite */
                      byte_picture->data[i+length-2+y*byte_picture->width] = 0xDD;   /* DD à Droite */
                    }
                  else
                    ;     /* Rien à faire */
                }
              /** Cas 6 : Bleu à gauche + du Rouge + un Bleu à droite => il faut peut être fusionner (le rouge CC +le bleu BB passe en violet DD) **/
              else if(is_full_red_around == 1)
                {
                  /* Cas particulier 1 : Blue-Red-Blue */
                  if(nb_red == 1)
                    {
                      byte_picture->data[i+y*byte_picture->width] = 0xDD;     /* BB à gauche devient DD */
                      byte_picture->data[i+1+y*byte_picture->width] = 0xDD;   /* CC au milieu devient DD */
                    }
                  /* Cas particulier 2 : Blue-Red-Red-Blue ou Blue-Nb Pair de Red-Blue */
                  else if(nb_red%2 == 0)
                    {
                      byte_picture->data[i+y*byte_picture->width] = 0xDD;     /* BB à gauche devient DD */
                      byte_picture->data[i+1+y*byte_picture->width] = 0xDD;   /* CC à gauche devient DD */
                      byte_picture->data[x-1+y*byte_picture->width] = 0xDD;   /* CC à droite devient DD */
                      byte_picture->data[x+y*byte_picture->width] = 0xDD;     /* BB à droite devient DD */
                    }
                  /* Nombre impair de Red => On ne sacrifie qu'un seul côté */
                  else
                    {
                      /** On calcule les 2 possibilités en tenant compte des stats des pattern **/
                      /* Passage 1 : On ne prend pas le premier */
                      for(pattern_coef_1=0,j=2; j<length-1; j+=2)
                        {
                          pattern = ((WORD) current_picture->data[2*(i+j)+0+y*current_picture->width] << 12) | 
                                    ((WORD) current_picture->data[2*(i+j)+1+y*current_picture->width] << 8)  | 
                                    ((WORD) current_picture->data[2*(i+j)+2+y*current_picture->width] << 4)  | 
                                    ((WORD) current_picture->data[2*(i+j)+3+y*current_picture->width]);
                          my_Memory(MEMORY_GET_PATTERN_SCORE,&pattern,&score);
                          pattern_coef_1 += score;
                        }
                      /* Passage 2 : On ne prend pas le dernier */
                      for(pattern_coef_2=0,j=1; j<length-2; j+=2)
                        {
                          pattern = ((WORD) current_picture->data[2*(i+j)+0+y*current_picture->width] << 12) | 
                                    ((WORD) current_picture->data[2*(i+j)+1+y*current_picture->width] << 8)  | 
                                    ((WORD) current_picture->data[2*(i+j)+2+y*current_picture->width] << 4)  | 
                                    ((WORD) current_picture->data[2*(i+j)+3+y*current_picture->width]);
                          my_Memory(MEMORY_GET_PATTERN_SCORE,&pattern,&score);
                          pattern_coef_2 += score;
                        }
                      /** On met en violet DD celui qui permet d'utiliser les pattern les plus utilisées **/
                      if(pattern_coef_1 > pattern_coef_2)
                        {
                          byte_picture->data[i+y*byte_picture->width] = 0xDD;     /* BB à Gauche devient DD */
                          byte_picture->data[i+1+y*byte_picture->width] = 0xDD;   /* CC à Gauche devient DD */
                        }
                      else
                        {
                          byte_picture->data[x+y*byte_picture->width] = 0xDD;    /* BB à Droite devient DD */
                          byte_picture->data[x-1+y*byte_picture->width] = 0xDD;  /* CC à Droite devient DD */
                        }
                    }
                }
              /** Cas 7 : Que du bleu **/
              else if(is_full_blue == 1 && length > 1)
                {
                  /* On va regrouper les bleus BB par 2 pour faire du violet DD : on les traitera en 16 bit */
                  for(j=(length%2==0)?0:1; j<length; j++)
                    byte_picture->data[i+j+y*byte_picture->width] = 0xDD;   /* Si le nb de BB est impair, on ne groupe pas le + à gauche (convention) */
                }
              /** Cas 8 : Mixure de Bleu et de Rouge (du bleu au milieu de rouge) dont la longueur >= 3 **/
              else
                {
                  /* On parcours de droite à gauche */
                  for(j=x; j>=i; j--)
                    {
                      /** Avant-Avant dernier (il reste 3 BYTE) = 8 cas possibles **/
                      if(j == i+2)
                        {
                          /* 3 Red (on passe le + à gauche en Yellow AA ) */
                          if(byte_picture->data[j-2+y*byte_picture->width] == 0xCC && byte_picture->data[j-1+y*byte_picture->width] == 0xCC && byte_picture->data[j+y*byte_picture->width] == 0xCC)
                            {
                              byte_picture->data[j-2+y*byte_picture->width] = 0xAA;
                              j-=2;   /* On avance de 3 */
                            }
                          /* 3 Blue (on passe les 2 à droite en violet DD) */
                          else if(byte_picture->data[j-2+y*byte_picture->width] == 0xBB && byte_picture->data[j-1+y*byte_picture->width] == 0xBB && byte_picture->data[j+y*byte_picture->width] == 0xBB)
                            {
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j+y*byte_picture->width] = 0xDD;
                              j-=2;   /* On avance de 3 */
                            }
                          /* RBR ou RBB (on passe le + à gauche en Yellow AA et les 2 à droite en violet DD) */
                          else if((byte_picture->data[j-2+y*byte_picture->width] == 0xCC && byte_picture->data[j-1+y*byte_picture->width] == 0xBB && byte_picture->data[j+y*byte_picture->width] == 0xCC) ||
                                  (byte_picture->data[j-2+y*byte_picture->width] == 0xCC && byte_picture->data[j-1+y*byte_picture->width] == 0xBB && byte_picture->data[j+y*byte_picture->width] == 0xCC))
                            {
                              byte_picture->data[j-2+y*byte_picture->width] = 0xAA;
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j+y*byte_picture->width] = 0xDD;
                              j-=2;   /* On avance de 3 */
                            }
                          /* BRB (on passe les 2 à droite en violet DD) */
                          else if(byte_picture->data[j-2+y*byte_picture->width] == 0xBB && byte_picture->data[j-1+y*byte_picture->width] == 0xCC && byte_picture->data[j+y*byte_picture->width] == 0xBB)
                            {
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j+y*byte_picture->width] = 0xDD;
                              j-=2;   /* On avance de 3 */
                            }
                          /* BBR (on passe les 2 à gauche en violet DD et celui à droite en Yellow AA) */
                          else if(byte_picture->data[j-2+y*byte_picture->width] == 0xBB && byte_picture->data[j-1+y*byte_picture->width] == 0xBB && byte_picture->data[j+y*byte_picture->width] == 0xCC)
                            {
                              byte_picture->data[j-2+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j+y*byte_picture->width] = 0xAA;
                              j-=2;   /* On avance de 3 */
                            }
                          /* RRB et BRR = On ne fait rien */
                          else
                            j-=2;   /* On avance de 3 */
                        }
                      /** Avant dernier (il reste 2 BYTE) **/
                      else if(j == i+1)
                        {
                          /* 2 Blue => Violet DD */
                          if(byte_picture->data[j+y*byte_picture->width] == 0xBB && byte_picture->data[j-1+y*byte_picture->width] == 0xBB)
                            {
                              byte_picture->data[j+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              j--;  /* On avance de 2 */
                            }
                          /* 2 Red => Rien à faire */
                          else if(byte_picture->data[j+y*byte_picture->width] == 0xCC && byte_picture->data[j-1+y*byte_picture->width] == 0xCC)
                            {
                              j--;  /* On avance de 2 */
                            }
                          /* 1 Red / 1 Blue (ou inverse) => Violet DD */
                          else if(byte_picture->data[j+y*byte_picture->width] != byte_picture->data[j-1+y*byte_picture->width])
                            {
                              byte_picture->data[j+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              j--;  /* On avance de 2 */
                            }
                        }
                      /** Dernier (il reste 1 BYTE) **/
                      else if(j == i)
                        {
                          /* Blue (on ne fait rien) */
                          if(byte_picture->data[j+y*byte_picture->width] == 0xBB)
                            ;
                          /* Red (On passe en Jaune AA) */
                          else if(byte_picture->data[j+y*byte_picture->width] == 0xCC)
                            byte_picture->data[j+y*byte_picture->width] = 0xAA;
                        }
                      else    /* Il reste au moins 4 BYTE */
                        {
                          /* BB on fusionne en VV */
                          if(byte_picture->data[j-1+y*byte_picture->width] == 0xBB && byte_picture->data[j+y*byte_picture->width] == 0xBB)
                            {
                              byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                              byte_picture->data[j+y*byte_picture->width] = 0xDD;
                              j--;   /* On avance de 2 */
                            }
                          /* RR : On ne fait rien */
                          else if(byte_picture->data[j-1+y*byte_picture->width] == 0xCC && byte_picture->data[j+y*byte_picture->width] == 0xCC)
                            j--;   /* On avance de 2 */
                          /* RB : Ca va dépendre de celui encore à gauche */
                          else if(byte_picture->data[j-1+y*byte_picture->width] == 0xCC && byte_picture->data[j+y*byte_picture->width] == 0xBB)
                            {
                              /* R[RB] : On isole le Bleu tout seul pour groupper les 2 R */
                              if(byte_picture->data[j-2+y*byte_picture->width] == 0xCC)
                                {
                                  ;   /* On avance de 1 */
                                }
                              /* B[RB] : On fusionne le RB en VV */
                              else if(byte_picture->data[j-2+y*byte_picture->width] == 0xBB)
                                {
                                  /* Les 2 passent en violet DD */
                                  byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                                  byte_picture->data[j+y*byte_picture->width] = 0xDD;
                                  j--;   /* On avance de 2 */
                                }
                            }
                          /* BR : Ca va dépendre de celui encore à gauche */
                          else if(byte_picture->data[j-1+y*byte_picture->width] == 0xBB && byte_picture->data[j+y*byte_picture->width] == 0xCC)
                            {
                              /* R[BR] : On passe le BR en VV */
                              if(byte_picture->data[j-2+y*byte_picture->width] == 0xCC)
                                {
                                  /* Les 2 passent en violet DD */
                                  byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                                  byte_picture->data[j+y*byte_picture->width] = 0xDD;
                                  j--;   /* On avance de 2 */
                                }
                              /* B[BR] : On fusionne le BB en VV et on passe le R en A */
                              else if(byte_picture->data[j-2+y*byte_picture->width] == 0xBB)
                                {
                                  /* Le R passe en AA */
                                  byte_picture->data[j+y*byte_picture->width] = 0xAA;

                                  /* Les 2 B passent en violet DD */
                                  byte_picture->data[j-1+y*byte_picture->width] = 0xDD;
                                  byte_picture->data[j-2+y*byte_picture->width] = 0xDD;
                                  j-=2;   /* On avance de 3 */
                                }
                            }
                        }
                    }
                }

              /* Bloc suivant */
              x = next_x;
            }
        }
    }

  /*** On va refaire les statistiques sur les fréquences d'utilisation des zones rouges CC 16 bit (2 BYTES, 4 points) ***/
  my_Memory(MEMORY_FREE_PATTERN,NULL,NULL);
  for(y=0; y<byte_picture->height; y++)
    for(x=0; x<byte_picture->width-1; x++)
      {
        /* Début d'un WORD rouge-rouge */
        if(byte_picture->data[x+y*byte_picture->width] == 0xCC && byte_picture->data[x+1+y*byte_picture->width] == 0xCC)
          {
            pattern = ((WORD) current_picture->data[2*x+0+y*current_picture->width] << 12) | 
                      ((WORD) current_picture->data[2*x+1+y*current_picture->width] << 8)  | 
                      ((WORD) current_picture->data[2*x+2+y*current_picture->width] << 4)  | 
                      ((WORD) current_picture->data[2*x+3+y*current_picture->width]);
            my_Memory(MEMORY_ADD_PATTERN,&pattern,NULL);
          }
      }
  my_Memory(MEMORY_SORT_PATTERN,NULL,NULL);

  /*** On va recherche les CC (Rouge) qui vont en paire et on va les convertir en 99 (Orange), pas assez long pour la pile ***/
  for(y=0; y<byte_picture->height; y++)
    for(x=0; x<byte_picture->width; x++)
      if(byte_picture->data[x+y*byte_picture->width] == 0xCC)
        {
          /* Longueur de la partie rouge */
          for(length=0,i=x; i<byte_picture->width; i++)
            if(byte_picture->data[i+y*byte_picture->width] == 0xCC)
              length++;
            else
              break;

          /* Si la longueur est 2 => Conversion en Orange 99 */
          if(length == 2)
            {
              byte_picture->data[x+y*byte_picture->width+0] = 0x99;
              byte_picture->data[x+y*byte_picture->width+1] = 0x99;
              x += (2-1);        /* -1 car x++ */
            }
          else
            x += (length-1);     /* -1 car x++ */
        }

  /** Statistiques sur l'image ROBYP **/
  nb_cc = 0;    /* Red */
  nb_99 = 0;    /* Orange */
  nb_bb = 0;    /* Blue */
  nb_aa = 0;    /* Yellow */
  nb_dd = 0;    /* Purple */
  nb_ff = 0;    /* Background */
  total = byte_picture->width*byte_picture->height;
  for(i=0; i<total; i++)
    if(byte_picture->data[i] == 0xFF)
      nb_ff++;
    else if(byte_picture->data[i] == 0x99)
      nb_99++;
    else if(byte_picture->data[i] == 0xCC)
      nb_cc++;
    else if(byte_picture->data[i] == 0xBB)
      nb_bb++;
    else if(byte_picture->data[i] == 0xAA)
      nb_aa++;
    else if(byte_picture->data[i] == 0xDD)
      nb_dd++;
  if(verbose)
    printf("  - Sprite BYTE ropyb : %dx%d Total=%d, Red=%d (%d%%), Orange=%d (%d%%), Purple=%d (%d%%), Yellow=%d (%d%%), Blue=%d (%d%%), Background=%d (%d%%).\n",
           byte_picture->width,byte_picture->height,total,nb_cc,(nb_cc*100)/total,nb_99,(nb_99*100)/total,nb_dd,(nb_dd*100)/total,nb_aa,(nb_aa*100)/total,nb_bb,(nb_bb*100)/total,nb_ff,(nb_ff*100)/total);

  /* Affiche les statistiques Pattern */
  my_Memory(MEMORY_GET_PATTERN_NB,&nb_pattern,NULL);
  if(verbose)
    printf("  - Nb Pattern   : %d\n",nb_pattern);
  for(i=1; i<=nb_pattern; i++)
    {
      my_Memory(MEMORY_GET_PATTERN,&i,&current_pattern);
      if(i < 5)
        if(verbose)
          printf("    - Pattern[%d] : %04X (%d)\n",i-1,current_pattern->pattern_data,current_pattern->nb_found/2);
    }

  /** Création de l'image BYTE Red / Orange / Blue / Yellow / Purple **/
  if(verbose)
    {
      strcpy(file_path,sprite_path);
      strcpy(&file_path[strlen(file_path)-4],"_B_ropyb.gif");
      result = GIFWriteFileFrom256Color(file_path,byte_picture);
      if(result)
        printf("  - Error : Can't create Sprite BYTE ropyb file '%s'.\n",file_path);
    }

  /* Renvoie la structure BYTE */
  return(byte_picture);
}


/**********************************************************/
/*  Compute8BitColors() : Compte les couleurs de l'image. */
/**********************************************************/
int Compute8BitColors(int nb_byte, int height, int width, unsigned char *windows_bitmap_data, int *palette_ind)
{
  unsigned char red, green, blue;
  int i, j, first, last, x, color_ind, window_height, window_width, nb_real_color, offset;
  
  /* Init */
  memset(palette_ind,0,257*sizeof(int));
  window_height = height;
  window_width = width;
  nb_real_color = 0;

  /** Passe tous les points en revue **/
  for(j=0; j<window_height && nb_real_color != 257; j++)
    for(i=0; i<window_width && nb_real_color != 257; i++)
      {
        /* Couleur du point */
        offset = (i+j*window_width)*nb_byte;
        red = windows_bitmap_data[offset];
        green = windows_bitmap_data[offset+1];
        blue = windows_bitmap_data[offset+2];
        color_ind = 65536*red + 256*green + blue;

        /** On insert/recherche la couleur (dichotomie) **/
        if(i == 0 && j == 0)
          {
            palette_ind[0] = color_ind;
            nb_real_color = 1;
          }
        else
          {
            for(first=0,last=nb_real_color; last>=first;)
              {
                x = (first+last)/2;
                if(color_ind < palette_ind[x])
                  last = x - 1;
                else
                  first = x + 1;

                if(color_ind == palette_ind[x])
                  break;
               }

            /* A t'on trouvé la couleur ou doit on l'ajouter */
            if(color_ind != palette_ind[x])
              {
                /* Décalage du tableau */
                if(x < nb_real_color)
                  if(palette_ind[x] < color_ind)
                    x++;
                memmove(&palette_ind[x+1],&palette_ind[x],(nb_real_color-x)*sizeof(int));
                palette_ind[x] = color_ind;
                nb_real_color++;
              }
          }
      }

  /* Renvoi le nombre de couleurs */
  return(nb_real_color);
}


/****************************************************************************/
/*  ConvertTrueColorTo256() : Conversion du true color en 256 couleurs GIF. */
/****************************************************************************/
struct picture_256 *ConvertTrueColorTo256(struct picture_true *current_picture_true)
{
  int i,j;
  int offset, nb_real_color;
  int first, last, x, color_ind;
  int palette_ind[256];
  unsigned char red, green, blue;
  struct picture_256 *current_picture_256;

  /* Allocation mémoire */
  current_picture_256 = (struct picture_256 *) calloc(1,sizeof(struct picture_256));
  if(current_picture_256 == NULL)
    return(NULL);
  current_picture_256->width = current_picture_true->width;
  current_picture_256->height = current_picture_true->height;

  /* Init Palette */
  memset(&current_picture_256->palette_red[0],0,256*sizeof(int));
  memset(&current_picture_256->palette_green[0],0,256*sizeof(int));
  memset(&current_picture_256->palette_blue[0],0,256*sizeof(int));

  /** Création de la palette **/
  nb_real_color = 0;
  for(j=0; j<current_picture_true->height; j++)
    for(i=0; i<current_picture_true->width; i++)
      {
        /* Couleur du point */
        offset = (i+j*current_picture_true->width)*3;
        red = current_picture_true->data[offset];
        green = current_picture_true->data[offset+1];
        blue = current_picture_true->data[offset+2];
        color_ind = 65536*red + 256*green + blue;

        /** On insert/recherche la couleur (dichotomie) **/
        if(i == 0 && j == 0)
          {
            palette_ind[0] = color_ind;
            nb_real_color = 1;
          }
        else
          {
            for(first=0,last=nb_real_color; last>=first;)
              {
                x = (first+last)/2;
                if(color_ind < palette_ind[x])
                  last = x - 1;
                else
                  first = x + 1;

                if(color_ind == palette_ind[x])
                  break;
              }

            /* A t'on trouvé la couleur ou doit on l'ajouter */
            if(color_ind != palette_ind[x])
              {
                /* Gestion des images > 256 couleurs */
                if(nb_real_color == 256)
                  return(NULL);

                /* Décalage du tableau */
                if(x < nb_real_color)
                  if(palette_ind[x] < color_ind)
                    x++;
                memmove(&palette_ind[x+1],&palette_ind[x],(nb_real_color-x)*sizeof(int));
                palette_ind[x] = color_ind;
                nb_real_color++;
              }
          }
      }
  /* Palette séparée RGB */
  for(i=0; i<nb_real_color; i++)
    {
      current_picture_256->palette_red[i] = (palette_ind[i]&0x00FF0000)>>16;
      current_picture_256->palette_green[i] = (palette_ind[i]&0x0000FF00)>>8;
      current_picture_256->palette_blue[i] = (palette_ind[i]&0x000000FF);
    }
  current_picture_256->nb_color = nb_real_color;

  /* Allocation mémoire de l'image en 256 couleurs */
  current_picture_256->data = (unsigned char *) calloc(1,current_picture_true->height*current_picture_true->width);
  if(current_picture_256->data == NULL)
    return(NULL);

  /** Points **/
  for(j=0; j<current_picture_true->height; j++)
    for(i=0; i<current_picture_true->width; i++)
      {
        offset = (i+j*current_picture_true->width)*3;
        red = current_picture_true->data[offset];
        green = current_picture_true->data[offset+1];
        blue = current_picture_true->data[offset+2];
        color_ind = 65536*red + 256*green + blue;

        /** Recherche dichotomique de la valeur **/
        for(first=0,last=nb_real_color; last>=first;)
          {
            x = (first+last)/2;
            if(color_ind < palette_ind[x])
              last = x - 1;
            else
              first = x + 1;

            if(color_ind == palette_ind[x])
              break;
          }

        /* Création du point */
        current_picture_256->data[i+j*current_picture_true->width] = (unsigned char) x;
      }
 
  /** Renvoi l'image 256 **/  
  return(current_picture_256);
}


/****************************************************************/
/*  PlotTrueColor() :  Place un point sur une image True Color. */
/****************************************************************/
void PlotTrueColor(int x, int y, unsigned char red, unsigned char green, unsigned char blue, struct picture_true *current_picture)
{
  current_picture->data[(y*current_picture->width+x)*3+0] = red;
  current_picture->data[(y*current_picture->width+x)*3+1] = green;
  current_picture->data[(y*current_picture->width+x)*3+2] = blue;
}

/*
 000   0  0000   0000   0   0  00000   000   00000   000    000
0   0  0      0      0  0   0  0      0          0  0   0  0   0
0   0  0   000     00    0000  0000   0000      0    000    0000
0   0  0  0          0      0      0  0   0    0    0   0      0
 000   0  00000  0000       0  0000    000     0     000    000
*/

/***************************************************************/
/*  PlotNumber() :  Place un chiffre sur une image True Color. */
/***************************************************************/
int PlotNumber(int number, int x, int y, unsigned char red, unsigned char green, unsigned char blue, struct picture_true *current_picture)
{
  /* Vérification */
  if(number > 9)
    return(0);

  /* 0 */
  if(number == 0)
    {
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+2,red,green,blue,current_picture);
      PlotTrueColor(x,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 1)
    {
      PlotTrueColor(x,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x,y+2,red,green,blue,current_picture);
      PlotTrueColor(x,y+3,red,green,blue,current_picture);
      PlotTrueColor(x,y+4,red,green,blue,current_picture);
      return(1);
    }
  else if(number == 2)
    {
      PlotTrueColor(x,y,red,green,blue,current_picture);
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x,y+3,red,green,blue,current_picture);
      PlotTrueColor(x,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 3)
    {
      PlotTrueColor(x,y,red,green,blue,current_picture);
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 4)
    {
      PlotTrueColor(x,y,red,green,blue,current_picture);
      PlotTrueColor(x+4,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 5)
    {
      PlotTrueColor(x,y,red,green,blue,current_picture);
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x+4,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 6)
    {
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 7)
    {
      PlotTrueColor(x,y,red,green,blue,current_picture);
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x+4,y,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 8)
    {
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      return(5);
    }
  else if(number == 9)
    {
      PlotTrueColor(x+1,y,red,green,blue,current_picture);
      PlotTrueColor(x+2,y,red,green,blue,current_picture);
      PlotTrueColor(x+3,y,red,green,blue,current_picture);
      PlotTrueColor(x,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+1,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+2,red,green,blue,current_picture);
      PlotTrueColor(x+4,y+3,red,green,blue,current_picture);
      PlotTrueColor(x+1,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+2,y+4,red,green,blue,current_picture);
      PlotTrueColor(x+3,y+4,red,green,blue,current_picture);
      return(5);
    }

  /* Never here */
  return(0);
}


/******************************************************************************/
/*  mem_free_picture_256() :  Libération mémoire de la structure picture_256. */
/******************************************************************************/
void mem_free_picture_256(struct picture_256 *current_picture)
{
  if(current_picture == NULL)
    return;

  if(current_picture->data)
    free(current_picture->data);

  if(current_picture->tab_nb_color)
    free(current_picture->tab_nb_color);

  if(current_picture->tab_color_line)
    free(current_picture->tab_color_line);

  free(current_picture);
}

/********************************************************************************/
/*  mem_free_picture_true() :  Libération mémoire de la structure picture_true. */
/********************************************************************************/
void mem_free_picture_true(struct picture_true *current_picture)
{
  if(current_picture == NULL)
    return;

  if(current_picture->data)
    free(current_picture->data);

  free(current_picture);
}

/**************************************************************************/
