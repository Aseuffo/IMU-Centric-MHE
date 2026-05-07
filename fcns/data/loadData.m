function log = loadData(logFolder, vehicle_type, vehicle, sim, timeStep)

if nargin < 3
    timeStep = 0.01;
end

% Select data folder
DATA_FOLDER = fullfile(logFolder);

switch vehicle_type
    case 'superformula' 
        loadSuperformulaData
    case 'indylight' 
        loadIndylightData
    case {'ferrari','corvette'}
        loadRevsDataset
    otherwise
        error('Unexpected vehicle type selected.')
end

end
