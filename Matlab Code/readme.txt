 Perceptual Tone Mapping Model for High Dynamic Range Imaging
Note: This code is not optimized for processing.


Table of Contents
-----------------
1. Requirements
2. Usage
3. Parameters
4. References

Requirements
------------
- MATLAB
- Image Processing Toolbox
- HDR Toolbox (for hdrread and hdrwrite functions)
- Utilities for tone mapping (located in the 'utils' folder)

Usage
-----
1. Ensure that you have the required HDR image file in the HDR directory;.
2. Adjust the parameters in the Conditions for Tone Mapping section as needed.
3. Run the script in MATLAB.
4. The tone-mapped image will be displayed, and optionally, saved to the specified output directory.

Example
-------
To use the script, simply run it in MATLAB after setting the desired parameters:

% Clear workspace variables
clearvars;

% Add utility paths
addpath(genpath('utils'));
addpath(genpath('HDR'));

%% Conditions for Tone Mapping
cond.XYZw1 = [95.047, 100.00, 108.883]; % D65 white point for HDR image
cond.Lw1 = 10000;                      % Luminance for HDR image
cond.Yb = 20;                          % Background Luminance
cond.XYZw2 = [95.047, 100.00, 108.883]; % White point for sRGB image or display
cond.Lw2 = 100;                        % Luminance for output image
cond.sr = 'avg';                       % Tone mapping method

%% Load HDR Image and Apply Tone Mapping
imgName = 'Peppermill';                % Base name of the HDR image file
hdr = double(hdrread([imgName, '.hdr'])); % Read input HDR radiance map

% Avoid zero or near-zero values in the HDR image
hdr = imresize(hdr, 0.2);
hdr(hdr <= 0) = 0.0001;

% Write a low-resolution HDR image (optional)
hdrwrite(hdr, 'PeppermillLow.hdr');

% Apply tone mapping operator
sdr = TMOz2CAM16Q(hdr, cond);

%% Display and Save the Result
figure, imshow(sdr, 'border', 'tight'); % Display the tone-mapped image
imwrite(sdr, ['output\' imgName '.png']); % Save the tone-mapped image

Parameters
----------
- cond.XYZw1: D65 white point for HDR image (default: [95.047, 100.00, 108.883])
- cond.Lw1: Luminance for HDR image (default: 10000)
- cond.Yb: Background luminance (default: 20)
- cond.XYZw2: White point for sRGB image or display (default: [95.047, 100.00, 108.883])
- cond.Lw2: Luminance for output image (default: 100)
- cond.sr: Tone mapping method (default: 'avg')

References
----------
For further reading and citation, please refer to:
- Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.

License
-------
This work is licensed under the IEEE Access License Agreement. For more information, please refer to the IEEE Access website and the specific licensing terms applicable to this publication.
