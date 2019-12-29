% clear 
clear;
clc;
close all;

crop_params = [450 1; 720 1080];

% read the template cross object
cross_template_file = '../data/cross_template_edited.png';
% cross_template_file = '../data/cross_template.png';
test_sample_file = '../data/sample_full.png';

cross_tempate = imread(cross_template_file);
% cross_tempate_hsv = [0.01389 0.3226 0.7294];
% cross_tempate_rgb = [193 146 141];

cross_tempate_hsv = rgb2hsv(cross_tempate);
global cross_template_hsv_hist;
cross_template_hsv_hist = imhist((cross_tempate_hsv));

global cross_tempate_rgb;
cross_tempate_rgb = cross_tempate;

test_sample = imread(test_sample_file);

% crop the test_sample
test_sample_cropped = test_sample(crop_params(1,1):crop_params(2,1), crop_params(1,2):crop_params(2,2), :);
test_sample_hsv = rgb2hsv(test_sample_cropped);
test_sample_rgb = test_sample_cropped;

% just for test
% global test_center_row;
% test_center_row = 169;
% global test_center_col;
% test_center_col = 403;
% cross_tempate_rgb = test_sample_rgb(test_center_row-32 + 1 : test_center_row+32, test_center_col-32 + 1: test_center_col+32, :);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % matching the image according to the rgb imhist
% params = struct();
% params.stride = struct();
% params.stride.x = 1;
% params.stride.y = 1;
% colorHistMatchingScores = colorHistMatching(cross_tempate, test_sample_cropped, params);
% figure();
% imshow(colorHistMatchingScores/max(colorHistMatchingScores(:)));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% matching the image according to the rgb imhist
% % test_sample_hsv = rgb2hsv(test_sample_cropped);
% test_sample_rgb = test_sample_cropped;
% test_sample_cropped_width = size(test_sample_cropped, 2);
% test_sample_cropped_height = size(test_sample_cropped, 1);
% colorHistMatchingScores = zeros(test_sample_cropped_height, test_sample_cropped_width);
% for i = 1:test_sample_cropped_height
%     for j = 1 : test_sample_cropped_width
%         % colorHistMatchingScores(i, j) = 1- pdist([cross_tempate_hsv; [test_sample_hsv(i, j, 1) test_sample_hsv(i, j, 2) test_sample_hsv(i, j, 3)]], 'cosine');
%         colorHistMatchingScores(i, j) = 1- pdist([cross_tempate_rgb; [test_sample_rgb(i, j, 1) test_sample_rgb(i, j, 2) test_sample_rgb(i, j, 3)]], 'cosine');
%     end
% end
% figure();
% imshow(colorHistMatchingScores);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % matching the image according to the block matching, L1 loss
% params = struct();
% params.stride = struct();
% params.stride.x = 1;
% params.stride.y = 1;
% blockL1MatchingScores = blockL1Matching(cross_tempate, test_sample_cropped, params);
% figure();
% % imshow(blockL1MatchingScores);
% imshow(blockL1MatchingScores/max(blockL1MatchingScores(:)));

% [~, maxIndex] = max(blockL1MatchingScores(:));
% [rowId, colId] = ind2sub(size(blockL1MatchingScores), maxIndex);

% g2 = figure();
% g2Axes = axes('Parent', g2);
% imshow(rgb2hsv(test_sample_cropped), 'Parent', g2Axes);
% % hold(g2Axes, 'on');
% % plot(test_center_col, test_center_row, 'b*', 'Parent', g2Axes);
% hold(g2Axes, 'on');
% plot(colId, rowId, 'ro', 'Parent', g2Axes);

% figure();
% imshow(rgb2hsv(cross_tempate_rgb));


% test_sample_cropped_hsv = rgb2hsv(test_sample_cropped);
% figure();
% imshow(test_sample_cropped_hsv(:, :, 1));
% figure();
% imshow(test_sample_cropped_hsv(:, :, 2));
% figure();
% imshow(test_sample_cropped_hsv(:, :, 3));

cross_tempate_rgb_hsv = rgb2hsv(cross_tempate_rgb);
figure();
imshow(cross_tempate_rgb_hsv(:, :, 1));
figure();
imshow(cross_tempate_rgb_hsv(:, :, 2));
figure();
imshow(cross_tempate_rgb_hsv(:, :, 3));


function colorHistMatchingScores = colorHistMatching(imTemplate, imTarget, params)
    window_stride = params.stride;

    imTemplateWidth = size(imTemplate, 2);
    imTemplateHeight = size(imTemplate, 1);

    imTargetWidth = size(imTarget, 2);
    imTargetHeight = size(imTarget, 1);

    colorHistMatchingScores = zeros(imTargetHeight, imTargetWidth);

    idx = imTemplateWidth/2 : window_stride.x : imTargetWidth - imTemplateWidth/2;
    idy = imTemplateHeight/2 : window_stride.y : imTargetHeight - imTemplateHeight/2;

    for i = 1 : length(idx)
        for j = 1 : length(idy)
            window_center_x = idx(i);
            window_center_y = idy(j);
            current_patch = imTarget(window_center_y - imTemplateHeight/2 + 1 : window_center_y + imTemplateHeight/2, window_center_x - imTemplateWidth/2 + 1 : window_center_x + imTemplateWidth/2, :);
            current_patch_hsv_hist = imhist((current_patch));
            global cross_template_hsv_hist;
            colorHistMatchingScores(window_center_y, window_center_x) = pdist([current_patch_hsv_hist'; cross_template_hsv_hist'], 'cosine');
        end
    end

end

function blockL1MatchingScores = blockL1Matching(imTemplate, imTarget, params)
    window_stride = params.stride;

    imTemplateWidth = size(imTemplate, 2);
    imTemplateHeight = size(imTemplate, 1);

    imTargetWidth = size(imTarget, 2);
    imTargetHeight = size(imTarget, 1);

    blockL1MatchingScores = zeros(imTargetHeight, imTargetWidth);

    idx = imTemplateWidth/2 : window_stride.x : imTargetWidth - imTemplateWidth/2;
    idy = imTemplateHeight/2 : window_stride.y : imTargetHeight - imTemplateHeight/2;

    for i = 1 : length(idx)
        for j = 1 : length(idy)
            window_center_x = idx(i);
            window_center_y = idy(j);
            current_patch = imTarget(window_center_y - imTemplateHeight/2 + 1 : window_center_y + imTemplateHeight/2, window_center_x - imTemplateWidth/2 + 1 : window_center_x + imTemplateWidth/2, :);
            global cross_tempate_rgb;
            % global test_center_row;
            % global test_center_col;
            % if window_center_x == test_center_col && window_center_x == test_center_row
            %     fprintf('debug here to see the matching results\n');
            % end
            cross_tempate_rgb = rgb2hsv(cross_tempate_rgb);
            current_patch = rgb2hsv(current_patch);
            abs_delta_block = abs(double(cross_tempate_rgb) - double(current_patch));
            abs_delta_block = mean(abs_delta_block, 3);
            blockL1MatchingScores(window_center_y, window_center_x) = sum(abs_delta_block(:))/length(abs_delta_block(:));
            blockL1MatchingScores(window_center_y, window_center_x) = 1/exp(blockL1MatchingScores(window_center_y, window_center_x));
        end
    end

end