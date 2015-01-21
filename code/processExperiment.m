% deprecated, use [runCreateThresholded] or [runCreateUnthresh] instead
function processExperiment()
% This is where all the experiment-specific parameters are set.

% TODO: make testGlobReferenceImages() into something which is called from either here or processPositions()
%
% --------------------------
% General
% --------------------------
experimentDetails.profile=0; % uses the profiler if non-zero
experimentDetails.noClobber = 1; % If non-zero, do not overwrite files if the exist.
experimentDetails.threads = 1; % asigned one position to each thread
experimentDetails.useGPU = 0;  % try using it if one is found
experimentDetails.verbose = 1; % Write to screen AND logfiles

% -------------------------------------------------------------------------------
% Directory structure
% -------------------------------------------------------------------------------
% From:
% experimentDir/
%               runDir/
%                      positionDir
% To:
% outputDir/
%            aviavs/
%                   thresholded
%                   unthresholded
%                   binarised
%            offsets
%            tiffs/
%                 runDir/
%                        positionDir
%            masks/
%                 runDir/
%                        positionDir
%            histsDir
%            statsDir
%            welledgesDir
%            cellnumbersDir
%            wellimagesDir
%            welledgesDir
%            welltiffsDir
%            frametimesDir
%            fuccifitsDir
%            fuccicountsDir
%            backgroundsDir
%            logDir
%            mapDir
%            measurementsDir
%            segmentedDir
%            brightnessCorrectionDir
%            annotations
% 
experimentDetails.outputDir = '../outputs/'; % path where all outputs hang off
experimentDetails.backgroundsDir = 'backgrounds/'; % backgrounds and offsets
experimentDetails.aviavsDir = 'unthresholded/'; % movies
experimentDetails.tiffsDir = 'correctedTiffs/'; % pre-processed tiffs
experimentDetails.masksDir = 'masks/'; % masks of foreground area
experimentDetails.histsDir = 'hists/'; % fluorescence histograms for debugging
experimentDetails.statsDir = 'stats/'; % fluorescence stats for debugging
experimentDetails.inputDir = '../data/'; % where the experiment is
experimentDetails.runDir = '20111118-0026/'; % the run for this experiment
experimentDetails.runDirs = {'20111118-0026/','20111118-0027/'}; % all the runs for this experiment in order
experimentDetails.dirPattern = '*).tif_Files'; % how to match files containing images
experimentDetails.logDir = 'log/';
experimentDetails.mapDir = 'map/';
experimentDetails.offsetsDir = 'offsets/';
experimentDetails.welltiffsDir = 'welltiffs/';
experimentDetails.fuccifitsDir = 'fuccifits/';
experimentDetails.fuccicountsDir = 'fuccicounts/';
experimentDetails.segmentedDir = 'segmented/';
experimentDetails.cellnumbersDir = 'cellnumbers/';
experimentDetails.measurementsDir = 'measurements/';
experimentDetails.welledgesDir = 'welledges/';
experimentDetails.frametimesDir = 'frametimes/';
experimentDetails.wellimagesDir = 'wellimages/';
experimentDetails.annotationsDir = 'annotations/';
experimentDetails.brightnessCorrectionDir = 'brightnessCorrection/';
% -----------------------------------------
% Selecting images and time points
% -----------------------------------------
% The time point here means the integer that odnetifies the frame nnumber in a sequence of time lapse frames.
experimentDetails.firstTimePoint = 1; % Start at t=this number. Don't make it 0 or something may break.
experimentDetails.timePointsLimit = 100; % stop at this number of time points if you get there (the images may run out first)
experimentDetails.filenameIncrementsTime = 1; % If non-zero, then the image filename contains the time point
experimentDetails.pattern = '_p000001t%08dz001c%02d.tif';% What is used to make the end of the image filename
experimentDetails.tiles = 1; % if you used mosaiX to tile an area, set this to how many tiles it made. Otherwise = 1

