/*
BVH Reconstruction using GHIK Tree for multiple end effectors

This example shows the performance of the IK Solver when reconstructing the motion of an Articulated Body from a .bvh file.
Several experiments were conducted using The Tree Bones Zoo Free Pack:
  - visit https://gumroad.com/truebones/p/free-truebones-zoo-over-75-animals-and-animations.
  - It will ask for a method of Payment but, you can omit this using the freecode: truebones4freefree.
You can also use any bhv file, for instance: 
  - SFU Motion Capture Database -- Available at -- http://mocap.cs.sfu.ca/
  - CMU mocap dataset in bvh format -- Available at -- https://github.com/una-dinosauria/cmu-mocap
  
  
Two Skeletons are shown, the white one represents the original motion, the green one is the reconstructed motion using IK. If desired, you can setup the heuristic to use.

Press 'w' to start/stop the bvh animation and solve IK. 
Drag with right and left mouse buttons to translate, rotate the eye scene. Scroll to zoom in/out.
*/

import nub.core.*;
import nub.core.constraint.*;
import nub.ik.animation.Skeleton;
import nub.ik.loader.bvh.BVHLoader;
import nub.ik.solver.GHIK;
import nub.primitives.*;
import nub.processing.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.Collection;
import java.util.Collections;

//Customizable parameters-------------------------------------------------------------------------
//Reference here a BVH File (the bvh file must be located in the same place this sketch is) 
/*
These example paths does not include the BVH files from the True Bones Zoo Pack as redistribution is not allowed. However, you could download and locate them within the sketch folder.
*/

//Human bvh files
String[] example_paths = new String[]{
  "human/1.bvh",
  "human/2.bvh",
  "human/3.bvh",
  "human/4.bvh",
  "human/5.bvh",
  "human/6.bvh",
  "human/7.bvh",
  "human/8.bvh", 
}; 

String path = example_paths[0];

//The heuristic mode defines the kind of algorithm to use most common options are:
/*
  Choose among these solvers: 
    * GHIK.HeuristicMode.CCD
    * GHIK.HeuristicMode.TIK
    * GHIK.HeuristicMode.TRIK
    * GHIK.HeuristicMode.BFIK
 Preferred heuristic is BFIK.
*/
GHIK.HeuristicMode mode = GHIK.HeuristicMode.BFIK;
//---------------------------------------------------------------------------------------------------

Scene scene;
BVHLoader loader;
Skeleton IKSkeleton;
boolean readNext = false, solve = false;
List<String> names = new ArrayList<String>();
List<Float> errorPerFrame = new ArrayList<Float>();
List<Float> accumulatedError = new ArrayList<Float>();
Collection<Integer> indices;
boolean usePositionError = true;
boolean drawAvgError = true;
boolean showInfo = true;
boolean showParams = false, useWristAnkles = true;
float skeletonHeight = 0;
float avg_error = 0;
int skip = 1;

public void settings(){
    fullScreen(P3D);
}

