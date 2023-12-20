#!/usr/bin/env bash
############################################################################
#   Copyright (c) Hubert Bukowski. All rights reserved.
#   Licensed under the MIT License.
#   See License.txt in the project root for full license information.
############################################################################
set -o errexit
set -o nounset
set -o errtrace
trap 'write_error "Command '"'"'$BASH_COMMAND'"'"' caused error $? at line $LINENO in function called from line $BASH_LINENO.\nCall stack: $(printf "::%s" ${FUNCNAME[@]:-} | cut -c3-)"' ERR
set -u
set -o pipefail
exec 3>&1


############################################################################
#   Configuration
############################################################################
powershell_version="7.4.0"
powershell_file_name="pwsh"


############################################################################
#   Initialization.
############################################################################
function initialize {
    local platform="linux" && [[ "$(uname)" = "Darwin" ]] && platform="osx"
    if [[ -f "/etc/alpine-release" ]]; then
        platform="linux-alpine"
    fi

    local architecture="x64"
    if [[ "$platform" = "linux" ]]; then
        case $(uname -m) in
            arm|armv71)
                architecture="arm32"
                ;;
            aarch64_be|aarch64|armv8b|armv8l|arm64)
                architecture="arm64"
                ;;
        esac
    fi

    local powershell_archive_file_name="powershell-$powershell_version-$platform-$architecture.tar.gz"

    installation_directory_path="$HOME/opt/local/microsoft/powershell/$powershell_version"
    installation_pwsh_path="$installation_directory_path/$powershell_file_name"
    powershell_download_link="https://github.com/PowerShell/PowerShell/releases/download/v$powershell_version/$powershell_archive_file_name"
    powershell_archive_destination_path="/tmp/$powershell_archive_file_name"

    current_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    initialize_verbose_logging "$@"
    initialize_force_install_powershell "$@"
    initialize_console_colors
}


############################################################################
#   Main script procedure.
############################################################################
function main {
    install_powershell=0
    if [[ $force_install_power_shell == "1" ]]; then
        write_verbose "Forced PowerShell $powershell_version installation is requested."
        install_powershell=1
    else
        pwsh_path=$(find_powershell $powershell_version "$powershell_file_name" "$installation_pwsh_path")

        if [[ -z "$pwsh_path" ]]; then
            install_powershell=1
            write_verbose "No PowerShell $powershell_version has been found in the current environment."
        fi
    fi

    if [[ $install_powershell == "1" ]]; then
        begin_step "install_powershell" "Installing PowerShell Core $powershell_version..."

        download_file "$powershell_download_link" "$powershell_archive_destination_path" || {
            write_error "PowerShell archive download failed. Error code: $?"
            return 1
        }

        install_archive "$powershell_archive_destination_path" "$installation_directory_path" "$installation_pwsh_path" || {
            write_error "PowerShell archive installation failed. Error code: $?"
            return 2
        }

        pwsh_path="$installation_pwsh_path"
        delete_item "$powershell_archive_destination_path" || {
            write_warning "Could not delete PowerShell archive file. Error code: $?"
        }

        end_step
    fi

    if [[ ! -f "$pwsh_path" ]]; then
        write_error "Could not find PowerShell executable at '$pwsh_path'."
        return 3
    fi

    execute_command "$pwsh_path" "$current_folder/run.ps1" "$@" || {
        write_error "PowerShell execution failed. Error code: $?"
        return 4
    }

    return 0
}


############################################################################
#   Function definitions.
############################################################################