%----------------
% Channel details
%----------------
experimentDetails.channelNumbers = [1 2 4 3]; % What channel numbers appear in axiovision
experimentDetails.channels = 4; % Maximum index into channelNumbers()
experimentDetails.wellDetectionChannel = 3; % usually BF channel. This is an index into channelNumbers()
experimentDetails.labels = {'GFP','RFP','BF2','BF'}; % Should match channels. Index is same as channelNumbers()

%---------------------
% What to measure/plot
%---------------------
experimentDetails.plotChannels = [1 2];
experimentDetails.plotQuantities = {'correctedIntegratedFluoresenceCellAll','correctedIntegratedFluoresenceCellAll'};
experimentDetails.insertRealTimes = 1; % Use times rather than frame number
experimentDetails.measureCorrectedTiffs = 1; % 0 = measure from raw images, 1 = "corrected" images

% ------------------------------------------------------------
% Correcting for camera DC offset (normally additive)
% ------------------------------------------------------------
experimentDetails.cameraMeanBlackLevel = uint16(32); % the DC component that comes out of the camera with no light

% ------------------------------------------------------------
% Correcting for uneven illumination (normally multiplicative)
% ------------------------------------------------------------
% This may require pre-building an image that represents the optics for the experiment
%
% Method for applying correction image:
% '0'   do nothing - for testing
% '*' multiply
% '/' divide
% '+' add
% '-' subtract, set negative pixels to zero
% '_' subtract and set what looks like noise (the lowest proportionBackground) to zero
% 'a' subtract but take abs of result
% '^' subtract but square the result
% '4' subtract but ^4 the result
%
% Methods of scaling the result
% 'minmax' - stretch so that minimum and maximum pixel values go between 0 and 65535
% 'median' - set the median pixel equal to brightnessCorrectionMedian
% a number (eg 65535) - multiply normalised pixel value [0-1] by this value
experimentDetails.doBrightnessCorrection = 0; % if==0, then don't do correction, 1==Frame (tile correction), 2==File (pre-made)
experimentDetails.brightnessCorrectionFrame = 1; % frame number (time point) to use (also for well detection)
experimentDetails.brightnessCorrectionFile = 'correction.tif'; % pre-made brightness correction file
experimentDetails.brightnessCorrectionFile = 'correction_%d.tif'; % OR a different file for each channel (if you have %d in the name)
experimentDetails.tileCorrection = 0; % if==1 then do tiles based on wells, otherwise fit quadratic
experimentDetails.unevenIlluminationScalingMethod = {'median', 'median', 'median', 'median', 'median'};
experimentDetails.unevenIlluminationCorrectionMethod = {'/', '/', '/', '/', '/'};
experimentDetails.brightnessCorrectionMedian = 2^10; % normalise median to this intensity

% ------------------------------------------------
% Correcting for image jitter due to stage wear
% ------------------------------------------------
experimentDetails.maxOffset = 10; % maximum offset used to align frames for registration

% ------------------------------------------------
% Correcting for background (normally subtractive)
% ------------------------------------------------
% Frames need to be aligned and background computed for each position x channel.
experimentDetails.doBackgroundCorrection = 1; % If non-zero the take away the background (determined previously from all time points)
experimentDetails.proportionBackground = 0.95;
experimentDetails.backgroundCorrectionMethod = {'_', '_', '_', '_', '_'}; % = 0, * , -, _, +, a, ^, 4 see applyReferenceImage()
experimentDetails.backgroundScalingMethod = {'minmax', 'minmax', 'minmax', 'minmax', 'minmax'}; % minmax, median or a number (to scale by)
experimentDetails.backgroundScalingMethod = {'65535', '65535', '65535', '655351', '65535'}; % minmax, median or a number (to scale by)

