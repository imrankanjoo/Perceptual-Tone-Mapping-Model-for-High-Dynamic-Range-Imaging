function Lav = logMean(img)

delta = 1e-6;
img_delta = log(img + delta);

Lav = exp(mean(img_delta(:)));

end