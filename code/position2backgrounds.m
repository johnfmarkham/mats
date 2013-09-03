function [positionDetails] = position2backgrounds(positionDetails)
% Make background images and save them
dir = positionDetails.dir;
offsets = readFrameOffsets(positionDetails);
channels = positionDetails.channels;
channelNumbers = positionDetails.channelNumbers;

pattern = positionDetails.pattern;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
firstTimePoint = positionDetails.firstTimePoint;

offsetsChannel = repmat(struct('x',0,'y',0),timePoints-firstTimePoint+1,1);
for j=1:channels
    outfile = makeFileName(positionDetails,'backgrounds',channelNumbers(j));
    if(positionDetails.noClobber && fileExists(outfile))
        log_fprintf(positionDetails,'The background file %s already exists. Skipping.\n',outfile);
        continue;
    end
    
    log_fprintf(positionDetails,'Extracting backgrounds from images in %s for channel %d (Axiovision %d\n',...
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
    if(positionDetails.useMasks)
        % You need a lot of images for this to work
        masksDir = getDir(positionDetails,'masks');
        gState = extractBackground3(files,offsetsChannel,masksDir);
        [alpha k backMean backVar] = gState{1:4};
        gState = extractBackground3(files,offsetsChannel,masksDir,1);
        backMedian = median(backMean(:));
        newMedian = 2^10;
        maxPixel = (2^16-1);
        scaledBackMean = backMean * (newMedian/backMedian);
        scaledBackMean(scaledBackMean>maxPixel-1) = maxPixel-1;
        im = uint16(round(scaledBackMean));
    else
        im = extractBackground2(files,offsetsChannel);
    end    
    % Median based method
    % im = extractBackground2(files,offsetsChannel);
    imwrite(im,outfile,'tif','Compression','none');
end