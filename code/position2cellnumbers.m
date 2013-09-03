function [positionDetails] = position2cellnumbers(positionDetails)
% Use pre-segmented and measurements to count cells
debug = 0;

timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
channels = positionDetails.channels; 

recordsFile = makeFileName(positionDetails,'cell');
cellnumbersFile = makeFileName(positionDetails,'cellnumbers',channels);
timePointsLimit = positionDetails.timePointsLimit;
firstTimePoint = positionDetails.firstTimePoint;

if(fileExists(cellnumbersFile))
    if(positionDetails.noClobber)
        log_fprintf(positionDetails,'Cell numbers for %s already exist.\n',cellnumbersFile);
        return;
    end
end

s = readHeaderedFile(recordsFile,1,positionDetails);

if(isempty(s))
        log_fprintf(positionDetails,'Records file %s isempty.\n',recordsFile);
        return;
end

% Get time points, count cells and make plots, 

frames = [s.time];
numTimes = timePoints-firstTimePoint+1;
channelNum = [s.channelNum];
integratedFluoresence = [s.integratedFluoresence];
segmentedChannelNum = [s.segmentedChannelNum];
segmentedArea = [s.segmentedArea];
tEntry.frame=0;
tEntry.numCells=0;

timesFile = makeFileName(positionDetails,'frametimes');
p = readHeaderedFile(timesFile,1,positionDetails);
if(~isempty(p))
    elapsed_hours = framestotimes(p,'elapsed_hours',firstTimePoint:timePoints);
    datenum = framestotimes(p,'datenum',firstTimePoint:timePoints);
    tEntry.elapsed_hours = 0;
else 
    elapsed_hours = [];
    datenum = [];
end

t = repmat(tEntry,numTimes,1);
% TODO: Some extra filtering

for j=1:channels
    for i=firstTimePoint:timePoints
        tIdx = i-firstTimePoint+1;
        t(tIdx).frame = i;
        tEntry.elapsed_hours = 0;
        if(positionDetails.segmented_on_self)
            t(tIdx).numCells = sum(frames==i & ...
                channelNum==j & segmentedChannelNum==j & ...
                integratedFluoresence >=positionDetails.minFluorescenceCellCounting & ...
                segmentedArea >= positionDetails.minAreaPixelsCellCounting...
                );
        else
            t(tIdx).numCells = sum(frames==i & channelNum==j & ...
                segmentedChannelNum==positionDetails.segmented_channel & ...
                integratedFluoresence >= positionDetails.minFluorescenceCellCounting & ...
                segmentedArea >= positionDetails.minAreaPixelsCellCounting...
                );
        end
        if(~isempty(p))
             t(tIdx).elapsed_hours = elapsed_hours(i);
             t(tIdx).datenum = datenum(i);
        end
    end
    cellnumbersFile = makeFileName(positionDetails,'cellnumbers',j);
    writeHeaderedFile(t,cellnumbersFile);
    plotFile = strrep(cellnumbersFile,'.csv','.png');
    opts.dimensions = 2;
    opts.groupings = 'together';
    opts.fields = {'numCells'};
    opts.xlabel = 'frames';
    opts.logfile_fd = positionDetails.logfile_fd;
    try
        plotHeaderedFile(plotFile,cellnumbersFile,opts);
    catch err
        log_fprintf(positionDetails,'There has been a problem: %s\nWhile plotting cellnumbers to make %s\n',err.message,cellnumbersFile);
    end
end



