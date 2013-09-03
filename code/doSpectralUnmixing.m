function [unmixed1,unmixed2] = doSpectralUnmixing(im1,im2,params)
haveGPU = 0;
% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end    
% Either pass the params or a file to get them from
if(ischar(params))
    offdiagonals = textread(params);
else
    offdiagonals = params;
end
% Construct unmixing matrix from off diagonal terms in mixing matrix
if(haveGPU)
    im1GPU = gpuArray(double(im1));
    im2GPU = gpuArray(double(im2));
    
    m = ones(2,2);
    m(2,1) = -offdiagonals(1);
    m(1,2) = -offdiagonals(2);
    det = 1 - m(2,1) * m(1,2);
    mGPU = gpuArray(m /det);
    unmixed1GPU = m(1,1) * double(im1) + m(1,2) * double(im2);
    unmixed2GPU = m(2,1) * double(im1) + m(2,2) * double(im2);
    unmixed1 = uint16(gather(unmixed1GPU));
    unmixed2 = uint16(gather(unmixed2GPU));
else
    m = ones(2,2);
    m(2,1) = -offdiagonals(1);
    m(1,2) = -offdiagonals(2);
    det = 1 - m(2,1) * m(1,2);
    m = m /det;
    unmixed1 = uint16(m(1,1) * double(im1) + m(1,2) * double(im2));
    unmixed2 = uint16(m(2,1) * double(im1) + m(2,2) * double(im2));
end


