#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Write-Step {
    <#
    .SYNOPSIS
        Writes a specified build step message to the information stream.
    .DESCRIPTION
        Write-Step cmdlet writes a message about a new build step that is about to be started. The message is written to the information stream.
    .PARAMETER StepName
        Name of the step that shall be written as a message preamble.
    .PARAMETER Message
        Step information message to be written by the host.
    .EXAMPLE
        Write-Step -StepName "prerequisites" -Message "Installing prerequisites."

        Writes an information message about the build step.
    .LINK
        Write-StepFinished
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        [Parameter(HelpMessage = 'Enter a name of the step being reported.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [ValidatePattern('^[a-z0-9_]+$')]
        [String]
        $StepName,

        [Parameter(HelpMessage = 'Enter a step message.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $Message
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $color = if ($script:StepsStarted -gt 0) {
            'DarkCyan'
        }
        else {
            'Cyan'
        }

        if ($script:StepsStarted -eq 0) {
            Write-Message -Message ""
            Write-Message -Message "$Message" -Color $color
        }
        else {
            Write-Message -Message "$Message" -Color $color
        }

        $script:StepsStarted += 1
        $script:LastStepResult.Enqueue($True)
    }
}
