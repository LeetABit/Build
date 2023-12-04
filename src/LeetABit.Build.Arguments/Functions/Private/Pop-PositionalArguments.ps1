#requires -version 6

Set-StrictMode -Version 3

function Pop-PositionalArguments {
    <#
    .SYNOPSIS
        Locates a positional argument in a head of the collection of arguments which kind has not yet been determined.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param ()

    process {
        while ($script:UnknownArguments.Count -gt 0) {
            if (-Not (Test-ParameterName $script:UnknownArguments[0])) {
                $script:PositionalArguments += $script:UnknownArguments[0]
                $script:UnknownArguments.RemoveAt(0)
            }
            else {
                break
            }
        }
    }
}