public void setup(){
    PFont myFont = createFont("Times New Roman Bold", 50, true);
    textFont(myFont);

    Scene._retainedBones = false; //Set this line to false for a better appeareance (as it renders in immediate mode, the sketch run slower)...
    //1. Setup Scene
    scene = new Scene(this);
    scene.setType(Graph.Type.ORTHOGRAPHIC);
    scene.eye().rotate(new Quaternion(0,0, PI));
    //2. Instantiate loader
    loader = new BVHLoader((sketchPath() + "/" + path), scene, null);
    humanoidEFFs(loader);
    
    //Skip first two postures (idle pose)
    loader.nextPosture(true);
    loader.nextPosture(true);
    skeletonHeight = calculateHeight(loader);
    scene.setBounds(skeletonHeight * 3);
    scene.fit(0);
    
    loader.generateConstraints();
    loader.skeleton().setRadius(scene.radius() * 0.01f);
    loader.skeleton().setBoneWidth(scene.radius() * 0.01f);
    loader.skeleton().setColor(color(0,0,255));
    loader.skeleton().setDepth(true);
    
   
    //Move the loader skeleton to the left
    //3. Create an IK Solver
    IKSkeleton = loader.skeleton().get(); //Generate a copy
    //IKSkeleton2.disableConstraints();
    IKSkeleton.setColor(color(0,255,0));
    IKSkeleton.setDepth(true);
    IKSkeleton.setTargetRadius(scene.radius() * 0.02f);
    IKSkeleton.setRadius(scene.radius() * 0.01f);
    IKSkeleton.setBoneWidth(scene.radius() * 0.01f);
    
    IKSkeleton.enableIK(mode);
    IKSkeleton.enableDirection(true, true); //Enable - Disable target direction.
    IKSkeleton.setMaxError(0.001f * skeletonHeight);
    IKSkeleton.addTargets();
    //Relocate the skeletons
    
    //loader.skeleton().reference().translate(0,0,-skeletonHeight * 2f);
    //IKSkeleton.reference().translate(0,0,skeletonHeight * 2f);
    
    //4. Set scene
    scene.setBounds(skeletonHeight * 3);
    scene.fit(0);
    scene.enableHint(Graph.BACKGROUND | Graph.AXES);
    toggleHints();
    //loader.skeleton().cull(true); //uncomment this line if you dont want to show the original animation
    //IKSkeleton.enableIK(false); //Disable IK Task as it is called explicitly
}

public void draw(){
    ambientLight(102, 102, 102);
    lightSpecular(204, 204, 204);
    directionalLight(102, 102, 102, 0, 0, -1);
    specular(255, 255, 255);
    shininess(10);
    scene.render();
    scene.beginHUD();
    if(showInfo) {
        drawTimeArray(errorPerFrame, 0, height - height / 4, width, height / 4, drawAvgError ? 50 : errorPerFrame.size(), usePositionError ? skeletonHeight * 0.2f : PI / 4, skeletonHeight);
        if (!drawAvgError)
            pickFromPane(indices, 0, height - height / 4, width, height / 4, errorPerFrame.size(), usePositionError ? skeletonHeight * 0.2f : PI / 4);
        else
            highlightWorst(indices, 0.8f * width, 0.1f * height, 0.2f * width, 3f / 4f * height - 0.2f * height, skeletonHeight);
    }
    drawInfo(10, 0.1f * height, 0.2f * width, 3f / 4f * height - 0.2f * height);
    scene.endHUD();
    if(readNext) readNextPosture(skip);
}

public void keyPressed(){
    if(key == 'W' || key == 'w'){
        readNext = !readNext;
    }
    if(key == 'S' || key == 's'){
        readNextPosture(skip);
    }
}

public void mouseMoved(){
    scene.mouseTag();
}

public void mouseDragged(){
    if(mouseButton == LEFT){
        scene.mouseSpin();
    } else if(mouseButton == RIGHT){
        scene.mouseTranslate();
    } else{
        scene.scale(scene.mouseDX());
    }
}

public void mouseWheel(MouseEvent event){
    scene.scale(event.getCount() * 20);
}

public void mouseClicked(MouseEvent event){
    if(event.getCount() == 2)
        if(event.getButton() == LEFT)
            scene.focus();
        else
            scene.align();
}

