/**********************************************************************
 *                                                                    *
 *  Dc_Shared.c : Module de la bibliothèque de fonctions génériques.  *
 *                                                                    *
 **********************************************************************
 *   Auteur : Olivier ZARDINI  *  Brutal Deluxe  *  Date : Jan 2013   *
 **********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <malloc.h>
#include <string.h>
#include <ctype.h>
#include <io.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/timeb.h>
#include <direct.h>
#ifndef WIN32
//#include <dirent.h>
#endif
#include <errno.h>
#include <math.h>

#include "Dc_Shared.h"

struct one_file
{
  char *file_path;
  
  struct one_file *next;
};

struct one_file *LoadListFiles(char *);
void mem_free_onefile_list(struct one_file *);
int compare_file(const void *,const void *);
char *my_strstr(char *,char *);
int myq_stricmp(char *,char *);
int myq_strnicmp(char *,char *,int);

/********************************************************************/
/*  BuildFileTab() :  Construit un tableau de la liste de fichiers. */
/********************************************************************/
char **BuildFileTab(char *file_path, int *nb_file_rtn)
{
  int i, nb_file;
  char **tab_file;
  struct one_file *first_file = NULL;  
  struct one_file *current_file;

  /** Cas particulier : un seul fichier **/
  if(strchr(file_path,'*') == NULL)
    {
      nb_file = 1;
      tab_file = (char **) calloc(1,sizeof(char *));
      if(tab_file == NULL)
        return(NULL);
      tab_file[0] = _strdup(file_path);
      if(tab_file[0] == NULL)
        {
          free(tab_file);
          return(NULL);
        }
      *nb_file_rtn = nb_file;
      return(tab_file);
    }

  /*** Il faut récupérer la liste des fichiers ***/
  /* Charge tous les fichier en mémoire */
  first_file = LoadListFiles(file_path);
  if(first_file == NULL)
    return(NULL);

  /* Compte le nombre de fichiers */
  for(nb_file=0,current_file = first_file; current_file; current_file = current_file->next)
    nb_file++;

  /* Création du tableau d'accès rapide */
  tab_file = (char **) calloc(nb_file,sizeof(char *));
  if(tab_file == NULL)
    return(NULL);
  for(i=0,current_file = first_file; current_file; current_file = current_file->next,i++)
    {
      tab_file[i] = current_file->file_path;
      current_file->file_path = NULL;
    }

  /* Libération de la liste */
  mem_free_onefile_list(first_file);

  /* Tri les fichiers par ordre alphabétique */  
  qsort(tab_file,nb_file,sizeof(char *),compare_file);

  /* Renvoie le tableau */
  *nb_file_rtn = nb_file;
  return(tab_file);
}


/*********************************************************************/
/*  LoadListFiles() :  Charge tous les fichiers binaires en mémoire. */
/*********************************************************************/
struct one_file *LoadListFiles(char *source_file_path)
{
#if defined(WIN32) || defined(WIN64)
  int i, rc;
  long hFile;
  int first_time = 1;
  struct _finddata_t c_file;
  char folder_path[1024];
  char buffer_file_path[1024];
  struct one_file *first_file = NULL;
  struct one_file *last_file = NULL;
  struct one_file *new_file;

  /* Extrait le nom du répertoire */
  strcpy(folder_path,source_file_path);
  for(i=strlen(folder_path); i>=0; i--)
    if(folder_path[i] == FOLDER_SEPARATOR_CHAR)    /* \ or / */
      {
        folder_path[i+1] = '\0';
        break;
      }

