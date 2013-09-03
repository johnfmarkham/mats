function [positionDetails] = position2backgroundmasks(positionDetails)
% Make background masks and save them
dir = positionDetails.dir;
offsets = readFrameOffsets(positionDetails);
channels = positionDetails.channels;
channelNumbers = positionDetails.channelNumbers;
outputMaskFolder = getDir(positionDetails,'masks');

pattern = positionDetails.pattern;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
firstTimePoint = positionDetails.firstTimePoint;
offsetsChannel = repmat(struct('x',0,'y',0),timePoints-firstTimePoint+1,1);
for j=1:channels
    log_fprintf(positionDetails,'Making masks from images in %s for channel %d (Axiovision %d)\n',...
        dir,j,channelNumbers(j));
    for i=1:firstTimePoint
        files{i} = '';
    end
    for i=firstTimePoint:timePoints
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,channelNumbers(j));
        end
        files{i} = strcat(dir,filename);
        offsetsChannel(i-firstTimePoint+1) = offsets(i,j);
    end
    lastOutfile = strcat(outputMaskFolder,filename);
    if(positionDetails.noClobber && fileExists(lastOutfile))
        log_fprintf(positionDetails,'The mask series containing the file %s already exists. Skipping.\n',lastOutfile);
        continue;
    end
    extractBackground3( files, offsetsChannel, outputMaskFolder,0);
    extractBackground3( files, offsetsChannel, outputMaskFolder,1);
end