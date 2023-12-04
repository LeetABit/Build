#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgumentInDictionary {
    <#
    .SYNOPSIS
        Examines specified arguments dictionary for presence of a specified named parameter's value.
    .PARAMETER ParameterName
        Name of the parameter.
    .PARAMETER Dictionary
        A dictionary that holds an arguments to be used as a parameter's value source.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object])]

    param (
        [Parameter(HelpMessage = 'Provide parameter name.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ParameterName,

        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$False)]
        [IDictionary]
        $Dictionary)

    process {
        if ($Dictionary) {
            foreach ($dictionaryParameterName in $Dictionary.Keys) {
                if ($dictionaryParameterName -ne $ParameterName) {
                    continue
                }

                $Dictionary[$dictionaryParameterName]
                break
            }
        }
    }
}
