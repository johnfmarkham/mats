function processPositions(experimentDetails)

% dir = './';
% baseName = 'testData';
% pattern = '20090131_ubiquitin_gfp-0036_c_7_p000001t%08dz001c%02d.tif'; 
% timePoints = 4; 
% channels = 3; 
% rgb = {uint8([1 1 1]),uint8([0 1 0]),uint8([1 0 0])};
 
experimentDetails.dir = strcat(experimentDetails.inputDir,experimentDetails.runDir);
dirPattern = strcat(experimentDetails.dir,experimentDetails.dirPattern);
dirList = dir(dirPattern);
dirs = length(dirList);
fprintf(1,'Found %d positions using dir %s\n',dirs,dirPattern);

% assume everything gets passed on
positionDetails = experimentDetails;
positionDetails.cellDetails = [];

for i=1:dirs
    diritem = dirList(i);
    if(diritem.isdir)
        for j=1:experimentDetails.tiles
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
                experimentDetails.pattern = strcat(pos_prefix,'t%08dz001c%02d.tif');
                positionDetails.pattern = regexprep(diritem.name, '.tif_Files', experimentDetails.pattern);
            end
            positionDetails.dir = strcat(experimentDetails.dir,diritem.name,'\'); % full path of position
            positionDetails.positionDir = strcat(diritem.name,'\'); % path of position relative to experiment
            positionDetails.experimentDir = experimentDetails.dir;
            % list using the first channel number
            timePointPatterm = sprintf('%s*%d.tif',positionDetails.dir,experimentDetails.channelNumbers(1));
            fileList = dir(timePointPatterm);
            positionDetails.timePoints = length(fileList);
            if(experimentDetails.makeFrameOffsets)
                position2frameoffsets(positionDetails)
            end
            if(experimentDetails.makeBackgrounds)
                position2backgrounds(positionDetails)
            end
            if(experimentDetails.measureWells)
                position2wellmeasurements(positionDetails);
            end
            if(experimentDetails.measureCells)
                positionDetails = position2cellmeasurements(positionDetails);
            end
            % Optionally write out corrected tiffs for use elsewhere
            if(positionDetails.makeCorrectedTiffs)
                position2tiffs(positionDetails);
            end
            if(experimentDetails.makeAvs)
                position2avs(positionDetails);
            end
            if(experimentDetails.makeAvi)
                position2avi(positionDetails);
            end
            if(experimentDetails.splitWells)
                position2welltiffs(positionDetails,experimentDetails);
            end
            if(experimentDetails.makeFucciFits)
                positionDetails = position2fuccifitavs(positionDetails);
            end
            if(experimentDetails.makePlots)
                positionDetails = position2plots(positionDetails);
            end
        end
    end % if a dir
end
if(experimentDetails.measureCells)
    positionDetails.cellDetails = readCellDetails('cellrecords.txt');
    plotCellMeasurements(positionDetails);
end



