function [Q, RGBa] = XYZ2CAM16Q(XYZ, XYZw, La, Yb, surround)
%%% CAM16-UCS developed by MUHAMMAD SAFDAR on 2017.03.14, Email: msafdar87@hotmail.com %%%
%%% Improved implementation and modified by Imran
%
% Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.
%
% Converts XYZ color space values to CAM16 color space.
%
% Syntax:
%   [Q, RGBa] = XYZ2CAM16Q(XYZ, XYZw, La, Yb, surround)
%
% Inputs:
%   XYZ      - Input color values in CIE 1931 XYZ color space (3-element vector).
%   XYZw     - Reference white point in XYZ color space (3-element vector).
%   La       - Adapted luminance of the scene (scalar).
%   Yb       - Background luminance (scalar).
%   surround - Surrounding conditions (scalar), affecting the perception of color.
%
% Outputs:
%   Q        - Brightness value in CAM16 color space (scalar).
%   RGBa     - Corresponding RGBa values .

[Q,RGBa]= CAM16_frwd(XYZ,XYZw,La,Yb,surround);

end

function [Q,RGBa]= CAM16_frwd(XYZ,XYZw,La,Yb,Surround)
%%% XYZ is test XYZ [nx3]
%%% XYZw is test white  [1x3]
%%% La is adaptive luminance; La should be calculated as (Lw*Yb)/Yw, where Lw is the luminance of reference white in cd/m2 unit, Yb is the luminance factor of the background and  Yw is the luminance factor of the reference white. 
%%% Yb is background luminance factor (typically 20%; Yb=20)
%%% Surround conditions give c (impact of surround), Nc (chromatic induction factor), and F (factor of degree of adaptation), 
%%% Default viewing condition corresponds to ISO 3664 P1 set-up


if nargin>2
else La=2000/(5*pi);
end % luminance of adapted white point
if nargin>3;
else Yb=20;end % luminance of background (typically 20)
if nargin>4;
   if strcmp(Surround,'avg'); c=0.69;  Nc=1;    F=1;   end % average surround
   if strcmp(Surround,'dim'); c=0.59;  Nc=0.9;  F=0.9; end % dim surround
   if strcmp(Surround,'dark');c=0.525; Nc=0.8;  F=0.8; end % dark surround
   if strcmp(Surround,'T1');  c=0.46;  Nc=0.9;  F=0.9; end % ISO 3664 T1 surround
else                          c=0.69;  Nc=1;    F=1; % ISO 3664 P1, average surround
end

% step 0
M_CAT16 =     [0.401288 0.650173 -0.051461; -0.250268 1.204414 0.045854; -0.002079 0.048952 0.953127];
RGBw = M_CAT16*XYZw';

D_pre =  F * (1- (1/3.6)*exp((-La-42)/92)); % D is degree of adoptation; If D is greater than one or less than zero,set it to one or zero accordingly.
if D_pre<0
    D = 0;
elseif D_pre>1
    D = 1;
else
    D = D_pre;
end

Dr = D*(XYZw(2)/RGBw(1)) + 1 - D;
Dg = D*(XYZw(2)/RGBw(2)) + 1 - D;
Db = D*(XYZw(2)/RGBw(3)) + 1 - D;

k = 1/(5*La+1);
Fl = 0.2*(k^4)*(5*La) + 0.1*((1-k^4)^2)*((5*La)^(1/3));
n = Yb/XYZw(2);
z = 1.48+sqrt(n);
Nbb = 0.725*(1/n)^0.2;

RGBwc(1) = Dr*RGBw(1);
RGBwc(2) = Dg*RGBw(2);
RGBwc(3) = Db*RGBw(3);
RGBaw=(400*(Fl*RGBwc/100).^0.42)./(27.13+(Fl*RGBwc/100).^0.42)+0.1;
Aw = (2*RGBaw(1) + RGBaw(2) + RGBaw(3)/20 - 0.305)*Nbb;
RGB = M_CAT16*XYZ';

RGBc(1,:) = Dr*RGB(1,:);
RGBc(2,:) = Dg*RGB(2,:);
RGBc(3,:) = Db*RGB(3,:);
indxg=RGBc>= 0;
indxl=~indxg;
div100=0.01;

RGBa(indxg)=( 400*( Fl*RGBc(indxg)*div100).^0.42)./(27.13+( Fl*RGBc(indxg)*div100).^0.42)+0.1;

RGBa(indxl) = (-400*(-Fl*RGBc(indxl)*div100).^0.42)./(27.13+(-Fl*RGBc(indxl)*div100).^0.42)+0.1;
RGBa=reshape(RGBa,size(RGBc));

 A = (2*RGBa(1,:) + RGBa(2,:) + RGBa(3,:)/20 - 0.305)*Nbb;
J= 100*(A./Aw).^(c.*z);
J=real(J);
Q = (4./c)*((J./100).^0.5)*(Aw + 4)*(Fl^0.25);
Q=real(Q);
    
end 