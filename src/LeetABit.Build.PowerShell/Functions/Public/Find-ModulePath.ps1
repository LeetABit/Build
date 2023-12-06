#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Find-ModulePath {
    <#
    .SYNOPSIS
        Finds paths to all PowerShell module directories in the specified path.
    .DESCRIPTION
        The Find-ModulePath cmdlet searches for a PowerShell modules in the specified location and returns a path to each module's directory found.
    .PARAMETER Path
        Path to the search directory.
    .PARAMETER LiteralPath
        Literal path to the search directory.
    .EXAMPLE
        PS > Find-ModulePath -Path "C:\Modules"

        Returns paths to all PowerShell module directories located in the specified location.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $False,
                   DefaultParameterSetName = 'Path')]
    [OutputType([String])]

    param (
        [Parameter(HelpMessage = 'Provide path to the search directory.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        [Parameter(HelpMessage = 'Provide path to the search directory.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath,

        [Switch]
        $Recurse)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $parameters = @{ "$($PSCmdlet.ParameterSetName)" = $SelectedPath }
        if (-not $Recurse) {
            $parameters.Depth = 0
        }
    }

    process {
        Get-ChildItem @parameters -Filter "*.psd1" -Exclude "*.Resources.psd1" -Recurse | Where-Object {
            Test-Path -Path $_.FullName -PathType Leaf
        } | Split-Path | Convert-Path | Select-Object -Unique
    }
}
