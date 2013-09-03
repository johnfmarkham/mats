%---------------------------------------
function fid = appendCellDetails(cellDetails,fileName)
info = dir(fileName);

fid = fopen(fileName,'a');
if(fid==-1)
    % fprintf(1,'Unable to open file %s for appending\n',fileName);
    return;
end
names = fieldnames(cellDetails);

% Write field names in first
if(isempty(info) || (info.bytes==0))
    fprintf(fid,'%s',names{1});
    for j = 2:length(names);
        fprintf(fid,',%s',names{j});
    end
    fprintf(fid,'\n');
%     for j = 1:length(names);
%         str = cellDetails(1).(names{j});
%         if(isnumeric(str))
%             fprintf(fid,'%%f');
%         else
%             s = regexp(str,'[A-Z]', 'once' );
%             % some numbers are still misidentified as strings
%             if(isempty(s))
%                 fprintf(fid,',%%f');
%             else
%                 fprintf(fid,',%%s');
%             end
%         end
%     end
%     fprintf(fid,'\n');
end

for i = 1:length(cellDetails)
    for j = 1:length(names);
        if(isnumeric(cellDetails(i).(names{j})))
            fprintf(fid,'%d',cellDetails(i).(names{j}));
        else
            fprintf(fid,'%s',cellDetails(i).(names{j}));
        end
        if(j<length(names))
            fprintf(fid,',');
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);
