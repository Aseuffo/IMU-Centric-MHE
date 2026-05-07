function importedInterface = importSlkModels()

%% Save to current version
% put here all models you want to import from a previous version
mdl_names = {'interface', 'bicycle'};
% put here which particular previous version you want to import from
base_rel = 'R2024a';
rel = version('-release');

if strcmp(['R' rel], base_rel)
    disp(['Working on base release ' base_rel '.']);
    importedInterface = false;
else
    disp(['Working on release R' rel '. ' ...
        'Simulink models will be imported.'])
    % pick your baseline previous release
    for i=1:length(mdl_names)
        mdl_names{i} = [mdl_names{i} '_' base_rel];
    end
    importedInterface = true;
    for i=1:length(mdl_names)
        import = false;
        % import if model doesn't exist yet
        if ~(exist([mdl_names{i}(1:end-7) '_R' rel '.mdl'], 'file'))
            import = true;
        end
        if import
            filePath = which(mdl_names{i});
            currentPath = cd(fileparts(filePath));
            load_system(mdl_names{i})
            close_system([mdl_names{i}(1:end-7) '_R' rel],0)
            save_system(mdl_names{i},[mdl_names{i}(1:end-7) '_R' rel '.mdl'])
            close_system([mdl_names{i}(1:end-7) '_R' rel])
            cd(currentPath)
            disp(['Model ' mdl_names{i}(1:end-7) '_R' rel ...
                ' has been imported correctly.'])
        else
            disp(['Model ' mdl_names{i}(1:end-7) '_R' rel ...
                ' has NOT been imported. If you want to import it, ' ...
                'delete ' [mdl_names{i}(1:end-7) '_R' rel] '.mdl before.'])
           if strcmp('interface', mdl_names{i})
               importedInterface = false;
           end
        end
    end
end