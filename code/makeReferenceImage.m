%------------------------------------
function correction = makeReferenceImage(imgname,wells,usePatchwork)
%------------------------------------
% Take an image and make an uneven illuminatino correction image from it.
% Either fit something of try and do it per-well.
% Neither works fantastically.
if(nargin==2)
    usePatchwork = 0;
end
    
% Patchwork is best if you have well detection working
img = imread(imgname);
rows = size(img,1);
cols = size(img,2);
nWells = length(wells);
cellxy = zeros(nWells,2);
widths = length(wells);
heights = length(wells);
for i=1:nWells
    cellxy(i,1) = (wells(i).tlx + wells(i).brx) / 2;
    cellxy(i,2) = (wells(i).tly + wells(i).bry) / 2;
    heights(i) = (- wells(i).tly + wells(i).bry) ;
    widths(i) = (- wells(i).tly + wells(i).bry);
end

% Sample a 40x40 patch of pixels in the centre of each well
% These are what we fit to
sampleBoxRadius = round((mean(widths) + mean(heights)) / 8);
points = (sampleBoxRadius*2+1)^2 * nWells;
x = zeros(points,1);
y = zeros(points,1);
z = zeros(points,1);
medians = zeros(nWells,1);
n = 1;
m = 1;
for i=1:nWells
    for j = -sampleBoxRadius:sampleBoxRadius
        for k = -sampleBoxRadius:sampleBoxRadius
            x(n) = round(cellxy(i,1)) + j;
            y(n) = round(cellxy(i,2)) + k;
            z(n) = img(y(n),x(n));
            n = n + 1;
        end
    end
    medians(i) = median(z(m:(n-1)));
    m = n;
end

if(usePatchwork)
    % Do a patchwork correction based on the median value in the centre of each
    % well
    pixels = rows * cols;
    correction = ones(rows,1);
    correction = repmat(correction,1,cols);
    correction_img = correction;
    imgsort = sort(reshape(img,pixels,1));
    medianpixel = double(imgsort(pixels/2));
    for i=1:nWells
        x=wells(i).tlx:wells(i).brx;
        y=wells(i).tly:wells(i).bry;
        correction(y,x) =  medianpixel / double(medians(i));
        correction_img(y,x) =  medians(i);
    end
    imwrite(uint16(round(correction_img)),strcat(imgname,'.correction.tif'),'tif','Compression','none','ColorSpace','icclab');
else
    % Set params for parameter fitting to start somewhere sensible
    % Use fmincon to fit quadratic form - turns out that patchwork is better
    names = {'a0','rx','ax','ry','ay','cx','cy',};
    lb = [min(z),0,0,0,0,-0.5,-0.5];
    ub = [2^12, 1, max(x), 1, max(y),0.5,0.5 ];
    r = sqrt((max(z)-min(z))/2) / ((max(x)-min(x))/2);
    init = [max(z),r, (max(x)+min(x))/2,r,(max(y)+min(y))/2,0,0];
    for i=1:7
        fprintf(1,'%s = %4g\n',names{i},init(i));
    end
    options = optimset('MaxFunEvals', 1000, 'TolFun', 1e-1, 'Display', 'final', 'LargeScale', 'off');
    % First optimise to minimise sum of squares difference between fitted
    % surface and image
    [minvec, minval, exitflag] = ...
        fmincon(@cost0,init,[],[], [],[],lb,ub,[],options,x,y,z);
    % Then minimise the variance of the image. This looks a bit better
    % but if you do this first it may not converge to the right place.
    % It still may not, and so I've ditched it.
    %[minvec, minval, exitflag] = ...
    %    fmincon(@cost2,minvec,[],[], [],[],lb,ub,[],options,img,x,y,z);
    for i=1:7
        fprintf(1,'%s = %4g\n',names{i},minvec(i));
    end
    fprintf(1,'min = %4g\n',minval);
    y = transpose(1:rows);
    y = repmat(y,1,cols);
    x = 1:cols;
    x = repmat(x,rows,1);
    img_correct = quadraticCorrection(minvec,x,y);
    
    imwrite(uint16(round(img_correct)),strcat(imgname,'.correction.tif'),'tif','Compression','none','ColorSpace','icclab');
    % Some of the image correction is noise, not from the optics and so should
    % be constant across the image.  In theory it should be around 10.
    % If you choose a bright image to do correction from then this shoudln't
    % matter.
    noise = 0;
    % Returns an images-shaped array of floats which can be used to multiply
    % and correct matching images
    correction = (max(max(img_correct))-noise) ./ (img_correct - noise);
end
    
%------------------------------------
function ret = cost0(params,x,y,z)
%------------------------------------
% Returns "volume" between compensation image and actual one.
% Not sure if this is better than RMS
f = quadraticCorrection(params,x,y) - z;
ret = sum(abs(f)) / length(f);
fprintf(1,'a0 = %g ret = %g\n',params(1),ret);


%------------------------------------
function ret = cost1(params,x,y,z)
%------------------------------------
% Returns RMS difference between compensation image and actual one
f = quadraticCorrection(params,x,y) - z;
ret = sqrt(sum(f .* f) / length(f));
fprintf(1,'a0 = %g ret = %g\n',params(1),ret);

%------------------------------------
function ret = cost2(params,img,x2,y2,z2)
%------------------------------------
% Returns difference between compensation image and actual one +
% a term which is the fluctuations in the result. 
% Arguably this last one is what you want to minimise but you need some
% way to tie the two surfaces together so that you don't converge to 
% unphysical results
rows = size(img,1);
cols = size(img,2);
y = transpose(1:rows);
y = repmat(y,1,cols);
x = 1:cols;
x = repmat(x,rows,1);
img_correct = quadraticCorrection(params,x,y);
img_corrected = (double(img) ./ img_correct);

n = rows * cols;
s_img_corrected = sum(sum(img_corrected)) / n;

% s_img_corrected_2 = sum(sum(img_corrected .* img_corrected));
% s_img_corrected = sum(sum(img_corrected));
% s_2_img_corrected = s_img_corrected^2;
% n = rows * cols;
% ret = sqrt( s_img_corrected_2/n - s_2_img_corrected/(n*n)) / (s_img_corrected / n);
ret1 = sum(sum(img_corrected .* img_corrected))/n - (s_img_corrected * s_img_corrected);
% 
f = quadraticCorrection(params,x2,y2) - z2;
ret2 = sqrt(sum(f .* f) / length(f));
fprintf(1,'total = %g ret1 = %g ret2 = %g ',ret1+ret2,ret1,ret2);
fprintf(1,'mean =  %g std_dev = %g  ',(s_img_corrected / n),ret1 * (s_img_corrected / n));
fprintf(1,'sum_corrected = %g ',s_img_corrected);
fprintf(1,'\n');
ret = ret1 + ret2;

%------------------------------------
function f = quadraticCorrection(params,x,y)
%------------------------------------
a0 = params(1);
rx = params(2);
ax = params(3);
ry = params(4);
ay = params(5);
cx = params(6);
cy = params(7);
one = ones(size(x));

dx = rx * (x - ax * one);
dy = ry * (y - ay * one);
f = (a0 * one - dx .* dx - dy .* dy + cx * x + cy * y);





