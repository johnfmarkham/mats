function writeHistsStatsHeaders(positionDetails)
% Write headers for stats files
% Headers for hists and stats on fluorescent intensities
useMasks = positionDetails.useMasks;
channels = positionDetails.channels;

if(useMasks)
    last_j = 2;
else
    last_j = 0;
end
for i=1:channels
    for j=0:last_j
        histsfile = makeFileName(positionDetails,'hists',i,j);
        statsfile = makeFileName(positionDetails,'stats',i,j);
        if(positionDetails.noClobber && fileExists(histsfile))
            log_fprintf(positionDetails,'The hists file %s already exists. Skipping.\n',histsfile);
            continue;
        end
        if(positionDetails.noClobber && fileExists(statsfile))
            log_fprintf(positionDetails,'The stats file %s already exists. Skipping.\n',statsfile);
            continue;
        end
        fd = fopen(statsfile,'w');
        fprintf(fd,'min,median,max,mean,std\n');
        fclose(fd);
        fd = fopen(histsfile,'w');
        bins = 0:4:(2^12);
        fprintf(fd,'b%04d,',bins);
        fprintf(fd,'\n');
        fclose(fd);
    end
end    
