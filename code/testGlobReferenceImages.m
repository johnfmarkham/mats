function testGlobReferenceImages()

experimentDetails.maxPixel = 2^15;

experimentDetails.smoothing_iterations = 10;
experimentDetails.dc_offset = 32;
experimentDetails.doNormalisation = 1;

experimentDetails.dir = 'd:\tmp\uneven_illumination_correction\';
experimentDetails.blackImage = '..\uneven_illumination_correction\axiocam_no_light.tif';

% for i=1:3
%     experimentDetails.dirPattern = sprintf('20111118-0001_Position(*)_p000001t000000*z001c0%d.tif',i);
%     experimentDetails.outfile = sprintf('smoothed_lsm_%d.tif',i);
%     im = globReferenceImages(experimentDetails);
%     imwrite(im,experimentDetails.outfile,'tif','Compression','none');
% end

experimentDetails.dir = 'd:\tmp\uneven_illumination_correction\';
for j = [10 100 200 500]
    experimentDetails.smoothing_iterations = j;
    for i=1:3
        experimentDetails.dirPattern = sprintf('2013*c%02d.tif',i);
        experimentDetails.outfile = sprintf('20130816_smoothed_%d_%d.tif',j,i);
        im = globReferenceImages(experimentDetails);
        if(~isempty(im))
            imwrite(im,strcat(experimentDetails.dir,experimentDetails.outfile),'tif','Compression','none');
        end
    end
end

% experimentDetails.smoothing_iterations = 10000;
% for i=[1 3]
%     experimentDetails.dirPattern = sprintf('20130111-0010_Position*c0%d.tif',i);
%     experimentDetails.outfile = sprintf('smoothed_10000_%d.tif',i);
%     im = globReferenceImages(experimentDetails);
%     imwrite(im,strcat(experimentDetails.dir,experimentDetails.outfile),'tif','Compression','none');
% end

% copyfile('smoothed_02.tif','smoothed_03.tif');
