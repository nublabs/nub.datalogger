
/**
 * nublogger temperature sensor Terciopelo(+)
 * 
 * Alex Hornstein      11.19.08
 * alex@nublabs.com
 * datalogger.nublabs.com
 *
 * (+)In keeping with the arduino nomenclature, we are naming all our code revisions
 * with Spanish names of venemous snakes.  
 * The Terciopelo, or fer-de-lance is a pit viper common in central and northwestern south america.
 * It has a powerful venom that, left untreated, can cause necrosis, brain hemorrhaging, renal failure and death.  
 * It's also capable of spraying venom through its fangs for up to 6 feet.  Cool, huh?
 * 
 */

/**
 * This is a sensor for  nublab's datalogging system.  The datalogger is a two-part system:  There is a USB dongle that plugs
 * into a computer that allows the computer to talk to a wireless Zigbee network, and then there are battery-powered sensors that 
 * sense data about the environemnt.  The sensors collect data and convert it into human-readable units, and then send the data
 * as plaintext over the wireless network to the computer, where it is stored and logged.  Any sensor that will work with this system
 * must implement the discover(), configure() and sample() functions, as well as be identifiable by a unique name
 *  
 * The discover() function is a short communication sequence when the sensor is first turned on where it broadcasts its name over the
 * network and ensures that the computer recognizes it and is ready to configure it and log its data.  The sensor also sends the units
 * of whatever value it will be reporting.
 * 
 * the configure() function is triggered by a flag sent by the computer that indicates that the computer would like to change the 
 * datalogger's sample rate.  configure() is another communication sequence in which the computer sends a sample interval in hours, 
 * minutes and seconds to the datalogger.  By default, the datalogger samples every second.
 * 
 * the sample() function is called by the sensor every sample interval.  sample() reads a value from whatever sensing element 
 * (Thermistor, current sensor, light sensor, etc) the particular sensor uses, converts it to physical units (degrees celsius, amps,
 * lux, etc) and sends out a string over the wireless network with the sensor's unique name and its sensed values.
 * 
 * the name:  each sensor should have a unique name burnt into its eeprom that makes it uniquely identifiable in the network.  
 * Nublabs is using a list of north and south american baby names which is available at datalogger.nublabs.com
 * 
 */

/**
 * This particular sensor is a temperature sensor using an NTC thermistor.  The thermistor is a resistive element.
 * We sense it using two resistor dividers--one resistor, R1 which connects from Vcc to the thermistor, and another resistor
 * that connects from the other end of the thermistor to ground.  We measure the voltage at both ends of the thermistor using
 * separate Analog to Digital Converter (ADC) pins.  This allows us to factor out any effect changing battery voltage has on 
 * our temperature measurement.
 * This code is written for version 2 of the sensor hardware.  A pdf of the sensor schematic and board layout is available at 
 * datalogger.nublabs.com
 * 
 */

#include "name.h"                          //this file stores the sensor's name.  This is intended to be easily replaced as we 
                                           //program lots of sensors

#include "globals.h"                       //this file has all my global variables, such as the temperature value, my delay, and flags
                                           //that keep track of whether or not I've been discovered/configured/etc

//#include "temperature_sensor_board_v2.h"   //this file has pin definitions specific to the version 2 circuit board
                                             //if you're using a board that's wired up differently, you'll need to change this file

#include "communications_definitions.h"    //this file has definitions for message bytes sent between the computer and the sensor

//#include "nublogger.h"                     //this file contains the discover() and configure() functions that are shared across all
                                             //sensors that work with the nublabs datalogging system

//#include "communications.h"                //this file contains functions that make serial communication easier

#include <stdio.h>

//sleep.h and wdt.h contain power-saving and sleep functions I use to put the arduino in power-efficient delays between samples
#include <avr/sleep.h>
#include <avr/wdt.h>

//these are useful bitwise definitions.  I only use them in setting up the watchdog timer, and I'd like to get rid of them and 
//replace them with more arduino-friendly functions eventually.
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

