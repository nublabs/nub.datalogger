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

#include "temperature_sensor_board_v2.h"   //this file has pin definitions specific to the version 2 circuit board
                                           //if you're using a board that's wired up differently, you'll need to change this file

#include "communications.h"                //this file has definitions for message bytes sent between the computer and the sensor

#include "nublogger.h"                     //this file contains the discover() and configure() functions that are shared across all
                                           //sensors that work with the nublabs datalogging system

void setup()
{
  initializeSensor();
  Serial.begin(19200);
}

void loop()
{
}
