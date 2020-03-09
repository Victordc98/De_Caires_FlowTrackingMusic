import processing.sound.*;
import processing.video.*;
import gab.opencv.*;

SoundFile basePad;
SoundFile baseArp1;
SoundFile baseArp2;
SoundFile melodyArp1;
SoundFile melodyArp2;


float ampIncrease =0.01;

Capture webcam;

color colorToMatch= color(245, 13, 50);
float tolerance= 8;

int camWidth =  640;   // we'll use a smaller camera resolution, since
int camHeight = 360;   // HD video might bog down our computer

int gridSize =  5;     // the image is divided into regions, and we
// get the average movement in each
OpenCV cv;

float melodyAmp;

void setup() {
  //size(1280, 720);
  fullScreen();
  noCursor();
  
  
  //start webcam
  String[] inputs = Capture.list();
  printArray(inputs);
  if (inputs.length == 0) {
    println("Couldn't detect any webcams connected!");
    exit();
  }
  webcam = new Capture(this, camWidth, camHeight);
  webcam.start();

  // create an instance of the OpenCV library
  cv = new OpenCV(this, camWidth, camHeight);


  // Load a soundfile
  basePad = new SoundFile(this, "BasePad_1.wav");
  baseArp1 = new SoundFile(this, "BaseArp1.wav");
  baseArp2 = new SoundFile(this, "BaseArp2.wav");
  melodyArp1 = new SoundFile(this, "MelodyArp1.wav");
  melodyArp2 = new SoundFile(this, "MelodyArp2.wav");



  // These methods return useful infos about the file
  //println("SFSampleRate= " + backing.sampleRate() + " Hz");
  //println("SFSamples= " + backing.frames() + " samples");
  //println("SFDuration= " + backing.duration() + " seconds");

  // Play the file in a loop
  basePad.play();
  baseArp1.play();
  baseArp2.play();
  melodyArp1.play();
  melodyArp2.play();


  //set starting amplitudes
  basePad.amp(1);
  baseArp1.amp(.02);
  baseArp2.amp(.02);
  melodyArp1.amp(.02);
  melodyArp2.amp(.02);

  frameRate(14);
}      


void draw() {
  

  if (webcam.available()) {
    webcam.read();
    float r=random(100, 200);
    float b=random(80, 230);
    float g=random(10, 50);
    fill(r,g,b, 100);
    rect(0, 0, width, height);

  // draw the image, with a dark overlay (moar sparkle)
    //image(webcam, 0,0, width,height); /line commented out for specifi visual aesthetic 
    
    
    // load the frame into OpenCV and calculate the
    // optical flow
    cv.loadImage(webcam);
    cv.calculateOpticalFlow();

    // draw flow in the image as circles (larger = more flow)
    fill(#FFD424, 100);
    noStroke();
    float avgFlow=0;
    int flowCnt=0;
    for (int y=gridSize; y<camHeight-gridSize; y+=gridSize) {
      for (int x=gridSize; x<camWidth-gridSize; x+=gridSize) {

        // get the average flow in this grid square
        PVector flow = cv.flow.getAverageFlowInRegion(x, y, gridSize, gridSize);
        flow.mult(0.5);     // value too large for drawing, reduce by 1/2

        // use the length (magnitude) of the flow line to set the circle diameter
        // if it's not large enough, skip it
        float dia = flow.mag(); 
        //println(flow.x);
        if (dia > 3) {

          // convert from camera dimensions to the larger screen dimensions
          // add some randomness too, to break the grid
          float nx = map(x, 0, webcam.width, 0, width) + random(gridSize);
          float ny = map(y, 0, webcam.height, 0, height) + random(gridSize);
          ellipse(nx, ny, dia, dia);

          //map the amplitude of certain audio flies to the circles
        } 
        avgFlow+=flow.y;
        flowCnt++;
        
      }
    }
    
    //change the amplitudes of sound files of based on position
    melodyAmp+=constrain(avgFlow/flowCnt*.3, -.2, .2);
    melodyAmp=constrain(melodyAmp, 0.01, 1);
    melodyArp1.amp(melodyAmp);
    melodyArp2.amp(melodyAmp);
    baseArp1.amp(1-melodyAmp);
    baseArp2.amp(1-melodyAmp);
    println(melodyAmp);
  }
}
