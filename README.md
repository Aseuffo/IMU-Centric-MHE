# IMU-Centric Moving Horizon Estimation for Lateral Dynamics Estimation

This repository contains the MATLAB development workspace for the IMU-centric Moving Horizon Estimation (MHE) framework presented in our paper:

IMU-Centric Moving Horizon Estimation of Lateral Dynamics Across Vehicles and Grip Conditions https://arxiv.org/abs/2609.10202

The proposed estimator reconstructs vehicle lateral velocity and lateral acceleration using inertial measurements and available onboard signals. The framework also adapts the effective tire force capacity in order to account for variations in tire-road grip conditions.

Unlike formulations that treat measured control inputs as perfectly known exogenous quantities, this approach allows signals such as steering input and longitudinal acceleration to be handled directly within the estimation window. The estimator combines a planar single-track vehicle model with a compact Sine Saturation Tire (SST) surrogate model. The effective front and rear tire force-capacity coefficients are estimated from a low-dimensional set of bounded and regularized decision variables.

## Repository Overview

This repository provides:

- MATLAB implementation of the IMU-centric MHE estimator.
- Vehicle parameter files for different test vehicles.
- Configuration files for selecting the estimator structure, tuning parameters, bounds, solver options, and plotting settings.
- Scripts for initializing the workspace and running the selected MHE experiment.

## Requirements

Before running the project, make sure the following dependencies are available:

- MATLAB
- CasADi for MATLAB

CasADi can be downloaded from the official website:

https://web.casadi.org/

After downloading CasADi, add it to the repository folder or make sure it is included in your MATLAB path.

## Getting Started

### 1. Download CasADi

Download the MATLAB version of CasADi and place it inside the repository folder, or add its location to the MATLAB path.

### 2. Download the Dataset

### 2. Download the Dataset

Download the required `.mat` files from the Stanford dataset repositories:

- Ferrari dataset: https://purl.stanford.edu/hd122pw0365
- Corvette dataset: https://purl.stanford.edu/yf219gg2055

For the experiments reported in the paper, we used the following data files:

- Ferrari: `20140222_02_01_03.mat`
- Corvette: `20130223_01_02_03_grandsport.mat`

After downloading the files, create a folder named `log` in the root directory of the repository. Inside `log`, create one folder for each vehicle: `ferrari` and `corvette`. Then, inside each vehicle folder, create a folder with the same name as the corresponding `.mat` file, without the `.mat` extension. Place the `.mat` file inside that folder.

The expected folder structure is:

``log/
├── ferrari/
│   └── 20140222_02_01_03/
│       └── 20140222_02_01_03.mat
└── corvette/
    └── 20130223_01_02_03_grandsport/
        └── 20130223_01_02_03_grandsport.mat``


### 3. Configure and Run the Workspace

Open the MATLAB initialization script `init.m`.

Inside this file, select the vehicle you want to evaluate. The currently supported vehicles are:

- Corvette
- Ferrari

Then run `init` from MATLAB.

The `init.m` script initializes the workspace, loads the selected dataset, applies the selected configuration, and runs the MHE experiment.

## MHE Implementation

The main MHE implementation is located in `runMHEExperiment.m`.

This file contains the core Moving Horizon Estimation routine used to reconstruct the lateral vehicle dynamics from the available measurements and model structure.

## Repository Structure

### Vehicle Model

Vehicle-specific parameters are stored in the `vehicle` folder. Each vehicle has a corresponding JSON parameter file.

These files contain parameters such as:

- Vehicle mass
- Vehicle geometry
- Inertia
- Tire model parameters
- Aerodynamic parameters

Some aerodynamic parameters are estimated or assumed when direct measurements are not available.

The tire parameters in these JSON files can be modified to tune the vehicle model or evaluate sensitivity to different tire configurations.

### MHE Configuration

The main configuration file for the estimator is `mhe_tuning.json`.

This file contains the principal settings used by the MHE framework. The default configuration corresponds to the setup presented in the paper.

The configuration file includes the following sections.

#### Estimator Structure

The `flags` section defines the estimator configuration, including which states and decision variables are optimized.

You can use this section to enable or disable specific estimated quantities depending on the experiment you want to run.

#### Data Segment Configuration

The `data_segment` section allows you to choose the lap, laps, or specific data segment to evaluate.

This is useful when testing the estimator on selected driving conditions or comparing performance across different parts of the dataset.

#### Tuning Configuration

The  section defines the tuning parameters used by the estimator.

The tuning is case-dependent, meaning that different estimator configurations may require different tuning values.

#### Bounds

The `bounds` section defines lower and upper limits for the optimization variables.

These bounds help ensure physically meaningful estimates and improve numerical robustness.

#### Initial Guess

The `initial_guess` section defines the initial values used for the optimization variables.

These values can influence solver convergence, especially when testing new configurations.

#### Solver Configuration

The `solver` section contains the numerical solver settings used by the MHE problem.

You can modify these parameters to adjust solver behavior, convergence tolerances, or computational performance.

#### Plot Configuration

The `plot` section controls the visualization options.

It allows you to configure whether to:

- Plot estimated forces.
- Save generated figures.
- Disable plotting for faster batch evaluation.

## Data Loading Behavior

Loading the dataset can be time-consuming. Once the data has been loaded into the MATLAB workspace, it does not need to be reloaded every time.

If you modify the configuration file and run `init.m` again, a pop-up GUI will ask whether you want to:

- Reuse the previously loaded data without reloading it.
- Overwrite the current workspace data and load a new dataset.

Choose Reuse if you are using the same dataset and only changed estimator or plotting configurations.

Choose Overwrite if you changed the dataset or want to reload the data from disk.

## Notes

- The default configuration matches the estimator setup used in the paper.
- Vehicle parameters can be modified through the corresponding JSON files in the `vehicle` folder.
- Tire parameters can be adjusted to test different model assumptions or grip conditions.
- Some aerodynamic parameters are approximate because direct measurements were not available.

## Citation

If you use this repository in your research, please cite our paper:

@article{ngoune2026imu,
  title   = {IMU-Centric Moving Horizon Estimation of Lateral Dynamics Across Vehicles and Grip Conditions},
  author  = {Seuffo Akouan'ha Ngoune and Alessandro Toschi and Paolo Burgio and Marko Bertogna},
  journal = {arXiv preprint arXiv:2609.10202 },
  year    = {2026},
  note    = {Accepted at IEEE ITSC 2026}
}


## Contact

For questions, issues, or suggestions, please open an issue in this repository.
