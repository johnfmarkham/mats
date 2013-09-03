%---------------------------------------
function table = readHeaderedFile(filename,isCSVDelimited,logfile_fd_or_globals)
%---------------------------------------
% Reads in a csv file whose first line is the field names
% Tries to figure out what is text and numbers from the next line after
% that
%
if(nargin==2)
    logfile_fd = 1;
elseif(isstruct(logfile_fd_or_globals) && isfield(logfile_fd_or_globals,'logfile_fd'))
    logfile_fd = logfile_fd_or_globals.logfile_fd;
elseif(isfloat(logfile_fd_or_globals))
    logfile_fd = logfile_fd_or_globals;
else
    logfile_fd = 1;
end
if(isCSVDelimited)
    delimiter = {'delimiter',','};
else
    delimiter = {};
end    
fprintf(logfile_fd,'Reading %s\n',filename);
lines = countLines(filename);

fid = fopen(filename,'r');
if(fid==-1)
    fprintf(logfile_fd,'Unable to open %s for reading\n',filename);
    table = [];
    return;
end
tline = fgetl(fid);
if(tline==-1)
    fprintf(logfile_fd,'Unable to read lines from %s\n',filename);
    table = [];
    return;
end
if(isempty(tline) || length(tline)<3)
    fprintf(logfile_fd,'Unable to read a decent line from the file\n',filename);
    table = [];
    return;
end

names = textscan(tline,'%s',delimiter{:});
names = names{1};
tline = fgetl(fid);
if(tline==-1)
    table = [];
    return;
end
row = textscan(tline,'%s',delimiter{:});
row = row{1};
formatstr = [];
numCols = length(names);
isFloat = false(numCols,1);
% Try and guess the format string
% Assume that columns with NA are numbers
for i=1:numCols
    if(i>length(row))
        formatstr = strcat(formatstr,'%s ');
        templateStruct.(names{i}) = '';
    elseif(isnan(str2double(row{i})) && strcmp(row{i},'NA')==0 && ~isempty(row{i}))
        formatstr = strcat(formatstr,'%s ');
        templateStruct.(names{i}) = '';
    else
        formatstr = strcat(formatstr,'%f ');
        templateStruct.(names{i}) = 0;
        isFloat(i) = 1;
    end
end
table = repmat(templateStruct,1,lines-1);

i = 1;
while(1)
%     row = textscan(tline,formatstr,delimiter{:});
    if(isempty(tline))
        break;
    else
        row = textscan(tline,'%s',delimiter{:});
    end
    cols = row{1};
    for j = 1:min(length(cols),numCols)
        if(isFloat(j))
            table(i).(names{j}) = str2double(cols{j});
        else
            table(i).(names{j}) = cols{j};
        end
    end
%     for j = 1:length(row);
%         x = row{j};
%         if(iscell(x))
%             if(isempty(x))
%                 x=NaN;
%             else
%                 x = x{1};
%             end
%         end
%         table(i).(names{j}) = x;
%         % WARNING: This may not be what you want.
%         % empty field replaced with 0       
%         if(isempty(table(i).(names{j})))
%             table(i).(names{j}) = 0;
%         end
%     end
    tline = fgetl(fid);
    if(isempty(tline) || sum((tline==-1))==length(tline))
        break;
    end
    rowNonWS = strrep(tline,' ','');
    rowNonWS = strrep(tline,'\t','');
    if(length(rowNonWS)<3)
        fprintf(logfile_fd,'This looks dodgy. Blank line in csv file');
        continue;
    end
    i = i + 1;
end
fclose(fid);

%---------------------------------------
function lines = countLines(filename)
%---------------------------------------
fid = fopen(filename,'r');
lines = 0;
if(fid==-1)
    return
end
while(fgets(fid)~=-1)
    lines = lines + 1;
end
fclose(fid);
