#include <EEPROM.h>
#include <avr/power.h>
#include <avr/sleep.h>
#include <string.h> 
#include <stdlib.h>

#define NAME "gretchen"

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

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/*
// Configuration
struct configuration {
  char* name;
  char** fields = {};
  int[] values = {};
};

configuration defaultConfig, receivedConfig;

void defineDefaultConfig(){
  defaultConfig.name = "default";
  defaultConfig.fields = {"delay", "numSamples", "timeToRun"};
  defaultConfig.values[0] = 1000;
  defaultConfig.values[1] = -1;
  defaultConfig.values[2] = -1;  
  receivedConfig = defaultConfig;
}


configuration defineReceivedConfig(char** receivedConfigFields, int[] receivedConfigVals){
  int numFieldsToConfigure = -1;
  
  if (arrayLen(receivedConfigFields) == arrayLen(receivedConfigVals)){
    numFieldsToConfigure = arrayLen(receivedConfigFields);
  }
  else{
    return defaultConfiguration;
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
}
*/

struct pin {
 int number;
};
pin LEDpin, switchPin, sleepPin, wakePin;

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
  
  Serial.begin(9600);  //initialize the serial port
}

float now(){
  return float(millis()/1000);  
}

int[] broadcastValues()
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
    
//    chksum = checksum(temp1, temp2);
}

/*float checksum(float t1, float t2){
  return t+t2;
}*/

float R2T(float resistance){
 return float(B/log(resistance/(R0*exp(-1*B/T0))) - 273);
}

void loop(){
  updateValues();
  broadcastValues();
  checkConfig();
  //delay(receivedConfig.values[0]);
  
  /*if sensingDone(){
   powerDown();
  }*/
}
