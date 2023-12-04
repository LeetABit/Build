#requires -version 6

Set-StrictMode -Version 3.0

function Register-BuildTask {
    <#
    .SYNOPSIS
        Registers a specified build task for the specified build extension.
    .DESCRIPTION
        Register-BuildTask cmdlet registers specified information about build task for the specified extension. Name of the extension for which the registration is being performed may be inferred from the script block which is a part of task jobs. If no extension name is provided and cmdlet cannot infer it from job script block an error is emitted.
    .EXAMPLE
        PS> Register-BuildTask "build" ("generate", "compile", "test") -ExtensionName "PowerShell"

        Registers a build task for "build" command that is realized by executing a sequence of the specified tasks. The registration is performed for "PowerShell" extension.
    .EXAMPLE
        PS> Register-BuildTask "generate" ({ param ($RepositoryRoot) begin { New-Resources $RepositoryRoot } })

        Registers a build task for "generate" command that is realized by executing a specified script block. The registration is performed for extension that is named after a module in which the specified script block is defined.
    .EXAMPLE
        PS> Register-BuildTask "test" ("test_scripts", "test_modules") -ExtensionName "PowerShell" -Condition { Text-Command "PSTest" }

        Registers a build task for "test" command that is realized by executing a sequence of "test_scripts" and "test_modules" tasks. The registration is performed for "PowerShell" extension. Execution of the task is conditional on the result of the specified script block execution.
    .EXAMPLE
        PS> Register-BuildTask "test" ("test_scripts", "test_modules") -ExtensionName "PowerShell" -IsDefault

        Registers a build task for "test" command that is realized by executing a sequence of "test_scripts" and "test_modules" tasks. The task is being registered as a default task for the extension - it will be executed when no task nem is specified.
    .EXAMPLE
        PS> Register-BuildTask "test" ("test_scripts", "test_modules") -ExtensionName "PowerShell" -PassThru -Force

        Registers a build task for "test" command that is realized by executing a sequence of "test_scripts" and "test_modules" tasks. The operation returns an information about registered task. The registration is being performed regardless the extension is already registered or not.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([TaskDefinition[]])]

    param (
        # Name of the task for which the registration shall be performed.
        [Parameter(HelpMessage = 'Provide name for the task for which the registration shall be performed.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $TaskName,

        # Defines list of script blocks or names of other tasks that shall be executed in the specified order as a realization of the task being defined.
        [Parameter(HelpMessage = 'Provide a collection of jobs for the task.',
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ValueFromRemainingArguments = $True)]
        [Object[]]
        $Jobs,

        # Name of the extension for which the registration shall be performed.
        [Parameter(HelpMessage = 'Provide name of the extension for which the registration shall be performed.',
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $ExtensionName,

        # Marks the task being registered as a task that will be executed when no task name for the execution will be specified.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $IsDefault,

        # Defines condition that shall be meet to execute the task being defined. This condition may be a script block that will be evaluated during task execution. Parameters for the script block are provided by means of LeetABit.Build.Arguments module. To execute the task the script block need to return a $True value.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Object]
        $Condition = $True,

        # Returns a information about task defined by the cmdlet. By default, this cmdlet does not generate any output.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $PassThru,

        # Indicates that this cmdlet overwrites already registered build task.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $Force
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (-not $ExtensionName) {
            $scriptBlocks = $Jobs | ForEach-Object {
                if ($_ -is [ScriptBlock]) {
                    $_
                }
            }

            $callingModuleName = Get-CallingModuleName $scriptBlocks
            if ($callingModuleName) {
                $ExtensionName = $callingModuleName
            }
        }

        if (-not $script:Extensions.ContainsKey($ExtensionName)) {
            $extension = [ExtensionDefinition]::new($ExtensionName)
            $extension.Resolver = $DefaultResolver
            $script:Extensions.Add($ExtensionName, $extension)
        }
        else {
            $extension = $script:Extensions[$ExtensionName]
        }

        if ($extension.Tasks.ContainsKey($TaskName) -and -not $Force) {
            throw $LocalizedData.Error_RegisterBuildTask_Reason -f
                ($LocalizedData.Exception_TaskAlreadyRegistered_ExtensionName_TaskName -f $ExtensionName, $TaskName)
        }

        $Jobs | Where-Object { $_ -is [String] } | ForEach-Object {
            if (-not $extension.Tasks.ContainsKey($_)) {
                throw $LocalizedData.Error_RegisterBuildTask_Reason -f
                    ($LocalizedData.Exception_ChildTaskNotFound_ExtensionName_TaskName -f $ExtensionName, $TaskName)
            }
        }

        $task = [TaskDefinition]::new($TaskName, $IsDefault, $Condition, $Jobs)
        $extension.Tasks.Add($TaskName, $task)

        if ($PassThru) {
            Write-Output $task.Clone()
        }
    }
}
