#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Get-BuildExtension {
    <#
    .SYNOPSIS
        Gets information about all registered build extensions.
    .DESCRIPTION
        Get-BuildExtension cmdlet retrieves an information about all registered build extensions which names contains specified $Name parameter. To register a build extensions use Register-BuildExtension cmdlet.
    .EXAMPLE
        PS> Get-BuildExtension -Name "PowerShell"

        Retrieves all registered build extensions that have a "PowerShell" term in its registered name.
    .LINK
        Register-BuildExtension
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([ExtensionDefinition[]])]

    [SuppressMessage(
        'PSReviewUnusedParameter',
        'Name',
        Justification = 'False positive as rule does not scan child scopes: https://github.com/PowerShell/PSScriptAnalyzer/issues/1472')]
    param (
        # Name of the extensions or part of it.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Name
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $Extensions.Values | Foreach-Object {
            if (-not $Name -or $Name -contains $_.Name) {
                $_.Clone()
            }
        }
    }
}
