function gatherFucciGFPPlots(experimentDetails)

runName = experimentDetails.runDir(1:end-1); % remove \
fuccipath = getDir(experimentDetails,'fuccifits');
fitsFile = strcat(fuccipath,runName,'_fuccifits.csv');
aviFile = strcat(fuccipath,runName,'_fuccifits_gfp.avi');

dirPattern = strcat(fuccipath,'*_gfp.csv');
fileList = dir(dirPattern);
files = length(fileList);

if(files==0)
    log_fprintf(experimentDetails,'No files found with pattern %s\n',dirPattern);
    return;
else
    if(experimentDetails.noClobber && fileExists(aviFile))
        log_fprintf(experimentDetails,'The GFP plots file %s already exists. Skipping.\n',aviFile);
        return;
    elseif(fileExists(fitsFile))
        fits = readHeaderedFile(fitsFile,1,experimentDetails);
    else
        log_fprintf(experimentDetails,'No fuccifits have been gathered. \n%s does not exist.\n',fitsFile);
        return;
    end
end

numPlots = length(fits);
greenTimes = [fits.p1_goff] - [fits.p1_gon];
greenSlope = [fits.p1_m1];
% greenOrder = transpose([(1:numPlots)  ; greenTimes  ]);
greenOrder = transpose([(1:numPlots)  ; greenSlope  ]);
greenSorted = sortrows(greenOrder,2);

for j=1:numPlots
    i = greenSorted(j,1);
    p = fits(i);
    % Incoming: d:\experiments\20111118\exports_intermediate_files\outputs\fuccifits_unmixed\20111118-0026_Position(10)_fuccifits, D 1
    % Outgoing: 20111118-0026_Position(6)_fuccifits_well_D_1_gfp.csv
    origName = p.position;
    stem = origName((1+find(origName=='\',1,'last')):end);
    gfpFile = sprintf('%s_well_%c_%d_gfp.csv',stem,p.row,p.col);
    gfpTable = readHeaderedFile(strcat(fuccipath,gfpFile),1,experimentDetails);
    if(isempty(gfpTable))
        log_fprintf(experimentDetails,'The file %s cannot be read. Skipping.\n',strcat(fuccipath,gfpFile));
        return;
    end
    tStart = p.p1_gon;
    tEnd = p.p1_goff;
    t = [gfpTable.time];
    gfp = [gfpTable.integratedFluoresence];
    idx = t>=tStart & t<=tEnd;
    t = t(idx) - tStart;
    % t = t(idx) - tEnd;
    gfp = gfp(idx);
    % gfp = gfp(idx)-max(gfp(idx));
    if(j==1)
        tMax = 2 * t(end);
        if(tMax==0)
            tMax=10;
        end
        gfpMax = 2 * max(gfp);
        tMin = 2 * t(1);
        gfpMin = 2 * min(gfp);
    end
    h = figure();
    plot(t,gfp,'g.');
    xlabel('time (hours)');
    xlim([0 tMax]);
    ylim([0 gfpMax]);
%    xlim([tMin 0]);
%    ylim([gfpMin 0]);
    ylabel('Total GFP');
    title(strrep(gfpFile,'_',' '));
    pngFile = strcat(fuccipath,strrep(gfpFile,'csv','png'));
    print(h, '-dpng', pngFile, '-r 600');
    close(h) 
end


dirPattern = strcat(fuccipath,'*_gfp.png');
fileList = dir(dirPattern);
files = length(fileList);
if(files==0)
    log_fprintf(experimentDetails,'No files found with pattern %s\n',dirPattern);
else
    if(experimentDetails.noClobber && fileExists(aviFile))
        log_fprintf(experimentDetails,'The fits avi file %s already exists. Skipping.\n',aviFile);
    else
        pics2avi(fuccipath,fileList,aviFile);
    end
end



