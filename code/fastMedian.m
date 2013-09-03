function m = fastMedian(im)
% Find median of im using a tabulated method rather than sorting
dims = length(size(im));
tableLength = 2^16 + 1;
imHist = zeros(1,tableLength);
rows = size(im,1);
if (dims==1)
    p = im+1; % 1 offset to prevent zero index
    imHist(p) = imHist(p) + 1;
else
    for i=1:rows
        p = im(i,:)+1; % 1 offset to prevent zero index
        imHist(p) = imHist(p) + 1;
    end
end
s = sum(imHist);
cs = cumsum(imHist);
m = find(cs>=(s/2),1,'first')-1;
    