function [base_layer, detail_layer] = fastbilateralfilter(img)
    % fastbilateralfilter separates an image into base and detail layers
    % using a bilateral filter.
    % Written by Jiangtao (Willy) Kuang and Hiroshi Yamaguchi
    % Date: Feb. 20, 2006

    % Determine downsampling factor based on image size
    if min(size(img)) < 1024
        z = 2;
    else
        z = 4;
    end

    % Avoid zero or near-zero values in the image
    img(img < 0.0001) = 0.0001;
    logimg = log10(img);  % Convert image to log scale

    % Apply piecewise bilateral filter
    base_layer = PiecewiseBilateralFilter(logimg, z);

    % Remove any erroneous points in the base layer
    base_layer = min(base_layer, max(logimg(:)));
    
    % Calculate detail layer
    detail_layer = logimg - base_layer;
    detail_layer(detail_layer > 12) = 0;  % Clamp detail layer values

    % Convert back from log scale
    base_layer = 10.^base_layer;
    detail_layer = 10.^detail_layer;
end

function a = idl_dist(m, n)
    % idl_dist computes the Euclidean distance matrix.
    % Inputs:
    %   m - number of rows
    %   n - number of columns
    % Output:
    %   a - distance matrix (mxn)

    % Create a row vector and compute squared distances
    x = 0:(n-1);
    x = min(x, (n - x)).^2;  % Square the distances
    if nargin == 1
        m = n;  % If only n is provided, set m = n
    end

    a = zeros(m, n);  % Initialize distance matrix

    for i = 0:m/2  % Row loop
        y = sqrt(x + i.^2);  % Euclidean distance
        a(i + 1, :) = y;  % Insert the row
        if i ~= 0
            a(m - i + 1, :) = y;  % Symmetrical row
        end
    end
end

function imageOut = PiecewiseBilateralFilter(imageIn, z)
    % PiecewiseBilateralFilter applies a piecewise bilateral filter to the input image.
    % Inputs:
    %   imageIn - Input image (log scale)
    %   z - Downsampling factor
    % Output:
    %   imageOut - Filtered output image

    % Get image dimensions
    imSize = size(imageIn);
    xDim = imSize(2);
    yDim = imSize(1);

    % Parameters for the filter
    sigma_s = 2 * xDim / z / 100;  % Spatial sigma
    sigma_r = 0.25;                 % Range sigma

    % Calculate intensity range
    maxI = max(imageIn(:));
    minI = min(imageIn(:));
    nSeg = (maxI - minI) / sigma_r;
    inSeg = round(nSeg);  % Number of segments

    % Create Gaussian kernel
    distMap = idl_dist(yDim, xDim);
    kernel = exp(-1 * (distMap ./ sigma_s).^2);
    kernel = kernel / kernel(1, 1);  % Normalize kernel
    fs = max(real(fft2(kernel)), 0);
    fs = fs / fs(1, 1);  % Normalize frequency response

    % Downsample the input image
    Ip = imageIn(1:z:end, 1:z:end);
    fsp = fs(1:z:end, 1:z:end);

    % Initialize output image
    imageOut = zeros(size(imageIn));
    intW = zeros(size(imageIn));  % Interpolation weight map

    for j = 0:inSeg  % Iterate over intensity segments
        value_i = minI + j * (maxI - minI) / inSeg;
        
        % Edge-stopping function
        jGp = exp((-1 / 2) * ((Ip - value_i) ./ sigma_r).^2);
        
        % Normalization factor
        jKp = max(real(ifft2(fft2(jGp) .* fsp)), 1e-10); 
        
        % Compute H for each pixel
        jHp = jGp .* Ip;
        sjHp = real(ifft2(fft2(jHp) .* fsp));
        
        % Normalize
        jJp = sjHp ./ jKp;
        
        % Upsample and interpolate
        jJ = imresize(jJp, z, 'nearest');
        jJ = jJ(1:yDim, 1:xDim);
        
        % Interpolation weight
        intW = max(ones(size(imageIn)) - abs(imageIn - value_i) * (inSeg) / (maxI - minI), 0);
        
        % Update output image
        imageOut = imageOut + jJ .* intW;
    end
end
