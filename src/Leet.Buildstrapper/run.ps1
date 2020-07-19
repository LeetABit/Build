#!/usr/bin/env pwsh
#requires -version 6

using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation

<#
.SYNOPSIS
Buildstrapper script for Leet.Build toolchain.

.DESCRIPTION
This buildstrapper is responsible for installing Leet.Build from a configured feed and invoking build toolchain.

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
[CmdletBinding(SupportsShouldProcess = $True,
               ConfirmImpact = 'Low',
               PositionalBinding = $False,
               DefaultParameterSetName = 'Remote')]

param (
    # Name of the build task to invoke.
    [Parameter(Position = 0,
               Mandatory = $False,
               ValueFromPipeline = $True,
               ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [String]
    $TaskName,

    # The path to the project's repository root directory. If not specified the current script root directory will be used.
    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [String]
    $RepositoryRoot = $PSScriptRoot,

    # Version of the Leet.Build tools to use. If not specified the current script will try to read it from 'Leet.Build.json' file.
    [Parameter(HelpMessage = 'Enter version of the Leet.Build to be used to run build scripts.',
               ParameterSetName = 'Remote',
               Mandatory = $True,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ [SemanticVersion]::Parse($_) })]
    [String]
    $LeetBuildVersion,

    # Location of a local Leet.Build version to use for the build.
    [Parameter(HelpMessage = 'Enter path to a Leet.Build directory to be used to run build scripts.',
               ParameterSetName = 'Local',
               Mandatory = $True,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [String]
    $LeetBuildLocation,

    # Path to the build log file.
    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ [System.IO.Path]::GetFullPath($_) })]
    [ValidateScript({ -not (Test-Path -Path $_ -PathType Container) })]
    [String]
    $LogFilePath = 'Leet.Build.log',

    # Indicates whether the buildstrapper script shall not modify preference variables.
    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [Switch]
    $PreservePreferences,

    # Indicates whether the buildstrapper script shall unload all Leet.Build modules before importing them.
    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [Switch]
    $UnloadModules,

    # Arguments to be passed to the Leet.Build toolchain.
    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $True,
               ValueFromRemainingArguments = $True)]
    [String[]]
    $Arguments
)

dynamicparam {
    if (Test-Path variable:LeetBuildVersion) {
        $extensibilityModule = Get-Module -FullyQualifiedName @{ ModuleName='Leet.Build.Extensibility'; ModuleVersion=$LeetBuildVersion }
    }
    else {
        $extensibilityModule = Get-Module -Name 'Leet.Build.Extensibility'
    }

    if (-not $extensibilityModule) {
        return
    }

    $parameterTypeName = 'System.Management.Automation.RuntimeDefinedParameter'
    $attributes = New-Object -Type System.Management.Automation.ParameterAttribute
    $attributes.Mandatory = $false
    $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)

    $result = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
    $buildExtensionCommand = Get-Command -FullyQualifiedModule @{ ModuleName='Leet.Build.Extensibility'; ModuleVersion=$extensibilityModule.Version } -Name 'Get-BuildExtension'
    & $buildExtensionCommand | ForEach-Object {
        $extensionPrefix = $($_.Name.Replace('.', [String]::Empty))

        ForEach-Object { $_.Tasks.Values } |
        ForEach-Object { $_.Jobs } |
        ForEach-Object {
            if ($_ -is [ScriptBlock]) {
                if ($_.Ast.ParamBlock) {
                    $_.Ast.ParamBlock.Parameters | ForEach-Object {
                        $parameterAst = $_
                        $parameterName = $_.Name.VariablePath.UserPath

                        ($parameterName, "$($extensionPrefix)_$parameterName") | ForEach-Object {
                            $dynamicParam = New-Object -Type $parameterTypeName ($parameterName, $parameterAst.StaticType, $attributeCollection)
                            if (-not ($result.Keys -contains $dynamicParam.Name)) {
                                $result.Add($dynamicParam.Name, $dynamicParam)
                            }
                        }
                    }
                }
            }
        }
    }

    $result
}