public void readNextPosture(int skip){
    for(int i = 0; i < skip; i++)
        loader.nextPosture();
    //move the root of the skeleton
    for(int i = 0; i < loader.skeleton().reference().children().size(); i++){
        Node skeletonRoot = loader.skeleton().reference().children().get(i);
        Node root = IKSkeleton.joint(loader.skeleton().jointName(skeletonRoot));
        Constraint c = root.constraint();
        root.setConstraint(null);
        root.setTranslation(skeletonRoot.translation().get());
        root.setRotation(skeletonRoot.rotation().get());
        root.setConstraint(c);
    }

    for(Node skNode : loader.skeleton().BFS()){
        Node node = IKSkeleton.joint(loader.skeleton().jointName(skNode));
        Constraint c = node.constraint();
        node.setConstraint(null);
        node.setTranslation(skNode.translation().get());
        node.setConstraint(c);
    }


    //Set the targets
    for(Map.Entry<String, Node> entry : IKSkeleton.targets().entrySet()){
        Node desired =  loader.skeleton().joint(entry.getKey());
        //EFF own rotation is known
        //skeleton.joint(entry.getKey()).setRotation(desired.rotation().get());
        entry.getValue().setTranslation(loader.skeleton().reference().location(desired));
        entry.getValue().setOrientation(loader.skeleton().reference().displacement(new Quaternion(), desired));
    }
    IKSkeleton.IKStatusChanged();
    IKSkeleton.solveIK();
    if(drawAvgError){
        errorPerFrame.add(usePositionError ? avgPositionDistance() : avgRotationDistance());
        avg_error += avgPositionDistance();
        if(usePositionError) positionDistancePerJoint(accumulatedError);
        else rotationDistancePerJoint(accumulatedError);
        indices = sortIndices();
    } else{
        errorPerFrame = usePositionError ? positionDistancePerJoint(accumulatedError) : rotationDistancePerJoint(accumulatedError);
        indices = sortIndices();
    }
}


//Some useful functions
float calculateHeight(BVHLoader parser){ //calculates the height of the skeleton
    Vector min = new Vector(Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE);
    Vector max = new Vector(-Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE);;
    for(Node n : parser.skeleton().joints().values()){
        //Vector pos = parser.skeleton().reference().children().get(0).location(n);
        Vector pos = n.position().get();
        if(max.x() < pos.x()) max.setX(pos.x());
        if(max.y() < pos.y()) max.setY(pos.y());
        if(max.z() < pos.z()) max.setZ(pos.z());
        if(min.x() > pos.x()) min.setX(pos.x());
        if(min.y() > pos.y()) min.setY(pos.y());
        if(min.z() > pos.z()) min.setZ(pos.z());
    }
    float mX = max.x() - min.x();
    float mY = max.y() - min.y();
    float mZ = max.z() - min.z();
    return mY;
}

//Draw error at each Frame
public List<Float> positionDistancePerJoint(List<Float> accum){
    List<Float> error = new ArrayList<Float>();
    Skeleton real = loader.skeleton();
    Skeleton computed = IKSkeleton;
    float dist = 0;
    int i = 0;
    boolean first = accum.isEmpty();
    for (String name : real.names().values()) {
        dist = Vector.distance(real.joint(name).position(), computed.joint(name).position());
        error.add(dist);
        if(first){
            names.add(name);
            accum.add(dist);
        } else{
            accum.set(i, accum.get(i) + dist);
        }
        i++;
    }
    return error;
}


public List<Float> rotationDistancePerJoint(List<Float> accum){
    List<Float> error = new ArrayList<Float>();
    Skeleton real = loader.skeleton();
    Skeleton computed = IKSkeleton;
    float dist = 0;
    int i = 0;
    boolean first = accum.isEmpty();
    for (String name : real.names().values()) {
        dist = quaternionDistance(real.joint(name).rotation(), computed.joint(name).rotation());
        error.add(dist);
        if(first){
            names.add(name);
            accum.add(dist);
        } else{
            accum.set(i, accum.get(i) + dist);
        }
        i++;
    }
    return error;
}

public Collection<Integer> sortIndices(){
    Map<Float, Integer> map = new TreeMap<Float, Integer>(Collections.reverseOrder());
    for (int i = 0; i < accumulatedError.size(); ++i) {
        map.put(accumulatedError.get(i), i);
    }
    return map.values();
}

