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
protrusion_vector = load (fullfile ([d '/data'], ['protrusion_vectors_', output_name, '.mat']));
extensions = protrusion_vector.protrusion;
normals = protrusion_vector.normals;
smoothed_edge = protrusion_vector.smoothedEdge;

nt = length(extensions);

%% ALL PROTRUSIONS SPEED %%

all_protrusions_speed_mean = zeros(nt,1);

for k = 1:nt
    
    % save temp vars for this frame
    ext_temp = extensions{k,1};
    norm_temp = normals{k,1};
    
    all_protrusions_mag = hypot(ext_temp(:,1), ext_temp(:,2));        % [px]
    all_protrusions_speed = (all_protrusions_mag .* mu2px) ./ recording_speed_min;	% [um/min]
    
    nt_temp = length(ext_temp);
    for jj = 1:nt_temp
        
        xyp = [ext_temp(jj,1) ext_temp(jj,2)];
        xyn = [norm_temp(jj,1) norm_temp(jj,2)];
        
        xyp = xyp./norm(xyp);
        xyn = xyn./norm(xyn);
        
        costheta = dot(xyp,xyn) ./ (norm(xyp) .* norm(xyn));
        
        if costheta < 0
            all_protrusions_speed(jj,1) = -all_protrusions_speed(jj,1);
        end
    end
    
    all_protrusions_speed_mean(k,1) = nanmean(all_protrusions_speed);
    
    clear ext_temp
    clear all_protrusions_mag all_protrusions_speed
    
end

%% SAVE %%
save(fullfile(d, 'data', ...
['all_protrusions_speed_mean_', output_name,'.mat']), ...
'all_protrusions_speed_mean');

clear