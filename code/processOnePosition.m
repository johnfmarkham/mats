%{
% A position is a field of view.
%}
function processOnePosition(experimentDetails, dirList, i)

% assume everything gets passed on
% Stop everything being synchronised
if(experimentDetails.haveWorkerPool)
	pause(mod(i,8));
end
logfile_name = strcat(getDir(experimentDetails,'log'),'logfile.csv');
logfile_fd(i) = fopen(logfile_name,'a');
positionDetails = experimentDetails;
positionDetails.cellDetails = [];
diritem = dirList(i);
if(diritem.isdir && diritem.name(1)~='.')
	for j=1:experimentDetails.tiles
		% and in addition there is some stuff which is different
		positionDetails.dir = diritem.name;
		% Convert dir name into pattern for file matching
		positionDetails.positionName = diritem.name;
		positionDetails.positionNum = i;
		if(experimentDetails.tiles==1)
			positionDetails.baseName = regexprep(diritem.name, '.tif_Files', '');
			positionDetails.pattern = regexprep(diritem.name, '.tif_Files', experimentDetails.pattern);
		else
			pos_prefix = sprintf('_p%06d',j);
			positionDetails.baseName = regexprep(diritem.name, '.tif_Files', pos_prefix);
			pattern = strcat(pos_prefix,'t%08dz001c%02d.tif');
			positionDetails.pattern = regexprep(diritem.name, '.tif_Files', pattern);
		end
		positionDetails.dir = strcat(experimentDetails.dir,diritem.name,'/'); % full path of position
		positionDetails.positionDir = strcat(diritem.name,'/'); % path of position relative to experiment
		positionDetails.experimentDir = experimentDetails.dir;
		logfile_name = makeFileName(positionDetails,'log');
		positionDetails.logfile_fd = fopen(logfile_name,'a');
		if(positionDetails.logfile_fd<0)
			fprintf(1,'Unable to open logfile: %s\n',logfile_name);
			break;
		end
		
		% list using the all channel numbers. hopefully this avoids the
		% problem caused by axiovision quitting mid position
		channelNumbers = experimentDetails.channelNumbers;
		numChannels = length(channelNumbers);
		timePoints = zeros(numChannels,1);
		for k=1:numChannels
			timePointPattern = sprintf('%s*%d.tif',positionDetails.dir, channelNumbers(k));
			fileList = dir(timePointPattern);
			timePoints(k) = length(fileList);
		end
		positionDetails.timePoints = min(timePoints);
		if(experimentDetails.makeFrameOffsets)
			log_fprintf(logfile_fd(i), 'position2frameoffsets() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2frameoffsets(positionDetails);
		end
		if(experimentDetails.findFrameTimes)
			log_fprintf(logfile_fd(i), 'position2frametimes() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2frametimes(positionDetails);
		end
		if(experimentDetails.makeBackgrounds)
			log_fprintf(logfile_fd(i), 'position2backgrounds() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2backgrounds(positionDetails);
		end
		if(experimentDetails.makeBackgroundMasks)
			log_fprintf(logfile_fd(i), 'position2backgroundmasks() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2backgroundmasks(positionDetails);
		end
		% Optionally write out corrected tiffs for use elsewhere
		if(experimentDetails.makeCorrectedTiffs)
			log_fprintf(logfile_fd(i), 'position2tiffs() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2tiffs(positionDetails);
		end
		% Segmenting comes after the other stuff
		if(experimentDetails.makeSegmentedTiffs)
			log_fprintf(logfile_fd(i), 'position2segmentation() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2segmentation(positionDetails);
		end
		if(experimentDetails.makeAvi)
			log_fprintf(logfile_fd(i), 'position2avi() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2avi(positionDetails);
		end
		if(experimentDetails.findWellEdges)
			log_fprintf(logfile_fd(i), 'position2welledges() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2welledges(positionDetails)
		end
		if(experimentDetails.makeSplitWells)
			position2welltiffs(positionDetails,experimentDetails);
		end
		if(experimentDetails.makeAvs)
			log_fprintf(logfile_fd(i), 'position2avs() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2avs(positionDetails);
		end
		if(experimentDetails.measureWells)
			log_fprintf(logfile_fd(i), 'position2wellmeasurements() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			position2wellmeasurements(positionDetails);
		end
		if(experimentDetails.measureCells)
			log_fprintf(logfile_fd(i), 'position2cellmeasurements() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			positionDetails = position2cellmeasurements(positionDetails);
		end
		if(experimentDetails.measureCellNumbers)
			log_fprintf(logfile_fd(i), 'position2cellnumbers() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			positionDetails = position2cellnumbers(positionDetails);
		end
		if(experimentDetails.makeFucciFits)
			log_fprintf(logfile_fd(i), 'position2fuccifitavs() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			positionDetails = position2fuccifitavs(positionDetails);
		end
		if(experimentDetails.makePlots)
			log_fprintf(logfile_fd(i), 'position2plots() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			positionDetails = position2plots(positionDetails);
		end
		if(experimentDetails.makePixelPlots)
			log_fprintf(logfile_fd(i), 'position2pixelplots() %d timePoints from %s\n',positionDetails.timePoints,positionDetails.dir);
			positionDetails = position2pixelplots(positionDetails);
		end
		fclose(logfile_fd(i));
	end % for tiles
end % if a dir

end