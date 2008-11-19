


/**
  This file contains definitions for message bytes sent back and forth between the sensor and computer
*/

//!  these are defined messages sent between the sensor and the computer
#define ACKNOWLEDGE                    1
#define ACKNOWLEDGE_AND_CONFIGURE      2
#define LISTENING                      3
#define CHECKSUM_ERROR_PLEASE_RESEND   4
#define CHECKSUM_ERROR_GIVING_UP       5
#define DISCOVER_ME                    6

#define MESSAGE_START 128
#define MESSAGE_END   129
