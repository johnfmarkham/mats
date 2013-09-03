function [positionDetails] = position2cellmeasurements(positionDetails)
%% Use pre-segmented image to make measurements on fluorescent channels
%
debug = 0;
haveGPU = 0;
if(positionDetails.useGPU && exist('gpuDeviceCount') && (gpuDeviceCount>0))
    g = gpuDevice;
    haveGPU = (g.ComputeCapability > 1.3);
end    

dir = positionDetails.dir;
pattern = positionDetails.pattern; 
timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
channels = positionDetails.channels; 
channelNumbers = positionDetails.channelNumbers;
rgb = positionDetails.rgb;
thresholds = positionDetails.thresholds;
measuredChannels = positionDetails.measuredChannels;
pattern = positionDetails.pattern; 
useMasks = positionDetails.useMasks; 
masksDir = getDir(positionDetails,'masks');
recordsFile = makeFileName(positionDetails,'cell');
if(fileExists(recordsFile))
    if(positionDetails.noClobber)
        log_fprintf(positionDetails,'Cell measurements for %s already exist.\n',recordsFile);
        return;
    else
        delete(recordsFile);
    end
end

if(positionDetails.brightnessCorrectionFrame==0)
    log_fprintf(positionDetails,'You should do correction to make these measurements\n');
end

log_fprintf(positionDetails,'Processing images from %s\n',dir);
% Do brightness correction 

% fid = fopen(recordsFile,'a');
% fprintf(fid,'well,row,col,time,area,x,y');
% for m = 1:length(measuredChannels)
%     label = positionDetails.labels{m};
%     fprintf(fid,',%s_area',label);
%     fprintf(fid,',%s_int_fl',label);
%     fprintf(fid,',%s_int_fl_cor',label);
%     fprintf(fid,',%s_int_fl_all_cor',label);
% end
% fprintf(fid,',closestEdgeX,closestEdgeY');
% fprintf(fid,'\n');

wellsFile = makeFileName(positionDetails,'welledges');
s = readHeaderedFile(wellsFile,1,positionDetails);    
if(isempty(s) || ~isstruct(s(1)))
    log_fprintf(positionDetails,'The wells file %s seems either empty or broken. Skipping measurement making and writing empty file.\n',wellsFile,recordsFile);
    writeEmptyFile(recordsFile);
    return;
end

if(positionDetails.measureCorrectedTiffs)
    tiffsDir = getDir(positionDetails,'tiffs'); % measuring pre-processed image
else
    tiffsDir = dir; % measuring from the raw images
