#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Write-BuildHelp {
    <#
    .SYNOPSIS
        Gets help for the build script or one of its targets.
    .PARAMETER ExtensionTopic
        Optional name of the build extension for which help shall be obtained.
    .PARAMETER TaskTopic
        Optional name of the build task for which help shall be obtained.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionTopic,

        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $TaskTopic
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        Get-BuildHelp $ExtensionTopic $TaskTopic | Out-String | Write-Information -InformationAction Continue
    }
}
