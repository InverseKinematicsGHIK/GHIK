/*
Benchmark between IK Heuristics

This example compares the performance in terms of accuracy between different IK heuristics steps using GHIK-Chain.
You can customize several Benchmark parameters as:
*) The number of joints of the IK Chain
*) The Type of chain. we distinguish among:
    - NONE : Unconstrained chain
    - HINGE : Each joint has a random Hinge constraint
    - CONE_ELLIPSE : Each joint has a random reach cone constraint
    - MIX_CONSTRAINED : Each joint has a random constraint.
*) The Type of solvers to use: Add to the solversType array the IK Heuristic step we want to consider. Choose among:
    - CCD : Cyclic Coordinate Descent
    - TIK: Triangulation
    - TRIK: Translate and Reach IK
    - BFIK: Back and Forth IK 
    Preferable solver for unconstrained chain is TRIK, for constrained chains choose BFIK.
    
* Press 'p' to follow a continuous path and 's' to stop the interpolators.
* Press 'w' to start/stop the solvers
* Press 'r' to generate a random Target position
* Drag with the right button the red balls to solve IK.
* Drag with right and left mouse buttons to translate, rotate the eye scene. Scroll to zoom in/out.
* Press ESC to exit.
*/

import nub.core.*;
import nub.ik.solver.*;
import nub.primitives.*;
import nub.core.constraint.*;
import nub.processing.*;
import nub.timing.Task;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

//-------------------------------------------------------------------
//-----------Customizable Benchmark Parameters ----------------------
//-------------------------------------------------------------------
int numJoints = 8; //Define the number of joints that each chain will contain
Util.ConstraintType constraintType = Util.ConstraintType.NONE; //Choose among Util.ConstraintType.NONE, Util.ConstraintType.HINGE, Util.ConstraintType.CONE_ELLIPSE, Util.ConstraintType.MIX_CONSTRAINED
Util.SolverType solversType[] = {Util.SolverType.CCD, Util.SolverType.TIK, Util.SolverType.TRIK, Util.SolverType.BFIK}; //If you wish you could add other Solvers, as the ones listed above
//-------------------------------------------------------------------

//Scene Parameters
ArrayList<Solver> solvers; //Will store Solvers
int randRotation = -1; //Set seed to generate initial random rotations, otherwise set to -1
int randLength = 0; //Set seed to generate random segment lengths, otherwise set to -1
Random random = new Random();
Scene scene;
String renderer = P3D; //Define a 2D/3D renderer
float targetRadius = 10; //Define size of target
float boneLength = 50; //Define length of segments (bones)
ArrayList<ArrayList<Node>> structures = new ArrayList<ArrayList<Node>>(); //Keep Structures
ArrayList<Node> idleSkeleton;
ArrayList<Node> targets = new ArrayList<Node>(); //Keep targets
ArrayList<Interpolator> interpolators = new ArrayList<Interpolator>(); //Interpolators
boolean solve = true;
float chain_length = 0; //chain length


void settings() {
  fullScreen(renderer);
}