  /** On boucle sur tous les fichiers présents **/
  while(1)
    {
      if(first_time == 1)
        {
          hFile = _findfirst(source_file_path,&c_file);
          rc = (int) hFile;
        }
      else
        rc = _findnext(hFile,&c_file);

      /* On analyse le résultat */
      if(rc == -1)
        break;    /* no more files */
      first_time++;

      /* On ne traite pas les dossiers **/
      if((c_file.attrib & _A_SUBDIR) == _A_SUBDIR)
        continue;

      /** On traite cette entrée **/
      /* Chemin du fichier */
      sprintf(buffer_file_path,"%s%s",folder_path,c_file.name);

      /** Conserve le chemin du fichier **/
      new_file = (struct one_file *) calloc(1,sizeof(struct one_file));
      if(new_file == NULL)
        {
          mem_free_onefile_list(first_file);
          _findclose(hFile);
          return(NULL);
        }
      new_file->file_path = _strdup(buffer_file_path);
      if(new_file->file_path == NULL)
        {
          free(new_file);
          mem_free_onefile_list(first_file);
          _findclose(hFile);
          return(NULL);
        }

      /* Rattache à la liste chainée */
      if(first_file == NULL)
        first_file = new_file;
      else
        last_file->next = new_file;
      last_file = new_file;
    }

  /* On ferme */
  _findclose(hFile);

  return(first_file);
#else
  DIR *dir;
  struct dirent *d;
  struct stat st;  
  char folder_path[1024];
  char buffer_file_path[1024];
  struct one_file *first_file = NULL;
  struct one_file *last_file = NULL;
  struct one_file *new_file;

  /* Extrait le nom du répertoire */
  strcpy(folder_path,source_file_path);
  for(int i=strlen(folder_path); i>=0; i--)
    if(folder_path[i] == FOLDER_SEPARATOR_CHAR)    /* \ or / */
      {
        folder_path[i+1] = '\0';
        break;
      }

  /* Ouverture du répertoire */
  dir = opendir(folder_path);
  if(dir == NULL)
    return(NULL);

  /* Passe toutes les entrées en revue */
  while((d = readdir(dir)))    
    {
      /* On ignore . et .. */
      if(!strcmp(d->d_name,".") || !strcmp(d->d_name,".."))
        continue;

      /* Nom complet */
      sprintf(buffer_file_path,"%s%c%s",folder_path,FOLDER_SEPARATOR_CHAR,d->d_name);

      /* On ignore les dossier */
      stat(buffer_file_path,&st);
      if(S_ISDIR(st.st_mode))
        continue;

      /* Le fichier fait t'il partie de la sélection */
      if(MatchHierarchy(buffer_file_path,source_file_path) == 0)
        continue;

      /** Conserve le chemin du fichier **/
      new_file = (struct one_file *) calloc(1,sizeof(struct one_file));
      if(new_file == NULL)
        {
          mem_free_onefile_list(first_file);
          closedir(dir);
          return(NULL);
        }
      new_file->file_path = strdup(buffer_file_path);
      if(new_file->file_path == NULL)
        {
          free(new_file);
          mem_free_onefile_list(first_file);
          closedir(dir);
          return(NULL);
        }

      /* Rattache à la liste chainée */
      if(first_file == NULL)
        first_file = new_file;
      else
        last_file->next = new_file;
      last_file = new_file;
    }
    
  /* Fermeture du répertoire */          
  closedir(dir);
  
  /* Renvoie la liste de fichier */
  return(first_file);
#endif  
}


/******************************************************/
/*  ExchangeByte() :  Echange les 2 octets d'un WORD. */
/******************************************************/
WORD ExchangeByte(WORD pattern)
{
  WORD new_pattern;

  new_pattern = (pattern >> 8) | (pattern << 8);

  return(new_pattern);
}


/******************************************************************************/
/*  mem_free_onefile_list() :  Libération d'une liste de structures one_file. */
/******************************************************************************/
void mem_free_onefile_list(struct one_file *first_file)
{
  struct one_file *current_file;
  struct one_file *next_file;
  
  for(current_file=first_file; current_file; )
    {
      next_file = current_file->next;
      if(current_file->file_path)
        free(current_file->file_path);
      free(current_file);
      current_file = next_file;
    }
}


