%% INPUT %%

% get the file directory
uiwait(msgbox('Load cell movie folder'));
d = uigetdir('');
warning off

% ask the user for an ouput stamp
prompt = {'Provide a name for the output files'};
title = 'Parameters';
dims = [1 35]; % set input box size
user_answer = inputdlg(prompt,title,dims); % get user answer
output_name = (user_answer{1,1});

% load protrusion vectors
protrusion_vector = load (fullfile ([d '/data'], ['protrusion_vectors_', output_name, '.mat']));
extensions = protrusion_vector.protrusion;
normals = protrusion_vector.normals;
smoothed_edge = protrusion_vector.smoothedEdge;

% load cell tracking
track = load(fullfile([d '/data'], ['cell_track_', output_name, '.mat']));
track = track.path;     % [um]

track_diff = [diff(track(:,1)) diff(track(:,2))]; % distance between subsequent frames [px]

nt = length(extensions);

%% LARGEST AND ALL EXTENSIONS SPEED %%

unit_largest_resultant = zeros(nt,2);
unit_all_ext_resultant = zeros(nt,2);

for k = 1:nt
    
    % save temp vars for this frame
    ext_temp = extensions{k,1};
    norm_temp = normals{k,1};
    edge_temp = smoothed_edge{k,1};
    
    nt_temp = length(ext_temp);
    protrusions = zeros(nt_temp, 4);
    
    % for each point on the edge
    for jj = 1:nt_temp
        
        xyp = [ext_temp(jj,1) ext_temp(jj,2)];
        xyn = [norm_temp(jj,1) norm_temp(jj,2)];
        
        xyp = xyp./norm(xyp);
        xyn = xyn./norm(xyn);
        
        costheta = dot(xyp,xyn) ./ (norm(xyp) .* norm(xyn));
        
        if costheta > 0     % protrusion
            
            protrusions(jj,1) = ext_temp(jj,1);
            protrusions(jj,2) = ext_temp(jj,2);
            protrusions(jj,3) = edge_temp(jj,1);
            protrusions(jj,4) = edge_temp(jj,2);
   
        end
    end
    
    % find extensions (protrusions ~= 0)
    mask = logical(protrusions(:,1));
    
    % find largest extension resultant
    measurements_p = regionprops(logical(mask), 'Area', 'Centroid');
    largest_ext_idx = find([measurements_p.Area] == max([measurements_p.Area]));
    largest_ext_idx = largest_ext_idx(1,1);
    
    largest_ext_length = measurements_p(largest_ext_idx).Area;
    largest_ext_centre = measurements_p(largest_ext_idx).Centroid(2);
    
    idx1 = ceil(largest_ext_centre - largest_ext_length/2);
    idx2 = floor(largest_ext_centre + largest_ext_length/2);
    largest = protrusions(idx1:idx2,:);
    
    largest_resultant = [sum(largest(:,1)) sum(largest(:,2))];
    unit_largest_resultant(k,:) = largest_resultant ./ (norm(largest_resultant));
    
    % all extensions
    all_resultant = [sum(protrusions(:,1)) sum(protrusions(:,2))];
    unit_all_ext_resultant(k,:) = all_resultant ./ (norm(all_resultant));
    
    for kk = 1:length(measurements_p)

        ext_length = measurements_p(kk).Area;
        ext_centre = measurements_p(kk).Centroid(2);
        
        idx1_temp = ceil(ext_centre - ext_length/2);
        idx2_temp = floor(ext_centre + ext_length/2);
        ext_temp = protrusions(idx1_temp:idx2_temp,:);
        
        ext_temp_resultant = [sum(ext_temp(:,1)) sum(ext_temp(:,2))];
        unit_all_ext_resultant_single(k).unit(kk,:) = ext_temp_resultant ./ (norm(ext_temp_resultant));
    
    end
    
    clear ext_temp norm_temp edge_temp
    clear protrusions mask measurements_p
    clear largest largest_resultant
    clear all_resultant
    clear ext_temp ext_temp_resultant
end

%% calculate costheta resultants with direction of motion %%

costheta_largest_ext_resultant = zeros(nt,1);
costheta_all_ext_resultant = zeros(nt,1);
costheta_all_ext_resultant_single = [];

for k = 1:nt
    
    costheta_largest_ext_resultant(k,1) = dot(unit_largest_resultant(k,:), track_diff(k,:)) ./...
        (norm(unit_largest_resultant(k,:)) * norm(track_diff(k,:)));
    
    costheta_all_ext_resultant(k,1) = dot(unit_all_ext_resultant(k,:), track_diff(k,:)) ./...
        (norm(unit_all_ext_resultant(k,:)) * norm(track_diff(k,:)));
    
    temp = unit_all_ext_resultant_single(k).unit;
    for kk = 1:size(temp,1)
        
        costheta_all_ext_resultant_single = [costheta_all_ext_resultant_single; ...
            dot(temp(kk,:), track_diff(k,:)) ./ (norm(temp(kk,:)) * norm(track_diff(k,:)))];
        
    end
    clear temp
    
end

%% SAVE %%

save(fullfile(d, 'data', ...
['costheta_largest_ext_vectors_resultant_', output_name,'.mat']), ...
'costheta_largest_ext_resultant');

save(fullfile(d, 'data', ...
['costheta_all_ext_resultant_vectors_resultant_', output_name,'.mat']), ...
'costheta_all_ext_resultant');

save(fullfile(d, 'data', ...
['costheta_all_ext_resultant_single_vectors_resultant_', output_name,'.mat']), ...
'costheta_all_ext_resultant_single');

clear