function processPositionsParallel(experimentDetails)
% This contains the loop to do all the different operations on each position.

if(~fileExists(experimentDetails.fontFile))
    writeFont(experimentDetails.fontFile); % Must be done out of the parfor loop
end

experimentDetails.dir = strcat(experimentDetails.inputDir,experimentDetails.runDir);
dirPattern = strcat(experimentDetails.dir,experimentDetails.dirPattern);
dirList = dir(dirPattern);
if (~isempty(experimentDetails.posNums))
	dirList = prunePositionsList(dirList, experimentDetails.posNums);
end
dirs = length(dirList);
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
	processOnePosition(experimentDetails, dirList, i);
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

end