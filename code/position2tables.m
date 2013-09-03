function [histograms, pixelCounts,autoThresholds] = position2tables(positionDetails,experimentDetails)
% Convert files from one well or microwell position to tables of values
% histograms(level,channel) are intensity histograms for the whole image series
% pixelCounts(timePoint,channel) are numbers of pixels in each channel above thresholds

dir = positionDetails.dir;
pattern = positionDetails.pattern; 
timePoints = positionDetails.timePoints; 
channels = positionDetails.channels; 
channelNumbers = positionDetails.channelNumbers;
thresholds = experimentDetails.thresholds;

histograms = zeros(2^16,channels);
pixelCounts = zeros(timePoints,channels);
autoThresholds = zeros(timePoints,channels);
log_fprintf(positionDetails,'Processing images from %s\n',dir);

for i =1:timePoints
    for j=1:channels
        if(positionDetails.filenameIncrementsTime)
            filename = sprintf(pattern,i,channelNumbers(j));
        else
            filename = sprintf(pattern,i,channelNumbers(j));
        end
        filename = strcat(dir,filename);
        log_fprintf(positionDetails,'Processing %s\n',filename);
        img16 = uint16(imread(filename));
        autoThresholds(i,j) = autoThreshold(img16);
        for m = 1:size(img16,1)
            for n = 1:size(img16,2)
                histograms(img16(m,n)+1,j) = ...
                    histograms(img16(m,n)+1,j) + 1;
            end
        end
        if(experimentDetails.autothresholding==0)
            img16(img16<thresholds(j)) = 0;
        else
            img16(img16<autoThresholds(j)) = 0;
        end
        img16 = medianFilter(img16,1,1);
        pixelCounts(i,j) = sum(sum(img16>0));
    end
end

%---------------------------------------
function threshold = autoThreshold(img)
% Make display mappings to maximise contrast
pixels = size(img,1) * size(img,2);
lowerHist = 0.001;
upperHist = 0.999;
imgsort = sort(reshape(img,pixels,1));
stepSize = floor(pixels/100);
for lowIdx=pixels:-stepSize:1
    d0 = double(imgsort(lowIdx)-imgsort(lowIdx-stepSize));
    d1 = double(imgsort(lowIdx-stepSize)-imgsort(lowIdx-2*stepSize));
    if( (d1 - d0) >= 0)
        break;
    end
end
threshold = imgsort(floor(pixels*upperHist));
