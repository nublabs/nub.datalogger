
/**
  This file contains definitions for message bytes sent back and forth between the sensor and computer
*/

#define NUM_TRIES 1
#define TIMEOUT 1000

//!  these are defined messages sent between the sensor and the computer
#define ACKNOWLEDGE                    1
#define ACKNOWLEDGE_AND_CONFIGURE      2
#define LISTENING                      3
#define CHECKSUM_ERROR_PLEASE_RESEND   4
#define CHECKSUM_ERROR_GIVING_UP       5
#define DISCOVER_ME                    6
#define TIMEOUT_ERROR                  7
#define MALFORMED_MESSAGE_ERROR_PLEASE_RESEND        8
#define MALFORMED_MESSAGE_ERROR_GIVING_UP            9


#define MESSAGE_START 128
#define MESSAGE_END   129

#define HOUR_HIGH 1
#define HOUR_LOW 2
#define MINUTE_HIGH 3
#define MINUTE_LOW 4
#define SECOND_HIGH 5
#define SECOND_LOW 6
#define CHECKSUM 7
#define CONFIGURATION_MESSAGE_LENGTH 9

#define DELIMITER ','     //using commas to delimit fields in the messages I send out
