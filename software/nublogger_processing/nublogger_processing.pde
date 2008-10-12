import processing.serial.*;
import java.io.*;

int numSamples = 3;

Serial myPort;
intVector data;
boolean listening = true;
String delimeter = ",";
String sketchPath = "/home/aresnick/nub/projects/nublogger/software/nublogger_processing/";

void setup() {
  size(10,10);
  sketchPath = choosePath();

  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
}

String choosePath(){
  String savePath = selectFolder();  // Opens file chooser
  if (savePath == null) {
    // If a file was not selected
    println("No output file was selected...");
  } else {
  // If a file was selected, print path to folder
  println(savePath);
  }
  return savePath;
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

  String lineToAppend = arrayToCSV(subset(sensorReadings, 1)) + '\n';
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
    headings[i-1] = "sensor"+i;
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
    else{
      csv += '\n';
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
  
  String firstLine = arrayToCSV(headings);
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
