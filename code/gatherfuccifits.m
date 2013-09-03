function gatherfuccifits(experimentDetails)
global debug_figure_handle;
debug_figure_handle = 17;

runName = experimentDetails.runDir(1:end-1); % remove \
fuccipath = getDir(experimentDetails,'fuccifits');
fitsFile = strcat(fuccipath,runName,'_fuccifits.csv');
plotFile = strcat(fuccipath,runName,'_fuccifits_tdiv_s.png');
aviFile = strcat(fuccipath,runName,'_fuccifits.avi');

dirPattern = strcat(fuccipath,'*fuccifits.csv');
fileList = dir(dirPattern);
files = length(fileList);

if(files==0)
    log_fprintf(experimentDetails,'No files found with pattern %s\n',dirPattern);
    return;
else
    if(experimentDetails.noClobber && fileExists(fitsFile))
        fits = readHeaderedFile(fitsFile,1,experimentDetails);
        log_fprintf(experimentDetails,'The fits file %s already exists. Skipping.\n',fitsFile);
    else
        fits = readHeaderedFiles(fuccipath,fileList,1,experimentDetails);
        saveTable(fits,fitsFile);
    end
end



if(experimentDetails.noClobber && fileExists(plotFile))
    log_fprintf(experimentDetails,'The fits plotFile %s already exists. Skipping.\n',plotFile);
elseif(isempty(fits))
    log_fprintf(experimentDetails,'The fits plotFile %s was empty. Skipping.\n',plotFile);
else
    tstart = [fits.tstart];
    tend = [fits.tend];
    tgon = [fits.tgon];
    ts = tend - tgon;
    green_peak = [fits.p2_y3];
    green_grad = green_peak./ts;

    divisionTimes = tend - tstart;
    sprop = ts./divisionTimes;

    r = corr(divisionTimes',ts');
    h = figure(debug_figure_handle);
    set(debug_figure_handle,'visible','off')
    plot(divisionTimes,ts,'b.');
    xlabel('division time');
    ylabel('time green');
    title(sprintf('r(t_{div},t_{green}) = %.2f',r));
    print(h, '-dpng', plotFile, '-r 600');
    close(h) 

    plotFile = strcat(fuccipath,runName,'_fuccifits_sprop.png');
    r = corr(divisionTimes',sprop');
    h = figure(debug_figure_handle);
    set(debug_figure_handle,'visible','off')
    plot(divisionTimes,sprop,'b.');
    xlabel('division time');
    ylabel('proportion of time green');
    title(sprintf('r(t_{div},sprop) = %.2f',r));
    print(h, '-dpng', plotFile, '-r 600');
    close(h) 
    
    plotFile = strcat(fuccipath,runName,'_fuccifits_green_peak.png');
    r = corr(divisionTimes',green_peak');
    h = figure(debug_figure_handle);
    set(debug_figure_handle,'visible','off')
    plot(divisionTimes,green_peak,'b.');
    xlabel('division time');
    ylabel('GFP max');
    title(sprintf('r(t_{div},GFP_{max}) = %.2f',r));
    print(h, '-dpng', plotFile, '-r 600');
    close(h) 

    plotFile = strcat(fuccipath,runName,'_fuccifits_green_grad.png');
    r = corr(divisionTimes',green_grad');
    h = figure(debug_figure_handle);
    set(debug_figure_handle,'visible','off')
    plot(divisionTimes,green_grad,'b.');
    xlabel('division time');
    ylabel('GFP rate');
    title(sprintf('r(t_{div},GFP rate) = %.2f',r));
    print(h, '-dpng', plotFile, '-r 600');
    close(h) 

end

dirPattern = strcat(fuccipath,'*fuccifits_well_*.png');
fileList = dir(dirPattern);
files = length(fileList);
if(files==0)
    log_fprintf(experimentDetails,'No files found with pattern %s\n',dirPattern);
else
    if(experimentDetails.noClobber && fileExists(aviFile))
        log_fprintf(experimentDetails,'The fits avi file %s already exists. Skipping.\n',aviFile);
    else
        pics2avi(fuccipath,fileList,aviFile);
    end
end



