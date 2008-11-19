/*
@file XBee.h
@author alec resnick (alec@nublabs.org)
@date 18 November 2008
@desc Wrapper around XBee hardware functions
@site http://datalogger.nublabs.org
 */

#ifndef XBEE_H
#define XBEE_H
#include "XBee_config.h" // Configuration variables for the XBee transmitter
#include "HardwareSerial.h" // Makes available Serial communications outside of the main Arduino sketch
#include "logging.h" // Implements primitive logging over the Serial channel
#include "wiring.h" // Implements digitalWrite and digitalRead
#undef round // An alternative to round is defined in wiring.h, this was conflicting with avr-libc's math.h andneeded to be un-defined
#include "math.h"


/*----------
@function:  XBee_initialize()
@parameters: 
 - none
@summary:  Sets XBee sleep pin mode, gets XBee ready for transmission
@todo:
* TODO 
 ----------*/
void XBee_initialize(){
  pinMode(XBEE_SLEEP_PIN, OUTPUT);  
}


/*----------
@function:  XBee_wake()
@parameters: 
 - none
@summary:  Sets XBee sleep pin mode, gets XBee ready for transmission
@todo:
* TODO 
 ----------*/
void XBee_wake(){
  digitalWrite(XBEE_SLEEP_PIN, LOW);
  delay(XBEE_COMM_DELAY);
}

void XBee_sleep(){
  pinMode(XBEE_SLEEP_PIN, OUTPUT);
  digitalWrite(XBEE_SLEEP_PIN, HIGH);
  delay(XBEE_COMM_DELAY);  
}

// The XBee has set values which you append to AT commands to choose baud rates
// This returns the appropriate index to append to the AT command to change the baud rate
int XBee_getBaudRateParameter(int baudRate){
  logMsg("Calculating baud rate parameter. . .", "DEBUG");
  //Baudrates available in the XBee.  Position in the array determines the parameter 
  int baudRates[] = {1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200};
  int numBaudRates = sizeof(baudRates)/sizeof(baudRates[0]);

  // Search through the baud rates array for desired baudRate
  for(int i = 0; i < numBaudRates; ++i){
   if(baudRates[i] == baudRate){
    return i;
   } 
  }
  
  //If baudRate chosen is not available
  return -1;
}

/*----------
@function:  XBee_changeBaudRate()
@parameters: 
 - none
@summary:  resets the baud rate of the XBee transmitter
@todo:
 ----------*/
void XBee_changeBaudRate(int currentBaudRate, int finalBaudRate) {
  logMsg("Changing XBee baud rate. . .", "DEBUG");
  Serial.begin(currentBaudRate);
  delay(XBEE_GUARD_TIME);
  //Enter command mode
  Serial.print("+++");
  delay(XBEE_COMM_DELAY);
  char* finalBaudRateParameter;
  finalBaudRateParameter = itoa(XBee_getBaudRateParameter(finalBaudRate), finalBaudRateParameter, 10); 
  //Change the baud rate
  //itoa returns a char* but we know we're only expecting one char, and we need a char, so we use finalBaudRateParameter[0]
  char baudRateChangeCmd[] = {'A', 'T', 'B', 'D', finalBaudRateParameter[0]};
  Serial.println(baudRateChangeCmd);
  //TODO: document this
  Serial.println("ATWR");
  //Exit command mode
  Serial.println("ATCN");
  Serial.begin(finalBaudRate);
  logMsg("XBee baud rate changed.", "DEBUG");
}

#endif
