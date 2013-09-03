%---------------------------------------
function wellDetails = readWellDetails(fileName)

fid = fopen(fileName,'r');
tline = fgetl(fid);
names = textscan(tline,'%s');
names = names{1};
formatstr = fgetl(fid);

data = textscan(fid, formatstr);

for i = 1:length(data{1})
    for j = 1:length(names);
        x = data{j}(i);
        if(iscell(x))
            x = x{1};
        end
        wellDetails(i).(names{j}) = x;
    end
end
