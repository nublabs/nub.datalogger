import processing.serial.*;
import java.io.*;

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
boolean skipAutoDetection=false;    //used for debugging purposes.  When it's set to true I use pre-configured settings 
//rather than prompt for user input or try to autodiscover shite

boolean fastBoot=false;         //another debugging variable which uses file defaults rather than opening a dialog

int baudRate=19200;       //the serial baudrate
int autodetectResponseTime= 3000;   //the time, in milliseconds, for a dongle to respond to the autodetection request

//String currentDirectory="/Users/nikki/nublabs/10am_reverted_code/nub.datalogger/software/nublogger_cascabel/";
String currentDirectory="";

//default file locations
String defaultConfigFile = currentDirectory+"config.csv";


String allSensorsOutputFile=currentDirectory+"output-all.csv";
String configuredSensorsOutputFile=currentDirectory+"output.csv";

//this LinkedList stores all of our known sensing objects.
LinkedList allSensors;

//this stores the names of our configured sensors, which is another way of saying that they're sensors we care about
LinkedList configuredSensors;

FileWriter output;

int lineFeed=(int)'\n';

PFont font;         //the font I'll use

final int TIMEOUT=100;
final int NUM_TRIES=1;

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
  int hours, minutes, seconds;
  String lastValue;
  boolean configured;
  Sensor(String newName)
  {
    name=newName;
    configured=false;
  }  
  Sensor(String newName, int h, int m, int s)
  {
    name=newName;
    hours=h;
    minutes=m;
    seconds=s;
    configured=false;
  }
  Sensor(String newName, String value)
  {
    name=newName;
    configured=false;
    lastValue=value;
  }  
  Sensor(String newName, int h, int m, int s, String value)
  {
    name=newName;
    hours=h;
    minutes=m;
    seconds=s;
    configured=false;
    lastValue=value;
  }
}

void setup() {
  size(400,400);
  font=loadFont("ACaslonPro-Regular-14.vlw");  //setting up our font
  textFont(font);
  textMode(MODEL);      //should make a smoother font
  background(0);
//  File configFile, dataFile;
  String configFile;
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
    background(0,80,0);              //turn the background green if we found a dongle
  }
  
  
  if(fastBoot)
    configFile=defaultConfigFile; 
  else
  {
    String configFileLocation=selectInput("Select a configuration file.  Hit cancel to use defaults");    //opens up a file chooser dialog
    if(configFileLocation==null)
      configFile=defaultConfigFile;
    else
        configFile=configFileLocation;

    String outputFileLocation=selectOutput("Select a file to save your logged data to.  Hit cancel to use defaults");    //opens up a file chooser dialog
    if(outputFileLocation!=null)
        configuredSensorsOutputFile=outputFileLocation;

  }
  
  readConfiguration(configFile);
  writeHeader();
}

//!writes the column headings for the output files
void writeHeader()
{  
  
  //write to the configured sensors output file
  try{
  output =new FileWriter(configuredSensorsOutputFile); 
  output.write("Date,Time,");
  for(int i=0;i<configuredSensors.size();i++)
  {
    Sensor a=(Sensor) configuredSensors.get(i);
    output.write(a.name+",units,");
  }
  output.write("\n");  
  output.flush();
  output.close();  
  } 
  catch(Exception e)
  {
    println("could not open output file");
  }

  //write to the 'all sensors' output file
  try{
  output =new FileWriter(allSensorsOutputFile); 
  output.write("Date,Time,");
  for(int i=0;i<configuredSensors.size();i++)
  {
    Sensor a=(Sensor) configuredSensors.get(i);
    output.write(a.name+",units,");
  }
  output.write("\n");  
  output.flush();
  output.close();  
  } 
  catch(Exception e)
  {
    println("could not open output file");
  }


}

