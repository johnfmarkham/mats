function position2welledges(positionDetails)
% Find the well positions and output to a file
% 
imgFile = makeFileName(positionDetails,'wellimages');
wellsFile = makeFileName(positionDetails,'welledges');
if(positionDetails.noClobber && fileExists(wellsFile))
    log_fprintf(positionDetails,'The well edges file %s already exists. Skipping.\n',wellsFile);
    return;
end
autoFind = positionDetails.autoFind;
channelNumbers = positionDetails.channelNumbers;
if(positionDetails.filenameIncrementsTime)
    filename_bf = sprintf(positionDetails.pattern,positionDetails.firstTimePoint,channelNumbers(positionDetails.wellDetectionChannel));
else
    filename_bf = sprintf(positionDetails.pattern,channelNumbers(positionDetails.wellDetectionChannel));
end
filename_bf = strcat(positionDetails.dir,filename_bf);
log_fprintf(positionDetails,'Extracting edges from %s\n',filename_bf);
img_bf = imread(filename_bf);
s = [];
if(autoFind)
    [s,im_h] = findWells(img_bf,autoFind,positionDetails.wellSize,positionDetails.overlap);
    if(autoFind==2)
        try
            [s,im_h] = findWells2(img_bf);
        catch err
            log_fprintf(positionDetails,'findWells2() broke with this message: %s\nReverting to old style\n',err.message);
            [s,im_h] = findWells(img_bf,positionDetails.autoFind,positionDetails.wellSize,positionDetails.overlap);
        end
        if(length(s)<10 )
            log_fprintf(positionDetails,'findWells2()only returned %d wells. using other method.\n',length(s));
            [s,im_h] = findWells(img_bf,autoFind,positionDetails.wellSize,positionDetails.overlap);
        end
    end
else
    [s,im_h] = findWells(img_bf,autoFind,positionDetails.wellSize,positionDetails.overlap);
end
if (~isempty(im_h))
	print(im_h, '-djpeg', imgFile, '-r 600');
	close(im_h);
end
saveTable(s,wellsFile);
