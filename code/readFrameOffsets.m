%---------------------------------------
function offsets = readFrameOffsets(positionDetails)
%---------------------------------------
% Reads frame offsets from a headered file and makes a lookup table
%
offsetsFile = makeFileName(positionDetails,'offsets');
frameOffsets = readHeaderedFile(offsetsFile,1,positionDetails);
offsets = repmat(struct('x',0,'y',0),length(frameOffsets),positionDetails.channels);
frames = [frameOffsets.frame];
for i=1:length(frames)
    fr = find(frames==i,1);
    for j=1:positionDetails.channels
        % Potential the channels are offset from each other
        offsets(i,j).x = frameOffsets(fr).x;
        offsets(i,j).y = frameOffsets(fr).y;
    end
end