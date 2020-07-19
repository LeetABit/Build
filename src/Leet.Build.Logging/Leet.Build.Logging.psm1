#requires -version 6
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation

Set-StrictMode -Version 2
Import-LocalizedData -BindingVariable LocalizedData -FileName Leet.Build.Logging.Resources.psd1

$EscapeSequence = [char]0x001b + '['

$LightPrefix = if ($env:APPVEYOR) { '1;9' } else { '1;3' }

$BlackColor   = '0m'
$RedColor     = '1m'
$GreenColor   = '2m'
$MagentaColor = '5m'
$CyanColor    = '6m'
$ResetColor   = '0m'

$LastStepName   = ""
$LastStepFailed = $False


##################################################################################################################
# Public Commands
##################################################################################################################


function Write-Diagnostic {
    <#
    .SYNOPSIS
    Writes a diagnostic message that informs about less relevant script progress.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $color = "$script:LightPrefix$script:BlackColor"
    }

    process {
        Write-Message -Color $color -Message $Message
    }
}


function Write-Failure {
    <#
    .SYNOPSIS
    Writes a message that informs about build failure.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $color = "$script:LightPrefix$script:RedColor"
    }

    process {
        $script:LastStepFailed = $True
        Write-Message -Color $color -Message $Message

        if ($ErrorActionPreference -eq 'Stop') {
            Write-Error $LocalizedData.BreakingError
        }
    }
}


function Write-Invocation {
    <#
    .SYNOPSIS
    Writes to the host information about the specified invocation.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $message = $LocalizedData.Write_Invocation_ExecutingCommandWithParameters_CommandName
        $message = $message -f ($Invocation.MyCommand.ModuleName, $Invocation.MyCommand.Name)
        Write-Verbose $message

        $Invocation.BoundParameters.Keys | ForEach-Object {
            $value = Leet.Build.Common\Format-String $Invocation.BoundParameters[$_]
            Write-Verbose "  -$_ = `'$value`'"
        }
    }
}


function Write-Message {
    <#
    .SYNOPSIS
    Writes a specified message string to the shell host with optional indentation and line wraps.
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
        [String]
        $Color = ''
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $preambleToWrite = $Preamble
        $colorToWrite = if ($Color) { "$EscapeSequence$Color" } else { '' }
        $resetColorToWrite = if ($Color) { "$EscapeSequence$ResetColor" } else { '' }

        foreach ($messagePart in $Message) {
            Write-Information "$preambleToWrite$colorToWrite$messagePart$resetColorToWrite"
            $preambleToWrite = ''
        }
    }
}


function Write-Modification {
    <#
    .SYNOPSIS
    Writes a message that informs about state change in the current system.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $color = "$script:LightPrefix$script:MagentaColor"
    }

    process {
        Write-Message -Color $color -Message $Message
    }
}


function Write-Step {
    <#
    .SYNOPSIS
    Writes a specified build step message string to the host.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Name of the step that shall be writen as a message preamble.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $color = "$script:LightPrefix$script:CyanColor"
    }

    process {
        $preamble = if ($env:TRAVIS -and $StepName) { "travis_fold:start:$StepName`r" }
                    else                            { '' }

        Write-Message -Preamble $preamble -Color $color -Message "$([System.Environment]::NewLine)$Message"

        $script:LastStepName   = $StepName
        $script:LastStepFailed = $False
    }
}


function Write-StepFinished {
    <#
    .SYNOPSIS
    Writes a specified build step success message string to the host.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Name of the step that shall be writen as a message preamble.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [ValidatePattern('^[a-z0-9_]+$')]
        [String]
        $StepName = $script:LastStepName
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $message  = $LocalizedData.Write_StepFinished_Success
        $color    = "$script:LightPrefix$script:GreenColor"
    }

    process {
        if (-not $StepName) {
            throw $LocalizedData.Write_StepFinished_NoStepStarted
        }

        if ($script:LastStepFailed) {
            throw $LocalizedData.Write_StepFinished_BuildStepFailed_StepName -f $StepName
        }

        $preamble = if ($env:TRAVIS -and $StepName) { "travis_fold:end:$StepName`r" } else { '' }

        Write-Message -Preamble $preamble -Color $color -Message $message
        Write-Message
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
