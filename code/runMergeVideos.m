% this is a temporary solution
% this concatenates different runs
% for the same position into a single movie
clear vars; close all; clc;
inPath = 'D:\experiments\20130823_Blimp_B_drugs\unthresholded\';
ffmpeg = 'C:\ffmpeg-20130520-git-5a65fea-win64-static\bin\ffmpeg.exe';

nThreads = 8;
refRun = '20130823-0023'; % takes well edges from here

aviSuffix = {'', '_1', '_2', '_3'};
nSuff = numel(aviSuffix);

listing = dir(fullfile(inPath, sprintf('%s*).avi', refRun)));
%listing = prunePositionsList(listing, [1:10, 65:75, 129:139, 193:203]);
%listing = prunePositionsList(listing, [11:64, 76:100]);
positions = [101:128, 140:192, 204:500];
listing = prunePositionsList(listing, positions);

n = numel(listing);

matlabpool('open', nThreads);
parfor i = 1:n
	try
		currName = listing(i).name;
		fprintf('%s\n', currName);
		k = strfind(currName, '(');
		pos = currName((k + 1):(end - 5));
		
		listAvs = dir(fullfile(inPath, sprintf('%s*(%s)*.avs', refRun, pos)));
		nAvs = numel(listAvs);
		for iAvs = 1:nAvs
			curAvs = listAvs(iAvs).name;
			newAvs = curAvs(15:end);
			f1 = fopen(fullfile(inPath, curAvs), 'rt');
			f2 = fopen(fullfile(inPath, newAvs), 'wt');
			
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
		
		for iSuff = 1:nSuff
			suff = aviSuffix{iSuff};
			outFile = fullfile(inPath, sprintf('%s%s.avi', pos, suff));
			if (exist(outFile, 'file') == 2)
				fprintf('movie exists, skipping iteration\n');
				continue
			end
			
			listFile = fullfile(inPath, sprintf('%s%s-list.txt', pos, suff));
			
			subListing = dir( ...
				fullfile(inPath, sprintf('20130823*(%s)%s.avi', pos, suff)));
			nSub = numel(subListing);
			
			fid = fopen(listFile, 'wt');
			for j = 1:nSub
				fprintf(fid, 'file ''%s''\n', ...
					fullfile(inPath, subListing(j).name));
			end
			fclose(fid);
			
			command = sprintf('%s -f concat -i %s -c copy %s -y', ...
				ffmpeg, listFile, outFile);
			dos(command);
		end
	catch err
		fprintf('%s\n', err.message);
	end
end
matlabpool('close');