#include "interupt_timing.h"

void setup(){  
  blinkLED(LEDpin.number, 3, 500);
  timer2_init(); //initialize the timer we use to keep track of our delay
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

int* updateValues()
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
    
    return [temp1, temp2];
}

void broadcastReadings(char** readings, char** units)
{
  if(len(readings) == len(units)){
    for(int i = 0; i < len(readings) && i < len(units); ++i){
      
      sendMessage(readings[i], DEL
    }
  }
  Serial.print(NAME);
  Serial.print(", ");
  printFloat(temp1);
  Serial.print(", degrees C, ");
  printFloat(temp2);
  Serial.print(", degrees C, ");
  Serial.print(chksum);  //the checksum is the sum of temp1 and temp2, cast as an int
  Serial.println();
}