end
segmentedDir = getDir(positionDetails,'segmented');
writeHeading = 1;
for i =1:timePoints
    measurementID = 0;
    cellID = 0;
    cellDetails = [];
    for j=1:channels
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,channelNumbers(j));
        end
        % TODO: getFileName() etc
        seg_name{j} = strcat(segmentedDir,filename);
        files{j}.name = strcat(tiffsDir,filename);
        files{j}.mask_name = strcat(masksDir,filename);
        files{j}.rgb = rgb{j};
    end
    for j=1:channels
        log_fprintf(positionDetails,'Reading segmentation image %s\n',seg_name{j});
        img_seg_all(:,:,j) = uint16(imread(seg_name{j}));
        log_fprintf(positionDetails,'Processing %s\n',files{j}.name);
        img16(:,:,j) = uint16(imread(files{j}.name));
        pixels = size(img_seg_all,1) * size(img_seg_all,2);
        img16sort(:,j) = sort(reshape(img16(:,:,j),pixels,1));
        % img8 is now non-zero where pixels are above-threshold. We can mask this against image. 
        [img8(:,:,j),lowMap ,highMap] = remapimg(img16(:,:,j),img16sort(:,j),0,0,1,thresholds(j),haveGPU);
        % Or use a specially constructed one
        if(useMasks)
            img_mask(:,:,j) = imread( files{j}.mask_name);
        else
            img_mask(:,:,j) = img8(:,:,j);
        end
    end
    % So now we have segmentation image, threshold mask and compensated
    % images
    x_pos = unique([s.tlx,s.brx]);
    y_pos = unique([s.tly,s.bry]);
    n_cols = length(x_pos);
    n_rows = length(y_pos);
    cx = ([s.brx]+[s.tlx])/2; 
    cy = ([s.bry]+[s.tly])/2;
    centres = [cx',cy'];
    n_wells = length(s);

    for m_seg=1:channels
        img_seg = img_seg_all(:,:,m_seg);
        values = unique(img_seg(img_seg ~= 0)); %non-zero pixels indicate a cell
        n_cells = length(values); %total number of cells
        for k = 1:n_cells;
            cellMask = (img_seg==values(k));
            [yy,xx] = find(cellMask); %what are the pixels for this cell?
            cell_area = length(xx);   %number of pixels for this cell
            centre_x = (mean(xx)); %could possibly use a different measure of the centre but this will do for now
            centre_y = (mean(yy));
            distance = (centre_x - centres(:,1)).^2 + (centre_y - centres(:,2)).^2; %distance from centre of each well
            which_well = find(distance == min(distance)); %which well is it in?
            % if there are several equi-distant wells, choose the first one
            if(length(which_well)>1)
                which_well = which_well(1);
            end
            row =s(which_well).row;
            col =s(which_well).col;

            thisWell = s(which_well);
            wallDistancesX = [thisWell.brx-centre_x,centre_x - thisWell.tlx];
            wallDistancesY = [thisWell.bry - centre_y,centre_y - thisWell.tly];
            closestEdgeX = min(wallDistancesX);
            closestEdgeY = min(wallDistancesY);

            % If we're outside the well then go to next cell
            % Possibly we could keep it and add a field to say so.
            if(centre_x > thisWell.brx || centre_x < thisWell.tlx || centre_y < thisWell.tly || centre_y > thisWell.bry)
                continue;
            end
    %         fprintf(fid,'%d,%c,%s,%d,%d,%d,%d',...
    %             which_well,row,col,i,cell_area,int32(centre_x),int32(centre_y));
            cellID = cellID + 1;

            for m = 1:length(measuredChannels)
               n = measuredChannels{m};
                % This is a hack to allow 3 indices to be used to access the matrices
                % no matter what
                if(channels==1)
                   thresholdedBitPlane = img_mask(:,:); % bright bits of the image
                   correctedBitPlane = img16(:,:); % all image normalised and corrected
                else
                   thresholdedBitPlane = img_mask(:,:,n); % bright bits of the image
                   correctedBitPlane = img16(:,:,n); % all image normalised and corrected
                end
               % Was mean() but this will work for thresholded images
               backgroundCorrection = median(median(double(correctedBitPlane)));
               thresholdMask = (cellMask~=0) & (thresholdedBitPlane~=0); % bits of cell that are bright
               thresholdedArea = sum(sum(thresholdMask));
               % Total fluoresence of bright bits of cell
               integratedFluoresence = sum(sum(correctedBitPlane(thresholdMask)));
               % Total fluoresence of bright bits of cell minus background
               correctedIntegratedFluoresence = ...
                   integratedFluoresence - (thresholdedArea * backgroundCorrection);
               % Total fluoresence of all of cell minus background
               correctedIntegratedFluoresenceAll = ...
                   sum(sum(correctedBitPlane(cellMask))) - (cell_area * backgroundCorrection);
    %            fprintf(fid,',%d,%d,%d,%d',...
    %                 thresholdedArea,...
    %                 integratedFluoresence,...
    %                 correctedIntegratedFluoresence,...
    %                 correctedIntegratedFluoresenceAll);
                measurementID = measurementID + 1;
                cellDetails(measurementID).time = i;
                cellDetails(measurementID).well = which_well;
                cellDetails(measurementID).cellID = cellID;
                cellDetails(measurementID).measurementID = measurementID;
                cellDetails(measurementID).row = row;
                cellDetails(measurementID).col = col;
                cellDetails(measurementID).position = positionDetails.positionName;
                cellDetails(measurementID).thresholdedArea = thresholdedArea;
                cellDetails(measurementID).segmentedArea = cell_area;
                cellDetails(measurementID).x = int32(centre_x);
                cellDetails(measurementID).y = int32(centre_y);
                cellDetails(measurementID).channelNum = m;
                cellDetails(measurementID).segmentedChannelNum = m_seg;
                cellDetails(measurementID).channelName = positionDetails.labels{m};
                cellDetails(measurementID).integratedFluoresence = integratedFluoresence;
                cellDetails(measurementID).correctedIntegratedFluoresenceThresh  = correctedIntegratedFluoresence;
                cellDetails(measurementID).correctedIntegratedFluoresenceCellAll = correctedIntegratedFluoresenceAll;
                cellDetails(measurementID).closestEdgeX = closestEdgeX;
                cellDetails(measurementID).closestEdgeY = closestEdgeY;
            end % measuredChannels
    %     fprintf(fid,'\n');
        end % for cells
    end % segmentedChannels

    % it's possible that the image contains no cells. If it doesn't then
    % skip this bit
    if(measurementID>0)
