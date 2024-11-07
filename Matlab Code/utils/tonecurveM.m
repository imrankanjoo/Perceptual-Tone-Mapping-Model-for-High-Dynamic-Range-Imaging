function base_Qc= tonecurveM(base_Q,key)
    
% Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.

a=  0.6781;
b= 0.3128;

gamma=a*key+b;

base_Qc = (base_Q).^gamma ;
end

