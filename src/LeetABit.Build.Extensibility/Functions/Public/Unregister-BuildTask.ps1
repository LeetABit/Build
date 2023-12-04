#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Unregister-BuildTask {
    <#
    .SYNOPSIS
        Unregisters specified build task.
    .DESCRIPTION
        Unregister-BuildTask cmdlet tries to unregister specified tasks from the specified extension. If the specified extension or task is not registered this cmdlet behaves according to -IgnoreMissing switch.
    .EXAMPLE
        PS> Unregister-BuildTask "PowerShell"

        Tries to unregister all tasks from "PowerShell" extension and emits an error if the extension is not registered yet.
    .EXAMPLE
        PS> Unregister-BuildTask "PowerShell" -TaskName "help" -IgnoreMissing

        Tries to unregister "help" task from "PowerShell" extension and continues execution if the extension nor task is not registered yet.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]

    param (
        # Name of the extension for which the build task shall be unregistered.
        [Parameter(HelpMessage = 'Provide name of the extension which task shall be unregistered.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionName,

        # Name of the tasks that shall be unregistered.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $TaskName,

        # Indicates that this cmdlet ignores tasks that are not defined for the specified build extension.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $IgnoreMissing
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (!$script:Extensions.ContainsKey($ExtensionName) -and -not $IgnoreMissing) {
            throw $LocalizedData.Error_UnregisterBuildTask_Reason -f
                ($LocalizedData.Exception_ExtensionNotFound_ExtensionName -f $ExtensionName)
        }

        $extension = $script:Extensions[$ExtensionName]
        if ($TaskName) {
            $TaskName | ForEach-Object {
                if ($extension.Tasks.ContainsKey($_)) {
                    $target = $LocalizedData.BuildTask_ExtensionName_TaskName -f $ExtensionName, $_
                    $action = $LocalizedData.Unregister
                    if ($PSCmdlet.ShouldProcess($target, $action)) {
                        $extension.Tasks.Remove($_)
                    }
                }
                elseif (-not $IgnoreMissing) {
                    throw $LocalizedData.Error_UnregisterBuildTask_Reason -f
                        ($LocalizedData.Exception_TaskNotFound_ExtensionName_TaskName -f $ExtensionName, $_)
                }
            }
        } else {
            $target = $LocalizedData.AllTasks_ExtensionName -f $ExtensionName
            $action = $LocalizedData.Unregister
            if ($PSCmdlet.ShouldProcess($target, $action)) {
                $extension.Tasks.Clear()
            }
        }
    }
}
