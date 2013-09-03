function gatherfuccicounts(experimentDetails)
global debug_figure_handle;
debug_figure_handle = 17;

runName = experimentDetails.runDir(1:end-1); % remove \
countspath = getDir(experimentDetails,'fuccicounts');
countsFile = strcat(countspath,runName,'_fuccicounts.csv');

dirPattern = strcat(countspath,'*fuccicounts.csv');
fileList = dir(dirPattern);
files = length(fileList);

if(files==0)
    log_fprintf(experimentDetails,'No files found with pattern %s\n',dirPattern);
    return;
else
    if(experimentDetails.noClobber && fileExists(countsFile))
        log_fprintf(experimentDetails,'The fits file %s already exists. Skipping.\n',countsFile);
    else
        counts = readHeaderedFiles(countspath,fileList,1);
        saveTable(counts,countsFile);
    end
end

