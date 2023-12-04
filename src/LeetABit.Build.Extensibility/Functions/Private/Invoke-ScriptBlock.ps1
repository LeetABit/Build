#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function Invoke-ScriptBlock {
    <#
    .SYNOPSIS
        Invokes a specified script block using dynamic parameter matching.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Script block that shall be invoked.
        [Parameter(HelpMessage = "Provide a script block that shall be invoked.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ScriptBlock]
        $ScriptBlock,

        # Prefix that may be used in parameters matching.
        [Parameter(HelpMessage = "Provide a string that may be used in parameters matching.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $ParameterPrefix,

        # Dictionary with additional arguments that may be used by the task implementation.
        [Parameter(HelpMessage = "Provide a dictionary with additional arguments that may be used by the task implementation.",
                   Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [AllowNull()]
        [IDictionary]
        $AdditionalArguments
    )

    process {
        $namedParameters, $positionalParameters = LeetABit.Build.Arguments\Select-CommandArgumentSet $ScriptBlock $ParameterPrefix $AdditionalArguments
        . $ScriptBlock @namedParameters @positionalParameters
    }
}
