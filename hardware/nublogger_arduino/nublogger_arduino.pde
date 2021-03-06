#include <EEPROM.h>
#include <avr/power.h>
#include <avr/sleep.h>
#include <string.h> 

#define NAME "gretchen"
#define ON 1
#define INITIALIZED 2
#define WHOAMI 3
#define WAITING_FOR_CONFIG 4
#define MESSAGE_START 5
#define MESSAGE_END 6

#define CHECKSUM_IDENTIFIER 7
#define NAME_IDENTIFIER 8
#define CONFIGURATION_IDENTIFIER 9
#define LOGGING_IDENTIFIER 10

/*#define MALFORMED_MESSAGE 101
#define MISSING_MESSAGE_START 102
#define MISSING_MESSAGE_END 103
#define TIMEOUT 104*/



//char** loggingLevels = {"INFO", "WARN", "ERROR", "CRITICAL"};

// Variables --------------------------------------------------
int sensor1_top, sensor1_bottom, sensor2_top, sensor2_bottom;  //the raw ADC values for the voltages on either side of the thermistor
float temp1, temp2;  //the temperature, in celsius, that the thermistor is measuring
float r1, r2;  //the resistance in ohms of the thermistors

int chksum;
int myDelay = 1000; //Default sample rate of 1Hz

//Temperature=B/ln(R/(R0*e^(-B/T0)))
float B = 3950;   //the beta value of the NTC thermistor--used to calculate temp from resistance
float T0 = 298.0;  //the T0 value of the thermistor--used to calculate temp from resistance
float R0 = 10000;  //the resistance at T0
float RTOP = 24000;
float RBOTTOM = 1000;

// Helper structures --------------------------------------------------
struct pin {
 int number;
};
pin LEDpin, switchPin, sleepPin, wakePin;

struct logMsg {
  char* logLevel;
  char* message;
};

int digitsOfPrecision = 2;  
int guardTime = 2000;
char* name;
float sampleInterval;
float sampleTime;
char* sensor1_unit, sensor2_unit;

// Helper functions --------------------------------------------------
/*boolean validLogLevel(char* logLevel){
  int numLevels = arrayLen(loggingLevels);
  for(int i = 0; i < numLevels; ++i){
    if (strstr(loggingLevels[i], logLevel)){
      return true;
    }
  }
  return false;
}

void log(char* logLevel, char* logMessage){
  boolean isValidLevel = validLogLevel(logLevel);
  if (isValidLevel == true) {
    char* toConcatenate[] = {logLevel, " ", logMessage};
    char* message = concat(toConcatenate);
    Serial.print(message);       
  }
}*/

int arrayLen(char* array[]){
 return sizeof(array)/sizeof(*array); 
}
int arrayLen(int* array[]){
 return sizeof(array)/sizeof(*array); 
}
int arrayLen(float* array[]){
 return sizeof(array)/sizeof(*array); 
}

char* concat(char** strings){
  int numStrings = arrayLen(strings);
  int numChars = 0;
  for(int i = 0; i < numStrings; ++i){
    numChars += strlen(strings[i]);
  }
  numChars += 1;
  
  char concatenatedString[numChars];
  
  int whichChar = 0;
  for(int i = 0; i < numStrings; ++i){
    int stringLength = strlen(strings[i]);
    for(int j = 0; j < stringLength; ++j){
      concatenatedString[whichChar] = strings[i][j]; 
      ++whichChar;
    }
  }
  
  return concatenatedString;
}


void initializePins(){
  pinMode(LEDpin.number, OUTPUT);
}

void configureMe(){
  sendMessage(CONFIGURATION_IDENTIFIER, "Looking for love, or configuration.");
}

char* listenFor(int msgID){
  
}

int listenFor(int msgID){
  
}

float listenFor(int msgID){
  
}
  
void sendMessage(int msgID, char* message) {
  XBee_wake();
  XBee_write(MESSAGE_START);
  XBee_write(msgID);
  XBee_write(message);
  XBee_write(MESSAGE_END);
  XBee_sleep();
}

