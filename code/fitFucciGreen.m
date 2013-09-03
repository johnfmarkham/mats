function [p q r] = fitFucciGreen(positionDetails,cellDetails,row,col,gfp,rfp,filenameStem)
% Fit to fucci green fluorescence data up to 4 cells to extract division
% times and time in S-phase. p contains all the stuff about this.
% q contains some fields describing what peaks were found and the
% r contains the fitted data
% status.

global debug_figure_handle;
global ydata_global;
global rejection_reason;
global rejection_flag;
global logfile_fd_global;
logfile_fd_global= positionDetails.logfile_fd;
debug_figure_handle = 117;
rejection_flag = 0;
rejection_reason = '';
 
debug = 1;
q.red = zeros(2,1); % row is division, col is # cells+1
q.green = zeros(2,1);
r.yGFP = []; % initialise time series
r.tGFP = [];
r.yGFP = [];
r.tGFP = [];

% options.filterLength = 15;
% options.cutoffHistGFP = 0.5;
% options.cutoffHistRFP = 0.85;
% options.maxGap = 40;
% options.minWidthGFP = 50;
% options.minWidthRFP = 10;
% options.maxOvershoot = 10;
options.maxTwoCellInOneCellIsland = positionDetails.fucciMaxTwoCellInOneCellIsland;
options.filterLength = positionDetails.fucciMedianFilterLength;
options.cutoffHistGFP = positionDetails.fucciCutoffGFP;
options.cutoffHistRFP = positionDetails.fucciCutoffRFP;
options.maxGap = positionDetails.fucciMaxMissingCellGap;
options.minWidthGFP = positionDetails.fucciMinGFPTime;
options.minWidthRFP = positionDetails.fucciMinRFPTime;
options.maxWidthGFP = positionDetails.fucciMaxGFPTime;
options.maxWidthRFP = positionDetails.fucciMaxRFPTime;
options.maxOvershootOn = positionDetails.fucciMaxOvershootOn;
options.maxOvershootOff = positionDetails.fucciMaxOvershootOff;
options.fucciMaxThreeCellInTwoCellIsland = positionDetails.fucciMaxThreeCellInTwoCellIsland;
options.fucciPercentileFilter = positionDetails.fucciPercentileFilter;

