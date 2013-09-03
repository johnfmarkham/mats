function tiffsWrite(positionDetails,files,img16)
% Write out these tiffs for later use
debug = 1;
channels = length(files);
for i=1:channels
    % CellProfiler calls them tiff, not tif so I do too
    posDir = getDir(positionDetails,'tiffs');
    name = strcat(posDir,files{i}.name);
    if(debug)
        log_fprintf(positionDetails,'Writing %s\n',name);
    end
    imwrite(img16(:,:,i),name,'tiff','Compression','packbits');
end



