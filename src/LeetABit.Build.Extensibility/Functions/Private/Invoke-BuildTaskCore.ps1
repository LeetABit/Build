#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function Invoke-BuildTaskCore {
    <#
    .SYNOPSIS
        Implements build task invocation.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Extension which defines the task.
        [Parameter(HelpMessage = "Provide build extension from which the task shall be executed.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [ExtensionDefinition]
        $Extension,

        # Name of the tasks to invoke.
        [Parameter(HelpMessage = "Provide name of the build tasks to be executed.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $TaskName,

        # Path to the project on which the task shall invoked.
        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $ProjectPaths,

        # PAth to the repository's source directory.
        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 3,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $SourceRoot,

        # Dictionary with additional arguments that may be used by the task implementation.
        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 4,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [AllowNull()]
        [IDictionary]
        $AdditionalArguments,

        # Collection of the task names that has already been run.
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
                            $stepName = ConvertTo-Identifier "$($Extension.Name)_$($task.Name)"
                            Write-Step -StepName $stepName -Message "$($Extension.Name) -> $($task.Name)"
                            $index = 0
                            foreach ($ProjectPath in $ProjectPaths) {
                                $index = $index + 1
                                $additionalProjectArguments = @{}

                                if ($AdditionalArguments) {
                                    foreach ($key in $AdditionalArguments.Keys) {
                                        $additionalProjectArguments[$key] = $AdditionalArguments[$key]
                                    }
                                }

                                $additionalProjectArguments['ProjectPath'] = $ProjectPath

                                $relativePath = Resolve-RelativePath $ProjectPath $SourceRoot

                                if ($relativePath -ne '.') {
                                    $stepName = $stepName + (ConvertTo-Identifier $relativePath)
                                    Write-Step -StepName $stepName -Message "$relativePath"
                                }

                                Invoke-ScriptBlock -ScriptBlock $job -ParameterPrefix $Extension.Name -AdditionalArguments $additionalProjectArguments

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
