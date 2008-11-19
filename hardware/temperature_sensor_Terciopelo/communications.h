#include <HardwareSerial.h>   //if you're not in the main sketch, you have to include this to let you use Serial functions
#include <string.h>

int getByte(int timeout)
{
  int currentTime=millis();
  int maxTime=currentTime+timeout;
  while((Serial.available()==0)&&(millis()<(maxTime)))
    {}
  if((millis()>maxTime)||(Serial.available()==0))
    return -1;
  else
    return Serial.read();
}
