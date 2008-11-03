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


//States
#define TURNING_ON 0
#define INITIALIZED 1
#define WAITING_FOR_CONFIG 3
#define CONFIGURED 4
#define SAMPLING 5
#define TURNING_OFF 6
#define BROKEN 7

//Message IDs
#define WHOAMI_IDENTIFIER 10
#define CHECKSUM_IDENTIFIER 11
#define NAME_IDENTIFIER 12
#define CONFIGURATION_IDENTIFIER 13
#define LOGGING_IDENTIFIER 14
#define MESSAGE_START 15
#define MESSAGE_END 16

//Error Messages
#define MALFORMED_MESSAGE 101
#define MISSING_MESSAGE_START 102
#define MISSING_MESSAGE_END 103
#define TIMEOUT 104

#include "WProgram.h"
void defineDefaultConfig();
void timer2_init();
void timer2_start();
void timer2_stop();
void Arduino_sleep();
void Arduino_wake();
void blinkLED(int targetPin, int numBlinks, int blinkInterval);
void setup();
void broadcastValues();
void printFloat(float a);
void updateValues();
int checksum(float t1, float t2);
float R2T(float resistance);
void checkConfig();
void loop();
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
/*
int defineReceivedConfig(char** receivedConfigFields, int* receivedConfigVals){
  int numFieldsToConfigure = -1;
  
  if (arrayLen(receivedConfigFields) == arrayLen(receivedConfigVals)){
    numFieldsToConfigure = arrayLen(receivedConfigFields);
    return 1
  }
  else{
    return 0; 
  }
  
  for(int i = 0; i < numFieldsToConfigure; ++i){
   writeConfigField(receivedConfiguration, receivedConfigFields[i], receivedConfigVals[i]); 
  }
}



int readConfigField(configuration config, char* whichField){
  int numFields = arrayLen(configuration.fields);
  for(int i = 0; i < numFields; ++i){
   if (config.fields[i] == whichField){
     return config.fields[i];
   }
  }
}

int writeConfigField(configuration config, char* whichField, int newValue){
  int numFields = arrayLen(configuration.fields);
  for(int i = 0; i < numFields; ++i){
   if (config.fields[i] == whichField){
     config.fields[i] = newValue;
     return config.fields[i];

   
  }
}

*/
struct pin {
 int number;
};
pin LEDpin, switchPin, sleepPin, wakePin;
/*
//Communications

int checksum(char* message){
  int chk = 0;
  for(int i = 0 ; i < strlen(message); ++i){
    chk += atoi((char*)message[i]);
  }
  
  return chk;
}

char* askFor(int valueID){
  sendMessage(valueID, "Gimme some love!");
  listenFor(valueID);
}

char* listenFor(int valueID){
  int incoming;
  
  int start = millis();
  char* message, stringBuffer;
  
  boolean recording = false;
  while(timeElapsedSince(start) < 2000 && recording == false){
    if (Serial.available() > 1){
      incoming = Serial.read();
      if (incoming == MESSAGE_START) {
        recording = true;
        while(recording == true){
          if (Serial.available() > 1) {
            incoming = Serial.read();
            if (incoming == MESSAGE_END){
             recording = false;
            }
            else{
              strcat(message, itoa(incoming, (char*)stringBuffer, 10));
            }
          }
          else {
           recording = false;
          }
      }
    }  
    }
  }
 return message; 
}

int timeElapsedSince(int startTime){
  return millis() - startTime;
}

void sendMessage(int msgID, char* message){
  XBee_wake();
  XBee_writeByte(MESSAGE_START);
  XBee_writeByte(msgID);
  XBee_writeStr(message);
  char* stringBuffer;
  XBee_writeByte(checksum(strcat(itoa(msgID, stringBuffer, 10), message)));  
  XBee_writeByte(MESSAGE_END);
}

void XBee_writeByte(char byteToSend){
  Serial.print(byteToSend, DEC); 
}

void XBee_writeStr(char* message){
  int msgLength = strlen(message);
  for(int i = 0; i < msgLength; ++i){
    XBee_writeByte(message[i]);
  } 
}

void XBee_wake(){
  digitalWrite(sleepPin.number, LOW);
  delay(15);
}

void XBee_sleep(){
  pinMode(sleepPin.number, OUTPUT);
  digitalWrite(sleepPin.number, HIGH);
  delay(1000);  
}
*/

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
  LEDpin.number = 13;
  switchPin.number = 12;
  sleepPin.number = 2;
  wakePin.number = sleepPin.number;
  
  blinkLED(LEDpin.number, 3, 500);
  defineDefaultConfig();
  Serial.begin(9600);  //initialize the serial port
  timer2_init(); //initialize the timer we use to keep track of our delay
}
/*
float now(){
  return float(millis()/1000);  
}
*/
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

void checkConfig()
{
}

void loop(){
   updateValues();
   broadcastValues();
   checkConfig();
   int i;
    delay(config_values[0]);  //delay in milliseconds
  
 // if (sensingDone()){
   //powerDown();
  //}
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

