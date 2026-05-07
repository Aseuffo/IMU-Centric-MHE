function exportSlkModels()

%% Save to previous version
% put here all models you want to export to a previous version
mdl_names = {'interface', 'bicycle'};
% put here all previous versions you want to make available
prev_rel = {'R2023b'};

% add to path external models folders
addpath('filters/')

% pick your current release
rel = version('-release');
for i=1:length(mdl_names)
    mdl_names{i} = [mdl_names{i} '_R' rel];
end
for i=1:length(mdl_names)
    filePath = which(mdl_names{i});
    currentPath = cd(fileparts(filePath));
    load_system(mdl_names{i})
    for ii=1:length(prev_rel)
        Simulink.exportToVersion(mdl_names{i}, ...
            [mdl_names{i}(1:end-7) '_' prev_rel{ii}], ...
            [prev_rel{ii} '_MDL']);
    end
    cd(currentPath);
end