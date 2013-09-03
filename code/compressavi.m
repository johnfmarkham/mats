function compressavi(filename,rows,cols)

compressor='ffmpeg\ffmpeg.exe';
tmpbase='tmpvideo';
tmpavi = strcat(tmpbase,'.avi');
tmpavs = strcat(tmpbase,'.avs');
fid = fopen(tmpavs,'w');
% Make the video a multiple of 16 so that VirtualDub doesn't complain
rightBorder = ceil(cols/16)*16 - cols;
bottomBorder = ceil(rows/16)*16 - rows;
fprintf(fid,'AVISource("%s").AddBorders(0,0,%d,%d)',tmpavi,rightBorder,bottomBorder);
fclose(fid);
movefile(filename,tmpavi,'f')
encode_command = sprintf('%s -i %s -y -an -vcodec mjpeg -b 50000k %s',...
    compressor,tmpavs,filename);
[status, result] = system(encode_command);
fprintf(1,'%s\nReturned %d\n',compressor,status);
fprintf(1,'%s\n',result);
delete(tmpavi);
delete(tmpavs);