void sendMessage(int msgID, int message) {
  XBee_wake();
  XBee_write(MESSAGE_START);
  XBee_write(msgID);
  XBee_write(message);
  XBee_write(MESSAGE_END);  
  XBee_sleep();
}

void sendMessage(int msgID, float message) {
  XBee_wake();
  XBee_write(MESSAGE_START);
  XBee_write(msgID);
  XBee_write(message);
  XBee_write(MESSAGE_END);
  XBee_sleep();
}

void initializeSensor(){
  XBee_write(ON);
  sendMessage(WHOAMI, NAME);
}

// XBee ----------------------------------------
void XBee_write(char byteToSend){
  Serial.print(byteToSend, DEC);
}

void XBee_write(char* message){
  int msgLength = strlen(message);
  for(int i = 0; i < msgLength; ++i){
    XBee_write(message[i]);
  }
}

void startMsg(){
  write(MESSAGE_START);
}
  
void endMsg(){
  XBee_write(MESSAGE_END);  
}

float checksum(char* msgToCheck){
  chksum = 0;
  for(int i = 0; i < strlen(msgToCheck); ++i){
      chksum += float(msgToCheck[i]);
  }
  
  return chksum;
}

boolean checkChecksum(int sample, int checksum) {
  if (sample == checksum){
   return true; 
  }
  else{
    return false;
  }
}

boolean checkReceived(char* compareAgainst){
char incomingChar[3];
  char okString[] = "OK";
  char result = 'n';

  int startTime = millis();
  while (millis() - startTime < 2000 && result == 'n') {
    if (Serial.available() > 1) {
      for (int i=0; i<3; i++) {
        incomingChar[i] = Serial.read();
      }
      if ( strstr(incomingChar, okString) != NULL ) {
          result = true;
        }  
        else {
          result = false;
        }
      }
    }
  return result;  
}

// Power management --------------------------------------------------
// XBee ----------------------------------------
void XBee_initalize(){
  Serial.print("X");
  delay(guardTime); 
}

void XBee_commandMode(){
  Serial.print("+++");
  delay(guardTime);
  if (XBee_commandReceived()){
    // Continue if command received
  }
  else{
    setup();
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


//Arduino ----------------------------------------
void Arduino_sleep(){
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);
  sleep_enable();
  attachInterrupt(0, Arduino_wake, LOW);
  sleep_mode();
  //Actually sleeps now
 
  sleep_disable();
  detachInterrupt(0);
}

void Arduino_wake(){
  // Wakes up
}

int Arduino_read(){
  int getByte;
  while (Serial.available() == 0){}
  getByte = Serial.read();
  
  return getByte;
}

char* whoami(){
  for(int i=0;i<255;i++)   //read in our unique name from EEPROM when we boot
    name[i] = EEPROM.read(i);
  if(name[254] != NULL){
    //log("ERROR", "Name not null-terminated."); 
  }
  
  return name;
}

void parseConfig(char* configStrings){
  int numConfigOptions = strlen(configStrings);
}

// Main program --------------------------------------------------
void setup()
{
  LEDpin.number = 13;
  switchPin.number = 12;
  sleepPin.number = 2;
  wakePin.number = sleepPin.number;
  
  blinkLED(LEDpin.number, 3, 500);
  
  name = whoami();
  
  Serial.begin(9600);  //initialize the serial port
  configureMe();
}

void loop()
{
  updateValues();
  broadcastValues();
  delay(myDelay);
}

float now(){
  return float(millis()/1000);  
}

void broadcastValues()
{
  blinkLED(LEDpin.number, 2, 250);
  Serial.print(name);
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

void blinkLED(int targetPin, int numBlinks, int blinkInterval) {
   // this function blinks the an LED light as many times as requested
   for (int i=0; i<numBlinks; i++) {
    digitalWrite(targetPin, HIGH); // sets the LED on
    delay(blinkInterval); // waits for a second
    digitalWrite(targetPin, LOW); // sets the LED off
    delay(blinkInterval);
   }
}
