function [ gState ] = extractBackground3( imlist, offsets, outputMaskFolder, reverse)

    % Sets debugging mode
    DEBUG = 0;
    
    % Creates directories if in debugging mode and directories don't exist
    if DEBUG
        if ~isdir(sprintf('%sdebug/', outputMaskFolder))
            mkdir(sprintf('%sdebug/', outputMaskFolder));
        end
        if ~isdir(sprintf('%sdebug/overlays/', outputMaskFolder))
            mkdir(sprintf('%sdebug/overlays/', outputMaskFolder));
        end
        if ~isdir(sprintf('%sdebug/vardists/', outputMaskFolder))
            mkdir(sprintf('%sdebug/vardists/', outputMaskFolder));
        end
    end
    % Decides how quickly the gaussian model of the background 'learns' in:
    learningAlpha = 0.08;
    
    % How many standard deviations must a pixel be from the mean background
    % before it is considered foreground
    k = 1;
    
    % Half images as learning
    len = length(imlist);
    nLearners = floor(len/2);
    
    % Single Gaussian algorithm
    updateFunc = @singleGaussianUpdate;
    initFunc = @singleGaussianInit;
    getForegroundFunc = @singleGaussianGetForeground;

    % Image pre processing function
    preProcFunc = @preProc1;
    
    % Post processing function: "closing"
    postProcFunc = @(img1,img2) dilate4(erode4(celAuto(double(img1), double(img2),4)));
    
    
    % Get min/max offsets
    minOffsets = struct('x', min([offsets.x]), 'y', min([offsets.y]));
    maxOffsets = struct('x', max([offsets.x]), 'y', max([offsets.y]));


    if nargin < 4
        reverse = 0;
    end
    
    % Prepare first image
    img0 = double(imread(imlist{nLearners}));
    img1 = offsetImage(img0, minOffsets, maxOffsets, offsets(nLearners));
    foregroundImg = img1;
    
    % Initialise state for gaussian algorithm
    gState = initFunc(learningAlpha, k, img1);
    
    % Main loop over images
    for i=1:len
        if reverse
            ip = len-i+1;
        else
            ip = i;
        end
        % Load image into memory
        img0 = double(imread(imlist{ip}));
        % Fix offset
        img1 = offsetImage(img0, minOffsets, maxOffsets, offsets(ip));
        % Preprocess image
        img = preProcFunc(img1);
        % Update model
        gState = updateFunc(gState, img);
        
        if i>=nLearners-1
            % Find foreground mask
            foregroundImg = getForegroundFunc(gState, img);
        end
        % If out of learning stage, write masks to files
        if i>=nLearners+1
            % Get filename
            [dummy filename] = fileparts(imlist{ip});
            % Get vars out of state variable
            [d1 d2 backMean backVar] = gState{1:4};
            % Get how many standard deviations away from the mean each
            % pixel is
            mdv = (img-backMean).^2./backVar;
            % Apply post-processing function
            displayForeground = postProcFunc(foregroundImg, oldForeground);
            % Write mask to file
            imwrite((displayForeground ~= 0), sprintf('%s%s.tif', ...
                outputMaskFolder, filename), 'tif', 'Compression', 'ccitt');
            if DEBUG
                % Write overlay to disk (DEBUG)
                imwrite(overlayImage(img1/600, double(displayForeground)), ...
                	sprintf('%sdebug/overlays/%s.bmp', outputMaskFolder, ...
                        filename));
                % Write mdv to disk (DEBUG)
                imwrite(filter2(gaussian(5,5,5), mdv)*64, jet, ...
                    sprintf('%sdebug/vardists/%s.bmp', outputMaskFolder, ...
                    filename));
            end
        end
        % Progress tracker
        tickFunction(i,1,len);
        % Replace previous image
        oldForeground = foregroundImg;
    end

end

% Unsharp filter
function img = preProc1(img0)
    img = double(img0)-filter2(gaussian(20,20,20), img0);
    img(img<0) = 0;
end

