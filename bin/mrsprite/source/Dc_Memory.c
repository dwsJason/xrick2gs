/*****************************************************************
 *                                                               *
 *   Dc_Memory.c : Module de gestion des ressources memoires.    *
 *                                                               *
 *****************************************************************
 *  Auteur : Olivier ZARDINI  *  CooperTeam  *  Date : Jan 2013  *
 *****************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>

#include "Dc_Code.h"
#include "Dc_Shared.h"
#include "Dc_Memory.h"

int compare_pattern(const void *,const void *);

/******************************************************/
/*  my_Memory() :  Fonction de gestion de la mémoire. */
/******************************************************/
void my_Memory(int code, void *data, void *value)
{
  int i, index;
  WORD pattern_data;
  static int nb_pattern;                   /* Pattern */
  static struct pattern *first_pattern;
  static struct pattern *last_pattern;
  struct pattern *current_pattern;
  struct pattern *next_pattern;
  struct pattern **tab_pattern;
  static int nb_redpattern;                /* Red Pattern */
  static struct pattern *first_redpattern;
  static struct pattern *last_redpattern;
  struct pattern *current_redpattern;
  struct pattern *next_redpattern;
  struct pattern **tab_redpattern;
  static int nb_codeline;                  /* Ligne de Code */
  static struct code_line *first_codeline;
  static struct code_line *last_codeline;
  struct code_line *current_codeline;
  struct code_line *next_codeline;
  static char buffer_comment[512];         /* Commentaire */
  static int nb_codefile;                  /* Fichier de Code */
  static struct code_file *first_codefile;
  static struct code_file *last_codefile;
  struct code_file *current_codefile;
  struct code_file *next_codefile;
  struct code_file **tab_codefile;

  switch(code)
    {
      case MEMORY_INIT :
        nb_pattern = 0;
        first_pattern = NULL;
        last_pattern = NULL;
        nb_redpattern = 0;
        first_redpattern = NULL;
        last_redpattern = NULL;
        nb_codeline = 0;
        first_codeline = NULL;
        last_codeline = NULL;
        strcpy(buffer_comment,"");
        nb_codefile = 0;
        first_codefile = NULL;
        last_codefile = NULL;
        break;

      case MEMORY_FREE :
        my_Memory(MEMORY_FREE_PATTERN,NULL,NULL);
        my_Memory(MEMORY_FREE_REDPATTERN,NULL,NULL);
        my_Memory(MEMORY_FREE_CODELINE,NULL,NULL);
        my_Memory(MEMORY_FREE_CODEFILE,NULL,NULL);
        break;

      /*************************/
      /*  Gestion des Pattern  */
      /*************************/
      case MEMORY_ADD_PATTERN :
        pattern_data = *((WORD *) data);

        /* A t'on déjà cette pattern */
        for(current_pattern=first_pattern; current_pattern; current_pattern=current_pattern->next)
          if(current_pattern->pattern_data == pattern_data)
            {
              current_pattern->nb_found++;
              return;
            }

        /* Création d'une nouvelle */
        current_pattern = (struct pattern *) calloc(1,sizeof(struct pattern));
        if(current_pattern == NULL)
          return;
        current_pattern->pattern_data = pattern_data;
        current_pattern->nb_found = 1;

        /* Attachement à la liste */
        if(first_pattern == NULL)
          first_pattern = current_pattern;
        else
          last_pattern->next = current_pattern;
        last_pattern = current_pattern;
        nb_pattern++;
        break;

      case MEMORY_GET_PATTERN_NB :
        *((int *) data) = nb_pattern;
        break;

      case MEMORY_GET_PATTERN :
        index = *((int *)data);
        *((struct pattern **) value) = NULL;
        if(index <= 0 || index > nb_pattern)
          break;

        for(i=1,current_pattern=first_pattern; i<=nb_pattern; i++,current_pattern=current_pattern->next)
          if(i == index)
            {
              *((struct pattern **) value) = current_pattern;
              break;
            }
        break;

      case MEMORY_GET_PATTERN_SCORE :
        pattern_data = *((WORD *) data);
        for(i=0,current_pattern=first_pattern; current_pattern; current_pattern=current_pattern->next,i++)
          {
            if(i > 2)   /* On ne prend en compte que les 3 premiers Pattern stockées dans les registres 16 bits X, Y et D */
              break;
            else if(current_pattern->pattern_data == pattern_data)
              {
                *((int *) value) = current_pattern->nb_found;
                return;
              }
          }

        /* Pas trouvé */
        *((int *) value) = 0;
        break;

      case MEMORY_SORT_PATTERN :
        if(nb_pattern == 0 || nb_pattern == 1)
          break;

        /* Allocation */
        tab_pattern = (struct pattern **) calloc(nb_pattern,sizeof(struct pattern *));
        if(tab_pattern == NULL)
          return;

        /* Remplissage */
        for(i=0, current_pattern = first_pattern; current_pattern; current_pattern = current_pattern->next,i++)
          tab_pattern[i] = current_pattern;

        /* Tri */
        qsort(tab_pattern,nb_pattern,sizeof(struct pattern *),compare_pattern);

        /* Recablage */
        first_pattern = tab_pattern[0];
        last_pattern = tab_pattern[nb_pattern-1];
        last_pattern->next = NULL;
        for(i=0; i<nb_pattern-1; i++)
          tab_pattern[i]->next =  tab_pattern[i+1];

        /* Libération */
        free(tab_pattern);
        break;

      case MEMORY_FREE_PATTERN :
        for(current_pattern=first_pattern; current_pattern; )
          {
            next_pattern = current_pattern->next;
            free(current_pattern);
            current_pattern = next_pattern;
          }
        nb_pattern = 0;
        first_pattern = NULL;
        last_pattern = NULL;
        break;


      /*****************************/
      /*  Gestion des Red Pattern  */
      /*****************************/
      case MEMORY_ADD_REDPATTERN :
        pattern_data = *((WORD *) data);

        /* A t'on déjà cette pattern */
        for(current_redpattern=first_redpattern; current_redpattern; current_redpattern=current_redpattern->next)
          if(current_redpattern->pattern_data == pattern_data)
            {
              current_redpattern->nb_found++;
              return;
            }

        /* Création d'une nouvelle */
        current_redpattern = (struct pattern *) calloc(1,sizeof(struct pattern));
        if(current_redpattern == NULL)
          return;
        current_redpattern->pattern_data = pattern_data;
        current_redpattern->nb_found = 1;

        /* Attachement à la liste */
        if(first_redpattern == NULL)
          first_redpattern = current_redpattern;
        else
          last_redpattern->next = current_redpattern;
        last_redpattern = current_redpattern;
        nb_redpattern++;
        break;

      case MEMORY_GET_REDPATTERN :
        index = *((int *) data);
        *((struct pattern **) value) = NULL;
        if(index <= 0 || index > nb_redpattern)
          break;

        for(i=1,current_redpattern=first_redpattern; i<=nb_redpattern; i++,current_redpattern=current_redpattern->next)
          if(i == index)
            {
              *((struct pattern **) value) = current_redpattern;
              break;
            }
        break;

      case MEMORY_SORT_REDPATTERN :
        if(nb_redpattern == 0 || nb_redpattern == 1)
          break;

        /* Allocation */
        tab_redpattern = (struct pattern **) calloc(nb_redpattern,sizeof(struct pattern *));
        if(tab_redpattern == NULL)
          return;

        /* Remplissage */
        for(i=0, current_redpattern = first_redpattern; current_redpattern; current_redpattern = current_redpattern->next,i++)
          tab_redpattern[i] = current_redpattern;

        /* Tri */
        qsort(tab_redpattern,nb_redpattern,sizeof(struct pattern *),compare_pattern);

        /* Recablage */
        first_redpattern = tab_redpattern[0];
        last_redpattern = tab_redpattern[nb_redpattern-1];
        last_redpattern->next = NULL;
        for(i=0; i<nb_redpattern-1; i++)
          tab_redpattern[i]->next =  tab_redpattern[i+1];

        /* Libération */
        free(tab_redpattern);
        break;

      case MEMORY_FREE_REDPATTERN :
        for(current_redpattern=first_redpattern; current_redpattern; )
          {
            next_redpattern = current_redpattern->next;
            free(current_redpattern);
            current_redpattern = next_redpattern;
          }
        nb_redpattern = 0;
        first_redpattern = NULL;
        last_redpattern = NULL;
        break;


      /********************************/
      /*  Gestion des Lignes de Code  */
      /********************************/
      case MEMORY_ADD_CODELINE :
        current_codeline = (struct code_line *) data;

        /* Attachement à la liste */
        if(first_codeline == NULL)
          first_codeline = current_codeline;
        else
          last_codeline->next = current_codeline;
        last_codeline = current_codeline;
        nb_codeline++;

        /* Met le commentaire */
        if(strlen(buffer_comment) > 0 && strlen(current_codeline->comment) == 0)
          strcpy(current_codeline->comment,buffer_comment);

        /* Vide le commentaire */
        strcpy(buffer_comment,"");
        break;

      case MEMORY_GET_CODELINE_NB :
        *((int *) data) = nb_codeline;
        break;

      case MEMORY_GET_CODELINE :
        index = *((int *) data);
        *((struct code_line **) value) = NULL;
        if(index <= 0 || index > nb_codeline)
          break;

        for(i=1,current_codeline=first_codeline; i<=nb_codeline; i++,current_codeline=current_codeline->next)
          if(i == index)
            {
              *((struct code_line **) value) = current_codeline;
              break;
            }
        break;

      case MEMORY_DROP_CODELINE :
        /** Supprime la dernière ligne ajoutée **/
        if(last_codeline == NULL)
          return;
        if(nb_codeline == 1)
          {
            free(first_codeline);
            nb_codeline = 0;
            first_codeline = NULL;
            last_codeline = NULL;
          }
        else
          {
            /* Cas général */
            for(current_codeline=first_codeline; current_codeline; current_codeline=current_codeline->next)
              if(current_codeline->next == last_codeline)
                break;
            free(last_codeline);
            nb_codeline--;
            last_codeline = current_codeline;
            current_codeline->next = NULL;
          }
        break;

      case MEMORY_FREE_CODELINE :
        for(current_codeline=first_codeline; current_codeline; )
          {
            next_codeline = current_codeline->next;
            free(current_codeline);
            current_codeline = next_codeline;
          }
        nb_codeline = 0;
        first_codeline = NULL;
        last_codeline = NULL;
        break;

      /*******************************************************/
      /*  Commentaire à ajouter à la ligne de code suivante  */
      /*******************************************************/
      case MEMORY_ADD_COMMENT :
        strcpy(buffer_comment,(char *)data);
        break;

      /*******************************/
      /*  Liste des fichiers Source  */
      /*******************************/
      case MEMORY_ADD_CODEFILE :
        current_codefile = (struct code_file *) data;

        /* Attachement à la liste */
        if(first_codefile == NULL)
          first_codefile = current_codefile;
        else
          last_codefile->next = current_codefile;
        last_codefile = current_codefile;
        nb_codefile++;
        break;

      case MEMORY_GET_CODEFILE_NB :
        *((int *) data) = nb_codefile;
        break;

      case MEMORY_GET_CODEFILE :
        index = *((int *) data);
        *((struct code_file **) value) = NULL;
        if(index <= 0 || index > nb_codefile)
          break;

        for(i=1,current_codefile=first_codefile; i<=nb_codefile; i++,current_codefile=current_codefile->next)
          if(i == index)
            {
              *((struct code_file **) value) = current_codefile;
              break;
            }
        break;

      case MEMORY_SORT_CODEFILE :
        if(nb_codefile == 0 || nb_codefile == 1)
          break;

        /* Allocation */
        tab_codefile = (struct code_file **) calloc(nb_codefile,sizeof(struct code_file *));
        if(tab_codefile == NULL)
          return;

        /* Remplissage */
        for(i=0, current_codefile = first_codefile; current_codefile; current_codefile = current_codefile->next,i++)
          tab_codefile[i] = current_codefile;

        /* Tri */
        qsort(tab_codefile,nb_codefile,sizeof(struct code_file *),(int (*)(const void *,const void *))data);

        /* Recablage */
        first_codefile = tab_codefile[0];
        last_codefile = tab_codefile[nb_codefile-1];
        last_codefile->next = NULL;
        for(i=0; i<nb_codefile-1; i++)
          tab_codefile[i]->next =  tab_codefile[i+1];

        /* Libération */
        free(tab_codefile);
        break;

      case MEMORY_FREE_CODEFILE :
        for(current_codefile=first_codefile; current_codefile; )
          {
            next_codefile = current_codefile->next;
            free(current_codefile);
            current_codefile = next_codefile;
          }
        nb_codefile = 0;
        first_codefile = NULL;
        last_codefile = NULL;
        break;

      default :
        break;
    }
}


