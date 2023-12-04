#requires -version 6

Set-StrictMode -Version 3.0

function Write-Step {
    <#
    .SYNOPSIS
        Writes a specified build step message to the information stream with step name folding when run in Travis CI environment.
    .DESCRIPTION
        Write-Step cmdlet writes a message about a new build step that is about to be started. The message is written to the information stream. This cmdlet also emits a log folding preamble when run in Travis CI environment.
    .EXAMPLE
        Write-Step -StepName "prerequisites" -Message "Installing prerequisites."

        Writes an information message about the build step with a folding preamble when run in Travis CI environment.
    .LINK
        Write-StepFinished
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Name of the step that shall be written as a message preamble.
        [Parameter(HelpMessage = 'Enter a name of the step being reported.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [ValidatePattern('^[a-z0-9_]+$')]
        [String]
        $StepName,

        # Step information message to be written by the host.
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
        $preamble = if ($env:TRAVIS -and $StepName) { "travis_fold:start:$StepName`r" }
                    else                            { '' }

        $color = if ($script:LastStep.Count -gt 0) {
            'DarkCyan'
        }
        else {
            'Cyan'
        }

        if ($script:LastStep.Count -eq 0) {
            Write-Message -Message "" -Preamble $preamble
            Write-Message -Message "$Message" -Color $color
        }
        else {
            Write-Message -Message "$Message" -Preamble $preamble -Color $color
        }

        $script:LastStep.Enqueue($StepName)
        $script:LastStepResult.Enqueue($True)
    }
}
