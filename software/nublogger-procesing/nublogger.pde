import processing.serial.*;

Serial port;
String data;

void setup(){
  println(Serial.list());
  port = new Serial(this, Serial.list()[0], 9600);
}

void draw(){
 while (port.available() > 0){
   data = port.readStringUntil(int("r"));
   if (data != null){
     println(data);
   }
 }
}
