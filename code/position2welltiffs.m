function position2welltiffs(positionDetails,experimentDetails)
% Cut out microwells from tifs 
% TODO: Hack this into new directory structure. Write wellfiles.
dir = positionDetails.dir;
baseName = positionDetails.baseName;
pattern = positionDetails.pattern; 
channels = positionDetails.channels; 
channelNumbers = positionDetails.channelNumbers ;
firstTimePoint = experimentDetails.firstTimePoint ;
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);

log_fprintf(positionDetails,'Processing images from %s\n',dir);
wellsFile = makeFileName(positionDetails,'welledges');
s = readHeaderedFile(wellsFile,1,positionDetails);    
if(isempty(s))
    log_fprintf(positionDetails,'Can''t find wellfile %s, skipping\n',wellsFile);
    return;
else
    log_fprintf(positionDetails,'Have microwell positions from %s\n',wellsFile);
end
microwells = length(s);
microwellBase = getDir(positionDetails,'wellimages');
tiffsDir = getDir(positionDetails,'tiffs');

for i=1:microwells
    % make dir in axiovision-like format
    % getDir(positionDetails,whichFile)
    wellSuffix = sprintf('_well_%c_%d',s(i).row,s(i).col);
    microwell_dir{i} = strcat(microwellBase,sprintf('%s%s',baseName,wellSuffix),'.tif_Files/');
    % mkdir(microwell_dir{i})
end

for i=firstTimePoint:timePoints
    for j=1:channels
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,channelNumbers(j));
        end
        name = strcat(dir,filename);
        log_fprintf(positionDetails,'Processing %s\n',name);
        img16 = uint16(imread(name)); % expecting mono 16 bit images
        for k=1:microwells
            wellSuffix = sprintf('_well_%c_%d',s(k).row,s(k).col);
            wellFilename = strrep(filename,'.tif',wellSuffix);
            microwell_imagename = strcat(microwell_dir{k},wellFilename,'.tif');
            ret = makeDir(microwell_dir{k},positionDetails);
            if(ret==0)
                log_fprintf(positionDetails,'Unable to make microwell images directory: %s\n',microwell_dir{k});
            end
            x = 1+floor(s(k).tlx):ceil(s(k).brx);
            y = 1+floor(s(k).tly):ceil(s(k).bry);
            microwell16 = img16(y,x);
            imwrite(microwell16,microwell_imagename,'Compression','none');
        end
    end
end
