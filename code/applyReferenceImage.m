%------------------------------------
function [img_correct,min_pixel,median_pixel,max_pixel,imgsort_correct] = ...
    applyReferenceImage(img,imgsort,correction,correctionsort,new_median,scalingMethod,operation,proportionBackground,haveGPU)
%------------------------------------
% Applies correction to img and optionally scales the median up.
% The last is done for two reasons. Firstly it minimises the loss
% of precision due to rounding the scaling result. Second it
% can be used to automatically normalise between frames.
% If correction is just a single number, then we assume just normalisation.
% Operation decides what will be done.
% TODO: This is called from a few places with old-style args. Fix this.
debug=0;

% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end    
% if(debug)
%     figure(3);
%     hist(double(imgsort),1:double(imgsort(end)));
% end
pixels = size(img,1) * size(img,2);
img = double(img);
imgsort = double(imgsort);
correction = double(correction);

correctionsort = double(correctionsort);
max_uint16 = 65535; % Assumes we're going to turn them into uint16's
median_img = imgsort(pixels/2);
sd_img = std(imgsort);

median_cor = correctionsort(pixels/2);
sd_cor = std(double(correctionsort));
% TODO: normalisation on quartile (restricts you to using background)
imgsort = imgsort * sd_cor/sd_img;
img = img * sd_cor/sd_img;

median_img = imgsort(pixels/2);
imgsort = imgsort + (median_cor-median_img);
img = img + (median_cor-median_img);

if(operation=='0') % do nothing - for testing - and thresholding in movies I think
    img_correct = img ; 
elseif(operation=='*')
    img_correct = (img .* correction); 
elseif(operation=='/')
    img_correct = (double(img) ./ correction); 
    img_correct(correction==0) = 0;
elseif(operation=='+')
    img_correct = img + correction; 
elseif(operation=='-') % subtract
    img_correct = img - correction; 
    img_correct(img_correct<0) = 0;
elseif(operation=='_' || operation=='t') % optionally subtract and set what looks like noise to zero
    if(operation=='_')
        img_correct = img - correction; 
    else
        img_correct = img; 
    end
    imgsort_correct = sort(reshape(img_correct,pixels,1));
    threshold = imgsort_correct(round(end*proportionBackground));
    img_correct(img_correct<threshold) = 0;
elseif(operation=='a') % subtract but take abs of result
    img_correct = img - correction; 
    img_correct = abs(img_correct);
elseif(operation=='^') % subtract but square the result
    img_correct = img - correction; 
    img_correct = img_correct.*img_correct;
elseif(operation=='4') % subtract but ^4 the result
    img_correct = img - correction; 
    img_correct = img_correct.*img_correct;
    img_correct = img_correct.*img_correct;
end
% TODO: Some checks in here to prevent silly combinations
if(strcmp(scalingMethod,'median'))
    imgsort_correct = sort(reshape(img_correct,pixels,1));
    median_pixel = imgsort_correct(pixels/2);
    img_correct = img_correct * (new_median/median_pixel);
elseif(strcmp(scalingMethod,'minmax'))
    minPix = min(min(img_correct));
    maxPix = max(max(img_correct));
    img_correct = (max_uint16/(maxPix-minPix)) * (img_correct - minPix);
else
    scale = str2num(scalingMethod);
    img_correct = scale * img_correct;
end

if(max(max(img_correct)) > max_uint16)
    % fprintf(1,'Warning: Scaling may result in loss of bright pixels\n');
    img_correct = min(img_correct,max_uint16);
end
img_correct = uint16(round(img_correct));
imgsort_correct = sort(reshape(img_correct,pixels,1));
median_pixel = imgsort_correct(pixels/2);
max_pixel = imgsort_correct(end);
min_pixel = imgsort_correct(1);
if(debug)
        figure(1);
        subplot(1,2,2);
        [y1,x1] = hist(double(imgsort_correct),100);
        plot(x1,log10(y1),'r');
        legend('Corrected');
        subplot(1,2,1);
        [y2,x2] = hist(double(imgsort),0:0.01:1);
        [y3,x3] = hist(correctionsort,0:0.01:1);
        plot(x2,log10(y2),'g',x3,log10(y3),'r');
        legend('Original','Background');
end
% TODO: Incorporate GPU
% if(new_median~=0) 
%     % imgsort = sort(reshape(img,pixels,1));
%     median_pixel = imgsort(pixels/2);
%     max_pixel = imgsort(end);
%     min_pixel = imgsort(1);
%     img_scale = new_median / double(median_pixel);
%     if(img_scale * double(max_pixel) * max(max(correction)) >= 2^16)
%         fprintf(1,'Warning: Scaling may result in loss of bright pixels\n');
%     end
%     if(haveGPU)
%         imgGPU = gpuArray(img);
%         scaleGPU = gpuArray(img_scale);
%         if(length(correction)>1)
%             correctionGPU = gpuArray(correction);
%             img_correctGPU = uint16(round(double(imgGPU) .* correctionGPU * scaleGPU));
%         else
%             img_correctGPU = uint16(round(double(imgGPU) * scaleGPU));
%         end
%         img_correct = gather(img_correctGPU);
%     else
%         if(length(correction)>1)
%             img_correct = uint16(round(double(img) .* correction * img_scale));
%         else
%             img_correct = uint16(round(double(img) * img_scale));
%         end
% elseif(nargin==4)
%     median_pixel = imgsort(pixels/2);
%     max_pixel = imgsort(end);
%     min_pixel = imgsort(1);
%     if(length(correction)>1)
%         if(haveGPU)
%             imgGPU = gpuArray(img);
%             correctionGPU = gpuArray(correction);
%             img_correctGPU = uint16(round(double(imgGPU) .* correctionGPU));
%             img_correct = gather(img_correctGPU);
%         else
%             img_correct = uint16(round(double(img) .* correction));
%         end
%     else
%         img_correct = img;
%     end
% else
%     
% end


