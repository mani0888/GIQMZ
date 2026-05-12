%% Main SIQMz
clc;    close all;      clear variables

tic
datasets = {'1.LIVE', '2.CSIQ', '3.TID2013', '4.CIDIQ', '5.KADID', '6.ZJU', '7.ZJUI'};
xlRange = {'C5:C783','C5:C868','C5:C2843','C5:C694','C5:C9953','C5:C1604','C5:C670'};
len_datasets = length(datasets);
FeaturesAll = [];
for i = 1:len_datasets
    char(datasets(i))
    path = ['F:\Datasets\',char(datasets(i)),'\distorted\'];
    filename = [path,'names.xlsx'];
    sheet = 1; 
    [~ , imgnames] = xlsread(filename,sheet,char(xlRange(i)));
    num_image = length(imgnames); % number of the image in the folder
    FeaturesA = zeros(num_image,80); % initialize matrix for the features
    
    for ii = 1:num_image
        % ii
        RGB = imread([path,char(imgnames(ii))]);
        sz = size(RGB);
        if sz(1)>960 || sz(2)>960
            if sz(1)>=sz(2)
                rszf =  960/sz(1);
            elseif sz(1)<sz(2)
                rszf =  960/sz(2);
            end
            RGB = imresize(RGB,rszf);
        end
        % SIQMZ Features
        FeaturesA(ii,:)  = IQM_SIQMZ( RGB );

    end

FeaturesSIQM = FeaturesA;

FeaturesAll = [FeaturesAll ; FeaturesSIQM];

end


function IQAtr = IQM_SIQMZ(RGB)

% Natural Scene Statistics (NSS) of Image Appearance Attributes
dims = size(RGB);
% RGB to XYZ conversion
if(size(RGB,3)==3)
    RGB = uint8(RGB);
    XYZ = 100*rgb2xyz(RGB);
    XYZ = (reshape(permute(XYZ, [3 1 2]), [3, dims(1) * dims(2)]))'; % nx3 dimension
end
% XYZ to CIELAB converison
Lab = xyz2lab(XYZ,'d65_31');
L=Lab(:,1); a=Lab(:,2); b=Lab(:,3);
L = reshape(L , [dims(1) dims(2)]); 
a = reshape(a , [dims(1) dims(2)]); 
b = reshape(b , [dims(1) dims(2)]);
C = sqrt(a.^2 + b.^2);              % Chroma channel
D = sqrt((L-100).^2 + a.^2 + b.^2); % Depth channel

% NSS features
featCh= NSSFeatures(C);  % Chroma channel
featD = NSSFeatures(D);  % Depth channel
IQAtr = [featCh featD ];

end

function [lab] = xyz2lab(xyz,obs,xyzw)
 
if (size(xyz,2)~=3)
   disp('xyz must be n by 3'); return;   
end
lab = zeros(size(xyz,1),size(xyz,2));

if strcmp('a_64',obs)
    white=[111.144 100.00 35.200];
elseif strcmp('a_31', obs)
    white=[109.850 100.00 35.585];
elseif strcmp('c_64', obs)
    white=[97.285 100.00 116.145];
elseif strcmp('c_31', obs)
    white=[98.074 100.00 118.232];
elseif strcmp('d50_64', obs)
    white=[96.720 100.00 81.427];
elseif strcmp('d50_31', obs)
    white=[96.422 100.00 82.521];
elseif strcmp('d55_64', obs)
    white=[95.799 100.00 90.926];
elseif strcmp('d55_31', obs)
    white=[95.682 100.00 92.149];
elseif strcmp('d65_64', obs)
    white=[94.811 100.00 107.304];
elseif strcmp('d65_31', obs)
    white=[95.047 100.00 108.883];
elseif strcmp('d75_64', obs)
    white=[94.416 100.00 120.641];
elseif strcmp('d75_31', obs)
    white=[94.072 100.00 122.638];
elseif strcmp('f2_64', obs)
    white=[103.279 100.00 69.027];
elseif strcmp('f2_31', obs)
    white=[99.186 100.00 67.393];
elseif strcmp('f7_64', obs)
    white=[95.792 100.00 107.686];
elseif strcmp('f7_31', obs)
    white=[95.041 100.00 108.747];
elseif strcmp('f11_64', obs)
    white=[103.863 100.00 65.607]; 
elseif strcmp('f11_31', obs)
    white=[100.962 100.00 64.350];
elseif strcmp('user', obs)
    white=xyzw;
else
   disp('unknown option obs'); 
   disp('use d65_64 for D65 and 1964 observer'); return;
end

lab = zeros(size(xyz,1),3);  

fx = zeros(size(xyz,1),3);
for i=1:3
    index = (xyz(:,i)/white(i) > (6/29)^3);
    fx(:,i) = fx(:,i) + index.*(xyz(:,i)/white(i)).^(1/3);   
    fx(:,i) = fx(:,i) + (1-index).*((841/108)*(xyz(:,i)/white(i)) + 4/29);   
end

lab(:,1)=116*fx(:,2)-16;
lab(:,2) = 500*(fx(:,1)-fx(:,2));
lab(:,3) = 200*(fx(:,2)-fx(:,3));

end

function feat1 = NSSFeatures(im)

feat1 = []; 
scale_num = 2;

for scale = 1:scale_num
    % 1. Spatial Domain NSS Features (GGD Parameters) [1:2]
    [MSCN_Map , Sigma_Map] = MSCNMap (im);
    [gampara , sigma] = ggdparamest(MSCN_Map(:));
    featGGD = [gampara sigma];

    % 2. Sigma Field Parameters (Mean, (CV^-1)^2)
    SM = Sigma_Map+eps;
    cvinvsq = (mean(SM(:))./std(SM(:))).^2;
    featSig = [mean2(Sigma_Map) cvinvsq];

    % 3. Neighboring Pair Products (AGGD Parameters)
    featNPPAGGD = NPPparams(MSCN_Map);

    feat1 = [feat1 featGGD featSig featNPPAGGD ];  
    im = imresize(im, 0.5);
end
end

function [MSCN_Map , sigma] = MSCNMap (im)
window = fspecial('gaussian',7,7/6);
window = window/sum(sum(window));

mu = filter2(window, im, 'same');
mu_sq = mu.*mu;
sigma = sqrt(abs(filter2(window, im.*im, 'same') - mu_sq));
MSCN_Map = (im-mu)./(sigma+1);
end

function [gamparam , sigma] = ggdparamest(coeffs)
gam      = 0.2:0.001:10;
r_gam    = (gamma(1./gam).*gamma(3./gam))./((gamma(2./gam)).^2);
sigma_sq = mean((coeffs - mean(coeffs)).^2);
sigma    = sqrt(sigma_sq);
E        = mean(abs(coeffs - mean(coeffs)));
rho      = sigma_sq/E^2;
[min_difference, array_position] = min(abs(rho - r_gam));
gamparam = gam(array_position);  
end

function [feat1] = NPPparams(MSCNmap)
% Constructing 4 neighborhood maps and extracting model features (AGGD parameters)
shifts = [ 0 1 ; 1 0 ; 1 1 ; -1 1];
modelFeat  = [];
for itr_shift =1:4
    % Construct the product neighborhood map.
    shifted_MSCN = circshift(MSCNmap,shifts(itr_shift,:));
    pair = MSCNmap.*shifted_MSCN; % Element wise product.
    hNPP(itr_shift,:) = histcounts(pair,150);
    
    % Fit an AGGD and extract its parameters.
    [alpha, leftstd, rightstd] = aggdparamest(pair(:));
    const = (sqrt(gamma(1/alpha))/sqrt(gamma(3/alpha)));
    meanparam = (rightstd-leftstd)*(gamma(2/alpha)/gamma(1/alpha))*const;

    % Aggregate the model parameters
    modelFeat =  [modelFeat alpha meanparam leftstd^2 rightstd^2];
end
feat1 = modelFeat ;
end

function [alpha, leftstd, rightstd] = aggdparamest(vec)
gam   = 0.2:0.001:10;
r_gam = ((gamma(2./gam)).^2)./(gamma(1./gam).*gamma(3./gam));
throwAwayThresh = 0.0;
leftstd            = sqrt(mean((vec(vec<-throwAwayThresh)).^2));
rightstd           = sqrt(mean((vec(vec>throwAwayThresh)).^2));
gammahat           = leftstd/rightstd;

vec1=vec;
rhat               = (mean(abs(vec1)))^2/mean((vec1).^2);
rhatnorm           = (rhat*(gammahat^3 +1)*(gammahat+1))/((gammahat^2 +1)^2);
[min_difference, array_position] = min((r_gam - rhatnorm).^2);
alpha              = gam(array_position);
end




