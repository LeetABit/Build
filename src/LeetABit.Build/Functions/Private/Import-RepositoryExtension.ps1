#requires -version 6

Set-StrictMode -Version 3.0

function Import-RepositoryExtension {
    <#
    .SYNOPSIS
        Executes LeetABit.Build.Repository scripts from the specified repository.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The directory to the repository's root directory path.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $RepositoryRoot)

    process {
        Get-ChildItem -Path $RepositoryRoot -Filter "LeetABit.Build.Repository.ps1" -Recurse | ForEach-Object {
            . "$_"
        }
    }
}
