# Buildstrappers

Buildstrapper scripts are the entry points to LeetABit.Build system. They are designed to be put in the root directory of the repository. The main job of the buildstrapping scripts is to make sure that the PowerShell is available in the system. Determine LeetABit.Build version required by the repository, install it and pass all the provided parameters to LeetABit.Build module for further execution. This process is divided into two phases.

## Phase 1: Platform dependent `run.cmd` and `run.sh`

First phase of the buildstrapping is optional and is responsible for locating and installing PowerShell in the system. This is implemented as two platform dependent scripts. For Windows system there is a dedicated `run.cmd` script. For linux and Mac OS there is a `run.sh` bash script. Both scripts are designed to produce very similar output. Each of them makes sure that the platform independent `run.ps1` script is executed using PowerShell in the version expected by the repository. Invoking `run.ps1` script directly does not provide such enforcement.

## Phase 2: Platform independent `run.ps1`

Second phase of the buildstrapping is responsible for locating and installing all required LeetABit.Build modules. There are two distinct ways of instructing buildstrapper about LeetABit.Build requirements: by specifying a required version or by specifying a location from which the LeetABit.Build modules shall be loaded. When a version is specified buildstrapper will try to import LeetABit.Build modules via `Install-Module` and `Import-Module` cmdlets. When a custom location is specified buildstrapper will try to import LeetABit.Build modules from this location only. There are three different ways of providing arguments for buildstrapper described at [Arguments page](Arguments.md).
