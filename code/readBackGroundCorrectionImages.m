function [correction,correction_sorted] = readBackGroundCorrectionImages(positionDetails)
% Read background correction images for all channels.
% image is 16 bit integer rep of brightness
% correction is a double with an upper bound of 1 (at the brightest
% point of the correction image)
if(positionDetails.doBackgroundCorrection==0)
    correction = [];
    correction_sorted = [];
    return;
end
channelNumbers = positionDetails.channelNumbers;
dir = positionDetails.dir;
destDir = strcat(positionDetails.outputDir,positionDetails.backgroundsDir,positionDetails.positionDir);
channels = positionDetails.channels;

for j=1:channels
    file = makeFileName(positionDetails,'backgrounds',channelNumbers(j));
    log_fprintf(positionDetails,'Extracting backgrounds from images in %s for channel %d (Axiovision %d)\n',...
        dir,j,channelNumbers(j));
    cor = double(imread(file));
    cor = cor/max(max(cor));
    correction(:,:,j) = cor;
    pixels = size(correction,1) * size(correction,2);
    % Pre-calculating these saves time later
    correction_sorted(:,j) = sort(reshape(correction(:,:,j),pixels,1));
end
