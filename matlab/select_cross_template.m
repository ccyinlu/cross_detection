% select the cross_template

clear all;
close all;
clc;

global cross_template_width;
global cross_template_height;
cross_template_width = 64;
cross_template_height = 64;

% open a file selector to select the sample image
fprintf('select the sample image to generate the cross_template\n');
global current_dir;
current_dir = pwd();

[FileName, PathName] = uigetfile('*.*', 'load the sample image with red cross', current_dir);
if isequal(FileName, 0)
    fprintf('user selected cancel');
    return;
else
    fprintf('user selected: %s', [PathName FileName]);
end

% read the sample image
global sample_image;
sample_image = imread([PathName FileName]);

imHandle = imshow(sample_image);

imHandle.ButtonDownFcn = @onButtonDownFcn;

function onButtonDownFcn(src, callbackdata)
    axesHandle = get(src,'Parent'); 
    coordinates = get(axesHandle,'CurrentPoint'); 
    cur_coordinates = round(coordinates(1,1:2));

    % crop the image
    global sample_image;
    global cross_template_width;
    global cross_template_height;
    cross_template = sample_image(cur_coordinates(2) - cross_template_width/2 + 1: cur_coordinates(2) + cross_template_width/2, ...
                                    cur_coordinates(1) - cross_template_height/2 + 1: cur_coordinates(1) + cross_template_height/2, ...
                                    :);

    figure();
    imshow(cross_template);

    global current_dir;
    [FileName, PathName] = uigetfile('*.*', 'select the filename to save the cross_template', current_dir);
    if isequal(FileName, 0)
        fprintf('user selected cancel');
        return;
    else
        fprintf('user selected: %s', [PathName FileName]);
    end

    imwrite(cross_template, [PathName FileName]);

end  % ButtonDownFcn