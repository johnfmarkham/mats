% A1 = imread('test.tif');
% A2 = imread('test2.tif');
% A3 = imread('test3.tif');
% A4 = imread('test4.tif');
% A5 = imread('test5.tif');
% A6 = imread('test6.tif');

function [ s out_h boxes] = findWells2( inImage, inGrid, boxGrowth)
    DEBUG = 1;
    LINE_SPACING = 5;
    BOX_GROWTH = 20;
    if(nargin<=1)
       inGrid = 1; 
    end
    if(nargin>2)
       BOX_GROWTH = boxGrowth; 
    end
    
    if(~inGrid)
        BOX_GROWTH = BOX_GROWTH+20;
    end
    if(DEBUG)
       profile on; 
    end
    si = size(inImage);
    
    gaussVars = [1 5 10 15 20 25];
    widthVars = 2:20;
    boxes = cell([length(gaussVars) length(widthVars)]);
    images = cell(size(boxes));
    for i=1:length(gaussVars)
        image1 = process(inImage, gaussVars(i), gaussVars(i), 50, 50)<1;
        images{i} = image1;
        % Pass over image trying to find solid lines with length in certain
        % range.
        [horzSegs, vertSegs] = getSegments(image1, LINE_SPACING);
        for j=1:length(widthVars)
            maxWidth = si(2)/widthVars(j);
            minWidth = maxWidth/2.3;
            [horzLines, vertLines] = filterSegments(horzSegs, vertSegs, minWidth, maxWidth);
            trimLinkThres = min(minWidth/LINE_SPACING, 10);
            boxes{i,j} = boxesFromLines(horzLines, vertLines, trimLinkThres);
        end
    end
    bestBoxes = selectBestBoxes(boxes, inImage);
    % Remove boxes that are very different to average size
    bestBoxes = trimBoxes(bestBoxes);
    if inGrid
        [hGrid vGrid] = boxesToGrid(bestBoxes);
        [bestBoxes, hGrid, vGrid] = removeOverlaps(bestBoxes, hGrid, vGrid);
        bestBoxes = addMissingBoxes(bestBoxes, hGrid, vGrid);
        [hGrid vGrid] = boxesToGrid(bestBoxes);
        bestBoxes = alignToGrid(bestBoxes, hGrid, vGrid);
        len = size(bestBoxes,1);
        bestBoxes = cat(2, bestBoxes, (1:len)',(1:len)');
        for i=1:len
            [y x] = getGridCoords(bestBoxes, hGrid, vGrid, i);
            bestBoxes(i,5:6) = [y x];
        end
    else
        bestBoxes(:,5:6) = assignLocs(bestBoxes);
    end
    % Increasing size of boxes by certain number.
    bestBoxes = growBoxes(bestBoxes, BOX_GROWTH, si);
    len = size(bestBoxes,1);
    for i=1:len
        [y x] = getGridCoords(bestBoxes, hGrid, vGrid, i);
        bestBoxes(i,5:6) = [y x];
    end
    s = matToStruct(bestBoxes);
    
    if(DEBUG)
%         [hGrid vGrid] = boxesToGrid(bestBoxes);
        profile off;
        bestBoxes = cat(2, bestBoxes, (1:len)',(1:len)');
        %drawDebug(bestBoxes, inImage, images{i(1)});
        out_h = drawImage(inImage, bestBoxes);
    end
end

function boxes = alignToGrid(boxes1, hGrid, vGrid)
    boxes = boxes1(:,1:4);
    for i=1:size(boxes1,1)
        [y x] = getGridCoords(boxes1, hGrid, vGrid, i);
        box = boxFromGrids(boxes1, hGrid, vGrid, y, x);
        boxes(i,:) = box;
    end
end

function locs = assignLocs(boxes)
    [~, vGrid] = boxesToGrid(boxes);
    grid = sortVGrid(vGrid, boxes);
    locs = zeros([size(boxes,1) 2]);
    for i=1:size(boxes,1)
        x = find(cellfun(@(x)ismember(i,x),grid)==1);
        y = find(grid{x}==i);
        locs(i,:) = [x y];
    end
end

