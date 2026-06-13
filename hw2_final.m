% Laser Speckle Contrast Imaging (LSCI) Homework
clear; clc; close all;

% --- 1. Define folder paths ---
mainDir = 'C:\Users\yusuf\OneDrive\Masaüstü\BIU\Neurophotonics\HW2\Imports';

readNoisePath = fullfile(mainDir, 'Noises', 'WithCover_Gain24dB_expT0.021ms_BlackLevel30DU');
kspPath       = fullfile(mainDir, 'Noises', 'WhitePaper_Gain24dB_expT0.5ms_BlackLevel0DU');
dataFolder    = fullfile(mainDir, 'Recordings', 'expT5ms_Gain24dB_BL100DU_FR40Hz_005_reduced');

disp('Step 1: Calculating camera noise...');

% --- 2. Calculate Read Noise (Kr^2) ---
% Using the dark frame (with cover) to find electronic noise
filesRN = dir(fullfile(readNoisePath, '*.tif*'));
imRN = double(imread(fullfile(readNoisePath, filesRN(1).name)));

if all(mod(imRN(:), 16) == 0), imRN = imRN / 16; end 
Kr_sq = var(imRN(:)) / (mean(imRN(:))^2);

% --- 3. Calculate Spatial Noise (Ksp^2) ---
% Using white paper images to find pixel differences
filesKsp = dir(fullfile(kspPath, '*.tif*'));
numFrames = min(length(filesKsp), 500); 

avgFrame = 0;
for i = 1:numFrames
    img = double(imread(fullfile(kspPath, filesKsp(i).name)));
    if all(mod(img(:), 16) == 0), img = img / 16; end 
    avgFrame = avgFrame + img;
end
avgFrame = avgFrame / numFrames; % Average the frames to remove shot noise
Ksp_sq = var(avgFrame(:)) / (mean(avgFrame(:))^2);

fprintf('Read Noise (Kr^2): %f\n', Kr_sq);
fprintf('Spatial Noise (Ksp^2): %f\n\n', Ksp_sq);

% --- 4. Process the main recordings ---
disp('Step 2: Processing 400 frames for BFi...');

filesData = dir(fullfile(dataFolder, '*.tif*'));
[~, idx] = sort([filesData.datenum]); % Sort by time
filesData = filesData(idx);

numDataFrames = length(filesData);
Kf_sq = zeros(numDataFrames, 1);

% Constants from the folder name
T = 0.005;         % Exposure time (5ms)
blackLevel = 100;  % Black level base

for i = 1:numDataFrames
    img = double(imread(fullfile(dataFolder, filesData(i).name)));
    if all(mod(img(:), 16) == 0), img = img / 16; end 
    
    img = max(img - blackLevel, 0); % Remove black level
    
    avg_intensity = mean(img(:));
    K_total_sq = var(img(:)) / (avg_intensity^2);
    
    % Corrected contrast formula
    Kf_sq(i) = K_total_sq - (Kr_sq / (avg_intensity^2)) - Ksp_sq;
end

% Calculate Blood Flow Index (BFi)
BFi = 1 ./ (2 * T * Kf_sq);
disp('Done!');

% --- 5. Plot the results ---
t = (0:numDataFrames-1) / 40; % 40 Hz frame rate

fig1 = figure; % 

plot(t, BFi, 'r-', 'LineWidth', 1.5);
title('Blood Flow Index (BFi) Over Time');
xlabel('Time (Seconds)');
ylabel('BFi [a.u.]');
grid on;
axis tight;

%
pos = fig1.Position; 
fig1.Position = [pos(1), pos(2), pos(3), pos(4) * 0.5]; 
% --------------------------------------
