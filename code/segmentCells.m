function lblImg = segmentCells(img, minArea,maxArea,maxEccentricity,minSolidity)
% Segments using watershed, thresholding must be done first.
%TODO: parameterise this
debug = 0;
kernelRadius = 5;
denom = double(max(img(:)-min(img(:))));
if(denom==0 || isempty(denom))
    lblImg = zeros(size(img),'uint16');
    return;
end
img = imfill(img, 'holes');
imgN = double(img-min(img(:)))/denom;

% th1=graythresh(imgN);
% 
th1 = 0;
cellMsk = imgN>th1;
if(debug)
    figure(114);
    subplot(2,2,1);
    imshow(cellMsk);
end
% Smooth the raw image (to avoid oversegmentation)


[xx,yy]=ndgrid(-kernelRadius:kernelRadius,-kernelRadius:kernelRadius);
gf = exp((-xx.^2-yy.^2)/20);
filtImg = conv2(imgN,gf,'same');
if(debug)
    subplot(2,2,2),imshow(filtImg,[])
end

% Separate touching cells 
%ws = watershed(filtImg);
%ws = watershed(imgN);
ws = watershed(img);
ws(~cellMsk) = 0;
% Make labelled image
lblImg = bwlabel(ws);
if(debug)
    subplot(2,2,3),imshow(lblImg);
    % figure,imshow(label2rgb(lblImg,'jet','k','shuffle'));
end
% Measure everything
x = regionprops(lblImg, 'all');
areas = [x.Area];
eccentricities = [x.Eccentricity];
solidities = [x.Solidity];
idx = find((solidities>minSolidity) & (areas>=minArea) & (areas<=maxArea) & (eccentricities<maxEccentricity));
% Make a mask to select wanted objects
mask = ismember(lblImg,idx);
% Fill in holes
mask = imfill(mask, 'holes');
% Turn logical image back into labelled image
lblImg = uint16(round(bwlabel(mask, 8)));
if(debug)
    subplot(2,2,4); imshow(lblImg);
    imrgb = label2rgb(lblImg,'lines','k');
    subplot(2,2,4); imshow(imrgb);
end