#===========================================================================
#   Checks whether the verbose logging is requested.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $#
#           All the parameters sent to the script.
#---------------------------------------------------------------------------
#   SETS:
#       verbose
#           Sets to value 1 if verbose logging has been requested;
#           to 0 otherwise.
#===========================================================================
function initialize_verbose_logging() {
    ci="$( echo "${CI:-}" | tr '[:upper:]' '[:lower:]' )"
    if [[ "$ci" == "true" ]]; then
        verbose=1
        write_verbose "Verbose logging enabled: 'CI' environmental variable with value 'true' found."
        return
    fi

    local i=1
    while [[ "$i" -le "$#" ]]; do
        local parameter=${@:$i:1}
        parameter="$( echo "$parameter" | tr '[:upper:]' '[:lower:]' )"
        if [[ $parameter =~ ^-(verbose|vb)(:(\$true)|(true)|([0-9]*[1-9][0-9]*)|(0x[0-9a-f]*[1-9a-f][0-9a-f]*))?$ ]] ; then
            verbose=1
            write_verbose "Verbose logging enabled: '$parameter' parameter found."
            return
        fi

        ((i++))
    done

    verbose=0
}


#===========================================================================
#   Checks whether the forced PowerShell installation is requested.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $#
#           All the parameters sent to the script.
#---------------------------------------------------------------------------
#   SETS:
#       force_install_power_shell
#           Sets to value 1 if forced PowerShell installation has been
#           requested; to 0 otherwise.
#===========================================================================
function initialize_force_install_powershell() {
    if [[ "${LeetABitBuild_ForceInstallPowerShell:-}" == "1" ]]; then
        force_install_power_shell=1
        write_verbose "Forced PowerShell installation enabled: 'LeetABitBuild_ForceInstallPowerShell' environmental variable with value '1' found."
        return
    fi

    local i=1
    while [[ "$i" -le "$#" ]]; do
        local parameter=${@:$i:1}
        parameter="$( echo "$parameter" | tr '[:upper:]' '[:lower:]' )"
        if [[ $parameter =~ ^-(forceinstallpowershell)(:(\$true)|(true)|([0-9]*[1-9][0-9]*)|(0x[0-9a-f]*[1-9a-f][0-9a-f]*))?$ ]] ; then
            force_install_power_shell=1
            write_verbose "Forced PowerShell installation enabled: '$parameter' parameter found."
            return
        fi

        ((i++))
    done

    force_install_power_shell=0
}


#===========================================================================
#   Initializes console colors if the current environment supports colors.
#---------------------------------------------------------------------------
#   SETS:
#       color_reset
#           Sets to a color reset command if current environment supports
#           colors.
#
#       color_red
#           Sets to a red color command if current environment supports
#           colors.
#
#       color_green
#           Sets to a green color command if current environment supports
#           colors.
#
#       color_yellow
#           Sets to a yellow color command if current environment supports
#           colors.
#
#       color_magenta
#           Sets to a magenta color command if current environment supports
#           colors.
#
#       color_cyan
#           Sets to a cyan color command if current environment supports
#           colors.
#===========================================================================
function initialize_console_colors() {
    if [[ -n "${GITHUB_WORKFLOW:-}" ]] ; then
        color_reset="\033[0m"
        color_red="\033[91m"
        color_green="\033[32m"
        color_yellow="\033[93m"
        color_magenta="\033[95m"
        color_cyan="\033[96m"

        write_verbose "Console colors enabled: running as GitHub workflow."
        exec 2> >(while read line; do printf "%b\n" "${color_red:-}$line${color_reset:-}" >&2 ; done)
    else
        ncolors=$(tput colors)
        if [[ -n "$ncolors" ]] && [[ $ncolors -ge 8 ]] ; then
            color_reset="$(tput sgr0 || echo)"
            color_red="$(tput setaf 1 || echo)"
            color_green="$(tput setaf 2 || echo)$(tput bold || echo)"
            color_yellow="$(tput setaf 3 || echo)$(tput bold || echo)"
            color_magenta="$(tput setaf 5 || echo)$(tput bold || echo)"
            color_cyan="$(tput setaf 6 || echo)$(tput bold || echo)"

            write_verbose "Console colors enabled: command 'tput colors' output match."
            exec 2> >(while read line; do printf "%b\n" "${color_red:-}$line${color_reset:-}" >&2 ; done)
        else
            write_verbose "Console colors disabled: command 'tput colors' output mismatch."
        fi
    fi
}


