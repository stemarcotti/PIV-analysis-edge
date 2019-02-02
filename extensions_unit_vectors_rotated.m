% input
% cell_track_(output_name).mat > path
% unit_vector_all_ext_(output_name).mat > resultant_all_ext
% unit_vector_largest_ext_(output_name).mat > resultant_largest_ext

track_diff = [diff(path(:,1)) diff(path(:,2))];
nt = size(track_diff,1);

% make unit vector track_diff
track_diff_unit = zeros(nt,2);
for k = 1:nt
    track_diff_unit(k,:) = track_diff(k,:)./norm(track_diff(k,:));
end

%%
% rotate vectors to direction of motion
theta = zeros(nt,1);
theta_a = zeros(nt,1);
theta_l = zeros(nt,1);
track_diff_unit_rotated = zeros(nt,2);
resultant_all_ext_rotated = zeros(nt,2);
resultant_largest_ext_rotated = zeros(nt,2);

for k = 1:nt
    
    % track diff unit vector
    x_t = track_diff_unit(k,1);
    y_t = track_diff_unit(k,2);
    % all ext unit vector
    x_a = resultant_all_ext(k,1);
    y_a = resultant_all_ext(k,2);
    % largest ext unit vector
    x_l = resultant_largest_ext(k,1);
    y_l = resultant_largest_ext(k,2);
    
    % calculate rotation angle
    theta(k,1) = atan2d(y_t, x_t);
    theta_a(k,1) = atan2d(y_a, x_a);
    theta_l(k,1) = atan2d(y_l, x_l);
    
    % track diff unit vector rotated to horizontal
    x1_t = x_t*cosd(-theta(k,1)) - y_t*sind(-theta(k,1));
    y1_t = x_t*sind(-theta(k,1)) + y_t*cosd(-theta(k,1));
    % all ext unit vector rotated to horizontal
    x1_a = x_a*cosd(-theta(k,1)) - y_a*sind(-theta(k,1));
    y1_a = x_a*sind(-theta(k,1)) + y_a*cosd(-theta(k,1));
    % largest ext unit vector rotated to horizontal
    x1_l = x_l*cosd(-theta(k,1)) - y_l*sind(-theta(k,1));
    y1_l = x_l*sind(-theta(k,1)) + y_l*cosd(-theta(k,1));
    
    track_diff_unit_rotated(k,:) = [x1_t y1_t];
    resultant_all_ext_rotated(k,:) = [x1_a y1_a];
    resultant_largest_ext_rotated(k,:) = [x1_l y1_l];
    
end

%% SAVE %%
save(fullfile(d, 'data', ...
['theta_rotation_track_diff', output_name,'.mat']), ...
'theta');

save(fullfile(d, 'data', ...
['theta_all_to_normalised_motion_', output_name,'.mat']), ...
'theta_a');

save(fullfile(d, 'data', ...
['theta_largest_to_normalised_motion_', output_name,'.mat']), ...
'theta_l');

save(fullfile(d, 'data', ...
['track_diff_unit_rotated', output_name,'.mat']), ...
'track_diff_unit_rotated');

save(fullfile(d, 'data', ...
['resultant_all_ext_rotated', output_name,'.mat']), ...
'resultant_all_ext_rotated');

save(fullfile(d, 'data', ...
['resultant_largest_ext_rotated', output_name,'.mat']), ...
'resultant_largest_ext_rotated');