% ----------------------------------
% Rendering for display in avi files
% ----------------------------------
% NOTE: here, threshold is some multple of peak-width at half height added
% to the median. Determined by trial and error.
experimentDetails.thresholds = [1.4,1.4,2,2,2]; % intensities to do pixel thresholding on
% Stretches individual channels using your manual set thesholds (except  brightfield)
experimentDetails.individualChanelsAllStretched = 1;
% if autothresholding then use gradient-based histogram method to determine bright bits
% otherwise, use median-based histogram method to find them
experimentDetails.autothresholding = 0;
% if no autothresholding then individual channels binarised
% if autothresholding then individual channels sent to black below autothreshold
experimentDetails.binariseChannels = 0;
% The overlay image is built by adding to the transmission image the bright bits from the fluorescence images
% For each well or position this is displayed with the individual channels.
experimentDetails.stack = {1,2,3}; % What channels to put beside the overlay image
% These specify how to do the overlaying. note that the indexed are into channelNumbers()
experimentDetails.rgb = {uint8([0 1 0]), uint8([1 0 0]), uint8([1 1 1]), uint8([0 0 1]) }; % rgb{i} gives contributions to rgb from channel i
experimentDetails.isTransmission = [0 0 1 1]; % is this transmission or fluorescent image (for background correction)
experimentDetails.isOverlaid = [1 1 0 1]; % overlay channel on combined image?

% ----------------------------------
% Font and scale bars on avi files
% ----------------------------------
experimentDetails.fontFile = 'courier_font_file.tif'; % where to cache the fonts captured for printing
experimentDetails.scaleBarMicrons = ' 250 u '; % Length of scale bar. What gets written.
experimentDetails.scaleBarMicrons(end-1) = 181; % Replace u with $\mu$
experimentDetails.scaleBarMicrons = ''; % Length of scale bar==0 means no scale bar
experimentDetails.scaleBarPixels = 600; % How many pixels do those microns cover?


% ----------------------------------
% Finding microwell boundaries
% ----------------------------------
experimentDetails.autoFind = 0; % find boundaries automatically?
experimentDetails.autoFind = 1; % find boundaries automatically?
experimentDetails.wellSize = 270;
experimentDetails.overlap = 5;

% -------------------------------------------------
% Spectral unmixing (like compensation on the FACS)
% -------------------------------------------------
experimentDetails.doUnmixing = 0; % if non-zero do spectral unmixing
% Unmixing params in a 2n array, where n = 1,2,...,numChannels
experimentDetails.unmixingParams = [0.015 0.2];
% this refers to the index into channelNumbers, not axiovision #
experimentDetails.unmixingChannels = [1 2];


% ---------------------------------------------------
% Preparing images for segmenting and finding objects
% ---------------------------------------------------
experimentDetails.useMasks = 1; % use Karl's background finder to create masks for segmentation
% Impulse noise filtering by cellular automata
experimentDetails.minNeighboursSpace = 4; % 3; % Adjacent pixels required for survival
experimentDetails.minNeighboursTime = 2; % 2; % Adjacent pixels in time over and above space ones
experimentDetails.minNeighboursChannel = 1; % Pixels in other channels required in addition to space/time
experimentDetails.maxIterations = 1; % No more than this many pasees in cellular automata loop
experimentDetails.tol = 0.001; % Stop once the difference in proportion of # pixels left varies by less than this

% ------------------------------------
% Filtering unwanted segmented objects
% ------------------------------------
experimentDetails.minAreaPixels = 20; % minimum pixel size to call segmented
experimentDetails.maxAreaPixels = 1600; % minimum pixel size to call segmented
experimentDetails.maxEccentricity = 0.8; % 0=circle, 1=line
experimentDetails.minSolidity = 0.5; % proportion of the pixels in the convex hull
experimentDetails.minAreaPixelsCellCounting = 100; % for cell counting be a bit harsher
experimentDetails.minFluorescenceCellCounting = 5e6; % for cell counting be a bit harsher

% -------------------------------------------------------------------------------
% When measuring fluorescence, how do you do it?
% -------------------------------------------------------------------------------
experimentDetails.segmented_on_self = 1; % each channel  segmnented and measured self
experimentDetails.measuredChannels = {1,2};
experimentDetails.segmented_channel = 3; % measure based on segmetning this (if not self)

