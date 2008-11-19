/*
@file datalogger_arduino.pde
@author alec resnick (alec@nublabs.org)
@date 18 November 2008
@desc Main Arduino file for the nub.datalogger project (datalogger.nublabs.org).
@site http://datalogger.nublabs.org
 */

#include <EEPROM.h> // Used to write to EEPROM

#include <avr/power.h> // Used for power management and sleep functions
#include <avr/sleep.h> // Used for power management and sleep functions
#include <avr/interrupt.h> // Used to implement an interrupt-based timer (timing.h)

#include <string.h> // Used for string manipulation  
#include <stdlib.h> // Used for string manipulation

#include "comm.h" // Defines communication functions and protocols
#include "arduino.h" // Defines Arduino specific configuration variables and functions
#include "XBee.h" // XBee communications module
#include "datalogger_config.h" // Defines datalogger configuration variables and functions
#include "timing.h" // Implements interrupt-based timing to address issues with Arduino's delay()
#include "helpers.h" // Helper functions
#include "logging.h" // Primitive logging system which sends log messages out over Serial

/*----------
@function:  setup
@parameters:  
 - none
@summary:  executed once
@todo:
* TODO Implement the autolocation of a dongle to listen to the datalogger
* TODO Implement global timestamps
 ----------*/
void setup(){  
  //initializeTiming();
  //findDongle();  //look for a dongle and send it my details so it can log me.
  delay(500);
Serial.begin(19200);
  logMsg("Starting up. . .", "INFO");

}


/*----------
@function:  loop
@parameters:  
 - none
@summary:  the global loop executed continuously in Arduino
@todo:
* TODO Implement auto-configuration
* TODO Implement time update
 ----------*/
void loop(){
  blinkLED(ARDUINO_LED_PIN, 3, 500); // Blinks the LED on the Arduino three times, spaced 500ms apart
  float* readings = updateValues(); // Updates sensor values
  char* units[] = {"degrees C"}; // Defines an array of unit strings for each sensors
  broadcastReadings(readings, units); // Broadcasts the readings and their units over Serial
  delay(MY_DELAY); // Waits for MY_DELAY milliseconds until the next reading. 
}


/*----------
@function:  resistanceToTemp
@parameters: 
 - resistance value as measured from the ADC [float]
@summary: Converts the measured resistance _resistance_ to a temperature in degrees Celsius using an equation from the [thermistor model name] datasheet.
@todo:
* TODO Document thermistor model name
 ----------*/
float resistanceToTemp(float resistance){
  float encodedTemp = float(B/log(resistance/(R0*exp(-1.0*B/T0))) - 273.0); // Temperature in degrees Celsius
  return encodedTemp;
}


/*----------
@function:  updateValues
@parameters: 
 - none
@summary: updates the global variables containing the temperature sensor readings with the most recent measurements
@todo:
* TODO Implement smoothing/averaging
* TODO Document which resistors on schematic top- and bottom- are
* TODO Document how and why the calculation of voltages, resistances, and temperatures works
 ----------*/
float* updateValues()
{
  logMsg("Updating sensor values . . .", "DEBUG");
  // MY_NUM_SENSORS is the number of sensors connected to the datalogger
  float* sensorReadings[MY_NUM_SENSORS];
  float sensorRatios[MY_NUM_SENSORS];

  float resistances[MY_NUM_SENSORS];
  float* readings;

  // Step through available sensors and record a top and bottom value for each
  for(int i = 0; i < 2*MY_NUM_SENSORS; i += 2){ //Loops through numSensors times
    float topResistorReading = (float)analogRead(i);
    float bottomResistorReading = (float)analogRead(i+1);
    float resistorReadings[] = { topResistorReading, bottomResistorReading };
    
    // ?
    sensorReadings[i/2] = resistorReadings;
    sensorRatios[i/2] = sensorReadings[i][0]/sensorReadings[i][1]; // Voltages computed
    resistances[i/2] = (sensorRatios[i/2] - 1)*RBOTTOM; // Voltages converted to resistances
    readings[i/2] = resistanceToTemp(resistances[i/2]); // Resistance values converted to temperature
  }    
  logMsg("Sensor values updated.", "DEBUG");
  
  return readings;
}


/*----------
@function:  broadcastReadings
@parameters:  
 - rawReadings is an array of float temperatures [float*]
 - units is an array of strings containing the units for each senors (indexed in the same order as rawReadings) [char**]
@summary: broadcastReadings is responsible for transmitting the readings and their units to the dongle attached to the computer.  It constructs a string of alternating readings and units, and then properly forms the message for transmission (with MESSAGE_START tags, message identifiers, checksum, etc.)
@todo:
* TODO 
 ----------*/
void broadcastReadings(float* rawReadings, char** units)
{
  logMsg("Broadcasting readings. . .", "INFO");
  //Requires an array of readings and an array of units which are the same length
  int readingsLength = sizeof(*rawReadings)/sizeof(rawReadings[0]);
  int unitsLength = sizeof(*units)/sizeof(units[0]);
  
  char* messageToBroadcast;
  if(readingsLength == unitsLength){
    for(int i = 0; i < readingsLength && i < unitsLength; ++i){
      //Append reading/unit pairs to the message (e.g. "20.7, degrees C")
      char* temp = floatToString(rawReadings[i]);
      char* toAdd[] = {floatToString(rawReadings[i]), MESSAGE_DELIMITER, units[i]};
      char* newMsg[] = {messageToBroadcast, concatStrings(toAdd, sizeof(toAdd)/sizeof(toAdd[0]))};
      //Combines strings constructed and appends to messageToBroadcast
      messageToBroadcast = concatStrings(newMsg, sizeof(newMsg)/sizeof(newMsg[0]));
    }

    //sendMessage takes the message and properly surrounds it with the checksum and necessary wireless handshaking
    sendMessage(messageToBroadcast, READING_IDENTIFIER); //READING_IDENTIFIER classifies the message (in this case, as a reading)
  }
  else{
    logMsg("Readings and units vectors different lengths; they need to be the same size.", "ERROR"); 
  }
}
