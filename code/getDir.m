function ret = getDir(positionDetails,whichDir)
% Try and make this directory structure:
% experimentDir/ 
%               runDir/
%                      positionDir % TODO: Stitch these
%                      % TODO: getFilePath(positionDetails,frame,channel)
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
%            wells
%            logs % TODO: Logs from stdout to files with timing etc
%            measurements
%            segmented
% 
fieldName = strcat(whichDir,'Dir');
if(strcmp(whichDir,'tiffs') || strcmp(whichDir,'masks'))
    ret = strcat(positionDetails.outputDir,positionDetails.(fieldName),positionDetails.runDir,positionDetails.positionDir);
elseif(strcmp(whichDir,'segmented'))
    ret = strcat(positionDetails.outputDir,positionDetails.(fieldName),positionDetails.runDir,positionDetails.positionDir);
elseif(strcmp(whichDir,'avs'))
    ret = strcat(positionDetails.outputDir,positionDetails.aviavsDir);
elseif(strcmp(whichDir,'avi'))
    ret = strcat(positionDetails.outputDir,positionDetails.aviavsDir);
elseif(strcmp(whichDir,'cell'))
    ret = strcat(positionDetails.outputDir,positionDetails.measurementsDir);
elseif(strcmp(whichDir,'well'))
    ret = strcat(positionDetails.outputDir,positionDetails.measurementsDir);
else
    ret = strcat(positionDetails.outputDir,positionDetails.(fieldName));
end
if(~dirExists(ret))
    makeDir(ret,positionDetails);
end
