function [positionDetails] = position2pixelplots(positionDetails)
% Make background masks and save them
dir = positionDetails.dir;
useMasks = positionDetails.useMasks;
channels = positionDetails.channels;
channelNumbers = positionDetails.channelNumbers;

timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
firstTimePoint = positionDetails.firstTimePoint;
if(useMasks)
    last_k = 2;
else
    last_k = 0;
end
for j=1:channels
    log_fprintf(positionDetails,'Making fluorescent intensity plots for %s, channel %d (Axiovision %d\n',...
        dir,j,channelNumbers(j));
    for k=0:last_k
        histsfile = makeFileName(positionDetails,'hists',j,k);
        statsfile = makeFileName(positionDetails,'stats',j,k);
        opts.groupings = 'together';
        opts.isLogScale = 0;
        opts.dimensions=2;
        opts.logfile_fd = positionDetails.logfile_fd;
        outfile = strrep(statsfile,'.csv','.png');
        if(positionDetails.noClobber && fileExists(outfile))
            log_fprintf(positionDetails,'A plot already exists for %s. Skipping\n',outfile);
        else
            plotHeaderedFile(outfile,statsfile,opts)
        end
        opts.isLogScale = 1;
        opts.dimensions=3;
        opts.xlabel = 'pixel value';
        opts.ylabel = 'pixels';
        outfile = strrep(histsfile,'.csv','.avi');
        if(positionDetails.noClobber && fileExists(outfile))
            log_fprintf(positionDetails,'A plot already exists for %s. Skipping\n',outfile);
            continue;
        end
        plotHeaderedFile(outfile,histsfile,opts)
    end
end