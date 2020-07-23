#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic

Set-StrictMode -Version 2
Import-LocalizedData -BindingVariable LocalizedData -FileName Leet.Build.Extensibility.Resources.psd1

Set-Variable LeetBuildRepository -Option ReadOnly -Value "Leet.Build.Repository"

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
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([ExtensionDefinition])]

    param (
        # Name of the extensions to get.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $Name
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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
        Invokes a specified build task on the specfied project.
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
        $ProjectPath = (Leet.Build.Arguments\Find-CommandArgument 'SourceRoot'),

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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (-not $script:Extensions.ContainsKey($ExtensionName)) {
            throw $LocalizedData.Error_InvokeBuildTask_Reason -f
                ($LocalizedData.Exception_ExtensioNotFound_ExtensionName -f $ExtensionName)
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
        Registers build extension in the Leet.Build system.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # ScriptBlock that resolves path to the projects recognized by the specified extension.
        [Parameter(HelpMessage = 'Provide a resolver ScriptBlock.',
                   Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [ScriptBlock]
        $Resolver = $DefaultResolver,

        # Name of the extension for which the registration shall be performed.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $ExtensionName,

        # Indicates that this cmdlet overwrites already registered extension removing all registered tasks.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $Force
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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

        # Collection of the task names that shall be executed before execution of the task being registered.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $Before,

        # Collection of the task names that shall be executed after execution of the task being registered.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
        $After,

        # Decorates the task being registered as a task that will be executed when no task name will be specified.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $IsDefault,

        # Defines condition that shall be meet to execute the task being defined.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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

        $task = [TaskDefinition]::new($TaskName, $Before, $After, $IsDefault, $Condition, $Jobs)
        $extension.Tasks.Add($TaskName, $task)

        if ($PassThru) {
            Write-Output $task.Clone()
        }
    }
}


function Resolve-Project {
    <#
    .SYNOPSIS
        Resolves paths to the projects found in the speicified location.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String],[String[]])]

    param (
        # Path to location from which the project shall be resolved.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $Path = (Leet.Build.Arguments\Find-CommandArgument 'SourceRoot'),

        # Name of the extension for which the project shall be resolved.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $ExtensionName,

        # Name of the task that the extension shall provide.
        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $TaskName
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        [Queue] $queue = [Queue]::new()
        $queue.Enqueue(@($Path, $ExtensionName))

        while ($queue.Count -gt 0) {
            $Path, $ExtensionName = $queue.Dequeue()
            $resolverFound = $false

            foreach ($extension in $script:Extensions.Values) {
                if (($ExtensionName -and $extension.Name -ne $ExtensionName) -or
                    (-not $ExtensionName -and $extension.Name -eq $LeetBuildRepository) -or
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
                    if ($extension.Name -ne $LeetBuildRepository) {
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
                                if ($extension.Name -eq $LeetBuildRepository) {
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
                        if ($extension.Name -eq $LeetBuildRepository) {
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
                if ($ExtensionName -eq $LeetBuildRepository) {
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

        # Indicates that this cmdlet ignores build extensions that are not refistered.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [Switch]
        $IgnoreMissingExtensions
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        $ExtensionName | ForEach-Object {
            if (!$script:Extensions.ContainsKey($_)) {
                throw $LocalizedData.Error_UnregisterBuildExtension_Reason -f
                    ($LocalizedData.Exception_ExtensioNotFound_ExtensionName -f $_)
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
    #>
    [CmdletBinding(PositionalBinding = $False,
                   SupportsShouldProcess = $True,
                   ConfirmImpact = 'Low')]

    param (
        # Name of the extension for which the build task shall be unregistered.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionName,

        # Name of the tasks that shall be unrefistered.
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
        $IgnoreMissingTasks
    )

    begin {
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        if (!$script:Extensions.ContainsKey($ExtenstionName)) {
            throw $LocalizedData.Error_UnregisterBuildTask_Reason -f
                ($LocalizedData.Exception_ExtensioNotFound_ExtensionName -f $ExtensionName)
        }

        $extension = $script:Extensions[$ExtenstionName]
        if ($TaskName) {
            $TaskName | ForEach-Object {
                if ($extension.Tasks.ContainsKey($_)) {
                    $target = $LocalizedData.BuildTask_ExtensionName_TaskName -f $ExtensionName, $_
                    $action = $LocalizedData.Unregister
                    if ($PSCmdlet.ShouldProcess($target, $action)) {
                        $extension.Tasks.Remove($_)
                    }
                }
                elseif (-not $IgnoreMissingTasks) {
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
            if ($_ -and $_ -is [scriptblock] -and $_.Module -and ($_.Module.Name -ne 'Leet.Build.Extensibility')) {
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
                $_ -and $_.Module -and $_.Module.Name -ne 'Leet.Build.Extensibility'
            } | Select-Object -First 1

            if ($scriptBlock) {
                $result = $scriptBlock.Module.Name
            }
        }

        if ($result -eq "Leet.Build") {
            $result = $LeetBuildRepository
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
                if ($task.Before -contains $currentTaskName) {
                    Invoke-BuildTaskCore $Extension $task.Name $ProjectPath $AdditionalArguments $TasksAlreadyRun
                }
            }

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

            foreach ($task in $Extension.Tasks.Values) {
                if ($task.After -contains $currentTaskName) {
                    Invoke-BuildTaskCore $Extension $task.Name $ProjectPath $AdditionalArguments $TasksAlreadyRun
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

        # Prefix that may be used in parameters machting.
        [Parameter(HelpMessage = "Provide a string that may be used in parameters machting.",
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
        $namedParameters, $positionlParameters = Leet.Build.Arguments\Select-CommandArgumentSet $ScriptBlock $ParameterPrefix $AdditionalArguments
        . $ScriptBlock @namedParameters @positionlParameters
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
    ##  Array of names of the tasks before execution of wihich the current shall be executed.
    #>
    [String[]] $Before

    <#
    ##  Array of names of the task after execution of wihich the current shall be executed.
    #>
    [String[]] $After

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
    TaskDefinition([String] $name, [String[]] $before, [String[]] $after,
                          [Boolean] $isDefault, [Object] $condition, [Object[]] $jobs) {
        $this.Name = $name
        $this.Before = @()
        if ($before) {
            $this.Before += $before
        }

        $this.After = @()
        if ($after) {
            $this.After += $after
        }

        $this.IsDefault = $isDefault
        $this.Condition = $condition
        $this.Jobs = $jobs
    }

    [TaskDefinition] Clone() {
        return [TaskDefinition]::new($this.Name,
            $this.Before.Clone(),
            $this.After.Clone(),
            $this.IsDefault,
            $this.Condition,
            $this.Jobs.Clone())
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
