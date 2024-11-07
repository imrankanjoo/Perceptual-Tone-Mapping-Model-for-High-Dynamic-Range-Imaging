function [M, h] = newM(Q, XYZw, La, Yb, Surround, RGBa)
    % newM calculates the new colorfulness and hue.
    % Inputs:
    %   Q       - Tone mapped brighntess values in CAM16Q space (Nx1)
    %   XYZw    - Reference white (1x3)
    %   La      - Adaptive luminance (cd/m^2)
    %   Yb      - Background luminance factor (typically 20%)
    %   Surround - Surround conditions ('avg', 'dim', 'dark', 'T1')
    %   RGBa    - RGB values in adapted space (Nx3)
    % Outputs:
    %   M       - Colorfulness (Nx1)
    %   h       - Hue values (Nx1)
    
    % Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.

    %% Step 1: Set Default Parameters
    if nargin < 3
        La = 2000 / (pi * 5);  % Default adaptive luminance
    end
    if nargin < 4
        Yb = 20;               % Default background luminance factor
    end
    if nargin < 5
        Surround = 'avg';      % Default surround condition
    end

    % Step 2: Determine Surround Parameters
    switch Surround
        case 'avg'
            c = 0.69; Nc = 1; F = 1;    % Average surround
        case 'dim'
            c = 0.59; Nc = 0.9; F = 0.9; % Dim surround
        case 'dark'
            c = 0.525; Nc = 0.8; F = 0.8; % Dark surround
        case 'T1'
            c = 0.46; Nc = 0.9; F = 0.9; % ISO 3664 T1 surround
        otherwise
            c = 0.69; Nc = 1; F = 1;     % Default average surround
    end

    % Step 3: Calculate Constants
    M_CAT16 = [
        0.401288, 0.650173, -0.051461; 
        -0.250268, 1.204414, 0.045854; 
        -0.002079, 0.048952, 0.953127
    ];
    
    RGBw = M_CAT16 * XYZw';  % Convert reference white to RGB
    D_pre = F * (1 - (1 / 3.6) * exp((-La - 42) / 92));  % Degree of adaptation

    % Clamp D to [0, 1]
    D = max(0, min(1, D_pre));

    % Calculate adaptation factors for RGB channels
    Dr = D * (XYZw(2) / RGBw(1)) + 1 - D;
    Dg = D * (XYZw(2) / RGBw(2)) + 1 - D;
    Db = D * (XYZw(2) / RGBw(3)) + 1 - D;

    % Step 4: Calculate Fl and Nbb
    k = 1 / (5 * La + 1);
    Fl = 0.2 * (k^4) * (5 * La) + 0.1 * ((1 - k^4)^2) * ((5 * La)^(1 / 3));
    n = Yb / XYZw(2);
    Nbb = 0.725 * (1 / n)^0.2;

    % Step 5: Calculate RGBwc and RGBaw
    RGBwc = [Dr * RGBw(1); Dg * RGBw(2); Db * RGBw(3)];
    RGBaw = (400 * (Fl * RGBwc ./ 100).^0.42) ./ (27.13 + (Fl * RGBwc ./ 100).^0.42) + 0.1;

    % Step 6: Calculate Aw and J
    Aw = (2 * RGBaw(1) + RGBaw(2) + RGBaw(3) / 20 - 0.305) * Nbb;
    J = 6.25 * ((c .* Q ./ ((Aw + 4) .* Fl.^0.25)).^2);

    %Step 7: Calculate a and b for Chromaticity
    a = RGBa(1, :) - 12 * RGBa(2, :) / 11 + RGBa(3, :) / 11;
    b = (RGBa(1, :) + RGBa(2, :) - 2 * RGBa(3, :)) / 9;

    %Step 8: Calculate Chromaticity and Hue
    [h] = cart2pol(a, b);
    h = h * 180 / pi;  % Convert radians to degrees
    h = h + 360 * (h < 0);  % Ensure hue is positive

    % Step 9: Calculate Chromatic Induction Factor
    et = (cos(2 + h * pi / 180) + 3.8) / 4;
    t = ((Nc * Nbb * 50000 / 13) * (et .* sqrt(a.^2 + b.^2))) ./ (RGBa(1, :) + RGBa(2, :) + 21 * RGBa(3, :) / 20);

    %Step 10: Calculate Colorfulness and Adaptation Matrix M
    C = (t.^0.9) .* sqrt(J ./ 100) .* (1.64 - 0.29^n)^0.73;
    M = C .* Fl.^0.25;
end
