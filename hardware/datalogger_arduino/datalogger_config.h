#ifndef DATALOGGER_CONFIG_H
#define DATALOGGER_CONFIG_H
// Attributes
#define MY_DIGITS_OF_PRECISION 2
#define MY_NAME "gretchen"
#define MY_SERIAL_NUMBER 1
#define MY_GUARD_TIME 1000
#define MY_TIMEOUT 500
#define MY_COMM_DELAY 50
#define MY_NUM_SENSORS 2

struct configuration {
  char* profileName;
  char** fields;
  int* values;
};

/*
configuration defaultConfiguration, receivedConfiguration, activeConfiguration;

defaultConfiguration.profileName = "default";
defaultConfiguration.fields = {"name", "serial_number", "sampling_rate", "sampling_length", "digits_of_precision"};
defaultConfiguration.values = {"gretchen", "1", "1m", "-1", "2"};
*/

//Thermistor sensor constants
float RBOTTOM=1000.0;
float B=3950.0;
float R0=10000.0;
float T0=298.0; 

#endif
