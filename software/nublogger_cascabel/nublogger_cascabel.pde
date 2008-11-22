import processing.serial.*;

/**
Nublogger Cascabel
This is the latest version of the nublogger software as of 11.20.08
This software discovers, configures and logs data from nublogger-compatible wireless boards
Here's an overview of what it does:
First, the software looks for a USB zigbee dongle.  If a dongle is not connected to the computer, the software
will exit with an error.  Otherwise, it should auto-discover the dongle.
Once the computer finds the dongle, it can listen to all the traffic on the wireless network the sensors are on.

The wireless sensors spend most of their time in a power save mode where they don't respond to serial input.
They wake up at their sample interval, broadcast data and go back to sleep.  Because of this, we assume that the 
sensors will initiate all communication.

When the sensor sends information to the computer, the computer can respond with an error message, an "acknowledge" 
message, or an "acknowledge and configure" message, where the computer asks the sensor to receive a new sample
interval

Whenever the computer sees a valid message with a new sensor name, it adds a column to the data file for the new 
sensor.  This involves saving the current data file to a temporary file and re-writing the data file with the temp 
file and an inserted column.

*/


Serial myPort;             //the serial port used to talk to the wireless network
boolean fastBoot=false;    //used for debugging purposes.  When it's set to true I use pre-configured settings rather
                           //than prompt for user input or try to autodiscover shite
int baudRate=19200;       //the serial baudrate
int autodetectResponseTime= 3000;   //the time, in milliseconds, for a dongle to respond to the autodetection request

void setup() {
  size(10,10);
  println(Serial.list());
  int serialPortNumber;
  if(fastBoot)
    serialPortNumber=0;
  else    
    serialPortNumber = autoselectSerialPort();        //auto-discover the dongle
  if(serialPortNumber==-1)
  {
    println("sorry, man--we didn't find a dongle");
    exit();
  }
  else
    myPort = new Serial(this, Serial.list()[serialPortNumber], 19200);
}

 void wait(int time)  //delay() doesn't work in setup, so this is a workaround
 {
   int start=millis();
   while(millis()<(start+time))
   {}
 }
 
//!This function goes through all the serial ports and sends out the string '+++'
//!If there's an xbee connected, it'll go into command mode and respond within two seconds with 'OK'
//sending it ATCN or waiting another ~2 seconds with no activity will bring it out of command mode
int autoselectSerialPort(){
  println("searching for a wireless dongle connected to the computer");
  String[] availablePorts = Serial.list();
  for(int i = 0; i < availablePorts.length; ++i){     //try all the available ports
    Serial port = new Serial(this, availablePorts[i], baudRate);
    if (questionAnswer(port, "+++", "OK" + char(13), "ATCN" +char(13),i) == true){
      port.stop();
      println("Found the dongle!  It's on port "+ i);
      return i;
    }
    port.stop();
  }
  print("Error: no dongle found");
  return -1;
}

//!sends out 'question' to the xbee and checks to see if the reply is the expected 'answer'
//!this is a helper utility for doing dongle autodetection
boolean questionAnswer(Serial port, String question, String answer, String response, int i){
  port.clear();
  port.write(question);
  println("asking whatever is on port " + i + " to go into command mode");
  wait(autodetectResponseTime);    //make this nonblocking (do the loop where I check millis() and myPort.available())

  if(port.available() > 0){
    println("something's talking back to us!");
    String givenAnswer = port.readString();
    if (givenAnswer.indexOf(answer) > -1){
      port.write(response);
      println("that's definitely the dongle.  OK, taking it out of command mode");
      wait(autodetectResponseTime);
      return true;
    }
  }
  
  return false;
}
