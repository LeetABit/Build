#!/usr/bin/env pwsh
#requires -version 6

<#
.SYNOPSIS
Buildstrapper script for Leet.Build toolchain.

.DESCRIPTION
This buildstrapper is responsible for installing Leet.Build from a configured feed and invoking build toolchain.

.PARAMETER RepositoryRoot
The path to the project's repository root directory. If not specified the current script root directory will be used.

.PARAMETER LeetBuildVersion
Version of the Leet.Build tools to use. If not specified the current script will try to read it from 'Leet.Build.json' file.

.PARAMETER LeetBuildRepository
Name of the PowerShellGet repository to use for Leet.Build module lookup.

.PARAMETER LeetBuildLocation
Location of a local Leet.Build version to use for the build.

.PARAMETER LogFilePath
Path to the build log file.

.PARAMETER Arguments
Arguments to be passed to the Leet.Build toolchain.

.NOTES
The 'Leet.Build.json' file stored under 'build' subdirectory of the repository root is used as a fallback location for some of the script configuration parameters.

.EXAMPLE
Example config file:
```json
{
  "$schema": "https://raw.githubusercontent.com/Leet/BuildTools/dev/schemas/Leet.Build.schema.json",
  "LeetBuildVersion": "0.0.0"
}
```
#>
[CmdletBinding(PositionalBinding = $False, DefaultParameterSetName = 'Remote')]
param(
    [Parameter( Position                    = 0                ,
                Mandatory                   = $False           )]
    [String]    $RepositoryRoot             = $PSScriptRoot    ,

    [Parameter( ParameterSetName            = 'Remote'         ,
                Mandatory                   = $True            )]
    [String]    $LeetBuildVersion                              ,

    [Parameter( ParameterSetName            = 'Remote'         ,
                Mandatory                   = $False           )]
    [String]    $LeetBuildRepository                           ,

    [Parameter( ParameterSetName            = 'Local'          ,
                Mandatory                   = $True            )]
    [String]    $LeetBuildLocation                             ,

    [String]    $LogFilePath                = 'Leet.Build.log' ,

    [Parameter( ValueFromRemainingArguments = $True            )]
    [String[]]  $Arguments
)

Set-StrictMode -Version 2

if ($env:VERBOSE_LOGGING)
{ $VerbosePreference     = 'Continue' }
  $ErrorActionPreference = 'Stop'
  $WarningPreference     = 'Continue'

$LastFoldName = ""

$LightPrefix = if ($env:APPVEYOR) { '1;9' } else { '1;3' }

$StepColor         = [char]0x001b + '[0;36m'
$ModificationColor = [char]0x001b + "[$($LightPrefix)5m"
$SuccessColor      = [char]0x001b + '[0;32m'
$DiagnosticColor   = [char]0x001b + "[$($LightPrefix)0m"
$DefaultColor      = [char]0x001b + '[0m'

<#
.SYNOPSIS
Invokes main script's procedure.
#>
function Invoke-MainScript () {
    try {
        Start-Logging
        Write-BuildstrapperInvocation (Get-Variable -Name MyInvocation -Scope 1 -ValueOnly)
        Write-BuildstrapperStep -Message "Initializing Leet.Build environment..." -FoldName "LeetBuildInitialization"
        Initialize-ScriptConfiguration
        Install-LeetBuild
        Import-LeetBuildModules
        Write-BuildstrapperSuccess

        Leet.Build\Invoke-LeetBuildCommand $script:RepositoryRoot $Arguments
        Write-Host
    } finally {
        Stop-Logging
    }
}

<#
.SYNOPSIS
Starts logging build messages to a specified log file.
#>
function Start-Logging {
    if ($script:LogFilePath) {
        Start-Transcript -Path $script:LogFilePath | Out-Null
    }
}

<#
.SYNOPSIS
Stops logging build messages to a specified log file.
#>
function Stop-Logging {
    if ($script:LogFilePath) {
        Stop-Transcript | Out-Null
    }
}

<#
.SYNOPSIS
Initializes the script by loading parameter values from configuration file or using default predefined values.

