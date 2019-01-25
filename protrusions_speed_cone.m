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

% load protrusion vectors
protrusion_vector = load(fullfile([d '/data'], ['protrusion_vectors_', output_name, '.mat']));
extensions = protrusion_vector.protrusion;
normals = protrusion_vector.normals;
edge = protrusion_vector.smoothedEdge;

% load cell tracking
track = load(fullfile([d '/data'], ['cell_track_', output_name, '.mat']));
track = track.path;     % [um]
track = track ./ mu2px; % [px]

track_diff = [diff(track(:,1)) diff(track(:,2))]; % distance between subsequent frames [px]

% parameters
theta = 15;	% cone: +/- the direction of travel [degrees]
cone_size = cosd(theta); % cosine of theta [degrees]

nt = length(extensions);

%% PROTRUSIONS SPEED IN CONE %%

ext_cone_speed_mean = zeros(nt,1);
retr_cone_speed_mean = zeros(nt,1);

for k = 1:nt
    
    % save temp vars for this frame
    ext_temp = extensions{k,1};
    norm_temp = normals{k,1};
    edge_temp = edge{k,1};
    
    nt_temp = length(ext_temp);
    ext_cone = [];
    retr_cone = [];
    
    for jj = 1:nt_temp
        
        % define vector from track to edge
        centroid_to_edge = [edge_temp(jj,1)-track(k,1) edge_temp(jj,2)-track(k,2)];
        
        % find angles
        xyp = [ext_temp(jj,1) ext_temp(jj,2)];
        xyn = [norm_temp(jj,1) norm_temp(jj,2)];
        
        costheta_protrusions = dot(xyp,xyn) ./ (norm(xyp) .* norm(xyn));
        costheta_cone = dot(centroid_to_edge, track_diff(k,:)) ./ (norm(centroid_to_edge) .* norm(track_diff(k,:)));
        
        % find extensions/retractions inside the cone
        if costheta_cone >= cone_size	% inside cone
            
            if costheta_protrusions > 0
                ext_cone = [ext_cone; ...
                    ext_temp(jj,1), ext_temp(jj,2), edge_temp(jj,1), edge_temp(jj,2)];
                
            elseif costheta_protrusions < 0
                retr_cone = [retr_cone; ...
                    ext_temp(jj,1), ext_temp(jj,2), edge_temp(jj,1), edge_temp(jj,2)];
                
            end
        end

    end
    
    if isempty(ext_cone) == 0
        ext_cone_mag = hypot(ext_cone(:,1), ext_cone(:,2));                 % [px]
        ext_cone_speed = (ext_cone_mag .* mu2px) ./ recording_speed_min;	% [um/min]
        
        ext_cone_speed_mean(k,1) = nanmean(ext_cone_speed);	% [um/min]
    end
    
    if isempty(retr_cone) == 0
        retr_cone_mag = hypot(retr_cone(:,1), retr_cone(:,2));              % [px]
        retr_cone_speed = (retr_cone_mag .* mu2px) ./ recording_speed_min;	% [um/min]
        
        retr_cone_speed_mean(k,1) = -nanmean(retr_cone_speed);	% [um/min]  % - sign because it's retraction
    end
    
    clear ext_temp norm_temp edge_temp
    clear ext_cone_mag ext_cone_speed
    clear retr_cone_mag retr_cone_speed
    
end

%% SAVE %%
save(fullfile(d, 'data', ...
['extensions_cone_speed_mean_', output_name,'.mat']), ...
'ext_cone_speed_mean');

save(fullfile(d, 'data', ...
['retractions_cone_speed_mean_', output_name,'.mat']), ...
'retr_cone_speed_mean');

clear