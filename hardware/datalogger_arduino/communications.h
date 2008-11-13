void transmitter_wake(){
  XBee_wake();
}

void transmitter_sleep(){
  XBee_sleep();
}

byte calculateChecksum(char* message){
 byte chk = 0;
 for(int i = 0 ; i < strlen(message); ++i){
   chk += atoi((char*)message[i]);
 }
}
