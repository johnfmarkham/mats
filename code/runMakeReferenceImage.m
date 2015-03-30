function runMakeReferenceImage()
ctx.dir = fullfile('..', '..', 'uneven');
ctx.maxPixel = 2^15;
ctx.dc_offset = 32;
ctx.doNormalisation = 1;

tryIters = [1, 10];
channels = [1,2];
for numIters = tryIters
    ctx.smoothing_iterations = numIters;
    for idxChan = channels
        ctx.dirPattern = sprintf('*c%02d.tif', idxChan);
        ctx.outfile = sprintf('smoothed_%d_%d.tif', numIters, idxChan);
        im = globReferenceImages(ctx);
        if(~isempty(im))
            imwrite(im,strcat(ctx.dir,ctx.outfile),'tif','Compression','none');
        end
    end
end