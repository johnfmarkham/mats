%------------------------------------
function im = globReferenceImages(experimentDetails)
%------------------------------------

% Average the set of images specified by dirPattern to produce a reference
% image. Assumes that they are all 16 bit monochrome tifs
% Also does some smoothing on the result to get rid of noise

dirPattern = fullfile(experimentDetails.dir, experimentDetails.dirPattern);
dirList = dir(dirPattern);
files = length(dirList);
im=[];
if(files==0)
    fprintf(1,'No match for %s\n',dirPattern);
    return;
end
im = imread(fullfile(experimentDetails.dir,dirList(1).name));
im_sum = zeros(size(im));
debug = 0;

j = 0;
for i=1:files
    file = dirList(i);
    if(file.isdir)
        fprintf(1,'%s is not an image file\n',file.name); 
    end
    im = double(imread(fullfile(experimentDetails.dir,file.name)));
    % If the reference image is getting bleached then this will correct
    newMedian = median(im(:)) - experimentDetails.dc_offset;
    if(experimentDetails.doNormalisation && i>1)
        meansMedian = median(im_sum(:))/(i-1);
        im_sum = im_sum + (meansMedian/newMedian) * (im - experimentDetails.dc_offset);
    else
        im_sum = im_sum + im - experimentDetails.dc_offset;
        meansMedian = median(im_sum(:))/i;
    end
    fprintf(1,'Adding %s to reference image. Median = %8.1f Previous stack median = %8.1f\n',file.name,newMedian,meansMedian); 
end
im = im_sum * (1/files);
for i=1:experimentDetails.smoothing_iterations
    im = smooth1d(im);
    fprintf(1,'Smoothing # %d\n',i); 
    if(debug)
        dy2dx2 = smooth2d(im,[0,1,0,1,-4,1,0,1,0]);
        fprintf(1,'2nd Derivative: (min,mean,max) = (%f,%f,%f)\n',min(min(dy2dx2)),mean(mean(double(dy2dx2))),max(max(dy2dx2))); 
    end
end
maxPixel = max(max(im));
im = im * (experimentDetails.maxPixel/maxPixel);
im = uint16(round(im));

%------------------------------------
function ret = smooth2d(img,coefficients)
%------------------------------------
% implements a smoothing filter on im
%  Can take alternative values in coefficients, in which case does
%  something else
refImgInfo = whos('img');
boxRadiusx=1;
boxRadiusy=1;
boxWidth = (boxRadiusx*2 + 1) * (boxRadiusy*2 + 1);
stackDim = [ size(img) , boxWidth];
stack = zeros(stackDim,refImgInfo.class);
rows = size(img,1);
cols = size(img,2);
% Middle of a gaussian kernel from here:
% http://homepages.inf.ed.ac.uk/rbf/HIPR2/gsmooth.htm
if(isempty(coefficients))
    coefficients = [16,26,16,26,41,26,16,26,16];
    coefficients  = coefficients / sum(coefficients);
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
        stack(y,x,layer) = img(y+j,x+i);
        % Deal with the edges by copying whatever layer got the edge to the others
        if(xMin==2)
            stack(y,1,layer) = stack(y,2,layer);
        end
        if(yMin==2)
            stack(1,x,layer) = stack(2,x,layer);
        end
        if(xMax==cols-1)
            stack(y,cols,layer) = stack(y,cols-1,layer);
        end
        if(yMax==rows-1)
            stack(rows,x,layer) = stack(rows-1,x,layer);
        end
    end
end
% lazy and not necessarily correct way of doing the corner points
stack(1,1,:) = median(stack(1,1,:));
stack(1,end,:) = median(stack(1,end,:));
stack(end,1,:) = median(stack(end,1,:));
stack(end,end,:) = median(stack(end,end,:));

for z = 1:boxWidth;
    stack(:,:,z) = stack(:,:,z) * coefficients(z);
end
ret = sum(stack,3);


%------------------------------------
function ret = smooth1d(img)
%------------------------------------
% implements a smoothing filter on im
% 
% Complete 1-D gaussian kernel from here:
% http://homepages.inf.ed.ac.uk/rbf/HIPR2/gsmooth.htm
% done on x and y direction
refImgInfo = whos('img');
boxRadiusx=3;
boxRadiusy=3;
boxWidth = (boxRadiusx*2 + 1);

rows = size(img,1);
cols = size(img,2);

xcols = cols + boxRadiusx * 2;
xrows = rows + boxRadiusy * 2;

stackDim = [ xrows, xcols , boxWidth];
stack = zeros(stackDim,refImgInfo.class);
ximg = zeros(xrows, xcols);
x=1:cols;
y=1:rows;
% middle
ximg(y+boxRadiusy,x+boxRadiusx) = img(y,x);
% top strip
ximg(1:boxRadiusy,x+boxRadiusx) = repmat(img(1,x),boxRadiusy,1);
% bottom strip
ximg(rows+boxRadiusy+1:xrows,x+boxRadiusx) = repmat(img(rows,x),boxRadiusy,1);
% left strip
ximg(y+boxRadiusy,1:boxRadiusx) = repmat(img(y,1),1,boxRadiusx);
% right strip
ximg(y+boxRadiusy,cols+boxRadiusx+1:xcols) = repmat(img(y,1),1,boxRadiusx);
% top left
ximg(1:boxRadiusy,1:boxRadiusx) = img(1,1);
% bottom left
ximg(rows+boxRadiusy+1:xrows,1:boxRadiusx) = img(rows,1);
% bottom right
ximg(rows+boxRadiusy+1:xrows,cols+boxRadiusx+1:xcols) = img(rows,cols);
% top right
ximg(1:boxRadiusy,cols+boxRadiusx+1:xcols) = img(1,cols);
% At this point ximg contains img with a border around the edge set to the
% edge pixel. Now we do two 1-D Gaussian filterings
% Gaussian 1-D kernel from here:
% http://homepages.inf.ed.ac.uk/rbf/HIPR2/gsmooth.htm
coefficients = [0.006,0.061,0.242,0.383,0.242,0.061,0.006];
coefficients  = coefficients / sum(coefficients);
% TODO: Why is there a black strip on this
layer = 0;
for i=-boxRadiusy:1:boxRadiusy
    layer = layer + 1;
    stack(y+boxRadiusy,:,layer) = ximg(y+boxRadiusy+i,:);
end
for z = 1:boxWidth;
    stack(:,:,z) = stack(:,:,z) * coefficients(z);
end
ximg = sum(stack,3);

layer = 0;
for i=-boxRadiusx:1:boxRadiusx
    layer = layer + 1;
    stack(:,x+boxRadiusx,layer) = ximg(:,x+boxRadiusx+i);
end
for z = 1:boxWidth;
    stack(:,:,z) = stack(:,:,z) * coefficients(z);
end
ximg = sum(stack,3);

ret = ximg(y+boxRadiusy,x+boxRadiusx);



