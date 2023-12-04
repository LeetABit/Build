#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Management.Automation

Set-StrictMode -Version 3.0

function Import-CallerPreference {
    <#
    .SYNOPSIS
        Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
        Script module functions do not automatically inherit their caller's variables, but they can be
        obtained through the $PSCmdlet variable in Advanced Functions. This function is a helper function
        for any script module Advanced Function; by passing in the values of $PSCmdlet and
        $ExecutionContext.SessionState, Import-CallerPreference will set the caller's preference variables locally.
    .EXAMPLE
        Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Imports the default PowerShell preference variables from the caller into the local scope.
    .LINK
        about_Preference_Variables
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The $PSCmdlet object from a script module Advanced Function.
        [Parameter(HelpMessage = 'Provide an instance of the $PSCmdlet object.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [PSCmdlet]
        $Cmdlet,

        # The $ExecutionContext.SessionState object from a script module Advanced Function.
        # This is how the Import-CallerPreference function sets variables in its callers' scope,
        # even if that caller is in a different script module.
        [Parameter(HelpMessage = 'Provide an instance of the $ExecutionContext.SessionState object.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [SessionState]
        $SessionState
    )

    begin {
        $preferenceVariablesMap = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'InformationPreference' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumHistoryCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null
            'Transcript' = $null

            'ConfirmPreference' = 'Confirm'
            'DebugPreference' = 'Debug'
            'ErrorActionPreference' = 'ErrorAction'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
            'WhatIfPreference' = 'WhatIf'
        }
    }

    process {
        foreach ($variableName in $preferenceVariablesMap.Keys) {
            $parameterName = $preferenceVariablesMap[$variableName]
            if (-not $parameterName `
                -or `
                -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($parameterName)) {
                $variable = $Cmdlet.SessionState.PSVariable.Get($variableName)

                if ($variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }
    }
}
