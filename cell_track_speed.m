%% INPUT %%

% get the file directory
uiwait(msgbox('Load cell movie folder'));
d = uigetdir('');
warning off

% ask the user for an ouput stamp
prompt = {'Provide a name for the output files',...
    'Movie ID (n) if file format is cb_(n)_m.tif',...
    'Frame interval [s]'};
title = 'Parameters';
dims = [1 35]; % set input box size
user_answer = inputdlg(prompt,title,dims); % get user answer
output_name = (user_answer{1,1});
cell_ID = str2double(user_answer{2,1});
recording_speed = str2double(user_answer{3,1});	% recording speed (frame interval [s])
recording_speed_min = recording_speed/60;       % recording speed (frame interval [min])

% load cell tracking
track = load(fullfile([d '/data'], ['cell_track_', output_name, '.mat']));
track = track.path;     % [um]

%% CELL SPEED %%

track_diff = [diff(track(:,1)) diff(track(:,2))]; % distance between subsequent frames [um]
track_mag = hypot(track_diff(:,1), track_diff(:,2)); 
track_speed = track_mag ./ recording_speed_min; % [um/min]

%% SAVE %%

save(fullfile(d, 'data', ...
['cell_track_speed_', output_name,'.mat']), ...
'track_speed');

clear