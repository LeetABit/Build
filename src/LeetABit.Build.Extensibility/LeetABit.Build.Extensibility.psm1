#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Diagnostics.CodeAnalysis

Set-StrictMode -Version 3.0

$script:Extensions = @{}
$script:DefaultResolver = {
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]
    <#
    .SYNOPSIS
        Provides a default mechanism of project resolution for build extension.
    #>
    param (
        # Path to the project.
        [String]
        $ResolutionRoot
    )

    $ResolutionRoot
}

$script:moduleMetadata = Read-ModuleMetadata $MyInvocation
if ($script:moduleMetadata.Resources) {
    Import-LocalizedData -BindingVariable 'LocalizedData' -FileName $script:moduleMetadata.Resources.Name
}

$script:moduleMetadata.ScriptFiles | ForEach-Object { . $_ }
Export-ModuleMember -Function $script:moduleMetadata.PublicFunctionNames

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
