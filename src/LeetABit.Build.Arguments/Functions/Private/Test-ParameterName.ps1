#requires -version 6

Set-StrictMode -Version 3

function Test-ParameterName {
    <#
    .SYNOPSIS
        Checks whether the specified argument represents a name of the parameter specifier.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([System.Boolean])]

    param (
        # Argument which shall be checked.
        [Parameter(HelpMessage = "Provide value of the command's argument.",
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $Argument)

    process {
        $firstParameterChar = '\p{Lu}|\p{Ll}|\p{Lt}|\p{Lm}|\p{Lo}|_|\?'
        $parameterChar = '[^\{\}\(\)\;\,\|\&\.\[\:\s\n]'

        $Argument -match "^-(($firstParameterChar)($parameterChar)*)\:?$"
    }
}
