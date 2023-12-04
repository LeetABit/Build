#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Write-Failure {
    <#
    .SYNOPSIS
        Writes a message that informs about build failure.
    .DESCRIPTION
        Write-Failure cmdlet writes a failure message to the information stream. It also emits a message in error stream if $ErrorActionPreference is set to 'Stop'.
    .EXAMPLE
        Write-Failure -Message "Could not execute build step." -ErrorAction 'Stop'

        Writes a build step failure message to the information stream and emits a message in the error stream.
    .NOTES
        This cmdlet marks most recent build step started as failed.
    .LINK
        Write-Step
    .LINK
        Write-StepFinished
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Build failure message.
        [Parameter(HelpMessage = 'Enter message that describes the failure.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $Message)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        [Void]$script:LastStepResult.Dequeue()
        $script:LastStepResult.Enqueue($False)

        Write-Message -Message $Message -Color 'Red'
    }
}
