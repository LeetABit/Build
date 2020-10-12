#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic

Set-StrictMode -Version 3.0
Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Extensibility.Resources.psd1

$Extensions = @{}
$DefaultResolver = {
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]
    <#
    .SYNOPSIS
        Provides a default mechanism of project resolution for build extension.
    #>
    param (
        # Path to the source directory.
        [String]
        $SourceRoot
    )

    $SourceRoot
}


##################################################################################################################
# Public Commands
##################################################################################################################


function Get-BuildExtension {
    <#
    .SYNOPSIS
        Gets information about all registered build extensions.
    .DESCRIPTION
        Get-BuildExtension cmdlet retrieves an information about all registered build extensions which names contains specified $Name parameter. To register a build extensions use Register-BuildExtension cmdlet.
    .EXAMPLE
        PS> Get-BuildExtension -Name "PowerShell"

        Retrieves all registered build extensions that have a "PowerShell" term in its registered name.
    .NOTES
        Register-BuildExtension
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([ExtensionDefinition[]])]

    param (
        # Name of the extensions or part of it.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Name
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $Extensions.Values | Foreach-Object {
            if (-not $Name -or $Name -contains $_.Name) {
                $_.Clone()
            }
        }
    }
}


function Invoke-BuildTask {
    <#
    .SYNOPSIS
        Invokes a specified build task on the specified project.
    .DESCRIPTION
        Invoke-BuildTask cmdlet executes a specified extension's task against specified project.
    .EXAMPLE
        PS> Invoke-BuildTask "PowerShell" "test"

        Invokes "test" task from "PowerShell" extension on a configured SourceRoot directory.
    .EXAMPLE
        PS> Invoke-BuildTask "PowerShell" "test" "~/repository/src/Script.ps1" -ArgumentList @{ "ToolVersion" = "1.0.0" }

        Invokes "test" task from "PowerShell" extension on "~/repository/src/Script.ps1" script file with additional parameter "ToolVersion".
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]
    [OutputType([Object])]

    param (
        # Name of the extension which defines the task.
        [Parameter(HelpMessage = "Provide name of the build extension from which the task shall be executed.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionName,

        # Name of the tasks to invoke.
        [Parameter(HelpMessage = "Provide name of the build tasks to be executed.",
                   Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [String[]]
        $TaskName,

        # Path to the project on which the task shall invoked.
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ProjectPath = (LeetABit.Build.Arguments\Find-CommandArgument 'SourceRoot'),

        # Collection with additional arguments that may be used by the task implementation.
        [Parameter(Position = 3,
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

        $target = $LocalizedData.BuildTask_ExtensionName_TaskName_ProjectPath -f $ExtensionName, ($TaskName -join ", "), $ProjectPath
        $action = $LocalizedData.Invoke
        if ($PSCmdlet.ShouldProcess($target, $action)) {
            Invoke-BuildTaskCore $extension $TaskName $ProjectPath $ArgumentList
        }
    }
}


function Register-BuildExtension {
    <#
    .SYNOPSIS
        Registers build extension in the module.
    .DESCRIPTION
        Register-BuildExtension cmdlet stores specified information about LeetABit.Build extension.
        Extension may define a project resolver script block. It is used to search for all project
        files within the repository that are supported by the extension. Resolver script block may
        define parameters. Values for the parameters will be provided by the means of `LeetABit.Build.Arguments` module.
        The job of the resolver is to return a path to the project file or directory.
        If no resolver is specified a default resolver will be used that returns path to the repository root.
    .EXAMPLE
        PS> Register-BuildExtension -ExtensionName "PowerShell"

        Register a default resolver for a "PowerShell" extension if it is not already registered.
    .EXAMPLE
        PS> Register-BuildExtension { "./Project.sln" } -Force

        Tries to evaluate name of the module that called Register-BuildExtension cmdlet and in case of success register a specified resolver for the extension with the name of the evaluated module regardless the extension is already registered or not.
    .NOTES
        When an extension has already registered a resolver of task and a -Force switch is used any registered resolver and all registered tasks are removed during execution of this cmdlet.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # ScriptBlock that resolves path to the projects recognized by the specified extension.
        [Parameter(HelpMessage = 'Provide a resolver ScriptBlock.',
                   Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "Resolver")]
        [ScriptBlock]
        $Resolver = $DefaultResolver,

        # Name of the extension for which the registration shall be performed.
        [Parameter(HelpMessage = 'Provide a name for the registered extension.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "Default")]
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "Resolver")]
        [String]
        $ExtensionName,

        # Indicates that this cmdlet overwrites already registered extension removing all registered tasks and resolver.
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
            $callingModuleName = Get-CallingModuleName $Resolver
            if ($callingModuleName) {
                $ExtensionName = $callingModuleName
            } else {
                throw $LocalizedData.Error_RegisterBuildExtension_Reason -f
                    ($LocalizedData.Exception_CouldNotDetectExtensionName)
            }
        }

        if ($script:Extensions.ContainsKey($ExtensionName)) {
            if ($Force) {
                $script:Extensions.Remove($ExtensionName)
            }
            else {
                throw $LocalizedData.Error_RegisterBuildExtension_Reason -f
                    ($LocalizedData.Exception_ProjectResolverAlreadyRegistered_ExtensionName -f $ExtensionName)
            }
        }

        $extension = [ExtensionDefinition]::new($ExtensionName)
        $extension.Resolver = $Resolver
        $script:Extensions.Add($ExtensionName, $extension)
    }
}


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
    [OutputType([TaskDefinition])]

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


function Resolve-Project {
    <#
    .SYNOPSIS
        Resolves paths to the projects found in the specified location.
    .DESCRIPTION
        Resolve-Project cmdlet tries to resolve projects inside specified directory using particular specified extension or all registered extensions.
    .EXAMPLE
        PS> Resolve-Project

        Tries to resolve all projects in the source directory inside repository root for all registered extensions.
    .EXAMPLE
        PS> Resolve-Project

        Tries to resolve all projects in the source directory inside repository root for all registered extensions.
    .EXAMPLE
        PS> Resolve-Project -ExtensionName "PowerShell"

        Tries to resolve all projects in the source directory inside repository root for "PowerShell" extension.
    .EXAMPLE
        PS> Resolve-Project -ExtensionName "PowerShell" -TaskName "test"

        Tries to resolve all projects in the source directory inside repository root for "PowerShell" extension only if it supports "test" task.
    .EXAMPLE
        PS> Resolve-Project -TaskName "test"

        Tries to resolve all projects in the source directory inside repository root for all extensions that support "test" task.
    .EXAMPLE
        PS> Resolve-Project -Path "~/repository/source"

        Tries to resolve all projects in the "~/repository/source" directory for all extensions.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String[]])]

    param (
        # Path to location from which the project shall be resolved.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $Path = (LeetABit.Build.Arguments\Find-CommandArgument 'SourceRoot'),

        # Name of the extension for which the project shall be resolved.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $ExtensionName,

        # Name of the task that the extension shall provide. Extensions that do not support this task are not evaluated during the execution.
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $TaskName
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        [Queue] $queue = [Queue]::new()
        $queue.Enqueue(@($Path, $ExtensionName))

        while ($queue.Count -gt 0) {
            $Path, $ExtensionName = $queue.Dequeue()
            $resolverFound = $false

            foreach ($extension in $script:Extensions.Values) {
                if (($ExtensionName -and $extension.Name -ne $ExtensionName) -or
                    (-not $ExtensionName -and $extension.Name -eq 'LeetABit.Build.Repository') -or
                    -not $extension.Resolver) {
                    continue
                }

                if ($TaskName) {
                    if (-not $extension.Tasks.ContainsKey($TaskName)) {
                        continue
                    }
                }
                else {
                    if (-not ($extension.Tasks.Values | Where-Object { $_.IsDefault })) {
                        continue
                    }
                }

                $resolverFound = $true
                $parameters = @{
                    ScriptBlock = $extension.Resolver
                    ParameterPrefix = $extension.Name
                    AdditionalArguments = @{'ProjectPath' = $Path}
                }

                Invoke-ScriptBlock @parameters | ForEach-Object {
                    $resolved = $_
                    $resolvedExtensionName = ''
                    if ($extension.Name -ne 'LeetABit.Build.Repository') {
                        $resolvedExtensionName = $extension.Name
                    }

                    if ($resolved -is [String]) {
                        $resolvedPath = $resolved
                    }
                    elseif ($resolved -is [String[]]) {
                        switch ($resolved.Length) {
                            1 {
                                $resolvedPath = $resolved[0]
                            }

                            2 {
                                $resolvedPath = $resolved[0]
                                $resolvedExtensionName = $resolved[1]
                            }

                            Default {
                                if ($extension.Name -eq 'LeetABit.Build.Repository') {
                                    throw $LocalizedData.Error_ResolveProject_Reason -f
                                        ($LocalizedData.Reason_RepositoryProjectResolverInvalidArray_ArrayLength -f $result.Length)
                                }
                                else {
                                    throw $LocalizedData.Error_ResolveProject_Reason -f
                                        ($LocalizedData.Reason_ExtensionProjectResolverInvalidArray_ExtensionName_ArrayLength -f $extension.Name, $result.Length)
                                }
                            }
                        }
                    }
                    else {
                        if ($extension.Name -eq 'LeetABit.Build.Repository') {
                            throw $LocalizedData.Error_ResolveProject_Reason -f
                                ($LocalizedData.Reason_RepositoryProjectResolverInvalidType_TypeName -f $resolved.GetType())
                        }
                        else {
                            throw $LocalizedData.Error_ResolveProject_Reason -f
                                ($LocalizedData.Reason_ExtensionProjectResolverInvalidType_ExtensionName_TypeName -f $extension.Name, $resolved.GetType())
                        }
                    }

                    if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
                        $resolvedPath = [System.IO.Path]::Combine($Path, $resolvedPath)
                    }

                    if ($extension.Name -eq $resolvedExtensionName) {
                        Write-Output -NoEnumerate @($resolvedPath, $resolvedExtensionName)
                    }
                    else {
                        $queue.Enqueue(@($resolvedPath,$resolvedExtensionName))
                    }
                }
            }

            if (-not $resolverFound) {
                if ($ExtensionName -eq 'LeetABit.Build.Repository') {
                    $ExtensionName = $Null
                    $queue.Enqueue(@($Path,$ExtensionName))
                }
                elseif ($ExtensionName) {
                    Write-Output -NoEnumerate @($Path,$ExtensionName)
                }
                else {
                    if ($TaskName) {
                        throw $LocalizedData.Error_ResolveProject_Reason -f
                            ($LocalizedData.Reason_NoExtensionForTask_TaskName -f $TaskName)
                    }
                    else {
                        throw $LocalizedData.Error_ResolveProject_Reason -f
                            ($LocalizedData.Reason_NoExtensionForDefaultTask)
                    }
                }
            }
        }
    }
}


