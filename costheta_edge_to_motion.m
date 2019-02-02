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

% load ext coordinates
unit_vector_all_ext = load(fullfile([d '/data'], ['unit_vector_all_ext_', output_name, '.mat']));
unit_vector_all_ext = unit_vector_all_ext.resultant_all_ext;
unit_vector_largest_ext = load(fullfile([d '/data'], ['unit_vector_largest_ext_', output_name, '.mat']));
unit_vector_largest_ext = unit_vector_largest_ext.resultant_largest_ext;

% load cell tracking
track = load(fullfile([d '/data'], ['cell_track_', output_name, '.mat']));
track = track.path;     % [um]

track_diff = [diff(track(:,1)) diff(track(:,2))]; % distance between subsequent frames [px]

% parameters
nt = length(track_diff);

%% %%
costheta_largest_ext = zeros(nt,1);
costheta_all_ext = zeros(nt,1);

for k = 1:nt
    
    costheta_largest_ext(k,1) = dot(unit_vector_largest_ext(k,:), track_diff(k,:)) ./...
        (norm(unit_vector_largest_ext(k,:)) * norm(track_diff(k,:)));
    
    costheta_all_ext(k,1) = dot(unit_vector_all_ext(k,:), track_diff(k,:)) ./...
        (norm(unit_vector_all_ext(k,:)) * norm(track_diff(k,:)));
    
end


save(fullfile(d, 'data', ...
['costheta_largest_ext', output_name,'.mat']), ...
'costheta_largest_ext');

save(fullfile(d, 'data', ...
['costheta_all_ext', output_name,'.mat']), ...
'costheta_all_ext');

