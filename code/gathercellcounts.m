function gathercellcounts(experimentDetails)
global debug_figure_handle;
debug_figure_handle = 17;
timePointsLimit = experimentDetails.timePointsLimit;
firstTimePoint = experimentDetails.firstTimePoint;
numTimes = timePointsLimit-firstTimePoint+1;
channels = experimentDetails.channels; 

tEntry.frame=0;
tEntry.numCells=0;
tEntry.elapsed_hours = 0;
tEntry.datenum = 0;

runName = experimentDetails.runDir(1:end-1); % remove \

for j=1:channels
    cellnumbersPath = getDir(experimentDetails,'cellnumbers');
    totalsFile = strcat(cellnumbersPath,runName,'_',num2str(j),'_cellnumbers.csv');
    plotFile = strrep(totalsFile,'.csv','.png');
    if(experimentDetails.noClobber && fileExists(totalsFile))
        log_fprintf(experimentDetails,'The plot file %s already exists. Skipping.\n',plotFile);
        continue;
    end

    dirPattern = sprintf('%s*%d%s',cellnumbersPath,j,'.csv');
    fileList = dir(dirPattern);
    
    s = readHeaderedFiles(cellnumbersPath,fileList,1,experimentDetails);
    if(isempty(s))
        log_fprintf(experimentDetails,'The cell numbers file %s is empty. Skipping.\n',cellnumbersPath);
        continue;
    end
    numCells = [s.numCells];
    frames = [s.frame];
    maxFrame = max(frames);
    t = repmat(tEntry,maxFrame,1);
    for i=1:maxFrame
        frame = firstTimePoint + i-1;
        t(i).frame = frame;
        t(i).numCells = sum(numCells(frames==frame));
        recs = s(frames==frame);
        t(i).elapsed_hours = recs(1).elapsed_hours;
        t(i).datenum = recs(1).datenum;
    end
    
    writeHeaderedFile(t,totalsFile);
    plotFile = strrep(totalsFile,'.csv','.png');
    opts.dimensions = 2;
    opts.logfile_fd = experimentDetails.logfile_fd;
    opts.fields = {'numCells'};
    opts.xlabel_text = 'frame';
    plotHeaderedFile(plotFile,totalsFile,opts)
end