#include "WProgram.h"
void setup();
void loop();
void sample();
int getByte(int timeout);
int getMessage(int timeout);
void sendData();
unsigned char getChecksum();
void configure();
void discover();
void initializeSensor();
void xbeeSleep();
void xbeeWake();
void getTemperatures();
void getRawData();
void convertToResistance();
void convertToTemperature();
void lowPowerOperation();
void system_sleep();
void setupWatchdog(int time);
void waitForSampleInterval();
void setup()
{
  Serial.begin(19200);
  lowPowerOperation();   //turns off all unnecessary modules in the microcontroller to save power
  initializeSensor();
 // discover();     //I'm getting rid of discovery--the computer can just see when it gets a new name coming in
}

void loop()
{
  waitForSampleInterval();
  sample();
}

void sample()
{
  getRawData();
  convertToResistance();
  convertToTemperature();
  sendData();
  sampleNumber++;
}


//communications.h
int getByte(int timeout)
{
  //all variables that deal with millis() should either be unsigned longs, or millis() should be cast as the variable it's going into.  There's a memory leak
  //if you don't do this
  unsigned long currentTime=millis();
  unsigned long maxTime=currentTime+timeout;
  while((Serial.available()==0)&&(millis()<(maxTime)))
  {
  }
  if(Serial.available()>0)        //did any data come in on the serial port?
    return Serial.read();
  else                             //we didn't get any data before the timeout
  return -1;
}

int getMessage(int timeout)
{
  int completeMessage=-1;   //a flag that lets us know if we got a full message
  start=0;              //drop whatever other data is in our buffer--it'll probably just confuse the functions if we don't
  index=0;              //set these to 0 so we don't run into any overrun bugs when they hit 255.  I think the unsigned char
                        //structure will take care (haha--"char") of it, but why push it?
  //all variables that deal with millis() should either be unsigned longs, or millis() should be cast as the variable it's going into.  There's a memory leak
  //if you don't do this
  unsigned long currentTime=millis();
  unsigned long maxTime=currentTime+timeout;  
  while((millis()<(maxTime))&&(completeMessage==-1))
  {
    if(Serial.available()>0)
    {
      buffer[index]=Serial.read();
/*      Serial.print(index,DEC);
      Serial.print(" ");
      Serial.print(buffer[index],DEC);
      Serial.println();*/
      if(buffer[index]==MESSAGE_END)   //we got a complete message
        completeMessage=1;
      index++;
    }
  }
  if(completeMessage==-1)    //we never got a complete message
    start=index;    //skip past whatever we got from the buffer

  return completeMessage;
}


//!this function takes care of putting together a message string, calculating a checksum, sending it out to the computer and making sure the computer got it ok
void sendData()
{
  char tries=0;
  char success=FALSE;
  int sensor1_temperature_decimals=(sensor1_temperature-(int)sensor1_temperature)*100;    //sprintf doesn't work for floats, so this hack gets 2 sigfigs
  int response=0;
 // sprintf(message,"%d", sampleNumber);
  sprintf(message, ",%s,%d.%d,degrees C,", name,(int)sensor1_temperature, sensor1_temperature_decimals);
//sprintf(message,"%d %d %d", (int) sensor1_temperature, (int) sensor1_resistance, sensor1_temperature_decimals);
  unsigned char checksum=getChecksum();
  while((success==FALSE)&&(tries<NUM_TRIES))
  {
    Serial.print(MESSAGE_START,DEC);
    Serial.print(message);
    Serial.print(checksum,DEC);
    Serial.print(',');
    Serial.print(MESSAGE_END,DEC);
    Serial.println();
    response=getByte(TIMEOUT);   //look for the computer's response

    if(response==ACKNOWLEDGE)   //the computer got the data.  It's happy, we're happy, we're done!
      success=TRUE;

    else if(response==ACKNOWLEDGE_AND_CONFIGURE)  //the computer can ask to upload a new configuration at any sample
    {
      success=TRUE;
      configure();
    }
    else         //if there was a timeout or a checksum mismatch, then re-try
    tries++;
  }

}

