function plotFluorescenceTimeSeries(positionDetails,cellDetails,row,col,scaled,outfileavi,outfilejpg)
% Plot various quantities versus time for cells in a particular microwell
% into a video file
plotChannels = positionDetails.plotChannels;
channelLabels = positionDetails.labels;
plotQuantities = positionDetails.plotQuantities;
% TODO: Plot actual time from file, not frames in plotFluorescenceTimeSeries()
nChannels = length(plotChannels);
nPlots = nChannels;  % TODO: look at plotting all quantities
% for j=1:nCells
%     c = cellDetails(j);
%     if(c.row==row && c.col==col && (~isempty(strfind(c.position,pos))) && strcmp(channel,c.channelName))
%         selectCells(j) = 1;
%     end
% end
%
% quantity = {'segmentedArea','thresholdedArea','integratedFluoresence',...
%     'correctedIntegratedFluoresenceThresh','correctedIntegratedFluoresenceCellAll'};
% quantity = {'correctedIntegratedFluoresenceCellAll'};
% scaled = 0;
% 
colours = {'.g','.r','.b','.k','.c','.y'};
channelNums = [cellDetails.channelNum];
segmentedChannelNums = [cellDetails.segmentedChannelNum];
rows = [cellDetails.row];
cols = [cellDetails.col];
times = [cellDetails.time];
integratedFluoresence = [cellDetails.integratedFluoresence];

if(isfield(cellDetails,'elapsed_times'))
    elapsed_times = [cellDetails.elapsed_times];
else
    elapsed_times = [];
end

if(isempty(times))
    log_fprintf(positionDetails,'No valid points to plot in %s or %s\n',outfilejpg,outfileavi);
    return;
end
% proportionSegmented = [cellDetails.thresholdedArea]./[cellDetails.segmentedArea];
%outfile = 'test.avi';
startTime = min(times);
endTime = max(times);
if(isnan(startTime) || isnan(endTime) || startTime>=endTime)
    log_fprintf(positionDetails,'Something strange about startTime endTime (%f,%f) so not making %s or %s\n',startTime,endTime,outfilejpg,outfileavi);
    return;
end
% h = figure;
h = figure('color','white','units','normalized','position',[.1 .1 .6 .4],'visible','off'); 
im = zeros(1280,320);
set(gca,'units','pixels','position',[5 5 size(im,2)-10 size(im,1)-10],'visible','off')
for k=1:nPlots
    j = plotChannels(k);
    yName = plotQuantities{1}; % TODO: Loop over plots
    % selectCells = ((channelNums==channel(j)) & (rows==row) & (cols==col) & (proportionSegmented==1));
    if(positionDetails.segmented_on_self)
        selectCells = (channelNums==j  & (rows==row) & (cols==col) & segmentedChannelNums==j & integratedFluoresence>0);
    else
        selectCells = (channelNums==j  & (rows==row) & (cols==col) & segmentedChannelNums==positionDetails.segmented_channel & integratedFluoresence>0);
    end
%         cellsInd = find(selectCells);
%         bins = 100;
    % set(h,'Name',sprintf('%s %s: (%s,%d)',channel{j},pos,row,col));
    subplot(nPlots,1,k);
    if(isempty(elapsed_times))
        x = times(selectCells);
    else
        x = elapsed_times(selectCells);
    end
    y = [cellDetails.(yName)];
    y = y(selectCells);
    if(scaled)
        y = y/mean(y);
    end
    unique_x = unique(x);
    unique_y = zeros(size(unique_x));
    for i=1:length(unique_x)
        ux = unique_x(i);
        unique_y(i) = sum(y(x==ux));
    end
    % plot(unique_x,unique_y,'.r',x,y,'.b');
    xlim([startTime,endTime]);
    hold on;
    plot(x,y,colours{k});
    xlim([startTime,endTime]);
    hold off;
    if(isempty(elapsed_times) && (positionDetails.insertRealTimes==0))
        xlabel('time (frames)');
    else
        xlabel('elapsed time (hours)');
    end
    ylabel(channelLabels{j});
    title(sprintf('%s versus time',yName));
end

% Estimate the time difference between frames
dx = unique_x(2:end)-unique_x(1:(end-1));
delta_t = min(dx);
if(isempty(delta_t) || delta_t==0)
    delta_t = 1;
end
% Round to the nearest 60th (probably a minute)
delta_t = round(60*delta_t)/60;
 
print(h, '-djpeg', outfilejpg, '-r 100');
close(h) 
% avisynth objects to some frame sizes
im = imread(outfilejpg);
dim1 = floor(size(im,1)/8) * 8;
dim2 = floor(size(im,2)/8) * 8;
imtrimmed(1:dim1,1:dim2,:) = im(1:dim1,1:dim2,:);

aviobj = VideoWriter(outfileavi);
aviobj.Quality = 100;
open(aviobj);

% Just measured from an image. Yuck.
x_beg = round(size(im,2) * (104/800)); % where the graph begins and ends
x_end = round(size(im,2) * (724/800));

for k=startTime:delta_t:endTime
    imout = imtrimmed;
    col = x_beg + round((x_end-x_beg) * (k-startTime)/double(endTime-startTime));
    imout(:,col,:) = 0;
    % plot([k,k],[0 max(y)],'k');
    writeVideo(aviobj,imout);
end

close(aviobj);
% imwrite(pixels,'imtest.png');
% pixels(pixels~=0) = 65535;
% imwrite(pixels,fontFile,'Compression','none');

