#include "EEPROM.h"

#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/interrupt.h>

#include <string.h> 
#include <stdlib.h>

#include "comm.h"
#include "arduino.h"
#include "XBee.h"
#include "datalogger_config.h"
#include "timing.h"
#include "helpers.h"

void setup(){  
  blinkLED(13, 3, 500);
  initializeTiming();
  findDongle();  //look for a dongle and send it my details so it can log me.
}

void loop(){
  
}

//Get configuration and apply configuration to datalogger
void configureMe(){
  XBee_changeBaudRate(9600, 19200);
  //defineDefaultConfig();
}

//Convert resistance to temperature, per details of thermistor TODO: document thermistor model
float resistanceToTemp(float resistance){
 return float(B/log(resistance/(R0*exp(-1*B/T0))) - 273);
}

//Updates readings
float* updateValues()
{
  float* sensorReadings[MY_NUM_SENSORS];
  float sensorRatios[MY_NUM_SENSORS], resistances[MY_NUM_SENSORS], readings[MY_NUM_SENSORS];

  // Step through available sensors and record a top and bottom value for each
  for(int i = 0; i < 2*MY_NUM_SENSORS; i += 2){
    //Steps through numSensors times
    float topReading = (float)analogRead(i);
    float bottomReading = (float)analogRead(i+1);
    float topBottom[] = {topReading, bottomReading};
    sensorReadings[i] = topBottom;
    sensorRatios[i/2] = sensorReadings[i][0]/sensorReadings[i][1];
    resistances[i/2] = (sensorRatios[i/2] - 1)*RBOTTOM;
    readings[i/2] = resistanceToTemp(resistances[i/2]);
  }    
  
  return readings;
}

//Broadcasts readings
void broadcastReadings(char** readings, char** units)
{
  //Requires an array of readings and an array of units
  int readingsLength = sizeof(readings)/sizeof(readings[0]);
  int unitsLength = sizeof(units)/sizeof(units[0]);
  if(readingsLength == unitsLength){
    char* messageToBroadcast = "";
    for(int i = 0; i < readingsLength && i < unitsLength; ++i){
      //Put reading/unit pairs into message
      char* toAdd[] = {readings[i], MESSAGE_DELIMITER, units[i], MESSAGE_DELIMITER};
      strcat(messageToBroadcast, concatStrings(toAdd));
    }
    Serial.print(messageToBroadcast);
    Serial.println();
  }
}
