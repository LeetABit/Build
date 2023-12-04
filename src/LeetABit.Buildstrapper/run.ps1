#!/usr/bin/env pwsh
#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

<#
.SYNOPSIS
    Command execution proxy for LeetABit.Build system that performs all the necessary initialization.
.DESCRIPTION
    This script is responsible for carrying over any build command to the registered modules through LeetABit.Build\Build-Repository cmdlet. To make this possible the script is also responsible for finding and installing required version of the LeetABit.Build modules in the system.
    The script may be instructed in two ways:
    First one by specifying version of the required LeetABit.Build module. This orders this script to download requested version of LeetABit.Build module from available PSRepositories when it is missing in the system.
    Second one by providing path to the directory that contains required LeetABit.Build module files. This path will be added to process $env:PSModulePath variable if not already present there.
.PARAMETER TaskName
    Name of the build task to invoke.
.PARAMETER ToolsetVersion
    Version of the LeetABit.Build tools to use. If not specified the current script will try to read it from 'LeetABit.Build.json' file.
.PARAMETER ToolsetLocation
    Location of a local LeetABit.Build version to use for the build.
.PARAMETER RepositoryRoot
    The path to the project's repository root directory. If not specified the current script root directory will be used.
.PARAMETER LogFilePath
    Path to the build log file.
.PARAMETER PreservePreferences
    Indicates whether the buildstrapper script shall not modify preference variables.
.PARAMETER UnloadModules
    Indicates whether the buildstrapper script shall unload all LeetABit.Build modules before importing them.
.PARAMETER Arguments
    Arguments to be passed to the LeetABit.Build toolset.
.EXAMPLE
    PS > ./run.ps1 help

    Use this command to display available build commands and learn about available parameters when the required LeetABit.Build modules configuration is available in the JSON configuration file or in environmental variable.
.EXAMPLE
    PS > ./run.ps1 help -ToolsetVersion 1.0.0

    Use this command to display available build commands and learn about available parameters when a specific version of LeetABit.Build module is expected.
.EXAMPLE
    PS > ./run.ps1 help -ToolsetLocation ~\LeetABit.Build

    Use this command to display available build commands and learn about available parameters for a LeetABit.Build stored in the specified location.
.EXAMPLE
    PS > ./run.ps1 -TaskName test -RepositoryRoot ~\Repository

    Use this command to execute 'test' command against repository located at ~\Repository location using LeetABit.Build configured in JSON file or via environmental variable.
    Configuration LeetABit.Build.json file need to be located under 'build' subfolder of the repository ~\Repository location.
.EXAMPLE
    PS > ./run.ps1 build -LogFilePath ~\LeetABit.Build.log

    Use this command to execute 'build' command against repository located at current location using LeetABit.Build configured in JSON file or via environmental variable and store execution log in ~\LeetABit.Build.log file.
.EXAMPLE
    PS > ./run.ps1 build -PreservePreferences

    Use this command to execute 'build' command without modification of PowerShell preference variables.
    By default this scripts modifies some of the preference variables bo values better suited for build script, i.e. error shall break execution, etc. All the preference variables are restored after each command execution.
.EXAMPLE
    PS > ./run.ps1 build -UnloadModules

    Use this command to execute 'build' command and unloads all LeetABit.Build modules from PowerShell before executing the command.
.NOTES
    Any parameter for LeetABit.Build system may be provided in three ways:
    1. Explicitly via PowerShell command arguments.
    2. JSON property in 'LeetABit.Build.json' file stored under 'build' subdirectory of the specified repository root.
    3. Environmental variable with a 'LeetABitBuild_' prefix before parameter name.

    The list above also defines precedence order of the importance.

    LeetABit.Build.json configuration file should be a simple JSON object with properties which names match parameter name and which values shall be used as arguments for the parameters.
    A JSON schema for the configuration file is available at https://raw.githubusercontent.com/LeetABit/Build/master/schema/LeetABit.Build.schema.json
.LINK
    LeetABit.Build\Build-Repository
#>

using namespace System.Collections
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation

[CmdletBinding(SupportsShouldProcess = $True,
               ConfirmImpact = 'Low',
               PositionalBinding = $False,
               DefaultParameterSetName = 'Local')]
