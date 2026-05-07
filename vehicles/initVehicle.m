function vehicle = initVehicle(carName)

try
    % Load and validate the vehicle data
    vehicle = loadVehicleData(carName);
    fprintf('Vehicle "%s" loaded.\n', carName);
    
catch ME
    % Termination on error to prevent inconsistent simulation results
    fprintf('CRITICAL ERROR: %s\n', ME.message);
    return; 
end

end