#===========================================================================
#   Searches for the PowerShell executable in the current system.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $version
#           Version of the PowerShell to be found.
#
#       $file_name
#           Name of the PowerShell executable file.
#
#       $expected_path
#           Default installation location of the PowerShell executable file.
#---------------------------------------------------------------------------
#   ECHOES:
#       Path to the PowerShell executable file found.
#===========================================================================
function find_powershell() {
    local version=$1
    local file_name=$2
    local expected_path=$3

    write_verbose "Searching for '$file_name' version $version in system PATH and at '$expected_path'..."

    check_powershell_version "$expected_path" "$version" && {
        echo "$expected_path"
        return 0
    }

    local candidates="$(which $file_name || return 0)"
    for candidate in ${candidates[@]}
    do
        check_powershell_version "$candidate" "$version" && {
            echo "$candidate"
            return 0
        }
    done

    return 0
}


#===========================================================================
#   Checks whether the PowerShell at specified path has a required version.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $power_shell_path
#           Path to the PowerShell executable file.
#
#       $required_version
#           Required PowerShell version.
#===========================================================================
function check_powershell_version() {
    local power_shell_path=$1
    local required_version=$2

    if [[ -f "$power_shell_path" ]]; then
        local candidate_version=$("$power_shell_path" --version | cut -d' ' -f2-)
        if [[ -n "$candidate_version" ]]; then
            write_verbose "Found PowerShell $candidate_version at '$power_shell_path'."
            if [[ "$candidate_version" == "$required_version" ]]; then
                return 0
            fi
        fi
    fi

    return 1
}


#===========================================================================
#   Downloads a file from the remote location.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $source_location
#           Path to the remote file to download.
#
#       $destination_path
#           Path to the destination of the downloaded file.
#===========================================================================
function download_file() {
    local source_location=$1
    local destination_path=$2

    write_modification "Downloading file from '$source_location' to '$destination_path'..."

    if machine_has wget; then
        execute_command wget --tries 10 --quiet -O "$destination_path" "$source_location"
    elif machine_has curl; then
        execute_command curl --retry 10 -sSL -f --create-dirs -s -o "$destination_path" "$source_location"
    else
        write_error "Could not download file: no downloading tool found."
        return 1
    fi

    local error=$?
    if [[ ! $error ]] ; then
        write_error "Could not download file: execute_command returned error $error."
        delete_item "$destination_path" || {
            write_warning "Could not delete PowerShell archive file. Error code: $?"
        }

        return 2
    fi

    if [[ ! -f "$destination_path" ]]; then
        write_error "Could not download file: destination file does not exist."
        return 3
    fi

    return 0
}


#===========================================================================
#   Installs the specified PowerShell archive file to the specified
#   location.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $archive_path
#           Path to the archive file to install.
#
#       $destination_directory_path
#           Path to the destination directory.
#
#       $executable_file_path
#           Path to the PowerShell executable file's expected location after
#           installation.
#===========================================================================
function install_archive() {
    local archive_path=$1
    local destination_directory_path=$2
    local executable_file_path=$3

    write_verbose "Installing PowerShell at '$destination_directory_path'..."

    delete_item "$destination_directory_path" || {
        write_error "Could not delete old PowerShell destination directory. Error code: $?"
        return 1
    }

    write_modification "Creating directory at '$destination_directory_path'..."
    mkdir -p "$destination_directory_path" || {
        write_error "Could not create a directory. Error code: $?"
        return 2
    }

    write_modification "Expanding archive to '$destination_directory_path'..."
    tar zxf "$archive_path" -C "$destination_directory_path" || {
        write_error "Could not expand archive. Error code: $?"
        return 3
    }

    write_modification "Setting execution permission for '$executable_file_path'..."
    chmod +x "$executable_file_path" || {
        write_error "Could not set execution permission. Error code: $?"
        return 4
    }

    return 0
}


