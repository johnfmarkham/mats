function position2avi(positionDetails)
% Convert files from one well position, possibly in multiple dir's to a movie
dir = positionDetails.dir; % where the files come from
baseName = strcat(positionDetails.outputDir,positionDetails.aviavsDir,positionDetails.baseName);
pattern = positionDetails.pattern;
if(positionDetails.useMasks)
    masksDir = getDir(positionDetails,'masks');
end

timePoints = min(positionDetails.timePoints,positionDetails.timePointsLimit);
channels = positionDetails.channels;
channelNumbers = positionDetails.channelNumbers;
rgb = positionDetails.rgb;
firstTimePoint = positionDetails.firstTimePoint;

if(positionDetails.doBackgroundCorrection )
    frameOffsets = readFrameOffsets(positionDetails);
    [backGroundCorrection,backGroundCorrectionSorted] = readBackGroundCorrectionImages(positionDetails);
else
    fo.x = 0;
    fo.y = 0;
    frameOffsets = repmat(fo,timePoints,channels);
    backGroundCorrection = [];
    backGroundCorrectionSorted = [];
end


log_fprintf(positionDetails,'Processing images from %s\n',dir);

mapfile = makeFileName(positionDetails,'map');
fid = fopen(mapfile,'w');
for i=1:channels
    fprintf(fid,'%s_low,%s_med,%s_high,',positionDetails.labels{i});
end
fprintf(fid,'elapsedTime\n');
fclose(fid);
% Write headers for stats files
% Headers for hists and stats on fluorescent intensities
writeHistsStatsHeaders(positionDetails);

font = imread(positionDetails.fontFile);
% Do brightness correction
if(positionDetails.filenameIncrementsTime)
    filename_bf = sprintf(positionDetails.pattern,firstTimePoint,channelNumbers(positionDetails.wellDetectionChannel));
else
    filename_bf = sprintf(positionDetails.pattern,channelNumbers(positionDetails.wellDetectionChannel));
end
filename_bf = strcat(positionDetails.dir,filename_bf);
img_bf = uint16(imread(filename_bf));
% No need to find wells if correction is done using a pre-made image
if(positionDetails.doBrightnessCorrection==1)
    wellsFile = makeFileName(positionDetails,'welledges');
    s = readHeaderedFile(wellsFile,1,positionDetails);    
else             % img,autoFind,separation,overlap
    s = [];
end
[unevenIlluminationCorrection,unevenIlluminationCorrectionSorted] = makeAllReferenceImages(positionDetails,s);
pixels = size(img_bf,1) * size(img_bf,2);
% Pre-calculating these saves time later
codec = 'ffds';
codec = 'indeo5';
codec = 'MSVC'; % using none because everything has it
codec = 'None'; % using none because everything has it
combo_outfile = makeFileName(positionDetails,'avi');
if(positionDetails.noClobber && fileExists(combo_outfile))
    log_fprintf(positionDetails,'movie file %s exists. Skipping this position.\n',combo_outfile);
    return;
end
%aviobj = avifile(combo_outfile,'compression','MSVC','quality',100);
aviobj = VideoWriter(combo_outfile);
aviobj.Quality = 100;
open(aviobj);
try
    for j=1:channels
        channel_outfile{j} = makeFileName(positionDetails,'avi',j);
        % aviobjs{j} = avifile(channel_outfile{j},'compression',codec,'quality',100);
        aviobjs{j} = VideoWriter(channel_outfile{j});
        aviobjs{j}.Quality = 100;
        open(aviobjs{j});
    end
    %dir = strcat(dir,baseName,'/');
    for i=firstTimePoint:timePoints
        for j=1:channels
            offsets{j}.x = frameOffsets(i,j).x;
            offsets{j}.y = frameOffsets(i,j).y;
            if(positionDetails.filenameIncrementsTime)
                filename = sprintf(pattern,i,channelNumbers(j));
            else
                filename = sprintf(pattern,channelNumbers(j));
            end
            files{j}.name = strcat(dir,filename);
            files{j}.rgb = rgb{j};
            if(positionDetails.useMasks)
                files{j}.mask = strcat(masksDir,filename);
            end
        end
        % Feed historical frames to tiffs2frames.
        [frame, frames] = tiffs2frame(positionDetails,files,unevenIlluminationCorrection,unevenIlluminationCorrectionSorted,backGroundCorrection,backGroundCorrectionSorted,offsets);
        % Write some text on the top of the overlaid frame
        frame.cdata = labelImage(frame.cdata,files{1}.name,positionDetails.scaleBarPixels,positionDetails.scaleBarMicrons,font);
        % aviobj = addframe(aviobj,frame);
        writeVideo(aviobj,frame);
        for j=1:channels
            % aviobjs{j} = addframe(aviobjs{j},frames{j});
            writeVideo(aviobjs{j},frames{j});
        end
    end
catch ME
    if(~isempty(aviobj))
        % aviobj = close(aviobj);
        close(aviobj);
        for j=1:channels
            if(~isempty(aviobjs{j}))
                % aviobjs{j} = close(aviobjs{j});
                close(aviobjs{j});
            end
        end
    end
    throw(ME);
end
% aviobj = close(aviobj);
close(aviobj);
for j=1:channels
    % aviobjs{j} = close(aviobjs{j});
    close(aviobjs{j});
end
% At this point we have giant avi files which need converting to something
% smaller
% rows = size(frame.cdata,1);
% cols = size(frame.cdata,2);
% outfiles = channel_outfile;
% outfiles{end+1} = combo_outfile;
% for i=1:length(outfiles)
%     % compressavi(outfiles{i},rows,cols);
% end

% Make avis out of all avs's
% Compress all avis into something smaller
perl_location = 'c:/Perl/bin/perl';
perl_location = 'C:/downloads/Perl64/bin/perl';
perl_location = 'c:/Perl64/bin/perl';
%system_command = sprintf('% convertavis.pl',perl_location);
%system_command = strcat(perl_location,' convertavis.pl',' ',baseName);
system_command = sprintf('%s convertavis.pl %s',perl_location,baseName);

%[status, result] = system(system_command);
%log_fprintf(positionDetails,'Results = %s\nStatus = %s\n',result,status);
