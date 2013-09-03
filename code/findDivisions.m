function findDivisions()


experimentDetails.segmented_dir = '.\segmented_dir\segmented_otsu\';
experimentDetails.segmented_channel = 2;

experimentDetails.measuredChannels = {1,2,3};
experimentDetails.splitWells = 0;
experimentDetails.measureWells = 0;
experimentDetails.measureCells = 1;

experimentDetails.makeAvi = 0;
experimentDetails.outputDir = '.\';
experimentDetails.makeAvs = 0;
% experimentDetails.microwells = 16; % how many microwells per position

% Old-style pixel thresholds - no longer used
%experimentDetails.thresholds = [4622,5001,4804,1915]; % intensities to do pixel thresholding on
%experimentDetails.thresholds = [5100,5000,5000,2000]; % intensities to do pixel thresholding on
% NOTE: here, threshold is some multple of peak-width at half height added
% to the median. Determined by trial and error.
experimentDetails.thresholds = [1.7,2,3,2]; % intensities to do pixel thresholding on
experimentDetails.thresholds = [1.7,1.7,1.7,2]; % intensities to do pixel thresholding on
experimentDetails.autothresholding = 1; % or do it automatically - this may not work
experimentDetails.dirPattern = '*tif_Files'; % how to match files containing images

experimentDetails.dir = '..\20110121-0047\'; % Must have \ on the end
experimentDetails.channels = 3;
experimentDetails.timePointsLimit = 1; % stop at this number of time points if you get there (images may run out first)
experimentDetails.labels = {'RFP','CTV','BF'}; % Should match chanels
experimentDetails.stack = {2,1}; % What channels to put beside combo image 
experimentDetails.channelNumbers = [0,1,2]; % What channel numbers appear in axiovision 
experimentDetails.rgb = {uint8([1 0 0]),uint8([0 0 1]),uint8([1 1 1])}; % rgb{i} gives contributions to rgb from channel i 
experimentDetails.pattern = '_t%02dc%d.tif';% What is used to make the end of the image filename
experimentDetails.filenameIncrementsTime = 0; % only use one %d in the format string then

experimentDetails.doBrightnessCorrection = 0; % if==0, then don't do correction, 1==Frame (tile correction), 2==File (pre-made)
experimentDetails.brightnessCorrectionFrame = 1; % frame number (time point) to use (==0 if not)
experimentDetails.brightnessCorrectionFile = '470_correction.tif'; % pre-made brightness correction file
experimentDetails.brightnessCorrectionFile = 'correction_%d.tif'; % OR a different file for each channel (if you have %d in there)
experimentDetails.brightnessCorrectionFile = 'smoothed_new_20x_ctv_100_0%d.tif'; % OR a different file for each channel (if you have %d in there)
experimentDetails.tileCorrection = 0; % if==1 then do tiles based on wells, otherwise fit quadratic

experimentDetails.wellDetectionChannel = 3; % usually BF channel
experimentDetails.brightnessCorrectionMedian = 2^10; % normalise median to this intensity
experimentDetails.wellSize = 100; % this is about their actual size - maybe a bit smaller better

experimentDetails.timePointsLimit = 1; % for testing

experimentDetails.dir = '..\20110128-0003\'; % Must have \ on the end
experimentDetails.pattern = '_c%d.tif';% What is used to make the end of the image filename
experimentDetails.dirPattern = '*tif_Files'; % how to match files containing images
processPositions(experimentDetails);

experimentDetails.dir = '..\20110128-0004\'; % Must have \ on the end
experimentDetails.pattern = '_c%d.tif';% What is used to make the end of the image filename
experimentDetails.dirPattern = '*tif_Files'; % how to match files containing images
processPositions(experimentDetails);

experimentDetails.wellDetectionChannel = 4; % usually BF channel
experimentDetails.dir = '..\20110128-0005\'; % Must have \ on the end
experimentDetails.channels = 4;
experimentDetails.labels = {'RFP','CTV','GFP','BF'}; % Should match chanels
experimentDetails.stack = {2,1,3}; % What channels to put beside combo image 
experimentDetails.channelNumbers = [0,1,2,3]; % What channel numbers appear in axiovision 
experimentDetails.rgb = {uint8([1 0 0]),uint8([0 0 1]),uint8([0 1 0]),uint8([1 1 1])}; % rgb{i} gives contributions to rgb from channel i 
experimentDetails.pattern = '_c%d.tif';% What is used to make the end of the image filename
experimentDetails.dirPattern = '*tif_Files'; % how to match files containing images
processPositions(experimentDetails);

