function createSlkBus()
%% Kistler Bus
KISTLERBus = Simulink.Bus;
KISTLERBus.Description = 'Kistler Sensor Data Type';
KISTLERBus.HeaderFile = char([]);
i = 1;

% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enableFlag';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% Longitudinal Speed 
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'longSpeed';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% Lateral Speed (latSpeed)
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'latSpeed';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

%%%
KISTLERBus.Elements = eleTmp;
clear eleTmp;
assignin("caller", "KISTLERBus", KISTLERBus);


%% Badenia Bus
BADENIABus = Simulink.Bus;
BADENIABus.Description = 'Badenia Sensor Data Type';
BADENIABus.HeaderFile = char([]);
i = 1;

% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enableFlag';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% Wheel Load Front Left
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'wLoadFl';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% Wheel Load Front Right
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'wLoadFr';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% Wheel Load Rear Left
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'wLoadRl';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% Wheel Load Rear Right
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'wLoadRr';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

%%%
BADENIABus.Elements = eleTmp;
clear eleTmp;
assignin("caller", "BADENIABus", BADENIABus);

%% GNSS Bus
GNSSBus = Simulink.Bus;
GNSSBus.Description = 'GNSS Bus Data Type';
GNSSBus.HeaderFile = char([]);
i = 1;
% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enableFlag';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% x
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'x';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% y
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'y';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% heading
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'heading';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% speed
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% cov_x
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'cov_x';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% cov_y
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'cov_y';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% heading_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'heading_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% speed_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
%%%
GNSSBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","GNSSBus",GNSSBus);


%% SLAM Bus
SLAMBus = Simulink.Bus;
SLAMBus.Description = 'SLAM Bus Data Type';
SLAMBus.HeaderFile = char([]);
i = 1;

% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enableFlag';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% x
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'x';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% xy
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'y';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% heading
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'heading';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% speed
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% cov_x
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'cov_x';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% cov_y
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'cov_y';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% heading_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'heading_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% speed_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% yaw
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yaw';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% pitch
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'pitch';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% roll
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'roll';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

%%%
SLAMBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","SLAMBus",SLAMBus);

%% IMU Bus
IMUBus = Simulink.Bus;
IMUBus.Description = 'IMU Bus Data Type';
IMUBus.HeaderFile = char([]);
i = 1;
% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enableFlag';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% yaw_rate
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yaw_rate';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% ax
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ax';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% ay
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ay';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% ay
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'az';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% yaw_rate_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yaw_rate_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% ax_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ax_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% ay_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ay_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
%%%
IMUBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","IMUBus",IMUBus);
 
%% VEHICLESTATE Bus
VEHICLESTATEBus = Simulink.Bus;
VEHICLESTATEBus.Description = 'Vehicle State Bus Data Type';
VEHICLESTATEBus.HeaderFile = char([]);
i = 1;

% enableFlag
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enableFlag';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% yaw_rate
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yaw_rate';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% ax
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ax';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% ay
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ay';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% yaw_rate_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yaw_rate_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% ax_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ax_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% ay_cov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'ay_cov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

%% Assign elements to the bus
VEHICLESTATEBus.Elements = eleTmp;

clear eleTmp;
assignin("caller", "VEHICLESTATEBus", VEHICLESTATEBus);


%% Measurements Bus
MeasurementsBus = Simulink.Bus;
MeasurementsBus.Description = 'Measurements Bus Data Type';
MeasurementsBus.HeaderFile = char([]);
i = 1;
%Kistler 
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'KISTLER';
eleTmp(i).DataType = 'KISTLERBus';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% GPS
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'GPS';
eleTmp(i).DataType = 'GNSSBus';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% IMU
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'IMU';
eleTmp(i).DataType = 'IMUBus';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% Slam
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'SLAM';
eleTmp(i).DataType = 'SLAMBus';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% vehicle state 
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'VEHICLESTATE';
eleTmp(i).DataType = 'VEHICLESTATEBus';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% badenia 
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'BADENIA';
eleTmp(i).DataType = 'BADENIABus';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% wheel speed
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'carSpeed';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed_fl';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed_fr';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed_rl';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed_rr';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

