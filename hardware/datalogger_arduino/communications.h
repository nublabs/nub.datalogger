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
  byte* data;
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
  sendMessage(request, REQUEST_IDENTIFIER)
}

void sendMessage(char* message, int messageIdentifier){
  blinkLED(LEDpin.number, 2, 250);
  int checksum = calculateChecksum(messageIdentifier + message);
  char** toBroadcast = [[(char)MESSAGE_START], [(char)messageIdentifier], (char*)message, [(char)CHECKSUM_IDENTIFIER], [(char)checksum], [(char)MESSAGE_END]]
  
  char* messageToTransmit = ""
  for(int i = 0; i < len(toBroadcast); ++i){
    for(int j = 0; j < len(toBroadcast[i]); ++j){
      messageToTransmit += toBroadcast[i]
    }
    messageToTransmit += MESSAGE_DELIMITER
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
}
