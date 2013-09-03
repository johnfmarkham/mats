function [positionDetails] = position2fuccifitavs(positionDetails)
% Use pre-segmented image to make measurements on fluorescent channels
debug = 0;
dir = positionDetails.dir;
labels = positionDetails.labels;

fuccifitsFile = makeFileName(positionDetails,'fuccifits');
fuccicountsFile = makeFileName(positionDetails,'fuccicounts');
annotationsFile = makeFileName(positionDetails,'annotations');
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
    % Just look at cells where they were measured from their segmented
    % channel
    if(isfield(cellDetails(1),'segmentedChannelNum'))
        idx = ([cellDetails.channelNum]==[cellDetails.segmentedChannelNum]);
        cellDetails = cellDetails(idx);
    end
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
log_fprintf(positionDetails,'Before new well edges: %d \n',length(cellDetails));
try
    cellDetails = incororporateNewWellEdges(cellDetails,s);
catch err
    log_fprintf(positionDetails,'incororporateNewWellEdges() broke with this message: %s\nUnable to do plots. Something wrong with %s?\n',err.message,recordsFile);
    return;
end
if(isempty(cellDetails))
    log_fprintf(positionDetails,'Had a problem re-assigning wells for %s\n',dir);
    return;
end
log_fprintf(positionDetails,'After new well edges: %d \n',length(cellDetails));
minFrame = min([cellDetails.frame]);
maxFrame = max([cellDetails.frame]);
n_wells = length(s);
recNum = 1;
for i=1:n_wells
    row =s(i).row;
    col =s(i).col;
    log_fprintf(positionDetails,'Fitting for well %c%d\n',row,col);
    wellSuffix = sprintf('_well_%c_%d',row,col);
    filenameStem = strrep(fuccifitsFile,'.csv',wellSuffix);
    sumrec.row = row;
    sumrec.col = col;
    sumrec.position = strrep(fuccifitsFile,'.csv','');
    try
        [rec summary] = fitFucciGreen(positionDetails,cellDetails,row,col,gfp,rfp,filenameStem);
    catch err
        log_fprintf(positionDetails,'There has been a problem: %s\nWhile fitting to make files for %s\n',err.message,filenameStem);
        rec = [];
        sumrec.red1 = 0;
        sumrec.red2 = 0;
        sumrec.green1 = 0;
        sumrec.green2 = 0;
    end
        
    if(~isempty(rec) && isfield(rec,'tstart') && isfield(rec,'tend'))
        rec.row = row;
        rec.col = col;
        sumrec.red1 = summary.red(1);
        sumrec.red2 = summary.red(2);
        sumrec.green1 = summary.green(1);
        sumrec.green2 = summary.green(2);
        rec.position = strrep(fuccifitsFile,'.csv','');
        p{recNum} = rec;
        avsName = sprintf('%s_%c_%d_annotate%s',positionDetails.baseName,row,col,'.avs');
        annotationRec.file = avsName;
        annotationRec.isOK = 1;
        annotationRec.div_1 = rec.div1_frame;
        annotationRec.ron_2 = rec.div2_ron_frame;
        annotationRec.ron_3 = rec.div2_ron_frame;
        annotationRec.roff_2 = rec.div2_roff_frame;
        annotationRec.roff_3 = rec.div2_roff_frame;
        annotationRec.gon_2_frame = rec.div2_gon_frame;
        annotationRec.gon_3_frame = rec.div2_gon_frame;
        annotationRec.goff_2_frame = rec.div2_goff_frame;
        annotationRec.goff_3_frame = rec.div2_goff_frame;
        annotationRec.div2 = rec.div2_frame;
        annotationRec.div3 = rec.div2_frame;
        annotationRec.comment = '  ';
        q{recNum} = annotationRec;
        recNum = recNum+1;
        avsName = makeFileName(positionDetails,'avs');
        avsName = strrep(avsName,'.avs',sprintf('_%c_%d_annotate.avs',row,col));
        fd = fopen(avsName,'w');
        firstFrame = max(rec.div1_frame-50,minFrame);
        lastFrame = min(rec.div2_goff_frame+100,maxFrame);
        fprintf(fd,'AviSource("%s_%c_%d%s").ShowFrameNumber(x=10,y=40,text_color=$ffffff).Trim(%d,%d)',...
            positionDetails.baseName,row,col,'.avs',firstFrame,lastFrame);
        fclose(fd);
    end
    r{i} = sumrec;
end
if(recNum==1)
    log_fprintf(positionDetails,'Warning: Unable to fit even one plot in this position\n');
    p = [];
    q = [];
end
saveTable(p,fuccifitsFile);
saveTable(q,annotationsFile);
saveTable(r,fuccicountsFile);
