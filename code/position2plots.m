function positionDetails = position2plots(positionDetails)
% Plot fluorescence versus time for microwells and make avs files for
% display with previously made avis.

stackLength = length(positionDetails.stack);
stackOrder = positionDetails.stack;

recordsFile = makeFileName(positionDetails,'cell');
try
    r = readHeaderedFile(recordsFile,1,positionDetails);    
    if(positionDetails.insertRealTimes)
        timesFile  = makeFileName(positionDetails,'frametimes');
        timesTable = readHeaderedFile(timesFile,1,positionDetails);  
        % timesTable = readMultiTimes(positionDetails);
        if(isempty(timesTable))
            log_fprintf(positionDetails,'Unable to read frame times\n');
            return;
        end
        r = incororporateTimesTable(r,timesTable);
    end
    
catch err
    log_fprintf(positionDetails,'readHeaderedFile() broke with this message: %s\nUnable to do plots. Something wrong with %s\n',err.message,recordsFile);
    % TODO: Put this handling in everything in a systematic manner.
    % Arguably by rethrowing this and catching all things in
    % processPositions...
    return;
end
scaled = 0; % plot fluorescence values, not the proportion of maximum
if(isempty(r))
    log_fprintf(positionDetails,'Measurements file %s is missing or empty.\n',recordsFile);
    return;
end

% Read wells in and loop over them
wellsFile = makeFileName(positionDetails,'welledges');
s = readHeaderedFile(wellsFile,1,positionDetails);    
if(isempty(s))
    log_fprintf(positionDetails,'Wells file %s is missing or empty.\n',wellsFile);
    return;
end
n_wells = length(s);
for i=1:n_wells
    row =s(i).row;
    col =s(i).col;
    left = s(i).tlx;
    top = s(i).tly;
    width = s(i).brx - s(i).tlx;
    height = s(i).bry - s(i).tly;
    top = floor(top/2) * 2; % makes it easier to encode (think that's what it is)
    left = floor(left/2) * 2;
    height = floor(height/8) * 8;
    width = floor(width/8) * 8;
    % Make avi file
    outfileavi = makeFileName(positionDetails,'avi');
    outextavi = sprintf('_plot_%c_%d%s',row,col,'.avi');
    outfileavi = strrep(outfileavi,'.avi',outextavi);
    outfilejpg = strrep(outfileavi,'.avi','.jpg');
    outfileavi_no_path = outfileavi((1+find(outfileavi=='/',1,'last')):end);
    
    if(positionDetails.noClobber && fileExists(outfileavi))
        log_fprintf(positionDetails,'The plot file %s already exists. Skipping.\n',outfileavi);
        continue;
    else
        log_fprintf(positionDetails,'Making plot %s.\n',outfileavi);
    end    
    % positionDetails.cellDetails = readCellDetails(s(i).file);
    try
        plotFluorescenceTimeSeries(positionDetails,r,row,col,scaled,outfileavi,outfilejpg);
    catch err
        log_fprintf(positionDetails,'plotFluorescenceTimeSeries() broke with this message: %s\nUnable to do plots. Something wrong with %s?\n',err.message,recordsFile);
        return;
    end
    % TODO: Optional avi/avs?
    % Make avs file to work with other avs files
    outfileavs = makeFileName(positionDetails,'avs');
    outextavs = sprintf('_plot_%c_%d%s',row,col,'.avs');
    outfileavs = strrep(outfileavs,'.avs',outextavs);
    fd = fopen(outfileavs,'w');
    fprintf(fd,'bg=colorbars(1152,900).converttoyuy2()\n');
    fprintf(fd,'bg=blankclip(bg)\n');
    fprintf(fd,'plot=AVISource("%s")\n',outfileavi_no_path);
    for j=1:stackLength
        varname = sprintf('movie%d',j);
        channel = stackOrder{j};
        channelText = positionDetails.labels{channel};
        rgb_channel = positionDetails.rgb{channel};
        avi_channel = makeFileName(positionDetails,'avi',channel);
        avi_channel_no_path = avi_channel((1+find(avi_channel=='/',1,'last')):end);
        channelColour = sprintf('%02X%02X%02X',rgb_channel(1)*255,rgb_channel(2)*255,rgb_channel(3)*255);
        fprintf(fd,'%s=AVISource("%s")',varname,avi_channel_no_path);
        fprintf(fd,'.Crop(%d,%d,%d,%d)',left,top,width,height);
        fprintf(fd,'.Subtitle("%s", font="georgia", size=24, text_color=$%s, align=9)\n',channelText,channelColour);
    end
    fprintf(fd,'\nbg');
    xoff = 0;
    yoff = 0;
    for j=1:stackLength
        fprintf(fd,'.Overlay(movie%d,%d,%d)',j,xoff,yoff);
        xoff = xoff + width;
    end
    yoff = height;
    xoff = 1;
    fprintf(fd,'.Overlay(plot,%d,%d)\n',xoff,yoff);
    fclose(fd);
end
% Something like this:
%
% bg = colorbars(1152,700).converttoyuy2()
% bg = blankclip(bg)
% 
% plot = AVISource("E:\jfm\work\fucci\exports_parallel\position_09_c1.avi")
% movie0=AVISource("..\20111118-0026_Position(9)_3.avi").Crop(0,550,320,368).Subtitle("BF", font="georgia", size=24,  text_color=$FFFFFF, align=9)
% movie1=AVISource("..\20111118-0026_Position(9)_1.avi").Crop(0,550,320,368).Subtitle("GFP", font="georgia", size=24, text_color=$00FF00, align=9)
% movie2=AVISource("..\20111118-0026_Position(9)_2.avi").Crop(0,550,320,368).Subtitle("RFP", font="georgia", size=24, text_color=$FF0000, align=9)
% bg.Overlay(movie0).Overlay(movie1,380,0).Overlay(movie2,760,0).Overlay(plot,1,260)
% 

