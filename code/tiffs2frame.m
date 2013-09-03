function [frame, frames_mono] = tiffs2frame(positionDetails,files,unevenIlluminationCorrection,unevenIlluminationCorrectionSorted,backGroundCorrection,backGroundCorrectionSorted,offsets)
% Convert tiff files into frame suitable for insertion into a movie
% frame contains the combined frame
% frames_mono  contains the individual ones
debug = 0;
haveGPU = 0;
if(positionDetails.useGPU && exist('gpuDeviceCount') && (gpuDeviceCount>0))
    g = gpuDevice;
    haveGPU = (g.ComputeCapability > 1.3);
end    
autothresholding = positionDetails.autothresholding;
thresholds = positionDetails.thresholds;
cameraMeanBlackLevel = positionDetails.cameraMeanBlackLevel;
newMedian = positionDetails.brightnessCorrectionMedian;
doBrightnessCorrection = positionDetails.doBrightnessCorrection;
doUnmixing = positionDetails.doUnmixing;
unmixingChannels = positionDetails.unmixingChannels;
unmixingParams = positionDetails.unmixingParams; 
binariseChannels = positionDetails.binariseChannels; 
individualChanelsAllStretched = positionDetails.individualChanelsAllStretched;
isTransmission = positionDetails.isTransmission;
isOverlaid = positionDetails.isOverlaid;
% Give each positions mapfile a different name for parallel purposes
mapfile = makeFileName(positionDetails,'map');
channels = length(files);

% Only keep open when needed. Spares me debugging problems.
tic;
% Read files and apply display mappings...
% Allocate space first
img16sort = [];
img16 = [];
img8 = [];
frames_mono = {};

% Read in the images, do various image processing things and calculate medians.
[img16, img16sort] = tiffsReadCorrect(positionDetails,files,unevenIlluminationCorrection,unevenIlluminationCorrectionSorted,backGroundCorrection,backGroundCorrectionSorted,offsets);

for i=1:channels
    if(debug)
        log_fprintf(positionDetails,'Remapping %s\n',files{i}.name);
    end
    [img8(:,:,i),lowMap,median_pixel,highMap] = remapimg(img16(:,:,i),img16sort(:,i),isTransmission(i),autothresholding,binariseChannels,thresholds(i),haveGPU);
    if(binariseChannels && (~isTransmission(i)))
        img8(:,:,i) = majorityRulesFilter(img8(:,:,i),1,1);
    end
    % If something breaks this stops
    fid = fopen(mapfile,'a');
    fprintf(fid,'%d,%d,%d,',lowMap,median_pixel,highMap);
    fclose(fid);
end
fid = fopen(mapfile,'a');
fprintf(fid,'%f\n',toc);
fclose(fid);

% Construct RGB image
if(haveGPU)
    frame8GPU = parallel.gpu.GPUArray.zeros(size(img16,1),size(img16,2),3,'double');
    img8GPU = gpuArray(double(img8));
end

frame8 = zeros(size(img16,1),size(img16,2),3,'uint8');
for i=1:channels
    % Not all channels are to be combined
    if(~isOverlaid(i))
        continue;
    end
    if(debug)
        log_fprintf(positionDetails,'Processing combined frame: %s\n',files{i}.name);
    end
    for j=1:3
        if(haveGPU)
            rgbGPU = gpuArray(double(files{i}.rgb(j)));
            frame8GPU(:,:,j) = frame8GPU(:,:,j) + img8GPU(:,:,i) * rgbGPU;
        else
            frame8(:,:,j) = frame8(:,:,j) + uint8(img8(:,:,i) * double(files{i}.rgb(j)));
        end
    end
end

if(haveGPU)
    frame8 = uint8(round(gather(frame8GPU)));
end
% TODO: Put in decimation on finding median of the big pics?

% frame8 = medianFilter(frame8,1,1);
frame = im2frame(frame8);
for i=1:channels
    % Either thresholding is applied to individual channel movies or it treats them like BF
    % which just stretches total dynamic range into 0-255
    log_fprintf(positionDetails,'Processing individual frame: %s\n',files{i}.name);
    if(isTransmission(i))
        img8(:,:,i) = remapimg(img16(:,:,i),img16sort(:,i),isTransmission(i),autothresholding,0,thresholds(i),haveGPU);
    elseif(individualChanelsAllStretched)
        img8(:,:,i) = remapimg(img16(:,:,i),img16sort(:,i),1,0,0,thresholds(i),haveGPU); % binarise fluorescent channels
    else
        img8(:,:,i) = remapimg(img16(:,:,i),img16sort(:,i),0,autothresholding,binariseChannels,thresholds(i),haveGPU);
        if(binariseChannels)
            img8(:,:,i) = majorityRulesFilter(img8(:,:,i),1,1);
        end
    end
    for j=1:3
        if(haveGPU)
            rgbGPU = gpuArray(double(files{i}.rgb(j)));
            frame8GPU(:,:,j) = img8GPU(:,:,i) * rgbGPU;
        else
            frame8(:,:,j) = uint8(img8(:,:,i) * double(files{i}.rgb(j)));
        end
    end
    if(haveGPU)
        frame8 = uint8(round(gather(frame8GPU)));
    end
    % frame8 = medianFilter(frame8,1,1);
    frames_mono{i} = im2frame(frame8);
end


