
fileInfo = dir(fullfile(logFolder, '*.mat'));

if ~isempty(fileInfo)
    fileName = fileInfo(1).name;
    fullPath = fullfile(logFolder, fileName);
    data = load(fullPath);
    fprintf('Log file loaded correctly: %s\n', fileName);
else
    error('File .mat not found in the folder %s\n',logFolder);
end

%% Data processing

bankingData.roadBank.Time = data.insData.roadBankAngle.time;
bankingData.roadBank.Data = data.insData.roadBankAngle.value;

vyData.longSpeed.Time = data.insData.vxCG.time;
vyData.longSpeed.Data = data.insData.vxCG.value;
vyData.latSpeed.Time = data.insData.vyCG.time;
vyData.latSpeed.Data = data.insData.vyCG.value;

imuData.longAcc.Time = data.insData.axCG.time;
imuData.longAcc.Data = data.insData.axCG.value;
imuData.latAcc.Time = data.insData.ayCG.time;
imuData.latAcc.Data = data.insData.ayCG.value;
imuData.vertAcc.Time = data.insData.azCG.time;
imuData.vertAcc.Data = data.insData.azCG.value;
imuData.yawRate.Time = data.insData.yawRate.time;
imuData.yawRate.Data = deg2rad(data.insData.yawRate.value);

carData.rpm.Time = data.driverData.engineSpeed.time;
carData.throttle.Time = data.driverData.throttle.time;
carData.brake.Time = data.driverData.brake.time;
carData.steer.Time = data.driverData.handwheelAngle.time;
carData.rpm.Data = data.driverData.engineSpeed.value;
carData.throttle.Data = data.driverData.throttle.value;
carData.brake.Data = data.driverData.brake.value;
carData.steer.Data = deg2rad(data.driverData.handwheelAngle.value) ./ vehicle.geometry.steeringwheel_ratio;

slamData.x.Time = data.insData.posE.time;
slamData.y.Time = data.insData.posN.time;
slamData.z.Time = data.insData.posU.time;
slamData.speed.Time = data.insData.vxCG.time;
slamData.speedLat.Time = data.insData.vxCG.time;
slamData.yaw.Time = data.insData.yawAngle.time;
slamData.pitch.Time = data.insData.pitchAngle.time;
slamData.roll.Time = data.insData.rollAngle.time;

slamData.x.Data = data.insData.posE.value;
slamData.y.Data = data.insData.posN.value;
slamData.z.Data = data.insData.posU.value;
slamData.speed.Data = data.insData.vxCG.value;
slamData.speedLat.Data = data.insData.vyCG.value;
slamData.yaw.Data = data.insData.yawAngle.value;
slamData.pitch.Data = data.insData.pitchAngle.value;
slamData.roll.Data = data.insData.rollAngle.value;

% lla0 = getWorldOrigin(world_origin);
% gpsAntennaData = processGps(vectornav_gps_a,lla0, sim);

kistlerData.longSpeed.Time = data.insData.vxCG.time;
kistlerData.longSpeed.Data = data.insData.vxCG.value;
kistlerData.latSpeed.Time = data.insData.vyCG.time;
kistlerData.latSpeed.Data = data.insData.vyCG.value;

vehiclestateData.longAcc.Time = data.insData.axCG.time;
vehiclestateData.longAcc.Data = data.insData.axCG.value;
vehiclestateData.latAcc.Time = data.insData.ayCG.time;
vehiclestateData.latAcc.Data = data.insData.ayCG.value;
vehiclestateData.yawRate.Time = data.insData.yawRate.time;
vehiclestateData.yawRate.Data = deg2rad(data.insData.yawRate.value);

%% Select data time window
timeWindow = carData.throttle.Time;

% Resampling and unifying time windows
timeWindow = timeWindow(1):timeStep:timeWindow(end);
timeWindow = unique(timeWindow);
clear i timeWindows resampledTime

% Find all variables in the workspace that match the pattern '*Data'
dataVars = who('*Data');

