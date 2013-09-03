function [im, offsets] = extractBackground2(imlist,offsets)
% Find a background image for the images in imstack
% Either offsets is an array of offsets from the first image, or it is a
% maximum offset and the actual offsets are computed and returned.

% Worth using GPU. At least 4x speedup
haveGPU = 0;
% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end    
% haveGPU = 0;

if(isempty(offsets) || length(offsets)==1)
    maxOffset = offsets;
    offsets = findOffsets3(imlist,maxOffset);
end

im = uint16(imread(imlist{1}));

stackLength = length(offsets);
rows = size(im,1);
cols = size(im,2);

% nBins = 2^10; % This decides memory use. 2.8GB for this array with 2^10 1MP
cameraPrecision = 2^12; % How many bits per pixel is the camera? This number is 2^bpp.
% newMedian = nBins/4;
scaleFactor = uint16((2^16)/cameraPrecision);
meanImg = zeros(rows,cols,'uint16');
meanAll = zeros(rows,cols,'double');

meanStackLength = floor(stackLength/scaleFactor);
if(meanStackLength>32)
    meanStack = zeros(rows,cols,meanStackLength,'uint16');
else
    meanStack = zeros(rows,cols,stackLength,'uint16');
end

for k=1:stackLength
    if(isempty(imlist{k}) || length(imlist{k})<2)
        continue;
    end
    fprintf(1,'Binning %s\n',imlist{k});
    im = uint16(imread(imlist{k})); % just in case it's not a 16 bit image
    meanImg = meanImg + im;
    % meanAll = meanAll + double(im);
    if(meanStackLength>32 && mod(k,scaleFactor)==0)
        meanStack(:,:,k/scaleFactor) = meanImg;
        meanImg = zeros(rows,cols,'uint16');
    else
        meanStack(:,:,k) = im;
    end
end
meanStackLength = size(meanStack,3);
min_k = min(min(min(meanStack)));
max_k = max(max(max(meanStack)));
fprintf(1,'Found pixels in the range %d - %d\n',min_k,max_k);
im = zeros(rows,cols,'uint16');
old_cumsum = (sum(meanStack<=min_k,3) < (stackLength/2));
% maxfreq = zeros(rows,cols,'uint16');

if(haveGPU)
    old_cumsum_GPU = gpuArray(double(old_cumsum));
    cumsum_GPU = gpuArray(double(old_cumsum));
    meanStack_GPU = gpuArray(double(meanStack));
    im_GPU = gpuArray(double(im));
    med_lim_GPU = gpuArray(double(meanStackLength/2));
    for k=min_k:max_k
        if(mod(k,100)==0)
            fprintf(1,'Finding medians for pixels = %d\n',k);
        end
        k_GPU = double(gpuArray(k));
        cumsum_GPU = (sum(meanStack_GPU<=k_GPU+1,3)< med_lim_GPU);
        im_GPU(old_cumsum_GPU & (~cumsum_GPU)) = k_GPU;
        old_cumsum_GPU = cumsum_GPU;
    end
    im = uint16(gather(im_GPU));
else
    for k=min_k:max_k
        if(mod(k,100)==0)
            fprintf(1,'Finding medians for pixels = %d\n',k);
        end
    %     freq = uint16(sum(meanStack==k,3));
    %     maxfreq = max(freq,maxfreq);
    %     im(freq==maxfreq) = k;
        % im gets median
        cumsum = (sum(meanStack<=k+1,3) < (meanStackLength/2));
        im(old_cumsum & (~cumsum)) = k;
        old_cumsum = cumsum;
    end
    % if(sum(sum(sum(meanStack<=min_k,3)>=(stackLength/2))))
    %     fprintf(1,'Warning: the median seems to be less than the minimum pixel\n');
    % end
    % im(sum(meanStack<=min_k,3)>=(stackLength/2)) = min_k;
end



