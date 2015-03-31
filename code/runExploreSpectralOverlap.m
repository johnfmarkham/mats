function runExploreSpectralOverlap()
clear variables; close all; clc;
inPath = fullfile('..', '..', '..');
runPatt = '*-%04d';
posPatt = '*%d*.tif_Files';
ch1Patt = '*%dz*c01.tif';
ch2Patt = '*%dz*c02.tif';

allRun = [9 9     11 11   13 13   13 13  13 13    13 13    13 13];
allFrm = [1 1     5 5     5 5     50 50  100 100  150 150  230 230];
allPos = [36 184  257 54  78 229  113 3  60 144   192 57   3 119];
numCases = numel(allRun);

ctx.thLo = 10;
ctx.thHi = 90;
ctx.xBins = 100;
ctx.sampleSize = 20000;
ctx.outPath = fullfile('..', '..', 'unmixing');

for iCase = 1:numCases
	fprintf('--- case %d out of %d ---\n', iCase, numCases);
	
	pos = allPos(iCase);
	run = allRun(iCase);
	frm = allFrm(iCase);
	
	runDir = dir(fullfile(inPath, sprintf(runPatt, run)));
	runDir = runDir(1).name;
	
	posDir = dir(fullfile(inPath, runDir, sprintf(posPatt, pos)));
	posDir = posDir(1).name;
	
	nameChan1 = dir(fullfile(inPath, runDir, posDir, sprintf(ch1Patt, frm)));
	nameChan1 = nameChan1(1).name;
	nameChan2 = dir(fullfile(inPath, runDir, posDir, sprintf(ch2Patt, frm)));
	nameChan2 = nameChan2(1).name;
	
	im1 = double( imread(fullfile(inPath, runDir, posDir, nameChan1)) );
	im2 = double( imread(fullfile(inPath, runDir, posDir, nameChan2)) );
	
	ctx.name = sprintf('pos = %d, [run, frm] = [%d, %d]', pos, run, frm);
	processCase(ctx, im1, im2)
end

%{
experimentDetails.channel11

debug = 1;

im11 = imread(experimentDetails.channel11);
im12 = imread(experimentDetails.channel12);
im21 = imread(experimentDetails.channel21);
im22 = imread(experimentDetails.channel22);

pixels = size(im11,1) * size(im11,2);
m11 = reshape(im11,pixels,1);
m12 = reshape(im12,pixels,1);
m21 = reshape(im21,pixels,1);
m22 = reshape(im22,pixels,1);

m11 = m11 - experimentDetails.blackValue;
m12 = m12 - experimentDetails.blackValue;
m21 = m21 - experimentDetails.blackValue;
m22 = m22 - experimentDetails.blackValue;

m21 = m21(m11>experimentDetails.lb1);
m11 = m11(m11>experimentDetails.lb1);

m12 = m12(m22>experimentDetails.lb2);
m22 = m22(m22>experimentDetails.lb2);

% figure(2);
% hist(double(m21));
% figure(3);
% hist(double(m12));

p1 = polyfit(double(m11),double(m21),1);
p2 = polyfit(double(m22),double(m12),1);
%  An optimisation procedure to do the same job as polyfit
%       x and y axes
% options = optimset('MaxFunEvals', 1000, 'TolFun', 1e-15, 'Display', 'final', 'LargeScale', 'off');
% init = [-p1(1),-p2(1)];
% ub = [0 0];
% lb = [-100 -100];
% [minvec, minval, exitflag] = fmincon(@cost,init,[],[], [],[],lb,ub,[],options,m11,m12,m21,m22);
if(debug)
    figure;
    hold on;
    x = 0:double(max(m11));
    y = polyval(p1,x);
    plot(m11,m21,'.g');
    plot(x,y,'k');
    x = 0:double(max(m22));
    y = polyval(p2,x);
    plot(m12,m22,'.r');
    plot(y,x,'k');
    xlim([0 200]);
    ylim([0 500]);
    hold off;
end

fid = fopen(experimentDetails.outfile,'w');
fprintf(fid,'%f %f\n',p1(1),p2(1));
%fprintf(fid,'%f %f\n',-minvec(1),-minvec(2));
fclose(fid);
%}
end

function processCase(ctx, im1, im2)
reset(RandStream.getGlobalStream, 2015);

% figure; imshow(mat2gray(im1));
% figure; imshow(mat2gray(im2));

xvec = im1(:);
yvec = im2(:);
thLo1 = prctile(xvec, ctx.thLo);
thLo2 = prctile(yvec, ctx.thLo);
thHi1 = prctile(xvec, ctx.thHi);
thHi2 = prctile(yvec, ctx.thHi);

sel = (xvec < thLo1) | (yvec < thLo2) | (xvec > thHi1) | (yvec > thHi2);
xvec = xvec(sel);
yvec = yvec(sel);

xvec = randsample(xvec, ctx.sampleSize);
yvec = randsample(yvec, ctx.sampleSize);

figure('name', ctx.name, 'position', [400, 400, 1200, 400]);
subplot(1, 2, 1);
densityPlot2D(xvec, yvec, [ctx.xBins, ctx.xBins])

subplot(1, 2, 2);
scatter(xvec, yvec);

set(gcf, 'PaperPosition', [0 0 30 10]);
set(gcf, 'PaperSize', [30 10]);
saveas(gcf, fullfile(ctx.outPath, ctx.name), 'pdf');
end

function densityPlot2D(xvec, yvec, nbins)
xvec = xvec(:);
yvec = yvec(:);

if (nargin < 3)
	nbins = [51, 51];
end
values = hist3([xvec, yvec], 'nbins', nbins);
values = log(values + 0.0001);

imagesc(values');
colorbar;
axis xy;
end

%{
function result = cost(v,m11,m12,m21,m22)
mix_12 = v(2);
mix_21 = v(1);
s11 = double(m11) + mix_12 * double(m21);
s21 = double(m21) + mix_21 * double(m11);

s12 = double(m12) + mix_12 * double(m22);
s22 = double(m22) + mix_21 * double(m12);

p1 = polyfit(double(s11),double(s21),1);
p2 = polyfit(double(s22),double(s12),1);

%result = std(s21) +  std(s12);
result = abs(p1(1)) + abs(p2(1));
fprintf(1,'%f %f %f %f %f\n',result,v(1),v(2),p1(1),p2(1));
end
%}