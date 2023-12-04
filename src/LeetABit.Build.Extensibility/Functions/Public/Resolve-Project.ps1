#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6

Set-StrictMode -Version 3.0

function Resolve-Project {
    <#
    .SYNOPSIS
        Resolves paths to the projects found in the specified location.
    .DESCRIPTION
        Resolve-Project cmdlet tries to resolve projects inside specified directory using particular specified extension or all registered extensions.
    .PARAMETER Path
        Path to location from which the project shall be resolved.
    .PARAMETER ExtensionName
        Name of the extension for which the project shall be resolved.
    .PARAMETER TaskName
        Name of the task that the extension shall provide. Extensions that do not support this task are not evaluated during the execution.
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
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $Path = (LeetABit.Build.Arguments\Find-CommandArgument 'SourceRoot'),

        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $ExtensionName,

        [Parameter(Position = 2,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String[]]
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
                    $found = $false
                    foreach ($task in $TaskName) {
                        if ($extension.Tasks.ContainsKey($task)) {
                            $found = $true
                            break
                        }
                    }

                    if (-not $found) {
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
                    AdditionalArguments = @{'ResolutionRoot' = $Path}
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
                        Write-Output -InputObject @($resolvedPath, $resolvedExtensionName) -NoEnumerate
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
                    Write-Output -InputObject @($Path,$ExtensionName) -NoEnumerate
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
