import processing.core.*; 
import processing.xml.*; 

import processing.serial.*; 
import java.io.*; 
import javax.swing.*; 

import java.applet.*; 
import java.awt.*; 
import java.awt.image.*; 
import java.awt.event.*; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class nublogger_cascabel extends PApplet {





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

//default file locations
String defaultConfigFile = "/Users/nikki/Documents/Processing/nublogger_processing/config.csv";  
String defaultOutputFile= "/Users/nikki/Documents/Processing/nublogger_processing/data.csv";


public void setup() {
  size(10,10);
  File configFile, dataFile;
  println(Serial.list());
  int serialPortNumber;
  if(fastBoot)    //just go ahead and use known defauls if I'm debugging.
  {
    serialPortNumber=0;
    configFile=new File(defaultConfigFile);
    dataFile=new File(defaultOutputFile);
  }
  else    
    serialPortNumber = autoselectSerialPort();        //auto-discover the dongle
  if(serialPortNumber==-1)
  {
    println("sorry, man--we didn't find a dongle");
    exit();
  }
  else
    myPort = new Serial(this, Serial.list()[serialPortNumber], 19200);   //opens up the serial port
    
  if(!fastBoot) 
    configFile = chooseConfigFile();    //opens up a file chooser dialog

}


 
public File chooseConfigFile(){
  try {
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  }
  catch (Exception e) {
    e.printStackTrace();
  }
  
  File file;
  // create a file chooser
  final JFileChooser fileChooser = new JFileChooser();   
  fileChooser.setDialogTitle("select a configuration file.  Hit cancel to use defaults");
  // in response to a button click:
  int returnVal = fileChooser.showOpenDialog(this); //opens up a choose file dialog
  
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    file = fileChooser.getSelectedFile();    //returns the selected file name
  }
  else {
    println("Open command cancelled, using default configuration file instead.");
    file = new File(defaultConfigFile);
  }
  
  return file;
}

 public void wait(int time)  //delay() doesn't work in setup, so this is a workaround
 {
   int start=millis();
   while(millis()<(start+time))
   {}
 }
 
 
 
 
 
//!This function goes through all the serial ports and sends out the string '+++'
//!If there's an xbee connected, it'll go into command mode and respond within two seconds with 'OK'
//sending it ATCN or waiting another ~2 seconds with no activity will bring it out of command mode
public int autoselectSerialPort() throws portInUseException
{
  println("searching for a wireless dongle connected to the computer");
  String[] availablePorts = Serial.list();
  for(int i = 0; i < availablePorts.length; ++i){     //try all the available ports
  try{
    Serial port = new Serial(this, availablePorts[i], baudRate);
    if (questionAnswer(port, "+++", "OK" + PApplet.parseChar(13), "ATCN" +PApplet.parseChar(13),i) == true){
      port.stop();
      println("Found the dongle!  It's on port "+ i);
      return i;
    }
    port.stop();
  }
  catch(portInUseException e){}
  }
  print("Error: no dongle found");
  return -1;
}


//!sends out 'question' to the xbee and checks to see if the reply is the expected 'answer'
//!this is a helper utility for doing dongle autodetection
public boolean questionAnswer(Serial port, String question, String answer, String response, int i){
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

  static public void main(String args[]) {
    PApplet.main(new String[] { "nublogger_cascabel" });
  }
}
