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

import controlP5.*;

Minim minim;
AudioInput in;
FFT fft;
ControlP5 cp5;

SignalFrame signalFrame;
RawFFTFrame rawFFTFrame;
HistographFrame histographFrame;

long frameTimeNs;
long frameTimeCheckpointNs = -1;
int numFramesCheckpoint = -1;
float currentFrameRate = Float.NaN;

void setup()
{
  
  //cp5 = new ControlP5(this);
  //cp5.setAutoDraw(false);
 
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.window(FFT.HAMMING);
  fft.logAverages(10, 3);
  background(0);
  
  signalFrame = new SignalFrame(this, 512, 200, "Audio Signal");
  rawFFTFrame = new RawFFTFrame(this, 512, 200, "Raw FFT");
  histographFrame = new HistographFrame(this, 512, 200, "Histograph");
}

void settings() {
  size(512, 200, P2D);
}

void draw()
{
  frameTimeNs = System.nanoTime();
  
  if (frameTimeNs - frameTimeCheckpointNs > 500000000) {
    int numFrames = frameCount;
    if (frameTimeCheckpointNs != -1) {
      currentFrameRate = (numFrames - numFramesCheckpoint) * 1.0 / (frameTimeNs - frameTimeCheckpointNs) * 1e9;
    }
    frameTimeCheckpointNs = frameTimeNs;
    numFramesCheckpoint = numFrames;
  }
  
  background(0);
  
  fft.forward(in.mix);
  //cp5.draw();
  
  noStroke();

  float centerFrequency = 0;
  float spectrumScale = 2;
  
  // draw the logarithmic averages
  {
    // since logarithmically spaced averages are not equally spaced
    // we can't precompute the width for all averages
    for(int i = 0; i < fft.avgSize(); i++)
    {
      centerFrequency    = fft.getAverageCenterFrequency(i);
      // how wide is this average in Hz?
      //float averageWidth = fft.getAverageBandWidth(i);   
      
      //// we calculate the lowest and highest frequencies
      //// contained in this average using the center frequency
      //// and bandwidth of this average.
      //float lowFreq  = centerFrequency - averageWidth/2;
      //float highFreq = centerFrequency + averageWidth/2;
      
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
        text("Logarithmic Average Center Frequency: " + centerFrequency, 5, 25);
        fill(255, 0, 0);
      }
      else
      {
          fill(255);
      }
      // draw a rectangle for each average, multiply the value by spectrumScale so we can see it better
      rect(xl, height - fft.getAvg(i)*spectrumScale, xr - xl, fft.getAvg(i)*spectrumScale );
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

public class AbstractFrame extends PApplet {
  int width, height;
  PApplet parent;
  ControlP5 cp5;

  public AbstractFrame(PApplet _parent, int _w, int _h, String _name) {
    super();   
    parent = _parent;
    width=_w;
    height=_h;
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }
  
  public void settings() {
    size(width, height);
  }
}

public class RawFFTFrame extends AbstractFrame {
  public RawFFTFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
  }
  
  public void draw() {
    background(0);
    stroke(255, 0, 0);
    //draw the waveforms
    
    for(int i = 0; i < fft.specSize(); i++)
    {
      // draw the line for frequency band i, scaling it up a bit so we can see it
      line( i, height, i, height - fft.getBand(i)*8 );
    }
  }
}

public class SignalFrame extends AbstractFrame {
  
  public SignalFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
  }
  
  public void draw() {
    background(0);

     // draw the waveforms
    for(int i = 0; i < in.bufferSize() - 1; i++)
    {
      stroke((1+in.left.get(i))*50,100,100);
      line(i, 50 + in.left.get(i)*50, i+1, 50 + in.left.get(i+1)*50);
      stroke(color(255, 255, 255));
      line(i, 150 + in.right.get(i)*50, i+1, 150 + in.right.get(i+1)*50);
    }
    
    // NaN check
    if (currentFrameRate == currentFrameRate) {
      fill(200, 70, 70);
      text("" + nf(currentFrameRate, 2, 1) + " FPS", 5, 25);
    }
  }
}
  
public class HistographFrame extends AbstractFrame {

  float[] volume;
  int currentIndex = 0;
  float scale = 1;
  
  public HistographFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
    
    volume = new float[_w];
  }
  
  public void draw() {
    background(0);
    
    if (currentIndex == volume.length) {
      reset();
    }
    
    volume[currentIndex] = getVolume();
    if (scale * volume[currentIndex] > height - 20) {
      scale = (height - 20) / volume[currentIndex];
    }

    for(int i = 0; i < volume.length - 1; i++)
    {
      if (i >= currentIndex) {
        break;
      }
      stroke(((int) (volume[i] * scale)) % 256, 100, 100);
      line(i, height - (volume[i] * scale) - 10, i + 1, height - (volume[i + 1] * scale) - 10);
    }
    
    currentIndex++;
  }
  
  void reset() {
    for (int i = 0; i < volume.length; i++) {
      volume[i] = 0;
    }
    currentIndex = 0;
  }
  
  float getVolume() {
    float sum = 0;
    for (int i = 0; i < fft.avgSize(); i++) {
      sum += fft.getAvg(i);
    }
    return sum;
  }
}