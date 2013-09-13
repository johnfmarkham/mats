% yet another implementation of finding well edges
function [s, imWells] = findWellsAK(img,separation)
% Finds square microwells and returns a list of well vertices
% img contains the input image
% minSep is a lower bound on well size in pixels
% it should be at least half the well width and height
% s is a list of well co-ords
% TODO: Return image
%
imID = 33;
imWells = [];
debug = 0; % Set this to zero to supress graphs

extra = 10; % widen well edges
th = 2;
d = 5;
aDegs = -7:1:7;
aRads = aDegs .* pi ./ 180;

imDims = size(img);
h = imDims(1);
w = imDims(2);

% if it's RGB, just sum the color planes and make a 2D array
if(numel(imDims) > 2)
	img = sum(img,3);
end

bw = double(edge(img,'sobel'));

% find rotation angle
dh = tan(aRads).*w;
na = numel(aRads);
maxLines = 0;
horizLines = [];
iOpt = NaN;
for i = 1:na
	dhCurr = floor(dh(i));
	yOffsets = round(linspace(0, dhCurr, w));
	
	yMin = max(1, 1 - dhCurr);
	yMax = min(h, h - dhCurr);
	
	curLines = [];
	numLines = 0;
	for y = yMin:d:yMax
		imInd = sub2ind([h, w], y + yOffsets, 1:w);
		if (sum(bw(imInd)) <= th)
			numLines = numLines + 1;
			curLines(numLines) = y;
		end
	end
	if (numLines > maxLines)
		horizLines = curLines;
		maxLines = numLines;
		iOpt = i;
	end
end
dh = dh(iOpt);

dw = floor( tan(-aRads(iOpt))*h );
xOffsets = round(linspace(0, dw, h));

xMin = max(1, 1 - dw);
xMax = min(w, w - dw);

vertLines = [];
numLines = 0;
for x = xMin:d:xMax
	imInd = sub2ind([h, w], 1:h, x + xOffsets);
	if (sum(bw(imInd)) <= th)
		numLines = numLines + 1;
		vertLines(numLines) = x;
	end
end

horizLines = [1, horizLines, h];
vertLines = [1, vertLines, w];

vDiff = [separation, diff(horizLines)];
horizLines = horizLines(vDiff >= separation);
vDiff = [separation, diff(vertLines)];
vertLines = vertLines(vDiff >= separation);

if (0)
	figure; imshow(bw);
	
	figure;
	hold on;
	for x = vertLines
		line([x, x + dw], [1, h], 'color', 'r');
		hold on;
	end
	for y = horizLines
		line([1, w], [y, y + dh], 'color', 'r');
		hold on;
	end
end

nRows = numel(horizLines) - 1;
nCols = numel(vertLines) - 1;


[tlx0, tly0] = meshgrid(vertLines(1:nCols), horizLines(1:nRows));
[brx0, bry0] = meshgrid(vertLines(2:nCols + 1), horizLines(2:nRows + 1));
[col, row] = meshgrid(1:nCols, 'A' - 1 + (1:nRows));
ca = cos(aRads(iOpt));
sa = sin(aRads(iOpt));
tlx = round( tlx0(:).*ca - tly0(:).*sa + dw) - extra;
tly = round( tlx0(:).*sa + tly0(:).*ca ) - extra;
brx = round( brx0(:).*ca - bry0(:).*sa + dw ) + extra;
bry = round( brx0(:).*sa + bry0(:).*ca ) + extra;
tlx = max(tlx, 1);
tly = max(tly, 1);
brx = min(brx, w);
bry = min(bry, h);
s = struct( ...
	'tlx', num2cell(tlx), 'tly', num2cell(tly), ...
	'brx', num2cell(brx), 'bry', num2cell(bry), ...
	'row', num2cell(char(row(:))), 'col', num2cell(num2str(col(:))));

if(debug)
	imWells = figure(imID);
	set(imWells, 'Position', [250 70 1200 900]);
	imshow(mat2gray(img));
	lineSpec = {'r:','b--','g-.','k:','c:'};
	for i=1:length(s)
		j = mod(i,3) + 1;
		hold on;
		plot([s(i).tlx, s(i).brx],[s(i).tly,s(i).tly],lineSpec{j});
		plot([s(i).tlx, s(i).brx],[s(i).bry,s(i).bry],lineSpec{j});
		plot([s(i).tlx, s(i).tlx],[s(i).tly,s(i).bry],lineSpec{j});
		plot([s(i).brx, s(i).brx],[s(i).tly,s(i).bry],lineSpec{j});
		cx = double((s(i).tlx+s(i).brx))/2;
		cy = double((s(i).tly+s(i).bry))/2;
		wellText = sprintf('%c%c',s(i).row,s(i).col);
		text(cx,cy,wellText, 'FontSize', 20, 'color', 'red', ...
			'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'center');
	end
end