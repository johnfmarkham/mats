%---------------------------------------
function extractWells(wellList)
%---------------------------------------
s.sourceRoot = 'h:\experiments\';
s.destRoot = 'd:\jmarkham\segmentation\';
wells = readHeaderedFile(wellList,1);
wallSize = 40;

for  i=1:length(wells)
    w = wells(i);
    x1 = 1 + w.x1 + wallSize/2;
    y1 = 1 + w.y1 + wallSize/2;
    x2 = 1 + w.x2 - wallSize/2;
    y2 =1 +  w.y2 - wallSize/2;
    
    well = w.Microwell;
    w.Path = strrep(w.Path,'"','');
    sourcepath = strcat(s.sourceRoot,w.Path,'/');
    sourcematch = strcat(s.sourceRoot,w.Path,'/*.tif');
    destpath = strcat(s.destRoot,w.Path,'/',well,'/');
    if(~dirExists(destpath))
        makeDir(destpath);
    end
    fileList = dir(sourcematch);
    fprintf(1,'Processing %s\n',sourcematch);
    files = length(fileList);
    
    for j=1:files
        if(fileList(j).isdir==0)
            f = fileList(j);
            infile = strcat(sourcepath,f.name);
            outfile = strcat(destpath,f.name);
            im = uint16(imread(infile));
            if(isempty(im))
                fprintf(1,'Unable to open %s\n',infile);
                return;
            end
            fprintf(1,'%s\n->\n%s\n',infile,outfile);
            imwrite(im(y1:y2,x1:x2),outfile,'tif','Compression','none');
%             outfile(end)   = 'g';
%             outfile(end-1) = 'p';
%             outfile(end-2) = 'j';
%             ar = uint8(im(y1:y2,x1:x2));
%             imwrite(ar,outfile,'jpg');
        end
    end
end