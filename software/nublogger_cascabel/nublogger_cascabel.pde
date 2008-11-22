/**
Nublogger Cascabel
This is the latest version of the nublogger software as of 11.20.08
This software discovers, configures and logs data from nublogger-compatible wireless boards
Here's an overview of what it does:
First, the software looks for a USB zigbee dongle.  If a dongle is not connected to the computer, the software
will exit with an error.  Otherwise, it should auto-discover the dongle.
Once the computer finds the dongle, it can listen to all the traffic on the wireless network the sensors are on.



*/

void setup() {
  size(10,10);
  File configFile;
  if(fastBoot)
  {
    configFile=new File(defaultConfigFile);
    dataFile=new File(defaultOutputFile);
  }
  else 
    configFile = chooseConfigFile();
   
  configOptions = parseConfigFile(configFile);
 
  sensorUnits.put(1, configOptions.get("Gretchen"));
  sensorUnits.put(2, configOptions.get("Mitchell"));
  println(Serial.list());
  int serialPortNumber;
  if(fastBoot)
    serialPortNumber=0;
  else    
    serialPortNumber = autoselectSerialPort();
  if(serialPortNumber==-1)
  {
    println("sorry, man--we didn't find a dongle");
    exit();
  }
  else
    myPort = new Serial(this, Serial.list()[serialPortNumber], 19200);
}


 

int autoselectSerialPort(){
 String[] availablePorts = Serial.list();
 for(int i = 0; i < availablePorts.length; ++i){
   Serial port = new Serial(this, Serial.list()[i], 9600);
   if (ask(port) == true){
     return i;
   }
 }
 print("Error: no dongle found");
 return -1;
}