Param (
    [Parameter(Position = 0,
               Mandatory = $False,
               ValueFromPipeline = $True,
               ValueFromPipelineByPropertyName = $True)]
    [AllowEmptyString()]
    [AllowEmptyCollection()]
    [String[]]
    $TaskName,

    [Parameter(HelpMessage = 'Enter version of the LeetABit.Build to be used to run build scripts.',
               ParameterSetName = 'Remote',
               Mandatory = $True,
               ValueFromPipeline = $True,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ [SemanticVersion]::Parse($_) })]
    [String]
    $ToolsetVersion,

    [Parameter(HelpMessage = 'Enter path to a LeetABit.Build directory to be used to run build scripts.',
               ParameterSetName = 'Local',
               Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [String]
    $ToolsetLocation,

    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [String]
    $RepositoryRoot = $PSScriptRoot,

    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [ValidateScript({ [System.IO.Path]::GetFullPath($_) })]
    [ValidateScript({ -not (Test-Path -Path $_ -PathType Container) })]
    [String]
    $LogFilePath = 'LeetABit.Build.log',

    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [Switch]
    $PreservePreferences,

    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $False)]
    [Switch]
    $UnloadModules,

    [Parameter(Mandatory = $False,
               ValueFromPipeline = $False,
               ValueFromPipelineByPropertyName = $True,
               ValueFromRemainingArguments = $True)]
    [String[]]
    $Arguments
)

