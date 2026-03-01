finish_sound = onCleanup(@() beep);

%% Source
addpath(genpath("fcns"));
addpath("vehicles/");

%% Initialize model parameters
Ts = 0.01;         % [s] sample time

%% Create Bus Data Type
createSlkBus

%% Select and Initialize the Vehicle
vehicle_type = "corvette"; % superformula, indylight, ferrari, corvette
vehicle = initVehicle(vehicle_type);

%% Initialiaze Kalman Filter 
run('initKalman.m');

%%  Choose log based on car 
% Default log per ca
logByCar = struct( ...
    "superformula", "20251016_yas_north_run01_q1_raw", ...
    "ferrari",      "20140222_02_01_03", ...
    "corvette",     "20130223_01_01_03_grandsport", ...
    "indylight",    "20250607_marzaglia_run03" ...
);

% Use default for that car
if isfield(logByCar, vehicle_type)
    logFolderName = logByCar.(vehicle_type);
else
    error('Unknown vehicle_type "%s". Add it to logByCar.', vehicle_type);
end


logFolder = fullfile("log", vehicle_type, logFolderName);

%% Load Data
sim = false;
log = loadDataWithPrompt(logFolder, vehicle_type, vehicle, sim, Ts, 'AutoReuseIfSame', false);

load gong; sound(y, Fs);
