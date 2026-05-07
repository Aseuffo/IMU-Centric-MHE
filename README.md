# urSlk

**EKF Simulink Development Workspace**

## Steps to Use

### 1. Open the `initBicycle` File
- Select the model you'd like to evaluate in the **Dynamic Model Parameter** section.
- In the **Refresh Model** section, specify your path.

### 2. Initialize the Interface
Run the `init` script to:
- Load data.
- Import Simulink models for your MATLAB version (uncomment the necessary section).

### 3. Run the Interface
- Open the Simulink model labeled for your MATLAB version.
- Press **Play** to run the simulation.

### 4. Show Results
- Run the `output` script to view the results of EKF for localization.
- Run the `output2` script to view the results of EKF for VyEstimation.
- Run the `output3` script to view the results of UKF for VyEstimation.
- Run the `KPI` script to evaluate the KPIs of both UKF and EKF for VyEstimation.

## How to use MHE
### 0. Download Casadi and necessary toolbox
### 1. Open the initBicycle File

    Select the model you'd like to evaluate in the Dynamic Model Parameter se>

### 2. Initialize the Interface

    Put the csv log in the log folder
    Run the init script to load data.

### 3. Run the MHE

    In the load_log script select the first and the last point of the simulation
    Run the MHE_DMultiAyMeas script for vy and D estimations

