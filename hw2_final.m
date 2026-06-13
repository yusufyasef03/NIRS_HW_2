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
K_total_sq_vec = zeros(numDataFrames, 1);


% Constants from the folder name
T = 0.005;         % Exposure time (5ms)
blackLevel = 100;  % Black level base
for i = 1:numDataFrames
    img = double(imread(fullfile(dataFolder, filesData(i).name)));
    if all(mod(img(:), 16) == 0), img = img / 16; end 
    
    img = max(img - blackLevel, 0); % Remove black level
    
    avg_intensity = mean(img(:));
    avg_intensity_val = avg_intensity(1); 
    
    K_total_sq = var(img(:)) / (avg_intensity_val^2);
    K_total_sq_val = K_total_sq(1);       
    
    Kr_sq_val  = Kr_sq(1);                 
    Ksp_sq_val = Ksp_sq(1);                
    
    K_total_sq_vec(i) = K_total_sq_val;
    
    % Corrected contrast formula
    Kf_sq(i) = K_total_sq_val - (Kr_sq_val / (avg_intensity_val^2)) - Ksp_sq_val;
end



% Calculate Blood Flow Index (BFi)
BFi = 1 ./ (2 * T * Kf_sq);
disp('Done!');


% --- 5. Plot the results ---
t = (0:numDataFrames-1) / 40; % 40 Hz frame rate
% --- corrected graph ---
fig1 = figure; % 
plot(t, BFi, 'r-', 'LineWidth', 1.5);
title('Corrected Blood Flow Index (BFi) Over Time');
xlabel('Time (Seconds)');
ylabel('BFi [a.u.]');
grid on;
axis tight;
%
pos = fig1.Position; 
fig1.Position = [pos(1), pos(2), pos(3), pos(4) * 0.5]; 
% --------------------------------------
% --- raw graph ---
fig2 = figure;
hold on;
plot(t, K_total_sq_vec, 'b--', 'LineWidth', 1.2, 'DisplayName', 'Raw K^2');
plot(t, Kf_sq, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Corrected K_f^2');
hold off;
title('Speckle Contrast: Raw vs. Corrected');
xlabel('Time (Seconds)');
ylabel('Contrast Squared (K^2)');
legend('Location', 'best');
grid on;
axis tight;
pos2 = fig2.Position;
fig2.Position = [pos2(1), pos2(2), pos2(3), pos2(4) * 0.5];