/**************************************************************/
/*  compare_pattern() :  Fonction de comparaison des pattern. */
/**************************************************************/
int compare_pattern(const void *data_1, const void *data_2)
{
  struct pattern *pattern_1;
  struct pattern *pattern_2;

  /* Récupère les structures */
  pattern_1 = *((struct pattern **) data_1);
  pattern_2 = *((struct pattern **) data_2);

  /* Comparaison du nb */
  if(pattern_1->nb_found < pattern_2->nb_found)
    return(1);
  else if(pattern_1->nb_found == pattern_2->nb_found)
    return(0);
  else
    return(-1);
}


/**********************************************************************/
/*  compare_codefile_size() :  Fonction de comparaison des code_file. */
/**********************************************************************/
int compare_codefile_size(const void *data_1, const void *data_2)
{
  struct code_file *codefile_1;
  struct code_file *codefile_2;

  /* Récupère les structures */
  codefile_1 = *((struct code_file **) data_1);
  codefile_2 = *((struct code_file **) data_2);

  /* Comparaison de la taille de l'objet */
  if(codefile_1->size < codefile_2->size)
    return(1);
  else if(codefile_1->size == codefile_2->size)
    return(0);
  else
    return(-1);
}


/*********************************************************************/
/*  compare_codefile_num() :  Fonction de comparaison des code_file. */
/*********************************************************************/
int compare_codefile_num(const void *data_1, const void *data_2)
{
  struct code_file *codefile_1;
  struct code_file *codefile_2;

  /* Récupère les structures */
  codefile_1 = *((struct code_file **) data_1);
  codefile_2 = *((struct code_file **) data_2);

  /* Comparaison du numéro de l'objet */
  if(codefile_1->index > codefile_2->index)
    return(1);
  else if(codefile_1->index == codefile_2->index)
    return(0);
  else
    return(-1);
}


/***************************************************************/
/*  compare_filepath() :  Fonction de comparaison des chemins. */
/***************************************************************/
int compare_filepath(const void *data_1, const void *data_2)
{
  char *filepath_1;
  char *filepath_2;

  /* Récupère les structures */
  filepath_1 = *((char **) data_1);
  filepath_2 = *((char **) data_2);

  /* Comparaison des noms */
  return(my_stricmp(filepath_1,filepath_2));
}

/*****************************************************************/
