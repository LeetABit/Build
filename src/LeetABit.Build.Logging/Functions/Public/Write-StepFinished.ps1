#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Write-StepFinished {
    <#
    .SYNOPSIS
        Writes a message about the result of the most recent build step.
    .DESCRIPTION
        Write-StepFinished cmdlet writes a message about build step failure when Write-Failure cmdlet was called since last Write-Step. Otherwise a success message is being written to the information stream.
    .EXAMPLE
        Write-StepFinished

        Writes an information about most recent build step result.
    .LINK
        Write-Step
    .LINK
        Write-Failure
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param ()

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $message  = $LocalizedData.Write_StepFinished_Success
    }

    process {
        if ($script:StepsStarted -eq 0) {
            throw $LocalizedData.Write_StepFinished_NoStepStarted
        }

        $script:StepsStarted -= 1;
        $stepResult = $script:LastStepResult.Dequeue()

        if (-not $stepResult) {
            throw $LocalizedData.Write_StepFinished_BuildFailed
        }

        if ($script:StepsStarted -eq 0) {
            Write-Message -Message "$message$([System.Environment]::NewLine)" -Color 'Green'
        }
    }
}