% Finds positive neighbours of a pixel in time and space
function img = celAuto(img0a, img0b, minNeighs)
        img1a = filter2([1 1 1;1 0 1; 1 1 1], img0a);
        img1b = filter2([1 1 1;1 0 1; 1 1 1], img0b);
        img = ((img1a+img1b)>=minNeighs) & img0a;
end

% 4-Space dilate function
function img = dilate4(img0)
    K = [-1  0;
          0 -1;
          0  1;
          1  0];
    img1 = double(img0);
    img = img1;
    for k=1:size(K,1)
        img = max(img, circshift(img1, K(k,:)));
    end
end

%4-Space erode function
function img = erode4(img0)
    K = [-1  0;
          0 -1;
          0  1;
          1  0];
    img1 = double(img0);
    img = img1;
    for k=1:size(K,1)
        img = min(img, circshift(img1, K(k,:)));
    end
end

% Finds foreground of image using gaussian model. Thresholds image by
% removing the lowest 97% of difference between img and mean first.
function foreground = singleGaussianGetForeground(gState, img)
    [alpha k backMean backVar] = gState{1:4};
    img0 = img-backMean;
    % Only want 3% of pixels
    img1 = img>quantile(img(:),0.97);
    foreground = (((img0 .* img0) > k^2*backVar) & (img0 > 0)) .* ones;
    foreground = foreground & img1;
end

% Updates gaussian model of background pixels
function gState = singleGaussianUpdate(gState, img)
    [alpha k backMean backVar] = gState{1:4};
    foreground = ((img-backMean).^2 > k^2*backVar);
    background = not(foreground);
    backVar = alpha*(img-backMean).^2+(1 - alpha)*backVar;
    backMean(background) = alpha*img(background) + (1 - alpha) * ...
        backMean(background);
    gState = {alpha k backMean backVar};
end

% Initialise model
function gState = singleGaussianInit(alpha, k, img)
    backMean = double(img);
    backVar = zeros(size(backMean));
    gState = {alpha k backMean backVar};
end

% Apply offset to image
function img = offsetImage(img0, minOffsets, maxOffsets, curOffsets)
    [H, W] = size(img0);
    img1 = circshift(img0, [-curOffsets.y, -curOffsets.x]);
    img1(:,(W+minOffsets.x):W) = 0;
    img1((H+minOffsets.y):H,:) = 0;
    img1(:,(W+minOffsets.x):W) = 0;
    img1((H+minOffsets.y):H,:) = 0;
    img = img1; %((maxOffsets.y+1):(H+minOffsets.y),(maxOffsets.x+1):(W+minOffsets.x));
end

% Creates gaussian kernel for filtering
function [ h ] = gaussian( m, n, sigma )
    [h1, h2] = meshgrid(-(m-1)/2:(m-1)/2, -(n-1)/2:(n-1)/2);
    hg = exp(- (h1.^2+h2.^2) / (2*sigma^2));
    h = hg ./ sum(hg(:));
end

% Normalises images histogram
function img = normaliseImage(img0, meanBlackLevel)
    img1 = img0-meanBlackLevel;
    md = median(img1(:));
    multiplier = 500/md;
    img = img1 * multiplier;
end

% Progress meter function
function tickFunction(i,start,len)
    i = i-start;
    tickVal = floor((100*i)/(len-start));
    prevTickVal = floor((100*(i-1))/(len-start));
    if(tickVal>prevTickVal)
        if i == len
            fprintf(1, '\n');
        elseif floor(tickVal/10) > floor(prevTickVal/10)
            if prevTickVal > 0
                for j=1:(tickVal-prevTickVal-1)
                    fprintf(1, '.');
                end
            end
            fprintf(1, '%2d%%', floor(tickVal/10)*10);
            if floor(tickVal/10)*10 == 100
                fprintf(1, '\n');
            end
        else
            for j=1:(tickVal-prevTickVal)
                fprintf(1, '.');
            end
        end
    end
end

% Overlays image with mask in red. Debugging function
function img = overlayImage(bwImg, rcImg)
    mx = max(bwImg(:));
    img = repmat(bwImg, [1 1 3]);
    img(:,:,1) = rcImg*mx;
end