.NOTES
If the script parameter values are not specified they may be loaded from Leet.Build.json configuration file.
This configuration file should be located in 'build' subdirectory of the folder specified in $script:RepositoryRoot variable.
If the parameter value is not specified at command-line level nor in the configuration file then a default predefined value is being assigned to it or an error is being thrown depending on the parameter's nature. 
#>
function Initialize-ScriptConfiguration {
    Write-BuildstrapperDiagnostics "Initializing configuration from Leet.Build.json file..."

    Initialize-ConfigurationFromFile
    Initialize-LeetBuildVersion
}

<#
.SYNOPSIS
Initializes a script configuration values from Leet.Build.json configuration file.
#>
function Initialize-ConfigurationFromFile {
    $configFilePath = Join-Paths $script:RepositoryRoot ('build', 'Leet.Build.json')
    Write-Verbose "Initializing configuration using '$configFilePath' as fallback file."
    $script:ConfigurationJson = $Null

    if (Test-Path $configFilePath -PathType Leaf) {
        try {
            $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
            $script:ConfigurationJson = ConvertFrom-Json $configFileContent
        }
        catch { throw "Leet.Build.json file is not correct JSON file." }
    }
}

<#
.SYNOPSIS
Gets a value for the specified script's parameter from the Leet.Build.json configuration file.

.PARAMETER ParameterName
Name of the script's parameter which value shall be obtained.

.PARAMETER DefaultValue
A default value for the script's parameter that shall be used if parameter's value is not present in the configuration file.

.NOTES
If default value is $Null then this function throws an exception if the parameter's value is not present if the configuration file.
#>
function Get-ConfigurationFileParameterValue ( [String] $ParameterName         ,
                                               [String] $DefaultValue  = $Null ) {
    $result = $DefaultValue
    if ($script:ConfigurationJson -and (Get-Member -Name $ParameterName -InputObject $script:ConfigurationJson)) {
        $result = $script:ConfigurationJson.$ParameterName
    }
    
    if ($result -eq $Null) {
        throw "Could not find '$ParameterName' member in Leet.Build.json configuration file."
    }

    return $result
}

<#
.SYNOPSIS
Initializes $script:LeetBuildVersion configuration parameter value.

.NOTES
If no value for the parameter is not set at command-line nor in configuration file an error is thrown.
#>
function Initialize-LeetBuildVersion {
    if ($script:LeetBuildVersion) { return }

    $script:LeetBuildVersion = Get-ConfigurationFileParameterValue 'LeetBuildVersion'
    Write-Verbose "  -LeetBuildVersion = `"$script:LeetBuildVersion`""
}

<#
.SYNOPSIS
Installs Leet.Build tools according to the specified script parameters.
#>
function Install-LeetBuild {
    if ($script:LeetBuildLocation) {
        Install-LocalLeetBuild
    } else {
        Install-RemoteLeetBuild
    }
}

<#
.SYNOPSIS
Sets local Leet.Build directory path as a head of the $env:PSModulePath variable.
#>
function Install-LocalLeetBuild {
    Write-BuildstrapperDiagnostics "Setting '$script:LeetBuildLocation' as the head of the PowerShell modules path..."
    $env:PSModulePath = Set-DirectoryAsPathHead $script:LeetBuildLocation $env:PSModulePath
}

<#
.SYNOPSIS
Installs Leet.Build module and its all dependencies from PowerShell gallery.
#>
function Install-RemoteLeetBuild {
    Write-BuildstrapperDiagnostics "Installing Leet.Build from the PowerShell gallery..."
    if ($script:LeetBuildRepository) {
        Install-Module -Name 'Leet.Build'                        `
                       -RequiredVersion $script:LeetBuildVersion `
                       -Repository $script:LeetBuildRepository   `
                       -Scope CurrentUser                        `
                       -AllowPrerelease
    } else {
        Install-Module -Name 'Leet.Build'                        `
                       -RequiredVersion $script:LeetBuildVersion `
                       -Scope CurrentUser                        `
                       -AllowPrerelease
    }
}

<#
.SYNOPSIS
Imports Leet.Build modules.
#>
function Import-LeetBuildModules {
    Write-BuildstrapperDiagnostics "Importing Leet.Build module..."
    Import-Module 'Leet.Build' -Force -Global
}

<#
.SYNOPSIS
Adds a specified directory to the $Path variable head.

.PARAMETER Directory
A directory to be added to the $Path.

