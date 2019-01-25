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

% load interpolated filed
protrusion_vector = load (fullfile ([d '/data'], ['protrusion_vectors_', output_name, '.mat']));
extensions = protrusion_vector.protrusion;
normals = protrusion_vector.normals;
smoothed_edge = protrusion_vector.smoothedEdge;

nt = length(extensions);

%% LARGEST AND ALL PROTRUSIONS SPEED %%

largest_ext_speed_mean = zeros(nt,1);
all_ext_speed_mean = zeros(nt,1);

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
    
    % find largest extension
    measurements_p = regionprops(logical(mask), 'Area', 'Centroid');
    largest_ext_idx = find([measurements_p.Area] == max([measurements_p.Area]));
    largest_ext_idx = largest_ext_idx(1,1);
    
    largest_ext_length = measurements_p(largest_ext_idx).Area;
    largest_ext_centre = measurements_p(largest_ext_idx).Centroid(2);
    
    largest_ext = protrusions(ceil(largest_ext_centre - largest_ext_length/2):floor(largest_ext_centre + largest_ext_length/2),:);
    
    % largest extension speed
    largest_ext_mag = hypot(largest_ext(:,1), largest_ext(:,2));            % [px]
    largest_ext_speed = (largest_ext_mag .* mu2px) ./ recording_speed_min;	% [um/min]
    
    largest_ext_speed_mean(k,1) = nanmean(largest_ext_speed);	% [um/min]
    
    % find all extensions
    all_ext_idx = find(mask==1);
    all_ext = protrusions(all_ext_idx,:);
    
    all_ext_mag = hypot(all_ext(:,1), all_ext(:,2));        % [px]
    all_ext_speed = (all_ext_mag .* mu2px) ./ recording_speed_min;	% [um/min]
    
    all_ext_speed_mean(k,1) = nanmean(all_ext_speed);
    
    clear ext_temp norm_temp edge_temp
    clear mask measurements_p
    clear largest_ext_idx largest_ext largest_ext_mag largest_ext_speed
    clear all_ext_idx all_ext all_ext_mag all_ext_speed
    
end

%% SAVE %%
save(fullfile(d, 'data', ...
['all_extensions_speed_mean_', output_name,'.mat']), ...
'all_ext_speed_mean');

save(fullfile(d, 'data', ...
['largest_extension_speed_mean_', output_name,'.mat']), ...
'largest_ext_speed_mean');

clear