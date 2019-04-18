%% load parent folder %%

warning off

uiwait(msgbox('Load parent folder'));
parent_d = uigetdir('');

matlab_folder = cd;
cd(parent_d)
listing = dir('**/cb*_m.tif');
cd(matlab_folder)

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
    mu2px = 0.1;
    track = load(fullfile([directory '/data'], ['cell_track_', output_name, '.mat']));
    track = track.path ./ mu2px;     % [px]
    track_diff = [diff(track(:,1)) diff(track(:,2))];
    
    nt = length(imfinfo([directory,'/', file]));
    
    coord_largest_ext = zeros(nt-1,2);
    
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
        ext(ext < 0) = 0; % get only extension from im_diffext_label = bwlabel(ext);
        retr = im_diff;
        retr(retr > 0) = 0; % get only extension from im_diff
        
        ext_label = bwlabel(ext);
        data_ext = regionprops(ext_label,'Centroid','Area');
        data_area_ext = [data_ext(:).Area];
        [~, idx_max_ext] = max(data_area_ext(:));
        max_ext = ext_label == idx_max_ext;
        [x_ext, y_ext] = find(max_ext ~= 0);
        
        retr_label = bwlabel(retr);
        data_retr = regionprops(retr_label,'Centroid','Area');
        data_area_retr = [data_retr(:).Area];
        [~, idx_max_retr] = max(data_area_retr(:));
        max_retr = retr_label == idx_max_retr;
        [x_retr, y_retr] = find(max_retr ~= 0);
        
        imshow(currentFrame, [])
        hold on
        plot(y_ext, x_ext, 'g.')
        plot(y_retr, x_retr, 'm.')
        quiver(track(kk,1), track(kk,2), 10*track_diff(kk,1), 10*track_diff(kk,2), 'm')
         
        im_out = getframe(gcf);
        im_out = im_out.cdata;
        % save .tif stack of convergence map
        imwrite(im_out, fullfile(directory, ['/images/scatter_blobs_dir_motion_' output_name '.tif']), ...
            'writemode', 'append');
        
        
    end
end
