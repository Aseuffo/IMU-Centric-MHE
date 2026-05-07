function vehicle = loadVehicleData(carName)
    % Construct the full filename
    fileName = sprintf('%s.json', carName);
    
    % Check if the file exists
    if ~exist(fileName, 'file')
        error('The file "%s" was not found in the current path.', fileName);
    end
    
    % Read and decode the JSON content
    try
        val = fileread(fileName);
        vehicle = jsondecode(val);
    catch
        error('Failed to parse JSON. Check syntax in "%s".', fileName);
    end
    
    % Define mandatory fields and their expected format/suggested values
    % Syntax: { 'FieldPath', 'Suggestion' }
    requiredFields = {
        'geometry.wheelbase', '3.115';
        'physics.mass', '750.0';
        'physics.Jz', '700.0';
        'aerodynamics.rho', '1.225';
        'tires.front.Macroparams', '[-16.17, 1.6, ... (6 elements)]';
        'tires.rear.Macroparams', '[-15.40, 1.5, ... (6 elements)]'
    };
    
    % Perform validation
    validateFields(vehicle, requiredFields);
end

function validateFields(data, requirements)
    for i = 1:size(requirements, 1)
        path = strsplit(requirements{i,1}, '.');
        current = data;
        missing = false;
        
        % Navigate through nested structure
        for j = 1:length(path)
            if isfield(current, path{j})
                current = current.(path{j});
            else
                missing = true;
                break;
            end
        end
        
        % Throw error if a field is missing
        if missing
            error('Missing mandatory parameter: "%s".\nSuggestion: Ensure it exists in JSON with a value like %s.', ...
                  requirements{i,1}, requirements{i,2});
        end
    end
end