begin {
    function Start-Logging {
        <#
        .SYNOPSIS
        Starts logging build messages to a specified log file.
        #>

        [SuppressMessage('PSUseShouldProcessForStateChangingFunctions',
                         '',
                         Justification = 'Functions called by this function will handle the confirmation.')]

        param ()

        if ($script:LogFilePath) {
            Start-Transcript -Path $script:LogFilePath | Out-Null
        }
    }


    function Stop-Logging {
        <#
        .SYNOPSIS
        Stops logging build messages to a specified log file.
        #>

        [SuppressMessage('PSUseShouldProcessForStateChangingFunctions',
                         '',
                         Justification = 'Functions called by this function will handle the confirmation.')]
        [SuppressMessage('PSAvoidUsingEmptyCatchBlock',
                         '',
                         Justification = 'Empty catch block is the only way to make Stop-Transcript work with -WhatIf applied to Start-Transcript.')]

        param ()

        if ($script:LogFilePath) {
            try {
                Stop-Transcript -ErrorAction 'SilentlyContinue' | Out-Null
            }
            catch { }
        }
    }


    function Set-PreferenceVariables {
        <#
        .SYNOPSIS
        Sets global peference variables to its local values to propagate them in module functions.
        #>
        [CmdletBinding(PositionalBinding = $False,
                       SupportsShouldProcess = $True,
                       ConfirmImpact = 'Low')]

        param ()

        process {
            if (-not $Script:PreservePreferences) {
                if ($PSCmdlet.ShouldProcess("Global preference variables.", "Modify with backup.")) {
                    $global:ConfirmPreference     = $ConfirmPreference
                    $global:DebugPreference       = $DebugPreference
                    $global:ErrorActionPreference = if ($Env:CI -and $OverrideErrorAction) { 'Stop' } else { $ErrorActionPreference }
                    $global:InformationPreference = if ($OverrideInformationAction) { 'Continue' } else { $InformationPreference }
                    $global:ProgressPreference    = if ($Env:CI -and $OverrideProgressAction) { 'SilentlyContinue' } else { $ProgressPreference }
                    $global:VerbosePreference     = if (('True', '1') -contains $env:LeetBuild_Verbose -and $OverrideVerbose) { 'Continue' } else { $VerbosePreference }
                    $global:WarningPreference     = if ($Env:CI -and $OverrideWarningAction) { 'Continue' } else { $WarningPreference }
                    $global:WhatIfPreference      = $WhatIfPreference
                }
            }
        }
    }


    function Reset-PreferenceVariables {
        <#
        .SYNOPSIS
        Resets global peference variables to the values from before script run.
        #>
        [CmdletBinding(PositionalBinding = $False,
                       SupportsShouldProcess = $True,
                       ConfirmImpact = 'Low')]

        param ()

        if (-not $Script:PreservePreferences) {
            if ($PSCmdlet.ShouldProcess("Global preference variables.", "Revert changes.")) {
                $global:ConfirmPreference     = $script:ConfirmPreferenceBackup
                $global:DebugPreference       = $script:DebugPreferenceBackup
                $global:ErrorActionPreference = $script:ErrorActionPreferenceBackup
                $global:InformationPreference = $script:InformationPreferenceBackup
                $global:ProgressPreference    = $script:ProgressPreferenceBackup
                $global:VerbosePreference     = $script:VerbosePreferenceBackup
                $global:WarningPreference     = $script:WarningPreferenceBackup
                $global:WhatIfPreference      = $script:WhatIfPreferenceBackup
            }
        }
    }


    function Initialize-ScriptConfiguration {
        <#
        .SYNOPSIS
        Initializes the script by loading parameter values from configuration file or using default predefined values.

        .NOTES
        If the script parameter values are not specified they may be loaded from Leet.Build.json configuration file.
        This configuration file should be located in 'build' subdirectory of the folder specified in $script:RepositoryRoot variable.
        If the parameter value is not specified at command-line level nor in the configuration file then a default predefined value is being assigned to it or an error is being thrown depending on the parameter's nature.
        #>

        param ()

        Initialize-ConfigurationFromFile
        Initialize-LeetBuildVersion
    }


    function Initialize-ConfigurationFromFile {
        <#
        .SYNOPSIS
        Initializes a script configuration values from Leet.Build.json configuration file.
        #>

        param ()

        $script:ConfigurationJson = @{}
        Get-ChildItem -Path $script:RepositoryRoot -Filter 'Leet.Build.json' -Recurse | Foreach-Object {
            $configFilePath = $_.FullName
            Write-Verbose "Initializing configuration using '$configFilePath' as fallback file."

            if (Test-Path $configFilePath -PathType Leaf) {
                try {
                    $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
                    $configJson = ConvertFrom-Json $configFileContent
                    $configJson.psobject.Properties | ForEach-Object {
                        $script:ConfigurationJson | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value -Force
                    }
                }
                catch {
                    Write-Error "'$configFilePath' file is not a correct JSON file."
                    throw
                }
            }
        }
    }


    function Get-ConfigurationFileParameterValue {
        <#
        .SYNOPSIS
        Gets a value for the specified script's parameter from the Leet.Build.json configuration file.

        .NOTES
        If default value is $Null then this function throws an exception if the parameter's value is not present if the configuration file.
        #>

        param (
            # Name of the script's parameter which value shall be obtained.
            [String]
            $ParameterName,

            # A default value for the script's parameter that shall be used if parameter's value is not present in the configuration file.
            [String]
            $DefaultValue = ''
        )

        Write-Verbose "Reading parameter '$ParameterName' from 'Leet.Build.json' with default fallback value '$DefaultValue'."
        $result = $DefaultValue
        if ($script:ConfigurationJson -and (Get-Member -Name $ParameterName -InputObject $script:ConfigurationJson)) {
            $result = $script:ConfigurationJson.$ParameterName
        }

        if (-not $result) {
            throw "Could not find '$ParameterName' member value in Leet.Build.json configuration file."
        }

        return $result
    }


    function Initialize-LeetBuildVersion {
        <#
        .SYNOPSIS
        Initializes $script:LeetBuildVersion configuration parameter value.

        .NOTES
        If no value for the parameter is not set at command-line nor in configuration file an error is thrown.
        #>

        param ()

        if ($script:LeetBuildVersion) { return }

        $script:LeetBuildVersion = Get-ConfigurationFileParameterValue 'LeetBuildVersion'
        Write-Verbose "  -LeetBuildVersion = `"$script:LeetBuildVersion`""
    }


    function Install-LeetBuild {
        <#
        .SYNOPSIS
        Installs Leet.Build tools according to the specified script parameters.
        #>

        param ()

        if ($script:LeetBuildLocation) {
            Install-LocalLeetBuild
        } else {
            Install-RemoteLeetBuild
        }
    }


    function Install-LocalLeetBuild {
        <#
        .SYNOPSIS
        Sets local Leet.Build directory path as a head of the $env:PSModulePath variable.
        #>

        param ()

        Write-Verbose "Setting '$script:LeetBuildLocation' as the head of the PowerShell modules path..."
        $env:PSModulePath = Join-DirectoryAndPath $script:LeetBuildLocation $env:PSModulePath
    }


    function Install-RemoteLeetBuild {
        <#
        .SYNOPSIS
        Installs Leet.Build module and its all dependencies from the available PowerShell repositories.
        #>

        param ()

        if (-not (Get-Module -FullyQualifiedName @{ ModuleName='Leet.Build'; ModuleVersion=$script:LeetBuildVersion } -ListAvailable)) {
            Write-Verbose "Installing Leet.Build v$script:LeetBuildVersion from the available PowerShell repositories..."
            Install-Module -Name 'Leet.Build'                        `
                           -RequiredVersion $script:LeetBuildVersion `
                           -Scope CurrentUser                        `
                           -AllowPrerelease                          `
                           -Force                                    `
                           -ErrorAction Stop
        }
    }


    function Import-LeetBuildModules {
        <#
        .SYNOPSIS
        Imports Leet.Build modules.
        #>

        param (
            # Indicates whether the buildstrapper script shall unload all Leet.Build modules before importing them.
            [Parameter(Mandatory = $False,
                       ValueFromPipeline = $False,
                       ValueFromPipelineByPropertyName = $False)]
            [Switch]
            $UnloadModules
        )

        if ($UnloadModules) {
            Remove-Module 'Leet.*' -Force
        }

        Import-Module 'Leet.Build' -Force -Global -ErrorAction Stop
    }


    function Join-DirectoryAndPath {
        <#
        .SYNOPSIS
        Joins a specified directory and a $Path variable if it does not contain the direcory yet.
        #>

        param (
            # A directory to be added to the $Path.
            [String]
            $Directory,

            # A value of the path set to which the directory shall be added.
            [String]
            $Path
        )

        $normalizedDirectory = [System.IO.Path]::GetFullPath($Directory)
        $delimiter = [System.IO.Path]::PathSeparator
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


    function Write-BuildstrapperInvocation {
        <#
        .SYNOPSIS
        Writes to the host information about the specified invocation.
        #>

        param (
            # Invocation which information shall be written.
            [InvocationInfo]
            $Invocation
        )

        Write-Verbose "Executing: '$($Invocation.MyCommand.Name)' with parameters:"
        $Invocation.BoundParameters.Keys | ForEach-Object {
            Write-Verbose "  -$_ = `"$($Invocation.BoundParameters[$_])`""
        }
    }

    try {
        Set-StrictMode -Version 2

        $ConfirmPreferenceBackup     = $global:ConfirmPreference
        $DebugPreferenceBackup       = $global:DebugPreference
        $ErrorActionPreferenceBackup = $global:ErrorActionPreference
        $InformationPreferenceBackup = $global:InformationPreference
        $ProgressPreferenceBackup    = $global:ProgressPreference
        $VerbosePreferenceBackup     = $global:VerbosePreference
        $WarningPreferenceBackup     = $global:WarningPreference
        $WhatIfPreferenceBackup      = $global:WhatIfPreference

        $OverrideErrorAction       = -not $PSBoundParameters.ContainsKey('ErrorAction')
        $OverrideInformationAction = -not $PSBoundParameters.ContainsKey('InformationAction')
        $OverrideProgressAction    = -not $PSBoundParameters.ContainsKey('ProgressAction')
        $OverrideVerbose           = -not $PSBoundParameters.ContainsKey('Verbose')
        $OverrideWarningAction     = -not $PSBoundParameters.ContainsKey('WarningAction')

        Start-Logging
        Set-PreferenceVariables
        Write-BuildstrapperInvocation -Invocation $MyInvocation
        Initialize-ScriptConfiguration
        Install-LeetBuild
        Import-LeetBuildModules -UnloadModules:$script:UnloadModules
    }
    catch {
        Stop-Logging
        throw
    }
}

process {
    try {
        Leet.Build\Build-Repository -RepositoryRoot $script:RepositoryRoot -TaskName $script:TaskName -NamedArguments $PSBoundParameters -UnknownArguments $script:Arguments
    }
    catch {
        throw
    }
    finally {
        Reset-PreferenceVariables
        Stop-Logging
    }
}

end {
    Stop-Logging
}
