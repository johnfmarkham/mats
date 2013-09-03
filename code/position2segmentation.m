function position2segmentation(positionDetails)
% Segment previously corrected tiffsand write them to disc
% 
segmentedDir = getDir(positionDetails,'segmented');
tiffsDir = getDir(positionDetails,'tiffs');
pattern = positionDetails.pattern;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
channels = positionDetails.channels;
channelNumbers = positionDetails.channelNumbers;
firstTimePoint = positionDetails.firstTimePoint;

log_fprintf(positionDetails,'Processing images from %s\n',tiffsDir);

for i=firstTimePoint:timePoints
    for j=1:channels
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,channelNumbers(j));
        end
        log_fprintf(positionDetails,'Segmenting %s\n',filename);
        infile = strcat(tiffsDir,filename);
        outfile = strcat(segmentedDir,filename);
        if(positionDetails.noClobber && fileExists(outfile))
            log_fprintf(positionDetails,'Segmented file %s exists. Skipping.\n',outfile);
            continue;
        end
        try
            img16 = uint16(imread(infile));
        catch err
            log_fprintf(positionDetails,'position2segmentation() broke and is skipping a file. The message: %s\nThe file:\n',err.message,infile);
            continue;
        end
        imgseg = segmentCells(img16, ...
            positionDetails.minAreaPixels,...
            positionDetails.maxAreaPixels,...
            positionDetails.maxEccentricity,...
            positionDetails.minSolidity);
        imwrite(imgseg,outfile,'tif','Compression','packbits');
        % Save an easy to view version as a jpg file
        % imrgb = label2rgb(imgseg,'Gray','k','random');
        imrgb = label2rgb(imgseg,'lines','k');
        outfile(end)='g';outfile(end-1)='p';outfile(end-2)='j';
        imwrite(imrgb,outfile);
    end
end
