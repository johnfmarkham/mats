function s = readHeaderedFiles(path,fileList,isCSVDelimited,globals)
% % Reads and concatenates a set of files with the same column headings
% Globals is meant to contain the member logfile_fd. this my hack to make
% logging work for threads.
s = [];
if(isempty(fileList))
    return;
end
for i=1:length(fileList)
    if(nargin==3)
        s = [s readHeaderedFile(strcat(path,fileList(i).name),isCSVDelimited)];
    else
        s = [s readHeaderedFile(strcat(path,fileList(i).name),isCSVDelimited,globals)];
    end
end