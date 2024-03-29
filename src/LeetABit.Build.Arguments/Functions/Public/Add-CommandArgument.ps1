#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using module LeetABit.Build.Common

Set-StrictMode -Version 3

function Add-CommandArgument {
    <#
    .SYNOPSIS
        Adds a value for the specified parameter.
    .DESCRIPTION
        Add-CommandArgument cmdlet stores a specified value for the parameter in internal module state for later usage. This value may be further selected by Find-CommandArgument or Select-CommandArgumentSet cmdlets.
    .PARAMETER ParameterName
        Name of the parameter which value shall be updated.
    .PARAMETER ParameterValue
        A new value for the parameter.
    .PARAMETER Force
        Indicates that this cmdlet overwrites value already set to the parameter.
    .EXAMPLE
        PS> Add-CommandArgument -ParameterName "TaskName" -ParameterValue "help"

        Checks whether an argument for parameter "TaskName" has been already set. If not the cmdlet assigns a "help" value for it.
    .EXAMPLE
        PS> Add-CommandArgument -ParameterName "TaskName" -ParameterValue "help" -Force

        Sets "help" value for parameter "TaskName" regardless it was already set or not.
    .LINK
        Find-CommandArgument
    .LINK
        Select-CommandArgumentSet
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        [Parameter(HelpMessage = 'Provide name of the parameter which value shall be updated',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateIdentifierAttribute()]
        [String]
        $ParameterName,

        [Parameter(HelpMessage = 'Provide a new value for the parameter.',
                   Position=1,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [AllowNull()]
        [Object]
        $ParameterValue,

        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $Force)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($script:NamedArguments.ContainsKey($ParameterName)) {
            if (-not $Force) {
                throw $LocalizedData.Error_SetCommandArgument_Reason -f
                    ($LocalizedData.Reason_ArgumentAlreadySet_ParameterName -f $ParameterName)
            }
        }

        $script:NamedArguments[$ParameterName] = $ParameterValue
    }
}