function vGrid2 = sortVGrid(vGrid, boxes)
    vGrid2 = cellfun(@(x)min(boxes(x,:),[],1),vGrid,'uniformoutput', false);
    vGrid2 = cell2mat(vGrid2);
    len = length(vGrid2);
    vGrid2 = reshape(vGrid2, 4,len/4)';
    [~, is] = sortrows(vGrid2,4);
    vGrid2 = vGrid(is);
end
function out_h = drawImage(inImage, boxes)
    out_h = figure('Visible','off');
    colormap(gray(256))
    minPixel = min(min(inImage));
    maxPixel = max(max(inImage));
    inImage = 255.0 * (double(inImage)-double(minPixel))/double(maxPixel-minPixel);
    inImage = uint16(inImage);
    image(inImage);
    drawBoxes(boxes);
    %im = getframe;
    %outImage = im.cdata;
end
function s = matToStruct(boxes)
    H = size(boxes,1);
    s = repmat(struct('tlx',0,'tly',0,'brx',0,'bry',0,'row',0,'col',0),1,H);
    for i=1:H
        s(i).row = sprintf('%c', 64+boxes(i,5));
        s(i).col = boxes(i,6);
        s(i).tlx = boxes(i,4);
        s(i).tly = boxes(i,1);
        s(i).brx = boxes(i,2);
        s(i).bry = boxes(i,3);
    end
end
function imageB = process(imageA, N, sigma, wsize, C)
    h = gaussian(N,N,sigma);
    imageB = filter2(h,imageA);
    imageB = threshold(imageB, wsize, C)*50;
end

function [ h ] = gaussian( m, n, sigma )
    [h1, h2] = meshgrid(-(m-1)/2:(m-1)/2, -(n-1)/2:(n-1)/2);
    hg = exp(- (h1.^2+h2.^2) / (2*sigma^2));
    h = hg ./ sum(hg(:));
end

function image2 = threshold(image1, wsize, C)
    h = meanFilter(wsize);
    image2 = filter2(h, image1);
    image2 = double(image1)-image2-C;
    image2 = image2>0;
end

function h = meanFilter(width)
    h = zeros([width width]);
    h = h + 1/(width^2);
end

function boxes2 = addMissingBoxes(boxes, hGrid, vGrid)
    missing = findEmptySlots(boxes, hGrid, vGrid);
    boxes2 = boxes;
    if(size(missing,2)<1)
        return;
    end
    for i=1:size(missing,1)
        box = boxFromGrids(boxes, hGrid, vGrid, missing(i,1), missing(i,2));
        boxes2 = cat(1, boxes2, box);
    end
end

function theta = horzAngleFromGrid(boxes, hGrid)
    gradients = zeros([length(hGrid)*2 1]);
    for i=1:length(hGrid)
        if(length(hGrid{i})>1)
            hBoxes = boxes(hGrid{i},:);
            hMidXs = (hBoxes(:,2)+hBoxes(:,4))/2;
            p = polyfit(hMidXs,hBoxes(:,1),1);
            gradients(i*2-1) = p(1);
            p = polyfit(hMidXs,hBoxes(:,3),1);
            gradients(i*2) = p(1);
        end
    end
    gradients = gradients(gradients~=0);
    angles = atan(gradients);
    theta = mean(angles);
end

function c = cGivenM(m, xs, ys)
    n = length(ys);
    b = sum(ys-xs*m);
    c = b/n;
end

function box = boxFromGrids(boxes, hGrid, vGrid, h, v)
    hBoxes = boxes(hGrid{h},:);
    vBoxes = boxes(vGrid{v},:);
    theta = horzAngleFromGrid(boxes, hGrid);
    m = tan(theta);
    
    hMidXs = (hBoxes(:,2)+hBoxes(:,4))/2;
    hMidYs = (hBoxes(:,1)+hBoxes(:,3))/2;
    vMidXs = (vBoxes(:,2)+vBoxes(:,4))/2;
    vMidYs = (vBoxes(:,1)+vBoxes(:,3))/2;
    line1 = polyfit(hMidXs,hMidYs,1);
    line2 = polyfit(vMidXs,vMidYs,1);
    
    % Box Centre
    x = (line2(2)-line1(2))/(line1(1)-line2(1));
    y = x*line1(1)+line1(2);
    
    c = cGivenM(m, hMidXs, hBoxes(:,1));
    top = m*x+c;
    c = cGivenM(m, hMidXs, hBoxes(:,3));
    bottom = m*x+c;  
    
    m = -m;
    c = cGivenM(m, vMidYs, vBoxes(:,2));
    right = m*y+c;
    c = cGivenM(m, vMidYs, vBoxes(:,4));
    left = m*y+c;
    box = [top right bottom left];