% wheel angle
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'carSteer';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% accelerator pedal
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'carThrottle';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% brake pedal
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'carBrake';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% current gear
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'carGear';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% engine rpm
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'carEngineRPM';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;
% Banking
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'bank';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = [1 1];
i = i + 1;

%%%
MeasurementsBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","MeasurementsBus",MeasurementsBus);



%%

InputBus = Simulink.Bus;
InputBus.Description = 'Input Bus type';
InputBus.HeaderFile = char([]);
i = 1;
% delta
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'steeringAngle';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% ax
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'longAcc';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;

% Create Input bus
InputBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","InputBus",InputBus);


%% 
% UKF State Estimate Bus
UKFStateEstimateBus = Simulink.Bus;
UKFStateEstimateBus.Description = 'State Estimate Bus for UKF';
UKFStateEstimateBus.HeaderFile = char([]);
i = 1;
% Longitudinal velocity
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'longitudinalVelocity';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Lateral velocity
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'lateralVelocity';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Yaw rate
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yawRate';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Create State Estimate Bus
UKFStateEstimateBus.Elements = eleTmp;
clear eleTmp;
assignin("caller", "UKFStateEstimateBus", UKFStateEstimateBus);

% UKF State Estimate Covariance Bus
UKFStateEstimateCovarianceBus = Simulink.Bus;
UKFStateEstimateCovarianceBus.Description = 'Covariance Bus for UKF State Estimates';
UKFStateEstimateCovarianceBus.HeaderFile = char([]);
i = 1;
% Longitudinal velocity covariance
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'longitudinalVelocityCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Lateral velocity covariance
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'lateralVelocityCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Yaw rate covariance
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yawRateCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Create State Estimate Covariance Bus
UKFStateEstimateCovarianceBus.Elements = eleTmp;
clear eleTmp;
assignin("caller", "UKFStateEstimateCovarianceBus", UKFStateEstimateCovarianceBus);

% UKF Output Bus
UKFOutputBus = Simulink.Bus;
UKFOutputBus.Description = 'UKF Output Bus Type';
UKFOutputBus.HeaderFile = char([]);
i = 1;
% State Estimate
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'stateEstimate';
eleTmp(i).DataType = 'UKFStateEstimateBus';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% State Estimate Covariance
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'stateEstimateCovariance';
eleTmp(i).DataType = 'UKFStateEstimateCovarianceBus';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Create UKF Output Bus
UKFOutputBus.Elements = eleTmp;
clear eleTmp;
assignin("caller", "UKFOutputBus", UKFOutputBus);



%%

InertialMeasurementBus = Simulink.Bus;
InertialMeasurementBus.Description = 'Inertial Measurement Bus Type';
InertialMeasurementBus.HeaderFile = char([]);
i = 1;
% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enable';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% yawRate
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yawRate';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% longAcc
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'longAcc';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% latAcc
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'latAcc';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% yawRateCov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'yawRateCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% longAccCov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'longAccCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% latAccCov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'latAccCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;

% Create InertialMeasurementBus
InertialMeasurementBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","InertialMeasurementBus",InertialMeasurementBus);


%%

SpeedMeasurementBus = Simulink.Bus;
SpeedMeasurementBus.Description = 'Speed Measurement Bus Type';
SpeedMeasurementBus.HeaderFile = char([]);
i = 1;
% enable
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'enable';
eleTmp(i).DataType = 'boolean';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% speed
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speed';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% speedCov
eleTmp(i) = Simulink.BusElement;
eleTmp(i).Name = 'speedCov';
eleTmp(i).DataType = 'double';
eleTmp(i).Dimensions = double(1);
i = i + 1;
% Create SpeedMeasurementBus
SpeedMeasurementBus.Elements = eleTmp;
clear eleTmp;
assignin("caller","SpeedMeasurementBus",SpeedMeasurementBus);

end

