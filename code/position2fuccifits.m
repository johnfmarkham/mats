function [positionDetails] = position2fuccifits(positionDetails)
% Use pre-segmented image to make measurements on fluorescent channels
debug = 0;
dir = positionDetails.dir;
labels = positionDetails.labels;

fuccifitsFile = makeFileName(positionDetails,'fuccifits');
if(positionDetails.noClobber && fileExists(fuccifitsFile))
    log_fprintf(positionDetails,'Fucci fit file %s exists. Skipping.\n',fuccifitsFile);
    return;
end


for i=1:length(labels)
    if(strcmp(labels{i},'GFP'))
        % gfp.quantity = 'correctedIntegratedFluoresenceCellAll';
        gfp.quantity = positionDetails.fucciFitQuantitiy;
        gfp.channelName = labels{i};
        gfp.channelNum = i;
    elseif(strcmp(labels{i},'RFP'))
        % rfp.quantity = 'correctedIntegratedFluoresenceCellAll';
        rfp.quantity = positionDetails.fucciFitQuantitiy;
        rfp.channelName = labels{i};
        rfp.channelNum = i;
    end
end
if(positionDetails.brightnessCorrectionFrame==0)
    log_fprintf(positionDetails,'You should do correction to make these measurements\n');
end

log_fprintf(positionDetails,'Processing images from %s\n',dir);
try
    wellsFile = makeFileName(positionDetails,'welledges');
    s = readHeaderedFile(wellsFile,1,positionDetails);    

    recordsFile = makeFileName(positionDetails,'cell');
    cellDetails = readHeaderedFile(recordsFile,1,positionDetails);
    if(isempty(s))
        log_fprintf(positionDetails,'Unable to read wells\n');
        return;
    end
    if(isempty(cellDetails))
        log_fprintf(positionDetails,'Unable to read cell measurements\n');
        return;
    end
    if(positionDetails.insertRealTimes)
        timesFile  = makeFileName(positionDetails,'frametimes');
        timesTable = readHeaderedFile(timesFile,1,positionDetails);  
        % timesTable = readMultiTimes(positionDetails);
        if(isempty(timesTable))
            log_fprintf(positionDetails,'Unable to read frame times\n');
            return;
        end
        cellDetails = incororporateTimesTable(cellDetails,timesTable);
    end
catch err
    log_fprintf(positionDetails,'There has been a problem: %s\nWhile reading files for %s\n',err.message,dir);
    return;
end
% Re-do allocation of segmented objects to wells
cellDetails = incororporateNewWellEdges(cellDetails,s);

n_wells = length(s);
recNum = 1;
for i=1:n_wells
    row =s(i).row;
    col =s(i).col;
    log_fprintf(positionDetails,'Fitting for well %c%d\n',row,col);
    wellSuffix = sprintf('_well_%c_%d',row,col);
    filenameStem = strrep(fuccifitsFile,'.csv',wellSuffix);
    rec = fitFucciGreen(positionDetails,cellDetails,row,col,gfp,rfp,filenameStem);
    if(~isempty(rec) && isfield(rec,'tstart') && isfield(rec,'tend'))
        rec.row = row;
        rec.col = col;
        rec.position = strrep(fuccifitsFile,'.csv','');
        p{recNum} = rec;
        recNum = recNum+1;
    end
end
if(recNum==1)
    log_fprintf(positionDetails,'Warning: Unable to fit even one plot in this position\n');
    p = [];
else
    
end
saveTable(p,fuccifitsFile);

