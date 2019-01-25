%% load parent folder %%

warning off

uiwait(msgbox('Load parent folder'));
parent_d = uigetdir('');

matlab_folder = cd;
cd(parent_d)
listing = dir('**/cb*.tif');
cd(matlab_folder)

dilationSize = 4;
erosionSize = 12;
connectivityFill = 4;

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
    
    nt = length(imfinfo([directory,'/', file]));
    
    coord_largest_ext = zeros(nt-1,1);
    
    for kk = 1:nt-1
        
        currentFrame = double(imread([directory '/' file],kk))/255;
        nextFrame = double(imread([directory '/' file],kk+1))/255;
        
        cellOutline1 = detectObjectBw(currentFrame, dilationSize, erosionSize, connectivityFill);
        cellOutline2 = detectObjectBw(nextFrame, dilationSize, erosionSize, connectivityFill);
        
        im_diff = cellOutline2 - cellOutline1; % 0 if images are the same; -1 if retraction; +1 extension
        
        % get extensions
        ext = im_diff;
        ext(ext < 0) = 0; % get only extension from im_diff
        
        % largest extension (record centroid coordinates)
        data = regionprops(logical(ext),'Centroid','Area');
        data_area = [data(:).Area];
        [~, idx_max] = max(data_area(:));
        coord_largest_ext(kk,1) = data(idx_max).Centroid(1,1);
        coord_largest_ext(kk,2) = data(idx_max).Centroid(1,2);
        
        % all extensions (record centroid coordinates)
        for idx = 1:length(data)
            coord_all_ext(kk).position(idx,1) = data(idx).Centroid(1,1);
            coord_all_ext(kk).position(idx,2) = data(idx).Centroid(1,2);
        end
        
    end
    
    save([directory '/data/coord_largest_ext_' output_name '.mat'], 'coord_largest_ext')
    save([directory '/data/coord_all_ext_' output_name '.mat'], 'coord_all_ext')
    
    clear ext data data_area coord_largest_ext coord_all_ext
end

clear; clc