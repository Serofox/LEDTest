/**
 * Get Line In
 * by Damien Di Fede.
 * Slight color modification by TfGuy44
 *  
 * This sketch demonstrates how to use the <code>getLineIn</code> method of 
 * <code>Minim</code>. This method returns an <code>AudioInput</code> object. 
 * An <code>AudioInput</code> represents a connection to the computer's current 
 * record source (usually the line-in) and is used to monitor audio coming 
 * from an external source. There are five versions of <code>getLineIn</code>:
 * <pre>
 * getLineIn()
 * getLineIn(int type) 
 * getLineIn(int type, int bufferSize) 
 * getLineIn(int type, int bufferSize, float sampleRate) 
 * getLineIn(int type, int bufferSize, float sampleRate, int bitDepth)  
 * </pre>
 * The value you can use for <code>type</code> is either <code>Minim.MONO</code> 
 * or <code>Minim.STEREO</code>. <code>bufferSize</code> specifies how large 
 * you want the sample buffer to be, <code>sampleRate</code> specifies the 
 * sample rate you want to monitor at, and <code>bitDepth</code> specifies what 
 * bit depth you want to monitor at. <code>type</code> defaults to <code>Minim.STEREO</code>,
 * <code>bufferSize</code> defaults to 1024, <code>sampleRate</code> defaults to 
 * 44100, and <code>bitDepth</code> defaults to 16. If an <code>AudioInput</code> 
 * cannot be created with the properties you request, <code>Minim</code> will report 
 * an error and return <code>null</code>.
 * 
 * When you run your sketch as an applet you will need to sign it in order to get an input. 
 * 
 * Before you exit your sketch make sure you call the <code>close</code> method 
 * of any <code>AudioInput</code>'s you have received from <code>getLineIn</code>.
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;
color white;
FFT fft;

void setup()
{
  size(512, 200, P2D);
  white = color(255);
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.window(FFT.HAMMING);
  fft.logAverages(10, 3);
  background(0);
}

void draw()
{
  background(0);
  // draw the waveforms
  //for(int i = 0; i < in.bufferSize() - 1; i++)
  //{
  //  stroke((1+in.left.get(i))*50,100,100);
  //  line(i, 50 + in.left.get(i)*50, i+1, 50 + in.left.get(i+1)*50);
  //  stroke(white);
  //  line(i, 150 + in.right.get(i)*50, i+1, 150 + in.right.get(i+1)*50);
  //}
  
  //stroke(255);
  // draw the waveforms
  fft.forward( in.mix );
  
  //for(int i = 0; i < fft.specSize(); i++)
  //{
  //  // draw the line for frequency band i, scaling it up a bit so we can see it
  //  line( i, height, i, height - fft.getBand(i)*8 );
  //}
  
  // no more outline, we'll be doing filled rectangles from now
  noStroke();
  
  float centerFrequency = 0;
  float spectrumScale = 4;
  
  // draw the logarithmic averages
  {
    // since logarithmically spaced averages are not equally spaced
    // we can't precompute the width for all averages
    for(int i = 0; i < fft.avgSize(); i++)
    {
      centerFrequency    = fft.getAverageCenterFrequency(i);
      // how wide is this average in Hz?
      float averageWidth = fft.getAverageBandWidth(i);   
      
      // we calculate the lowest and highest frequencies
      // contained in this average using the center frequency
      // and bandwidth of this average.
      float lowFreq  = centerFrequency - averageWidth/2;
      float highFreq = centerFrequency + averageWidth/2;
      
      // freqToIndex converts a frequency in Hz to a spectrum band index
      // that can be passed to getBand. in this case, we simply use the 
      // index as coordinates for the rectangle we draw to represent
      // the average.
      int xl = (int) (i * (width * 1.0 / fft.avgSize()));
      int xr = (int) ((i + 1) * (width * 1.0 / fft.avgSize()));
      
      // if the mouse is inside of this average's rectangle
      // print the center frequency and set the fill color to red
      if ( mouseX >= xl && mouseX < xr )
      {
        fill(255, 128);
        text("Logarithmic Average Center Frequency: " + centerFrequency, 5, height - 25);
        fill(255, 0, 0);
      }
      else
      {
          fill(255);
      }
      // draw a rectangle for each average, multiply the value by spectrumScale so we can see it better
      rect(xl, height, xr - xl, height - fft.getAvg(i)*spectrumScale );
    }
  }
}


void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  super.stop();
}