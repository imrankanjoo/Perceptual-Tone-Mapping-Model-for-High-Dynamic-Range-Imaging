function rgbimg = TMOz_CAM16Q(hdr, cond)
    % TMOz2CAM16Q applies a tone mapping operator using CAM16Q to HDR images.
    % Inputs:
    %   hdr  - High Dynamic Range image in sRGB format
    %   cond - Surround conditions structure
    % Output:
    %   rgbimg - Tone-mapped RGB image
    
    % Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.
    %% Convert HDR image from sRGB to XYZ color spac
    sz = size(hdr);
    xyzi = srgb2xyzLinear(hdr); 
    clear hdr;

    % Extract luminance (Y) and calculate key value
    y = xyzi(:, 2);
    key = imgKey(y(:));

    % Get surround conditions
    [XYZw1, La1, Yb, sr, XYZw2, La2] = getcond(cond);

    %% Normalize XYZ values
    normy = 100;
    xyzi = xyzi ./ max(xyzi(:, 2)) * normy;

    %% Convert XYZ to CAM16Q
    [Q, RGBa] = XYZ2CAM16Q(xyzi, XYZw1, La1, Yb, sr);
    Qimg = reshape(Q, sz(1), sz(2));
    clear xyzi Q;

    % Normalize Q image
    maxq = max(Qimg(:));
    Qimg = Qimg ./ maxq;

    %% Apply Bilateral Filter to get base and detail layers
    [base_Q, detail_Q] = fastbilateralfilter(Qimg); 
    clear Qimg;

    %% Enhance Details using Local Contrast
    detail_Qe = Qimg_LocalContrast_Enhancement(detail_Q); 
    clear detail_Q;

    %% Apply Tone Curve Compression to Base
    base_Qc = tonecurveM(base_Q, key); 
    clear base_Q;

    %% Combine Base and Detail Images
    Qimgo = base_Qc .* detail_Qe .* maxq; 
    clear base_Qc detail_Qe;

    %% Color Correction based on QMh
    [Mc, h] = newM(Qimgo(:).', XYZw2, La2, Yb, sr, RGBa);
    QMh = [Qimgo(:), Mc.', h.'];
    
    %% Convert QMh back to XYZ
    xyzo = CAM16UCS2XYZ_QMhs(QMh, XYZw2, La2, Yb, sr);

    %% Clipping: Simulate Incomplete Light Adaptation
    TonedXYZ = TMOzclip(xyzo); 

    %% Final XYZ to RGB image
    TonedXYZ = TonedXYZ ./ max(TonedXYZ(:, 2)) * XYZw2(2);
    TonedXYZ = TonedXYZ ./ max(TonedXYZ(:, 2));              
    rgbimg = xyz2srgb(TonedXYZ);
    rgbimg = reshape(rgbimg, sz);
    rgbimg = uint8(rgbimg);
end

function [XYZw1, La1, Yb, sr, XYZw2, La2] = getcond(cond)
    % Extract surround conditions from the input structure
    XYZw1 = cond.XYZw1;
    Yb = cond.Yb;
    La1 = cond.Lw1 * Yb / 100;
    sr = cond.sr;
    XYZw2 = cond.XYZw2;
    La2 = cond.Lw2 * Yb / 100;
end