end

function [locs] = findEmptySlots(boxes, hGrid, vGrid)
    H = size(hGrid, 2);
    W = size(vGrid, 2);
    boxLocs = zeros([H W]);
    
    for i=1:size(boxes,1)
        [y x] = getGridCoords(boxes, hGrid, vGrid, i);
        boxLocs(y,x)=i;
    end
    [hs vs] = find(boxLocs==0);
    locs = cat(2, hs, vs);
end
function [boxes2, hGrid2, vGrid2] = removeOverlaps(boxes, hGrid, vGrid)
    boxes2 = boxes;
    hGrid2 = hGrid;
    vGrid2 = vGrid;
    while(1)
        [isOverlap n1 n2] = checkForOverlaps(boxes2, hGrid2, vGrid2);
        if(isOverlap)
            [boxes2, hGrid2, vGrid2] = fixOverlap(boxes2, hGrid2, vGrid2, n1, n2);
        else
            break;
        end
    end
end

function [isOverlap n1 n2] = checkForOverlaps(boxes, hGrid, vGrid)
    H = size(hGrid, 2);
    W = size(vGrid, 2);
    boxLocs = zeros([H W]);
    n1 = 0;
    n2 = 0;
    isOverlap = 0;
    for i=1:size(boxes,1)
        [y x] = getGridCoords(boxes, hGrid, vGrid, i);
        if(boxLocs(y,x)==0)
            boxLocs(y,x)=i;
        else
            n1 = i;
            n2 = boxLocs(y,x);
            isOverlap = 1;
            break;
        end
    end
end
function [boxes2 hGrid2 vGrid2] = fixOverlap(boxes, hGrid, vGrid, n1, n2)
    r1 = gridConformity(boxes, hGrid, vGrid, n1);
    r2 = gridConformity(boxes, hGrid, vGrid, n2);
    if(r1<r2)
        toRemove = n2;
    else
        toRemove = n1;
    end
    boxes2 = boxes;
    boxes2(toRemove,:) = [];
    [hGrid2 vGrid2] = boxesToGrid(boxes2);
end

function [h v] = getGridCoords(boxes, hGrid, vGrid, n)
    % strange matlab code
    h = find(cellfun(@(x)ismember(n,x),hGrid)==1);
    v = find(cellfun(@(x)ismember(n,x),vGrid)==1);
end

function [bestBoxes] = selectBestBoxes(boxes, img)
    stds = zeros([size(boxes) 3]);
    [H, W] = size(img);
    for i=1:size(boxes,1)
       for j=1:size(boxes,2)
            [hMean wMean hVar wVar] = boxStats(boxes{i,j});
            hStd = sqrt(hVar);
            wStd = sqrt(wVar);
            std = max(hStd/hMean,wStd/wMean);
            stds(i,j,1) = std;
            stds(i,j,2) = hMean;
            stds(i,j,3) = wMean;
       end
    end
    acceptablestds = zeros([0 3]);
    acceptables = {};
    for i=1:size(boxes,1)
        for j=1:size(boxes,2)
            totalArea = H*W;
            avgArea = stds(i,j,2)*stds(i,j,3);
            
            if size(boxes{i,j},1)*avgArea>totalArea/9
                acceptables{end+1} = boxes{i,j};
                acceptablestds(end+1,:) = stds(i,j,:);
            end
        end
    end
    
    if(isempty(acceptables))
        ME = MException('IMGFail:BoxesUnfound', 'Could not find wells.');
        throw(ME);
    end
    lengths = cellfun(@(x)size(x,1),acceptables);
    lengths = lengths(:);
    u = max(lengths);
    lengths = cellfun(@(x)size(x,1),acceptables);
    lengths = lengths(:);
    is = find(lengths>=u-2);
    boxes2 = acceptables(is);
    vars2 = acceptablestds(is);
    [dummy i] = min(vars2(:,1));
    bestBoxes = boxes2{i};
