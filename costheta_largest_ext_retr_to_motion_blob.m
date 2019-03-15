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
    
    nt = length(imfinfo([directory,'/', file]));
    
    coord_largest_ext = zeros(nt-1,2);
    coord_largest_retr = zeros(nt-1,2);
    
    for kk = 1:nt-1
        
        currentFrame = double(imread([directory '/' file],kk))/255;
        nextFrame = double(imread([directory '/' file],kk+1))/255;
        
        imbw1 = edge(currentFrame, 'canny');
        imbw1 = imdilate(imbw1, strel('disk', 4));
        imbw1 = imfill(imbw1, 'holes');
        imbw1 = imerode(imbw1, strel('disk', 4));
        
        imbw2 = edge(nextFrame, 'canny');
        imbw2 = imdilate(imbw2, strel('disk', 4));
        imbw2 = imfill(imbw2, 'holes');
        imbw2 = imerode(imbw2, strel('disk', 4));
        
        im_diff = imbw2 - imbw1; % 0 if images are the same; -1 if retraction; +1 extension
        
        % get extensions
        ext = im_diff;
        ext(ext < 0) = 0; % get only extensions from im_diff
        
        % get retractions
        retr = im_diff;
        retr(retr > 0) = 0; % get only retractions from im_diff
       
        % largest extension (record centroid coordinates)
        data_ext = regionprops(logical(ext),'Centroid','Area');
        data_area_ext = [data_ext(:).Area];
        [~, idx_max_ext] = max(data_area_ext(:));
        coord_largest_ext(kk,1) = data_ext(idx_max_ext).Centroid(1,1);
        coord_largest_ext(kk,2) = data_ext(idx_max_ext).Centroid(1,2);
        
        % largest retraction (record centroid coordinates)
        data_retr = regionprops(logical(retr),'Centroid','Area');
        data_area_retr = [data_retr(:).Area];
        [~, idx_max_retr] = max(data_area_retr(:));
        coord_largest_retr(kk,1) = data_retr(idx_max_retr).Centroid(1,1);
        coord_largest_retr(kk,2) = data_retr(idx_max_retr).Centroid(1,2);
        
    end
    
    % make unit vectors
    track_px = track ./ mu2px;
    track_px(end,:) = [];
    
    centroid_to_largest_ext = [coord_largest_ext(:,1)-track_px(:,1) coord_largest_ext(:,2)-track_px(:,2)];
    largest_ext_unit = zeros(nt-1,2);
    for k = 1:nt-1
        largest_ext_unit(k,:) = centroid_to_largest_ext(k,:) ./ norm(centroid_to_largest_ext(k,:));
    end
    
    centroid_to_largest_retr = [coord_largest_retr(:,1)-track_px(:,1) coord_largest_retr(:,2)-track_px(:,2)];
    largest_retr_unit = zeros(nt-1,2);
    for k = 1:nt-1
        largest_retr_unit(k,:) = centroid_to_largest_retr(k,:) ./ norm(centroid_to_largest_retr(k,:));
    end
    
    % find costheta largest ext/retr to direction of motion 
    costheta_largest_ext = zeros(nt-1,1);
    costheta_largest_retr = zeros(nt-1,1);
    
    for k = 1:nt-1
        
        costheta_largest_ext(k,1) = dot(largest_ext_unit(k,:), track_diff(k,:)) ./...
            (norm(largest_ext_unit(k,:)) * norm(track_diff(k,:)));
        
        costheta_largest_retr(k,1) = dot(largest_retr_unit(k,:), track_diff(k,:)) ./...
            (norm(largest_retr_unit(k,:)) * norm(track_diff(k,:)));
        
    end
    
    save([directory '/data/costheta_largest_ext_blob_' output_name '.mat'], 'costheta_largest_ext')
    save([directory '/data/costheta_largest_retr_blob_' output_name '.mat'], 'costheta_largest_retr')
    
    clear ext retr
    clear data_ext data_area_ext
    clear data_retr data_area_retr
    clear coord_largest_ext coord_largest_retr
    clear track track_diff track_px
    clear centroid_to_largest_ext centroid_to_largest_retr
    clear largest_ext_unit largest_retr_unit
    
end

clear; clc