public void drawInfo(float x, float y, float w, float h){
    int k = 0;
    int n = 8;
    pushStyle();
    textAlign(LEFT, CENTER);
    fill(255);
    float y_col = y + k++ * (1.f * h / (n + 1));
    textSize(24);
    text("Height: " + String.format("%.2f", skeletonHeight / skeletonHeight * 100), x + 10, y_col);
    y_col = y + k++ * (1.f * h / (n + 1));
    fill(0,0,255);
    ellipse(x + 22, y_col + 2, 20, 20);
    fill(255);
    text("Original", x + 44, y_col);
    y_col = y + k++ * (1.f * h / (n + 1));
    fill(0,255,0);
    ellipse(x + 22, y_col + 2, 20, 20);
    fill(255);
    text("Reconstruction", x + 44, y_col);

    y_col = y + k++ * (1.f * h / (n + 1));
    text("# Joints: " + loader.skeleton().joints().size(), x + 10, y_col);
    y_col = y + k++ * (1.f * h / (n + 1));
    text("# End effectors: " + loader.skeleton().endEffectors().size(), x + 10, y_col);
    y_col = y + k++ * (1.f * h / (n + 1));
    float e = IKSkeleton.solvers().get(0).error() / IKSkeleton.endEffectors().size();
    e = Math.max(0, e - 0.001f * skeletonHeight );
    text("Average distance error per end effector: " + String.format("%.2f",  e / skeletonHeight * 100) + "%", x + 10, y_col);




    popStyle();

}

public void highlightWorst(Collection<Integer> indices, float x, float y, float w, float h, float sk_height){
    if(indices == null) return;
    int k = 0;
    int n = 8;
    pushStyle();
    textAlign(LEFT, CENTER);
    fill(255);
    float y_col = y + k++ * (1.f * h / (n + 1));
    textSize(24);
    text("Joints with worst position error: ", x + 10, y_col);
    textSize(20);
    for(int idx : indices){
        if(k == n) break;
        //Draw a line from joint to column
        Node joint = IKSkeleton.joint(names.get(idx));
        Vector v = scene.screenLocation(joint);
        float x_col = x;
        y_col = y + k * (1.f * h / (n + 1));
        stroke(255,0,0);
        strokeWeight(2);
        line(x_col, y_col, v.x(), v.y());
        float e = accumulatedError.get(idx) / errorPerFrame.size();
        e = e / sk_height * 100;
        text(k + " " + names.get(idx) + ": " + String.format("%.2f", e), x_col + 10, y_col);
        k++;
    }
    popStyle();
}


public void pickFromPane(Collection<Integer> indices, float x, float y, float w, float h, int cap, float max_v){
    if(indices == null) return;
    int k = 0;
    for(int idx : indices){
        if(k == 5) break;
        //Draw a line from joint to column
        Node joint = IKSkeleton.joint(names.get(idx));
        Vector v = scene.screenLocation(joint);
        float x_col = x + (idx +0.5f) * w / cap;
        float value = errorPerFrame.get(idx) / max_v;
        float y_col = y + (h - (value) * h);

        stroke(255,0,0);
        strokeWeight(2);
        line(x_col, y_col, v.x(), v.y());
        k++;
    }
}

public float avgPositionDistance(){
    Skeleton real = loader.skeleton();
    Skeleton computed = IKSkeleton;
    float dist = 0;
    for (String name : real.names().values()) {
        dist += Vector.distance(real.joint(name).position(), computed.joint(name).position());
    }
    return dist / real.names().size();
}


public float avgRotationDistance(){
    Skeleton real = loader.skeleton();
    Skeleton computed = IKSkeleton;
    float dist = 0;
    for (String name : real.names().values()) {
        dist += quaternionDistance(real.joint(name).rotation(), computed.joint(name).rotation());
    }
    return dist / real.names().size();
}