%     figure;
%     colormap(gray);
%     image(img/50);
%     drawBoxes(bestBoxes);
end

% function [bestBoxes] = selectBestBoxes(boxes, minNumBoxes, img)
%     stds = zeros(size(boxes));
%     for i=1:size(boxes,1)
%        for j=1:size(boxes,2)
%             [hMean wMean hVar wVar] = boxStats(boxes{i,j});
%             hStd = sqrt(hVar);
%             wStd = sqrt(wVar);
%             std = max(hStd/hMean,wStd/wMean);
%             stds(i,j) = std;
%        end
%     end
%     lengths = cellfun(@(x)size(x,1),boxes);
%     lengths = lengths(:);
%     lengths = lengths(lengths>=minNumBoxes);
%     u = mode(lengths);
%     lengths = cellfun(@(x)size(x,1),boxes);
%     lengths = lengths(:);
%     is = find(lengths>=u);
%     boxes2 = boxes(is);
%     vars2 = stds(is);
%     [dummy i] = min(vars2(:));
%     bestBoxes = boxes2{i};
% %     figure;
% %     colormap(gray);
% %     image(img/50);
% %     drawBoxes(bestBoxes);
%     
% end

function [boxes] = boxesFromLines(horzLines, vertLines, trimLinkThres)
    % It is much easier to find links between lines when we keep the
    % horizontal and vertical lines in separate groups.
    [horzLinks vertLinks] = findLinks2(horzLines, vertLines);
    
    [horzLinks vertLinks] = trimLinks(horzLinks, vertLinks, trimLinkThres);
    % Also when finding groups it makes it easier to keep horizontal and
    % vertical separate since we know that horizontal lines can only have
    % links with vertical lines.
    [hGroups vGroups] = findGroups(horzLinks, vertLinks);
    
    % The previous function gave the index of the lines, this function
    % gathers the lines into groups.
    groupedLines = groupLines(hGroups, vGroups, horzLines, vertLines);
    % Filtering out groups with small numbers of vertices;
    bestGroups = filterGroups(groupedLines);
    % Turning the groups of lines into boxes.
    boxes = getBoxes(bestGroups);
end
function [boxes2] = trimBoxes(boxes)
    % Not using variance at the moment.. Perhaps use as signifier that we
    % have outliers?
    [hMean wMean , ~, ~] = boxStats(boxes);
    boxes2 = zeros([0 4]);
    for i=1:size(boxes,1)
        w = boxes(i,2)-boxes(i,4);
        h = boxes(i,3)-boxes(i,1);
        % Boxes must be within 20% of mean height and width
        if hMean*0.8 < h && h < hMean*1.2 && wMean*0.8 < w && w < wMean*1.2
           boxes2(end+1,:) = boxes(i,:); 
        end
    end
end
function [grid2] = sortGrid(grid, boxes, sortCol)
    avgs = zeros([length(grid) 4]);
    for i=1:length(grid)
        avgs(i,:) = mean(boxes(grid{i},1:4));
    end
    [~, order] = sortrows(avgs,sortCol);
    grid2 = grid(order);
end

function r = gridConformity(boxes, hGrid, vGrid, boxNo)
    [h v] = getGridCoords(boxes, hGrid, vGrid, boxNo);
    avgsH = mean(boxes(hGrid{h},:));
    avgsV = mean(boxes(vGrid{v},:));
    avgs = avgsH;
    avgs([2 4]) = avgsV([2 4]);
    avgs = abs(avgs - boxes(boxNo,:));
    r = sum(avgs);
end

% Gets mean and variance for width and height of boxes
function [hMean wMean hVar wVar] = boxStats(boxes)
    w2Sum = 0;
    h2Sum = 0;
    wSum = 0;
    hSum = 0;
    n = size(boxes,1);
    for i=1:n
       w = boxes(i,2)-boxes(i,4);
       h = boxes(i,3)-boxes(i,1);
       wSum = wSum + w;
       hSum = hSum + h;
       w2Sum = w2Sum + w^2;
       h2Sum = h2Sum + h^2;
    end
    hVar = (h2Sum - hSum^2/n)/(n-1);
    wVar = (w2Sum - wSum^2/n)/(n-1);
    hMean = hSum/n;
    wMean = wSum/n;
