function [im, offsets] = extractBackground(imlist,offsets)
% Find a background image for the images in imstack
% Either offsets is an array of offsets from the first image, or it is a
% maximum offset and the actual offsets are computed and returned.

% haveGPU = 0;
% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end    
% haveGPU = 0;

if(isempty(offsets) || length(offsets)==1)
    maxOffset = offsets;
    offsets = findOffsets(imlist,maxOffset);
end

im = uint16(imread(imlist{1}));

stackLength = length(offsets);
rows = size(im,1);
cols = size(im,2);

nBins = 2^10; % This decides memory use. 2.8GB for this array with 2^10 1MP
cameraPrecision = 2^12; % How many bits per pixel is the camera? This number is 2^bpp.
newMedian = nBins/4;
scaleFactor = uint16(cameraPrecision/nBins);
bins = zeros(rows,cols,nBins,'uint16');
for k=1:stackLength
    if(isempty(imlist{k}) || length(imlist{k})<2)
        continue;
    end
    fprintf(1,'Binning %s\n',imlist{k});
    im = uint16(imread(imlist{k}));
    m = double(fastMedian(im));
    % This re-scaling may not be needed. For both fluorescent and transmission images
    % can cause it to overflow the bins.
    % im = uint16(round(((double(double(newMedian)/m)) * double(shiftImage(im,offsets(k).x,offsets(k).y)))));
    
    % Based on the first image decide whether to scale images
    if(k==1 && max(max(im))<nBins)
        scaleFactor = 1;
    end
    im = shiftImage(im,offsets(k).x,offsets(k).y);
    % Scale only if we need to
    if(scaleFactor~=1)
        im = im/scaleFactor;
    end
    im = im + 1;
    im(im>nBins) = nBins;
    for j=1:rows
        for i=1:cols
            p = im(j,i);
            bins(j,i,p) = bins(j,i,p) + 1;
        end
    end
end
for j=1:rows
    if(mod(j,200)==0)
        fprintf(1,'Constructing background image row %d\n',j);
    end
    for i=1:cols
        pixhist = zeros(nBins,1);
        % Leave overflow bins behind
        % 65535 comes from overflow uint16 ops
        % 65536 comes from nBins hack above
        pixhist(1:nBins-2) = double(bins(j,i,1:nBins-2));
        s = sum(pixhist);
        cs = cumsum(pixhist);
        im(j,i) = find(cs>=(s/2),1,'first')-1;
    end
end


