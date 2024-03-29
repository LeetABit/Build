#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Invoke-BuildTask {
    <#
    .SYNOPSIS
        Invokes a specified build task on the specified project.
    .DESCRIPTION
        Invoke-BuildTask cmdlet executes a specified extension's task against specified project.
    .PARAMETER ExtensionName
        Name of the extension which defines the task.
    .PARAMETER TaskName
        Name of the tasks to invoke.
    .PARAMETER ProjectPath
        Path to the project on which the task shall invoked.
    .PARAMETER SourceRoot
        Path to the repository's source directory.
    .PARAMETER ArgumentList
        Collection of additional arguments that may be used by the task implementation.
    .EXAMPLE
        PS> Invoke-BuildTask "PowerShell" "test"

        Invokes "test" task from "PowerShell" extension on a repository root directory.
    .EXAMPLE
        PS> Invoke-BuildTask "PowerShell" "test" "~/repository/src/Script.ps1" -ArgumentList @{ "ToolVersion" = "1.0.0" }

        Invokes "test" task from "PowerShell" extension on "~/repository/src/Script.ps1" script file with additional parameter "ToolVersion".
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]
    [OutputType([Object])]

    param (
        [Parameter(HelpMessage = "Provide name of the build extension from which the task shall be executed.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionName,

        [Parameter(HelpMessage = "Provide name of the build tasks to be executed.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [String[]]
        $TaskName,

        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $ProjectPath,

        [Parameter(Position = 3,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $SourceRoot,

        [Parameter(Position = 4,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True,
                   ValueFromRemainingArguments = $True)]
        [String[]]
        $ArgumentList
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (-not $script:Extensions.ContainsKey($ExtensionName)) {
            throw $LocalizedData.Error_InvokeBuildTask_Reason -f
                ($LocalizedData.Exception_ExtensionNotFound_ExtensionName -f $ExtensionName)
        }

        $extension = $script:Extensions[$ExtensionName]

        if (-not $TaskName) {
            $TaskName = @()
            $extension.Tasks.Values | ForEach-Object {
                if ($_.IsDefault) {
                    $TaskName += $_.Name
                }
            }
        }
        else {
            foreach ($task in $TaskName) {
                if (-not $extension.Tasks.ContainsKey($task)) {
                    throw $LocalizedData.Error_InvokeBuildTask_Reason -f
                        ($LocalizedData.Exception_TaskNotFound_ExtensionName_TaskName -f $ExtensionName, $task)
                }
            }
        }

        if (-not $TaskName) {
            throw $LocalizedData.Error_InvokeBuildTask_Reason -f
                ($LocalizedData.Exception_DefaultTaskNotFound_ExtensionName -f $ExtensionName)
        }

        $target = $LocalizedData.BuildTask_ExtensionName_TaskName_ProjectPath -f $ExtensionName, ($TaskName -join ", "), ($ProjectPath -join ", ")
        $action = $LocalizedData.Invoke
        if ($PSCmdlet.ShouldProcess($target, $action)) {
            Invoke-BuildTaskCore -Extension $extension -TaskName $TaskName -ProjectPaths $ProjectPath -SourceRoot $SourceRoot -AdditionalArguments $ArgumentList
        }
    }
}
