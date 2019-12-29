% clear 
clear;
clc;
close all;

params = struct();
params.HThreshold = 0.2;
params.RThreshold = 0.5;

crop_params = [500 1; 720 720];

cross_tempate_rgb = [193 146 141]/255.0;

% read the template cross object
cross_template_file = '../data/cross_template.png';
% cross_template_file = '../data/cross_template.png';
% test_sample_file = '../data/sample_full.png';
% test_sample_file = '../data/sample1.png';
test_sample_file = '../data/cam_front/000004.png';

cross_tempate = imread(cross_template_file);
test_sample = imread(test_sample_file);
test_sample_cropped = test_sample(crop_params(1,1):crop_params(2,1), crop_params(1,2):crop_params(2,2), :);

cross_tempate_hsv = rgb2hsv(cross_tempate);
test_sample_hsv = rgb2hsv(test_sample_cropped);

cross_tempate_h = cross_tempate_hsv(:, :, 1);
cross_tempate_kernal_h = cross_tempate_h;
cross_tempate_kernal_h(cross_tempate_h > params.HThreshold) = 1;
cross_tempate_kernal_h = 1 - cross_tempate_kernal_h;

test_sample_h_filter = test_sample_hsv(:, :, 1);
test_sample_h_filter(test_sample_h_filter > params.HThreshold) = 1;
test_sample_h_filter = 1 - test_sample_h_filter;

cross_tempate_r = cross_tempate(:, :, 1);
cross_tempate_kernal_r = double(cross_tempate_r)/255.0;
cross_tempate_kernal_r(cross_tempate_kernal_r < params.RThreshold) = 0;

test_sample_r_filter = double(test_sample_cropped(:, :, 1))./sum(test_sample_cropped, 3);
test_sample_r_filter(test_sample_r_filter < params.RThreshold) = 0;

imTargetHFiltered = imfilter(test_sample_h_filter, cross_tempate_kernal_h);

imTargetHFilteredNorm = imTargetHFiltered/max(imTargetHFiltered(:));

[~, maxIndex] = max(imTargetHFilteredNorm(:));
[rowId, colId] = ind2sub(size(imTargetHFilteredNorm), maxIndex);

figure();
imshow(imTargetHFilteredNorm);

figure();
imshow(test_sample_cropped);

hold on;
plot(colId, rowId, 'ro');

figure();
imshow(cross_tempate_kernal_h);

figure();
imshow(test_sample_hsv(:, :, 1));

figure();
imshow(test_sample_hsv(:, :, 2));

figure();
imshow(test_sample_hsv(:, :, 3));



% figure();
% imshow(imTargetRFiltered/max(imTargetRFiltered(:)));

% imTargetAllFiltered = 0.4 * imTargetHFiltered + 0.6 * imTargetRFiltered;
% imTargetAllFilteredNorm = imTargetAllFiltered/max(imTargetAllFiltered(:));

% figure();
% imshow(imTargetAllFilteredNorm);

% [~, maxIndex] = max(imTargetAllFilteredNorm(:));
% [rowId, colId] = ind2sub(size(imTargetAllFilteredNorm), maxIndex);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% detect harris corners in the filtered image 
% imTargetHFilteredBW = imTargetHFiltered;
% imTargetHFilteredBW(imTargetHFiltered > 0) = 1;

% imTargetHFilteredBWThin = bwmorph(imTargetHFilteredBW,'thin',inf);

% C = corner(imTargetHFilteredBWThin,'harris', 20);

% g2 = figure();
% g2Axes = axes('Parent', g2);
% imshow(imTargetHFilteredBWThin, 'Parent', g2Axes);
% hold(g2Axes, 'on');
% plot(C(:,1), C(:,2), 'ro', 'Parent', g2Axes);