end

function [hGrid vGrid] = boxesToGrid(boxes)
    downNeighbours = zeros([size(boxes,1) 1]);
    rightNeighbours = zeros([size(boxes,1) 1]);
    for i=1:size(boxes,1)
        box = boxes(i,:);
        rightMatches = find((boxes(:,1)<=box(3) & boxes(:,3)>=box(1)) & ...
            boxes(:,2)>box(2));
        if(~isempty(rightMatches))
            boxes1 = boxes(rightMatches, :);
            [~, k] = min(boxes1(:, 4));
            rightNeighbours(i) = rightMatches(k);
        end
        downMatches = find((boxes(:,4)<=box(2) & boxes(:,2)>=box(4)) & ...
            boxes(:,1)>box(1));
        if(~isempty(downMatches))
            downMatches = sortrows(downMatches, 1);
            boxes1 = boxes(downMatches, :);
            [~, k] = min(boxes1(:, 1));
            downNeighbours(i) = downMatches(k);
        end
    end
    [hNeighs vNeighs] = nonDirectionalise(rightNeighbours, downNeighbours);
    horzGroups = zeros([size(boxes,1) 1]);
    vertGroups = zeros([size(boxes,1) 1]);
    nextVertNum = 1;
    nextHorzNum = 1;
    for i=1:size(boxes,1)
        if horzGroups(i) == 0
            horzGroups(i) = nextHorzNum;
            nextHorzNum = nextHorzNum + 1;
            j = hNeighs(i,1);
            while j~=0
               horzGroups(j) = horzGroups(i);
               j = hNeighs(j,1);
            end
            j = hNeighs(i,2);
            while j~=0
               horzGroups(j) = horzGroups(i);
               j = hNeighs(j,2);
            end
        end
        if vertGroups(i) == 0
            vertGroups(i) = nextVertNum;
            nextVertNum = nextVertNum + 1;
            j = vNeighs(i,1);
            while j~=0
               vertGroups(j) = vertGroups(i);
               j = vNeighs(j,1);
            end
            j = vNeighs(i,2);
            while j~=0
               vertGroups(j) = vertGroups(i);
               j = vNeighs(j,2);
            end
        end
    end
    hGrid = cell([1 nextHorzNum-1]);
    for i=1:nextHorzNum-1
       hGrid{i} = find(horzGroups==i);
    end
    vGrid = cell([1 nextVertNum-1]);
    for i=1:nextVertNum-1
       vGrid{i} = find(vertGroups==i);
    end
    hGrid = sortGrid(hGrid, boxes, 1);
    vGrid = sortGrid(vGrid, boxes, 2);
end

function [hNeighs vNeighs] = nonDirectionalise(rNeighs, dNeighs)
    len = size(rNeighs, 1);
    hNeighs = cat(2, zeros([len 1]), rNeighs);
    vNeighs = cat(2, zeros([len 1]), dNeighs);
    for i=1:len
        rNeigh = rNeighs(i);
        dNeigh = dNeighs(i);
        if rNeigh~=0
            hNeighs(rNeigh,1) = i;
        end
        if dNeigh~=0
           vNeighs(dNeigh,1) = i; 
        end
    end
    
end

% Draws figures with debugging images
%function drawDebug(groups, boxes, inImage, image1)
function drawDebug(boxes, inImage, image1)
    figure;
    colormap(gray);
    image(image1*50);
    % Draws line groups
%     figure;
%     colormap(gray);
%     image(double(inImage)/40);
%     drawGroups(groups);
%     title('Groups of linked lines: Small groups pruned');
    
    % Draws boxes
    figure;
    colormap(gray);
    image(double(inImage)/40);
    drawBoxes(boxes);
    title('Boxes around detected wells');
end

% Increases boxes size by given number of pixels.
function newBoxes = growBoxes(boxes, growBy, imageSize)
    newBoxes = zeros(size(boxes));
    for i=1:size(boxes,1)
        top = boxes(i,1);
        right = boxes(i,2);
        bottom = boxes(i,3);
        left = boxes(i,4);
        % max,min used to not go outside of image bounds
        top = max(top- growBy, 1);
        right = min(right+growBy, imageSize(2));
        bottom = min(bottom+growBy, imageSize(1));
        left = max(left-growBy, 1);
        newBoxes(i,1:4) = [top right bottom left];
    end
