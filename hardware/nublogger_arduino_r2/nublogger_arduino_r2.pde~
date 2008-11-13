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
struct configuration {
  char* name;
  char** fields;
  int* values};
};
configuration defaultConfig, receivedConfig;
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

void XBee_wake(){
  digitalWrite(sleepPin.number, LOW);
  delay(15);
}

void XBee_sleep(){
  pinMode(sleepPin.number, OUTPUT);
  digitalWrite(sleepPin.number, HIGH);
  delay(1000);  
}

ISR(TIMER2_COMPA_vect)    //timer2 compare match
{
  milliseconds+=33;
  if(milliseconds>1000)
  {
    milliseconds-=1000;
    seconds++;
  }
  if(seconds>60)
  {
    seconds-=60;
    minutes++;
  }
}

void timer2_init()
{
  TCCR2A=0;
  TCCR2B=(1<<CS22) | (1<<CS21) | (1<<CS20);  //set the clock prescaler to 1024.  slow it down as much as possible.
  OCR2A=255;    //we're going to check the counter and throw an interrupt when it's equal to OCR2A.  We can tweak this value later to give us sooper-accurate timing, 
                //but for now it's essentially an overflow.  Each overflow is 33 ms.
  TIMSK2=0;     //keep interrupts off for now, to keep things clean
}

void timer2_start()
{
  TIMSK2=(1<<OCIE2A);  //enable an interrupt on a OCR2A compare match
  sei();     //enable global interrupts;
}
void timer2_stop()
{
  TIMSK2=0;   //get rid of that interrupt
  cli();      //kill global interrupts
}


//Arduino ----------------------------------------
void Arduino_sleep(){
  set_sleep_mode(SLEEP_MODE_PWR_SAVE);   //put it to sleep but keep a clock running
  sleep_enable();
  //attachInterrupt(0, Arduino_wake, LOW);  no good--this is an external interrupt
  //we want to set up compare matches and prescalers on timer2, put it in PWR_SAVE mode (which kills everything except timer2)
  //and then just put it to sleep.  The interrupt vector for timer2 overflow will wake it up.
  sleep_mode();
  //Actually sleeps now
 
  sleep_disable();
}

void Arduino_wake(){
  // Wakes up
}

void changeBaudRate()
{
  Serial.begin(9600);
  Serial.print("+++");
  delay(2000);
  Serial.println("ATBD4");
  Serial.println("ATWR");
  Serial.println("ATCN");
  Serial.begin(19200);
}


void blinkLED(int targetPin, int numBlinks, int blinkInterval) {
   // this function blinks the an LED light as many times as requested
   for (int i=0; i<numBlinks; i++) {
    digitalWrite(targetPin, HIGH); // sets the LED on
    delay(blinkInterval); // waits for a second
    digitalWrite(targetPin, LOW); // sets the LED off
    delay(blinkInterval);
   }
}

void setup(){  
//  configureMe();
  LEDpin.number = 4;
  switchPin.number = 12;
  sleepPin.number = 2;
  wakePin.number = sleepPin.number;
  
  blinkLED(LEDpin.number, 3, 500);
  defineDefaultConfig();
  changeBaudRate();
  Serial.begin(19200);  //initialize the serial port
  timer2_init(); //initialize the timer we use to keep track of our delay
  findDongle();  //look for a dongle and send it my details so it can log me.
}


//returns the checksum of a string
byte calculate_checksum(char* message){
 byte chk = 0;
 for(int i = 0 ; i < strlen(message); ++i){
 chk += atoi((char*)message[i]);
 }
}

//broadcast yourself to the world, looking for a dongle to talk to.
void findDongle()
{
  boolean discovered=false;
  int count=0;
  byte data, checksum;
  checksum=0;
  while((count<3)&&(discovered==false))    //send a 'discover me' byte up to three times looking for a dongle
  {
    count++;
   Serial.print(DISCOVER); 
   delay(COMM_DELAY);
   if(Serial.available()>0)
   {
     data=Serial.read();
     if(data==DISCOVERY_RESPONSE);
       discovered=true;
   }
  }
   if(discovered==true)   //ok, the dongle is responding, so let's send it our configuration fields.
   {
     count=0;
     boolean data_sent=false;
     while((count<3)&&(data_sent==false))
     {
      count++;
      Serial.print(MESSAGE_START,BYTE);
      Serial.print(NAME);
      checksum+=calculate_checksum(NAME);
      Serial.print(',');
      Serial.print(config_fields[0]);
      checksum+=calculate_checksum(config_fields[0]);
      Serial.print(',');
      Serial.print(config_fields[1]);
      checksum+=calculate_checksum(config_fields[1]);
      Serial.print(',');
      Serial.print(config_fields[2]);
      checksum+=calculate_checksum(config_fields[2]);
      Serial.print(',');
      Serial.print(checksum,BYTE);
      Serial.print(MESSAGE_END,BYTE);
     }
      
   }
}


void broadcastValues()
{
  blinkLED(LEDpin.number, 2, 250);
  Serial.print(NAME);
  Serial.print(", ");
  printFloat(temp1);
  Serial.print(", degrees C, ");
  printFloat(temp2);
  Serial.print(", degrees C, ");
  Serial.print(chksum);  //the checksum is the sum of temp1 and temp2, cast as an int
  Serial.println();
}

void printFloat(float a)  //takes in a float and prints it out as a string to the serial port
{
  //cast the float as an int, truncating the precision to two decimal points
  int num = a*pow(10, digitsOfPrecision);
  
  Serial.print(float(num)/pow(10, digitsOfPrecision), DEC);
  Serial.print('.');
  
  //if num is negative, this can come out negative, too and that's an easy way to flip out some bits on the computer side 
  Serial.print(abs(num%10));
}


void updateValues()
{
    sensor1_top = analogRead(0);
    sensor1_bottom = analogRead(1);
    sensor2_top = analogRead(2);
    sensor2_bottom = analogRead(3);
  
    sensor1_top = float(sensor1_top);
    sensor1_bottom = float(sensor1_top);
    sensor2_top = float(sensor2_top);
    sensor2_bottom = float(sensor2_bottom);
  
    float sensor1_ratio = sensor1_top/sensor1_bottom;
    float sensor2_ratio = sensor2_top/sensor2_bottom;
 
    r1 = (sensor1_ratio - 1)*RBOTTOM;
    r2 = (sensor2_ratio - 1)*RBOTTOM;
  
    //temp1=r1;
    temp1 = R2T(r1);
    temp2 = R2T(r2);
    
    chksum = checksum(temp1, temp2);
}

int checksum(float t1, float t2){
  return (int)(t1+t2);
}

float R2T(float resistance){
 return float(B/log(resistance/(R0*exp(-1*B/T0))) - 273);
}

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
