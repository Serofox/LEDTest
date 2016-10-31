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

SignalFrame signalFrame;
RawFFTFrame rawFFTFrame;
HistographFrame histographFrame;
MultiHistographFrame multiHistographFrame;
ControlFrame controlFrame;

long frameTimeNs;
long frameTimeCheckpointNs = -1;
int numFramesCheckpoint = -1;
float currentFrameRate = Float.NaN;

float freqFilterLog = log(40000);

public void setup()
{
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.STEREO);
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.window(FFT.HAMMING);
  fft.logAverages(10, 3);
  background(0);
  
  //signalFrame = new SignalFrame(this, 512, 200, "Audio Signal");
  //rawFFTFrame = new RawFFTFrame(this, 512, 200, "Raw FFT");
  //histographFrame = new HistographFrame(this, 512, 200, "Histograph");
  multiHistographFrame = new MultiHistographFrame(this, 257 * 3, 257 * 3, "Histograph");
  //controlFrame = new ControlFrame(this, 170, 200, "Controls");
}

public void settings() {
  size(512, 200, P2D);
}

public void draw()
{
  frameTimeNs = System.nanoTime();
  
  if (frameTimeNs - frameTimeCheckpointNs > 500000000) {
    int numFrames = frameCount;
    if (frameTimeCheckpointNs != -1) {
      currentFrameRate = (numFrames - numFramesCheckpoint) * 1.0f / (frameTimeNs - frameTimeCheckpointNs) * 1e9f;
    }
    frameTimeCheckpointNs = frameTimeNs;
    numFramesCheckpoint = numFrames;
  }
  
  background(0);
  
  fft.forward(in.mix);
  
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
      int xl = (int) (i * (width * 1.0f / fft.avgSize()));
      int xr = (int) ((i + 1) * (width * 1.0f / fft.avgSize()));
      
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

public void stop()
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
      text("" + nf(currentFrameRate, 2, 1) + " FPS", 10, 10);
    }
  }
}

public static float avg(float[] vals) {
  return avg(vals, 0, vals.length);
}

public static float avg(float[] vals, int startIndex, int endIndex) {
  float sum = 0;
  for (int i = startIndex; i < endIndex; i++) {
    sum += vals[i];
  }
  return sum / (endIndex - startIndex);
}

public static float std(float[] vals) {
  return std(vals, 0, vals.length);
}

public static float std(float[] vals, int startIndex, int endIndex) {
  float avg = avg(vals, startIndex, endIndex);
  float sum = 0;
  for (int i = startIndex; i < endIndex; i++) {
    sum += (vals[i] - avg) * (vals[i] - avg);
  }
  return (float) Math.sqrt(sum / (endIndex - startIndex));
}

public abstract class Canvas {
  
  PApplet parent;
  int x, y, width, height;
  
  public Canvas(PApplet parent, int x, int y, int w, int h) {
    this.parent = parent;
    this.x = x;
    this.y = y;
    width = w;
    height = h;
  }
  
  public abstract void draw();
  
  public void line(float x1, float y1, float x2, float y2) {
    parent.line(x1 + x, y1 + y, x2 + x, y2 + y);
  }
  
  public void rect(float x1, float y1, float w, float h) {
    parent.rect(x1 + x, y1 + y, w, h);
  }
  
  public void background(int c) {
    parent.fill(c);
    parent.stroke(c);
    parent.rect(x, y, width, height);
  }
  
  public void text(String s, float x1, float y1) {
    parent.text(s, x1 + x, y1 + y);
  }
  
  public void stroke(int a, int b, int c) {
    parent.stroke(a, b, c);
  }
  
  public void stroke(int a, int b) {
    parent.stroke(a, b);
  }
  
  public void stroke(int a) {
    parent.stroke(a);
  }
  
  public void fill(int a, int b, int c) {
    parent.fill(a, b, c);
  }
  
  public void fill(int a, int b) {
    parent.fill(a, b);
  }
  
  public void fill(int a) {
    parent.fill(a);
  }
  
  public void noStroke() {
    parent.noStroke();
  }
  
  public void noFill() {
    parent.noFill();
  }
}

public class CanvasFrame extends AbstractFrame {
  
  ArrayList<Canvas> canvases = new ArrayList<Canvas>();
  
  public CanvasFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
  }
  
  public void draw() {
    for (Canvas c : canvases) {
      c.draw();
    }
  }
  
  public void addCanvas(Canvas c) {
    canvases.add(c);
  }
}

public class HistographCanvas extends Canvas {
  
  static final int FRAMES_PER_SECOND = 60;
  static final float ROLLING_LENGTH_SEC = .5f;
  static final int ROLLING_LENGTH_DATA_POINTS = (int) (FRAMES_PER_SECOND * ROLLING_LENGTH_SEC);
  
  float[] volume;
  boolean[] inPeak;
  float[] rollingVolume;
  float[] avgOverTime;
  float[] stdOverTime;
  int currentIndex = 0;
  int ticks = 0;
  float scale = 1;
  float freqFilter;
  int startFFTIndex;
  int endFFTIndex;
  
  public HistographCanvas(PApplet parent, int x, int y, int w, int h, int startFFTIndex, int endFFTIndex) {
    super(parent, x, y, w, h);
    this.startFFTIndex = startFFTIndex;
    this.endFFTIndex = endFFTIndex;
    
    volume = new float[w];
    inPeak = new boolean[w];
    avgOverTime = new float[w];
    stdOverTime = new float[w];
    rollingVolume = new float[ROLLING_LENGTH_DATA_POINTS];
  }
  
