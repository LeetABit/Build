#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Select-ParameterName {
    <#
    .SYNOPSIS
        Obtains a parameter name from the specified argument if it matches an parameter name pattern.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # Argument to examine.
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

        if ($Argument -match "^-(($firstParameterChar)($parameterChar)*)\:?$") {
            $matches[1]
        }
    }
}
