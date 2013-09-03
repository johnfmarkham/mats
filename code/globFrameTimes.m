function posframe2time = globFrameTimes(framePath,wildCard)

filePattern = strcat(framePath,wildCard);

fileList = dir(filePattern);

maxPosnum = 500;
maxFramenum = 5000;
maxRun = 50;

posframerun2time = zeros(maxPosnum,maxFramenum,maxRun);
globals.fd = 1;
isCSVDelimited = 1;
s = readHeaderedFiles(framePath,fileList,isCSVDelimited,globals);


frames = [s.frame];
datenums = [s.datenum];

positions = zeros(size(frames)); 
runs = zeros(size(frames)); 

for i=1:length(s)
    path = s(i).path;
    left = find(path=='-',1,'first')+1;
    right = find(path=='_',1,'first')-1;
    runs(i) = str2double(path(left:right));
    left = find(path=='(',1,'first')+1;
    right = find(path==')',1,'first')-1;
    positions(i) = str2double(path(left:right));
    posframerun2time(positions(i),frames(i),runs(i)) = datenums(i);
end

uniquePositions = unique(positions);
uniqueRuns = unique(runs);
uniqueFrames = unique(frames);
% uniqueFrames = uniqueFrames(2:end); % get rid of zero
maxPosnum = max(uniquePositions);
maxFramenum = max(uniqueFrames);
maxRun = max(uniqueRuns);
maxFrame = 0;

posframerun2time = posframerun2time(1:maxPosnum,1:maxFramenum,1:maxRun);
posframe2time = zeros(maxPosnum,3*maxFramenum);

for i=1:length(uniquePositions)
    pos = uniquePositions(i);
    tStarts = posframerun2time(pos,1,:); % just in case something is out of order
    tStarts = tStarts(tStarts~=0);
    tStart = min(tStarts); 
    lastFrame = 0;
    for j=1:length(uniqueRuns)
        run =  uniqueRuns(j);
        t = posframerun2time(pos,:,run);
        t = t(t~=0);
        posframe2time(pos,lastFrame + (1:length(t))) = t - tStart;
        lastFrame = lastFrame + length(t);
        maxFrame = max(maxFrame,lastFrame);
    end
end
  
posframe2time = posframe2time(:,1:maxFrame);
    
    


