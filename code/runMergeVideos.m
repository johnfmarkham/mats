% concatenate different runs for the same position into a single movie
function runMergeVideos
clear vars; close all; clc; fclose all;
ctx.expName = '20150306';
ctx.refRun = [ctx.expName, '-0013']; % takes well edges from here
ctx.posList = 1:999;

ctx.nThreads = 8;
ctx.ffmpeg = 'C:\ffmpeg-20130520-git-5a65fea-win64-static\bin\ffmpeg.exe';

ctx.inPath = 'Z:\processing\output\thresholded\';
processInput(ctx)

ctx.inPath = 'Z:\processing\output\unthresholded\';
processInput(ctx)
end

function processInput(ctx)
ctx.aviSuffix = {'', '_1', '_2', '_3'};
ctx.nSuff = numel(ctx.aviSuffix);

listing = dir(fullfile(ctx.inPath, sprintf('%s*).avi', ctx.refRun)));
listing = prunePositionsList(listing, ctx.posList);

n = numel(listing);
if (n <= 3)
	for i = 1:n
		currName = listing(i).name;
		processPosition(currName, ctx);
	end
else
	matlabpool('open', ctx.nThreads);
	parfor i = 1:n
		currName = listing(i).name;
		processPosition(currName, ctx);
	end
	matlabpool('close');
end
fclose all;
end

function processPosition(currName, ctx)
try
	fprintf('%s\n', currName);
	k = strfind(currName, '(');
	pos = currName((k + 1):(end - 5));
	
	listAvs = dir(fullfile( ...
		ctx.inPath, sprintf('%s*(%s)*.avs', ctx.refRun, pos)));
	nAvs = numel(listAvs);
	for iAvs = 1:nAvs
		curAvs = listAvs(iAvs).name;
		newAvs = curAvs(15:end);
		f1 = fopen(fullfile(ctx.inPath, curAvs), 'rt');
		f2 = fopen(fullfile(ctx.inPath, newAvs), 'wt');
		
		line1 = fgetl(f1);
		line2 = fgetl(f1);
		line3 = fgetl(f1);
		line4 = fgetl(f1);
		line5 = fgetl(f1);
		
		k = strfind(line1, '").');
		s1 = line1(k(1):end);
		k = strfind(line2, '").');
		s2 = line2(k(1):end);
		k = strfind(line3, '").');
		s3 = line3(k(1):end);
		k = strfind(line4, '").');
		s4 = line4(k(1):end);
		
		line1 = ['movie0=AVISource("', pos, '.avi', s1];
		line2 = ['movie1=AVISource("', pos, '_1.avi', s2];
		line3 = ['movie2=AVISource("', pos, '_2.avi', s3];
		line4 = ['movie3=AVISource("', pos, '_3.avi', s4];
		
		fprintf(f2, '%s\n', line1);
		fprintf(f2, '%s\n', line2);
		fprintf(f2, '%s\n', line3);
		fprintf(f2, '%s\n', line4);
		fprintf(f2, '%s\n', line5);
		
		fclose(f1);
		fclose(f2);
	end
	
	for iSuff = 1:ctx.nSuff
		suff = ctx.aviSuffix{iSuff};
		outFile = fullfile(ctx.inPath, sprintf('%s%s.avi', pos, suff));
		if (exist(outFile, 'file') == 2)
			fprintf('movie exists, skipping iteration\n');
			continue
		end
		
		listFile = fullfile(ctx.inPath, sprintf('%s%s-list.txt', pos, suff));
		
		subListing = dir( ...
			fullfile(ctx.inPath, sprintf('%s*(%s)%s.avi', ...
			ctx.expName, pos, suff)));
		nSub = numel(subListing);
		
		fid = fopen(listFile, 'wt');
		for j = 1:nSub
			fprintf(fid, 'file ''%s''\n', ...
				fullfile(ctx.inPath, subListing(j).name));
		end
		fclose(fid);
		
		command = sprintf('%s -f concat -i %s -c copy %s -y', ...
			ctx.ffmpeg, listFile, outFile);
		dos(command);
	end
catch err
	fprintf('%s\n', err.message);
end
end