#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgumentInCommandLine {
    <#
    .SYNOPSIS
        Examines command line arguments for presence of a specified named parameter's value.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([Object])]

    param (
        # Name of the parameter.
        [Parameter(HelpMessage = 'Provide parameter name.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [String]
        $ParameterName,

        # Indicates whether the argument shall be threated as a value for [Switch] parameter.
        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Switch]
        $IsSwitch)

    process {
        foreach ($dictionaryParameterName in $script:NamedArguments.Keys) {
            if ($dictionaryParameterName -ne $ParameterName) {
                continue
            }

            $script:NamedArguments[$ParameterName]
            return
        }

        Find-CommandArgumentInUnknownArguments $ParameterName $IsSwitch
    }
}
