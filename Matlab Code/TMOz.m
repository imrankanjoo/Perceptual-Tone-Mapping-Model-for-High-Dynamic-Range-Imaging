%Clear workspace variables
clearvars;  

% Add utility paths
addpath(genpath('utils'));
addpath(genpath('HDR'));

%% Conditions for Tone Mapping
cond.XYZw1 = [95.047, 100.00, 108.883]; % D65 white point for HDR image
cond.Lw1 = 10000;                      % Luminance for HDR image
cond.Yb = 20;                          % Background Luminance
cond.XYZw2 = [95.047, 100.00, 108.883]; % White point for sRGB image or display
cond.Lw2 = 100;                     % Luminance for output image
cond.sr = 'avg';                       % Tone mapping method

%% Load HDR Image and Apply Tone Mapping
imgName = '4861Low';                       % Base name of the HDR image file
hdr = double(hdrread([imgName, '.hdr'])); % Read input HDR radiance map

% Avoid zero or near-zero values in the HDR image
hdr(hdr <= 0) = 0.0001;

% Apply tone mapping operator
sdr = TMOz_CAM16Q(hdr, cond);

%% Display and Save the Result
figure, imshow(sdr, 'border', 'tight'); % Display the tone-mapped image

% Optional: Save the tone-mapped image (uncomment to save)
imwrite(sdr, ['output\' imgName '.png'] );