//!this computes a checksum of the global string 'message'
unsigned char getChecksum()
{
  char i=0;
  unsigned char checksum=0;
  while(message[i]!=0)
  {
    if(message[i]!=DELIMITER)   //don't add the delimiters (like commas) into the checksum
      checksum+=message[i];
    i++;
  }
  return checksum;
}


//nublogger.h
//!  configure() runs if the computer is trying to change the sensor's sample rate
/**
 * In configure(), the datalogger sends a LISTENING message to the computer, indicating that it's ready to receive data.
 * The computer sends three ints:  the hours, minutes and seconds of the sample interval, followed by a checksum byte that's the sum 
 * of the ints modulo 256.  The sensor computes a checksum on the received data.  If its checksum matches, it sends an 
 * ACKNOWLEDGE message back to the computer and updates its sample interval information.  If the checksum does not match, it sends 
 * a CHECKSUM_ERROR_PLEASE_RESEND message, asking the computer to send the three ints again, followed by a checksum.  If the 
 * sensor can't get a valid message (with a matching checksum) after three tries, it gives up, sends a CHECKSUM_ERROR_GIVING_UP 
 * message to the computer and keeps its original sample interval information
 */
void configure()
{ 
  char i=0;
  char tries=0;
  char success=0;
  unsigned char checksum=0;
  int error;

  while((tries<NUM_TRIES)&&(success==0))     //we'll try
  {
    checksum=0;
    Serial.println(LISTENING,DEC);
    error=getMessage(TIMEOUT);
    if(error==-1)
    {
      Serial.println(TIMEOUT_ERROR,DEC);
      tries++;
    }
    else
    {
      if(buffer[start]==MESSAGE_START)
      {
        if((index-start)==CONFIGURATION_MESSAGE_LENGTH)    //check to make sure the message is the size we expect
        {
          for(i=1;i<CHECKSUM;i++)
            checksum+=buffer[start+i];
          if(checksum==buffer[start+CHECKSUM])    //check to see if the calculated checksum is the same as the received checksum
          {

            Serial.println(ACKNOWLEDGE,DEC);   //do this first so the timeout can be shorter
            delay(1);  //wait a sec for the data to get out, since it's giving me drama
            //if it is, then we can load all the sample interval info
            hours=(int)buffer[start+HOUR_HIGH]*256+(int)buffer[start+HOUR_LOW];
            minutes=(int)buffer[start+MINUTE_HIGH]*256+(int)buffer[start+MINUTE_LOW];
            seconds=(int)buffer[start+SECOND_HIGH]*256+(int)buffer[start+SECOND_LOW];
            success=1;         //we can stop looping
            configured=1;      //the sensor is configured!
           
/*            Serial.println(hours);
            Serial.println(minutes);
            Serial.println(seconds);
*/
          }
          else
          {
            if(tries<NUM_TRIES)
            {
              Serial.println(CHECKSUM_ERROR_PLEASE_RESEND,DEC);
              tries++;
            }
            else
              Serial.println(CHECKSUM_ERROR_GIVING_UP,DEC);
          }
        }
        else      //the message is the wrong size
        {
          if(tries<NUM_TRIES)
          {
            Serial.println(MALFORMED_MESSAGE_ERROR_PLEASE_RESEND,DEC);
            tries++;
          }
          else
            Serial.println(MALFORMED_MESSAGE_ERROR_GIVING_UP,DEC);
        }
      }
      else
      {
        if(tries<NUM_TRIES)
        {
          Serial.println(MALFORMED_MESSAGE_ERROR_PLEASE_RESEND,DEC);
          tries++;
        }
        else
          Serial.println(MALFORMED_MESSAGE_ERROR_GIVING_UP,DEC);
      }
    }
  }
}


