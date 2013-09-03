function [correction,correction_sorted] = makeAllReferenceImages(positionDetails,s)
% Make reference images for all channels to correct for uneven
% illumination. Either read in pre-made ones or try and make one from one
% image in each channel.
channels = positionDetails.channels;
if(positionDetails.doBrightnessCorrection==0)
    correction = [];
    correction_sorted = [];
end
channelNumbers = positionDetails.channelNumbers;
% Do brightness correction 
if(positionDetails.doBrightnessCorrection==1)
    for j=1:positionDetails.channels
        if (positionDetails.filenameIncrementsTime==0)
            fprintf(1,'Need multiple images for this. Sorry.');
            exit(-1);
        end
        filename_cor = sprintf(positionDetails.pattern,positionDetails.brightnessCorrectionFrame,channelNumbers(j));
        filename_cor = strcat(positionDetails.dir,filename_cor);
        cor = makeReferenceImage(filename_cor,s,positionDetails.tileCorrection);
        correction(:,:,j) = cor;
    end
elseif(positionDetails.doBrightnessCorrection==2)
    % image is 16 bit integer rep of brightness
    % correction is a double with a lower bound of 1 (at the brightest
    % point of the correction image)
    % The idea is to multiply this by the image to be corrected.
    if(strfind(positionDetails.brightnessCorrectionFile,'%d'))
        for j=1:positionDetails.channels
            bcdir = getDir(positionDetails,'brightnessCorrection');
            file = sprintf(positionDetails.brightnessCorrectionFile,channelNumbers(j));
            file = strcat(bcdir,file);
            cor = double(imread(file));
            cor = cor/max(max(cor));
            correction(:,:,j) = cor;
        end
    else
        cor = double(imread(positionDetails.brightnessCorrectionFile));
        cor = cor/max(max(cor));
        % Make it 0-1 based multiplicative correction
        for j=1:positionDetails.channels
            correction(:,:,j) = cor;
        end
    end
end
if(positionDetails.doBrightnessCorrection==0)
    correction = 0;
    correction_sorted = 0;
else
    for j=1:channels
        pixels = size(correction,1) * size(correction,2);
        % Pre-calculating these saves time later
        correction_sorted(:,j) = sort(reshape(correction(:,:,j),pixels,1));
    end
end
