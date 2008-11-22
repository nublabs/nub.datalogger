import processing.serial.*;
import java.io.*;
import javax.swing.*;

/**
 * Nublogger Cascabel
 * This is the latest version of the nublogger software as of 11.20.08
 * This software discovers, configures and logs data from nublogger-compatible wireless boards
 * Here's an overview of what it does:
 * First, the software looks for a USB zigbee dongle.  If a dongle is not connected to the computer, the software
 * will exit with an error.  Otherwise, it should auto-discover the dongle.
 * Once the computer finds the dongle, it can listen to all the traffic on the wireless network the sensors are on.
 * 
 * The wireless sensors spend most of their time in a power save mode where they don't respond to serial input.
 * They wake up at their sample interval, broadcast data and go back to sleep.  Because of this, we assume that the 
 * sensors will initiate all communication.
 * 
 * When the sensor sends information to the computer, the computer can respond with an error message, an "acknowledge" 
 * message, or an "acknowledge and configure" message, where the computer asks the sensor to receive a new sample
 * interval
 * 
 * Whenever the computer sees a valid message with a new sensor name, it adds a column to the data file for the new 
 * sensor.  This involves saving the current data file to a temporary file and re-writing the data file with the temp 
 * file and an inserted column.
 * 
 */


Serial myPort;             //the serial port used to talk to the wireless network
boolean skipAutoDetection=true;    //used for debugging purposes.  When it's set to true I use pre-configured settings 
//rather than prompt for user input or try to autodiscover shite

boolean fastBoot=true;         //another debugging variable which uses file defaults rather than opening a dialog

int baudRate=19200;       //the serial baudrate
int autodetectResponseTime= 3000;   //the time, in milliseconds, for a dongle to respond to the autodetection request

//default file locations
String defaultConfigFile = "/Users/nikki/nublabs/nub.datalogger/software/nublogger_cascabel/config.csv";

String allSensorsOutputFile="/Users/nikki/nublabs/nub.datalogger/software/nublogger_cascabel/output-all.csv";
String configuredSensorsOutputFile="/Users/nikki/nublabs/nub.datalogger/software/nublogger_cascabel/output.csv";

//this LinkedList stores all of our known sensing objects.
LinkedList allSensors;

//this stores the names of our configured sensors, which is another way of saying that they're sensors we care about
LinkedList configuredSensors;

FileWriter output;

int lineFeed=10;

final int START_BYTE=0;
final int NAME=1;
final int VALUE=2;
final int UNITS=3;
final int CHECKSUM=4;
final int END_BYTE=5;
final int EXPECTED_SIZE=6;


//! definitions for byte messages that go back and forth between the computer and the logger
final int ACKNOWLEDGE                    =1;
final int ACKNOWLEDGE_AND_CONFIGURE      =2;
final int LISTENING                      =3;
final int CHECKSUM_ERROR_PLEASE_RESEND   =4;
final int CHECKSUM_ERROR_GIVING_UP       =5;
final int DISCOVER_ME                    =6;
final int TIMEOUT_ERROR                  =7;
final int MALFORMED_MESSAGE_ERROR_PLEASE_RESEND     =   8;
final int MALFORMED_MESSAGE_ERROR_GIVING_UP         =   9;
final int MESSAGE_START =128;
final int MESSAGE_END   =129;


class Sensor{
  String name;
  Sensor(String newName)
  {
    name=newName;
  }
}

void setup() {
  size(10,10);
  File configFile, dataFile;
  String configFile
  allSensors=new LinkedList();
  configuredSensors=new LinkedList();

  println(Serial.list());
  int serialPortNumber;
  if(skipAutoDetection)    //just go ahead and use known defauls if I'm debugging.
  {
    serialPortNumber=0;
  }
  else    
    serialPortNumber = autoselectSerialPort();        //auto-discover the dongle
  if(serialPortNumber==-1)
  {
    println("sorry, man--we didn't find a dongle");
    exit();
  }
  else
  {
    myPort = new Serial(this, Serial.list()[serialPortNumber], 19200);   //opens up the serial port
    myPort.bufferUntil(lineFeed);   //if I choose to, read until I get a line feed
  }
  
  /** this all treats configFile as a File object.  I want to use the loadStrings() functions, so I'm going to try making
  configFile a string instead
  */
  /*  
  if(fastBoot)
  {
    configFile=new File(defaultConfigFile);
  }  
  
  else
  {
    String configFileLocation=selectInput("select a configuration file.  Hit cancel to use defaults");    //opens up a file chooser dialog
    if(configFileLocation==null)
    {
      configFile=new File(defaultConfigFile);
    }
    else
    {
      try{
        configFile=new File(configFileLocation);
      }
      catch(Exception e)
      {
        println("can't open that file.  Using default");
        configFile=new File(configFileLocation);
      }
    }
  }*/
  
  
  readConfiguration(configFile);
}

