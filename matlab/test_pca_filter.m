% clear 
clear;
clc;
close all;

params = struct();
params.HThreshold = 0.2;
params.RThreshold = 0.5;

crop_params = [450 1; 720 1080];

cross_tempate_rgb = [216 141 137]/255.0;

% read the template cross object
cross_template_file = '../data/cross_template_edited.png';
% cross_template_file = '../data/cross_template.png';
% test_sample_file = '../data/sample_full.png';
test_sample_file = '../data/sample4.png';

cross_tempate = imread(cross_template_file);
test_sample = imread(test_sample_file);
test_sample_cropped = test_sample(crop_params(1,1):crop_params(2,1), crop_params(1,2):crop_params(2,2), :);

% cross_tempate_cor = zeros(size(cross_tempate, 1), size(cross_tempate, 2));
% for i = 1 : size(cross_tempate, 1)
%     for j = 1 : size(cross_tempate, 2)
%         current_pixel = [double(cross_tempate(i, j, 1)) double(cross_tempate(i, j, 2)) double(cross_tempate(i, j, 3))]/255.0;
%         cross_tempate_cor(i,j) = (1- acos(dot(current_pixel, cross_tempate_rgb)/(norm(current_pixel)*norm(cross_tempate_rgb)))/1.57)^4;
%     end
% end

% figure();
% imshow(cross_tempate_cor);

% test_sample_cropped_cor = zeros(size(test_sample_cropped, 1), size(test_sample_cropped, 2));
% for i = 1 : size(test_sample_cropped, 1)
%     for j = 1 : size(test_sample_cropped, 2)
%         current_pixel = [double(test_sample_cropped(i, j, 1)) double(test_sample_cropped(i, j, 2)) double(test_sample_cropped(i, j, 3))]/255.0;
%         test_sample_cropped_cor(i,j) = (1- acos(dot(current_pixel, cross_tempate_rgb)/(norm(current_pixel)*norm(cross_tempate_rgb)))/1.57)^4;
%     end
% end

% figure();
% imshow(test_sample_cropped_cor);
cross_tempate_lab = rgb2lab(cross_tempate);
figure();
imshow(cross_tempate_lab(:,:,1));

figure();
imshow(cross_tempate_lab(:,:,2));

figure();
imshow(cross_tempate_lab(:,:,3));

test_sample_cropped_lab = rgb2lab(test_sample_cropped);
figure();
imshow(test_sample_cropped_lab(:,:,1));

figure();
imshow(test_sample_cropped_lab(:,:,2));

figure();
imshow(test_sample_cropped_lab(:,:,3));

figure();
imshow(test_sample_cropped_lab(:,:,1)./test_sample_cropped_lab(:,:,2));