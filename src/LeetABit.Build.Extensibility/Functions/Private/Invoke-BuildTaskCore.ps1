#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function Invoke-BuildTaskCore {
    <#
    .SYNOPSIS
        Implements build task invocation.
    .PARAMETER Extension
        Extension which defines the task.
    .PARAMETER TaskName
        Name of the tasks to invoke.
    .PARAMETER ProjectPaths
        Path to the project on which the task shall invoked.
    .PARAMETER SourceRoot
        Path to the repository's source directory.
    .PARAMETER AdditionalArguments
        Dictionary with additional arguments that may be used by the task implementation.
    .PARAMETER TasksAlreadyRun
        Collection of the task names that has already been run.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        [Parameter(HelpMessage = "Provide build extension from which the task shall be executed.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [ExtensionDefinition]
        $Extension,

        [Parameter(HelpMessage = "Provide name of the build tasks to be executed.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $TaskName,

        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $ProjectPaths,

        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 3,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $SourceRoot,

        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 4,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [AllowNull()]
        [IDictionary]
        $AdditionalArguments,

        [Parameter(Position = 5,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $TasksAlreadyRun = @()
    )

    process {
        foreach ($currentTaskName in $TaskName) {
            if ($TasksAlreadyRun -contains $currentTaskName) {
                continue
            }

            $TasksAlreadyRun += $currentTaskName

            foreach ($task in $Extension.Tasks.Values) {
                if ($task.Name -eq $currentTaskName) {
                    foreach ($job in $task.Jobs) {
                        if ($job -is [String]) {
                            Invoke-BuildTaskCore -Extension $Extension -TaskName $job -ProjectPaths $ProjectPaths -SourceRoot $SourceRoot -AdditionalArguments $AdditionalArguments -TasksAlreadyRun $TasksAlreadyRun
                        }
                        else {
                            $scriptBlock = if ($job -is [ScriptBlock]) {
                                $job
                            } else {
                                $job.ScriptBlock
                            }

                            $stepName = ConvertTo-Identifier "$($Extension.Name)_$($task.Name)"
                            Write-Step -StepName $stepName -Message "$($Extension.Name) -> $($task.Name)"
                            if ($task.Initialization) {
                                Invoke-ScriptBlock -ScriptBlock $task.Initialization -ParameterPrefix $Extension.Name -AdditionalArguments $AdditionalArguments
                            }

                            $index = 0
                            foreach ($ProjectPath in $ProjectPaths) {
                                $index = $index + 1

                                LeetABit.Build.Arguments\Set-ProjectPath $ProjectPath
                                $relativePath = Resolve-RelativePath $ProjectPath $SourceRoot

                                if ($relativePath -ne '.') {
                                    $stepName = $stepName + (ConvertTo-Identifier $relativePath)
                                    Write-Step -StepName $stepName -Message "$relativePath"
                                }

                                Invoke-ScriptBlock -ScriptBlock $scriptBlock -ParameterPrefix $Extension.Name -AdditionalArguments $additionalArguments

                                if ($relativePath -ne '.') {
                                    Write-StepFinished
                                }
                            }

                            Write-StepFinished
                        }
                    }
                }
            }
        }
    }
}
