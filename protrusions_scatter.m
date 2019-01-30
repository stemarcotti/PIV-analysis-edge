%% INPUT %%

% get the file directory
uiwait(msgbox('Load cell movie folder'));
d = uigetdir('');
warning off

% ask the user for an ouput stamp
prompt = {'Provide a name for the output files',...
    'Movie ID (n) if file format is cb_(n)_m.tif',...
    'Pixel size [um]',...
    'Frame interval [s]'};
title = 'Parameters';
dims = [1 35]; % set input box size
user_answer = inputdlg(prompt,title,dims); % get user answer
output_name = (user_answer{1,1});
cell_ID = str2double(user_answer{2,1});
mu2px = str2double(user_answer{3,1});           % pixel size [um]
recording_speed = str2double(user_answer{4,1});	% recording speed (frame interval [s])
recording_speed_min = recording_speed/60;       % recording speed (frame interval [min])

file = sprintf('/cb%d_m.tif', cell_ID);
nt = length(imfinfo(strcat(d, file)));

dilationSize = 4;
erosionSize = 4;
connectivityFill = 4;

%% %%
for k = 1:nt-1
    
    currentFrame = double(imread([d '/' file],k))/255;
    nextFrame = double(imread([d '/' file],k+1))/255;
    
    cellOutline1 = detectObjectBw(currentFrame, dilationSize, erosionSize, connectivityFill);
    cellOutline2 = detectObjectBw(nextFrame, dilationSize, erosionSize, connectivityFill);
    
    im_diff = cellOutline2 - cellOutline1; % 0 if images are the same; -1 if retraction; +1 extension
    
    retr_mask = im_diff == -1;
    ext_mask = im_diff == 1;
    
    [xr, yr] = find(retr_mask == 1);
    [xe, ye] = find(ext_mask == 1);
    
    imshow(currentFrame, [])
    hold on
    scatter(yr, xr, 'm.')
    scatter(ye, xe, 'y.')
    hold off
    
    % get current frame for save
    im_out = getframe(gcf);
    im_out = im_out.cdata;
    
    % save .tif stack
    imwrite(im_out, fullfile([d '/images'], ['ext_retr_', output_name, '.tif']), ...
        'writemode', 'append');
end