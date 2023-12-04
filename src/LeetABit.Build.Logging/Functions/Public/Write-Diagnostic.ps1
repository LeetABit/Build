#requires -version 6

Set-StrictMode -Version 3.0

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
        Write-Message -Message $Message -Color 'DarkGray'
    }
}