/*****************************************************/
/*  compare_file() : On tri par ordre alphabétique.  */
/*****************************************************/
int compare_file(const void *arg1, const void *arg2)
{
  char *file_path1 = *((char **)arg1);
  char *file_path2 = *((char **)arg2);

  /* On compare les deux chemin */
  return(my_stricmp(file_path1,file_path2));
}


/******************************************************/
/*  mem_free_list() :  Libération mémoire du tableau. */
/******************************************************/
void mem_free_list(int nb_values, char **values)
{
  int i;

  /* On libère le tableau */
  if(values)
    {
      for(i=0; i<nb_values; i++)
        if(values[i])
          free(values[i]);
      free(values);
    }
}


/***********************************************************************/
/*  BuildListFromFile() :  Récupère la liste des valeurs d'un fichier. */
/***********************************************************************/
char **BuildListFromFile(char *file_path, int *nb_value)
{
  FILE *fd;
  int nb_line, line_length;
  char **tab;
  char buffer_line[1024];

  /* Ouverture du fichier */
  fd = fopen(file_path,"r");
  if(fd == NULL)
    return(NULL);

  /* Compte le nombre de lignes */
  nb_line = 0;
  fseek(fd,0L,SEEK_SET);
  while(fgets(buffer_line,1024-1,fd))
    nb_line++;

  /* Allocation du tableau */
  tab = (char **) calloc(nb_line,sizeof(char *));
  if(tab == NULL)
    {
      fclose(fd);
      return(NULL);
    }

  /** Lecture du fichier **/
  nb_line = 0;
  fseek(fd,0L,SEEK_SET);
  while(fgets(buffer_line,1024-1,fd))
    {
      /** Traitement préliminaire de nettoyage **/
      line_length = strlen(buffer_line);
      if(line_length < 2)              /* Ligne vide */
        continue;
      if(buffer_line[line_length-1] == '\n')
        buffer_line[line_length-1] = '\0';  /* On vire le \n final */

      /** Stocke la valeur **/
      tab[nb_line] = _strdup(buffer_line);
      if(tab[nb_line] == NULL)
        {
          mem_free_list(nb_line,tab);
          fclose(fd);
          return(NULL);
        }
      nb_line++;
    }

  /* Fermeture du fichier */
  fclose(fd);

  /* Renvoi le tableau */
  *nb_value = nb_line;
  return(tab);
}


/**************************************************/
/*  GetOneByte() :  Décode un octet de l'operand. */
/**************************************************/
unsigned char GetOneByte(char *operand)
{
  unsigned int integer;
  char buffer[10];

  /** On reconnait la forme $XX **/
  if(strlen(operand) == 3)
    if(operand[0] == '$')
      {
        sscanf(&operand[1],"%02X",&integer);
        return((unsigned char)integer);
      }

  /** On reconnait la forme #$XX **/
  if(strlen(operand) == 4)
    if(!my_strnicmp(operand,"#$",2))
      {
        sscanf(&operand[2],"%02X",&integer);
        return((unsigned char)integer);
      }

  /** On reconnait la forme $XX,S **/
  if(strlen(operand) == 5)
    if(operand[0] == '$' && !my_stricmp(&operand[3],",S"))
      {
        buffer[0] = operand[1];
        buffer[1] = operand[2];
        buffer[2] = '\0';
        sscanf(buffer,"%02X",&integer);
        return((unsigned char)integer);
      }

  /* Inconnu */
  return(0x00);
}


/*************************************************/
/*  GetOneWord() :  Décode un WORD de l'operand. */
/*************************************************/
WORD GetOneWord(char *operand)
{
  unsigned int integer;

  /** On reconnait la forme $XXXX **/
  if(strlen(operand) == 5)
    if(operand[0] == '$')
      {
        sscanf(&operand[1],"%04X",&integer);
        return((WORD)integer);
      }

  /** On reconnait la forme #$XXXX **/
  if(strlen(operand) == 6)
    if(!my_strnicmp(operand,"#$",2))
      {
        sscanf(&operand[2],"%04X",&integer);
        return((WORD)integer);
      }

  /* Inconnu */
  return(0x0000);
}


