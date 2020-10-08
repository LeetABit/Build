#requires -version 6
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation

Set-StrictMode -Version 3.0
Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Logging.Resources.psd1

$LastStepName   = ""
$LastStepFailed = $False


##################################################################################################################
# Public Commands
##################################################################################################################


function Write-Diagnostic {
    <#
    .SYNOPSIS
        Writes a diagnostic message that informs about less relevant script progress.
    .DESCRIPTION
        Write-Diagnostic cmdlet writes a less relevant diagnostic build message to the information stream.
    .EXAMPLE
        Write-Diagnostic "Checking optional features finished."

        Writes a diagnostic message to the information stream.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Diagnostic message to be written by the host.
        [Parameter(HelpMessage = 'Enter a diagnostic message.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Message)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        Write-Message -Message $Message -Color 'DarkGrey'
    }
}


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
        [String[]]
        $Message)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $script:LastStepFailed = $True
        Write-Message -Message $Message -Color 'Red'

        if ($ErrorActionPreference -eq 'Stop') {
            Write-Error $LocalizedData.BreakingError
        }
    }
}


function Write-Invocation {
    <#
    .SYNOPSIS
        Writes a verbose message about the specified invocation.
    .DESCRIPTION
        Write-Invocation cmdlet writes a message to a verbose stream that contains information about executing function invocation.
    .EXAMPLE
        Write-Invocation $MyInvocation

        Writes a verbose information about current function invocation.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Invocation which information shall be written.
        [Parameter(HelpMessage = "Provide invocation information about the command to write to verbose log.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNull()]
        [InvocationInfo]
        $Invocation
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $message = $LocalizedData.Write_Invocation_ExecutingCommandWithParameters_CommandName
        $message = $message -f ($Invocation.MyCommand.ModuleName, $Invocation.MyCommand.Name)
        Write-Verbose $message

        $Invocation.BoundParameters.Keys | ForEach-Object {
            $value = LeetABit.Build.Common\ConvertTo-ExpressionString $Invocation.BoundParameters[$_]
            Write-Verbose "  -$_ = `'$value`'"
        }
    }
}


function Write-Message {
    <#
    .SYNOPSIS
        Writes a specified message string to the information stream with optional preamble and ANSI color escape sequence.
    .DESCRIPTION
        Write-Message cmdlet writes a message to the information stream. An optional preamble is also written on the first line before the actual message. Caller may also specify a color of the message using one of the [System.ConsoleColor] members.
    .EXAMPLE
        Write-Message -Message "Working on updates..." -Preamble "{step:updates}" -Color "Red"

        Writes an information in red color perpended with a preamble.
    .EXAMPLE
        Write-Message -Message "Working on updates..."

        Writes an information in default foreground color with no preamble.
    .NOTES
        Preamble may be used to decorate a message with a text consumed by the presentation layer. This feature is used by Travis CI for log folding.
    #>

    param (
        # Message to be written by the host.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Message = @(),

        # Additional control text to be used for the message.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $Preamble = '',

        # Color for the message.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [System.ConsoleColor]
        $Color
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $preambleToWrite = $Preamble
        $colorToWrite = ""
        $resetToWrite = ""

        if ($Color) {
            $colorToWrite = [char]0x001b + '['
            $colorToWrite += if ($Color -ge [System.ConsoleColor]::DarkGray) { if ($env:APPVEYOR) { '1;9' } else { '1;3' } } else { '3' }
            $colorToWrite += ($Color % 8) + 'm'
            $resetToWrite = [char]0x001b + '[0m'
        }

        foreach ($messagePart in $Message) {
            Write-Information "$preambleToWrite$colorToWrite$messagePart$resetToWrite"
            $preambleToWrite = ''
        }
    }
}


function Write-Modification {
    <#
    .SYNOPSIS
        Writes a message that informs about state change in the current system.
    .DESCRIPTION
        Write-Modification cmdlet writes a message that informs the user about a change that is going to be made to the current system. The message is written to the information stream. This cmdlet shall be used to inform the user about any change that is made to the system in order to give an opportunity to manually revert the changes in case of failure.
    .EXAMPLE
        Write-Modification "Downloading 'archive.zip' file to the repository directory."

        Writes an information message about the file download with the information where it is going to be stored.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Modification message to be written by the host.
        [Parameter(HelpMessage = 'Enter a diagnostic message.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Message
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        Write-Message -Message $Message -Color 'Magenta'
    }
}


function Write-Step {
    <#
    .SYNOPSIS
        Writes a specified build step message to the information stream with step name folding when run in Travis CI environment.
    .DESCRIPTION
        Write-Step cmdlet writes a message about a new build step that is about to be started. The message is written to the information stream. This cmdlet also emits a log folding preamble when run in Travis CI environment.
    .EXAMPLE
        Write-Step -StepName "prerequisites" -Message "Installing prerequisites."

        Writes an information message about the build step with a folding preamble when run in Travis CI environment.
    .NOTES
        This cmdlet does not support nested steps. To start a new build step the Write-StepFinished cmdlet shall be called. Otherwise folding and error handling for the outer step will not work correctly.
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

        Write-Message -Message "$([System.Environment]::NewLine)$Message" -Preamble $preamble -Color 'Cyan'

        $script:LastStepName   = $StepName
        $script:LastStepFailed = $False
    }
}


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
        $message  = "  " + $LocalizedData.Write_StepFinished_Success
    }

    process {
        if (-not $script:LastStepName) {
            throw $LocalizedData.Write_StepFinished_NoStepStarted
        }

        if ($script:LastStepFailed) {
            throw $LocalizedData.Write_StepFinished_BuildStepFailed_StepName -f $script:LastStepName
        }

        $preamble = if ($env:TRAVIS -and $script:LastStepName) { "travis_fold:end:$script:LastStepName`r" } else { '' }

        Write-Message -Message $message -Preamble $preamble -Color 'Green'
        Write-Message
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
