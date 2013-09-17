function [s im_h] = findWells(img,autoFind,separation,overlap)
% Finds square microwells and returns a list of well vertices
% img contains the input image
% minSep is a lower bound on well size in pixels
% it should be at least half the well width and height
% s is a list of well co-ords
% TODO: Return image
% 
im_h = [];
debug = 1; % Set this to zero to supress graphs
upIsDown = 1; % matlab plotting and avisynth pixel y are opposites
imgInfo = whos('img');
haveColorPlanes = length(imgInfo.size)-2;
% if it's RGB, just sum the color planes and make a 2D array
if(haveColorPlanes)
    img = sum(img,3);
end

% sum of intensities. This is what we want to maximise
xf = transpose(sum(img,1));
yf = sum(img,2);
% normally image co-ords for rows starts at top, not bottom
% however in the image I displayed this didn't happen, so I've
% commented out this swap
% yf(1:end) = yf(end:-1:1);

% Apply a smoothing filter a lot of times to iron out some 
% local maxima
for i=1:256
    xf = mr_smoothy(xf);
    yf = mr_smoothy(yf);
end
% Find the remaining local maxima
xfm = findLocalMaxima(xf);
yfm = findLocalMaxima(yf);
xlen = size(img,2);
ylen = size(img,1);

if(autoFind)
    % There will still be unwanted ones. Get rid of them.
    minSep = separation;
    xfm = pruneLocalMaxima(xf,xfm,minSep);
    yfm = pruneLocalMaxima(yf,yfm,minSep);
    % make results list
    rows = length(yfm)-1;
    cols = length(xfm)-1;
    n = 1;
    s = repmat(struct('tlx',0,'tly',0,'brx',0,'bry',0),1,rows*cols);
    rowlabel = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for i=1:cols
        for j=1:rows
            s(n).tlx = xfm(i);
            s(n).tly = yfm(j);
            s(n).brx = xfm(i+1);
            s(n).bry = yfm(j+1);
            s(n).row = rowlabel(rows-j+1);
            s(n).col = sprintf('%d',i);
            n = n + 1;
        end
    end
else
    cols = max(round(xlen/separation),1);
    rows = max(round(ylen/separation),1);
    n = 1;
    s = repmat(struct('tlx',0,'tly',0,'brx',0,'bry',0),1,rows*cols);
    rowlabel = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for i=1:cols
        for j=1:rows
            s(n).tlx = max(1,(i-1) * separation - overlap/2);
            s(n).tly = max(1,(j-1) * separation - overlap/2);
            s(n).brx = min(xlen,i * separation + overlap/2);
            s(n).bry = min(ylen,j * separation + overlap/2);
            s(n).tlx = snapToMax(s(n).tlx,xfm);
            s(n).tly = snapToMax(s(n).tly,yfm);
            s(n).brx = snapToMax(s(n).brx,xfm);
            s(n).bry = snapToMax(s(n).bry,yfm);
            s(n).row = rowlabel(rows-j+1);
            s(n).col = sprintf('%d',i);
            n = n + 1;
        end
    end
end

if(upIsDown)
    for i=1:length(s)
        tmp = s(i).tly;
        s(i).tly = ylen + 1 - s(i).bry;
        s(i).bry = ylen + 1 - tmp;
    end
end

