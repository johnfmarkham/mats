function globCellNumberCounts()


cellNumberPath = 'D:/experiments/20121213/exports_intermediate_files/outputs/cellnumbers/';
linespec = {'b.','r.','k.','c.','g.','y.'};
rowConditions = {'No CTV or CFSE','CTV (1x)','CTV (1/2 x)','CTV (1/4 x)','CTV (1/8 x)','CFSE 1x'};
colConditions = {'Control','Zapped'};
vec.numCells = [];
vec.datenum = [];
vec.row = [];
vec.col = [];
vec.channel = [];

dirPattern = cellNumberPath;
dirList = dir(dirPattern);
dirs = length(dirList);
for i=1:dirs
    diritem = dirList(i);
    if(diritem.isdir && diritem.name(1)~='.')
        dirName =  diritem.name;
        col = double(dirName(end)-'0');
        row = dirName(end-1);
        filePattern = strcat(cellNumberPath,dirName,'/*_cellnumbers.csv');
        fileList = dir(filePattern);
        files = length(fileList);
        for j=1:files
            filename = strcat(cellNumberPath,dirName,'/',fileList(j).name);
            tab = readHeaderedFile(filename,1);
            offset = strfind(filename,'_cellnumbers') - 1;
            channel = double(filename(offset) - '0');
            if(col==4 && channel>2)
                channel = channel + 2; % A hack to skip unused channels
            end
            numRows = length(tab);
            vec.datenum = [vec.datenum ; [tab.datenum]' ]; 
            vec.numCells = [vec.numCells ; [tab.numCells]' ]; 
            vec.row = [vec.row; repmat(row,numRows,1)];
            vec.col = [vec.col; repmat(col,numRows,1)];
            vec.channel = [vec.channel ; repmat(channel,numRows,1)];
        end
    end
end

numEntries = length(vec.col);
entry.numCells = 0;
entry.datenum = 0;
entry.row = 0;
entry.col = 0;
entry.channelvec = 0;
entry.hours = 0;
p = repmat(entry,numEntries,1);
start = min(vec.datenum);
for i=1:numEntries
    fields = fieldnames(vec);
    for j=1:length(fields)
        p(i).(fields{j}) = vec.(fields{j})(i);
    end
    dv = datevec((p(i).datenum - start));
    p(i).hours = dv(6)/3600 + dv(5)/60 + dv(4) + dv(3) * 24;
end
vec.hours = [p.hours];
for i='C':'H'
    for j=4:5
        h=figure;
        hold on;
        for k=min(vec.channel):max(vec.channel)
            idx = (vec.row==i & vec.col==j & vec.channel==k);
            if(sum(idx)==0)
                plot(0,0,linespec{k});
            else
                plot(vec.hours(idx),vec.numCells(idx),linespec{k});
            end
        end
        legend('RedDot','RFP','GFP','CTV','BF','BFbelow');
        title(sprintf('Well %c%d  %s:%s',i,j,colConditions{j-3},rowConditions{i-'B'}));
        xlabel('hours');
        ylabel('number of cells');
        hold off;
        plotFile = sprintf('%scellnumbers_well_%c%d.png',cellNumberPath,i,j);
        print(h, '-dpng', plotFile, '-r 300');
        close(h) 

    end
end

writeHeaderedFile(p,strcat(cellNumberPath,'summary.csv'));










