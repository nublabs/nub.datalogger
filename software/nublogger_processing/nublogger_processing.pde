import processing.serial.*;
import java.io.*;
import javax.swing.*; 

int numSamples = 3;

Serial myPort;
intVector data;
boolean listening = true;

String delimeter = ",";
String sketchPath = "/home/aresnick/nub/projects/nublogger/software/nublogger_processing/";

HashMap sensorUnits = new HashMap();
HashMap configOptions = new HashMap();

void setup() {
  size(10,10);
  File configFile = chooseConfigFile();
  configOptions = parseConfigFile(configFile);
  
  sensorUnits.put(1,"degrees Celsius");
  sensorUnits.put(2,"degrees Celsius");
  println(Serial.list());
  int serialPortNumber = autoselectSerialPort();
  myPort = new Serial(this, Serial.list()[serialPortNumber], 9600);
}

void listen(Serial port){
  String dataRecvd = null;
  String[] data = null;
  do {
    dataRecvd = port.readStringUntil('\n');
  }while(dataRecvd == null);
  data = parseRaw(dataRecvd);
  println(dataRecvd);
  writeReading(data);
}


String[] parseRaw(String input){
  String[] parameters = split(input, delimeter);
  return parameters;
}

void writeReading(String[] sensorReadings){
  String filename = sketchPath + sensorReadings[0] + ".csv";
  
  if(!fileExists(filename)){
    initializeSensorFile(sensorReadings);
  }

  String lineToAppend = arrayToCSV(subset(sensorReadings, 1));
  appendToFile(lineToAppend, filename);
}

boolean fileExists(String filename){
  File file = new File(filename);
  if(!file.exists())
    return false;
  return true;
}

String[] constructHeadings(String[] sensorReadings){
  String[] headings = new String[sensorReadings.length-2];
  for(int i = 1; i < sensorReadings.length-1; ++i){
    headings[i-1] = ("sensor" + i) + " " + "(" + sensorUnits.get(i) + ")";
  } 
  return headings;
}

String arrayToCSV(String[] array){
  String csv = "";
  for(int i = 0; i < array.length; ++i){
    csv += array[i];
    if (i < array.length-1){
      csv += ',';
    }
  }
  
  return csv;
}

void appendToFile(String toAppend, String filename){
  try {
    BufferedWriter out = new BufferedWriter(new FileWriter(filename, true));
    out.write(toAppend);
    out.close();
  } 
  catch (IOException e) {
    print("IOException caught!  Error writing to "+filename);
  }
}

void initializeSensorFile(String[] sensorReadings){
  String filename = sketchPath + sensorReadings[0] + ".csv";
  String[] headings = constructHeadings(sensorReadings);
  
  String firstLine = arrayToCSV(headings) + '\n';
  appendToFile(firstLine, filename);
}

void toggleListening(){
  listening = !listening;
}

void keyPressed(){
  toggleListening();  
}

void draw() {
  if (myPort.available() > 0 && listening == true){
    listen(myPort);
  }
}


/////////////////////////////////////////

float display(float temp_in) {
  return 6*(100-(temp_in-273)) + 100;
}

float display_c(float temp_in) {
  return 6*(100 - temp_in) + 100;
}


float data_request(char channel){
  int rawValue = 0;
  while(rawValue == 0){
    myPort.write(channel);
    delay(50);
  }  
  
  while(myPort.available() > 0){
    data.push(myPort.read());
  }
  
  if(data.get(2) == channel){
    rawValue = data.get(0) + data.get(1)*256;
  }
  else{
    rawValue = 0;
  }
  
  myPort.clear();
  
  return float(rawValue);
}

float get_data(char channel){
  floatVector samples = new floatVector(numSamples);
  floatVector differences = new floatVector(numSamples);
  
  for(int i = 0; i < numSamples; ++i){
    samples.set(i, data_request(channel));
    floatVector complement = samples.complement(i);
    differences.set(i, abs(subtractMap(complement.getArray())));
  }
  
  float smallestDiff = min(differences.getArray());
  int smallestIndex = differences.index(smallestDiff);
    
  return average(samples.complement(smallestIndex));  
}

float average(floatVector toAverage){
  return addMap(toAverage.getArray())/toAverage.getArray().length;
}

float average(intVector toAverage){
  return float(addMap(toAverage.getArray()))/float(toAverage.size());
}

float subtractMap(float[] subtractionArray){
  int startIndex = 0; 
  int endIndex = subtractionArray.length;
  
  float subtraction = 0.0;
  for(int i = startIndex; i < endIndex; ++i){
    subtraction -= subtractionArray[i];
  }
  
  return subtraction;
}

int subtractMap(int[] subtractionArray){
  int subtraction = 0;
  int startIndex = 0;
  int endIndex = subtractionArray.length;
  for(int i = startIndex; i < endIndex; ++i){
    subtraction -= subtractionArray[i];
  }
  
  return subtraction;
}

float addMap(float[] additionArray){
  int startIndex = 0;
  int endIndex = additionArray.length;
  float addition = 0.0;
  for(int i = startIndex; i < endIndex; ++i){
    addition += additionArray[i];
  }
  
  return addition;
}