end

% Should be an easier way to do this but couldn't find a map function that
% worked.
function boxes = getBoxes(groups)
    boxes = zeros([length(groups) 4]);
    for i=1:length(groups)
        boxes(i,:) = boxFromGroup(groups{i});
    end
end

% Draws box as rectangles on screen with distinct colours. Used for
% debugging.
function drawBoxes(boxes)
    colours = hsv(size(boxes,1));
    for i=1:size(boxes,1)
        drawBox(boxes(i,:), colours(i,:));
    end
end

% Draws single box as rectangle on screen with supplied colour. Used for
% debugging.
function drawBox(box, colour)
    axis image;
    x = box(4);
    y = box(1);
    w = box(2)-box(4);
    h = box(3)-box(1);
    if(size(box,2)>4)
        text(x+w/2,y+h/2, sprintf('%c%d', 64+box(5), box(6)), 'FontSize', 30, 'color', 'red', ...
            'VerticalAlignment', 'Middle', 'HorizontalAlignment', 'center');
    end
    if(w<=0)
        fprintf(1,'Warning: w = %d\n',w);
        w = 1;
    end
    if(h<=0)
        fprintf(1,'Warning: h = %d\n',h);
        h = 1;
    end
    rectangle('Position', [x,y,w,h],...
            'LineWidth',4,...
            'EdgeColor', colour);
end

% Returns a box when given a group by first sorting the x/y coordinates of
% all the lines and finding the extremities.
function box = boxFromGroup(group)
    len = length(group);
    xs = zeros(len*2);
    ys = zeros(len*2);
    % Populate xs and ys
    for i=1:len
       xs(i*2-1) = group{i}(1);
       ys(i*2-1) = group{i}(2);
       xs(i*2) = group{i}(3);
       ys(i*2) = group{i}(4);
    end
    xs = sort(xs);
    ys = sort(ys);
    % Not the absolute extremities in case there are crazy outliers
    top = ys(3);
    bottom = ys(len*2-2);
    left = xs(3);
    right = xs(len*2-2);
    % Clockwise starting from top
    box = [top right bottom left];
end

% Draws groups of lines with distinct colours. Used for debugging.
function drawGroups(groups)
    colours = hsv(length(groups));
    for i=1:length(groups)
        drawLines(groups{i}, colours(i,:));
    end
end

% Filter the small groups from list of groups. Should be an easier way but
% can't find filter function!
function [ bestGroups ] = filterGroups(groups)
    indexes = cellfun(@(x)length(x)>15,groups);
    bestGroups = groups(indexes);
end

% Creates groups of lines using information about groups based on indexes
% into horzLines and vertLines.
function [ groups ] = groupLines(hGroups, vGroups, horzLines, vertLines)
    groups = {};
    % First adds horizontal lines into their groups.
    for i=1:length(hGroups)
        group = hGroups{i};
        if ~isempty(hGroups{i})
            % Terrible hack to avoid having to supply number of groups
            if(length(groups)<group)
               groups{group} = {}; 
            end
           groups{group}{end+1} = horzLines(i,:);
        end
    end
    
    %
    for i=1:length(vGroups)
        if ~isempty(vGroups{i})
           groups{vGroups{i}}{end+1} = vertLines(i,:);
        end
    end
end

% Finds connected groups of vertexes given adjacency lists. 
function [ hGroups vGroups ] = findGroups(hLinks, vLinks)
    hGroups = cell(size(hLinks));
    vGroups = cell(size(vLinks));
    nextGroupNum = 1;
    % Iterate over hLinks
    for i = 1:length(hLinks)
        % group stays -1 if no connected vLinks are grouped
        group = -1;
        % iterates over connected vLinks
        for j = 1:length(hLinks{i})
            % if grouped
            if ~isempty(vGroups{hLinks{i}(j)})
                % set group
                group = vGroups{hLinks{i}(j)};
            end
        end
        % If no connected vLinks are grouped, get new groupNum
        if(group == -1)
            group = nextGroupNum;
            nextGroupNum = nextGroupNum + 1;
        end
        % Assign group num to hLink and all connected vLinks
        hGroups{i} = group;
        for j = 1:length(hLinks{i})
            vGroups{hLinks{i}(j)} = group;
        end
    end
