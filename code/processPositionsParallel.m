function processPositionsParallel(experimentDetails)
% This contains the loop to do all the different operations on each position.

if(~fileExists(experimentDetails.fontFile))
    writeFont(experimentDetails.fontFile); % Must be done out of the parfor loop
end


experimentDetails.dir = strcat(experimentDetails.inputDir,experimentDetails.runDir);
dirPattern = strcat(experimentDetails.dir,experimentDetails.dirPattern);
dirList = dir(dirPattern);
dirs = length(dirList);
tiles = experimentDetails.tiles;
experimentDetails.logfile_fd = 1; % So that you can at least find where to open it
logfile_name = strcat(getDir(experimentDetails,'log'),'logfile.csv');
experimentDetails.logfile_fd = fopen(logfile_name,'a');
if(experimentDetails.logfile_fd<0)
    fprintf('Unable to open logfile: %s\n',logfile_name);
    return;
end

log_fprintf(experimentDetails,'Found %d positions using dir %s\n',dirs,dirPattern);
if(experimentDetails.profile)
    profile on;
end
% TODO: Some sort of sensible loop over runDirs somewhere

% Report on GPUs
if(experimentDetails.useGPU && exist('gpuDeviceCount') && (gpuDeviceCount>0))
    log_fprintf(experimentDetails, 'Found %d GPUs\n',gpuDeviceCount);
    for ii = 1:gpuDeviceCount
        g = gpuDevice(ii);
        log_fprintf(experimentDetails, 'Device %i is a %s has ComputeCapability %s \n', ...
                g.Index,g.Name, g.ComputeCapability)
    end
    experimentDetails.haveGPU = (g.ComputeCapability > 1.3);
end    
experimentDetails.haveWorkerPool = 0;

if(exist('defaultParallelConfig') && exist('matlabpool') && experimentDetails.threads>1)
    log_fprintf(experimentDetails, 'Found parallel toolbox and workers\n');
    experimentDetails.haveWorkerPool = 1;
end
 
if(experimentDetails.haveWorkerPool)
    matlabpool ('open', 'local', experimentDetails.threads);
end
fclose(experimentDetails.logfile_fd);

