#include <EEPROM.h>
#include <avr/power.h>
#include <avr/sleep.h>
#include <string.h> 
#include <stdlib.h>
#include <avr/interrupt.h>
#include "XBee_communications.h"
#include "configuration.h"

#define NAME "gretchen"

//move the EEPROM data down by 1--the first location gets corrupted in a brownout


float RBOTTOM=1000.0;
float B=3950.0;
float R0=10000.0;
float T0=298.0;

float sensor1_top;
float sensor2_top;
float sensor1_bottom;
float sensor2_bottom;

float r1,r2, temp1, temp2;
int chksum; 

int milliseconds, seconds, minutes;

int interval;
byte unit;
int repetitions;
  
boolean repeat;
int count;

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*
// Configuration

*/

char * config_name;
char ** config_fields;
int * config_values;


void defineDefaultConfig(){
  config_name = "default";
  config_fields[0] = "delay";
  config_fields[1] = "numSamples";
  config_fields[2] = "timeToRun";
  config_values[0] = 1000;
  config_values[1] = -1;
  config_values[2] = -1;
}

struct pin {
 int number;
};
pin LEDpin, switchPin, sleepPin, wakePin;









//broadcast yourself to the world, looking for a dongle to talk to.








void getConfirmation()
{
  byte confirmationByte=255;
  delay(COMM_DELAY);
  if(Serial.available() > 0)
      confirmationByte=Serial.read();
  switch(confirmationByte){
    case(OK):
      repeat=false;
    break;
    case(RESEND):
      repeat=true;
      count++;
    break;
    case(STAND_BY_FOR_CONFIG):
       repeat=false;
       getConfig();
    break;
  }
}

void getConfig()
{
  byte count=0;
  boolean done=false;
  while((count<3) && (done==false))   //give it three tries, then bail if it's not working.
  {
    count++;
  byte checksum=0;
  byte data;
  byte error=EVERYTHINGS_FINE;
  
  //start byte
  delay(COMM_DELAY);
  if(Serial.available()>0)
  {
    data=Serial.read();
    if(data!=MESSAGE_START)
      error=BAD_PACKET_STRUCTURE_ERROR;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;
 
 //INTERVAL HIGH BYTE
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    data=Serial.read();
    checksum+=data;
    interval=256*(int)data;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;

 //INTERVAL LOW BYTE
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    data=Serial.read();
    checksum+=data;
    interval+=(int)data;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;

 //UNIT
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    unit=Serial.read();
    checksum+=unit;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;

 //HIGH_REPETITION
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    data=Serial.read();
    checksum+=data;
    repetitions=data*256;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;

 //LOW_REPETITION
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    data=Serial.read();
    checksum+=data;
    repetitions+=data;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;

 //CHECKSUM
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    data=Serial.read();
    if(checksum!=data)
      error=BAD_CHECKSUM_ERROR;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;

 //END BYTE
  delay(COMM_DELAY);
  if((Serial.available()>0)&&(error==EVERYTHINGS_FINE))
  {
    data=Serial.read();
    if(MESSAGE_END!=data)
      error=BAD_PACKET_STRUCTURE_ERROR;
  }
  else if (Serial.available() == 0)
    error=NO_DATA_ERROR;
    
    Serial.print(error,BYTE);   //send out the error, if we have one
    if(error==EVERYTHINGS_FINE)
      done=true;
  }
}


void loop(){
   updateValues();
   repeat=true;
   count=0;
   while((repeat==true)&&(count<3))
   {
     count++;
     broadcastValues();
     getConfirmation();
   }
//   checkConfig();
   int i;
    delay(config_values[0]);  //delay in milliseconds
  
 // if (sensingDone()){
   //powerDown();
  //}
}