#===========================================================================
#   Deletes a file system item specified by its path.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $item_path
#           Path to the item to delete.
#===========================================================================
function delete_item() {
    local item_path=$1

    if [[ -d "$item_path" ]] ; then
        write_modification "Deleting directory '$item_path'..."
        rm -rf "$item_path" > /dev/null
        return $?
    elif [[ -f "$item_path" ]] ; then
        write_modification "Deleting file '$item_path'..."
        rm -f "$item_path" > /dev/null
        return $?
    fi

    return 0
}

#===========================================================================
#   Executes a specified program with specified arguments and verbose
#   command line logging.
#---------------------------------------------------------------------------
#   PARAMETERS:
#       $@
#           Program path and all the parameters for it.
#===========================================================================
function execute_command() {

    write_verbose "Executing"
    begin_verbose
    for i in "$@"; do
        write_verbose_direct "\"$i\" "
    done

    end_verbose

    "$@"

    local error=$?

    if [[ "$error" != "0" ]] ; then
        write_error "Command execution failed. Error code $error"
        return 1
    fi

    return 0
}


#===========================================================================
#   Checks whether the specified command is available in the current system.
#---------------------------------------------------------------------------
#   $command_name
#       Name of the command which availability shall be determined.
#===========================================================================
function machine_has() {
    local command_name=$1

    hash "$command_name" > /dev/null 2>&1
    return $?
}


#===========================================================================
#   Writes a message about a modification done to the executing environment.
#---------------------------------------------------------------------------
#   $message
#       Modification message.
#===========================================================================
function write_modification() {
    local message=$1

    printf "%b\n" "${color_magenta:-1}$message${color_reset:-}" >&3
}


#===========================================================================
#   Writes a diagnostic message about script execution.
#---------------------------------------------------------------------------
#   $message
#       Diagnostic message.
#===========================================================================
function write_verbose() {
    local message=$1

    [[ $verbose == "1" ]] || return 0
    printf "%b\n" "${color_yellow:-}VERBOSE: $message${color_reset:-}" >&3
}


#===========================================================================
#   Starts a verbose log section.
#===========================================================================
function begin_verbose() {
    [[ $verbose == "1" ]]  || return 0
    printf "%b" "${color_yellow:-}" >&3
}


#===========================================================================
#   Stops a verbose log section.
#===========================================================================
function end_verbose() {
    [[ $verbose == "1" ]]  || return 0
    printf "%b\n" "${color_reset:-}" >&3
}


#===========================================================================
#   Writes a verbose message without any additional formatting applied.
#---------------------------------------------------------------------------
#   $message
#       Diagnostic message.
#===========================================================================
function write_verbose_direct() {
    local message=$1

    [[ $verbose == "1" ]] || return 0
    printf "%b" "$message" >&3
}


#===========================================================================
#   Writes a beginning of the build step.
#---------------------------------------------------------------------------
#   $step_name
#       Name of the step that shall be used to fold the log.
#
#   $message
#       Step message.
#===========================================================================
function begin_step() {
    local step_name=$1
    local message=$2

    printf "%b\n" "${color_cyan:-}$message${color_reset:-}" >&3
    last_step_name=$step_name
}


#===========================================================================
#   Writes a success message for the latest build step started.
#===========================================================================
function end_step() {

    printf "%b\n" "${color_green:-}Success${color_reset:-}" >&3
}


#===========================================================================
#   Writes an execution warning.
#---------------------------------------------------------------------------
#   $message
#       Warning message.
#===========================================================================
function write_warning() {
    local message=$1

    printf "%b\n" "${color_yellow:-}WARNING: $message${color_reset:-}" >&3
}


#===========================================================================
#   Writes an execution error.
#---------------------------------------------------------------------------
#   $message
#       Error message.
#===========================================================================
function write_error() {
    local message=$1

    printf "%b\n" "${color_red:-}ERROR: $message${color_reset:-}" >&2
}


############################################################################
#   Script start
############################################################################
initialize "$@"
main "$@"
