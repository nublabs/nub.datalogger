#define FALSE 0
#define TRUE 1

//this is the message we send out to the computer
char message[50];

char discovered =TRUE;  //has the computer confirmed discovery?
char configured =TRUE;  //has the computer sent the sensor configuration info, or is it running off default values?

//the sample interval
int hours = 0;
int minutes = 0;
int seconds = 0;

//the buffer and the index and start bytes keep track of our own buffering system for data we use to get messages
char buffer[256];
unsigned char index=0;
unsigned char start=0;

//these ints hold the raw numerical values from the ADC
int sensor1_top;
int sensor1_bottom;
int sensor2_top;
int sensor2_bottom;

//these floats hold the calculated resistance values of each thermistor
float sensor1_resistance;
float sensor2_resistance;

//these floats hold the actual temperatures in degrees celsius
float sensor1_temperature;
float sensor2_temperature;