void readConfiguration(File configFile)
{
}

void draw(){
  String rawData;
  String [] splitMessage;
  while(myPort.available()>0)   //while there's data in the serial buffer
  {
    rawData=myPort.readStringUntil(lineFeed);     //read data off the serial port until I hit a line feed and store it in
    //rawData
    if(rawData!=null)
    {    
      print(day()+"/"+month()+"/"+year()+"    ");   //print out the date
      print(hour()+":"+minute()+":"+second()+"    ");  //print out the time in 24-hour format  
      print(rawData);                                             
      splitMessage=splitTokens(rawData,",");        //break the message up into smaller strings everywhere there's a comma
      if(checkMessage(splitMessage))                 //make sure the message is valid
      {
        addData(splitMessage);     //add the data to the log
      }
    }
  }
}


/** addData scans our list of known sensors ('sensors') and configured sensors ('configuredSensors') and checks to see
 * if the sensor that sent this message is listed.  If it's unlisted, it adds that sensor to the 'sensors' list and creates a 
 * new column in the 'allSensors' file.  If it's listed under 'sensors' but not under 'configuredSensors' then it appends a
 * line with a timestamp and the data to the sensors file.  If it's listed under 'configuredSensors,' ('sensors' is a subset
 * of 'configuredSensors') it appends a line to both the 'allSensors' and 'configuredSensors' files.
 * 
 */
void addData(String[] splitMessage)
{
  Sensor mySensor;
  int i;
  boolean inConfiguredSensors=false;
  boolean inSensors=false;
  for(i=0;i<allSensors.size();i++)    //go through the sensors list and see if we have this sensor's name stored
  {
    mySensor=(Sensor)allSensors.get(i);
    if(splitMessage[NAME].equals(mySensor.name))
      inSensors=true;
  }
  for(i=0;i<configuredSensors.size();i++)    //go through the sensors list and see if we have this sensor's name stored
  {
    mySensor=(Sensor)configuredSensors.get(i);
    if(splitMessage[NAME].equals(mySensor.name))
      inConfiguredSensors=true;
  }

  if((!inSensors)&&(!inConfiguredSensors))   //this is a completely new sensor
  {
    allSensors.add(new Sensor(splitMessage[NAME]));   //add the name to the sensors list
    addColumn(splitMessage);                       //add a column to the allSensors file
  }

  if(inConfiguredSensors)                          //if this is one of the sensors we've configured
  {
    writeToConfiguredSensors(splitMessage);
    writeToAllSensors(splitMessage);
  }

  if((!inConfiguredSensors)&&(inSensors))          //if this isn't a sensor we've configured, but we've seen it before
  {
    writeToAllSensors(splitMessage);
  }

}


void addColumn(String[] splitMessage)
{
}

void writeToAllSensors(String[] splitMessage)
{
  try{
  output=new FileWriter(allSensorsOutputFile,true);  //put it in append mode
  //write the timestamp
/*  String timestamp=day()+"/"+month()+"/"+year()+","+hour()+":"+minute()+":"+second()+",";
  output.write(timestamp,0,timestamp.length());*/
  output.write(day()+"/"+month()+"/"+year()+",");   //print out the date
  output.write(hour()+":"+minute()+":"+second()+",");  //print out the time in 24-hour format

  Sensor mySensor;   //dummy sensor, just to check names

  /**this loop goes through the list of sensors.  It spits out two blank comma-delimited spaces (one for the value,
   * one for the units, if the sensor's name doesn't match the one from the splitMessage.  If it does match, it prints out
   * the value and units from the message
   */
  for(int i=0;i<allSensors.size();i++)   
  {
    mySensor=(Sensor)allSensors.get(i);
    if(mySensor.name.equals(splitMessage[NAME]))  //this is the sensor from splitMessage
    {
      output.write(splitMessage[VALUE]+","+splitMessage[UNITS]+",");   //print out the data
    }
    else
      output.write(",,");    //just print out blank spaces as placeholders
  }
  output.write("\n");
  output.flush();
  output.close();
  }
  catch(Exception e){
    println("error opening file");
  }    
}

