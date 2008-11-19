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
 
 
 //!  this function configures all the digital communication pins as input or output pins
 /**
   If you adapt this code to work with another sensor or board, you should replace the code in initializeSensor() to 
   initialize all your relevant pins
   
 */
 void initializeSensor()
 {
 /*  pinMode(XBEE_SLEEP,OUTPUT);
   pinMode(SAMPLE_BUTTON,INPUT);
   pinMode(LED,OUTPUT);*/
 }
 
