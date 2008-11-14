#include <EEPROM.h>

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

void setup(){  
  blinkLED(ARDUINO_LED_PIN, 3, 500);
  initializeTiming();
  findDongle();  //look for a dongle and send it my details so it can log me.
}

void loop(){
  
}


void configureMe(){
  changeBaudRate(9600, 19200);
  defineDefaultConfig();
}

float resistanceToTemp(float resistance){
 return float(B/log(resistance/(R0*exp(-1*B/T0))) - 273);
}

float* updateValues()
{
  float[MY_NUM_SENSORS][2] sensorReadings;
  float[MY_NUM_SENSORS] sensorRatios, resistances, readings;

  for(int i = 0; i < 2*numSensors; i += 2){
    sensorReadings[i] = [flot(analogRead(i)), float(analogRead(i+1))];
    sensorRatios[i/2] = sensorReadings[i][0]/sensorReadings[i][1];
    resistances[i/2] = (sensorRatios[i/2] - 1)*RBOTTOM;
    readings[i/2] = resistanceToTemperature(resistances[i/2]);
  }    
  
  return readings;
}

void broadcastReadings(char** readings, char** units)
{
  if(len(readings) == len(units)){
    char* messageToBroadcast = "";
    for(int i = 0; i < len(readings) && i < len(units); ++i){
      messageToBroadcast += readings[i] + MESSAGE_DELIMITER + units[i] + MESSAGE_DELIMITER;
    }
    Serial.print(messageToBroadcast);
    Serial.println();
  }
}