void writeToConfiguredSensors(String[] splitMessage)
{
  try{
  output=new FileWriter(configuredSensorsOutputFile,true);  //put it in append mode
  //write the timestamp
  output.write(day()+"/"+month()+"/"+year()+",");   //print out the date
  output.write(hour()+":"+minute()+":"+second()+",");  //print out the time in 24-hour format

  Sensor mySensor;   //dummy sensor, just to check names

  /**this loop goes through the list of sensors.  It spits out two blank comma-delimited spaces (one for the value,
   * one for the units, if the sensor's name doesn't match the one from the splitMessage.  If it does match, it prints out
   * the value and units from the message
   */
  for(int i=0;i<configuredSensors.size();i++)   
  {
    mySensor=(Sensor)configuredSensors.get(i);
    if(mySensor.name.equals(splitMessage[NAME]))  //this is the sensor from splitMessage
      output.write(splitMessage[VALUE]+","+splitMessage[UNITS]+",");   //print out the data
    else
      output.write(",,");    //just print out blank spaces as placeholders
  }
  output.write("\n");
  output.flush();
  output.close();
  }
  catch(Exception e){
    println("error opening file");
  }

}

//! makes sure the message checksum and format is ok
boolean checkMessage(String[] message)
{
  
  //look out for Integer.decode!  It throws numberFormatExceptions left and right!
  if(message.length==EXPECTED_SIZE)
  {
    if(Integer.decode(message[START_BYTE])==MESSAGE_START)
    {
      if(Integer.decode(trim(message[END_BYTE]))==MESSAGE_END)
      {
        if(Integer.decode(message[CHECKSUM])==calculateChecksum(message))
          return true;    //the message format and checksum are ok
        else
        {
          println("bad checksum");
          return false;
        }
      }
      else
      {
        println("Message end byte doesn't match up");
        return false;
      }
    }
    else
    {
      println("Message start byte doesn't match up");
      return false;
    }
  }
  else
  {
    println("wrong message length");
    return false;
  }
}

int calculateChecksum(String[] message)
{
  int i;
  int checksum=0;

  //check to see that charAt is from 0 to 255
  for(i=0;i<message[NAME].length();i++)
    checksum+=(int)message[NAME].charAt(i);
  for(i=0;i<message[VALUE].length();i++)
    checksum+=(int)message[VALUE].charAt(i);
  for(i=0;i<message[UNITS].length();i++)
    checksum+=(int)message[UNITS].charAt(i);

  return checksum%256;
}

//opens up a dialog to select a configuration file
File chooseConfigFile(){
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

void wait(int time)  //delay() doesn't work in setup, so this is a workaround
{
  int start=millis();
  while(millis()<(start+time))
  {
  }
}



//!This function goes through all the serial ports and sends out the string '+++'
//!If there's an xbee connected, it'll go into command mode and respond within two seconds with 'OK'
//sending it ATCN or waiting another ~2 seconds with no activity will bring it out of command mode
int autoselectSerialPort() //throws portInUseException
{
  println("searching for a wireless dongle connected to the computer");
  String[] availablePorts = Serial.list();
  for(int i = 0; i < availablePorts.length; ++i){     //try all the available ports
    //  try{    //todo:  gracefully handle a portInUseException error
    Serial port = new Serial(this, availablePorts[i], baudRate);
    if (questionAnswer(port, "+++", "OK" + char(13), "ATCN" +char(13),i) == true){
      port.stop();
      println("Found the dongle!  It's on port "+ i);
      return i;
    }
    port.stop();
    /*  }
     catch(portInUseException e){}*/
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