function Unregister-BuildExtension {
    <#
    .SYNOPSIS
        Unregisters specified build extension.
    .DESCRIPTION
        Unregister-BuildExtension removes all registered information for a specified extension name. If the specified extension is not registered this cmdlet behaves according to -IgnoreMissing switch.
    .EXAMPLE
        PS> Unregister-BuildExtension "PowerShell"

        Tries to unregister a "PowerShell" extension and emits an error if the extension is not registered yet.
    .EXAMPLE
        PS> Unregister-BuildExtension ("PowerShell", "Dotnet") -IgnoreMissing

        Tries to unregister a "PowerShell" and "Dotnet" extensions. The command continues execution without error if an extension to be removed is not registered.
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]

    param (
        # Name of the extension that shall be unregistered.
        [Parameter(HelpMessage = 'Provide name of the extension that shall be unregistered.',
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $ExtensionName,

        # Indicates that this cmdlet ignores build extensions that are not registered.
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
        $ExtensionName | ForEach-Object {
            if (!$script:Extensions.ContainsKey($_) -and -not $IgnoreMissing) {
                throw $LocalizedData.Error_UnregisterBuildExtension_Reason -f
                    ($LocalizedData.Exception_ExtensionNotFound_ExtensionName -f $_)
            }
        }

        $ExtensionName | ForEach-Object {
            $target = $LocalizedData.BuildExtension_ExtensionName -f $ExtensionName
            $action = $LocalizedData.Unregister
            if ($PSCmdlet.ShouldProcess($target, $action)) {
                $script:Extensions.Remove($_)
            }
        }
    }
}


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


###################################################################################################################
## Private Commands
###################################################################################################################


function Get-CallingModuleName {
    <#
    .SYNOPSIS
        Gets the name of the module in which the specified script blocks are defined or the nearest module on the call stack.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Name of the extension for which the project resolver shall be unregistered.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [ScriptBlock[]]
        $Scripts
    )

    process {
        $uniqueModules = @($Scripts | ForEach-Object {
            if ($_ -and $_ -is [scriptblock] -and $_.Module -and ($_.Module.Name -ne 'LeetABit.Build.Extensibility')) {
                $_.Module.Name
            }
        } | Sort-Object | Get-Unique)

        if ($uniqueModules -and ($uniqueModules | Measure-Object).Count -eq 1) {
            $result = $uniqueModules[0]
        }
        else {
            [ScriptBlock]$scriptBlock = Get-PSCallStack | Select-Object -Skip 1 | Foreach-Object {
                $_.InvocationInfo.MyCommand.ScriptBlock
            } | Where-Object {
                $_ -and $_.Module -and $_.Module.Name -ne 'LeetABit.Build.Extensibility'
            } | Select-Object -First 1

            if ($scriptBlock) {
                $result = $scriptBlock.Module.Name
            }
        }

        if ($result -eq "LeetABit.Build") {
            $result = 'LeetABit.Build.Repository'
        }

        if ($result) {
            $result
        }
    }
}


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
        [String]
        $ProjectPath,

        # Dictionary with additional arguments that may be used by the task implementation.
        [Parameter(HelpMessage = "Provide path to the project on which the task shall invoked.",
                   Position = 3,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [AllowNull()]
        [IDictionary]
        $AdditionalArguments,

        # Collection of the task names that has already been run.
        [Parameter(Position = 4,
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
                            Invoke-BuildTaskCore $Extension $job $ProjectPath $AdditionalArguments $TasksAlreadyRun
                        }
                        else {
                            Invoke-ScriptBlock $job $Extension.Name $AdditionalArguments
                        }
                    }
                }
            }
        }
    }
}


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


