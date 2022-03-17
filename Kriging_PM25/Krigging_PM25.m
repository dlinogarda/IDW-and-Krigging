clear all;
clc
tic

%% DATA LOADING AND REFINEMENT
[num,txt,raw] = xlsread('convertcsv.xlsx');
SX = size(raw);
for i = 2:SX(1)
    Data(i-1,1) = str2num(raw{i,6});  %PM25
    Data(i-1,2) = str2num(raw{i,15}); %Longitude (X)
    Data(i-1,3) = str2num(raw{i,12}); %Latitude  (Y)
    
end
SX = size(Data);

mm = 1;
% Filter outliers
for i = 1:SX(1)
    if (Data(i,1)==0 || Data(i,2)==0 || Data(i,3)==0)
        continue,
    end
    data(mm,1) = Data(i,1);
    data(mm,2) = Data(i,2);
    data(mm,3) = Data(i,3);
    mm = mm + 1;
end
SX = size(data);

% Determine the Area
x = [117,124];
y = [21,28];
nn = 1;
for i = 1:SX(1)
    if ((data(i,2)>x(1)&&data(i,2)<x(2)) && (data(i,3)>y(1)&&data(i,3)<y(2)))
        Fdata(nn,:) = data(i,:);
        nn = nn + 1;
    end
end
SX = size(Fdata);

idx = randperm(SX(1)) ;
% Determine the Sample by selecting randomly
Sdata(1:500,:) = Fdata(idx(1:500),:);

% Determine the pixels (resolution)
Sdata(:,2:3) = round(Sdata(:,2:3)*100);

% Determine min and max
xmin = min(Sdata(:,2)); ymin = min(Sdata(:,3));
xmax = max(Sdata(:,2)); ymax = max(Sdata(:,3)); 
% Maximum Distance
edis = round(sqrt((xmax-xmin)^2+(ymax-ymin)^2));
% Distance of Y axis
ydis = ymax-ymin;

% Create new coordinate by row and column
Sdata(:,2) = Sdata(:,2)-xmin+1;
Sdata(:,3) = Sdata(:,3)-ymin+1;
SX = size(Sdata);

% Select Train Data
trr = round(0.8*SX(1));
SDtrain(1:trr,:) = Sdata(1:trr,:);
% Select Testing Data
SDtest(1:SX(1)-trr,:) = Sdata(trr+1:SX(1),:);
str = size(SDtrain); sts = size(SDtest);

% Interpolation of Trainning data
figure, plot(Sdata(:,2),Sdata(:,3),'*');
title('Preview of points distribution');

for i = 1:str(1)
    MapData(SDtrain(i,3),SDtrain(i,2)) = SDtrain(i,1);
end
SM = size(MapData);
gridy = (1:SM(1)); %latitude (x)
gridx = (1:SM(2)); %logitude (y)

% Test Figure
figure, imagesc(gridx',gridy',MapData); axis image; axis xy
title('Point testing location');
%% ----------------------------------------------------------------From IDW
% Estimate the Variogram Values
Varpar = variogram([SDtrain(:,2) SDtrain(:,3)],SDtrain(:,1),'nrbins',edis);
% Regression to find Nugget, Sill and Range constructed in vstruct
figure,
[dum,dum,dum,vstruct] = variogramfit(Varpar.distance,Varpar.val,[],[],[],'model','stable');
title('Gaussian variogram model'); legend('Training data','Testing data','Location','NorthWest');

% Define coordinate row and column 
[XX,YY]= meshgrid(1:SM(2),1:SM(1));

% Interpolating unkonw points
[Zhat,Zvar] = kriging(vstruct,SDtrain(:,2),SDtrain(:,3),SDtrain(:,1),XX,YY);

% Kriging prediction map
figure, imagesc(gridx',gridy',Zhat); axis image; axis xy; title('Map of kriging predictions')
hold on, plot(SDtrain(:,2),SDtrain(:,3),'.c'); plot(SDtest(:,2),SDtest(:,3),'.r'); legend('Training data','Testing data','Location','NorthWest');
% Kriging prediction by contour
figure, contour(XX,YY,Zhat); axis image; title('Contour of kriging prediction');
hold on, plot(SDtrain(:,2),SDtrain(:,3),'.c'); plot(SDtest(:,2),SDtest(:,3),'.r'); legend('contour','Training data','Testing data','Location','NorthWest');

% Kriging variance by map
figure, imagesc(gridx',gridy',Zvar); axis image; axis xy; title('Map of kriging variance');
hold on, plot(SDtrain(:,2),SDtrain(:,3),'.c'); plot(SDtest(:,2),SDtest(:,3),'.r'); legend('Training data','Testing data','Location','NorthWest');
% Kriging variance by contour
figure, contour(XX,YY,Zvar); axis image; title('Contour of kriging variance');
hold on, plot(SDtrain(:,2),SDtrain(:,3),'.c'); plot(SDtest(:,2),SDtest(:,3),'.r'); legend('contour','Training data','Testing data','Location','NorthWest');

% Extract interpolated points in Tranning locations
for i = 1: trr
    Intpointst(i,1) = Zhat(SDtrain(i,3),SDtrain(i,2));
    Intpointst(i,2) = SDtrain(i,2);
    Intpointst(i,3) = SDtrain(i,3);
end
% Root Mean Square Error (RMSE) of Observed points and Predicted points (Tranning)
RMSEtranning = sqrt(sum((Intpointst(:,1)-SDtrain(:,1)).^2)/str(1))

% Extract interpolated points in Testing locations
for i = 1: SX(1)-trr
    Intpoints(i,1) = Zhat(SDtest(i,3),SDtest(i,2));
    Intpoints(i,2) = SDtest(i,2);
    Intpoints(i,3) = SDtest(i,3);
end
% Root Mean Square Error (RMSE) of Observed points and Predicted points (Testing)
RMSEtesting = sqrt(sum((Intpoints(:,1)-SDtest(:,1)).^2)/sts(1))

% Extract interpolated points in All locations
for i = 1: SX(1)
    Intps(i,1) = Zhat(Sdata(i,3),Sdata(i,2));
    Intps(i,2) = Sdata(i,2);
    Intps(i,3) = Sdata(i,3);
end
% Root Mean Square Error (RMSE) of Observed points and Predicted points (Testing)
RMSEall = sqrt(sum((Intps(:,1)-Sdata(:,1)).^2)/SX(1))

