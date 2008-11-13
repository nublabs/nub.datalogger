void XBee_wake(){
  digitalWrite(sleepPin.number, LOW);
  delay(15);
}

void XBee_sleep(){
  pinMode(sleepPin.number, OUTPUT);
  digitalWrite(sleepPin.number, HIGH);
  delay(1000);  
}

void XBee_changeBaudRate(int currentBaudRate, int finalBaudRate)
{
  Serial.begin(currentBaudRate);
  Serial.print("+++");
  delay(2000);
  char* finalBaudRateParameter = itoa(XBee_getBaudRateParameter(finalBaudRate)); 
  Serial.println("ATBD" + finalBaudRateParameter);
  Serial.println("ATWR");
  Serial.println("ATCN");
  Serial.begin(finalBaudRate);
}

// The XBee Maxstream has set values which you append to AT commands to choose baud rates, this searches them
int XBee_getBaudRateParameter(int baudRate){
  int[] baudRates = [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200];
  
  for(int i = 0; i < len(baudRates); ++i){
   if(baudRates[i] == baudRate){
    return i;
   } 
  }
  
  return -1;
}
