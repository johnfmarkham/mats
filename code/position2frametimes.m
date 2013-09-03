function position2frametimes(positionDetails)
% Get the time stamps out of the files so that they can be exactly timed
posDir = positionDetails.dir;
pattern = positionDetails.pattern;
channelNumbers = positionDetails.channelNumbers;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
firstTimePoint = positionDetails.firstTimePoint;
timesFile = makeFileName(positionDetails,'frametimes');

if(positionDetails.noClobber && fileExists(timesFile))
    log_fprintf(positionDetails,'The times file %s already exists. Skipping.\n',timesFile);
    return;
end


log_fprintf(positionDetails,'Extracting times from images in %s\n',posDir);

times =  repmat(struct('frame',0,'elapsed_hours',0,'interval_minutes',0,'timestr','""','elapsed_seconds',0,'path','""'),1,timePoints-firstTimePoint+1);

for i=firstTimePoint:timePoints
    if(positionDetails.filenameIncrementsTime)
        filename = sprintf(pattern,i,channelNumbers(positionDetails.wellDetectionChannel));
    else
        filename = sprintf(pattern,channelNumbers(positionDetails.wellDetectionChannel));
    end
    log_fprintf(positionDetails,'Extracting time from %s\n',filename);
    s = dir(strcat(posDir,filename));
    ds = datestr(s.datenum,' yyyymmdd HH:MM:SS');
    dn = s.datenum;
    if(i==firstTimePoint)
        im = 0;
        ed = 0;
        firstTime = dn;
    else
        im = (dn-lastTime)*24*60;
        ed = (dn-firstTime);
    end
    lastTime = dn;
    if(i==0)
        continue;
    end
    times(i).frame = i;
    times(i).elapsed_hours = ed*24;
    times(i).elapsed_seconds = ed*24*60*60;
    times(i).interval_minutes = im;
    times(i).timestr = ds;
    times(i).datenum = dn;
    times(i).path = filename;
end
saveTable(times,timesFile);
