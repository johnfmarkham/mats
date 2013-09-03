function processMicrowells(experimentDetails)

dirPattern = strcat(experimentDetails.dir,experimentDetails.dirPattern);
dirList = dir(dirPattern);
dirs = length(dirList);

thresholdsFile = strcat(experimentDetails.outputDir,'index.html');
autoid = fopen(htmlFile,'w');

htmlFile = strcat(experimentDetails.outputDir,'index.html');
fid = fopen(htmlFile,'w');
fprintf(fid,'<head>\n');
fprintf(fid,'<title> \n');
fprintf(fid,'Summary Plots\n');
fprintf(fid,'</title>\n');
fprintf(fid,'</head>\n');
fprintf(fid,'<body>\n');
fprintf(fid,'<h3>Averaged over all microwells</h3>\n');
fprintf(fid,'<img src="histtotal.png">\n');
fprintf(fid,'<img src="pixelstotal.png">\n');
fprintf(fid,'<img src="scattertotal.png">\n');
fprintf(fid,'<br>\n');
cellListFile = strcat(experimentDetails.outputDir(),'cellsinwells.txt');
cellList = readCellList(cellListFile);

channels = experimentDetails.channels;
pixelstotal = zeros(0,channels); 
histtotal = zeros(2^16,channels);
cellstotal = zeros(0,channels+2);

dirPattern = strcat(experimentDetails.dir,experimentDetails.dirPattern);
dirList = dir(dirPattern);
dirs = length(dirList);

j = 1;
for i=1:dirs
    diritem = dirList(i);
    if(diritem.isdir)
        positionDetails.dir = diritem.name;
        % Convert dir name into pattern for file matching
        positionDetails.pattern = regexprep(diritem.name, '.tif_Files', experimentDetails.pattern);
        positionDetails.baseName = regexprep(diritem.name, '.tif_Files', '');
        positionDetails.dir = strcat(experimentDetails.dir,diritem.name,'\');
        positionDetails.channels = experimentDetails.channels;
        timePointPatterm = strcat(positionDetails.dir,'*1.tif');
        fileList = dir(timePointPatterm);
        positionDetails.timePoints = length(fileList);
        baseName = positionDetails.baseName;
        % make tables to graph
        [histograms, pixelCounts,autoThresholds] = position2tables(positionDetails,experimentDetails);
        nCells = cellsInWell(baseName,cellList);
        pixelstotal = cat(1,pixelstotal,pixelCounts); 
        histtotal = histtotal + histograms;
        if(nCells)
            cellColumn = nCells * ones(size(pixelCounts,1),1);
            wellnum = j * ones(size(pixelCounts,1),1);
            pixelCountsWithCell = cat(2,wellnum,cellColumn,pixelCounts);
            cellstotal = cat(1,cellstotal,pixelCountsWithCell);
        end
        histName = sprintf('%s_hist.png',baseName);
        pixelsName = sprintf('%s_pixels.png',baseName);
        scatterName = sprintf('%s_scatter.png',baseName);
        fprintf(fid,'<h3>%s</h3>',baseName);
        if(nCells)
            fprintf(fid,'Cells = %d<br>',nCells);
        end
        fprintf(fid,'<img src="%s">',histName);
        fprintf(fid,'<img src="%s">',pixelsName);
        fprintf(fid,'<img src="%s">',scatterName);
        histName = strcat(experimentDetails.outputDir,histName);
        pixelsName = strcat(experimentDetails.outputDir,pixelsName);
        plotHist(histograms,histName,experimentDetails);
        plotPixelsVersusTime(pixelCounts,pixelsName,experimentDetails);
        plotScatter(pixelCounts,scatterName,experimentDetails);
      
        fprintf(fid,'<br>\n');
        j = j + 1;
    end
end

histName = strcat(experimentDetails.outputDir,'histtotal.png');
pixelsName = strcat(experimentDetails.outputDir,'pixelstotal.png');
scatterName = strcat(experimentDetails.outputDir,'scattertotal.png');
plotHist(histtotal,histName,experimentDetails);
plotPixelsVersusTime(pixelstotal,pixelsName,experimentDetails);
plotScatter(pixelstotal,scatterName,experimentDetails);

% make totals graphs and write out counts
fprintf(fid,'</body>\n');
fclose(fid);
% Write out the cells and pixels - this is the useful bit
cellsFile = strcat(experimentDetails.outputDir,'cellpixels.txt');
fid = fopen(cellsFile,'w');
for i=1:size(cellstotal,1)
    fprintf(fid,'%d ',cellstotal(i,:));
    fprintf(fid,'\n');
end
fclose(fid);
end

%-------------------------------------------
function cellList = readCellList(filename)
%-------------------------------------------
    [wells,ncells] = textread(filename,'%s %d');
    for i=1:length(ncells)
        cellList{i}.cells = ncells(i);
        cellList{i}.well = wells(i);
    end
end

%-------------------------------------------
function nCells = cellsInWell(baseName,cellList)
%-------------------------------------------
    for i=1:length(cellList)
        if(strcmp(baseName,cellList{i}.well))
            nCells = cellList{i}.cells; 
            return;
        end
    end
    nCells = 0;
end

%-------------------------------------------
function plotHist(histograms,histName,experimentDetails)
%-------------------------------------------
h = figure(1);
maxy = max(max(histograms));
intensity = 1:4096; % intensity range
intensity = repmat(intensity,1,experimentDetails.channels);
plot(intensity,histograms(intensity,:));
hold on;
xthresh = cat(1,experimentDetails.thresholds,experimentDetails.thresholds);
ythresh = cat(1,zeros(1,experimentDetails.channels),maxy * ones(1,experimentDetails.channels));
plot(xthresh,ythresh);
hold off;
xlabel('intensity');
ylabel('# pixels');
legend(experimentDetails.labels{:});
saveas(h,histName,'png');
end
%-------------------------------------------
function plotPixelsVersusTime(pixelCounts,pixelsName,experimentDetails)
%-------------------------------------------
pixels = transpose(1:size(pixelCounts,1));
pixels = repmat(pixels,1,experimentDetails.channels);
h = figure(2);
plot(pixels,pixelCounts);
xlabel('t');
ylabel('# pixels');
legend(experimentDetails.labels{:});
saveas(h,pixelsName,'png');
end
%-------------------------------------------
function plotScatter(pixelCounts,scatterName,experimentDetails)
%-------------------------------------------
pixels = 1:size(pixelCounts,1);
pixels = repmat(pixels,1,experimentDetails.channels);
h = figure(3);
plot(pixelCounts(:,3),pixelCounts(:,4),'.');
xlabel(experimentDetails.labels{3});
ylabel(experimentDetails.labels{4});
saveas(h,scatterName,'png');
end