DynamicParam {
    Set-StrictMode -Version 3.0
    function Initialize-ScriptConfiguration {
        <#
        .SYNOPSIS
            Initializes the script by loading parameter values from configuration file or using default predefined values.
        .NOTES
            If the script parameter values are not specified they may be loaded from LeetABit.Build.json configuration file.
            This configuration file should be located in 'build' subdirectory of the folder specified in $script:RepositoryRoot variable.
            If the parameter value is not specified at command-line level nor in the configuration file then a default predefined value is being assigned to it or an error is being thrown depending on the parameter's nature.
        #>

        $configurationJson = Read-ConfigurationFromFile
        $script:ToolsetVersion = Get-ParameterValue 'ToolsetVersion' $configurationJson
        $script:ToolsetLocation = Get-ParameterValue 'ToolsetLocation' $configurationJson
    }


    function Read-ConfigurationFromFile {
        <#
        .SYNOPSIS
            Reads a script configuration values from LeetABit.Build.json configuration file.
        .PARAMETER RepositoryRoot
            The path to the project's repository root directory. If not specified the current script root directory will be used.
        #>

        Param (
            [String]
            $RepositoryRoot = $PSScriptRoot
        )

        $result = @{}
        Get-ChildItem -Path $RepositoryRoot -Filter 'LeetABit.Build.json' -Recurse | Foreach-Object {
            $configFilePath = $_.FullName
            Write-Verbose "Reading fallback configuration from '$configFilePath' file."

            if (Test-Path $configFilePath -PathType Leaf) {
                try {
                    $configFileContent = Get-Content -Raw -Encoding UTF8 -Path $configFilePath
                    ConvertFrom-Json $configFileContent | ConvertTo-Hashtable | ForEach-Object {
                        foreach ($key in $_.Keys) {
                            $result[$key] = $_[$key]
                        }
                    }
                }
                catch {
                    Write-Error "'$configFilePath' file is not a correct JSON file."
                    throw $_
                }
            }
        }

        $result
    }


    function ConvertTo-Hashtable {
        <#
        .SYNOPSIS
            Converts an input object to a HAshtable.
        .PARAMETER InputObject
            Object to convert.
        #>
        [CmdletBinding(PositionalBinding = $False)]
        [OutputType([Hashtable])]
        param (
            [Parameter(Position = 0,
                       Mandatory = $False,
                       ValueFromPipeline = $True,
                       ValueFromPipelineByPropertyName = $True)]
            [Object]
            [AllowNull()]
            $InputObject
        )

        process {
            if ($Null -eq $InputObject -or $InputObject -is [IDictionary]) {
                $InputObject
            }
            elseif ($InputObject -is [IEnumerable] -and $InputObject -isnot [string]) {
                $InputObject | ForEach-Object {
                    ConvertTo-Hashtable -InputObject $_
                }
            } elseif ($InputObject -is [PSObject]) {
                $hash = @{}
                foreach ($property in $InputObject.PSObject.Properties) {
                    $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
                }

                $hash
            } else {
                $InputObject
            }
        }
    }


    function Install-BuildToolset {
        <#
        .SYNOPSIS
            Installs LeetABit.Build tools according to the specified script parameters.
        #>

        param ()

        if ($script:ToolsetLocation) {
            Install-LocalBuildToolset
        } elseif ($script:ToolsetVersion) {
            Install-RemoteBuildToolset
        }
    }


    function Install-LocalBuildToolset {
        <#
        .SYNOPSIS
            Sets local LeetABit.Build directory path as a head of the $env:PSModulePath variable.
        #>

        param ()

        Write-Verbose "Setting '$script:ToolsetLocation' as the head of the PowerShell modules path..."
        $normalizedLocation = if ([System.IO.Path]::IsPathRooted($script:ToolsetLocation)) {
            $script:ToolsetLocation
        }
        else {
            Join-Path (Get-Location) $script:ToolsetLocation
        }

        $env:PSModulePath = Join-DirectoryAndPath $normalizedLocation $env:PSModulePath
    }


    function Install-RemoteBuildToolset {
        <#
        .SYNOPSIS
            Installs LeetABit.Build module and its all dependencies from the available PowerShell repositories.
        #>

        param ()

        if (-not (Get-Module -FullyQualifiedName @{ ModuleName='LeetABit.Build'; ModuleVersion=$script:ToolsetVersion } -ListAvailable)) {
            Write-Verbose "Installing LeetABit.Build v$script:ToolsetVersion from the available PowerShell repositories..."
            Install-Module -Name 'LeetABit.Build'                        `
                           -RequiredVersion $script:ToolsetVersion `
                           -Scope CurrentUser                        `
                           -AllowPrerelease                          `
                           -Force                                    `
                           -ErrorAction Stop
        }
    }


    function Import-BuildToolsetModules {
        <#
        .SYNOPSIS
            Imports LeetABit.Build modules.
        .PARAMETER UnloadModules
            Indicates whether the buildstrapper script shall unload all LeetABit.Build modules before importing them.
        #>

        param (
            [Parameter(Mandatory = $False,
                       ValueFromPipeline = $False,
                       ValueFromPipelineByPropertyName = $False)]
            [Switch]
            $UnloadModules
        )

        process {
            if ($UnloadModules) {
                Remove-Module 'LeetABit.*' -Force
            }

            Import-Module 'LeetABit.Build' -Global -ErrorAction Stop
        }
    }


    function Join-DirectoryAndPath {
        <#
        .SYNOPSIS
            Joins a specified directory and a $Path variable if it does not contain the directory yet.
        .PARAMETER Directory
            A directory to be added to the $Path.
        .PARAMETER Path
            A value of the path set to which the directory shall be added.
        #>

        param (
            [String]
            $Directory,

            [String]
            $Path
        )

        $normalizedDirectory = [System.IO.Path]::GetFullPath($Directory)
        $delimiter = [System.IO.Path]::PathSeparator
        $result = $normalizedDirectory

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


    function Get-ParameterValue {
        <#
        .SYNOPSIS
            Gets a value for the specified script's parameter if not specified via command line using environment variables or LeetABit.Build.json configuration file.
        .PARAMETER ParameterName
            Name of the script's parameter which value shall be set.
        .PARAMETER ConfigurationJson
            Custom PowerShell object with JSON configuration.
        #>

        param (
            [String]
            $ParameterName,

            [PSCustomObject]
            $ConfigurationJson
        )

        $parameterNames = @("LeetABitBuild_$ParameterName", $ParameterName)

        foreach ($currentParameterName in $parameterNames) {
            if (Test-Path "variable:script:$currentParameterName") {
                $result =  Get-Content "variable:script:$currentParameterName"
                if ($result) {
                    $result
                    return
                }
            }

            if ($ConfigurationJson -and $ConfigurationJson.ContainsKey($currentParameterName)) {
                $result = $ConfigurationJson[$currentParameterName]
                Write-Verbose "  -$ParameterName = `"$result`""
                $result
                return
            }

            if (Test-Path "env:\$currentParameterName") {
                $result = Get-Content "env:\$currentParameterName"
                if ($result) {
                    Write-Verbose "  -$ParameterName = `"$result`""
                    $result
                    return
                }
            }
        }

        $Null
    }

    function Import-RepositoryExtension {
        <#
        .SYNOPSIS
            Executes LeetABit.Build.Repository scripts from the specified repository.
        .PARAMETER RepositoryRoot
            The directory to the repository's root directory path.
        #>
        [CmdletBinding(PositionalBinding = $False)]

        param (
            [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                       Position = 0,
                       Mandatory = $True,
                       ValueFromPipeline = $False,
                       ValueFromPipelineByPropertyName = $False)]
            [String]
            $RepositoryRoot)

        process {
            Get-ChildItem -Path $RepositoryRoot -Filter "LeetABit.Build.Repository.ps1" -Recurse | ForEach-Object {
                [void](. "$_")
            }
        }
    }

    if (-not $PSBoundParameters.ContainsKey('RepositoryRoot')) {
        $RepositoryRoot = $PSScriptRoot
    }

    Initialize-ScriptConfiguration

    if ($script:ToolsetLocation -or ($script:ToolsetVersion -and (Get-Module -FullyQualifiedName @{ ModuleName='LeetABit.Build'; ModuleVersion=$script:ToolsetVersion } -ListAvailable))) {
        if ($script:ToolsetLocation) {
            Install-LocalBuildToolset
        }

        Import-BuildToolsetModules
        Import-RepositoryExtension $RepositoryRoot

        LeetABit.Build.Extensibility\Get-DynamicParameters
    }
}

Begin {
    Set-StrictMode -Version 3.0
    function Start-Logging {
        <#
        .SYNOPSIS
            Starts logging build messages to a specified log file.
        #>
        [CmdletBinding(PositionalBinding = $False,
                       SupportsShouldProcess = $True,
                       ConfirmImpact = "Low")]

        param ()

        process {
            if ($script:LogFilePath) {
                if ($PSCmdlet.ShouldProcess("Transcript to a file: '$script:LogFilePath'",
                                            "Start")) {
                    try {
                        Start-Transcript -Path $script:LogFilePath | Out-Null
                    }
                    catch [PSInvalidOperationException] {
                        Start-Transcript -Path $script:LogFilePath | Out-Null
                    }
                }
            }
        }
    }


    function Stop-Logging {
        <#
        .SYNOPSIS
            Stops logging build messages to a specified log file.
        #>
        [CmdletBinding(PositionalBinding = $False,
                       SupportsShouldProcess = $True,
                       ConfirmImpact = "Low")]

        param ()

        if ($script:LogFilePath) {
            try {
                if ($PSCmdlet.ShouldProcess("Transcript to a file: '$script:LogFilePath'", "Stop")) {
                    Stop-Transcript -ErrorAction 'SilentlyContinue' | Out-Null
                }
            }
            catch {
                Write-Verbose "Could not stop transcript: $_"
            }
        }
    }


    function Set-PreferenceVariables {
        <#
        .SYNOPSIS
            Sets global preference variables to its local values to propagate them in module functions.
        .PARAMETER PreservePreferences
            Indicates whether the current preference variables shall be preserved by this function. If the value is set to $True this method is a no-op.
        .PARAMETER OverrideErrorAction
            Indicates whether the Error action preference variable shall be set to 'Stop'.
        .PARAMETER OverrideInformationAction
            Indicates whether the Information action preference variable shall be set to 'Continue'.
        #>
        [CmdletBinding(PositionalBinding = $False,
                       SupportsShouldProcess = $True,
                       ConfirmImpact = 'Low')]

        param (
            [Switch]
            $PreservePreferences,
            [Switch]
            $OverrideErrorAction,
            [Switch]
            $OverrideInformationAction
        )

        process {
            if (-not $PreservePreferences) {
                if ($PSCmdlet.ShouldProcess("Global preference variables.", "Modify with backup.")) {
                    if ($Env:CI -or $OverrideErrorAction) {
                        $script:ErrorActionPreference = 'Stop'
                    }

                    if ($Env:CI -or $OverrideInformationAction) {
                        $script:InformationPreference = 'Continue'
                    }

                    if ($Env:CI) {
                        $script:VerbosePreference = 'Continue'
                    }

                    if ($Env:CI) {
                        $script:ProgressPreference = 'SilentlyContinue'
                    }
                }
            }
        }
    }


    function Write-Invocation {
        <#
        .SYNOPSIS
            Writes a verbose message about the specified invocation.
        .PARAMETER Invocation
            Invocation which information shall be written.
        #>

        param (
            [InvocationInfo]
            $Invocation
        )

        Write-Verbose "Executing: '$($Invocation.MyCommand.Name)' with parameters:"
        $Invocation.BoundParameters.Keys | ForEach-Object {
            Write-Verbose "  -$_ = `"$($Invocation.BoundParameters[$_])`""
        }
    }

    try {
        $OverrideErrorAction       = -not $PSBoundParameters.ContainsKey('ErrorAction')
        $OverrideInformationAction = -not $PSBoundParameters.ContainsKey('InformationAction')

        Start-Logging
        Set-PreferenceVariables -PreservePreferences:$script:PreservePreferences `
                                -OverrideErrorAction:$OverrideErrorAction `
                                -OverrideInformationAction:$OverrideInformationAction
        Write-Invocation $MyInvocation
        Initialize-ScriptConfiguration
        Install-BuildToolset
        Import-BuildToolsetModules -UnloadModules:$script:UnloadModules
    }
    catch {
        Stop-Logging
        throw $_
    }
}

Process {
    try {
        LeetABit.Build\Build-Repository -RepositoryRoot $script:RepositoryRoot -TaskName $script:TaskName -NamedArguments $PSBoundParameters -UnknownArguments $script:Arguments
    }
    catch {
        Stop-Logging
        throw $_
    }
}

End {
    Stop-Logging
}
