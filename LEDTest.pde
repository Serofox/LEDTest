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
import java.util.*;

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
float minStdDev = 3;

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
  histographFrame = new HistographFrame(this, 256 * 2, 256, "Histograph");
  //multiHistographFrame = new MultiHistographFrame(this, 257 * 3, 257 * 3, "Histograph");
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
  
  public void stroke(int a, int b, int c, int d) {
    parent.stroke(a, b, c, d);
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
  
  public void fill(int a, int b, int c, int d) {
    parent.fill(a, b, c, d);
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

public class ArrayDeque<T> {
  
  T[] elements;
  int size = 0;
  int startIndex = 0;
  
  public ArrayDeque() {
    elements = (T[]) new Object[32];
  }
  
  public int size() {
    return size;
  }
  
  public void addLast(T item) {
    sizeCheck();
    int index = (startIndex + size) % elements.length;
    elements[index] = item;
    size++;
  }
  
  public T get(int i) {
    return elements[(startIndex + i) % elements.length];
  }
  
  public void removeFirst() {
    elements[startIndex] = null;
    startIndex = (startIndex + 1) % elements.length;
    size--;
  }
  
  private void sizeCheck() {
    if (size == elements.length) {
      T[] newElements = (T[]) new Object[elements.length * 2];
      System.arraycopy(elements, startIndex, newElements, startIndex, elements.length - startIndex);
      System.arraycopy(elements, 0, newElements, elements.length, startIndex);
      elements = newElements;
    }
  }
}

public class HistographCanvas extends Canvas {
  
  class Peak {
    int maxTick;
    float max;
    int start;
    int end;
    
    public Peak(int maxTick, float max, int start, int end) {
      this.maxTick = maxTick;
      this.max = max;
      this.start = start;
      this.end = end;
    }
  }
  
  class Interval {
    int start;
    int end;
    
    public Interval(int start, int end) {
      this.start = start;
      this.end = end;
    }
  }
  
  class DiffInfo {
    int diff;
    Peak startPeak;
    Peak endPeak;
    
    public DiffInfo(int diff, Peak startPeak, Peak endPeak) {
      this.diff = diff;
      this.startPeak = startPeak;
      this.endPeak = endPeak;
    }
  }
  
  final Comparator<DiffInfo> DIFF_INFO_COMPARATOR = new Comparator<DiffInfo>() {
    int compare(DiffInfo first, DiffInfo second) {
      return first.diff - second.diff;
    }
  };
  
  static final int FRAMES_PER_SECOND = 60;
  static final float ROLLING_LENGTH_SEC = .5f;
  static final float PATTERN_MATCHING_LENGTH_SEC = 5;
  static final int ROLLING_LENGTH_DATA_POINTS = (int) (FRAMES_PER_SECOND * ROLLING_LENGTH_SEC);
  static final int PATTERN_MATCHING_DATA_POINTS = (int) (FRAMES_PER_SECOND * PATTERN_MATCHING_LENGTH_SEC);
  static final int MAX_BPM = 240;
  static final int MIN_BPM = 30;
  static final int MIN_TICKS_BETWEEN_PEAKS = 60 * FRAMES_PER_SECOND / MAX_BPM;
  static final int MAX_TICKS_BETWEEN_PEAKS = 60 * FRAMES_PER_SECOND / MIN_BPM;
  
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
  int currentPeakStartTick;
  ArrayDeque<Peak> peaks = new ArrayDeque<Peak>();
  
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
    
    stroke(10 * endFFTIndex, 50 + 25 * endFFTIndex, 25 * endFFTIndex);
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
    canDetectPeaks = canDetectPeaks && std >= minStdDev;
    
    avgOverTime[currentIndex] = avg;
    stdOverTime[currentIndex] = std;
    
    float currentVolume = rollingVolume[ticks % rollingVolume.length] = volume[currentIndex] = getVolume();
    if (scale * currentVolume > height - 20) {
      scale = (height - 20) / currentVolume;
    }

    boolean wasInPeak = inPeak[(inPeak.length + currentIndex - 1) % inPeak.length];
    inPeak[currentIndex] = canDetectPeaks && currentVolume >= avg + std;
    if (!wasInPeak && inPeak[currentIndex]) {
      currentPeakStartTick = ticks;
    }
    
    if (wasInPeak && !inPeak[currentIndex]) {
      int maxTick = -1;
      float maxVolume = -1;
      int endTick = ticks - 1;
      for (int i = currentPeakStartTick; i <= endTick; i++) {
        int index = (i - (ticks - currentIndex) + width) % width;
        if (volume[index] > maxVolume) {
          maxVolume = volume[index];
          maxTick = i;
        }
      }
      peaks.addLast(new Peak(maxTick, maxVolume, currentPeakStartTick, endTick));
    }
    
    if (peaks.size() > 0 && peaks.get(0).start < ticks - PATTERN_MATCHING_DATA_POINTS) {
      peaks.removeFirst();
    }

    for(int i = 0; i < volume.length - 1 && i < currentIndex; i++)
    { 
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
    }
    
    //
    // Draw beats
    //
    
    stroke(250, 50, 50);
    fill(250, 50, 50);
    
    int minTick = ticks - currentIndex;
    for (int i = 0; i < peaks.size(); i++) {
      Peak peak = peaks.get(i);
      if (peak.start < minTick) {
        continue;
      }
      rect(peak.start - minTick, height - 10, peak.end - peak.start - 1, 4);
    }
    
    if (inPeak[currentIndex]) {
      rect(currentPeakStartTick - minTick, height - 10, ticks - currentPeakStartTick - 1, 4);
    }
    
    DiffInfo[] diffs = new DiffInfo[peaks.size() * peaks.size()];
    int in = 0;
    for (int i = 0; i < peaks.size(); i++) {
      for (int j = i + 1; j < peaks.size(); j++) {
        int diff = peaks.get(j).maxTick - peaks.get(i).maxTick;
        if (diff < MIN_TICKS_BETWEEN_PEAKS) {
          continue;
        }
        if (diff > MAX_TICKS_BETWEEN_PEAKS) {
          break;
        }
        diffs[in] = new DiffInfo(diff, peaks.get(i), peaks.get(j));
        in++;
      }
    }
    
    Arrays.sort(diffs, 0, in, DIFF_INFO_COMPARATOR);
    
    String out = "";
    for (int i = 0; i < in; i++) {
      out += diffs[i].diff + ", ";
    }
    
    //
    // Print spectrum range shown
    //
    
    float lowFreq = fft.getAverageCenterFrequency(startFFTIndex) - fft.getAverageBandWidth(startFFTIndex) / 2;
    float hiFreq = fft.getAverageCenterFrequency(endFFTIndex) - fft.getAverageBandWidth(endFFTIndex) / 2;
    
    fill(70, 70, 70);
    text("" + (int) lowFreq + "-" + (int) hiFreq + " Hz", 10, 20);
    
    text(out, 10, 50);
    
    //if (Math.abs(x - width) < 5 && y == 0) {
    if (true) {
      System.out.println(out);
      List<Interval> beatIntervals = getBeatPattern(diffs, in);
      String intervals = "";
      for (Interval interval : beatIntervals) {
        intervals += "[";
        for (int i = interval.start; i <= interval.end; i++) {
          intervals += diffs[i].diff;
          if (i != interval.end) {
            intervals += ", ";
          }
        }
        intervals += "], ";
      }
      System.out.println(intervals);
      
      if (beatIntervals.size() > 0) {
        float bestAverage = -1;
        DiffInfo bestDiffInfo = null;
        // Find interval with highest avg peak
        for (Interval interval : beatIntervals) {
          float localSum = 0;
          float bestLocalMax = 0;
          DiffInfo bestLocalDiffInfo = null;
          for (int i = interval.start; i <= interval.end; i++) {
            DiffInfo diff = diffs[i];
            float max = (diff.startPeak.max + diff.endPeak.max) / 2;
            localSum += max;
            if (bestLocalDiffInfo == null || max > bestLocalMax) {
              bestLocalDiffInfo = diff;
              bestLocalMax = max;
            }
          }
          // Divide by diffs[interval.start].diff to favor smaller diffs
          float localAvg = localSum / (interval.end - interval.start + 1) / diffs[interval.start].diff;
          if (localAvg > bestAverage) {
            bestDiffInfo = bestLocalDiffInfo;
            bestAverage = localAvg;
          }
        }
        
        stroke(230, 200, 50);
        int start = bestDiffInfo.startPeak.maxTick;
        if (start / width < ticks / width) {
          while (start / width < ticks / width) {
            start += bestDiffInfo.diff;
          }
          start = start % width;
        } else {
          stroke(230, 50, 200, 60);
          line(start % width, 0, start % width, height);
          line(bestDiffInfo.endPeak.maxTick % width, 0, bestDiffInfo.endPeak.maxTick % width, height);
          line(start % width, height / 2, bestDiffInfo.endPeak.maxTick % width, height / 2);
          start = start % width + 2 * bestDiffInfo.diff;
        }
        
        // Forwards
        stroke(230, 200, 50, 80);
        for (int i = 0; i < width - start; i += bestDiffInfo.diff) {
          line(i + start, 0, i + start, height);
        }
        
        // Backwards
        stroke(230, 100, 50, 80);
        for (int i = 3 * bestDiffInfo.diff; start - i > 0; i += bestDiffInfo.diff) {
          line(start - i, 0, start - i, height);
        }
      }
    }
    currentIndex++;
    ticks++;
  }
  
  List<Interval> getBeatPattern(DiffInfo[] diffs, int length) {
    int MAX_DIFF_RANGE = 4;
    int MIN_DIFFS_IN_CLUSTER = 3;
    
    ArrayList<Interval> res = new ArrayList<Interval>();
    if (length == 0) {
      return res;
    }
    
    boolean done = false;
    int prevStart = -1, prevEnd = -1;
    int start = 0, end = 0;
    
    while (!done) {
      while (diffs[end].diff - diffs[start].diff <= MAX_DIFF_RANGE) {
        end++;
        if (end == length) {
          done = true;
          break;
        }
      }
      end--;
      if (end - start >= MIN_DIFFS_IN_CLUSTER) {
        if (start > prevEnd && prevEnd != -1) {
          res.add(new Interval(prevStart, prevEnd));
          prevStart = prevEnd = -1;
        }
        if (end - start > prevEnd - prevStart) {
          prevStart = start;
          prevEnd = end;
        }
      }
      start++;
      end = start;
    }
    if (prevEnd != -1) {
      res.add(new Interval(prevStart, prevEnd));
    }
    
    return res;
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
    //addCanvas(new HistographCanvas(this, 0, 0, width, height, 12, fft.avgSize()));
    addCanvas(new HistographCanvas(this, 0, 0, width, height, 12, 15));
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