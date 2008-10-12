#include <EEPROM.h>

char name[256];

int sensor1_top, sensor1_bottom, sensor2_top, sensor2_bottom;  //the raw ADC values for the voltages on either side of the thermistor
float temp1, temp2;  //the temperature, in celsius, that the thermistor is measuring
float r1, r2;  //the resistance in ohms of the thermistors
float B=3950;   //the beta value of the NTC thermistor--used to calculate temp from resistance
float T0=298.0;  //the T0 value of the thermistor--used to calculate temp from resistance
float R0=10000;  //the resistance at T0
float RTOP=24000;
float RBOTTOM=1000;
int checksum;
//Temperature=B/ln(R/(R0*e^(-B/T0)))




void setup()
{
  Serial.begin(9600);  //initialize the serial port
  for(int i=0;i<255;i++)   //read in our unique name from EEPROM when we boot
    name[i]=EEPROM.read(i);
  //I should check to make sure I read in a proper, null-terminated string, and throw an error
  //or come up with a randomly generated string if that's not the case;
}

void updateValues();
void sendValues();
void printFloat(float a);

void loop()
{
  updateValues();
  sendValues();
//   delay(1000);  
}

void sendValues()
{
  Serial.print(name);
   Serial.print(", ");
   printFloat(temp1);
   Serial.print(" degrees C");
   Serial.print(',');
   printFloat(temp2);
   Serial.print(" degrees C");
   Serial.print(',');
   Serial.print(checksum);  //the checksum is the sum of temp1 and temp2, cast as an int
                            //this might somehow (although I don't see it happening) make trouble,
                            //since the logging side is receiving a truncated version of temp1 and temp2
   Serial.println();
/*   Serial.print(analogRead(0));
   Serial.print(" ");
   Serial.print(analogRead(1));
   Serial.print(" ");
   Serial.print(analogRead(2));
   Serial.print(" ");
   Serial.print(analogRead(3));
   Serial.print(" ");
   Serial.println();*/
   

}

void printFloat(float a)  //takes in a float and prints it out as a string to the serial port
{
  int num=a*10;  //cast the float as an int, truncating the precision to one decimal point
  Serial.print(num/10);
  Serial.print('.');
  Serial.print(abs(num%10));   //if num is negative, this can come out negative, too and that's an easy way to flip out some bits on the computer side
  
}

void updateValues()
{
    sensor1_top=analogRead(0);
    sensor1_bottom=analogRead(1);
    sensor2_top=analogRead(2);
    sensor2_bottom=analogRead(3);
    r1=((float)sensor1_top/(float)sensor1_bottom)*RBOTTOM*(1-((float)sensor1_bottom/(float)sensor1_top));
    r2=((float)sensor2_top/(float)sensor2_bottom)*RBOTTOM*(1-((float)sensor2_bottom/(float)sensor2_top));
    //temp1=r1;
    temp1=B/log(r1/(R0*exp(-1*B/T0)));
    temp1-=273;
    temp2=B/log(r2/(R0*exp(-1*B/T0)));
    temp2-=273;
    checksum=temp1+temp2;
    
}
