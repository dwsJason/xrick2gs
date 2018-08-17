/*****************************************************************
 *                                                               *
 *   Dc_Memory.h : Header de gestion des ressources memoires.    *
 *                                                               *
 *****************************************************************
 *  Auteur : Olivier ZARDINI  *  CooperTeam  *  Date : Jan 2013  *
 *****************************************************************/

#define MEMORY_INIT             1
#define MEMORY_FREE             2

#define MEMORY_ADD_PATTERN       10
#define MEMORY_GET_PATTERN_NB    11
#define MEMORY_GET_PATTERN       12
#define MEMORY_GET_PATTERN_SCORE 13
#define MEMORY_SORT_PATTERN      14
#define MEMORY_FREE_PATTERN      15

#define MEMORY_ADD_CODELINE      20
#define MEMORY_GET_CODELINE_NB   21
#define MEMORY_GET_CODELINE      22
#define MEMORY_DROP_CODELINE     23
#define MEMORY_FREE_CODELINE     25

#define MEMORY_ADD_REDPATTERN    30
#define MEMORY_GET_REDPATTERN    32
#define MEMORY_SORT_REDPATTERN   34
#define MEMORY_FREE_REDPATTERN   35

#define MEMORY_ADD_COMMENT       40

#define MEMORY_ADD_CODEFILE      50
#define MEMORY_GET_CODEFILE_NB   51
#define MEMORY_GET_CODEFILE      52
#define MEMORY_SORT_CODEFILE     53
#define MEMORY_FREE_CODEFILE     54

struct pattern
{
  WORD pattern_data;
  int nb_found;

  struct pattern *next;
};

void my_Memory(int,void *,void *);
int compare_filepath(const void *,const void *);
int compare_codefile_size(const void *,const void *);
int compare_codefile_num(const void *,const void *);

/*****************************************************************/