% Loop through each variable and resample the data
for i = 1:length(dataVars)
    varName = dataVars{i};  % Get the variable name as a string

    % Use dynamic field referencing to access the variable
    eval([varName ' = resampleData(' varName ', timeWindow);']);
end
clear i  varName dataVars

%% Data packaging
% Find all variables in the workspace that match the pattern '*Data'
dataVars = who('*Data');

% Loop through each variable and resample the data
for i = 1:length(dataVars)
    varName = dataVars{i};  % Get the variable name as a string

    % Use dynamic field referencing to access the variable
    log.(varName) = eval(varName);
end
clear i  varName dataVars

% Find simulink inputs
GNSS1 = Simulink.Bus.createMATLABStruct('GNSSBus');
GNSS2 = Simulink.Bus.createMATLABStruct('GNSSBus');
IMU = Simulink.Bus.createMATLABStruct('IMUBus');
KISTLER = Simulink.Bus.createMATLABStruct('KISTLERBus');
BADENIA = Simulink.Bus.createMATLABStruct('BADENIABus');
VEHICLESTATE = Simulink.Bus.createMATLABStruct('VEHICLESTATEBus');
Measurements = Simulink.Bus.createMATLABStruct('MeasurementsBus');

KISTLER.enableFlag = timeseries(squeeze(log.kistlerData.longSpeed.isNew),  timeWindow, 'Name', 'enableFlag');
KISTLER.longSpeed  = timeseries(squeeze(log.kistlerData.longSpeed.Data),   timeWindow, 'Name', 'vx');
KISTLER.latSpeed   = timeseries(squeeze(log.kistlerData.latSpeed.Data),    timeWindow, 'Name', 'vy');

IMU.enableFlag     = timeseries(squeeze(log.imuData.longAcc.isNew),        timeWindow, 'Name', 'enableFlag');
IMU.ax             = timeseries(squeeze(log.imuData.longAcc.Data),         timeWindow, 'Name', 'ax');
IMU.ay             = timeseries(squeeze(log.imuData.latAcc.Data),          timeWindow, 'Name', 'ay');
IMU.az             = timeseries(squeeze(log.imuData.vertAcc.Data),         timeWindow, 'Name', 'az');
IMU.yaw_rate       = timeseries(squeeze(log.imuData.yawRate.Data),         timeWindow, 'Name', 'yaw_rate');

VEHICLESTATE.enableFlag     = timeseries(squeeze(log.vehiclestateData.longAcc.isNew),        timeWindow, 'Name', 'enableFlag');
VEHICLESTATE.ax             = timeseries(squeeze(log.vehiclestateData.longAcc.Data),         timeWindow, 'Name', 'ax');
VEHICLESTATE.ay             = timeseries(squeeze(log.vehiclestateData.latAcc.Data),          timeWindow, 'Name', 'ay');
VEHICLESTATE.yaw_rate       = timeseries(squeeze(log.vehiclestateData.yawRate.Data),         timeWindow, 'Name', 'yaw_rate');

Measurements.VEHICLESTATE = VEHICLESTATE;
Measurements.GPS          = GNSS1;
Measurements.SLAM         = GNSS2;
Measurements.IMU          = IMU;
Measurements.KISTLER      = KISTLER;


Measurements.carSteer     = timeseries(squeeze(carData.steer.Data),        timeWindow, 'Name', 'carSteer');
Measurements.carThrottle  = timeseries(squeeze(carData.throttle.Data),     timeWindow, 'Name', 'carThrottle');
Measurements.carBrake     = timeseries(squeeze(carData.brake.Data),        timeWindow, 'Name', 'carBrake');
Measurements.carEngineRPM = timeseries(squeeze(carData.rpm.Data),          timeWindow, 'Name', 'carEngineRPM');
Measurements.bank         = timeseries(squeeze(bankingData.roadBank.Data),              timeWindow, 'Name', 'bank');

% Save simulink input struct
log.Measurements = Measurements;


log.vehicleType = vehicle_type;
log.logName = logFolder;