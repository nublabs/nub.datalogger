int milliseconds, seconds, minutes;

void initializeTiming() {
  milliseconds = 0;
  seconds = 0;
  minutes = 0;  
  timer2_init();
}


ISR(TIMER2_COMPA_vect)    //timer2 compare match
{
  milliseconds += 33;
  if(milliseconds > 1000)
  {
    milliseconds -= 1000;
    seconds++;
  }
  if(seconds > 60)
  {
    seconds -= 60;
    minutes++;
  }
}

void timer2_init()
{
  TCCR2A=0;
  TCCR2B=(1<<CS22) | (1<<CS21) | (1<<CS20);  //set the clock prescaler to 1024.  slow it down as much as possible.
  OCR2A=255;    //we're going to check the counter and throw an interrupt when it's equal to OCR2A.  We can tweak this value later to give us sooper-accurate timing, 
                //but for now it's essentially an overflow.  Each overflow is 33 ms.
  TIMSK2=0;     //keep interrupts off for now, to keep things clean
}

void timer2_start()
{
  TIMSK2=(1<<OCIE2A);  //enable an interrupt on a OCR2A compare match
  sei();     //enable global interrupts;
}
void timer2_stop()
{
  TIMSK2=0;   //get rid of that interrupt
  cli();      //kill global interrupts
}

