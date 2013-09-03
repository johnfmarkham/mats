function [img16, img16sort] = tiffsReadCorrect(positionDetails,files,unevenIlluminationCorrection,unevenIlluminationCorrectionSorted,backGroundCorrection,backGroundCorrectionSorted,offsets)
% Read tiffs and do various corrections on them. Responsible for
% - spectral unmixing
% - uneven illumination correction
% - impulse noise removal
% - Mask application
% - writes stats about the images
debug = 0;
haveGPU = 0;
if(positionDetails.useGPU && exist('gpuDeviceCount') && (gpuDeviceCount>0))
    g = gpuDevice;
    haveGPU = (g.ComputeCapability > 1.3);
end    
max_uint16 = 65535;

% Used to see if this is the first time point in a series
persistent firstInSeries;
persistent positionNum;
persistent stack_t; % buffer containing time history
if(isempty(positionNum) || positionDetails.positionNum~=positionNum)
    positionNum = positionDetails.positionNum;
    firstInSeries = 1;
else
    firstInSeries = 0;
end

autothresholding = positionDetails.autothresholding;
thresholds = positionDetails.thresholds;
cameraMeanBlackLevel = positionDetails.cameraMeanBlackLevel;
newMedian = positionDetails.brightnessCorrectionMedian;
doBrightnessCorrection = positionDetails.doBrightnessCorrection;
doBackgroundCorrection = positionDetails.doBackgroundCorrection;
doUnmixing = positionDetails.doUnmixing;
unmixingChannels = positionDetails.unmixingChannels;
unmixingParams = positionDetails.unmixingParams; 
binariseChannels = positionDetails.binariseChannels; 
individualChanelsAllStretched = positionDetails.individualChanelsAllStretched;
isTransmission = positionDetails.isTransmission;
backgroundScalingMethod = positionDetails.backgroundScalingMethod;
backgroundCorrectionMethod = positionDetails.backgroundCorrectionMethod;
unevenIlluminationScalingMethod = positionDetails.unevenIlluminationScalingMethod;
unevenIlluminationCorrectionMethod = positionDetails.unevenIlluminationCorrectionMethod;

proportionBackground = positionDetails.proportionBackground;
% Stuff for impulse noise filtering
minNeighboursSpace = positionDetails.minNeighboursSpace;
minNeighboursTime = positionDetails.minNeighboursTime;
minNeighboursChannel = positionDetails.minNeighboursChannel;
maxIterations = positionDetails.maxIterations;
tol = positionDetails.tol;
useMasks = positionDetails.useMasks;

% Read files and apply display mappings...
% Allocate space first
img16sort = [];
img16 = [];
channels = length(files);

for i=1:channels
%    if(debug)
    if(1)
        log_fprintf(positionDetails,'Reading %s\n',files{i}.name);
    end
    if(isempty(img16))
        img = uint16(imread(files{i}.name));
        pixels = size(img,1)*size(img,2);
        img16sort = zeros(pixels,channels,'uint16');
        img16 = zeros(size(img,1),size(img,2),channels,'uint16');
        masks8 = zeros(size(img,1),size(img,2),channels,'uint8');
    end
    img16(:,:,i) = uint16(imread(files{i}.name));
    img16(:,:,i) = shiftImage(img16(:,:,i),offsets{i}.x,offsets{i}.y);
    if(useMasks)
        masks8(:,:,i) = imread(files{i}.mask);
        masks8(:,:,i) = shiftImage(masks8(:,:,i),offsets{i}.x,offsets{i}.y);
    end
end

% Write some stats about pixels
bins = 0:4:(2^12);
for i=1:channels
    if(useMasks)
        last_j = 2;
    else
        last_j = 0;
    end
    for j=0:last_j
        histsfile = makeFileName(positionDetails,'hists',i,j);
        statsfile = makeFileName(positionDetails,'stats',i,j);
        im = img16(:,:,i);
        im = double(im(:));
        fd = fopen(statsfile,'a');
        fprintf(fd,'%d,%d,%d,%.1f,%.1f\n',min(im),median(im),max(im),mean(im),std(im));
        fclose(fd);

        fd = fopen(histsfile,'a');
        n = hist(double(im),bins);
        fprintf(fd,'%d,',n);
        fprintf(fd,'\n');
        fclose(fd);
    end
end

% TODO: GPU
img16 = img16 - cameraMeanBlackLevel;

if(doUnmixing)
    % This does unmixing in 2x2 blocks along the diagonal of the mixing
    % matrix. The assumption is that only adjacent channels mix. Note that
    % we introduce noise because each unmixing depends on the previous one
    % which rounds to uint16. Hopefully this won't be noticable. But if it
    % bothers you, change doSpectralUnmixing() to return double and cache
    % that result for re-use.
    for i=0:2:length(unmixingChannels)-1
        im1 = img16(:,:,unmixingChannels(1+i));
        im2 = img16(:,:,unmixingChannels(2+i));
        [unmixed1,unmixed2] = doSpectralUnmixing(im1,im2,unmixingParams((1+i):(2+i)));
        img16(:,:,unmixingChannels(1+i)) = unmixed1;
        img16(:,:,unmixingChannels(2+i)) = unmixed2;
    end
