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

nt = length(extensions);

%% LARGEST AND ALL EXTENSIONS SPEED %%

coord_largest_ext = zeros(nt,2);

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
    
    % largest_ext = protrusions(ceil(largest_ext_centre - largest_ext_length/2):floor(largest_ext_centre + largest_ext_length/2),:);
    largest_ext_centroid = protrusions(ceil(largest_ext_centre),3:4);
    
    coord_largest_ext(k,:) = largest_ext_centroid;
    
    clear ext_temp norm_temp edge_temp
    clear mask measurements_p
    clear largest_ext_idx largest_ext
    
end

%% SAVE %%

save([d '/data/coord_largest_ext_vectors_' output_name '.mat'], 'coord_largest_ext')

clear