function [filtImg mesg] = caFilter(inputImg,minAdjacent,maxIter,tol,haveGPU)
% implements a 2D cellular automata filter a monochrome image that has had
% some noisy pixels set to zero
% 
if(isempty(maxIter))
    maxIter = 4;
end
if(isempty(minAdjacent))
    minAdjacent = 2;
end

boxRadiusx = 1;
boxRadiusy = 1;
inputImgInfo = whos('inputImg');
boxWidth = (boxRadiusx*2 + 1) * (boxRadiusy*2 + 1);
%medianIndex = ceil(boxWidth/2);
% If there are extra layers, assume they are planes put into to give more
% info. The first one is the main plane from this time point on - refImg.
haveExtraPlanes = length(inputImgInfo.size)-2;
bitplanes = inputImgInfo.size(end);
if(haveExtraPlanes)
    nExtraPlanes = size(inputImg,3)-1;
    refImg = inputImg(:,:,1); % main plane
else
    nExtraPlanes = 0;
    refImg = inputImg;
end

stackDim = [size(inputImg,1),size(inputImg,2), boxWidth-1+nExtraPlanes];


rows = size(inputImg,1);
cols = size(inputImg,2);
pixels = rows * cols;
stackType = inputImgInfo.class;
stack = zeros(stackDim,stackType);
% Preload the stack with the extra images
if(haveExtraPlanes)
    stack(:,:,boxWidth:end) = inputImg(:,:,2:end);
end
if(haveGPU)
    stackGPU =  parallel.gpu.GPUArray.zeros(stackDim,inputImgInfo.class);
    refImgGPU = gpuArray(refImg);
end
k=0;
oldNZP = 0;
zeroPixels = sum(sum(refImg==0,1,'double'));
nzp = pixels - zeroPixels;
mesg = sprintf('CA filter: iter = %d zeroPixels = %d Proportion nonzero = %f\n',k,zeroPixels,nzp/pixels);
for k=1:maxIter 
    layer = 0;
    for i=-boxRadiusx:1:boxRadiusx
        for j=-boxRadiusy:1:boxRadiusy
            % Self-plane gets skipped
            if(i==0 && j==0)
                continue;
            end
            layer = layer + 1;
            yMin = max(1,1-j);
            yMax = min(rows,rows-j);
            xMin = max(1,1-i);
            xMax = min(cols,cols-i);
            x = xMin:xMax;
            y = yMin:yMax;
            if(haveGPU)
                stackGPU(y,x,layer) = refImgGPU(y+j,x+i);
            else
                stack(y,x,layer) = refImg(y+j,x+i);
            end
        end
    end
    % We stop short of the extra planes in the stack
    if(haveGPU)
        stack = gather(stackGPU);
    end

    zeroPixels = (stack==0);
    nonzeroPixels = ~zeroPixels;
    mask = (sum(nonzeroPixels,3)< minAdjacent);
    filtImg = refImg;
    filtImg(mask) = 0;
    refImg = filtImg;
    
    zeroPixels = sum(sum(refImg==0,1,'double'));
    nzp = pixels - zeroPixels;
    mesg = strcat(mesg,sprintf('CA filter: iter = %d zeroPixels = %d Proportion nonzero = %f\n',k,zeroPixels,nzp/pixels));
    if(oldNZP==nzp || abs(nzp-oldNZP)/(nzp+oldNZP) < tol)
        return;
    end
    oldNZP = nzp;
end
