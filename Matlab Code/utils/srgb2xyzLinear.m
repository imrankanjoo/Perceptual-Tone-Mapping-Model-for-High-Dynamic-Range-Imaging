function XYZpred=srgb2xyzLinear(img)

% img is an luminance RGB images with unit cd/m2
% use a sRGB matrix to convert RGB 2 XYZ
    
% Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.

M = [0.412424    0.212656    0.0193324;  
     0.357579    0.715158    0.119193;   
     0.180464    0.0721856   0.950444];
size_img = size(img);
scalars = reshape(img, size_img(1)*size_img(2), size_img(3));
XYZpred = (scalars * M);

XYZpred(XYZpred<0.00000001) = 0.00000001;
end