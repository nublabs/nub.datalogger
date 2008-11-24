//****************************************************************
/*
 * Watchdog Sleep Example 
 * Demonstrate the Watchdog and Sleep Functions
 * Photoresistor on analog0 Piezo Speaker on pin 10
 * 
 
 * KHM 2008 / Lab3/  Martin Nawrath nawrath@khm.de
 * Kunsthochschule fuer Medien Koeln
 * Academy of Media Arts Cologne
 
 */
//****************************************************************

#include <avr/sleep.h>
#include <avr/wdt.h>

#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

#include "WProgram.h"
void setup();
void setupLowPowerMode();
void loop();
void lowPowerOperation();
void system_sleep();
void setupWatchdog(int time);
void waitForSampleInterval();
int a=0;
int hours, minutes, seconds;
volatile boolean f_wdt=1;

void setup(){
  Serial.begin(19200);
  hours=0;
  minutes=0;
  seconds=5;
  // CPU Sleep Modes 
  // SM2 SM1 SM0 Sleep Mode
  // 0    0  0 Idle
  // 0    0  1 ADC Noise Reduction
  // 0    1  0 Power-down
  // 0    1  1 Power-save
  // 1    0  0 Reserved
  // 1    0  1 Reserved
  // 1    1  0 Standby(1)
}


void setupLowPowerMode()
{
  lowPowerOperation();
}

//****************************************************************
//****************************************************************
//****************************************************************
void loop(){

  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
    f_wdt=0;       // reset flag    

     waitForSampleInterval();
     Serial.println(millis());
     delay(2);
  }
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

void waitForSampleInterval()
{
  unsigned long totalSeconds=(hours*3600)+(minutes*60)+seconds;  //the total number of seconds we're going to wait
  unsigned int eightSecondChunks=totalSeconds/8;
  unsigned int remainder=totalSeconds%8;
  unsigned int j;
  setupWatchdog(9);    //set the watchdog timer to 8 second intervals
  for(j=0;j<eightSecondChunks;j++)
    system_sleep();    //sleep off what time we can in 8 second chunks;
 if(remainder>4)
 {
   setupWatchdog(8);  //sleep for 4 seconds;
   system_sleep();
   remainder-=4;
 }
 if(remainder>2)
 {
   setupWatchdog(7);  //2 second interval
   system_sleep();
   remainder-=2;
  }
  if(remainder>1)
  {
    setupWatchdog(6);  //1 second interval
    system_sleep();
  }
}

//****************************************************************  
// Watchdog Interrupt Service / is executed when  watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag
}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

