#requires -version 6

Set-StrictMode -Version 3.0

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
