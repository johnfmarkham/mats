function position2avs(positionDetails)
% makes avs file that arranges images nicely

baseNameAvs = strcat(positionDetails.outputDir,positionDetails.baseName);
dir = positionDetails.dir;
baseName = positionDetails.baseName;
pattern = positionDetails.pattern; 
timePoints = positionDetails.timePoints; 
channels = positionDetails.channels; 
channelNumbers = positionDetails.channelNumbers;
rgb = positionDetails.rgb;
stackLength = length(positionDetails.stack);
stackOrder = positionDetails.stack;
labels = positionDetails.labels;
firstTimePoint = positionDetails.firstTimePoint ;

log_fprintf(positionDetails,'Processing images from %s\n',dir);
outfile = makeFileName(positionDetails,'avs');
avi = makeFileName(positionDetails,'avi');
% makeFileName(positionDetails,'avi')
for j=1:channels
    avis{j} = sprintf('%s_%d%s',baseName,j,'.avi');
end

% a=AVISource("20090213_blimp_gfp-0040_Position(1).avi")
% b=AVISource("20090213_blimp_gfp-0040_Position(1)_3.avi")
% c=AVISource("20090213_blimp_gfp-0040_Position(1)_2.avi")
% 
% # d=c.ConvertToYUY2.SpatialSoften(4, 0, 0)
% 
% StackHorizontal(StackHorizontal(a, c),b)

% Makes avs to put channels side-by-side
fd = fopen(outfile,'w');
varname = 'movie0';
fprintf(fd,'%s=AVISource("%s").',varname,avi);
fprintf(fd,'Subtitle("%s", font="georgia", size=24, text_color=$FFFFFF, align=9)\n',baseName);

for j=1:stackLength
    varname = sprintf('movie%d',j);
    channel = stackOrder{j};
    channelText = labels{channel};
    rgb_channel = rgb{channel};
    channelColour = sprintf('%02X%02X%02X',rgb_channel(1)*255,rgb_channel(2)*255,rgb_channel(3)*255);
    fprintf(fd,'%s=AVISource("%s").',varname,avis{channel});
    fprintf(fd,'Subtitle("%s", font="georgia", size=24, text_color=$%s, align=9)\n',channelText,channelColour);
end
if(stackLength==1)
    fprintf(fd,'StackHorizontal(movie0,movie1)\n');
elseif(stackLength==2)
    fprintf(fd,'StackHorizontal(StackHorizontal(movie0, movie1),movie2)\n');
elseif(stackLength==3)
    fprintf(fd,'StackHorizontal(StackHorizontal(movie0, movie1),StackHorizontal(movie2, movie3))\n');
elseif(stackLength==4)
    fprintf(fd,'StackHorizontal(StackHorizontal(movie0, movie1),StackHorizontal(movie2, StackHorizontal(movie3,movie4)))\n');
elseif(stackLength==5)
    fprintf(fd,'StackHorizontal(StackHorizontal(movie0, movie1),StackHorizontal(StackHorizontal(movie2, movie3), StackHorizontal(movie4,movie5)))\n');
end
fclose(fd);
% Do the same but for microwells
wellsFile = makeFileName(positionDetails,'welledges');
s = readHeaderedFile(wellsFile,1,positionDetails);    
position2wellavs(positionDetails,s);