parfor i=1:dirs
% for i=1:dirs
    % assume everything gets passed on
    % Stop everything being synchronised
    if(experimentDetails.haveWorkerPool)
        pause(mod(i,8));
    end
    logfile_name = strcat(getDir(experimentDetails,'log'),'logfile.csv');
    logfile_fd(i) = fopen(logfile_name,'a');
    positionDetails = experimentDetails;
    positionDetails.cellDetails = [];
    diritem = dirList(i);
    if(diritem.isdir && diritem.name(1)~='.')
        for j=1:tiles
            % and in addition there is some stuff which is different
            positionDetails.dir = diritem.name;
            % Convert dir name into pattern for file matching
            positionDetails.positionName = diritem.name;
            positionDetails.positionNum = i;
            if(experimentDetails.tiles==1)
                positionDetails.baseName = regexprep(diritem.name, '.tif_Files', '');
                positionDetails.pattern = regexprep(diritem.name, '.tif_Files', experimentDetails.pattern);
            else
                pos_prefix = sprintf('_p%06d',j);
                positionDetails.baseName = regexprep(diritem.name, '.tif_Files', pos_prefix);
                pattern = strcat(pos_prefix,'t%08dz001c%02d.tif');
                positionDetails.pattern = regexprep(diritem.name, '.tif_Files', pattern);
            end
            positionDetails.dir = strcat(experimentDetails.dir,diritem.name,'/'); % full path of position
            positionDetails.positionDir = strcat(diritem.name,'/'); % path of position relative to experiment
            positionDetails.experimentDir = experimentDetails.dir;
            logfile_name = makeFileName(positionDetails,'log');
            positionDetails.logfile_fd = fopen(logfile_name,'a');
            if(positionDetails.logfile_fd<0)
                fprintf(1,'Unable to open logfile: %s\n',logfile_name);
                break;
            end
            
            % list using the all channel numbers. hopefully this avoids the
            % problem caused by axiovision quitting mid position
            channelNumbers = experimentDetails.channelNumbers;
            numChannels = length(channelNumbers);
            timePoints = zeros(numChannels,1);
            for k=1:numChannels
                timePointPattern = sprintf('%s*%d.tif',positionDetails.dir, channelNumbers(k));
                fileList = dir(timePointPattern);
                timePoints(k) = length(fileList);
            end
            positionDetails.timePoints = min(timePoints);
            if(experimentDetails.makeFrameOffsets)
                log_fprintf(logfile_fd(i), 'position2frameoffsets() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2frameoffsets(positionDetails);
            end
            if(experimentDetails.findFrameTimes)
                log_fprintf(logfile_fd(i), 'position2frametimes() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2frametimes(positionDetails);
            end
            if(experimentDetails.makeBackgrounds)
                log_fprintf(logfile_fd(i), 'position2backgrounds() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2backgrounds(positionDetails);
            end
            if(experimentDetails.makeBackgroundMasks)
                log_fprintf(logfile_fd(i), 'position2backgroundmasks() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2backgroundmasks(positionDetails);
            end
            % Optionally write out corrected tiffs for use elsewhere
            if(experimentDetails.makeCorrectedTiffs)
                log_fprintf(logfile_fd(i), 'position2tiffs() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2tiffs(positionDetails);
            end
            % Segmenting comes after the other stuff
            if(experimentDetails.makeSegmentedTiffs)
                log_fprintf(logfile_fd(i), 'position2segmentation() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2segmentation(positionDetails);
            end
            if(experimentDetails.makeAvi)
                log_fprintf(logfile_fd(i), 'position2avi() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2avi(positionDetails);
            end
            if(experimentDetails.findWellEdges)
                log_fprintf(logfile_fd(i), 'position2welledges() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2welledges(positionDetails)
            end
            if(experimentDetails.makeSplitWells)
                position2welltiffs(positionDetails,experimentDetails);
            end
            if(experimentDetails.makeAvs)
                log_fprintf(logfile_fd(i), 'position2avs() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2avs(positionDetails);
            end
            if(experimentDetails.measureWells)
                log_fprintf(logfile_fd(i), 'position2wellmeasurements() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                position2wellmeasurements(positionDetails);
            end
            if(experimentDetails.measureCells)
                log_fprintf(logfile_fd(i), 'position2cellmeasurements() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                positionDetails = position2cellmeasurements(positionDetails);
            end
            if(experimentDetails.measureCellNumbers)
                log_fprintf(logfile_fd(i), 'position2cellnumbers() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                positionDetails = position2cellnumbers(positionDetails);
            end
            if(experimentDetails.makeFucciFits)
                log_fprintf(logfile_fd(i), 'position2fuccifitavs() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                positionDetails = position2fuccifitavs(positionDetails);
            end
            if(experimentDetails.makePlots)
                log_fprintf(logfile_fd(i), 'position2plots() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                positionDetails = position2plots(positionDetails);
            end
            if(experimentDetails.makePixelPlots)
                log_fprintf(logfile_fd(i), 'position2pixelplots() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
                positionDetails = position2pixelplots(positionDetails);
            end
            fclose(logfile_fd(i));
        end % for tiles
    end % if a dir
end
if(experimentDetails.haveWorkerPool)
    matlabpool close
end

experimentDetails.logfile_fd = fopen(logfile_name,'a');
if(experimentDetails.logfile_fd<0)
    fprintf('Unable to open logfile: %s\n',logfile_name);
    return;
end

if(experimentDetails.measureCellNumbers)
    gathercellcounts(experimentDetails);
end

if(experimentDetails.makeFucciFits)
    gatherfuccifits(experimentDetails);
    gatherFucciGFPPlots(experimentDetails);
    gatherfuccicounts(experimentDetails);
end

fclose(experimentDetails.logfile_fd);

% % re-initialised
% positionDetails = experimentDetails;
% positionDetails.cellDetails = [];
% if(experimentDetails.measureCells)
%     positionDetails.cellDetails = readCellDetails('cellrecords.txt');
%     plotCellMeasurements(positionDetails);
% end

if(experimentDetails.profile)
    p = profile('info');
    save myprofiledata p
    clear p
    load myprofiledata
    profview(0,p)
end