options.min_px1x2 = 0;
options.max_px1x2 = 0.5;
idx = find(filenameStem=='\',1,'last');
options.file = strrep(filenameStem(idx+1:end),'_',' ');

segmentingGreen = 1;
maxGaps = [1000,400,0,400]; % min/max division times
minGaps = [0,20,0,50];
channelNumGFP = gfp.channelNum;
channelNumRFP = rfp.channelNum;
yNameGFP = gfp.channelName;
yNameRFP = rfp.channelName;
yQuantityGFP = gfp.quantity;
yQuantityRFP = rfp.quantity;
rows = [cellDetails.row];
cols = [cellDetails.col];
times = [cellDetails.time];
frames = [cellDetails.frame];
yGFPMixed = [cellDetails.(yQuantityGFP)];
yRFPMixed = [cellDetails.(yQuantityRFP)];
% Hack unmix - which I think may be wrong since 
if(isfield(positionDetails,'fucciGreenFromRedUnmix') && isfield(positionDetails,'fucciRedFromGreenUnmix'))
    yGFP = yGFPMixed - positionDetails.fucciRedFromGreenUnmix * yRFPMixed;
    yRFP = yRFPMixed - positionDetails.fucciGreenFromRedUnmix * yGFPMixed;
else
    yGFP = yGFPMixed;
    yRFP = yRFPMixed;
end
channelNums = [cellDetails.channelNum];

allCellsGFP = (channelNums==channelNumGFP);
sortedGFP = sort(yGFP(allCellsGFP));
if(options.cutoffHistGFP>1)
    cutoffGFP = options.cutoffHistGFP; % assume an actual numerical value
elseif(floor(length(sortedGFP)*options.cutoffHistGFP)>0)
    cutoffGFP = sortedGFP(floor(length(sortedGFP)*options.cutoffHistGFP));
    cutoffGFP = max(0,cutoffGFP);
else
    cutoffGFP = 0;
end

allCellsRFP = (channelNums==channelNumRFP);
sortedRFP = sort(yRFP(allCellsRFP));
if(options.cutoffHistRFP>1)
    cutoffRFP = options.cutoffHistRFP; % assume an actual numerical value
elseif(floor(length(sortedRFP)*options.cutoffHistRFP)>0)
    cutoffRFP = sortedRFP(floor(length(sortedRFP)*options.cutoffHistRFP));
    cutoffRFP = max(0,cutoffRFP);
else
    cutoffRFP = 0;
end

selectedCellsGFP = ((channelNums==channelNumGFP) & (rows==row) & (cols==col));
selectedCellsRFP = ((channelNums==channelNumRFP) & (rows==row) & (cols==col));
selectedCellsGFPCutoff = ((channelNums==channelNumGFP) & (rows==row) & (cols==col) & (yGFP>cutoffGFP));
selectedCellsRFPCutoff = ((channelNums==channelNumRFP) & (rows==row) & (cols==col) & (yRFP>cutoffRFP));
% nCells = sum(selectedCells);
% Extract GFP data
yGFPCutoff = yGFP(selectedCellsGFPCutoff);
tGFPCutoff = times(selectedCellsGFPCutoff);
yGFP = yGFP(selectedCellsGFP);
tGFP = times(selectedCellsGFP);
plotDataGFP = cellDetails(selectedCellsGFP);
csvFileGFP = strcat(filenameStem,'_gfp.csv');

% Extract RFP data
yRFPCutoff = yRFP(selectedCellsRFPCutoff);
tRFPCutoff = times(selectedCellsRFPCutoff);
yRFP = yRFP(selectedCellsRFP);
tRFP = times(selectedCellsRFP);
plotDataRFP = cellDetails(selectedCellsRFP);
csvFileRFP = strcat(filenameStem,'_rfp.csv');

% Build number of cells versus time and FP intensities vs time
unique_t = unique(times);
unique_f = unique(frames);
nCellsGFP = zeros(size(unique_t));
nCellsRFP = zeros(size(unique_t));
intensityGFP = zeros(size(unique_t));
intensityRFP = zeros(size(unique_t));
for i=1:length(unique_t)
    ut = unique_t(i);
    nCellsGFP(i) = sum(tGFPCutoff==ut);
    nCellsRFP(i) = sum(tRFP==ut);
    intensityGFP(i) = sum(yGFP(tGFP==ut));
    intensityRFP(i) = sum(yRFP(tRFP==ut));
end
plotFile = strcat(filenameStem,'.png');
% Find the regions when you think there are 1, 2 and 4 cells
% Median filter x over width filterLength
nCellsMedianGFP = median1D(nCellsGFP,options.filterLength,options.fucciPercentileFilter);
nCellsMedianRFP = median1D(nCellsRFP,options.filterLength,options.fucciPercentileFilter);
% tn = findCellDivisions(nCellsMedian,unique_t,minGaps,maxGaps,segmentingGreen);
tnGFP = findCellDivisionsFromGFP(nCellsMedianGFP,unique_t,tGFPCutoff,tRFPCutoff,options.maxGap,options.minWidthGFP,options.maxTwoCellInOneCellIsland,options.fucciMaxThreeCellInTwoCellIsland);
while(tnGFP(3)-tnGFP(2) > options.maxWidthRFP || tnGFP(4)-tnGFP(3) > options.maxWidthGFP || tnGFP(2)-tnGFP(1) > options.maxWidthGFP)
    options.maxGap = options.maxGap/2;  
    log_fprintf(positionDetails,'Retrying fitting with maxGap = %.2f\n',options.maxGap);
    if(options.maxGap < positionDetails.fucciMaxMissingCellGap * 0.125)
        rejection_reason = 'GFP island or RFP time too big';
        rejection_flag = 1;
        break;
    end
    tnGFP = findCellDivisionsFromGFP(nCellsMedianGFP,unique_t,tGFPCutoff,tRFPCutoff,options.maxGap,options.minWidthGFP,options.maxTwoCellInOneCellIsland,options.fucciMaxThreeCellInTwoCellIsland);
end

tnRFP1 = [0 0];
tnRFP2 = [0 0];
if(tnGFP(4)~=0)
    tnRFP2 = findG1FromRFP(nCellsMedianRFP,unique_t,2,tRFP,tGFPCutoff,tnGFP(2),tnGFP(3),options.maxGap,options.minWidthRFP);
    tnRFP1 = findG1FromRFP(nCellsMedianRFP,unique_t,1,tRFP,tGFPCutoff,unique_t(1),tnGFP(1),options.maxGap,options.minWidthRFP);
    if(tnRFP2(2)~=0)
       q.red(2) = 2;
    else
       tnRFP2 = findG1FromRFP(nCellsMedianRFP,unique_t,1,tRFP,tGFPCutoff,tnGFP(2),tnGFP(3),options.maxGap,options.minWidthRFP);
       if(tnRFP2(2)~=0)
           q.red(2) = 1; 
       end
    end
    q.green(1) = 1;
    q.green(2) = 2;
elseif(tnGFP(2)~=0)
    tnRFP2 = findG1FromRFP(nCellsMedianRFP,unique_t,2,tRFP,tGFPCutoff,tnGFP(2),unique_t(end),options.maxGap,options.minWidthRFP);
    tnRFP1 = findG1FromRFP(nCellsMedianRFP,unique_t,1,tRFP,tGFPCutoff,unique_t(1),tnGFP(1),options.maxGap,options.minWidthRFP);
    if(tnRFP2(2)~=0)
       q.red(2) = 2;
    else
       tnRFP2 = findG1FromRFP(nCellsMedianRFP,unique_t,1,tRFP,tGFPCutoff,tnGFP(2),unique_t(end),options.maxGap,options.minWidthRFP);
       if(tnRFP2(2)~=0)
           q.red(2) = 1;
       end
    end
    q.green(1) = 1;
else
    tnRFP1 = findG1FromRFP(nCellsMedianRFP,unique_t,1,tRFP,tGFPCutoff,unique_t(1),unique_t(end),options.maxGap,options.minWidthRFP);
end

if(tnRFP1(2)~=0)
   q.red(1) = 1;
end

% Find if it's a one cell well and if so whether it turns into 4 cells
% Everything will be filled in if it is
p = [];
p1 = [];
p2 = [];
p3 = [];
f = {'tGFP','yGFP','tGFPCutoff','yGFPCutoff','yNameGFP','nCellsGFP','tnGFP','tRFPCutoff','nCellsMedianGFP','p','p1','p2','p3','unique_t',...
     'tRFP','yRFP','tGFPCutoff','yRFPCutoff','yNameRFP','nCellsRFP','tnRFP1','tnRFP2','tRFPCutoff','nCellsMedianRFP'};
for i = 1:length(f)
    str = strcat('options.',f{i},' = ',f{i},';');
    eval(str);
end

if(tnGFP(4)==0)
    if(debug)
        writeDebugImage(plotFile,options);
    end
    log_fprintf(positionDetails,strcat('Could not fit because: ',rejection_reason,'\n'));
else    
    % Fit first peak 
    p1 = fitPeak(tGFPCutoff,yGFPCutoff,tnGFP(1),tnGFP(2),options,positionDetails);
    % Fit second peak 
    p2 = fitPeak(tGFPCutoff,yGFPCutoff,tnGFP(3),tnGFP(4),options,positionDetails);
    % Calculate observables and return answers
    p.tstart = p1.goff;
    p.tend = p2.goff;
    p.tgon = p2.gon;
    p.proportionSphase = (p.tend-p.tgon)/(p.tend-p.tstart);
    ind1 = find(unique_t==tnGFP(1),1,'first');
    ind2 = find(unique_t==tnGFP(2),1,'first');
    ind3 = find(unique_t==tnGFP(3),1,'first');
    ind4 = find(unique_t==tnGFP(4),1,'first');
    p.div1_frame = unique_f(ind2);
    p.div2_frame = unique_f(ind4);
    p.div2_gon_frame   = unique_f(ind3);
    p.div2_goff_frame   = unique_f(ind4);
    p.div2_ron_frame   = 0;
    p.div2_roff_frame   = 0;
    p.proportionTwoCellInIsland = sum(nCellsGFP(ind3:ind4)==2)/(ind4-ind3+1);
    p.GFPOneCellOn = tnGFP(1);
    p.GFPOneCellOff = tnGFP(2);
    p.GFPOneCellMeanIntensity = mean(intensityGFP(ind1:ind2));
    p.GFPOneCellMaxIntensity = max(intensityGFP(ind1:ind2));
    p.GFPOneCellRateIntensity = p.GFPOneCellMaxIntensity/(tnGFP(2) - tnGFP(1));

    p.GFPTwoCellOn = tnGFP(3);
    p.GFPTwoCellOff = tnGFP(4);
    p.GFPTwoCellMeanIntensity = mean(intensityGFP(ind3:ind4));
    p.GFPTwoCellMaxIntensity = max(intensityGFP(ind3:ind4));
    p.GFPTwoCellRateIntensity = p.GFPTwoCellMaxIntensity/(tnGFP(4) - tnGFP(3));

    p.RFPTwoCellOn = tnGFP(2);
    p.RFPTwoCellOff = tnGFP(3);
    p.RFPTwoCellMeanIntensity = mean(intensityRFP(ind2:ind3));
    p.RFPTwoCellMaxIntensity = max(intensityRFP(ind2:ind3));
    p.RFPTwoCellRateIntensity = p.RFPTwoCellMaxIntensity/(tnGFP(3) - tnGFP(2));


    % p.residual = sqrt(p1.residual^2 + p2.residual^2);
    p.resnorm = sqrt(p1.resnorm^2 + p2.resnorm^2);
    p.resnorm2 = sqrt(p1.resnorm2^2 + p2.resnorm2^2);
    if(tnRFP2(2) && ~isempty(tRFPCutoff))
        p3 = fitPeak(tRFPCutoff,yRFPCutoff,tnRFP2(1),tnRFP2(2),options,positionDetails);
        rind1 = find(unique_t==tnRFP2(1),1,'first');
        rind2 = find(unique_t==tnRFP2(2),1,'first');
        p.div2_ron_frame = unique_f(rind1);
        p.div2_roff_frame = unique_f(rind2);
    else
        p3 = vectoparams(setlb([0],[0],0,0,0)); % need something
        p3.resnorm = 0;
        p3.resnorm2 = 0;
%         p3.residual = 0;
%         p3.t = 0;
%         p3.y = 0;
    end
    f = fieldnames(p1);
    for i=1:length(f)
        p.(strcat('p1_',f{i})) = p1.(f{i});
        p.(strcat('p2_',f{i})) = p2.(f{i});
        p.(strcat('p3_',f{i})) = p3.(f{i});
    end
    options.p = p;
    options.p1 = p1;
    options.p2 = p2;
    options.p3 = p3;
    writeDebugImage(plotFile,options);
    saveTable(plotDataGFP,csvFileGFP);
    saveTable(plotDataRFP,csvFileRFP);
    if(debug>1)
        ydata_global = yGFP; % keeps func plot happy
        x = paramstovec(p1);
        func(x,tGFP);
        print(debug_figure_handle, '-dpng', strcat(filenameStem,'_1.png'), '-r 600');
        x = paramstovec(p2);
        func(x,tGFP);
        print(debug_figure_handle, '-dpng', strcat(filenameStem,'_2.png'), '-r 600');

        ydata_global = yRFP; % keeps func plot happy
        x = paramstovec(p3);
        func(x,tRFP);
        print(debug_figure_handle, '-dpng', strcat(filenameStem,'_3.png'), '-r 600');
    end
end
q.rejection_flag = rejection_flag;
q.rejection_reason = rejection_reason;
r.yGFP = yGFP;
r.tGFP = tGFP;
r.yGFP = yRFP;
r.tGFP = tRFP;

%------------------------------------
function p = fitPeak(t,y,tstart,tend,options,positionDetails)
%------------------------------------
global ydata_global;

idx = ((t>=tstart) & (t<=tend));
if(isempty(idx) || sum(idx)==0 || length(idx)<=6)
    log_fprintf(positionDetails,'Need at least data points to fit to. have only %d\n',length(idx));
    p = vectoparams(setlb([0],[0],0,0,0));
    p.resnorm = 0;
    p.resnorm2 = 0;
    return;
end
xdata = t(idx);
ydata = y(idx);
ydata_global = ydata;
ymax = max(ydata);
tmaxind = find((ydata==ymax),1,'last');
tmax = xdata(tmaxind);
lb = setlb(xdata,ymax,options.maxOvershootOn,options.maxOvershootOff,options.min_px1x2);
ub = setub(xdata,ymax,options.maxOvershootOn,options.maxOvershootOff,options.max_px1x2);
x0 = setx0(xdata,tmax,ymax,options.min_px1x2);

% Optimise this fit
%options = optimset('MaxFunEvals', 1000, 'TolFun', 1e-1, 'Display', 'final', 'LargeScale', 'off');
options = optimset('MaxFunEvals', 1000, 'TolFun', 1e-1, 'Display', 'off');
try
    [x,resnorm,residual,exitflag,output] = lsqcurvefit(@func,x0,xdata,ydata,lb,ub,options);
catch err
    log_fprintf(positionDetails,'There has been a problem fitting: %s\n',err.message);
    log_fprintf(positionDetails,'xdata = %f\n',xdata);
    log_fprintf(positionDetails,'ydata = %f\n',ydata);
    log_fprintf(positionDetails,'x0 = %f\n',x0);
    p = vectoparams(setlb([0],[0],0,0,0));
    p.resnorm = 0;
    p.resnorm2 = 0;
    return;
end
    
p = vectoparams(x);
p.resnorm = resnorm;
p.resnorm2 = sqrt(sum(residual.^2))/sum(ydata);
% p.residual = residual;
% p.y = y;
% p.t = t;
    %------------------------------------
function ret = median1D(x,n,percentile)
%------------------------------------
% Median filter x over width n
xs = zeros(length(x),n);
m = length(x);
for i=1:n
    xs(i:m,i) = x(1:m+1-i);
end
xs = sort(xs,2);
% ret = median(xs,2);
ret = xs(:,ceil(percentile*n));
%------------------------------------
function tn = findG1FromRFP(nCells,unique_t,peakHeight,tRFP,tGFP,tnMin,tnMax,maxGap,minWidth)
%------------------------------------
tn(1:2) = findIsland(nCells,tGFP,unique_t,peakHeight,tnMin,tnMax,minWidth);
if(sum(tn(1:2)==0))
    return;
end
tn(1) = extendIsland(tRFP,tGFP,unique_t,tn(1),tnMin,-1,maxGap);
tn(2) = extendIsland(tRFP,tGFP,unique_t,tn(2),tnMax,1,maxGap);
%------------------------------------
function tn = findCellDivisionsFromGFP(nCells,unique_t,tGFP,tRFP,maxGap,minWidth,maxTwoCellInOneCellIsland,fucciMaxThreeCellInTwoCellIsland)
%------------------------------------
% Return where green goes on and off
% nCellsMedian = median1D(nCellsGFP,options.filterLength);
global rejection_reason;
global rejection_flag;
% maxOneCellInTwoCellIsland = 0.05;

tn = [0 0 0 0];
if(isempty(unique_t) || isempty(nCells))
    rejection_reason = 'No cells or times';
    rejection_flag = 1;
    return;
end
tn(1:2) = findIsland(nCells,tRFP,unique_t,1,unique_t(1),unique_t(end),minWidth);
if(sum(tn(1:2)==0))
    rejection_reason = '1 cell GFP island missing';
    rejection_flag = 1;
    return;
end
tn(1) = extendIsland(tGFP,tRFP,unique_t,tn(1),unique_t(1),-1,maxGap);
tn(2) = extendIsland(tGFP,tRFP,unique_t,tn(2),unique_t(end),1,maxGap);
ind1 = find(unique_t==tn(1),1,'first');
ind2 = find(unique_t==tn(2),1,'first');
n1 =  sum(nCells(ind1:ind2)==1);
n2 =  sum(nCells(ind1:ind2)==2);
if( n2 > maxTwoCellInOneCellIsland * n1 )
    rejection_reason = sprintf('1 cell island had too many instances of 2 cells in it: n2/n1 = %d/%d',n2,n1);
    rejection_flag = 1;
    return;
end

tn(3:4) = findIsland(nCells,tRFP,unique_t,2,tn(2)+maxGap,unique_t(end),minWidth);
if(sum(tn(3:4)==0))
    rejection_reason = '2 cell GFP island missing';
    rejection_flag = 1;
    return;
end
tn(3) = extendIsland(tGFP,tRFP,unique_t,tn(3),tn(2)+maxGap,-1,maxGap);
tn(4) = extendIsland(tGFP,tRFP,unique_t,tn(4),unique_t(end),1,maxGap);
ind3 = find(unique_t==tn(3),1,'first');
ind4 = find(unique_t==tn(4),1,'first');

n3 =  sum(nCells(ind3:ind4)>=3);
n2 =  sum(nCells(ind3:ind4)==2);
if(n3 > fucciMaxThreeCellInTwoCellIsland * n2 )
    rejection_reason = sprintf('2 cell island had too many instances of >=3 cells in it: n3/n2 = %d/%d',n3,n2);
    rejection_flag = 1;
    tn(3) = 0;
    tn(4) = 0;
    return;
end
% Avoid searching overhang from median filtering
for endIsland = ind2:ind3
    if(nCells(endIsland)==0)
        break;
    end
end
% Don't put in tRFP because we don't care about this for "bad" islands
badIsland = findIsland(nCells,[],unique_t,1,unique_t(endIsland),tn(3),minWidth);
if(badIsland(1))
    rejection_reason = sprintf('Extra island found between t=%.2f and t=%.2f at t=%.2f and t=%.2f\n',tn(2),tn(3),badIsland(1),badIsland(2));
    rejection_flag = 1;
    tn(3) = 0;
    tn(4) = 0;
    return;
end
%------------------------------------
function tn = findIsland(nCells,tOtherChannel,unique_t,height,fromWhereTime,toWhereTime,minWidth)
%------------------------------------
% Find regions where 1 and 2 cells are green/red and none in the other
% channel are red/green
width = 0;
tn = [0 0];
tiny = 1e-4;
% The times don't always exactly match because sometimes searching starts after maxGap
% So we start at the next available time.
fromWhere = find(unique_t>=fromWhereTime,1,'first')+1;
toWhere = find(unique_t>=toWhereTime,1,'first');
if(isempty(fromWhere))
    fromWhere = find(abs(unique_t-fromWhereTime)./(unique_t+fromWhereTime)<tiny,1,'first')+1;
end
if(isempty(toWhere))
    toWhere = find(abs(unique_t-toWhereTime)./(unique_t+toWhereTime)<tiny,1,'first');
end
tstart = 0;
foundGap = 1;
for tindex=fromWhere:toWhere
    t = unique_t(tindex);
    if(nCells(tindex)==height && sum(tOtherChannel==t)==0)
        if(tstart==0 || foundGap)
            tstart = t;
            foundGap = 0;
        end
    else
        foundGap = 1;
    end
%     log_fprintf(positionDetails,' %4d %4d %4d\n',tstart,t,t-tstart+1);
    if((t-tstart)>minWidth && foundGap==0)
        tn = [tstart t];
%         log_fprintf(positionDetails,'*%4d %4d %4d\n',tstart,t,t-tstart+1);
        break;
    end
end
%------------------------------------
function tend = extendIsland(tGFP,tRFP,unique_t,fromWhereTime,toWhereTime,dir,maxGap)
%------------------------------------
% Glob together regions where 1 and 2 cells are green that look like they
% belong with each other, but which are separated by small regions with no
% cells
tiny = 1e-4;
fromWhere = find(unique_t==fromWhereTime,1,'first');
toWhere = find(unique_t==toWhereTime,1,'first');
if(isempty(fromWhere))
    fromWhere = find(abs(unique_t-fromWhereTime)./(unique_t+fromWhereTime)<tiny,1,'first')+1;
end
if(isempty(toWhere))
    toWhere = find(abs(unique_t-toWhereTime)./(unique_t+toWhereTime)<tiny,1,'first');
end
tend = fromWhereTime;

for tindex=fromWhere:dir:toWhere
    t = unique_t(tindex);
    if(sum(tGFP==t)>0)
        tend = t;
    end
    if((t-tend)*dir > maxGap)
        break;
    end
end
%------------------------------------
function tn  = findCellDivisions(nCells,unique_t,minGaps,maxGaps,segmentingGreen)
%------------------------------------
times = length(nCells);
tn = [0 0 0 0];
tn0 = min(unique_t);
foundGreenAgain = 0; % green has re-appeared after a division
for i=1:times
    t = unique_t(i);
    nc = nCells(i);
    if(tn(1)==0)
        if(nc==1)
            if((t-tn0)<minGaps(1))
                log_fprintf(positionDetails,'nc = %d %.1f < minGaps1 %4.1f',nc,(t-tn0),minGaps(1));
                return;
            end
            tn(1)=t;
        elseif( (t-tn0)>maxGaps(1) )
            log_fprintf(positionDetails,'nc = %d %.1f < maxGaps1 %4.1f',nc,(t-tn0),maxGaps(1));
            return;
        end
    elseif(tn(2)==0)
        if(segmentingGreen)
            if(nc>1 || (t-tn(1))>maxGaps(2))
                log_fprintf(positionDetails,'nc = %d %4.1f < maxGaps2 %4.1f',(t-tn(1)),maxGaps(2));
                return;
            elseif(nc==0)
                if((t-tn(1))<minGaps(2))
                    log_fprintf(positionDetails,'nc = %d %4.1f < minGaps2 %4.1f',nc,t-tn(1),minGaps(2));
                    return
                end;
                tn(2) = t;
            end
        else
            if(nc>2 || (t-tn(1))>maxGaps(2))
                log_fprintf(positionDetails,'nc = %d %4.1f < maxGaps2 %4.1f',nc,(t-tn(1)),maxGaps(2));
                return;
            elseif(nc==2)
                if((t-tn(1))<minGaps(2))
                    log_fprintf(positionDetails,'nc = %d %4.1f < %4.1f',nc,(t-tn(1)),minGaps(2));
                    return
                end
                tn(2) = t;
            end
        end
    elseif(tn(4)==0)
        if(segmentingGreen)
            if(nc>2 || (t-tn(2))>maxGaps(4))
                log_fprintf(positionDetails,'nc = %d %4.1f < maxGaps4 %4.1f',nc,t-tn(2),maxGaps(4));
                return
            elseif((nc==1 || nc==2) && foundGreenAgain==0)
                foundGreenAgain = 1;
            elseif(nc==0 && foundGreenAgain~=0)
                if((t-tn(2))>=minGaps(4))
                    tn(4) = t;
                else
                    log_fprintf(positionDetails,'nc = %d %4.1f < minGaps4 %4.1f',nc,(t-tn(2)),minGaps(4));
                end
                return;
            end
        else
            if(nc>4 || (t-tn(2))>maxGaps(4))
                return
            else
                if((t-tn(2))>=minGaps(4))
                    tn(4) = t;
                end
                return;
            end
        end
    else
        log_fprintf(positionDetails,'nc = %d t=%4.1f',nc,t);
        return;
    end
end
%------------------------------------
function p = vectoparams(x)
%------------------------------------
p.x1 = x(1);
p.px1x2 = x(2); % proportion of x3-x1 given over to x2-x1
p.px1x3 = x(3); % proportion of x4-x1 given over to x3-x1
p.x4 = x(4);
p.m1 = x(5);
p.dm12 = x(6); % difference between tan of the angle m1 and m2 in radians

p.y1 = 0;
p.y4 = 0;

p.x3 = p.x1 + p.px1x3 * (p.x4-p.x1);
p.x2 = p.x1 + p.px1x2 * (p.x3-p.x1);
p.y2 = p.y1 + p.m1 * (p.x2-p.x1);
p.m2 = p.m1 + p.dm12;
p.y3 = p.y2 + p.m2 * (p.x3-p.x2);
p.m3 = (p.y4-p.y3)/(p.x4-p.x3);
p.gon = p.x1;
p.goff = p.x4;
%------------------------------------
function x = paramstovec(p)
%------------------------------------
% x = [p.x1,p.dx1x2,p.m1,p.dx2x3,p.dm12,p.dx3x4];
if(isempty(p))
    x = [0 0 0 0 0 0]
else
    x = [p.x1,p.px1x2,p.px1x3,p.x4,p.m1,p.dm12];
end
%------------------------------------
function x0 = setx0(xdata,tmax,ymax,min_px1x2)
%------------------------------------
tstart = xdata(1);
tend = xdata(end);
p.x1 = tstart;
% p.px1x2 = 0.7;
p.px1x2 = min_px1x2;
if(tend>tmax)
    p.px1x3 = (tend-tmax)/(tmax-tstart);
else
    p.px1x3 = 0.99;
end
p.x4 = tend;
p.m1 = ymax/(tend-tstart);
p.dm12 = 0;
x0 = paramstovec(p);
%------------------------------------
function lb = setlb(xdata,ymax,maxOvershootOn,maxOvershootOff,min_px1x2)
%------------------------------------
% p.px1x2 = x(2); % proportion of x3-x1 given over to x2-x1
% p.px1x3 = x(3); % proportion of x4-x1 given over to x3-x1
% p.dm12 = x(6); % difference between tan of angle m1 and m2
tstart = xdata(1);
tend = xdata(end);
p.x1 = tstart-maxOvershootOn;
p.px1x2 = min_px1x2;
if(tend==tstart)
    p.px1x3 = 0.95;
else
    p.px1x3 = 1 - (maxOvershootOff/(tend-tstart));
end
p.x4 = tend-maxOvershootOff;
if(tend==tstart)
    p.m1 = 0;
    p.dm12 = 0;
else
%     p.m1 = 0.5 * ymax/(tend-tstart);
    p.m1 = 0;
    p.dm12 =  - 10 * ymax/(tend-tstart);
end
% p.dm12 = -0.01;
% p.dm12 = -p.m1/2;
lb = paramstovec(p);
%------------------------------------
function ub = setub(xdata,ymax,maxOvershootOn,maxOvershootOff,max_px1x2)
%------------------------------------
tstart = xdata(1);
tend = xdata(end);
p.x1 = tstart+maxOvershootOn;
p.px1x2 = max_px1x2;
% p.px1x2 = 0.01;
p.px1x3 = 1;
p.x4 = tend+maxOvershootOff;
if(tend==tstart)
    p.m1 =  10 * ymax;
else
    p.m1 = 10 * ymax/(tend-tstart);
end
p.dm12 = 0;
ub = paramstovec(p);
%------------------------------------
function y = func(x,t)
%------------------------------------
%% The function we want to minimise.

% It worries me that injecting things in with globals may break when this
% is called by something in a parfor loop (as it is).
global logfile_fd_global;
global ydata_global;
global debug_figure_handle;
debug = 0;
y = zeros(size(t));
p = vectoparams(x);
y1 = 0;
idx = (t>p.x1) & (t<p.x2);
y(idx) =   y1 + (t(idx)-p.x1) * p.m1;

idx = (t>=p.x2) & (t<p.x3);
y(idx) = p.y2 + (t(idx)-p.x2) * p.m2;

idx = (t>=p.x3) & (t<p.x4);
y(idx) = p.y3 + (t(idx)-p.x3) * p.m3;
if(debug)
    figure(debug_figure_handle);
    plot(t,y,'b.');
    hold on;

    if(length(y)==length(ydata_global))
        diff = y-ydata_global;
        mse = sqrt(mean(diff.*diff))/mean(ydata_global);
        title(sprintf('mse = %4.3f',mse));
        plot(t,ydata_global,'g.');
        fprintf(logfile_fd_global,'mse = %4.3f ',mse);
    else
        fprintf(logfile_fd_global,'    ');
    end
    textOff = 1.05;
    text(p.x1,p.y1,sprintf('(%4.1f,%4.1f)',p.x1,p.y1));
    text((p.x1+p.x2)/2,textOff * (p.y1+p.y2)/2,sprintf('%4.1f',p.m1));
    text(p.x2,p.y2,sprintf('(%4.1f,%4.1f) dm12 = %4.1f',p.x2,p.y2,p.dm12));
    text((p.x2+p.x3)/2,textOff * (p.y2+p.y3)/2,sprintf('%4.1f',p.m2));
    text(p.x3,p.y3,sprintf('(%4.1f,%4.1f)',p.x3,p.y3));
    text((p.x3+p.x4)/2,textOff * (p.y3+p.y4)/2,sprintf('%4.1f',p.m3));
    text(p.x4,p.y4,sprintf('(%4.1f,%4.1f)',p.x4,p.y4));
    hold off;
    f = fieldnames(p);
    for i=1:length(f)
        fprintf(logfile_fd_global,'%s=%4.1f ',f{i},p.(f{i}));
    end
    fprintf(logfile_fd_global,'\n');
end
%---------------------------------------
function writeDebugImage(plotFile,options)
%------------------------------------
% Prints measurements to a jpg file
global ydata_global;
global rejection_reason;
global rejection_flag;
global debug_figure_handle;
% This transfers all the fields in options into the name space of this
% function. p1, p2, p3, x1, x2... come from here
f = fieldnames(options);
for i = 1:length(f)
    str = strcat(f{i},' = options.',f{i},';');
    eval(str);
end

%h = figure('color','white','units','normalized','position',[0 0 1 1],'Visible','off'); 
%im = zeros(4096,8192);
%set(h,'units','pixels','position',[5 5 size(im,2)-10 size(im,1)-10],'visible','off')
h = figure(debug_figure_handle);
set(debug_figure_handle,'visible','off')
set(debug_figure_handle,'Position',[0 0 2048 2048])
nPlotRows = 3;
nPlotCols = 2;
if(isempty(unique_t) || length(unique_t)<1)
    tmax = 1;
else
    tmax = max(unique_t);
end

% 1. and 2. Cells vs time with cell num markers
subplot(nPlotRows,nPlotCols,1);
plot(unique_t,nCellsGFP,'b.');
hold on;
plot([tnGFP(1) tnGFP(1)],[0 1],'g-');
plot([tnGFP(1) tnGFP(2)],[1 1],'g-');
plot([tnGFP(2) tnGFP(2)],[0 1],'g-');

plot([tnGFP(3) tnGFP(3)],[0 2],'g-');
plot([tnGFP(3) tnGFP(4)],[2 2],'g-');
plot([tnGFP(4) tnGFP(4)],[0 2],'g-');
xlim([0,tmax]);
xlabel('time (h)');
str2 = '# segmented cells from GFP vs time';
if(rejection_flag)
    title({file,strcat('Rejected: ',rejection_reason),str2});
else
    str1 = sprintf('t_{div} = %6.2f S_{phase}/t_{div} = %5.2f',(p.tend-p.tstart),p.proportionSphase);
    title({file,str1,str2});
end
ylabel('#cells');
hold off;

subplot(nPlotRows,nPlotCols,3);
plot(unique_t,nCellsMedianGFP,'b');
hold on;
% plot([tnGFP(1) tnGFP(1)],[0 1],'k-');
% plot([tnGFP(2) tnGFP(2)],[0 2],'k-');
% plot([tnGFP(4) tnGFP(4)],[0 4],'k-');
xlim([0,tmax]);
xlabel('time (h)');
title('median filtered # segmented cells from GFP vs time');
ylabel('#cells');

% 3. Fl vs time with fits
subplot(nPlotRows,nPlotCols,5);
hold on;
plot(tGFP,yGFP,'c.');
plot(tGFPCutoff,yGFPCutoff,'g.');
if(~isempty(p1) && ~isempty(p2))
    ydata_global = yGFP; % keeps func plot happy
    x1 = paramstovec(p1);
    y1 = func(x1,tGFP);
    x2 = paramstovec(p2);
    y2 = func(x2,tGFP);
    hold on;
    tIndex = tGFP>=p1.x1 & tGFP<=p1.x4;
    plot(tGFP(tIndex),y1(tIndex),'b');
    tIndex = tGFP>=p2.x1 & tGFP<=p2.x4;
    plot(tGFP(tIndex),y2(tIndex),'b');
    plot([p1.x1 p1.x4],[0 0],'b*');
    plot([p2.x1 p2.x4],[0 0],'b*');
    hold off;
end
xlim([0,tmax]);
if(~isempty(yGFPCutoff) && max(yGFPCutoff)>0)
    ylim([0,max(yGFPCutoff)]);
end
xlabel('time (h)');
ylabel(yNameGFP);
title(sprintf('%s versus time',yNameGFP));

% 4. and 5. Cells vs time with cell num markers
subplot(nPlotRows,nPlotCols,2);
plot(unique_t,nCellsRFP,'b.');
hold on;
plot([tnRFP1(1) tnRFP1(1)],[0 1],'r-');
plot([tnRFP1(1) tnRFP1(2)],[1 1],'r-');
plot([tnRFP1(2) tnRFP1(2)],[0 1],'r-');
plot([tnRFP2(1) tnRFP2(1)],[0 2],'r-');
plot([tnRFP2(1) tnRFP2(2)],[2 2],'r-');
plot([tnRFP2(2) tnRFP2(2)],[0 2],'r-');
xlim([0,tmax]);
xlabel('time (h)');
title('# segmented cells from RFP vs time');
ylabel('#cells');
hold off;

subplot(nPlotRows,nPlotCols,4);
plot(unique_t,nCellsMedianRFP,'b');
hold on;
xlim([0,tmax]);
xlabel('time (h)');
title('median filtered # segmented cells from RFP vs time');
ylabel('#cells');

% 6. Fl vs time for RFP
subplot(nPlotRows,nPlotCols,6);
hold on;
plot(tRFP,yRFP,'m.');
plot(tRFPCutoff,yRFPCutoff,'r.');
if(~isempty(p3))
    ydata_global = yRFP; % keeps func plot happy
    x3 = paramstovec(p3);
    y3 = func(x3,tRFP);
    hold on;
    tIndex = tRFP>=p3.x1 & tRFP<=p3.x4;
    plot(tRFP(tIndex),y3(tIndex),'k');
    plot([p3.x1 p3.x4],[0 0],'k*');
    hold off;
end

xlim([0,tmax]);
if(~isempty(yRFPCutoff) && max(yRFPCutoff)>0)
    ylim([0,max(yRFPCutoff)]);
end
xlabel('time (h)');
ylabel(yNameRFP);
title(sprintf('%s versus time',yNameRFP));

% % 7. time vs frame
% subplot(nPlots,1,7);
% hold on;
% plot(1:(length(unique_t)),unique_t);
% xlim([0,length(unique_t)]);
% ylim([0,tmax]);
% xlabel('frame');
% ylabel('time (h)');
% title(sprintf('%s versus time',yNameRFP));

% f = getframe(h);
% close(h) 
% [im,map] = frame2im(f);    %Return associated image data 
% imwrite(im,plotFile);


print(h, '-dpng', plotFile, '-r 600');
% print(h, '-dtiff', strrep(plotFile,'.png','.tiff'), '-r 300');
close(h) 




