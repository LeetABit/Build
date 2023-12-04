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
        Writes a message about the result of the most recent build step and closes folding when run in Travis CI environment.
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
        if ($script:LastStep.Count -eq 0) {
            throw $LocalizedData.Write_StepFinished_NoStepStarted
        }

        $stepName = $script:LastStep.Dequeue()
        $stepResult = $script:LastStepResult.Dequeue()

        if (-not $stepResult) {
            throw $LocalizedData.Write_StepFinished_BuildFailed
        }

        $preamble = if ($env:TRAVIS -and $stepName) { "travis_fold:end:$stepName`r" } else { '' }
        if ($script:LastStep.Count -gt 0) {
            if ($preamble) {
                Write-Message -Message "" -Preamble $preamble -Color 'DarkGreen'
            }
        }
        else {
            Write-Message -Message "$message$([System.Environment]::NewLine)" -Preamble $preamble -Color 'Green'
        }
    }
}
