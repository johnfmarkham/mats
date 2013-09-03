function filtImg = medianFilterGPU(refImg,boxRadiusx,boxRadiusy)
% implements a median filter on an rgb image
% rgb filtered separately
% 
haveGPU = 0;
if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
    g = gpuDevice;
    haveGPU = (g.ComputeCapability > 1.3);
end    

refImgInfo = whos('refImg');
boxWidth = (boxRadiusx*2 + 1) * (boxRadiusy*2 + 1);
medianIndex = ceil(boxWidth/2);
stackDim = [ size(refImg) , boxWidth];
haveColorPlanes = length(refImgInfo.size)-2;
bitplane = 1:refImgInfo.size(end); % only used for color
rows = size(refImg,1);
cols = size(refImg,2);

if(haveGPU)
    stackGPU =  parallel.gpu.GPUArray.zeros(stackDim,refImgInfo.class);
    refImgGPU = gpuArray(refImg);
end

layer = 0;
for i=-boxRadiusx:1:boxRadiusx
    for j=-boxRadiusy:1:boxRadiusy
        layer = layer + 1;
        yMin = max(1,1-j);
        yMax = min(rows,rows-j);
        xMin = max(1,1-i);
        xMax = min(cols,cols-i);
        x = xMin:xMax;
        y = yMin:yMax;
        if(haveGPU)
            if(haveColorPlanes)
                stackGPU(y,x,bitplane,layer) = refImgGPU(y+j,x+i,bitplane);
            else
                stackGPU(y,x,layer) = refImgGPU(y+j,x+i);
            end
        else
            if(haveColorPlanes)
                stack(y,x,bitplane,layer) = refImg(y+j,x+i,bitplane);
            else
                stack(y,x,layer) = refImg(y+j,x+i);
            end
        end
    end
end

if(haveGPU)
    stack = gather(stackGPU);
end

if(haveColorPlanes)
    filtImg = median(stack,4);
else
    filtImg = median(stack,3);
end