int addMap(int[] additionArray){
  int startIndex = 0;
  int endIndex = additionArray.length;
  int addition = 0;
  for(int i = startIndex; i < endIndex; ++i){
    addition += additionArray[i];
  }
  
  return addition;
} 

// A fucking intVector class, because Processing can't template ArrayLists
class intVector{
 int[] internalArray;
 
 public intVector(){
 } 
 
 public intVector(int size){
   internalArray = new int[3];
 }
 
 public intVector(int[] array){
  internalArray = array;
 }
 
 int[] getArray(){
   int[] arrayCopy;
   arrayCopy = internalArray;
   return arrayCopy;
 }
 
 int size() {
  return this.internalArray.length; 
 }
 
 intVector push(int toAdd){
   internalArray = expand(internalArray);
   internalArray[internalArray.length-1] = toAdd;
   
   return this;
 }
 
 int pop(){
   int endValue = internalArray[internalArray.length-1];
   internalArray = subset(internalArray, 0, this.size()-1);
   return endValue;
 }
 
 int get(int index){
  return internalArray[index]; 
 }
 
 intVector set(int index, int value){
   internalArray[index] = value;
   return this;
 }
 
 intVector complement(int index){
   int[] arrayUpTo = subset(internalArray, 0, index);
   int[] arrayAfter = subset(internalArray, index+1, this.size());
   int[] complementArray = splice(arrayUpTo, arrayAfter, arrayUpTo.length-1);
   intVector complementVector = new intVector(complementArray);
   return complementVector;
 }
 
 intVector remove(int index){
   int[]  newArray = this.complement(index).getArray();
   this.internalArray = newArray;
   return this;
 }
 
 int index(float value){
   for(int i = 0; i < this.size(); ++i){
     if(this.get(i) == value){
       return i;
     }
   }
   return -1;
 }
}

// A fucking floatVector class, because Processing can't template ArrayLists
class floatVector{
  float[] internalArray;
 
  public floatVector(){
  } 
 
  public floatVector(int arraySize){
    internalArray = new float[3];
  }
 
  public floatVector(float[] array){
   internalArray = array;
  }
  
  float[] getArray(){
    float[] arrayCopy;
    arrayCopy = internalArray;
    return arrayCopy;
  }
 
  int size() {
   return this.internalArray.length; 
  }
 
  floatVector push(int toAdd){
   internalArray = expand(internalArray);
   internalArray[internalArray.length-1] = toAdd;
   
   return this;
  }
  
  float pop(){
    float endValue = internalArray[internalArray.length-1];
    internalArray = subset(internalArray, 0, this.size()-1);
    return endValue;
  }
 
  float get(int index){
    return internalArray[index]; 
  }
 
  floatVector set(int index, float value){
    internalArray[index] = value;
    return this;
  }
  
  floatVector complement(int index){
    float[] arrayUpTo = subset(internalArray, 0, index);
    float[] arrayAfter = subset(internalArray, index+1, this.size());
    floatVector complementVector = new floatVector(splice(arrayUpTo, arrayAfter, arrayUpTo.length-1));
    return complementVector;
  }
  
  float subtractMap(int startIndex, int endIndex){
    float subtraction = 0;
    for(int i = startIndex; i < endIndex; ++i){
      subtraction -= this.internalArray[i];
    }
    
    return subtraction;
  }
   
  int index(float value){
    for(int i = 0; i < this.size(); ++i){
      if(this.get(i) == value){
        return i;
      }
    }
    return -1;
  }
}

File chooseConfigFile(){
  try { 
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); 
  } 
  catch (Exception e) { 
    e.printStackTrace();  
  }
  
  File file;
  // create a file chooser 
  final JFileChooser fc = new JFileChooser(); 
  
  // in response to a button click:
  int returnVal = fc.showOpenDialog(this); 
  
  if (returnVal == JFileChooser.APPROVE_OPTION) { 
    file = fc.getSelectedFile(); 
  }
  else { 
    println("Open command cancelled by user."); 
  }
  
  return file;
}

/* Config files have three lines (do not include the angle brackets in your file):
NUBLOGGER_NAME <name of datalogger>
SAMPLE_INTERVAL <interval between samples, in minutes>
SAMPLING_TIME <length of time to sample for, in minutes>
SENSOR1_UNIT <units of measurement>
SENSOR2_UNIT <units of measurement>
*/
HashMap parseConfigFile(File file){
  HashMap configOptions = new HashMap();
  String lines[] = loadStrings(file);
  for(int i = 0; i < lines.length; ++i){
    String words[] = lines[i].split(" ");
    String configOption = words[0];
    String configValue = words[1];
    
    configOptions.put(configOption, configValue);
  }
  
  return configOptions;
}

int autoselectSerialPort(){
 String[] avaliablePorts = Serial.list();
 for(int i = 0; i < availablePorts.length; ++i){
   Serial port = new Serial(this, Serial.list()[i], 9600);
   if (ask(port) == true){
     return i;
   }
 }
 print("Error: no dongle found");
}

boolean ask(Serial port){
  port.clear();
  port.write("Anybody out there?");
  if(port.available() > 0){
     if (port.readStringUntil('\n') == "Yes"){
       return true;
     }
   }
}
