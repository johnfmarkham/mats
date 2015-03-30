function position2frameoffsets(positionDetails)
% Find the offsets between each frame and the first so that they can be
% aligned
dir = positionDetails.dir;
pattern = positionDetails.pattern;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
firstTimePoint = positionDetails.firstTimePoint;
channelNumbers = positionDetails.channelNumbers;
wellDetectionChannel = positionDetails.wellDetectionChannel;
numTimePoints = timePoints-firstTimePoint+1;

offsetsFile = makeFileName(positionDetails,'offsets');
if(positionDetails.noClobber && fileExists(offsetsFile))
    log_fprintf(positionDetails,'The offsets file %s already exists. Skipping.\n',offsetsFile);
    return;
end

log_fprintf(positionDetails,'Extracting frame offsets from images in %s\n',dir);
files = cell(numTimePoints,1);
for i=1:numTimePoints
    files{i} = '';
end

for i=firstTimePoint:timePoints
    if(positionDetails.filenameIncrementsTime)
        filename = sprintf(pattern,i,channelNumbers(wellDetectionChannel));
    else
        filename = sprintf(pattern,channelNumbers(wellDetectionChannel));
    end
    files{i} = strcat(dir,filename);
end
% offsets = findOffsets(files,positionDetails.maxOffset,positionDetails.offsetResolution);
offsets = findOffsets3(files, positionDetails.useGPU, positionDetails.verbose);
% Align frame numbers
for i=firstTimePoint:timePoints
    offsets(i-firstTimePoint+1).frame = i;
end
offsetsFile = makeFileName(positionDetails,'offsets');

saveTable(offsets,offsetsFile);
