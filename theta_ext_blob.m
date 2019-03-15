%% load parent folder %%

warning off

uiwait(msgbox('Load parent folder'));
parent_d = uigetdir('');

matlab_folder = cd;
cd(parent_d)
listing = dir('**/cb*_m.tif');
cd(matlab_folder)

% ask the user for an ouput stamp
prompt = {'Pixel length [um]'};
title = 'Parameters';
dims = [1 35]; % set input box size
user_answer = inputdlg(prompt,title,dims); % get user answer
mu2px = str2double(user_answer{1,1});

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
    
    nt = size(track_diff,1);
    
    % make unit vector track_diff
    track_diff_unit = zeros(nt,2);
    for k = 1:nt
        track_diff_unit(k,:) = track_diff(k,:)./norm(track_diff(k,:));
    end
    
    coord_all_ext = load(fullfile([directory '/data'], ['coord_all_ext_blob_', output_name, '.mat']));
    coord_all_ext = coord_all_ext.coord_all_ext;
    coord_largest_ext = load(fullfile([directory '/data'], ['coord_largest_ext_blob_', output_name, '.mat']));
    coord_largest_ext = coord_largest_ext.coord_largest_ext;
    
    % LARGEST EXTENSION
    % make unit vector
    track_px = track ./ mu2px;
    track_px(end,:) = [];
    
    centroid_to_largest_ext = [coord_largest_ext(:,1)-track_px(:,1) coord_largest_ext(:,2)-track_px(:,2)];
    largest_ext_unit = zeros(nt,2);
    for k = 1:nt
        largest_ext_unit(k,:) = centroid_to_largest_ext(k,:) ./ norm(centroid_to_largest_ext(k,:));
    end
    save([directory '/data/unit_vector_largest_ext_blob_' output_name '.mat'], 'largest_ext_unit')
    
    % rotate to direction of motion and save theta_l
    theta_l = zeros(nt,1);
    largest_ext_rotated = zeros(nt,2);
    
    for k = 1:nt
        
        % track diff unit vector
        x_t = track_diff_unit(k,1);
        y_t = track_diff_unit(k,2);
        % primary sink unit vector
        x_l = largest_ext_unit(k,1);
        y_l = largest_ext_unit(k,2);
        
        % calculate rotation angle
        theta = atan2d(y_t, x_t);
        % track diff unit vector rotated to horizontal
        x1_t = x_t*cosd(-theta) - y_t*sind(-theta);
        y1_t = x_t*sind(-theta) + y_t*cosd(-theta);
        % all ext unit vector rotated to horizontal
        x1_l = x_l*cosd(-theta) - y_l*sind(-theta);
        y1_l = x_l*sind(-theta) + y_l*cosd(-theta);
        theta_l(k,1) = atan2d(y1_l, x1_l);  % [degrees]
        largest_ext_rotated(k,:) = [x1_l y1_l];
    end
    save([directory '/data/resultant_largest_ext_blob_rotated_' output_name '.mat'], 'largest_ext_rotated')
    save([directory '/data/theta_largest_ext_blob_to_direction_motion_' output_name '.mat'], 'theta_l')
    
    % ALL EXTENSIONS
    theta_a = [];
    for k = 1:nt
        
        coord_all_ext_temp = coord_all_ext(k).position;
        nt_temp = size(coord_all_ext_temp,1);
        
        for kk = 1:nt_temp
            
            vec = [coord_all_ext_temp(kk,1)-track_px(k,1) coord_all_ext_temp(kk,2)-track_px(k,2)];
            vec_unit = vec ./ norm(vec);
            
            % track diff unit vector
            x_t = track_diff_unit(k,1);
            y_t = track_diff_unit(k,2);
            % primary sink unit vector
            x_a = vec_unit(1,1);
            y_a = vec_unit(1,2);
            
            % calculate rotation angle
            theta = atan2d(y_t, x_t);
            % all ext unit vector rotated to horizontal
            x1_a = x_a*cosd(-theta) - y_a*sind(-theta);
            y1_a = x_a*sind(-theta) + y_a*cosd(-theta);
            
            theta_a_temp = atan2d(y1_a, x1_a);  % [degrees]
            theta_a = [theta_a; theta_a_temp];
            
        end
        
        clear coord_all_ext_temp
    end
    save([directory '/data/theta_all_ext_blob_to_direction_motion_' output_name '.mat'], 'theta_a')
    
    clear track track_diff track_px
    clear coord_all_ext coord_largest_ext
    clear centroid_to_largest_ext
    
end

clear; clc