void setup() {
    randomSeed(0);
    PFont myFont = createFont("Times New Roman Bold", 50, true);
    textFont(myFont);
    scene = new Scene(this);
    if (scene.is3D()) scene.setType(Graph.Type.ORTHOGRAPHIC);
    scene.setBounds(numJoints * 1f * boneLength);
    scene.leftHanded = false;
    int numSolvers = solversType.length;
    //1. Create Targets
    targets = Util.createTargets(numSolvers, scene, targetRadius);
    float alpha = 1.f * width / height > 1.5f ? 0.5f * width / height : 0.5f;
    alpha *= numSolvers / 4f; //avoid undesirable overlapping
    //2. Generate IK Chains
    chain_length = 0;
    for (int i = 0; i < numSolvers; i++) {
      float offset = numSolvers == 1 ? 0 : i * 2 * alpha * scene.radius() / (numSolvers - 1) - alpha * scene.radius();
      int r = (int) random(255), g = (int) random(255), b = (int) random(255);
      structures.add(Util.generateAttachedChain(scene, numJoints, 0.7f * targetRadius, boneLength, new Vector(offset, 0, 0), color(r, g, b), randRotation, randLength));
    }
    //Calculate height
    chain_length = 0;
    for(int i = 1; i < structures.get(0).size(); i++){
      Node n = structures.get(0).get(i);
      chain_length += Vector.distance(n.position(), n.reference().position());
    }
    println("Height : " + chain_length);

    //3. Apply constraints
    for (ArrayList<Node> structure : structures) {
      Util.generateConstraints(structure, constraintType, 13, scene.is3D());
    }
    idleSkeleton = Util.detachedCopy(structures.get(0)); //Dummy chain
    //4. Set eye scene
    scene.eye().rotate(new Quaternion(new Vector(1, 0, 0), -PI / 2.f));
    //scene.eye().rotate(new Quaternion(new Vector(0, 1, 0), PI));
    //5. generate solvers
    solvers = new ArrayList<Solver>();
    for (int i = 0; i < numSolvers; i++) {
      final Solver solver = Util.createSolver(solversType[i], structures.get(i));
      solvers.add(solver);
      //6. Define solver parameters
      solver.setMaxError(0.001f * chain_length); //Set error threshold
      solver.setMinDistance(0); //Set minimum distance
      solver.setTimesPerFrame(50); //Set number of times per frame the solver will be executed
      solver.setMaxIterations(50); //Ste the maximum iterations the solver will be executed
      if(constraintType != Util.ConstraintType.NONE){
        //Uncomment to swap order from root to end effector and end effector to root at each iteration
        //solver.setSwapOrder(true);
        ((GHIK)solver).enableDeadLockResolution(true);
      }
      //7. Set targets
      solvers.get(i).setTarget(structures.get(i).get(numJoints - 1), targets.get(i));
      targets.get(i).setPosition(structures.get(i).get(numJoints - 1).position());
      //8. Register task
      Interpolator interpolator = new Interpolator(targets.get(i));
      interpolator.configHint(Interpolator.SPLINE);
      interpolators.add(interpolator);
    }

    //Scene hints
    scene.enableHint(Scene.BACKGROUND, 0);
    scene.enableHint(Scene.AXES);
    scene.eye().rotate(new Quaternion(PI/2,0,0));
    scene.fit();

    scene.eye().setConstraint(new Constraint() {
      @Override
      public Quaternion constrainRotation(Quaternion rotation, Node node) {
        return new Quaternion(0,rotation.eulerAngles().y(),0);
      }
    });
}

void draw() {
  lights();
  ambientLight(102, 102, 102);
  lightSpecular(204, 204, 204);
  directionalLight(102, 102, 102, 0, 5, 5);
  specular(255, 255, 255);
  shininess(10);
  for (int i = 0; i < solvers.size(); i++) {
    if (solve) solvers.get(i).solve();
  }
  scene.render();
  scene.beginHUD();
  pushStyle();
  textSize(50);
  fill(255);
  stroke(255);
  textAlign(CENTER, CENTER);
  text("IK Heuristic steps benchmark", width * 0.5f, 100);
  popStyle();

  for (int i = 0; i < solvers.size(); i++) {
    Util.printInfo(scene, solvers.get(i), structures.get(i).get(0).position(), chain_length);
  }
  scene.endHUD();
}


public Node generateRandomReachablePosition(List<? extends Node> chain, boolean is3D) {
  for (int i = 0; i < chain.size() - 1; i++) {
    if (is3D) {
      if (random.nextFloat() > 0.5f) {
        chain.get(i).rotate(new Quaternion(new Vector(0, 0, 1), random.nextFloat() * 2 * PI - PI));
        chain.get(i).rotate(new Quaternion(new Vector(0, 1, 0), random.nextFloat() * 2 * PI - PI));
        chain.get(i).rotate(new Quaternion(new Vector(1, 0, 0), random.nextFloat() * 2 * PI - PI));
      }
    } else
      chain.get(i).rotate(new Quaternion(new Vector(0, 0, 1), (float) (random.nextFloat() * PI)));
  }
  return chain.get(chain.size() - 1);
}

