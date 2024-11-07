function alpha=imgKey(L)
    
% Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.

L=L./max(L(:));
LMin = MaxQuart(L, 0.01);
LMax = MaxQuart(L, 0.99);

log2Min     = log2(LMin + 1e-9);
log2Max     = log2(LMax + 1e-9);
logAverage  = logMean(L);
log2Average = log2(logAverage + 1e-9);

alpha = 0.18*4^((2.0*log2Average - log2Min - log2Max)/( log2Max - log2Min));
end
