%---------------------------------------
function [img, lowMap,medianPixel,highMap] =  remapimg(img,imgsort,isBrightField,autothresholding,binarise,threshold,haveGPU)
% Remap histogram of img into something different
%
% Make display mappings to maximise contrast
% OR 
% quantise based on manually injected threshold
% 
% Description of those params
%
% autothresholding - if true, do the threshold using an gradient based
% method. Otherwise, use threshold
%
% binarise - if true all pixels go to either maxPixel or minPixel. Otherwise
% the values are stretced to go between the two
%
% threshold - used for manual thresholding
% 
% Error check binarise/bf not on at once
% mode = bf_stretch/fl_overlay 
% fl_threshold = maual/auto
% fl_mapping = binarise/stretch
% TODO: Document this in processExperiment() and fix the binarised combo image
debug = 0;
pixels = size(img,1) * size(img,2);
lowerHist = 0.001;
upperHist = 0.999;
minPixel = 0;
maxPixel = 128;
lowMap = 0;
highMap = 128;
% imgsort = sort(reshape(img,pixels,1));
q  = floor(pixels/4);
medianPixel = imgsort(q * 2);

% define threshold to be some multple of distance between quartiles
threshold = imgsort(q * 2) + threshold * (imgsort(q * 3) - imgsort(q * 1));

if(isBrightField)
%        lowerHist = 0.05;
%        upperHist = 0.90;
    lowerHist = 0;
    upperHist = 0.99;
    lowMap = imgsort(floor(pixels*lowerHist)+1);
    threshold = lowMap;
elseif(autothresholding)
% otherwise, stretch out from the point of inflection to the end
% to fill 0-255. This sets the noisy background to black but results
% in bright patches of image modulating the overall brightness
    stepSize = floor(pixels/100);
    for lowIdx=pixels:-stepSize:1+2*stepSize
        d0 = double(imgsort(lowIdx)-imgsort(lowIdx-stepSize));
        d1 = double(imgsort(lowIdx-stepSize)-imgsort(lowIdx-2*stepSize));
        % && (d0 ~= 0) && (imgsort(lowIdx)~=imgsort(pixels)) && (lowIdx~=pixels)
        % protect against picking the maximum pixel value in the event
        % that too many are saturated
        if( ((d1 - d0) >= 0) && (d0 ~= 0) && (imgsort(lowIdx)~=imgsort(pixels)) && (lowIdx~=pixels))
            break;
        end
    end
    lowMap = imgsort(lowIdx);
    threshold = lowMap;
else
    lowMap = threshold;
end

if(haveGPU)
    if(binarise)
        imgGPU = gpuArray(img);
        thresholdGPU = gpuArray(threshold);
        maxPixelGPU = gpuArray(maxPixel);
        imgGPU = uint8((imgGPU>thresholdGPU)) * maxPixelGPU;
    else % binarise
        highMap = imgsort(ceil(pixels*upperHist));
        factor = (maxPixel - minPixel) / double(highMap - lowMap);
        imgGPU = gpuArray(int32(img));
        factorGPU = gpuArray(factor);
        lowMapGPU = gpuArray(int32(lowMap));
        imgGPU = imgGPU - lowMapGPU;
        img8GPU = uint8(floor(double(imgGPU) * factorGPU));
    end
    img = gather(img8GPU);
else
    if(binarise && (~isBrightField))
        img = uint8((img>threshold)) * maxPixel;
    else % binarise
        highMap = imgsort(ceil(pixels*upperHist));
        factor = double((maxPixel - minPixel)) / double(highMap - lowMap);
        img = img - lowMap;
        img = uint8(floor(img * factor));
    end
end

if(debug)
    figure(4);
    hist(double(imgsort),1:double(imgsort(end)));
    hold on;
    plot(lowMap,0,'ro');
    plot(highMap,0,'ro');
    plot(threshold,0,'go');
    title(sprintf('autoThresholding = %d isBright = %d',autothresholding,isBrightField));
    hold off;
end