void readConfiguration(String configFile)
{
  //I have to check to make sure that configFile is a real file
  
  String [] lines=loadStrings(configFile);
  if(lines!=null)
  {
    if(lines.length>1)  
    {
  for(int i=1;i<lines.length;i++)   //skip the header line and then read everything else from the file
                                      //do I want to think about what happens if they don't put in a header line?
  {
    String[] brokenUp=splitTokens(lines[i],",");
    //the format is sensor name, sample interval in hours, minutes, seconds
    //add the sensors to 
    Sensor temp=new Sensor(trim(brokenUp[0]));
    temp.hours=Integer.decode(trim(brokenUp[1]));
    temp.minutes=Integer.decode(trim(brokenUp[2]));
    temp.seconds=Integer.decode(trim(brokenUp[3]));
    configuredSensors.add(temp);
    allSensors.add(temp); 
  }
  }
  }
}

void draw(){
  String rawData;
  String [] splitMessage;
//  while(true)   //I don't trust draw to run properly--I'm putting in my own forever loop
 // {
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
        if(needsConfiguration(splitMessage))
        {
           // configure();
              configure(splitMessage);
        }
        else
         myPort.write(ACKNOWLEDGE);          
      }
    }
  }

  text("sensors we're listening to",15,20);
  for(int count=0;count<allSensors.size();count++)
  {
    Sensor a=(Sensor) allSensors.get(count);
    text(a.name,15,20+((count+1)*20));
  }

  text("sensors we want to configure",200,20);
  for(int count=0;count<configuredSensors.size();count++)
  {
    Sensor a=(Sensor) configuredSensors.get(count);
    text(a.name,200,20+((count+1)*20));
  }
//  }
}

//this checks if a sensor needs to be configured.
boolean needsConfiguration(String[] splitMessage)
{
  Sensor a;
  boolean doesItNeedToBeConfigured=false;
  for(int i=0;i<configuredSensors.size();i++)     //loop through the list of sensors that need configuration and see if this is one of them
  {
    a=(Sensor)configuredSensors.get(i);
    if((splitMessage[NAME].equals(a.name))&&(a.configured==false))
    {
      doesItNeedToBeConfigured=true;
      i=configuredSensors.size();     //exit the loop
    }
  }
  return doesItNeedToBeConfigured;
}



void configure(String[] splitMessage)
{
  int tries=0;
  int response=-1;
  boolean tryingToConfigure=true;
  Sensor a=new Sensor("");
  int index=0;
  for(int i=0;i<configuredSensors.size();i++)     //loop through the list of sensors that need configuration and see if this is one of them
  {
    a=(Sensor)configuredSensors.get(i);
    if(splitMessage[NAME].equals(a.name))  //we found our sensor
      {
        index=i;
        i=configuredSensors.size();
      }
  }
  int highHour, lowHour, highMinute, lowMinute, highSecond, lowSecond;
  highHour=a.hours/256;
  lowHour=a.hours%256;
  highMinute=a.minutes/256;
  lowMinute=a.minutes%256;
  highSecond=a.seconds/256;
  lowSecond=a.seconds%256;
  println("asking datalogger if it's ready to configure");
   myPort.write(ACKNOWLEDGE_AND_CONFIGURE);
   delay(50);

   while((tryingToConfigure)&&(!a.configured)&&(tries<NUM_TRIES))
   {
     println("listening for a response");
   if(listenForResponse(TIMEOUT,LISTENING)==0)  //checks to make sure the sensor is ready to receive configuration
   {  
     println("sending configuration message");
      myPort.write(MESSAGE_START);
      myPort.write(highHour);
      myPort.write(lowHour);
      myPort.write(highMinute);
      myPort.write(lowMinute);
      myPort.write(highSecond);
      myPort.write(lowSecond);
      myPort.write((highHour+lowHour+highMinute+lowMinute+highSecond+lowSecond)%256);  //print the checksum;
      myPort.write(MESSAGE_END);
      println("send config message, listening for response");
      response=listenForResponse(TIMEOUT*2,ACKNOWLEDGE);
      if(response==0)  //everything got through ok
        {
          println(a.name+" is configured");
          a.configured=true;
          configuredSensors.add(index+1,a);
          configuredSensors.remove(index);          
          tryingToConfigure=false;
        }
       else
       {
         if((response==CHECKSUM_ERROR_GIVING_UP)||(response==MALFORMED_MESSAGE_ERROR_GIVING_UP))
           tryingToConfigure=false;    //if the sensor gives up, so do we
       }
   }
   else
   {
     tries++;
     println(splitMessage[NAME]+" is not ready for configuration.  The response was "+response);
   }
   }
    
}