  public void draw() {
    background(0);
    
    if (inPeak[(currentIndex - 1 + inPeak.length) % inPeak.length]) {
      stroke(250, 100, 100);
    } else {
      stroke(50, 25 * endFFTIndex, 25 * endFFTIndex);
    }
    rect(0, 0, width, height);
    noFill();
    
    freqFilter = exp(freqFilterLog);
    
    if (currentIndex == volume.length) {
      reset();
    }
    
    float avg, std;
    boolean canDetectPeaks = ticks >= ROLLING_LENGTH_DATA_POINTS;
    if (canDetectPeaks) {
      avg = avg(rollingVolume);
      std = std(rollingVolume);
    } else if (ticks == 0) {
      avg = std = 0;
    } else {
      avg = avg(rollingVolume, 0, ticks);
      std = std(rollingVolume, 0, ticks);
    }
    
    avgOverTime[currentIndex] = avg;
    stdOverTime[currentIndex] = std;
    
    float currentVolume = rollingVolume[ticks % rollingVolume.length] = volume[currentIndex] = getVolume();
    if (scale * currentVolume > height - 20) {
      scale = (height - 20) / currentVolume;
    }

    if (canDetectPeaks) {
      inPeak[currentIndex] = currentVolume >= avg + std;
    }

    for(int i = 0; i < volume.length - 1; i++)
    {
      if (i >= currentIndex) {
        break;
      }
      
      //
      // Draw Volume
      //
      
      stroke(((int) (volume[i] * scale)) % 256, 100, 100);
      line(i, getYCoord(volume[i]), i + 1, getYCoord(volume[i + 1]));
      
      //
      // Draw moving avg/std
      //
      
      stroke(100, 100, 200);
      line(i, getYCoord(avgOverTime[i]), i + 1, getYCoord(avgOverTime[i + 1]));
      stroke(100, 200, 100);
      line(i, getYCoord(stdOverTime[i] + avgOverTime[i]), i + 1, getYCoord(stdOverTime[i + 1] + avgOverTime[i + 1]));
      
      //
      // Draw beats
      //
      
      if (inPeak[i]) {
        stroke(250, 50, 50);
        line(i, height - 10, i, height - 6);
      }
    }
    
    currentIndex++;
    ticks++;
    
    //
    // Print spectrum range shown
    //
    
    float lowFreq = fft.getAverageCenterFrequency(startFFTIndex) - fft.getAverageBandWidth(startFFTIndex) / 2;
    float hiFreq = fft.getAverageCenterFrequency(endFFTIndex) - fft.getAverageBandWidth(endFFTIndex) / 2;
    
    fill(70, 70, 70);
    text("" + (int) lowFreq + "-" + (int) hiFreq + " Hz", 10, 20);
  }
  
  public void reset() {
    for (int i = 0; i < volume.length; i++) {
      volume[i] = 0;
    }
    currentIndex = 0;
  }
  
  public float getVolume() {
    float sum = 0;
    for (int i = startFFTIndex; i < endFFTIndex; i++) {
      //if (fft.getAverageCenterFrequency(i) <= freqFilter) {
        sum += fft.getAvg(i);
      //}
    }
    return sum;
  }
  
  public float getYCoord(float value) {
    return height - (value * scale) - 10;
  }
}

public class MultiHistographFrame extends CanvasFrame {
  
  public MultiHistographFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
  }
  
  public void setup() {
    int rows = 3;
    int cols = 3;
    
    for (int i = 0; i < rows * cols; i++) {
      addCanvas(new HistographCanvas(this, (i / rows) * width / cols, i % rows * height / rows, width / cols - 1, height / rows - 1, i * 3, (i + 1) * 3));
    }
    
    //addCanvas(new HistographCanvas(this, 0, 0, width / 2, height / 5, 0, 3));
    //addCanvas(new HistographCanvas(this, 0, height / 5, width / 2, height / 5, 3, 6));
    //addCanvas(new HistographCanvas(this, 0, 2 * height / 5, width / 2, height / 5, 6, 9));
    //addCanvas(new HistographCanvas(this, 0, 3 * height / 5, width / 2, height / 5, 9, 12));
    //addCanvas(new HistographCanvas(this, 0, 4 * height / 5, width / 2, height / 5, 12, 15));
    
    //addCanvas(new HistographCanvas(this, width / 2, 0, width / 2, height / 5, 15, 18));
    //addCanvas(new HistographCanvas(this, width / 2, height / 5, width / 2, height / 5, 18, 21));
    //addCanvas(new HistographCanvas(this, width / 2, 2 * height / 5, width / 2, height / 5, 21, 24));
    //addCanvas(new HistographCanvas(this, width / 2, 3 * height / 5, width / 2, height / 5, 24, 27));
    //addCanvas(new HistographCanvas(this, width / 2, 4 * height / 5, width / 2, height / 5, 27, 30));
  }
}
  
public class HistographFrame extends CanvasFrame {
  
  public HistographFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
  }
  
  public void setup() {
    addCanvas(new HistographCanvas(this, 0, 0, width, height, 0, fft.avgSize()));
  }
}

public class ControlFrame extends AbstractFrame {
  
  ControlP5 cp5;
  
  public ControlFrame(PApplet _parent, int _w, int _h, String _name) {
    super(_parent, _w, _h, _name);
  }
  
  public void setup() {
    surface.setLocation(10, 10);
    cp5 = new ControlP5(this);
       
    cp5.addKnob("Filter to Freq (log)")
       .plugTo(parent, "freqFilterLog")
       .setPosition(10, 10)
       .setSize(150, 150)
       .setRange(log(10), log(40000))
       .setValue(log(40000));
  }
  
  public void draw() {
    background(0);
  }
}