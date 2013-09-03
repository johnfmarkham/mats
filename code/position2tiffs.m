function position2tiffs(positionDetails)
% Convert tiffs into their corrected form and write them out
dir = positionDetails.dir;
baseName = strcat(positionDetails.outputDir,positionDetails.baseName);
pattern = positionDetails.pattern;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
channels = positionDetails.channels;
channelNumbers = positionDetails.channelNumbers;
rgb = positionDetails.rgb;
firstTimePoint = positionDetails.firstTimePoint;
useMasks = positionDetails.useMasks;
log_fprintf(positionDetails,'Processing images from %s\n',dir);
% Do brightness correction
if(positionDetails.filenameIncrementsTime)
    filename_bf = sprintf(positionDetails.pattern,firstTimePoint,channelNumbers(positionDetails.wellDetectionChannel));
else
    filename_bf = sprintf(positionDetails.pattern,channelNumbers(positionDetails.wellDetectionChannel));
end
filename_bf = strcat(positionDetails.dir,filename_bf);
img_bf = imread(filename_bf);
wellsFile = makeFileName(positionDetails,'welledges');
s = readHeaderedFile(wellsFile,1,positionDetails);    
backGroundCorrection = [];
backGroundCorrectionSorted = [];
unevenIlluminationCorrection = [];
unevenIlluminationCorrectionSorted = [];
if(positionDetails.doBackgroundCorrection )
    [backGroundCorrection,backGroundCorrectionSorted] = readBackGroundCorrectionImages(positionDetails);
    frameOffsets = readFrameOffsets(positionDetails);
else
    fo.x = 0;
    fo.y = 0;
    frameOffsets = repmat(fo,timePoints-firstTimePoint+1,channels);
end
if(positionDetails.doBrightnessCorrection)
    [unevenIlluminationCorrection,unevenIlluminationCorrectionSorted] = makeAllReferenceImages(positionDetails,s);
end
pixels = size(img_bf,1) * size(img_bf,2);

tiffsDir = getDir(positionDetails,'tiffs');
% Headers for hists and stats on fluorescent intensities
if(useMasks)
    masksDir = getDir(positionDetails,'masks');
end
writeHistsStatsHeaders(positionDetails);

for i=firstTimePoint:timePoints
    infiles = {};
    outfiles = {};
    offsets = {};
    allPreviouslyProcessed = 1;
    for j=1:channels
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,channelNumbers(j));
        end
        path_filename = strcat(tiffsDir,filename);

        outfiles{j}.name = filename; % output files get put in their own directory
        infiles{j}.name = strcat(dir,filename);
        if(positionDetails.useMasks)
            infiles{j}.mask = strcat(masksDir,filename);
        end
        infiles{j}.rgb = rgb{j};
        offsets{j}.x = frameOffsets(i,j).x;
        offsets{j}.y = frameOffsets(i,j).y;
        if(positionDetails.noClobber && fileExists(path_filename))
            log_fprintf(positionDetails,'The corrected tiff file %s already exists. Skipping.\n',filename);
            continue;
        end
        allPreviouslyProcessed = 0;
    end
    if(allPreviouslyProcessed)
        continue;
    end
    % TODO: When doing temporal filtering, delay the filename and do a fake call in order to get the frame number right.
    [img16, img16sort] = tiffsReadCorrect(positionDetails,infiles,unevenIlluminationCorrection,unevenIlluminationCorrectionSorted,backGroundCorrection,backGroundCorrectionSorted,offsets);
    tiffsWrite(positionDetails,outfiles,img16);
end
