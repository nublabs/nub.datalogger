#include "XBee_config.h"
#include "wiring_serial.c"

void XBee_wake(){
  digitalWrite(XBEE_SLEEP_PIN, LOW);
  delay(XBEE_COMM_DELAY);
}

void XBee_sleep(){
  pinMode(XBEE_SLEEP_PIN, OUTPUT);
  digitalWrite(XBEE_SLEEP_PIN, HIGH);
  delay(XBEE_COMM_DELAY);  
}

//Reconfigures baudRate
//TODO: add error handling
void XBee_changeBaudRate(int currentBaudRate, int finalBaudRate)
{
  Serial.begin(currentBaudRate);
  delay(XBEE_GUARD_TIME);
  //Enter command mode
  Serial.print("+++");
  delay(XBEE_COMM_DELAY);
  char* finalBaudRateParameter = itoa(XBee_getBaudRateParameter(finalBaudRate)); 
  //Change the baud rate
  Serial.println("ATBD" + finalBaudRateParameter);
  //TODO: document this
  Serial.println("ATWR");
  //Exit command mode
  Serial.println("ATCN");
  Serial.begin(finalBaudRate);
}

// The XBee Maxstream has set values which you append to AT commands to choose baud rates
// This returns the appropriate index to append to the AT command to change the baud rate
int XBee_getBaudRateParameter(int baudRate){
  //Available baudRates
  int* baudRates = [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200];
  
  int numBaudRates = sizeof(baudRates)/sizeof(baudRates[0]);
  for(int i = 0; i < numBaudRates; ++i){
   if(baudRates[i] == baudRate){
    return i;
   } 
  }
  
  //If baudRate chosen is not available
  return -1;
}
