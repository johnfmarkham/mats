function plotCellMeasurements(positionDetails)
% Takes cell measurements and prints some diagnostics

cellDetails = positionDetails.cellDetails;

channels = positionDetails.channels; 
nCells = length(cellDetails);
measuredChannels = positionDetails.measuredChannels;

for j=1:length(measuredChannels)
    cellsInThisChannel = ([cellDetails.channelNum]==j);
    cellsInd = find(cellsInThisChannel);
    segmentedArea = [cellDetails.segmentedArea];
    thresholdedArea = [cellDetails.thresholdedArea];
    integratedFluoresence = [cellDetails.correctedIntegratedFluoresenceThresh];
    correctedIntegratedFluoresenceThresh = [cellDetails.correctedIntegratedFluoresenceThresh];
    correctedIntegratedFluoresenceCellAll = [cellDetails.correctedIntegratedFluoresenceCellAll];
    bins = 100;
    h = figure(j+100);
    set(h,'Name',cellDetails(cellsInd(1)).channelName);
    subplot(2,3,1);
    x = segmentedArea(cellsInThisChannel);
    y = thresholdedArea(cellsInThisChannel);
    plot(x,y,'.');
    xlabel('segmentedArea');
    ylabel('thresholdedArea');
    title('Cell areas (pixels)');
    subplot(2,3,2);
    hist(segmentedArea(cellsInThisChannel),bins);
    xlabel('segmentedArea');
    ylabel('cells');
    subplot(2,3,3);
    hist(thresholdedArea(cellsInThisChannel),bins);
    xlabel('thresholdedArea');
    ylabel('cells');
    subplot(2,3,4);
    hist(integratedFluoresence(cellsInThisChannel),bins);
    xlabel('integratedFluoresence');
    ylabel('cells');
    subplot(2,3,5);
    hist(correctedIntegratedFluoresenceThresh(cellsInThisChannel),bins);
    xlabel('correctedIntegratedFluoresenceThresh');
    ylabel('cells');
    subplot(2,3,6);
    hist(correctedIntegratedFluoresenceCellAll(cellsInThisChannel),bins);
    xlabel('correctedIntegratedFluoresenceCellAll');
    ylabel('cells');
end
