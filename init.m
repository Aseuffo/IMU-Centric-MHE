close all 
% clc
finish_sound = onCleanup(@() beep);

%% Source
addpath(genpath("fcns"));
addpath("vehicles/");

%% Initialize model parameters
Ts = 0.01;         % [s] sample time

%% Create Bus Data Type
createSlkBus

%% Select and Initialize the Vehicle
vehicle_type = "ferrari"; %  ferrari, corvette
vehicle = initVehicle(vehicle_type);

%%  Choose log based on car 
% Default log per ca
logByCar = struct( ...
    "ferrari",      "20140222_02_01_03", ...
    "corvette",     "20130223_01_01_03_grandsport" ...
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


%% Run MHE 
workspaceData = runMHEExperiment(vehicle,log);