end

for i=1:channels
    log_fprintf(positionDetails,'Remapping %s\n',files{i}.name);
    % Pre-compute the sorted image for later use
    img16sort(:,i) = sort(reshape(img16(:,:,i),pixels,1));
    max_pixel = max(img16sort(end,i));
    if(doBackgroundCorrection)
            [img16(:,:,i),min_pixel,median_pixel,max_pixel,img16sort(:,i)] =...
            applyReferenceImage(img16(:,:,i),img16sort(:,i),backGroundCorrection(:,:,i),backGroundCorrectionSorted(:,i),newMedian,backgroundScalingMethod{i},backgroundCorrectionMethod{i},proportionBackground,haveGPU);
    end
    if(doBrightnessCorrection && isTransmission(i)==0)
        [img16(:,:,i),min_pixel,median_pixel,max_pixel,img16sort(:,i)] = ...
            applyReferenceImage(img16(:,:,i),img16sort(:,i),unevenIlluminationCorrection(:,:,i),unevenIlluminationCorrectionSorted(:,i),newMedian,unevenIlluminationScalingMethod{i},unevenIlluminationCorrectionMethod{i},proportionBackground,haveGPU);
    end
    if(max_pixel==max_uint16)
        log_fprintf(positionDetails,'Warning: Scaling in applyReferenceImage() may have resulted in loss of bright pixels\n');
    end
end

% First filter the new frame on its own
% Then filter with added frames as a unit.
% Either use adjacent time frames from sam channel of adjacent channels
% from same time.
% Remove impulse noise with cellular automata filter
if(minNeighboursSpace~=0 && binariseChannels~=0)
    if(minNeighboursTime==0)
        for i=1:channels
            [img16(:,:,i) mesg] = caFilter(img16(:,:,i),minNeighboursSpace,maxIterations,tol,haveGPU);
            log_fprintf(positionDetails,mesg);
        end
    else % otherwise if filtering over time
        if(firstInSeries)
            % TODO: Fix in here - When the second frame comes in, you have [1 2 2]
            % For the theird frame, you have [1 2 3]
            % Then carry on as before.
            
            stack_t = cat(4,img16,img16,img16);
            for i=1:channels
                [stack_t(:,:,i,1)  mesg] = caFilter(stack_t(:,:,i,1),minNeighboursSpace,maxIterations,tol,haveGPU);
                log_fprintf(positionDetails,mesg);
                img16(:,:,i) = stack_t(:,:,i,1);
                for j=2:3
                    [stack_t(:,:,i,j) mesg] = caFilter(stack_t(:,:,i,1),minNeighboursSpace,maxIterations,tol,haveGPU);
                    log_fprintf(positionDetails,mesg);
                end
            end
        else
            % Shuffle time points along
           for j=1:2
                stack_t(:,:,:,j) = stack_t(:,:,:,j+1);
           end
           % Filter new ones in each channel
           for i=1:channels
               [stack_t(:,:,i,3) mesg]  = caFilter(img16(:,:,i),minNeighboursSpace,maxIterations,tol,haveGPU); 
                log_fprintf(positionDetails,mesg);
           end
           % Add other times from this channel, re-ordered to put main channel first
           % This is the one that we look at NN in.
           stackPlusExtras = cat(4,stack_t(:,:,:,2) , stack_t(:,:,:,1) , stack_t(:,:,:,3));
           if(minNeighboursChannel>0)
               % Make space to take other channels
               for i=1:channels-1
                   stackPlusExtras = cat(4,stackPlusExtras , stack_t(:,:,:,1));
               end

               for i=1:channels
                   % And same times from other channel to the following slices
                   k = 4;
                   for j=1:channels
                       if(j~=i)
                            stackPlusExtras(:,:,i,k) = stack_t(:,:,j,2);
                            k = k + 1;
                       end
                   end
               end   
           end % if using other channels
           for i=1:channels
               % Output the middle time point - this introduces a delay
               stackPlusExtrasChannel = ...
                   reshape(stackPlusExtras(:,:,i,:),...
                   [size(stackPlusExtras,1),...
                   size(stackPlusExtras,2),...
                   size(stackPlusExtras,4)]);
               [img16(:,:,i)  mesg] = caFilter(stackPlusExtrasChannel,minNeighboursSpace + minNeighboursTime + minNeighboursChannel,maxIterations,tol,haveGPU);
               log_fprintf(positionDetails,mesg);
           end
        end
    end % if temporal filtering too
    for i=1:channels
        img16sort(:,i) = sort(reshape(img16(:,:,i),pixels,1));
    end
end % if impulase noise filtering at all
% Logical and the mask with the channel images (ie. set zero pixels in the
% mask to zero in the output images). Then re-map again
if(useMasks)
    img16(masks8==0) = 0;
    for i=1:channels
        img16sort(:,i) = sort(reshape(img16(:,:,i),pixels,1));
    end
end

