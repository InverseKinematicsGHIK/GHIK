# GHIK

GHIK - Generic heuristic Inverse Kinematics is a [Processing](https://processing.org/) library based on [nub](https://github.com/VisualComputing/nub) that allows to test the performance among different IK heuristic algorithms based on [CCD](https://www.tandfonline.com/doi/abs/10.1080/2165347X.2013.823362), [Triangulation](http://ir.canterbury.ac.nz/bitstream/10092/743/1/12607089_ivcnz07.pdf) and [FABRIK](http://andreasaristidou.com/FABRIK.html) to deal with constrained articulated bodies.

**Installation instructions**

1. Download and install [Processing](https://processing.org/download/)
2. Download and extract the [zip file](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/ghik_nub.zip) found in this repository and place it within the "libraries" folder of your Processing sketchbook. To know the Processing sketchbook location open the Preferences window from the Processing application and look for the "Sketchbook location" item at the top. The zip file must be extracted in this location inside the library's folder. If this folder does not exist you must create it (just create an empty folder called "libraries").
3. Restart the Processing application. 
4. Go to File -> Examples -> libraries -> nub and open any of the examples included in the library. Benchmark and BVHReconstruction examples show some of the conducted experiments to test heuristic algorithms performance.

Look at [this video](https://www.youtube.com/watch?v=MMbubxV6SzE) that shows the procedure for libraries installation.

**Important note:** as this library extends [nub](https://github.com/VisualComputing/nub) functionality, there could exists conflicts if a prior version of nub is installed. In such case, please remove the previous version before install this one. 

## Free Truebones Zoo Pack
If you want to use Free Truebones Zoo pack please download it from [here](https://gumroad.com/l/skZMC). 
A minimum amount of $2 usd must be selected, however, when it ask for a method of Payment you can use the freecode: truebones4freefree to download this amazing collection for free.

## Demo videos
**IK benchmark for kinematic chains**

* [Free](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/1Free.mp4)
* [Hinge](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/2Hinge.mp4)
* [Cone](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/3Cone.mp4)
* [Mix](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/4Mix.mp4)

**Mocap reconstruction**

* [Human](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/8Human.mp4)
* [Cat](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/6Cat.mp4)
* [Spider](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/10Spider.mp4)
* [Tyranno](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/11Tyranno.mp4)
* [Monkey](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/9Monkey.mp4)
* [Dragon](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/7Dragon.mp4)

**[Visual smoothness FABRIK vs TRIK](https://github.com/InverseKinematicsGHIK/GHIK/raw/main/videos/5FABRIKvsTRIK1.mp4)**