.PARAMETER Path
A value of the path set to which the directory shall be added.
#>
function Set-DirectoryAsPathHead ( [String] $Directory ,
                                   [String] $Path      ) {
    $normalizedDirectory = [System.IO.Path]::GetFullPath($Directory)
    $delimiter = if ($IsWindows) { ';' } else { ':' }
    $result = $Directory

    ($Path -split $delimiter) | ForEach-Object {
        $normalizedItem = [System.IO.Path]::GetFullPath($_)
        if ($IsWindows) {
            if ($normalizedItem -ine $normalizedDirectory) {
                $result += "$delimiter$_"
            }
        } else {
            if ($normalizedItem -cne $normalizedDirectory) {
                $result += "$delimiter$_"
            }
        }
    }

    return $result
}

<#
.SYNOPSIS
Combines a path with a sequence of child paths into a single path.

.DESCRIPTION
The Join-Paths cmdlet combines a path and sequence of child-paths into a single path. The provider supplies the path delimiters.

.PARAMETER Path
Specifies the main path (or paths) to which the child-path is appended. Wildcards are permitted.
The value of Path determines which provider joins the paths and adds the path delimiters. The Path parameter is required, although the parameter name ("Path") is optional.

.PARAMETER ChildPaths
Specifies the elements to append to the value of the Path parameter. Wildcards are permitted. The ChildPaths parameter is required, although the parameter name ("ChildPaths") is optional.

.NOTES
The cmdlets that contain the Path noun (the Path cmdlets) manipulate path names and return the names in a concise format that all Windows PowerShell providers can interpret. They are designed for use in programs and scripts where you want to display all or part of a path name in a particular format. Use them like you would use Dirname, Normpath, Realpath, Join, or other path manipulators.
You can use the path cmdlets with several providers, including the FileSystem, Registry, and Certificate providers.
This cmdlet is designed to work with the data exposed by any provider. To list the providers available in your session, type Get-PSProvider. For more information, see about_Providers.

.EXAMPLE
# This function call returns 'C:\First\Second\Third\Fourth.file'
Join-Paths 'C:' ('First\', '\Second', '\Third\', 'Fourth.file')
#>
function Join-Paths ( [String]   $Path       ,
                            [String[]] $ChildPaths ) {
    $isWeb = ($Path -like 'http*')
    $ChildPaths | ForEach-Object { $Path = if ($isWeb) { "$Path/$_" } else { Join-Path $Path $_ } }
    return $Path
}

<#
.SYNOPSIS
Writes to the host information about the specified invocation.

.PARAMETER Invocation
Invocation which information shall be written.
#>
function Write-BuildstrapperInvocation( [System.Management.Automation.InvocationInfo] $Invocation ) {
    Write-Verbose "Executing: '$($Invocation.MyCommand)' with parameters:"
    $Invocation.BoundParameters.Keys | ForEach-Object {
        Write-Verbose "  -$_ = `"$($Invocation.BoundParameters[$_])`""
    }
}

<#
.SYNOPSIS
Writes a message that informs about state change in the current system.

.PARAMETER Message
Installation message to be written by the host.
#>
function Write-BuildstrapperModification ( [String] $Message ) {
    Write-Host "$script:ModificationColor$Message$script:DefaultColor"
}

<#
.SYNOPSIS
Writes a message that informs about state change in the current system.

.PARAMETER Message
Installation message to be written by the host.
#>
function Write-BuildstrapperDiagnostics ( [String] $Message ) {
    Write-Host "$script:DiagnosticColor$Message$script:DefaultColor"
}

<#
.SYNOPSIS
Writes a specified build step message string to the host.

.PARAMETER Message
Step information message to be written by the host.

.PARAMETER FoldName
Name of the fold to start if supported by the host.
#>
function Write-BuildstrapperStep ( [String] $Message  ,
                      [String] $FoldName ) {
    $preamble = ""

    if ($env:TRAVIS) {
        $preamble = "travis_fold:start:$FoldName`r"
    }

    Write-Host "$preamble$script:StepColor$Message$script:DefaultColor"
    $script:LastFoldName = $FoldName
}

<#
.SYNOPSIS
Writes a specified build step success message string to the host.
#>
function Write-BuildstrapperSuccess () {
    $preamble = ""

    if ($env:TRAVIS) {
        $preamble = "travis_fold:end:$script:LastFoldName`r"
    }

    Write-Host ("$preamble$script:SuccessColor" + "Success.$script:DefaultColor")
    Write-Host
}

######################################################################################################################
# Main
######################################################################################################################

Invoke-MainScript