%         if(writeHeading)
%             writeHeading = 0;
%             fid = fopen(recordsFile,'w');
%             f = fields(cellDetails(1));
%             fprintf(fid,'%s',f{1});
%             for fieldNum=2:length(f)
%                 fprintf(fid,',%s',f{fieldNum});
%             end
%             % fprintf(fid,'\n');
%             fclose(fid);
%         end
        if(appendCellDetails(cellDetails,recordsFile)<0)
            log_fprintf(positionDetails,'Unable to write measurements for position %s to file %s\n',dir,recordsFile);
        end
    end % found cells to add
    nMeasurements = measurementID;
    nCells = cellID;
    if(debug)
        for j=1:channels
            log_fprintf(positionDetails,'Making debugging image for %s\n',files{j}.name);
            [img8(:,:,j),lowMap,medianPixel,highMap] = remapimg(img16(:,:,j),img16sort(:,j),1,1,0,0,haveGPU);
            frame8 = uint8(zeros(size(img16,1),size(img16,2),3));
            for rgbN=1:3
                rgb_vals = rgb{j};
                frame8(:,:,rgbN) = frame8(:,:,rgbN) + img8(:,:,j) * rgb_vals(rgbN);
            end
            if(measurementID>0)
                cellsInThisChannel = ([cellDetails.channelNum]==j & [cellDetails.segmentedChannelNum]==j);
            else
                cellsInThisChannel = [];
            end
            annotateDebugImage(frame8,files{j}.name,cellDetails(cellsInThisChannel));
        end
    end
    positionDetails.cellDetails = [positionDetails.cellDetails , cellDetails];
end % time points
%fprintf(fid,'\n');
% fclose(fid);
% Make a place marker if nothing was written
writeEmptyFile(recordsFile);

%---------------------------------------
function writeEmptyFile(recordsFile)
%---------------------------------------
if(~fileExists(recordsFile))
    fid = fopen(recordsFile,'a');
    fprintf(fid,'\n');
    fclose(fid);
end



%---------------------------------------
function annotateDebugImage(frame8,filename,cellDetails)
% Prints measurements on jpgs
nCells = length(cellDetails);
framesize = [1 1 size(frame8,2) size(frame8,1)];
% Make an image the same size and put text in it
hf = figure('color','white','units','pixels','Position',framesize,'visible','off');
image(ones(size(frame8)));
set(gca,'units','pixels','position',framesize,'visible','off');

% Text at all the cell positions
for i=1:nCells
   cd = cellDetails(i);
   x = cd.x;
   y = size(frame8,1) + 1 - cd.y;
   str = sprintf('id %d xy %d,%d a %d',...
       cd.cellID,cd.x,cd.y,cd.segmentedArea);
   text('units','pixels','position',[x y],'fontsize',12,'string',str)
%    str = sprintf('ID=%d Well=(%c%c) XY=(%d,%d) A=%d',...
%        cd.cellID,cd.row,cd.col,cd.x,cd.y,cd.segmentedArea);
%    text('units','pixels','position',[x y],'fontsize',10,'string',str)
end

% Capture the text image
% Note that the size will have changed by about 1 pixel
% if(positionDetails.threads>1) TODO: Fix this to just write to file
tim = getframe(gca);

% Extract the cdata
tim2 = tim.cdata;

% Make a mask with the negative of the text
tmask = logical(tim2==0);
smask = size(tmask);
sframe = size(frame8);

% If the window can't display in its full size then a bit smaller than
% frame8 is grabbed. Then we have to paste bits on around the edge to match
% sizes.
for i=1:length(sframe)
    if(smask(i) < sframe(i))
        spiece = smask;
        spiece(i) = sframe(i) - smask(i);
        piece = false(spiece);
        if(i==1)
            tmask = cat(i,piece,tmask);
        else
            tmask = cat(i,tmask,piece);
        end
        smask = size(tmask);
    end
end

% Place white text
% Replace mask pixels with UINT8 max
frame8(tmask) = uint8(255);

image(frame8);
close(hf)
% Hopefully this was a tif file. Otherwise we might be in trouble.
filename(end) = 'g';
filename(end-1) = 'p';
filename(end-2) = 'j';
imwrite(frame8,filename);




