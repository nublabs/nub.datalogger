//!  configure() runs if the computer is trying to change the sensor's sample rate
/**
  In configure(), the datalogger sends a LISTENING message to the computer, indicating that it's ready to receive data.
  The computer sends three ints:  the hours, minutes and seconds of the sample interval, followed by a checksum byte that's the sum 
  of the ints modulo 256.  The sensor computes a checksum on the received data.  If its checksum matches, it sends an 
  ACKNOWLEDGE message back to the computer and updates its sample interval information.  If the checksum does not match, it sends 
  a CHECKSUM_ERROR_PLEASE_RESEND message, asking the computer to send the three ints again, followed by a checksum.  If the 
  sensor can't get a valid message (with a matching checksum) after three tries, it gives up, sends a CHECKSUM_ERROR_GIVING_UP 
  message to the computer and keeps its original sample interval information
*/
void configure()
{ 
}

//!  This function tells the computer of the datalogger's existence
/**
  When the sensor turns on, it runs discover().  It sends a MESSAGE_START message, a DISCOVER_ME message, and its name out to the 
  computer and waits for acknowledgement.  The computer can send back a plain "ACKNOWLEDGE" message, which means that the sensor 
  should run using its default configuration values.  The computer can also send back an "ACKNOWLEDGE_AND_CONFIGURE" message, which 
  means that it has configuration data for the sensor.  If the sensor gets this message, it'll run configure() to receive the data 
  from the computer.
*/
void discover()
{
}
