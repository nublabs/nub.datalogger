#include<math.h>
#include "datalogger_config.h"

void stringFloat(float a)  //takes in a float and prints it out as a string to the serial port
{
  //cast the float as an int, truncating the precision to two decimal points
  int num = a*pow(10, MY_DIGITS_OF_PRECISION);
  char* stringNum = '';
  stringNum += itoa((float(num)/pow(10, digitsOfPrecision)));
  stringNum += '.';
  
  //if num is negative, this can come out negative, too and that's an easy way to flip out some bits on the computer side 
  stringNum += itoa(abs(num%10));
  
  return stringNum;
}