public static float quaternionDistance(Quaternion a, Quaternion b) {
    float s1 = 1, s2 = 1;
    if (a.w() < 0) s1 = -1;
    if (b.w() < 0) s2 = -1;
    float dot = s1 * a._quaternion[0] * s2 * b._quaternion[0] + s1 * a._quaternion[1] * s2 * b._quaternion[1] + s1 * a._quaternion[2] * s2 * b._quaternion[2] + s1 * a._quaternion[3] * s2 * b._quaternion[3];
    dot = Math.max(Math.min(dot, 1), -1);
    return (float) (1 - Math.pow(dot, 2));
}


void drawTimeArray(List<Float> serie, float x, float y, float w, float h, int cap, float max_v, float sk_height){
    int n = serie.size();
    int start = cap < n ? n - cap : 0;
    push();
    fill(74, 77, 79);
    rect(x,y, w, h);
    float w_col = w / cap;
    stroke(150);
    max_v = max_v / sk_height * 100;

    for(int i = start; i < n; i++){
        float value = serie.get(i) / sk_height * 100f;
        value = value / max_v;
        float x_cur  = (i - start) * w_col;
        float y_cur = h - (value) * h;
        fill(18, 111, 204);
        rect(x + x_cur, y + y_cur, w_col, h - y_cur );
    }

    int num_ticks = 8;
    textSize(18);
    noLights();
    float ticks_step = 1f / num_ticks;
    for(int i = 1; i < num_ticks; i++){
        float value = (ticks_step * i);
        float x_cur  = x;
        float y_cur = h - (value) * h;
        fill(0);
        text("" + String.format("%.2f", value * max_v), x_cur + 5, y + y_cur);
        stroke(100);
        line(x_cur + 10, y + y_cur, x + w, y + y_cur);
    }

    noLights();
    fill(255);
    textSize(32);
    if(errorPerFrame.size() > 0)
    text("Mean per Joint position error: ( Avg " + String.format("%.2f", (avg_error / sk_height * 100f) / errorPerFrame.size()) + "%)", x, y - 10);
    pop();
}

public void removeChildren(Skeleton sk, Node node){
    while(!node.children().isEmpty()){
        Node child = node.children().get(0);
        removeChildren(sk, child);
        sk.joints().remove(sk.jointName(child));
        sk.names().remove(child);
        child.setReference(null);
        Scene.prune(child);
    }
}


public void removeChildren(BVHLoader loader, String names[]){
    Skeleton sk = loader.skeleton();
    for(String name : names){
        if(sk.joints().containsKey(name) && useWristAnkles) {
            removeChildren(sk, sk.joint(name));
        }
    }
}

public void toggleHints(){
    for(Node n : IKSkeleton.joints().values()){
        if(showParams){
            n.enableHint(Node.AXES);
            n.enableHint(Node.CONSTRAINT);
        } else{
            n.disableHint(Node.AXES);
            n.disableHint(Node.CONSTRAINT);
        }
    }
    for(Node n : loader.skeleton().joints().values()){
        if(showParams){
            n.enableHint(Node.AXES);
            n.enableHint(Node.CONSTRAINT);
        } else{
            n.disableHint(Node.AXES);
            n.disableHint(Node.CONSTRAINT);
        }
    }
    showParams = !showParams;
}

public void obtainEFFS(BVHLoader loader, String names[]){
    Skeleton sk = loader.skeleton();
    for(String name : names){
        if(sk.joints().containsKey(name) && useWristAnkles) {
            Node n = sk.joint(name);
            sk.joints().remove(name);
            sk.names().remove(n);
            n.setReference(null);
            Scene.prune(n);
        }
    }
}

public void humanoidEFFs(BVHLoader loader){
    String names[] = new String[]{"RTHUMB", "RIGHTHANDINDEX1", "LTHUMB", "LEFTTOEBASE", "RIGHTTOEBASE", "LEFTHANDINDEX1", "LEFTFINGERBASE", "RIGHTFINGERBASE"};
    obtainEFFS(loader, names);
}
