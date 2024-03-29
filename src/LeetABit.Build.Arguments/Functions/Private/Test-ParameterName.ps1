#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Test-ParameterName {
    <#
    .SYNOPSIS
        Checks whether the specified argument represents a name of the parameter specifier.
    .PARAMETER Argument
        Argument which shall be checked.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([System.Boolean])]

    param (
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
