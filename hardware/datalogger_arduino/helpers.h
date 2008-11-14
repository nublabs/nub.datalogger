#ifndef HELPERS_H
#define HELPERS_H
#include "datalogger_config.h"

char* concatStrings(char** stringsToConcat){
 int numStrings = sizeof(stringsToConcat)/sizeof(stringsToConcat[0]);
 char* catted = "";
 for(int i = 0; i < numStrings; ++i){
   strcat(catted, stringsToConcat[i]);
 }
 
 return catted;
}
#endif
