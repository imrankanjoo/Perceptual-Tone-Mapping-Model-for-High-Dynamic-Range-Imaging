function XYZ = CAM16UCS2XYZ_QMhs(QMh, XYZw, La, Yb, surround)
% CAM16-UCS implemented by MUHAMMAD SAFDAR on 2017.03.14
% Mehmood, I., Shi, X., Khan, M. U., & Luo, M. R. (2023). Perceptual Tone Mapping Model for High Dynamic Range Imaging. IEEE Access, 11, 110272-110288.
%
% Converts CAM16-UCS color space values to XYZ color space.
%
% Syntax:
%   XYZ = CAM16UCS2XYZ_QMhs(QMh, XYZw, La, Yb, surround)
%
% Inputs:
%   QMh      - Brightness (Q) and Colorfulness (M) values in CAM16-UCS.
%   XYZw     - Reference white point in XYZ color space (3-element vector).
%   La       - Adapted luminance of the scene (scalar).
%   Yb       - Background luminance (scalar).
%   surround - Surrounding conditions (scalar), affecting the perception of color.
%
% Outputs:
%   XYZ      - Corresponding XYZ color space values (3-element vector).


XYZ= CAM16_revQMh(QMh,XYZw,La,Yb,surround);


end
function XYZ = CAM16_revQMh(QMh,XYZw,La,Yb,Surround)
%%% XYZ is test XYZ [Nx3]
%%% XYZw is test white  [1x3]
%%% La is adaptive luminance; La should be calculated as (Lw*Yb)/Yw, where Lw is the luminance of reference white in cd/m2 unit, Yb is the luminance factor of the background and  Yw is the luminance factor of the reference white. 
%%% Yb is background luminance factor (typically 20%; Yb=20)
%%% Surround conditions give c (impact of surround), Nc (chromatic induction factor), and F (factor of degree of adaptation), 

% Get parameters
if nargin>2;else La=2000/(pi*5);end                % luminance of adapted white point
if nargin>3;else Yb=20;end                         % luminance of background (typically 20)
if nargin>4;
   if strcmp(Surround,'avg'); c=0.69;  Nc=1;    F=1;   end % average surround
   if strcmp(Surround,'dim'); c=0.59;  Nc=0.9;  F=0.9; end % dim surround
   if strcmp(Surround,'dark');c=0.525; Nc=0.8;  F=0.8; end % dark surround
   if strcmp(Surround,'T1');  c=0.46;  Nc=0.9;  F=0.9; end % ISO 3664 T1 surround
else                          c=0.69;  Nc=1;    F=1;       % ISO 3664 P1, average surround
end

% step 0; Calculate constants

k=1/(5*La+1);
FL=0.2*k^4*5*La+0.1*(1-k^4)^2*(5*La)^(1/3);



% step 1
M_CAT16 =     [0.401288 0.650173 -0.051461; -0.250268 1.204414 0.045854; -0.002079 0.048952 0.953127];
M_CAT16inv =  [1.86206786  -1.01125463 0.14918677;  0.38752654 0.62144744 -0.00897398; -0.01584150 -0.03412294 1.04996444];
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
Ncb = Nbb;

RGBwc(1) = Dr*RGBw(1);
RGBwc(2) = Dg*RGBw(2);
RGBwc(3) = Db*RGBw(3);

RGBaw = (400*(Fl*RGBwc./100).^0.42)./(27.13+(Fl*RGBwc./100).^0.42)+0.1;

Aw = (2*RGBaw(1) + RGBaw(2) + RGBaw(3)/20 - 0.305)*Nbb;


J=6.25*((c.*QMh(:,1)./((Aw+4).*Fl.^0.25)).^2);
C=QMh(:,2)./(Fl.^0.25);


h=QMh(:,3);

% step 3; Compute t, et, p1, p2, p3, p4, p5, a,and b
t=(C./((J/100).^(0.5)*(1.64-0.29^n)^0.73)).^(1/0.9);
et=(cos(h*pi/180+2)+3.8)/4;
A=Aw*(J/100).^(1/(c*z));

p1=(50000/13)*Nc*Ncb.*et./t;
p2=A/Nbb+0.305;
p3=21/20;

if t==0
    a=0; b=0;
else
    at=cos(h*pi/180);
    bt=sin(h*pi/180);
    p4=p1./bt;
    p5=p1./at;

    p=abs(bt)>=abs(at);
    q=abs(bt)<abs(at);

    r=size(QMh,1);a=zeros(r,1);b=zeros(r,1);

    b(p)=p2(p)*(2+p3)*(460/1403)./(p4(p)+(2+p3).*(220/1403)*(at(p)./bt(p))-(27/1403)+p3*(6300/1403));
    a(p)=b(p).*(at(p)./bt(p));

    a(q)=p2(q)*(2+p3)*(460/1403)./(p5(q)+(2+p3).*(220/1403)-((27/1403)-p3*(6300/1403))*(bt(q)./at(q)));
    b(q)=a(q).*(bt(q)./at(q));
end

% step 5; Calculate post-adaptation values
Rpa=(460*p2+451*a+288*b)/1403;
Gpa=(460*p2-891*a-261*b)/1403;
Bpa=(460*p2-220*a-6300*b)/1403;

% step 6; Convert back to Hunt-Pointer-Estevez space
Rc=100*(((27.13*abs(Rpa-0.1))./(400-abs(Rpa-0.1)))).^(1/0.42)/FL;


j=find(Rpa<0.1); Rc(j)=-Rc(j);
j=find(Rpa==0.1);Rc(j)=0;

Gc=100*(((27.13*abs(Gpa-0.1))./(400-abs(Gpa-0.1)))).^(1/0.42)/FL;


l=find(Gpa<0.1); Gpa(l)=-Gc(l);
l=find(Gpa==0.1);Gc(l)=0;

Bc=100*(((27.13*abs(Bpa-0.1))./(400-abs(Bpa-0.1)))).^(1/0.42)/FL;


m=find(Bpa<0.1); Bc(m)=-Bc(m);
m=find(Bpa==0.1);Bc(m)=0;

R=real(Rc/Dr);
G=real(Gc/Dg);
B=real(Bc/Db);

XYZ = (M_CAT16inv* [R, G, B]')';
XYZ(XYZ<0)=0;

end

