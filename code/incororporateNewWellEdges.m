function c = incororporateNewWellEdges(c,s)
% Takes the cell measurements in c and re-assigns them to cells based on the
% contents of s

if(isempty(c) || isempty(s))
    fprintf(1,'Empty edges or measurements\n');
    return;
end
nMeasurements = length(c);
nWells = length(s);

for i=1:nWells
    % Was getting some non-integer or zero numbers out fo the wells files
    s(i).tly = max(round(s(i).tly),1);
    s(i).tlx = max(round(s(i).tlx),1);
    s(i).bry = max(round(s(i).bry),1);
    s(i).brx = max(round(s(i).brx),1);
end

x = [c.x];
y = [c.y];

rows = [c.row];
cols = [c.col];

brx = [s.brx];
bry = [s.bry];

img_x = max([max(brx) max(x)]);
img_y = max([max(bry) max(y)]);
fprintf(1,'img_x = %d img_y = %d product = %d\n',img_x,img_y,img_x*img_y);
if(img_x>4096 || img_y > 4096) % Catches a bug
    c = [];
    return;
end

rowTable = zeros(img_y,img_x,'uint8');
colTable = zeros(img_y,img_x);

for i=1:nWells
    rowTable(s(i).tly:s(i).bry,s(i).tlx:s(i).brx) = s(i).row;
    colTable(s(i).tly:s(i).bry,s(i).tlx:s(i).brx) = s(i).col;
end
for i=1:nMeasurements
    rows(i) = rowTable(c(i).y,c(i).x);
    cols(i) = colTable(c(i).y,c(i).x);
    c(i).row = rows(i);
    c(i).col = cols(i);
end
% Pull out the cells that didn't fall into a row or col
c = c(rows~=0 & cols~=0);
