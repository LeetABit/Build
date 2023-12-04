#requires -version 6

Set-StrictMode -Version 3.0

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
        $colors = (0, 4, 2, 6, 1, 5, 3, 7)
    }

    process {
        $preambleToWrite = $Preamble
        $colorToWrite = ""
        $resetToWrite = ""

        if ($Color) {
            $colorToWrite = [char]0x001b + '['
            $colorToWrite += if ($Color -ge [System.ConsoleColor]::DarkGray) { if ($env:APPVEYOR) { '1;9' } else { '1;3' } } else { '3' }

            $colorToWrite += [String]($colors[[Int]$Color % 8]) + 'm'
            $resetToWrite = [char]0x001b + '[0m'
        }

        $indentation = "  " * ($script:LastStep.Count)

        foreach ($messagePart in $Message) {
            Write-Information "$preambleToWrite$indentation$colorToWrite$messagePart$resetToWrite"
            $preambleToWrite = ''
        }
    }
}
