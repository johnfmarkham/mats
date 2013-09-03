function position2wellmeasurements(positionDetails)
% Use pre-segmented images to make measurements on fluorescent channels
% Requires labelled images which show where the cells are
fprintf(1,'This functino is no longer used. Try position2cellmeasurements().');
return;
haveGPU = 0;
if(positionDetails.useGPU && exist('gpuDeviceCount') && (gpuDeviceCount>0))
    g = gpuDevice;
    haveGPU = (g.ComputeCapability > 1.3);
end    

dir = positionDetails.dir;
positionName = positionDetails.positionName;
timePoints = positionDetails.timePoints; 
channels = positionDetails.channels; 
channelNumbers = positionDetails.channelNumbers ;
rgb = positionDetails.rgb;
thresholds = positionDetails.thresholds;
newMedian = positionDetails.brightnessCorrectionMedian;
measuredChannels = positionDetails.measuredChannels;
pattern = positionDetails.pattern; 

if(positionDetails.brightnessCorrectionFrame==0)
    log_fprintf(positionDetails,'You need to do correction to make these measurements\n');
    return;
end

log_fprintf(positionDetails,'Processing images from %s\n',dir);
% Do brightness correction 
recordsFile = makeFileName(positionDetails,'well');
fid = fopen(recordsFile,'a');
fprintf(fid,'#position,well,row,col,time,area,x,y');
for m = 1:length(measuredChannels)
    label = positionDetails.labels{m};
    fprintf(fid,',%s_area',label);
    fprintf(fid,',%s_int_fl',label);
    fprintf(fid,',%s_int_fl_cor',label);
    fprintf(fid,',%s_int_fl_all_cor',label);
end
fprintf(fid,'\n');
wellsFile = makeFileName(positionDetails,'welledges');
s = readHeaderedFile(wellsFile,1,positionDetails);    
correction = makeAllReferenceImages(positionDetails,s);
for i =1:timePoints
%for i =1:10:80
    for j=1:channels
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,channelNumbers(j));
        end
        files{j}.name = strcat(dir,filename);
        files{j}.rgb = rgb{j};
    end

    for j=1:channels
        log_fprintf(positionDetails,'Processing %s\n',files{j}.name);
        img16(:,:,j) = uint16(imread(files{j}.name)) - positionDetails.cameraMeanBlackLevel;
        % compensate across space and time (relative to median)
        img16(:,:,j) = applyReferenceImage(img16(:,:,j),correction(:,:,j),newMedian);
        % img8 is now non-zero where pixels are above-threshold. We can mask this against image. 
        [img8(:,:,j),lowMap ,highMap] = remapimg(img16(:,:,j),0,0,1,thresholds(j),haveGPU);
    end
    % So now we have segmentation image, threshold mask and compensated
    % images
    cx = ([s.brx]+[s.tlx])/2; 
    cy = ([s.bry]+[s.tly])/2;
    n_wells = length(s);
    for k = 1:n_wells;
       wellMask = zeros(size(img8,1),size(img8,2));
       wellMask(s(k).tly:s(k).bry,s(k).tlx:s(k).brx) = 1;
       wellMask = (wellMask==1);
       well_area = sum(sum(wellMask));   %number of pixels for this well
       row =s(k).row;
       col =s(k).col;
       fprintf(fid,positionName);
       fprintf(fid,',%d,%c,%c,%d,%d,%d,%d',...
           k,row,col,i,well_area,int32(cx(k)),int32(cy(k)));
       for m = 1:length(measuredChannels)
           n = measuredChannels{m};
           thresholdedBitPlane = img8(:,:,n); % bright bits of the image
           correctedBitPlane = img16(:,:,n); % all image normalised and corrected
           thresholdMask = (wellMask~=0) & (thresholdedBitPlane~=0); % bits of cell that are bright
           thresholdedArea = sum(sum(thresholdMask));
           % Total fluoresence of bright bits of cell
           integratedFluoresence = sum(sum(correctedBitPlane(thresholdMask)));
           % Total fluoresence of bright bits of cell minus background
           correctedIntegratedFluoresence = ...
               integratedFluoresence - (thresholdedArea * newMedian);
           % Total fluoresence of all of cell minus background
           correctedIntegratedFluoresenceAll = ...
               sum(sum(correctedBitPlane(wellMask))) - (well_area * newMedian);
           fprintf(fid,',%d,%d,%d,%d',...
                thresholdedArea,...
                integratedFluoresence,...
                correctedIntegratedFluoresence,...
                correctedIntegratedFluoresenceAll);
       end % channels
    fprintf(fid,'\n');
    end % for wells
end
fprintf(fid,'\n');
fclose(fid);

