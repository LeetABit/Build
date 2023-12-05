#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using module LeetABit.Build.Common

Set-StrictMode -Version 3

function Set-CommandArgumentSet {
    <#
    .SYNOPSIS
        Sets a collection of arguments that shall be used for command execution.
    .DESCRIPTION
        Set-CommandArgumentSet cmdlet clears all arguments previously set and stores a new values for the parameters in internal module state for later usage. These values may be further selected by Find-CommandArgument or Select-CommandArgumentSet cmdlets.
    .PARAMETER RepositoryRoot
        Location of the repository on which te command will be executed.
    .PARAMETER NamedArguments
        Dictionary of buildstrapper parameters (including dynamic ones) that have been successfully bound.
    .PARAMETER UnknownArguments
        Collection of other arguments passed.
    .EXAMPLE
        PS> Set-CommandArgumentSet -RepositoryRoot "." -NamedArguments @{ "TaskName" = "help" } -UnknownArguments $args

        Clears all arguments previously set in the module and initializes internal module data with values from the specified parameters.
    .NOTES
        This cmdlet searches for repository configuration file called 'LeetABit.Build.json' inside repository root directory. Values from this file are used as one of the arguments source.
        This file shall contain one JSON object with properties which names match parameter name and which values shall be used as arguments for these parameters.
        A schema for this file is located at https://raw.githubusercontent.com/LeetABit/Build/master/schema/LeetABit.Build.schema.json
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]

    param (
        [Parameter(HelpMessage = 'Provide path to the root folder of the repository for which the command will be executed.',
                   Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [ValidateContainerPathAttribute()]
        [String]
        $RepositoryRoot,

        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [IDictionary]
        $NamedArguments,

        [Parameter(Position=2,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [String[]]
        $UnknownArguments)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if ($PSCmdlet.ShouldProcess($LocalizedData.Resource_CurrentCommandArgumentSet,
                                    $LocalizedData.Operation_Overwrite)) {
            $script:ConfigurationJson = Read-ConfigurationFromFile $RepositoryRoot
            $script:NamedArguments = @{}
            $script:PositionalArguments = @()
            $script:UnknownArguments.Clear()

            $NamedArguments.Keys | ForEach-Object {
                $script:NamedArguments.Add($_, $NamedArguments[$_])
            }

            if ($UnknownArguments) {
                $script:UnknownArguments.AddRange($UnknownArguments)
                Pop-PositionalArguments
            }
        }
    }
}
