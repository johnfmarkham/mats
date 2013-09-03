function s = incororporateTimesTable(s,t)
% Takes the cell measurements in s and incorporates the time measurements
% in t to replace frame numbers with time in hours
timePoints = length(t);
measurements = length(s);
oldPath = '';
pathList = {};
pathNumsTimePoints = zeros(timePoints,1);
for i=1:timePoints
    strPath = t(i).path;
    idx = find(strPath=='_',1,'first');
    if(isempty(idx))
        fprintf(1,'No paths to find in times file\n');
        return;
    else
        strPath = strPath(1:(idx-1));
    end
    if(~strcmp(strPath,oldPath))
        pathList = {pathList,strPath};
        oldPath = strPath;
    end
    pathNumsTimePoints(i) = length(pathList);
end
nPaths = length(pathList);
frameToTime = zeros(timePoints,nPaths);
for i=1:timePoints
    frameToTime(i,pathNumsTimePoints(i)) = t(i).elapsed_hours;
end

oldPath = '';
pathIdx = 0;
for i=1:measurements
    strPath = s(i).position;
    idx = find(strPath=='_',1,'first');
    if(isempty(idx))
        fprintf(1,'No paths to find in measurements file\n');
        return;
    else
        strPath = strPath(1:(idx-1));
    end
    if(~strcmp(strPath,oldPath))
        for j=1:nPaths
            if(strcmp(strPath,pathList{j}))
                pathIdx = j;
                break;
            end
        end
        oldPath = strPath;
    end
    s(i).frame = s(i).time;
    s(i).time = frameToTime(s(i).frame,pathIdx);
end
