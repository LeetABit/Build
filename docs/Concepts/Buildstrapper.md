# Leet.Buildstrapper

Buildstrapper scripts are the entry points to Leet.Build system. They are designed to be put in the root directory of the repository. The main job of the buildstrapping scripts is to make sure that the PowerShell is available in the system. Determine Leet.Build version required by the repository, install it and pass all the provided parameters to Leet.Build module for further execution. This process is divided into two phases.

## Phase 1: Platform dependent `run.cmd` and `run.sh`

First phase of the buildstrapping is optional and is responsible for locating and installing PowerShell in the system. This is implemented as two platform dependent scripts. For Windows system there is a dedicated `run.cmd` script. For linux and Mac OS there is a `run.sh` bash script. Both scripts are designed to produce very similar output. Each of them makes sure that the platform independent `run.ps1` script is executed using PowerShell in the version expected by the repository. Invoking `run.ps1` script directly does not provide such enforcement.

## Phase 2: Platform independent `run.ps1`

Second phase of the buildstrapping is responsible for locating and installing all required Leet.Build modules. There are two distinc ways of instructing buildstrapper about required Leet.Build version: by specifying a required version or by specifying a location from which the Leet.Build modules shall be loaded. When a version is specified buildstrapper will try to import Leet.Build modules via `Install-Module` and `Import-Module` cmdlets. When a custom location is specified buildstrapper will try to import Leet.Build modules from this location only. There are three different ways of providing arguments for buildstrapper parameters: via PowerShell command parameters, via environment variables with a name that consist of a prefix `Leet_` and name of the parameter, via JSON entry in a `Leet.Build.json` configuration file located in repository root directory or in any of its subdirectories. Precedence of the arguments is following: `command parameter > environment variable > configuration file`.