/**********************************************/
/*  Get24Bit() :  Décode 24 bit de l'operand. */
/**********************************************/
DWORD Get24Bit(char *operand)
{
  unsigned int integer;

  /** On reconnait la forme $XXXXXX **/
  if(strlen(operand) == 7)
    if(operand[0] == '$')
      {
        sscanf(&operand[1],"%06X",&integer);
        return((DWORD)integer);
      }

  /* Inconnu */
  return(0x000000);
}


/***************************************************************************/
/*  RenameAllFiles() :  Renomme tous les fichiers de manière incrémentale. */
/***************************************************************************/
int RenameAllFiles(int nb_file, char **tab_file, char *file_name_prefix, char *file_name_extension)
{
  int i, result;
  char folder_path[1024];
  char file_path[1024];

  /* Chemin du dossier */
  strcpy(folder_path,tab_file[0]);
  for(i=strlen(folder_path); i>=0; i--)
    if(folder_path[i] == FOLDER_SEPARATOR_CHAR)   /* \ or / */
      {
        folder_path[i+1] = '\0';
        break;
      }

  /** Traite tous les fichiers**/
  for(i=0; i<nb_file; i++)
    {
      /* Nouveau nom */
      sprintf(file_path,"%s%s_%03d.%s",folder_path,file_name_prefix,i,file_name_extension);

      /* Renommage */
      result = rename(tab_file[i],file_path);
      if(result != 0)
        printf("  Error : Impossible to rename file '%s' as '%s'",tab_file[i],file_path);
    }

  /* OK */
  return(0);
}


/************************************************************************/
/*  my_stricmp() :  On compare les chaines de caractère sans la casse.  */
/************************************************************************/
int my_stricmp(char *s1, char *s2)
{
#if defined(WIN32) || defined(WIN64)
  return(_stricmp(s1,s2));
#else
  /* Cette fonction n'existe pas de façon native sous Unix */
  for( ; ( *s1 && *s2 ) && (((tolower)(*s1)) == ((tolower)(*s2))); s1++, s2++)
    ;

  return(((tolower)(*s1)) - ((tolower)(*s2)));
#endif
}


/*************************************************************************/
/*  my_strnicmp() :  On compare les chaines de caractère sans la casse.  */
/*************************************************************************/
int my_strnicmp(char *s1, char *s2, int length)
{
#if defined(WIN32) || defined(WIN64)
  return(_strnicmp(s1,s2,length));
#else
  /* Cette fonction n'existe pas de façon native sous Unix */
  if(length == 0)
    return(0);

  for( ; (*s1!=0) && (*s2!=0) && (length>0); s1++, s2++, length--)
      if(((tolower)(*s1)) != ((tolower)((*s2))))
        return(((tolower)(*s1)) - ((tolower)(*s2)));

  if(length == 0)
    return(0);
  else
    return(1);
#endif
}