% -------------------------------------------------------------------------------
% Using objects counts and fluorescence in fucci repoter to do division detection
% -------------------------------------------------------------------------------
% These parameters control the heuristics used to find microwells with one cell
% that then goes on to divide twice.
experimentDetails.fucciMedianFilterLength = 11; % # segmented objects filter
experimentDetails.fucciCutoffGFP = 0.05; % proportion of measurements discarded
experimentDetails.fucciCutoffRFP = 0.5; % proportion of measurements discarded
experimentDetails.fucciMaxMissingCellGap = 1; % extend island over this time if cells missing
experimentDetails.fucciMinGFPTime = 1; % min island width before extension
experimentDetails.fucciMinRFPTime = 1; % min island width before extension
experimentDetails.fucciMaxGFPTime = 25; % max island width
experimentDetails.fucciMaxRFPTime = 10; % max island width
experimentDetails.fucciMaxOvershootOn = 2; % max time past end of island that fucci can be on
experimentDetails.fucciMaxOvershootOff = 1; % max time past beginning of island that fucci can be on
experimentDetails.fucciMaxTwoCellInOneCellIsland = 0.1; % shouldn't really have extra cells
experimentDetails.fucciMaxThreeCellInTwoCellIsland = 0.1; % shouldn't really have extra cells
experimentDetails.fucciPercentileFilter = 0.5; % the median filter can be changed to get any percentile
experimentDetails.fucciGreenFromRedUnmix = 0.076; % post segmentation unmixing
experimentDetails.fucciRedFromGreenUnmix = 0.9;   % post segmentation unmixing
experimentDetails.fucciFitQuantitiy = 'integratedFluoresence'; % which observable to use

% -------------------------------------------------------------------------------
% Each corresponding function is called for each position
% -------------------------------------------------------------------------------
% they are ordered below the way the function calls are in processPositions
experimentDetails.makeFrameOffsets = 1;
experimentDetails.findFrameTimes = 1;
experimentDetails.makeBackgrounds = 1;
experimentDetails.makeBackgroundMasks = 1;
experimentDetails.makeCorrectedTiffs = 1;
experimentDetails.makeSegmentedTiffs = 1;
experimentDetails.makeAvi = 1;
experimentDetails.findWellEdges = 1;
experimentDetails.makeSplitWells = 1;
experimentDetails.makeAvs = 1;
experimentDetails.measureWells = 1;
experimentDetails.measureCells = 1;
experimentDetails.measureCellNumbers = 1;
experimentDetails.makeFucciFits = 1;
experimentDetails.makePlots = 1;
experimentDetails.makePixelPlots = 1;
experimentDetails.operations = {...
    'makeFrameOffsets', ...
    'findFrameTimes', ...
    'makeBackgrounds', ...
    'makeBackgroundMasks', ...
    'makeCorrectedTiffs', ...
    'makeSegmentedTiffs', ...
    'makeAvi', ...
    'findWellEdges', ...
    'makeSplitWells', ...
    'makeAvs', ...
    'measureWells', ...
    'measureCells', ...
    'measureCellNumbers', ...
    'makeFucciFits', ...
    'makePlots', ...
    'makePixelPlots'
};
for i=1:length(experimentDetails.runDirs)
	experimentDetails.runDir = experimentDetails.runDirs{i};
	processPositionsParallel(experimentDetails);
end
%{
for j=1:length(experimentDetails.operations)
    experimentDetails.(experimentDetails.operations{j}) = 0;
end
% -------------------------------------------------------------------------------
% Process the different runs from the microscope
% -------------------------------------------------------------------------------
for i=1:length(experimentDetails.runDirs)
    experimentDetails.runDir = experimentDetails.runDirs{i};
    for j=1:length(experimentDetails.operations)
        experimentDetails.(experimentDetails.operations{j}) = 1;
        processPositionsParallel(experimentDetails);
        experimentDetails.(experimentDetails.operations{j}) = 0;
    end
end
%}
