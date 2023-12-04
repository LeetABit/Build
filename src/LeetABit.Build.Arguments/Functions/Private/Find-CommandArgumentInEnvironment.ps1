#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3

function Find-CommandArgumentInEnvironment {
    <#
    .SYNOPSIS
        Examines environmental variables for presence of a specified named parameter's value.
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
        $ParameterName
    )

    process {
        if (Test-Path "env:\$ParameterName") {
            Get-Content "env:\$ParameterName"
        }
    }
}
