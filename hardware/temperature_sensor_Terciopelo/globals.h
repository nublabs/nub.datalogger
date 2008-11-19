#define FALSE 0
#define TRUE 1

char discovered =TRUE;  //has the computer confirmed discovery?
char configured =TRUE;  //has the computer sent the sensor configuration info, or is it running off default values?

//the sample interval
int hours = 0;
int minutes = 0;
int seconds = 0;
