function ret = shiftImage(im,x,y)
% Shift an image by a set number of pixels. Can be half a pixel! 
% See majorityRulesFilter() for GPU

% haveGPU = 0;
% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end    
% haveGPU = 0;

rows = size(im,1);
cols = size(im,2);
ret = zeros(rows,cols,'uint16');
% Looping over these makes 
xHi = ceil(x);
xLow = floor(x);
yHi = ceil(y);
yLow = floor(y);
iter = 0;
for i=xLow:1:xHi
    for j=yLow:1:yHi
        yMin = max(1,1-j);
        yMax = min(rows,rows-j);
        xMin = max(1,1-i);
        xMax = min(cols,cols-i);
        x = xMin:xMax;
        y = yMin:yMax;
        if(iter==0)
            ret(y,x) = im(y+j,x+i);
        else
            imshift = im(y+j,x+i);
            ret(y,x) = ret(y,x) + imshift;
            % Prevent grey strips by making them 0
            ret(imshift==0) = 0;
        end
        iter = iter + 1;
    end
end
if(iter>1)
	ret(y,x) = uint16(ret(y,x) * (1.0/iter));
end