//!  This function tells the computer of the datalogger's existence
/**
 * When the sensor turns on, it runs discover().  It sends a MESSAGE_START message, a DISCOVER_ME message, and its name out to the 
 * computer and waits for acknowledgement.  The computer can send back a plain "ACKNOWLEDGE" message, which means that the sensor 
 * should run using its default configuration values.  The computer can also send back an "ACKNOWLEDGE_AND_CONFIGURE" message, which 
 * means that it has configuration data for the sensor.  If the sensor gets this message, it'll run configure() to receive the data 
 * from the computer.
 */
void discover()
{ 
  unsigned char checksum=0;
  int i=0;
  Serial.print(MESSAGE_START, BYTE);
  Serial.print(DISCOVER_ME,BYTE);
  Serial.print(name);
  while(name[i]!=0)
  {
    checksum+=name[i];
    i++;
  }
  checksum+=DISCOVER_ME;
  Serial.print(checksum,BYTE);
  Serial.print(MESSAGE_END,BYTE);

  int receivedByte=getByte(TIMEOUT);     //looks for a byte on the serial port with a 100ms timeout
  if(receivedByte==ACKNOWLEDGE)
    discovered=TRUE;
  if(receivedByte==ACKNOWLEDGE_AND_CONFIGURE)
  {
    discovered=TRUE;
    configure();
  }
  if(receivedByte==-1)
  {
    Serial.print(TIMEOUT_ERROR,BYTE);  //getByte didn't get a byte before the timeout
  }  
}



//temperature_sensor_board_v2.h
/**
 * these are the pin definitions for the v2 board
 * 
 * function      atmega pin    arduino pin
 * 
 * Serial RX        PD0             0    //serial lines that go out to the xbee module
 * Serial TX        PD1             1
 * Xbee_sleep       PD2             2    //a pin that, when asserted, puts the xbee radio into a low power sleep mode
 * Sample_button    PD3             3    //an optional button that forces the sensor to take and send out a measurement
 * LED              PD4             4    //an LED on board that you can use for all kinds of stuff
 * 
 * sensor1_top      PC0             (analog) 0    
 * sensor1_bottom   PC1             (analog) 1
 * sensor2_top      PC2             (analog) 2
 * sensor2_bottom   PC3             (analog) 3
 * 
 */

#define XBEE_SLEEP 2
#define SAMPLE_BUTTON 3
#define LED 4

#define SENSOR1_TOP 0
#define SENSOR1_BOTTOM 1
#define SENSOR2_TOP 2
#define SENSOR2_BOTTOM 3

//the NTC thermistor constants.  They have to be floats since #defined constants don't seem to calculate floating point values correcly
float R0=10000.0;
float B=3950.0;
float T0=298;
float RBOTTOM=1000.0;


//!  this function configures all the digital communication pins as input or output pins
/**
 * If you adapt this code to work with another sensor or board, you should replace the code in initializeSensor() to 
 * initialize all your relevant pins
 * 
 */
void initializeSensor()
{
  pinMode(XBEE_SLEEP,OUTPUT);
  pinMode(SAMPLE_BUTTON,INPUT);
  pinMode(LED,OUTPUT);
  xbeeWake();
}  

//just a wrapper for putting the xbee into sleep mode
void xbeeSleep()
{
  digitalWrite(XBEE_SLEEP,HIGH);
}

//just a wrapper for making the xbee wake up
void xbeeWake()
{
  digitalWrite(XBEE_SLEEP,LOW);
}


void getTemperatures()
{
  getRawData();
  convertToResistance();
  convertToTemperature();
}

//!this just grabs the raw values off the analog to digital converter
void getRawData()
{
  sensor1_top=analogRead(0);
  sensor1_bottom=analogRead(1);

  /*  uncomment if I enable 2-sensing elements per sensor
   sensor2_top=analogRead(2);
   sensor2_bottom=analogRead(3);*/
}

