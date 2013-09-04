mats
====
Microgrid Array Tools - a pipeline for processing microscope time lapse movies made using microgrids.

About MATS
==========

MATS stands for Microgrid Array Tools and is software written in MATLAB to process time lapse microscopy experiments. While there's other software out there that can do this, notably http://www.cellprofiler.org/, MATS has some features specific to our needs that we find useful. In particular MATS has the following:


* Support for automatic recognition and use of microgrids from Microsurfaces:
http://www.microsurfaces.com.au/
There are three different algorithms which can use the transmission image to find grid boundaries. Depending on imaging mode and grid style, one of them usually works. 


* MATS works well with the files produced by Axiovision
http://microscopy.zeiss.com/microscopy/en_de/downloads/axiovision.html
We've been using a Zeiss Axiovert 200m with Axiovision. It may not work so well with other microscope software but I'm happy to put in changes should there be demand. 


* Support for spectral unmixing
We've been using the Zeiss Colibri illumination with a quad-band filter block
http://www.semrock.com/SetDetails.aspx?id=2740
and use MATS to unmix adjacent channels.


* Support for automatic position setting
Setting positions that covers all the grids is a painful task. Karl Dudfield (thanks Karl!) has written something that automates it, including doing interpolation of the focus to account for a non-level slide/plate holder or uneven grids. PositionSetter also works with the Deltavision microscope's position files. If there is demand, it can possibly be modified to work with other microscopes.


* Support for measurement of FUCCI cell cycle reporter proteins. 
http://www.ncbi.nlm.nih.gov/pubmed/18267078
This code is being released partly in support of a paper using FUCCI cells. We have used it to measure and fit a functional form to fluorescence in order to infer cell cycle times (also done in MATS).


* Support for multi-threading and GPU acceleration
You can optionally use as many cores on your local machine as the MATLAB parallel toolbox will support (8-12 from memory). Additionally, if you have a CUDA compatible GPU, some operations are sped up considerably - although the benefit from this quickly disappears if you have too many threads running because the bus gets saturated.


* Generation of position specific background images. 
MATS uses all the images in a stack to try and find the background. This only works if the cells are motile and take up only a small proportion of the image. If it does work though, it removes fluctuations in background fluorescence due to the grids or anything that is stuck to them. This is useful for fluorescence measurement and segmentation.


* Support for image registration to account for misalignment at successive time points. 
Wear on the stage we use means that it doesn't always return to exactly the same position. MATS aligns all the image in a stack - mainly to support generation and use of the background image but also to make movies easier to look at.


* Support for avisynth. 
I use avisynth and VirtualDub to look at the movies that MATS makes.
http://avisynth.org/mediawiki/Main_Page
http://www.virtualdub.org/
Avisynth is useful because it can do compositing on-the-fly which minimises the amount of video that needs to be pre-stored. It can also do various other editing functions that are useful for presentations.


My intention is to put in the changes needed to make MATS run in Octave. I'm not sure when this will happen but, again, if there is demand I can adjust the priority accordingly.


Finally, there is some other code and data being released which is specific to the forthcoming paper (as opposed to MATS which has been and will be used more generally). This material is from Andrey Kan and has been put here:


https://github.com/hodgkinlab/fuccipaper




John Markham


4/9/2012



