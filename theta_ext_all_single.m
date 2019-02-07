%% load parent folder %%

warning off

uiwait(msgbox('Load parent folder'));
parent_d = uigetdir('');

matlab_folder = cd;
cd(parent_d)
listing = dir('**/cb*_m.tif');
cd(matlab_folder)

mu2px = 0.1;

%% open one file at a time and perform analysis %%

n_files = length(listing);

for file_list = 1:n_files
    
    % file and directory name
    file = listing(file_list).name;
    directory = listing(file_list).folder;
    
    % output name and cell ID
    slash_indeces = strfind(directory,'/');
    output_name = directory(slash_indeces(end)+1:end);
    cell_ID = str2double(output_name(1:2));
    
    % load
    track = load(fullfile([directory '/data'], ['cell_track_', output_name, '.mat']));
    track = track.path;     % [um]
    track_diff = [diff(track(:,1)) diff(track(:,2))];
    
    track_px = track ./ mu2px;
    track_px(end,:) = [];
    
    nt = size(track_diff,1);
    
    % make unit vector track_diff
    track_diff_unit = zeros(nt,2);
    for k = 1:nt
        track_diff_unit(k,:) = track_diff(k,:)./norm(track_diff(k,:));
    end
    
    all_ext_single = load(fullfile([directory '/data'], ['unit_vector_all_ext_single_vectors_', output_name, '.mat']));
    all_ext_single = all_ext_single.resultant_ext;
    
    % ALL EXTENSIONS
    theta_a = [];
    for k = 1:nt
        
        all_ext_temp = all_ext_single(k).resultant;
        nt_temp = size(all_ext_temp,1);
        
        for kk = 1:nt_temp
            
            % track diff unit vector
            x_t = track_diff_unit(k,1);
            y_t = track_diff_unit(k,2);
            % primary sink unit vector
            x_a = all_ext_temp(kk,1);
            y_a = all_ext_temp(kk,2);
            
            % calculate rotation angle
            theta = atan2d(y_t, x_t);
            % all ext unit vector rotated to horizontal
            x1_a = x_a*cosd(-theta) - y_a*sind(-theta);
            y1_a = x_a*sind(-theta) + y_a*cosd(-theta);
            
            theta_a_temp = atan2d(y1_a, x1_a);  % [degrees]
            theta_a = [theta_a; theta_a_temp];
            
        end
        
        clear all_ext_temp
    end
    save([directory '/data/theta_all_ext_single_vectors_to_direction_motion_' output_name '.mat'], 'theta_a')
    
    clear track track_diff track_px
    clear all_ext_single
    
end

clear; clc