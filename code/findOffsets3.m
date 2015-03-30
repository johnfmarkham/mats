function offsets = findOffsets3(files, haveGPU, debug)
% Given a list of image files, returns an array of coordinates that align
% images to the first image. Uses phase correlation.

% Sets debug mode: Prints top 5 results
DEBUG = 0;

if nargin == 2;
    DEBUG = debug;
end

% haveGPU = 0;
% if(exist('gpuDeviceCount') && (gpuDeviceCount>0))
%     g = gpuDevice;
%     haveGPU = (g.ComputeCapability > 1.3);
% end

numOffsets = length(files);

% Creates matrix of coordinates struct to be returned
offsets =  repmat(struct('frame',0,'x',0,'y',0),1,numOffsets);
offsets(1).frame = 1; % First offset is zero
if(numOffsets==1)
    return;
end
% First image is reference image.
image1 = double(imread(files{1}));

% Size of reference image used multiple times
%si = size(image1);
si = [300, 300];
if(haveGPU)
    image1G = gpuArray(image1(1:si(1),1:si(2)));
    hammingG = gpuArray(hamming(si(1), si(2)));
    image1G = image1G .* hammingG;
    image1G = fft2(image1G);
else
    % Hamming window applied to image to reduce edge effects
    image1 = image1(1:si(1), 1:si(2)) .* hamming(si(1), si(2));
    % Fourier transform used on image1
    image1 = fft2(image1);
end
% Remaining images tested against reference image
if(haveGPU)
    for k=2:numOffsets
        % Reads image, hamming window applied and then FT
        image2 = single(imread(files{k})); 
        image2 = image2(1:si(1), 1:si(2));
        image2G = gpuArray(image2);
        image2G = image2G .* hammingG;
        image2G = fft2(image2G);
        
        % Produces third image
        productG = image1G .* conj(image2G);
        productG = productG ./ abs(productG);
        productG = abs(ifft2(productG));
        product = gather(productG);

        % Finds maximum and position of maximum in resultant image
        [A, B] = max(product(:));
        % 0-Indexes position to make finding row and column easier
        B = B-1;
        [i j] = coordsFromPos(B, si);
        % Writes to struct matrix
        offsets(k).frame = k;
        offsets(k).x = i;
        offsets(k).y = j;
    end
else
    for k=2:numOffsets
        % Reads image, hamming window applied and then FT
        image2 = double(imread(files{k})); 
        image2 = image2(1:si(1), 1:si(2));
        image2 = image2 .* hamming(si(1), si(2));
        image2 = fft2(image2, si(1), si(2));
        
        % Produces third image
        product = image1 .* conj(image2);
        product = product ./ abs(product);
        product = abs(ifft2(product));

        % Finds maximum and position of maximum in resultant image
        [A, B] = max(product(:));
        % 0-Indexes position to make finding row and column easier
        B = B-1;
        % Uses function to get row and column
        [i j] = coordsFromPos(B, si);

        % Writes to struct matrix
        offsets(k).frame = k;
        offsets(k).x = i;
        offsets(k).y = j;
    end
end

% If debug, prints top 5 coordinates
if(DEBUG)
    fprintf(1, 'i = %d, j = %d, B= %d, max = %f\n', i, j, B, A);
    product(B+1) = 0;
    for k=(1:5)
        [A, B] = max(product(:));
        B = B-1;
        [i j] = coordsFromPos(B, si);
        fprintf(1, 'i = %d, j = %d, B= %d, max = %f\n', i, j, B, A);
        product(B+1) = 0;
    end
end

%----------------------------
function [i j] = coordsFromPos(B, si)

% Finds i and j coordinates of maximum
i = mod(B, si(1));
j = floor(B/si(1));

% If over halfway point of image converts to minus.
if(i>si(1)/2)
    i = mod(si(1)-i,si(1))*-1;
end
if(j>si(2)/2)
    j = mod(si(2)-j,si(2))*-1;
end

% Converts to final values
temp = i;
i = -j;
j = -temp;

% Removes negative 0s!
if i == -0
    i=0;
end
if j == -0
    j=0;
end


% Hamming window function
function r = hamming(M, M2)
if nargin == 2;  
    w1 = hamming(M);
    w2 = hamming(M2);
    r = w1 * w2';
    return;
end;
r = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));