//!this function converts the raw ADC values from the thermistor into resistances of the thermistor
void convertToResistance()
{
  sensor1_resistance = ((float)sensor1_top/(float)sensor1_bottom - 1)*RBOTTOM; // Voltages converted to resistances
  /* uncomment if I enable two sensing elements
   sensor2_resistance = ((float)sensor2_top/(float)sensor2_bottom - 1)*RBOTTOM; // Voltages converted to resistances*/
   int a=(int) sensor1_resistance;
}

//this function converts the resistance of the thermistor into a temperature according to the thermistor's calibration curve
void convertToTemperature()
{
  sensor1_temperature = float(B/log(sensor1_resistance/(R0*exp(-1.0*B/T0))) - 273.0); // Temperature in degrees Celsius
  /* uncomment if I enable two sensing elements
   sensor2_temperature = float(B/log(sensor2_resistance/(R0*exp(-1.0*B/T0))) - 273.0); // Temperature in degrees Celsius   */
}

//!kills the TWI, SPI, timer1 and timer2 modules.  We're not using TWI or SPI, and timer1 and timer2 are used for PWM, which we don't use
void lowPowerOperation()
{
  //turn off modules we're not using to save power
  sbi(PRR,PRTWI);
   sbi(PRR,PRSPI);
   sbi(PRR,PRTIM1);
   sbi(PRR,PRTIM2);
 
 //set up the micro to go into POWER_DOWN mode when sleep_mode() is called.  It's the lowest power mode, and turns off pretty much everything except for the WDT
  cbi( SMCR,SE );      // sleep enable, power down mode
  cbi( SMCR,SM0 );     // power down mode
  sbi( SMCR,SM1 );     // power down mode
  cbi( SMCR,SM2 );     // power down mode
  
}

//****************************************************************  
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {

  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  sleep_enable();

  sleep_mode();                        // System sleeps here

    sleep_disable();                     // System continues execution here when watchdog timed out 
    sbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter ON

}

//****************************************************************
// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void setupWatchdog(int time) {

  byte configValue;

  if (time > 9 ) time=9;
  configValue=time & 7;
  if (time > 7) configValue|= (1<<5);
  configValue|= (1<<WDCE);
  
  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCSR = configValue;
  WDTCSR |= _BV(WDIE);
}

/**
  This function is responsible for making the sensor wait for its sampleInterval while using very little power.  It uses the 
  watchdog timer, which can wait 8,4,2, or 1 seconds.  By putting the sensor in a very low power sleep mode first and using
  the watchdog timer's overflow interrupt to bring it out of the sleep mode, I can be extremely power efficient, using ~50uA 
  rather than 20mA.  Using efficient sleep methods, the sensor can run for ~290 days off of 2 AA batteries, sampling every minute.
  It's probably a bit less than that, but I think half a year is totally reasonable
*/
void waitForSampleInterval()
{
  unsigned long totalSeconds=(hours*3600)+(minutes*60)+seconds;  //the total number of seconds we're going to wait
  unsigned int eightSecondChunks=totalSeconds/8;
  unsigned int remainder=totalSeconds%8;
  unsigned int j;
  setupWatchdog(9);    //set the watchdog timer to 8 second intervals
  for(j=0;j<eightSecondChunks;j++)
    system_sleep();    //sleep off what time we can in 8 second chunks;
 if(remainder>=4)
 {
   setupWatchdog(8);  //sleep for 4 seconds;
   system_sleep();
   remainder-=4;
 }
 if(remainder>=2)
 {
   setupWatchdog(7);  //2 second interval
   system_sleep();
   remainder-=2;
  }
  if(remainder>=1)
  {
    setupWatchdog(6);  //1 second interval
    system_sleep();
  }
}

//****************************************************************  
// Watchdog Interrupt Service / is executed when  watchdog timed out
// This is just an interrupt vector so the interrupt has something to call.  I just care about the timing.
ISR(WDT_vect) {
  boolean f_wdt=1;  // set global flag
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

