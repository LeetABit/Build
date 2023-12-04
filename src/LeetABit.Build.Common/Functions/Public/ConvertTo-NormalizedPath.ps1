#requires -version 6

Set-StrictMode -Version 3.0

function ConvertTo-NormalizedPath {
    <#
    .SYNOPSIS
        Converts path to the canonical form that can be used to compare paths.
    .DESCRIPTION
        The ConvertTo-NormalizedPath cmdlet converts specified path to canonical form by removing any provider name from the beginning of the path.
        In the next steps path is converted to absolute path with unified directory separator characters. This cmdlet does not support wildcard characters.
    .EXAMPLE
        PS> ConvertTo-NormalizedPath -LiteralPath '.'

        Returns an absolute path to the current directory.
    .EXAMPLE
        PS> ConvertTo-NormalizedPath -LiteralPath 'C:Windows'

        Returns an absolute path to the Windows subdirectory of the current directory in C drive.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   DefaultParameterSetName = 'Path')]
    [OutputType([String])]

    param (
        # Path to normalize.
        [Parameter(HelpMessage = 'Provide a path to normalize.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'Path')]
        [String[]]
        $Path,

        # Path to normalize.
        [Parameter(HelpMessage = 'Provide a path to normalize.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ParameterSetName = 'LiteralPath')]
        [String[]]
        $LiteralPath
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            [System.IO.Path]::TrimEndingDirectorySeparator((Convert-Path -Path (Convert-Path -Path $Path)))
        }
        else {
            [System.IO.Path]::TrimEndingDirectorySeparator((Convert-Path -LiteralPath (Convert-Path -LiteralPath $LiteralPath)))
        }
    }
}
