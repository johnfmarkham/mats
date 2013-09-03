function offsets = findOffsets(imlist,maxOffset,offsetInc)
% Finds shifts of subsequent images relative to first image that aligns
% them. Looks up until +/- maxOffset away.
% 

% haveGPU = 0;
% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end    
% haveGPU = 0;
boxRadiusx = maxOffset;
boxRadiusy = maxOffset;
% offsetInc = 0.5; % Can be 0.5 but I think there is some LPF in there
alignMentThreshold = 0.9;
offsetCoarse = 1;

im2 = double(imread(imlist{1}));
numOffsets = length(imlist);
rows = size(im2,1);
cols = size(im2,2);
pixels = rows*cols;
offsets =  repmat(struct('frame',0,'x',0,'y',0),1,numOffsets);
offsets(1).frame = 1; % First offset is zero
if(numOffsets==1)
    return;
end

% Put a black boundary around so that shifting and zero filling the other
% image doesn't impact on the
im2(1:maxOffset,:) = 0;
im2(:,cols-maxOffset-1:cols) = 0;
im2(:,1:maxOffset) = 0;
im2(rows-maxOffset-1:rows,:) = 0;
im2sort = sort(reshape(im2,pixels,1));
imlim = im2sort(pixels * alignMentThreshold);
im2(im2<imlim) = 0;
pixels2 = sum(sum(im2~=0));

p2 = rows * cols;
m2 = sum(sum(im2))/p2;
for k=2:numOffsets
    if(isempty(imlist{k}) || length(imlist{k})<2)
        continue;
    end
    fprintf(1,'Finding offset for %s\n',imlist{k});
    maxCorrelation = 0;
    imk = uint16(imread(imlist{k}));
    for i=-boxRadiusx:offsetCoarse:boxRadiusx
        for j=-boxRadiusy:offsetCoarse:boxRadiusy
            im1 = double(shiftImage(imk,i,j));
            mask = (im2~=0);
            m1 = sum(sum(im1(mask)))/pixels2;
            r = imageCorrelation(im1,im2,mask);
            % Things that didn't work
%             dp = sum(sum(im1.*im2));
%             dpn = dp/(pixels2 * m1 * m2);
%            dp = sum(sum((im1(mask).*im2(mask))./((im1(mask)+im2(mask)).*(im1(mask)+im2(mask)))));
%            dpn = dp/pixels2;
            if(r>maxCorrelation)
                offsets(k).frame = k;
                offsets(k).x = i;
                offsets(k).y = j;
                maxCorrelation = r;
                fprintf(1,'Coarse k = %d i=%4d j=%4d r=%10f m1=%10f m2=%10f\n',k,i,j,r,m1,m2);
            end
        end
    end
    if(offsetCoarse>offsetInc)
        coarse_x = offsets(k).x;
        coarse_y = offsets(k).y;
        for i=coarse_x-offsetInc:offsetInc:coarse_x+offsetInc
            for j=coarse_y-offsetInc:offsetInc:coarse_y+offsetInc
                im1 = double(shiftImage(imk,i,j));
                mask = (im2~=0);
                m1 = sum(sum(im1(mask)))/pixels2;
                r = imageCorrelation(im1,im2,mask);
                if(r>maxCorrelation)
                    offsets(k).frame = k;
                    offsets(k).x = i;
                    offsets(k).y = j;
                    maxCorrelation = r;
                end
                fprintf(1,'Fine   k = %d i=%4.1f j=%4.1f r=%10f m1=%10f m2=%10f\n',k,i,j,r,m1,m2);
            end
        end
    end
    fprintf(1,'*****  k = %d i=%4.1f j=%4.1f\n',k,offsets(k).x,offsets(k).y);
end
%------------------------------------------------------
function r = imageCorrelation(img1,img2,mask)
%------------------------------------------------------
im1 = double(img1(mask));
im2 = double(img2(mask));
im1d = im1-mean(mean(im1));
im2d = im2-mean(mean(im2));

r = sum(sum((im1d.*im2d))) / sqrt(sum(sum(im1d.*im1d))*sum(sum(im2d.*im2d)));



