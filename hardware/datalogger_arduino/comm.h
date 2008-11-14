//Protocol (0-25)
#define MESSAGE_START 0
#define MESSAGE_END 1
#define MESSAGE_DELIMITER ","

//Messages from dongle
#define OK 2
#define DISCOVERY_CONFIRMED

//States (51-100)
#define TURNING_ON 50
#define INITIALIZED 51
#define WAITING_FOR_CONFIG 52
#define CONFIGURED 53
#define SAMPLING 54
#define TURNING_OFF 55
#define BROKEN 56

//Message IDs (101 - 150)
#define WHOAMI_IDENTIFIER 101
#define CHECKSUM_IDENTIFIER 102
#define CONFIGURATION_IDENTIFIER 103
#define LOGGING_IDENTIFIER 104
#define REQUEST_IDENTIFIER 105

//Error Messages (151 - 200)
#define MALFORMED_MESSAGE_ERROR 101
#define MISSING_MESSAGE_START_ERROR 102
#define MISSING_MESSAGE_END_ERROR 103
#define TIMEOUT_ERROR 104
#define WRONG_CHECKSUM_ERROR 105
#define NO_DATA_ERROR 106

//Request messages (201 - 250)
#define PLEASE_RESEND 151
#define PLEASE_CONFIGURE_ME 152
#define PLEASE_DISCOVER_ME 153

//Commands (251 - 300)
#define WAIT_FOR_CONFIGURATION 201
#define RESEND_MESSAGE 202
#define SLEEP 203
#define WAKE 204

//
#include "XBee.h"
#include "arduino.h"
#include "datalogger_config.h"
//

void transmitter_wake(){
  XBee_wake();
}

void transmitter_sleep(){
  XBee_sleep();
}

void timeout(){
  sendMessage(TIMEOUT_ERROR);
}


char* receiveMsg(){
  char* data;
  int index = 0;
  while(Serial.available() > 0){
    data[index] = Serial.read();
    ++index;
  }
  return data;
}

boolean receivedMsg(char* msg){
  int startTime = millis();
  while(millis() - startTime > MY_TIMEOUT ){
      char* messge = receiveMsg();
      if (strstr(message, msg) == NULL) {
        return false;
      }
      else {
        return true;
      }
    }
  timeout();
  return false;  
}

void request(char* request){
  sendMessage(request, REQUEST_IDENTIFIER);
}

void sendMessage(char* message, int messageIdentifier){
  blinkLED(ARDUINO_LED_PIN, 2, 250);
  int checksum = calculateChecksum(messageIdentifier + message);
  char[][] toBroadcast = [[(char)MESSAGE_START], [(char)messageIdentifier], (char*)message, [(char)CHECKSUM_IDENTIFIER], [(char)checksum], [(char)MESSAGE_END]];
  char* messageToTransmit = "";
  for(int i = 0; i < strlen(toBroadcast); ++i){
    for(int j = 0; j < strlen(toBroadcast[i]); ++j){
      messageToTransmit += toBroadcast[i];
    }
    messageToTransmit += MESSAGE_DELIMITER;
  }
}

boolean findDongle(){
  boolean foundDongle = false;
  int startTime = millis();
 
  while(millis() - startTime < MY_TIMEOUT && foundDongle == false){
    request((char)PLEASE_DISCOVER_ME);
    delay(MY_COMM_DELAY);
    if(receivedMessage(DISCOVERY_CONFIRMED){
     return true; 
    }
  }
  return false;
}

byte calculateChecksum(char* message){
  byte chk = 0;
  for(int i = 0 ; i < strlen(message); ++i){
    chk += atoi((char*)message[i]);
  }
  
  return chk;
}
