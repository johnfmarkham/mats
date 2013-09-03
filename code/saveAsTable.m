%---------------------------------------
function saveAsTable(data,file,names)
%---------------------------------------
% Write headered csv file
fid = fopen(file,'wt');
for i=1:size(data,2)-1
    fprintf(fid,'%s,',names{i});
end
fprintf(fid,'%s\n',names{end});
for i=1:size(data,1)
    for j=1:size(data,2)-1
        fprintf(fid,'%e,',data(i,j));
    end
    fprintf(fid,'%e\n',data(i,end));
end
fclose(fid);
