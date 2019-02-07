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
    res_ext = zeros(length(measurements_p),2);
    for ii = 1:length(measurements_p)
        ext_length = measurements_p(ii).Area;
        ext_centre = measurements_p(ii).Centroid(2);
        
        ext_temp = protrusions(ceil(ext_centre - ext_length/2):floor(ext_centre + ext_length/2),:);
        res_ext_temp = [sum(ext_temp(:,1)) sum(ext_temp(:,2))];
        res_ext_temp = res_ext_temp/norm(res_ext_temp); % unit vector
        
        res_ext(ii,:) = res_ext_temp;
    end
    
    resultant_ext(k).resultant = res_ext;
    
    clear ext_temp norm_temp edge_temp
    clear mask measurements_p
    
end

%% SAVE %%
save([d '/data/unit_vector_all_ext_single_vectors_' output_name '.mat'], 'resultant_ext')

clear
