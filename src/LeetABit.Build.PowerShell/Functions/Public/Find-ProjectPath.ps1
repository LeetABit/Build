#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Find-ProjectPath {
    <#
    .SYNOPSIS
        Finds paths to all script files and PowerShell module directories in the specified path.
    .DESCRIPTION
        The Find-ProjectPath cmdlet searches for a script or module in the specified location and returns a path to each item found.
    .PARAMETER Path
        Path to the search directory.
    .PARAMETER LiteralPath
        Literal path to the search directory.
    .EXAMPLE
        PS > Find-ProjectPath -Path "C:\Modules"

        Returns paths to all scripts and modules located in the specified directory.
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
        $LiteralPath)

    begin {
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $SelectedPath = if ($PSCmdlet.ParameterSetName -eq 'Path') { $Path } else { $LiteralPath }
        $parameters = @{ "$($PSCmdlet.ParameterSetName)" = $SelectedPath }
    }

    process {
        $directories = Find-ModulePath @parameters -Recurse

        $directories | ForEach-Object {
            Write-Verbose -Message "Found PowerShell module directory: '$_'"
            $_
        }

        Find-ScriptPath @parameters | Where-Object {
            -not (Test-PathInContainer -Path $_.FullName -Container $directories)
        } | ForEach-Object {
            Write-Verbose -Message "Found script file: '$_'"
            $_.FullName
        }
    }
}
