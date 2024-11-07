function TonedXYZ = TMOzclip(xyzin)
    % TMOzclip applies tone mapping to the input XYZ values.
    % This function simulates incomplete light adaptation and glare
    % in the visual system by clipping dark and light pixels.
    %
    % Inputs:
    %   xyzin - Input XYZ values (Nx3 matrix)
    %
    % Outputs:
    %   TonedXYZ - clipped XYZ values (Nx3 matrix)
    % Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.

    % Convert XYZ to xyY
    xyy = xyz2xyY(xyzin);
    outY = xyy(:, 3);  % Extract luminance channel

    % Normalize luminance to [0, 1]
    outY = outY ./ max(outY);

    %% Clipping: Simulate incomplete light adaptation and glare
    % Clip 1% dark pixels and light pixels individually
    min_y = max(percentile(outY(:), 1), 0);
    max_y = percentile(outY(:), 99);
    
    % Normalize the luminance values
    outY1 = (outY - min_y) ./ (max_y - min_y);
    outY1 = min(outY1, 1);  % Clamp to [0, 1]
    outY1(outY1 < 0) = 0.0001;  % Avoid zero values

    % Update the luminance channel in xyY
    xyy(:, 3) = outY1;

    % Convert back from xyY to XYZ
    TonedXYZ = xyY2xyz(xyy);
end
