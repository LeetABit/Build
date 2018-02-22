#!/usr/bin/env bash
#==========================================================================
#  Copyright (c) Leet. All rights reserved.
#  Licensed under the MIT License.
#  See License.txt in the project root for full license information.
#--------------------------------------------------------------------------
#  This script makes sure that the PowerShell Core in the required version
#  is installed on the system and then runs 'run.ps1' PowerShell script
#  passing all current script's parameters to it.
#==========================================================================

current_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
power_shell_version="6.0.1"
last_fold_name=""

#============================================================================
#  Main script procedure.
#============================================================================
function main {
  write_step_start "InstallPowerShellCore" "Checking PowerShell Core v$power_shell_version availability."
  find_pwsh $power_shell_version pwsh_path
  if [ -z "$pwsh_path" ]; then
    install_power_shell_package $power_shell_version

    find_pwsh $power_shell_version pwsh_path
    if [ -z "$pwsh_path" ]; then
      write_error "Could not install PowerShell Core v$power_shell_version."
      return 2
    fi

    echo -e "PowerShell Core v$power_shell_version has been installed at '$pwsh_path'."
  else
    echo -e "PowerShell Core v$power_shell_version already installed at '$pwsh_path'."
  fi

  write_step_succeed
  echo -e ""

  $pwsh_path "$current_folder/run.ps1" "$@"
}

#============================================================================
#  Searches for the 'pwsh' file in the current system.
#--------------------------------------------------------------------------
#  $power_shell_version
#    Version of the PowerShell Core application to be found in the system.
#
#  $return
#    Name of the variable that gets the PowerShell Core application path
#    found.
#============================================================================
function find_pwsh() {
  local power_shell_version=$1
  local __resultvar=$2

  if machine_has pwsh; then
    paths=($(whereis pwsh))
    for path in ${paths[@]:1}
    do
      version=$($path --version | cut -d' ' -f2-)
      if [ "$version" == "v$power_shell_version" ]; then
        eval $__resultvar="'$path'"
        return 0
      fi
    done

	path=$(which pwsh)
    if [ ! -z "$path" ]; then
      version=$($path --version | cut -d' ' -f2-)
      if [ "$version" == "v$power_shell_version" ]; then
        eval $__resultvar="'$path'"
      fi
    fi
  fi
}

#============================================================================
#  Installs required version of the PowerShell Core in the current system.
#--------------------------------------------------------------------------
#  $power_shell_version
#    Version of the PowerShell Core application to be found in the system.
#============================================================================
function install_power_shell_package() {
  local power_shell_version=$1

  local file_name_suffix="-1.ubuntu.14.04_amd64.deb" && [[ "$(uname)" = "Darwin" ]] && file_name_suffix="-osx.10.12-x64.pkg"
  local file_name_version_connectior="_" && [[ "$(uname)" = "Darwin" ]] && file_name_version_connectior="-"
  local file_name="powershell$file_name_version_connectior$power_shell_version$file_name_suffix"
  local destination_path="/tmp/$file_name"
  local download_path="https://github.com/PowerShell/PowerShell/releases/download/v$power_shell_version/$file_name";

  write_modification "Downloading PowerShell Core package to '$destination_path'..."
  local failed=false
  if machine_has wget; then
    wget --tries 10 --quiet -O "$destination_path" "$download_path" || failed=true
  else
    failed=true
  fi

  if [ "$failed" = true ] && machine_has curl; then
    failed=false
    curl --retry 10 -sSL -f --create-dirs -o "$destination_path" "$download_path" || failed=true
  fi

  if [ "$failed" = true ]; then
    write_error "Could not download PowerShell Core v$power_shell_version."
    return 1
  fi

  write_modification "Instaling PowerShell Core package..."
  if [ "$(uname)" = "Darwin" ]; then
    sudo installer -pkg $destination_path -target /
  else
    sudo dpkg -i $destination_path
    sudo apt-get install -f
  fi

  write_modification "Deleting '$destination_path'..."
  rm -f $destination_path
}

#============================================================================
#  Checks whether the specified command is available in the current system.
#--------------------------------------------------------------------------
#  $command_name
#    Name of the command which availability shall be determined.
#============================================================================
function machine_has() {
  local command_name=$1

  hash "$command_name" > /dev/null 2>&1
  return $?
}

#============================================================================
#  Writes a execution step start message to the host.
#--------------------------------------------------------------------------
#  $step_name
#    Name of the step to start.
#
#  $message
#    Step message.
#============================================================================
function write_step_start() {
  local step_name=$1
  local message=$2

  local preamble=""

  if [ $TRAVIS ]; then
    preamble="travis_fold:start:$step_name"
  fi
  
  echo ""
  echo -e "$preamble\x1B[36m$message\x1B[0m"
  last_step_name=$step_name
}

#============================================================================
#  Writes a execution step ended message to the host.
#============================================================================
function write_step_succeed() {
  local preamble=""

  if [ $TRAVIS ]; then
    preamble="travis_fold:end:$last_step_name"
  fi
  
  echo -e "$preamble\x1B[32mSuccess.\x1B[0m"
}

#============================================================================
#  Writes a message about a modification done to the executing environment.
#--------------------------------------------------------------------------
#  $message
#    Execution message.
#============================================================================
function write_modification() {
  local message=$1

  echo -e "\x1B[1;35m$message\x1B[0m"
}

#============================================================================
#  Writes an execution error.
#--------------------------------------------------------------------------
#  $message
#    Error message.
#============================================================================
function write_error() {
  local message=$1

  echo -e "\x1B[1;31m$message\x1B[0m" 1>&2
}

#============================================================================
#  Script start.
#============================================================================

main "$@"
