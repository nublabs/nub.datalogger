//Protocol (0-25)
#define MESSAGE_START 0
#define MESSAGE_END 1
#define MESSAGE_DELIMITER ","

//Messages from dongle
#define OK 2
#define DISCOVERY_CONFIRMED

//States (51-100)
#define TURNING_ON 50
#define INITIALIZED 51
#define WAITING_FOR_CONFIG 52
#define CONFIGURED 53
#define SAMPLING 54
#define TURNING_OFF 55
#define BROKEN 56

//Message IDs (101 - 150)
#define WHOAMI_IDENTIFIER 101
#define CHECKSUM_IDENTIFIER 102
#define CONFIGURATION_IDENTIFIER 103
#define LOGGING_IDENTIFIER 104
#define REQUEST_IDENTIFIER 105

//Error Messages (151 - 200)
#define MALFORMED_MESSAGE_ERROR 101
#define MISSING_MESSAGE_START_ERROR 102
#define MISSING_MESSAGE_END_ERROR 103
#define TIMEOUT_ERROR 104
#define WRONG_CHECKSUM_ERROR 105
#define NO_DATA_ERROR 106

//Request messages (201 - 250)
#define PLEASE_RESEND 151
#define PLEASE_CONFIGURE_ME 152
#define PLEASE_DISCOVER_ME 153

//Commands (251 - 300)
#define WAIT_FOR_CONFIGURATION 201
#define RESEND_MESSAGE 202
#define SLEEP 203
#define WAKE 204

// Attributes
#define MY_DIGITS_OF_PRECISION 2
#define MY_NAME "gretchen"
#define MY_SERIAL_NUMBER 1
#define MY_GUARD_TIME 1000
#define MY_TIMEOUT 500
#define MY_COMM_DELAY 50
#define MY_NUM_SENSORS 2


// XBee configuration 
#define XBEE_SLEEP_PIN 13
#define XBEE_COMM_DELAY 1000
#define XBEE_GUARD_TIME 2000


//----------

#include "helpers.h"

struct configuration {
  char* profileName;
  char** fields;
  int* values;
};

configuration defaultConfiguration, receivedConfiguration, activeConfiguration;

defaultConfiguration.profileName = "default";
defaultConfiguration.fields = ["name", "serial_number", "sampling_rate", "sampling_length", "digits_of_precision"]
defaultConfiguration.values = ["gretchen", "1", "1m", "-1", "2"]