##################################################################################################################
# Classes
##################################################################################################################


<#
##  Provides detailed information about the registered extension.
#>
class ExtensionDefinition {
    <#
    ##  Name of the registered extension.
    #>
    [String] $Name

    <#
    ##  Represents a project path resolver for the current extension.
    #>
    [ScriptBlock] $Resolver

    <#
    ##  Dictionary of the detailed information object about current extension tasks mapped to the task name.
    #>
    [Dictionary[String,TaskDefinition]] $Tasks

    <#
    ##  Initializes a new instance of the ExtensionDefinition class.
    #>
    ExtensionDefinition([String] $name)
    {
        $this.Name = $name
        $this.Resolver = $null
        $this.Tasks = [Dictionary[String,TaskDefinition]]::new([StringComparer]::OrdinalIgnoreCase)
    }

    <#
    ##  Creates a new instance of the ExtensionDefinition class with all the data copied from this instance.
     #>
    [ExtensionDefinition] Clone() {
        $result = [ExtensionDefinition]::new($this.Name)
        $result.Resolver = $this.Resolver
        $result.Tasks = [Dictionary[String,TaskDefinition]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Tasks.Values | ForEach-Object {
            $result.Tasks.Add($_.Name, $_.Clone())
        }

        return $result
    }
}


<#
##  Provides information about defined task.
#>
class TaskDefinition
{
    <#
    ##  Name of the task.
    #>
    [String] $Name

    <#
    ##  Describes whether the task represented by the current object is the default task or not.
    #>
    [Boolean] $IsDefault

    <#
    ##  Condition for current task execution.
    #>
    [Object] $Condition

    <#
    ##  Array of a task's jobs.
    #>
    [Object[]] $Jobs

    <#
    ##  Initializes a new instance of the TaskDefinition class.
    #>
    TaskDefinition([String] $name, [Boolean] $isDefault, [Object] $condition, [Object[]] $jobs) {
        $this.Name = $name
        $this.IsDefault = $isDefault
        $this.Condition = $condition
        $this.Jobs = $jobs
    }


    <#
    ##  Creates a new instance of the TaskDefinition class with all the data copied from this instance.
     #>
    [TaskDefinition] Clone() {
        return [TaskDefinition]::new($this.Name,
            $this.IsDefault,
            $this.Condition,
            $this.Jobs.Clone())
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
