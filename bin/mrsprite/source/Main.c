/*****************************************************************************/
/*                                                                           */
/*  MrSprite :  Outil de génération de code pour Sprite sur Apple IIgs.       */
/*                                                                           */
/*****************************************************************************/
/*  Auteur : Olivier ZARDINI  *  Brutal Deluxe Software  *  Date : Nov 2012  */
/*****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "Dc_Shared.h"
#include "Dc_Graphic.h"
#include "Dc_Code.h"
#include "Dc_Gif.h"
#include "Dc_Memory.h"

/****************************************************/
/*  Main() :  Fonction principale de l'application. */
/****************************************************/
int main(int argc, char *argv[])
{
  int i, result, nb_file, verbose, nb_bank;
  char **tab_file;
  char file_extension[256];
  DWORD color_bg, color_frame;
  DWORD palette_16[16] = {0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF};

  /* Information */
  printf("MrSprite v1.0 (c) Brutal Deluxe 2012-2013.\n");

  /* Init */
  verbose = 0;
  my_Memory(MEMORY_INIT,NULL,NULL);

  /* Vérification des paramètres */
  if(argc < 3)
    {
      printf("  Usage : %s COMMAND   <param_1> <param_2> <param_3>...\n",argv[0]);
      printf("          %s EXTRACT   <sprite_file(s)_path> <background_color_RRGGBB> <frame_color_RRGGBB>.\n",argv[0]);
      printf("          ----\n");
      printf("          %s MIRROR    <sprite_file(s)_path> <background_color_RRGGBB>.\n",argv[0]);
      printf("          %s FLIP      <sprite_file(s)_path> <background_color_RRGGBB>.\n",argv[0]);
      printf("          %s ODD       <sprite_file(s)_path> <background_color_RRGGBB>.\n",argv[0]);
      printf("          ----\n");
      printf("          %s UNIQUE    <sprite_file(s)_path>.\n",argv[0]);
      printf("          %s RENAME    <file(s)_path>        <new_name>.\n",argv[0]);
      printf("          %s WALLPAPER <sprite_file(s)_path> <background_color_RRGGBB> <frame_color_RRGGBB>.\n",argv[0]);
      printf("          ----\n");
      printf("          %s CODE [-V] <sprite_file(s)_path> <background_color_RRGGBB> <color_0_RRGGBB> <color_1_RRGGBB>...\n",argv[0]);
      printf("          %s BANK      <sprite_code(s)_path> <bank_object_name>.\n",argv[0]);
      printf("          ----\n");
      return(1);
    }

  /**********************************************************************************/
  /**  EXTRACT : Extrait tous les sprites d'une planche et les entoure d'un cadre  **/
  /**********************************************************************************/
  if(argc == 5 && !my_stricmp(argv[1],"EXTRACT"))
    {
      /* Vérifie les paramètres */
      color_bg = DecodeRGBColor(argv[3]);
      color_frame = DecodeRGBColor(argv[4]);
      if(color_bg == 0xFFFFFFFF || color_frame == 0xFFFFFFFF)
        {
          printf("  Error : Can't convert color into a valid 0xRRGGBB format.\n");
          return(1);
        }

      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Modifie l'image pour ajouter un cadre autour du Sprite + Création de l'image Sprite **/
      for(i=0; i<nb_file; i++)
        {
          printf("  - Processing file : '%s'\n",tab_file[i]);
          result = ExtractAllSprite(tab_file[i],color_bg,color_frame);
        }

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }


  /***************************************************/
  /**  MIRROR : Retourne les Sprites Droite/Gauche  **/
  /***************************************************/
  if(argc == 4 && !my_stricmp(argv[1],"MIRROR"))
    {
      /* Décodage des 16 couleurs du sprite */
      color_bg = DecodeRGBColor(argv[3]);
      if(color_bg == 0xFFFFFFFF)
        {
          printf("  Error : Can't convert color '%s' into a valid 0xRRGGBB format.\n",argv[3]);
          return(1);
        }

      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Création ses Sprites Mirroir **/
      for(i=0; i<nb_file; i++)
        {
          printf("  - Processing file : '%s'\n",tab_file[i]);
          result = CreateMirrorPicture(tab_file[i],color_bg);
        }

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }


  /********************************************/
  /**  FLIP : Inverse les Sprites Haut/Base  **/
  /********************************************/
  if(argc == 4 && !my_stricmp(argv[1],"FLIP"))
    {
      /* Décodage des 16 couleurs du sprite */
      color_bg = DecodeRGBColor(argv[3]);
      if(color_bg == 0xFFFFFFFF)
        {
          printf("  Error : Can't convert color '%s' into a valid 0xRRGGBB format.\n",argv[3]);
          return(1);
        }

      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Création ses Sprites Inversé **/
      for(i=0; i<nb_file; i++)
        {
          printf("  - Processing file : '%s'\n",tab_file[i]);
          result = CreateFlipPicture(tab_file[i],color_bg);
        }

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }

  /*******************************************************/
  /**  ODD : Génère les positions impaires des sprites  **/
  /*******************************************************/
  if(argc == 4 && !my_stricmp(argv[1],"ODD"))
    {
      /* Décodage des 16 couleurs du sprite */
      color_bg = DecodeRGBColor(argv[3]);
      if(color_bg == 0xFFFFFFFF)
        {
          printf("  Error : Can't convert color '%s' into a valid 0xRRGGBB format.\n",argv[3]);
          return(1);
        }

      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Création ses Sprites Impaires **/
      for(i=0; i<nb_file; i++)
        {
          printf("  - Processing file : '%s'\n",tab_file[i]);
          result = CreateOddPicture(tab_file[i],color_bg);
        }

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }

  /**********************************************/
  /**  UNIQUE : Elimine les Sprites en double  **/
  /**********************************************/
  if(argc == 3 && !my_stricmp(argv[1],"UNIQUE"))
    {
      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Supprime les Sprites en double **/
      result = RemoveDuplicatedPictures(nb_file,tab_file);

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }


  /***********************************************************/
  /**  RENAME : Renomme les fichiers de facon incrémentale  **/
  /***********************************************************/
  if(argc == 4 && !my_stricmp(argv[1],"RENAME"))
    {
      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /* Tri les fichiers */
      qsort(tab_file,nb_file,sizeof(char *),compare_filepath);

      /* File extension */
      strcpy(file_extension,"gif");
      for(i=strlen(tab_file[0]); i>=0; i++)
        if(tab_file[0][i] == '.')
          {
            strcpy(file_extension,&tab_file[0][i+1]);
            break;
          }

      /** Renomme les fichiers de facon incrémentale **/
      result = RenameAllFiles(nb_file,tab_file,argv[3],file_extension);

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }


  /***************************************************************/
  /**  WALLPAPER : Crée une grande image avec tous les Sprites  **/
  /***************************************************************/
  if(argc == 5 && !my_stricmp(argv[1],"WALLPAPER"))
    {
      /* Vérifie les paramètres */
      color_bg = DecodeRGBColor(argv[3]);
      color_frame = DecodeRGBColor(argv[4]);
      if(color_bg == 0xFFFFFFFF || color_frame == 0xFFFFFFFF)
        {
          printf("  Error : Can't convert color into a valid 0xRRGGBB format.\n");
          return(1);
        }

      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Création de l'image complète **/
      result = CreateWallPaper(nb_file,tab_file,color_bg,color_frame);

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }

  //C:\svn_devzing\MrSprite\Debug>MrSprite.exe CODE D:\Project\StreetFighter\adon_spr_*.gif BAFECA 000000 443344 550000 555555 664400 777777 990000 996644 AA7700 BBBBBB CC4400 CC8866 CCAA00 DDAA88 DDCCAA
  /************************************************/
  /**  CODE : Création du code pour les Sprites  **/
  /************************************************/
  if(argc > 4 && !my_stricmp(argv[1],"CODE"))
    {
      /* Verbose */
      if(!my_stricmp(argv[2],"-V"))
        verbose = 1;

      /* Décodage des 16 couleurs du sprite */
      color_bg = DecodeRGBColor(argv[verbose+3]);
      if(color_bg == 0xFFFFFFFF)
        {
          printf("  Error : Can't convert color '%s' into a valid 0xRRGGBB format.\n",argv[verbose+3]);
          return(1);
        }
      for(i=0; i<argc-verbose-4; i++)
        {
          palette_16[i] = DecodeRGBColor(argv[verbose+4+i]);
          if(palette_16[i] == 0xFFFFFFFF)
            {
              printf("  Error : Can't convert color '%s' into a valid 0xRRGGBB format.\n",argv[verbose+3+i]);
              return(1);
            }
        }

      /* Récupère la liste des fichiers */
      tab_file = BuildFileTab(argv[verbose+2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[verbose+2]);
          return(2);
        }

      /** Création du code pour le Sprite **/
      for(i=0; i<nb_file; i++)
        {
          printf("  - Processing file : '%s'\n",tab_file[i]);
          result = CreateSpriteCode(tab_file[i],color_bg,argc-verbose-4,&palette_16[0],verbose);
        }

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }


  /*******************************************************************/
  /**  BANK : On regroupe les sources des sprites en BANK de 64 KB  **/
  /*******************************************************************/
  if(4 == argc && !my_stricmp(argv[1],"BANK"))
    {
      /* Récupère la liste des fichiers source */
      tab_file = BuildFileTab(argv[2],&nb_file);
      if(tab_file == NULL)
        {
          printf("  Error : Can't build file list from '%s'.\n",argv[2]);
          return(2);
        }

      /** Chargement / Compilation des fichiers sources **/
      for(i=0; i<nb_file; i++)
        {
          printf("  - Loading source file : '%s'\n",tab_file[i]);
          result = LoadSpriteCode(tab_file[i]);
          if(result)
            break;
        }

      /* Tri les Sprites par taille */
      my_Memory(MEMORY_SORT_CODEFILE,compare_codefile_size,NULL);

      /** Création des Banc de code **/
      result = BuildCodeBank(argv[2],argv[3],&nb_bank);

      /* Tri les Sprites par numero */
      my_Memory(MEMORY_SORT_CODEFILE,compare_codefile_num,NULL);

      /** Création du fichier Source d'index **/
      result = CreateMainCode(argv[2],argv[3],nb_bank);

      /* Libération mémoire */
      mem_free_list(nb_file,tab_file);
    }

  /* Libération */
  my_Memory(MEMORY_FREE,NULL,NULL);

  /* OK */
  return(0);
}

/*************************************************************************************/