if(debug)
    if(autoFind)
        figure(1);
        n = 1:length(xf);
        plot(n,xf,xfm,xf(xfm),'o');
        xlabel('x');
        ylabel('S I(x,y)dy');
        figure(2);
        n = 1:length(yf);
        plot(n,yf,yfm,yf(yfm),'o');
        xlabel('y');
        ylabel('S I(x,y)dx');
    end
    im_h = figure (33);
    hold on;
    colormap(gray(256))
    minPixel = min(min(img));
    maxPixel = max(max(img));
    img = 255.0 * (double(img)-double(minPixel))/double(maxPixel-minPixel);
    img = uint16(img);
    rows = size(img,1);
    img(:,:) = img(rows:-1:1,:);
    image(img);
    lineSpec = {'r:','b--','g-.','k:','c:'};
    for i=1:length(s)
        j = mod(i,3) + 1;
        plot([s(i).tlx, s(i).brx],[s(i).tly,s(i).tly],lineSpec{j});
        plot([s(i).tlx, s(i).brx],[s(i).bry,s(i).bry],lineSpec{j});
        plot([s(i).tlx, s(i).tlx],[s(i).tly,s(i).bry],lineSpec{j});
        plot([s(i).brx, s(i).brx],[s(i).tly,s(i).bry],lineSpec{j});
        cx = double((s(i).tlx+s(i).brx))/2;
        cy = rows - (double((s(i).tly+s(i).bry))/2);
        wellText =  sprintf('%c%c',s(i).row,s(i).col);
         text(cx,cy,wellText, 'FontSize', 20, 'color', 'red', ...
        'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'center');
    end
    hold off; 
    xlim([0, size(img,2)]);
    ylim([0, size(img,1)]);
    % if(positionDetails.threads>1) TODO: Fix this
    %im = getframe;
    %img = im.cdata;
end

%------------------------------------
function f = mr_smoothy(f)
% Apply a simple low pass filter
f_0 = [f; f(end); f(end)];
f_1 = [f(1); f; f(end)];
f_2 = [f(1); f(1); f];

f = 0.5 * (0.5 * (f_0 + f_2) + f_1);
f = f(2:end-1);

%------------------------------------
function maxima = pruneLocalMaxima(f,fm,minSep)
% Staring from the highest local maximum, get rid all other maxima
% within minSep of eachother
% f = the function 
% fm = locations of its maxima
n = length(fm);
fmi = f(fm); % an array of the maxima
fmax = max(fmi);
for i=1:n
    if(fmi(i)==fmax)
        break
    end
end
% Prune on distance criteria
% prune to the right of highest peak
ifmax = i;
currentMax = ifmax;
for i=ifmax:n-1
    if(fm(i+1)-fm(currentMax) < minSep)
        fm(i+1) = 0;
    else
        currentMax = i+1;
    end
end

% prune to the left
currentMax = ifmax;
for i=ifmax:-1:2
    if(fm(currentMax)-fm(i-1) < minSep)
        fm(i-1) = 0;
    else
        currentMax = i-1;
    end
end
maxima = fm(fm~=0);

%------------------------------------
function t = snapToMax(t,maxima)
% Quantises t to the closest value in maxima

% Round them to integers first. Something fishy was going on...
t = int16(round(t));
maxima = int16(round(maxima));
diff = abs(maxima-t);
minDiff = min(diff);
% But you can only snap to within 10 pixels
if(minDiff > 10)
    return;
end
idx = find(((minDiff-diff)==0),1,'first');
t = maxima(idx);

%------------------------------------
function maxima = findLocalMaxima(f)
% Return local maxima and points of inflection when df/dt>0 on either side
% Assumes maxima on the boundary to force well boundary where perhaps we
% wouldn't otherwise get one.
boundaryAlwaysWellEdge = 1;

nMaxima = 0;
% First deal with LH boundary
if(boundaryAlwaysWellEdge)
    nMaxima = nMaxima + 1;
    maxima(nMaxima) = 1;
elseif(f(1)>f(2))
    nMaxima = nMaxima + 1;
    maxima(nMaxima) = 1;
elseif (f(1)==f(2) && f(1) > f(3)) 
    nMaxima = nMaxima + 1;
    maxima(1) = 2;
end
% now find real maxima
n = length(f);
for i=2:n-1
    if(f(i-1) < f(i) && f(i+1)<=f(i))
        nMaxima = nMaxima + 1;
        maxima(nMaxima) = i;
    end
end
% Then deal with RH boundary
if(boundaryAlwaysWellEdge)
    nMaxima = nMaxima + 1;
    maxima(nMaxima) = n;
elseif(f(n)>f(n-1))
    nMaxima = nMaxima + 1;
    maxima(nMaxima) = n;
end
return;