//!listens to the serial port for a max of timeout milliseconds and returns 0 if the response is the expected response
//!or the response if it's unexpected.


int listenForResponse(int timeout,int expectedResponse)
{
  String response=null;
  int currentTime=millis();
  while((millis()<(currentTime+timeout))&&(response==null))
  {
    response=myPort.readStringUntil(lineFeed);
  }

   if(response==null)
   {
     println("no response");
     return -1;
   }
   else
   {
     println("the sensor's response was "+trim(response)+" and we expected: "+String.valueOf(expectedResponse));
     if(trim(response).equals(String.valueOf(expectedResponse)))  //the response matches what I expected
  {
    println("great!  That's the response we were hoping to get");
    return 0;
  }
  else
  {
    try{
      return Integer.decode(trim(response));
    }
    catch(Exception e)
    {
      println("wacky response string:  "+response);
      return -1;
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
    allSensors.add(new Sensor(splitMessage[NAME],splitMessage[VALUE]));   //add the name to the sensors list
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

/**this function adds two new columns to the file--one for the sensor name and one for its units.  It completely rewrites
the file from scratch, and then passes off the expanded file to writeToAllSensors to append the new sample to the end of 
the file
*/
void addColumn(String[] splitMessage)
{
  String[] file =loadStrings(allSensorsOutputFile); // read in all the data from the allSensors output file
  try{
  output =new FileWriter(allSensorsOutputFile);    //we just read all that data into ram, so now I'm going to overwrite the file
  output.write(file[0]+splitMessage[NAME]+","+"units,\n");
  for(int i=1;i<file.length;i++)
    output.write(file[i]+",,\n"); 
  output.flush();
  output.close();  
  }
  catch(Exception e)
  {
    println("could not open output file");
  }
  writeToAllSensors(splitMessage);
}

/**
This function makes a data and timestamp for the current sample and inserts the sample into the data, with placeholders
for all the other sensors that don't have data
*/
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
/**
This function is identical too writeToAllSensors except it only writes to the file dedicated to storing data for configured
sensors.
*/
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
    try{
    if(Integer.decode(message[START_BYTE])==MESSAGE_START)
    {
      try{
      if(Integer.decode(trim(message[END_BYTE]))==MESSAGE_END)
      {
        try{
        if(Integer.decode(message[CHECKSUM])==calculateChecksum(message))
          return true;    //the message format and checksum are ok
        else
        {
          println("bad checksum");
          myPort.write(CHECKSUM_ERROR_PLEASE_RESEND);
          return false;
        }
       }
      catch(Exception e)
      {
        return false;
      }
      
      }
      else
      {
        println("Message end byte doesn't match up");
        myPort.write(MALFORMED_MESSAGE_ERROR_PLEASE_RESEND);
        return false;
      }
      }
      catch(Exception e)
      {
        return false;
      }

    }
    else
    {
      println("Message start byte doesn't match up");
      myPort.write(MALFORMED_MESSAGE_ERROR_PLEASE_RESEND);
      return false;
    }
    }
    catch(Exception e)
    {
      return false;
    }
  }
  else
  {
    println("wrong message length");
    myPort.write(MALFORMED_MESSAGE_ERROR_PLEASE_RESEND);
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
    try{    //todo:  gracefully handle a portInUseException error
    Serial port = new Serial(this, availablePorts[i], baudRate);
    if (questionAnswer(port, "+++", "OK" + char(13), "ATCN" +char(13),i) == true){
      port.stop();
      println("Found the dongle!  It's on port "+ i);
      return i;
    }
    port.stop();
    }
     catch(Exception e)
      {
        println("Uh-oh.  That port's in use.  Moving on...");
      }
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

void keyPressed()  //if a key gets hit
{
  if((key=='q')||(key=='Q'))  //user wants to quit
    exit();  //then we quit
}


