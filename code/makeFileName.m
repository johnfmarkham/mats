function ret = makeFileName(positionDetails,whichFile,index,index2)
% Try and make the filenames for various outputs that go here:
% outputDir/
%            aviavs/
%                   thresholded [pre-concatenated]
%                   unthresholded
%                   binarised
%            offsets
%            tiffs/
%                 runDir/
%                        positionDir
%            backgrounds
%            logs
%            maps
%            measurements
%            segmented
% 
% Index refers to channel number index where applicable.
if(strcmp(whichFile,'avi') || strcmp(whichFile,'avs'))
    if(nargin==2 || isempty(index))
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'.',whichFile);
    elseif(index==0) % combo avs
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_all','.',whichFile);
    else
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_',num2str(index),'.',whichFile);
    end
elseif(strcmp(whichFile,'backgrounds') ) % TODO: Fix this
    if(isempty(index))
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'.tif');
    else
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_',num2str(index),'.tif');
    end
elseif(strcmp(whichFile,'wellimages') )
    ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_',whichFile,'.jpg');
elseif(strcmp(whichFile,'hists') || strcmp(whichFile,'stats'))
    ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_',num2str(index));
    if(index2==0)
        ret = strcat(ret,'.csv');
    elseif(index2==1)
        ret = strcat(ret,'_background.csv');
    elseif(index2==2)
        ret = strcat(ret,'_foreground.csv');
    end
else
    % Default is something like
    % outputDir/offsets/20120413-0002_Position(213)_offsets.csv
    if(nargin==2 || isempty(index))
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_',whichFile,'.csv');
    elseif(~isempty(index))
        ret = strcat(getDir(positionDetails,whichFile),positionDetails.baseName,'_',num2str(index),'.csv');
    end
end