end

% Creates two adjacency lists of vertical lines connected to horizontal
% lines.
function [horzLinks vertLinks] = findLinks2(horzLines, vertLines)
    [H1, W1] = size(horzLines);
    [H2, W2] = size(vertLines);
    horzLinks = cell([H1, 1]);
    vertLinks = cell([H2, 1]);
    for i = 1:H1
       horzLinks{i} = find(vertLines(:,2)<horzLines(i,2) & vertLines(:,4)>horzLines(i,2) & ...
           horzLines(i,1) < vertLines(:,1) & horzLines(i,3) > vertLines(:,1));
       % Do both lists at the same time
       for j = 1:length(horzLinks{i})
          vertLinks{horzLinks{i}(j)}(end+1) = i; 
       end
    end
end

function [horzLinks2 vertLinks2] = trimLinks(horzLinks, vertLinks, N)
    horzLinks2 = horzLinks;
    vertLinks2 = vertLinks;
    for i = 1:length(horzLinks2)
        if(length(horzLinks2{i}) < N)
            for k = 1:length(horzLinks2{i})
                j = horzLinks2{i}(k);
                vertLinks2{j} = vertLinks2{j}(vertLinks2{j}~=i);
            end
            horzLinks2{i} = [];
        end
    end
    for j = 1:length(vertLinks2)
        if(length(vertLinks2{j}) < N)
            for k = 1:length(vertLinks2{j})
                i = vertLinks2{j}(k);
                horzLinks2{i} = horzLinks2{i}(horzLinks2{i}~=j);
            end
            vertLinks2{j} = [];
        end
    end
end

% Draws lines to figure with given colour. Used for debugging.
function drawLines(lines, colour)
    axis image;
    for i=1:length(lines)
        line(lines{i}([1,3]), lines{i}([2,4]),...
            'linewidth',4,...
            'color', colour);
    end
end

function [horzSegs, vertSegs] = filterSegments(horzSegs, vertSegs, minLen, maxLen)
    horzSegs = horzSegs(horzSegs(:,3)<= maxLen & horzSegs(:,3)>=minLen,:);
    horzSegs = cat(2, horzSegs(:,1:2), horzSegs(:,1)+horzSegs(:,3)-1, horzSegs(:,2));
    vertSegs = vertSegs(vertSegs(:,3)<= maxLen & vertSegs(:,3)>=minLen,:);
    vertSegs = cat(2, vertSegs(:,1:2), vertSegs(:,1), vertSegs(:,2)+vertSegs(:,3)-1);
end
function [horzSegs, vertSegs] = getSegments(img, granularity)
    [H1, W1] = size(img);
    vertSegs = zeros([0,3]);
    horzSegs = zeros([0,3]);
    for offset=1:(1+granularity):W1 % Lines 'granularity' pixels apart
        pixels = img(:,offset);
        segs = lineAnalyser(pixels);
        H2 = size(segs,1);
        segs = cat(2, repmat(offset,[H2,1]), segs);
        vertSegs = cat(1, vertSegs, segs);
    end
    for offset=1:(1+granularity):H1
        pixels = img(offset,:);
        segs = lineAnalyser(pixels);
        H2 = size(segs,1);
        segs = cat(2, segs(:,1), repmat(offset,[H2,1]), segs(:,2));
        horzSegs = cat(1, horzSegs, segs);
    end
end

function segs = lineAnalyser(pixels)
    segs = zeros(0,2);
    len = length(pixels);
    notPixels = ~pixels;
    start = 1;
    while(1)
        oneLocs = find(pixels(start:len), 1);
        if(isempty(oneLocs) || start == len)
            break;
        end
        start = oneLocs(1)+start-1;
        zeroLocs = find(notPixels(start:len), 1);
        if(isempty(zeroLocs))
            finish = len;
        else
            finish = zeroLocs(1)+start-1;
        end
        segs(end+1,:) = [start, (finish-start)];
        start = finish;
    end
end