/**********************************************************************/
/*  MatchHierarchy() : Indique si un nom appartient à une hiérarchie. */
/**********************************************************************/
int MatchHierarchy(char *name, char *hierarchie)
{
  int i,j,k;
  int length;
  char *hier_ptr;
  char *name_ptr;
  int result;
  int count;
  size_t offset;
  char buffer[2048];

  /*** On parcours les deux chaînes ***/
  for(i=0,j=0; i<(int)strlen(hierarchie); i++)
    {
      if(hierarchie[i] != '*')
        {
          if(toupper(hierarchie[i]) !=  toupper(name[j]) &&
            !(hierarchie[i] == '/' && name[j] == '\\') &&
            !(hierarchie[i] == '\\' && name[j] == '/'))
            return(0);
          j++;
        }
      else if(hierarchie[i] == '?')
        j++;
      else
        {
          /* Si '*' dernier caractère de la chaîne => OK */
          if(hierarchie[i+1] == '\0')
            return(1);

          /** S'il ne reste pas d'autre '*' : On compare la fin **/
          hier_ptr = strchr(&hierarchie[i+1],'*');
          if(hier_ptr == NULL)
            {
              length = (int)strlen(&hierarchie[i+1]);
              if((int)strlen(&name[j]) < length)
                return(0);
              if(!myq_stricmp(&name[strlen(name)-length],&hierarchie[i+1]))
                return(1);
              else
                return(0);
            }

          /** On compte le nb d'occurences de la partie entre les deux '*' dans name **/
          strncpy(buffer,&hierarchie[i+1],hier_ptr-&hierarchie[i+1]);
          buffer[hier_ptr-&hierarchie[i+1]] = '\0';
          length = (int)strlen(buffer);
          for(count = 0,offset = j;;count++)
            {
              name_ptr = my_strstr(&name[offset],buffer);
              if(name_ptr == NULL)
                break;
              offset = (name_ptr - name) + 1;
            }
          /* Si aucune occurence => pas de matching */
          if(count == 0)
            return(0);

          /** On lance la récursivité sur toutes les occurences trouvées **/
          for(k=0,offset=j; k<count; k++)
            {
              name_ptr = my_strstr(&name[offset],buffer);
              result = MatchHierarchy(name_ptr+length,&hierarchie[i+1+length]);
              if(result)
                return(1);
              offset = (name_ptr - name) + 1;
            }
          return(0);
        }
    }

  /* On est arrivé au bout : OK */
  return(1);
}


/**********************************************************************/
/*  my_strstr() : Recherche l'occurence d'une chaîne dans une autre.  */
/**********************************************************************/
char *my_strstr(char *name, char *hierarchie)
{
  int i;
  int length_n = (int)strlen(name);
  int length_h = (int)strlen(hierarchie);

  /* On élimine les cas extrêmes */
  if(length_n < length_h)
    return(NULL);

  /** On parcours la chaîne 'name' afin de localiser la chaine 'hierarchie' **/
  for(i=0; i<length_n-length_h+1; i++)
    {
      /* La recherche tient compte des '?' */
      if(!myq_strnicmp(&name[i],hierarchie,length_h))
        return(&name[i]);
    }

  /* On a rien trouvé */
  return(NULL);
}


/********************************************************************/
/*  myq_stricmp() : Compare deux chaînes de caractères avec les '?'. */
/********************************************************************/
int myq_stricmp(char *string_n, char *string_h)
{
  int i;
  int length_n = (int)strlen(string_n);
  int length_h = (int)strlen(string_h);

  /* On élimine immédiatement les cas défavorables */
  if(length_n != length_h)
    return(1);

  /** On compare tous les caractères avec gestion du '?' **/
  for(i=0; i<length_n; i++)
    {
      if(string_h[i] == '?')
        continue;
      else if((toupper(string_n[i]) != toupper(string_h[i])) && 
              !(string_n[i]=='\\' && string_h[i]=='/') &&
              !(string_n[i]=='/' && string_h[i]=='\\'))
        return(1);
    }

  /* On a deux chaînes identiques */
  return(0);
}


/*********************************************************************/
/*  myq_strnicmp() : Compare deux chaînes de caractères avec les '?'. */
/*********************************************************************/
int myq_strnicmp(char *string_n, char *string_h, int length)
{
  int i;
  int length_n = (int)strlen(string_n);
  int length_h = (int)strlen(string_h);

  /* On élimine immédiatement les cas défavorables */
  if(length_n < length || length_h < length)
    return(1);

  /** On compare tous les caractères avec gestion du '?' **/
  for(i=0; i<length; i++)
    {
      if(string_h[i] == '?')
        continue;
      else if(toupper(string_n[i]) != toupper(string_h[i]))
        return(1);
    }

  /* On a deux chaînes identiques */
  return(0);
}

/********************************************************************/
