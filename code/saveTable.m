%---------------------------------------
function saveTable(table,file)
%---------------------------------------
fid = fopen(file,'wt');

cellArray = 0;
if(iscell(table))
    cellArray = 1;
end

if(isempty(table))
    fields = [];
elseif(cellArray)
    fields = fieldnames(table{1});
elseif(isstruct(table(1)))
    fields = fieldnames(table(1));
else
    fields = [];
end
nFields = length(fields);
for i=1:nFields
    fprintf(fid,'%s',fields{i});
    if(i<nFields)
        fprintf(fid,',');
    end
end
if(~isempty(table))
    fprintf(fid,'\n');
end

for i=1:length(table)
    for j=1:nFields
        if(cellArray)
            x = table{i}.(fields{j});
        else
            x = table(i).(fields{j});
        end
        if(isnumeric(x))
            fprintf(fid,'%f',x);
        else
            fwrite(fid,x);
        end
        if(j<nFields)
            fwrite(fid,',');
        end
    end
    fprintf(fid,'\n');
end
fclose(fid);