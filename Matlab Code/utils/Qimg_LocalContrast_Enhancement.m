function detail_s = Qimg_LocalContrast_Enhancement(detail)
    
% Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.


% to turn off the details enhancement, uncomment the 2 line below 
% detail_s = detail;
% return;
maxd=max(detail(:));

detail_s=maxd*(detail/maxd).^1;