public void generatePath() {
  int idx = 0;
  int seed = (int) (random(0,10000));
  for(Interpolator interpolator : interpolators){
    List<? extends Node> structure = structures.get(idx);
    randomSeed(seed);
    noiseSeed(seed);
    interpolator.clear(); // reset the interpolator
    interpolator.setNode(targets.get(idx++));
    //Generate a random near pose
    Node node = structure.get(structure.size() - 1);
    float maxDist = 0, minDist = Float.MAX_VALUE;
    Vector prev = node.position();
    int n = 100;
    float step = 1f;
    float last = step * n;


    for (float t = 0; t < last; t += step) {
      for (int i = 0; i < structure.size(); i++) {
        float angle = TWO_PI * noise(1000 * i + t) - PI;
        Vector dir = new Vector(noise(10000 * i + t), noise(20000 * i + t), noise(30000 * i + t));
        structure.get(i).setRotation(new Quaternion(dir, angle));
      }
      Node key = new Node(node.position(), node.orientation(), 1.f);
      interpolator.addKeyFrame(key, 512, 0.5);
      Vector curr = node.position();
      if (t != 0) {
        if (Vector.distance(prev, curr) > maxDist) {
          maxDist = Vector.distance(prev, curr);
        }
        if (Vector.distance(prev, curr) < minDist) {
          minDist = Vector.distance(prev, curr);
        }
        n++;
      }
      prev = curr;
    }
  }
}


void keyPressed() {
  if (key == 'w' || key == 'W') {
    solve = !solve;
  }
  if (key == 'R' || key == 'r') {
    Node f = generateRandomReachablePosition(idleSkeleton, scene.is3D());
    Vector delta = Vector.subtract(f.position(), targets.get(0).position());
    for (Node target : targets) {
      target.setPosition(Vector.add(target.position(), delta));
      target.setOrientation(f.orientation());
    }
  }
  if (key == 'i' || key == 'I') {
    for (List<Node> structure : structures) {
      for (Node f : structure) {
        f.setRotation(new Quaternion());
      }
    }
  }

  if (key == 's' || key == 'S') {
    for (Solver s : solvers) s.solve();
  }

  if (key == 'm' || key == 'M') {
    for (Solver s : solvers) {
      if (s instanceof GHIK){
        ((GHIK) s).context().setSingleStep(!((GHIK) s).context().singleStep());
        if(((GHIK) s).context().singleStep())
          s.setTimesPerFrame(1);
      }
    }
  }

  if (key == '0') {
    for (Solver s : solvers) {
      if (s instanceof GHIK){
        ((GHIK) s).context().setOrientationWeight(1);
        ((GHIK) s).context().setDirection(!((GHIK) s).context().direction());
      }
    }
  }

  if (key == 'p' || key == 'P') {
    for (List<Node> structure : structures) {
      for (Node f : structure) {
        f.setRotation(new Quaternion());
      }
    }
    generatePath();
    for(Interpolator interpolator : interpolators){
      interpolator.enableRecurrence();
      interpolator.run(1);
    }
  }

  if(key == 's' || key == 'S'){
    for(Interpolator interpolator : interpolators){
      interpolator.task().stop();
    }
  }


  if (key == '1') {
    for(Interpolator interpolator : interpolators){
      interpolator.toggleHint(Interpolator.SPLINE);
    }
  }
  if (key == '2') {
    for(Interpolator interpolator : interpolators){
      interpolator.setSpeed(interpolator.speed() * 1.2f);
    }
  }
  if (key == '3') {
    for(Interpolator interpolator : interpolators){
      interpolator.setSpeed(interpolator.speed() * 0.8f);
    }
  }
}

void mouseMoved() {
  scene.mouseTag();
}

void mouseDragged() {
  if (mouseButton == LEFT) {
    scene.mouseSpin();
  } else if (mouseButton == RIGHT) {
    if (targets.contains(scene.node())) {
      for (Node target : targets) scene.translateNode(target, scene.mouseDX(), scene.mouseDY(), 0, 0);
    } else {
      scene.mouseTranslate();
    }
  } else {
    scene.scale(scene.mouseDX());
  }
}

void mouseWheel(MouseEvent event) {
  scene.scale(event.getCount() * 20);
}

void mouseClicked(MouseEvent event) {
  if (event.getCount() == 2)
    if (event.getButton() == LEFT)
      scene.focus();
    else
      scene.align();
}
