function timesTable = readMultiTimes(positionDetails)
timesTable = [];
oldBaseName = positionDetails.baseName;
for i=1:length(positionDetails.runDirs)
    positionDetails.baseName = strrep(oldBaseName,positionDetails.runDirs{1},positionDetails.runDirs{i});
    timesFile = makeFileName(positionDetails,'frametimes');
    newTimes = readHeaderedFile(timesFile,1,positionDetails);
    if(isempty(timesTable))
        timesTable = newTimes;
    else
        lastRec = timesTable(end);
        newRec = newTimes(1);
        oldDate = datenum(lastRec.timestr);
        newDate = datenum(newRec.timestr);
        diff = datevec(newDate-oldDate);
        frame_offset = lastRec.frame;
        elapsed_seconds_offset = lastRec.elapsed_seconds + diff(end)*3600 + diff(end-1)*60 + diff(end-2);
        elapsed_hours_offset = elapsed_seconds_offset/3600;
        for i=1:length(newTimes)
            rec = newTimes(i);
            newTimes(i).frame = rec.frame + frame_offset;
            newTimes(i).elapsed_hours = rec.elapsed_hours + elapsed_hours_offset;
            newTimes(i).elapsed_seconds = rec.elapsed_seconds + elapsed_seconds_offset;
        end
        timesTable =  [timesTable newTimes];  
    end
end


