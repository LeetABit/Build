#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 3.0

function Get-BuildHelp {
    <#
    .SYNOPSIS
        Gets help about build scripts usage.
    .DESCRIPTION
        Get-BuildHelp cmdlet provides a concise documentation about each of the loaded extensions and build tasks.
    .EXAMPLE
        PC> Get-BuildHelp

        Gets help about all registered build extensions and tasks.
    .EXAMPLE
        PC> Get-BuildHelp -ExtensionTopic "PowerShell"

        Gets a detailed help about all tasks provided by "PowerShell" extension.
    .EXAMPLE
        PC> Get-BuildHelp -TaskTopic "build"

        Gets a detailed help about all build commands provided by different extensions.
    .EXAMPLE
        PC> Get-BuildHelp -ExtensionTopic "PowerShell" -TaskTopic "build"

        Gets a detailed help about "build" task provided by "PowerShell" extension.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # Optional name of the build extension for which help shall be obtained.
        [Parameter(Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $ExtensionTopic,

        # Optional name of the build task for which help shall be obtained.
        [Parameter(Position = 1,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $TaskTopic
    )

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $scriptName = Join-Path '.' 'run.ps1'
    }

    process {
        $typeNameSuffix = if ($ExtensionTopic) {
            if ($TaskTopic) { 'DetailedView' } else { 'ExtensionView' }
        }
        else {
            if ($TaskTopic) { 'TaskView' } else { 'GeneralView' }
        }

        $helpInfo = @{}
        $helpInfo.ScriptName = $scriptName
        $helpInfo.Synopsis = $LocalizedData.Get_BuildHelp_Buildstrapper_Synopsis
        $helpInfo.TaskTopic = $TaskTopic
        $helpInfo.ExtensionTopic = $ExtensionTopic
        $helpInfo.Extensions = @()

        foreach ($currentExtension in LeetABit.Build.Extensibility\Get-BuildExtension) {
            if ($ExtensionTopic -and $ExtensionTopic -ne $currentExtension.Name) {
                continue
            }

            $extension = @{}
            $extension.Name = $currentExtension.Name
            $extension.Description = ''

            if ($currentExtension.Resolver.Module -and $currentExtension.Resolver.Module.Name -ne 'LeetABit.Build.Extensibility') {
                $extension.Description = $currentExtension.Resolver.Module.Description
            }

            $extension.Tasks = @{}

            foreach ($currentTask in $currentExtension.Tasks.Values) {
                if ($TaskTopic -and $TaskTopic -ne $currentTask.Name) {
                    continue
                }

                $task = @{}
                $task.Name = $currentTask.Name
                $task.IsDefault = $currentTask.IsDefault
                $task.Jobs = @()
                $task.Description = @()
                $task.Parameters = @()

                $currentTask.Jobs | ForEach-Object {
                    if ($_ -is [String]) {
                        $task.Jobs += $_
                        $task.Description += $extension.Tasks[$_].Description
                        $task.Parameters += $extension.Tasks[$_].Parameters
                    }
                    else {
                        if (-not $extension.Description) {
                            if ($_.Module) {
                                $extension.Description = $_.Module.Description
                            }
                        }

                        $jobScriptBlock = [String]$_
                        $function:private:ScriptBlockCommand = $jobScriptBlock
                        $helpObject = Get-Help 'ScriptBlockCommand'
                        $helpString = (Get-Help 'ScriptBlockCommand' -Full | Out-String)

                        $job = @{}
                        $job.Description = $helpObject.Synopsis
                        $task.Description += $helpObject.Synopsis

                        $nextSection = if ($helpObject.PSObject.TypeNames -contains 'ExtendedCmdletHelpInfo') {
                            'PARAMETERS'
                        }
                        else {
                            'DESCRIPTION'
                        }

                        $startIndex = $helpString.IndexOf("SYNTAX") + "SYNTAX".Length
                        $endIndex   = $helpString.IndexOf($nextSection, $startIndex)
                        $syntaxText = $helpString.Substring($startIndex, $endIndex - $startIndex).Trim()

                        $syntaxString = ($syntaxText -split [Environment]::NewLine) -join ''
                        $syntax = "$scriptName $($task.Name)"
                        $regex = $Regex_ScriptBlockSyntax_FunctionName -f 'ScriptBlockCommand'

                        if ($syntaxString -match $regex) {
                            $syntax += "$($matches[1])"
                        }

                        $job.Syntax = $syntax.Trim()
                        $job.Parameters = @()

                        if ($helpObject.parameters.PSObject.Properties.Name -contains 'parameter') {
                            foreach ($parameterObject in $helpObject.parameters.parameter) {
                                $parameter = @{}
                                $parameter.Name = $parameterObject.Name
                                if ($parameterObject.PSObject.Properties.Name -contains "type") {
                                    $parameter.Type = $parameterObject.type.name
                                }

                                if ($parameterObject.PSObject.Properties.Name -contains "description") {
                                    if ($parameterObject.description -is [String]) {
                                        $parameter.Description = $parameterObject.description
                                    }
                                    else {
                                        $parameter.Description = $parameterObject.description.Text
                                    }
                                }
                                else {
                                    $parameter.Description = ""
                                }

                                $parameter.Mandatory = [System.Convert]::ToBoolean($parameterObject.required)
                                $parameterObject = Convert-DictionaryToHelpObject -Properties $parameter -HelpObjectName 'Parameter' -HelpView $typeNameSuffix
                                $task.Parameters += $parameterObject
                                $job.Parameters += $parameterObject
                            }
                        }

                        $task.Jobs += Convert-DictionaryToHelpObject -Properties $job -HelpObjectName 'Job' -HelpView $typeNameSuffix
                    }
                }

                $parametersDictionary = @{}

                if ($task.Parameters) {
                    $task.Parameters | ForEach-Object {
                        if ($parametersDictionary.ContainsKey($_.Name)) {
                            $alreadyStored = $parametersDictionary[$_.Name]
                            $parametersDictionary.Remove($_.Name)

                            if ($alreadyStored.Type -ne $_.Type) {
                                $alreadyStored.Type = "String"
                            }

                            if ($alreadyStored.Description -notcontains $_.Description) {
                                $alreadyStored.Description += $_.Description
                            }

                            $alreadyStored.Mandatory = $alreadyStored.Mandatory -or $_.Mandatory
                            $parametersDictionary.Add($alreadyStored.Name, $alreadyStored)
                        }
                        else {
                            $_.Description = @($_.Description)
                            $parametersDictionary.Add($_.Name, $_)
                        }
                    }
                }

                $task.Description = (($task.Description | Get-Unique) -join " ").Trim()
                $task.Parameters = $parametersDictionary.Values | Sort-Object -Property Name
                $extension.Tasks.Add($task.Name, (Convert-DictionaryToHelpObject -Properties $task -HelpObjectName 'Task' -HelpView $typeNameSuffix))
            }

            if (-not $TaskTopic -or $extension.Tasks) {
                $extension.Tasks = $extension.Tasks.Values;
                $helpInfo.Extensions += Convert-DictionaryToHelpObject -Properties $extension -HelpObjectName 'Extension' -HelpView $typeNameSuffix
            }
        }

        Convert-DictionaryToHelpObject -Properties $helpInfo -HelpObjectName 'HelpInfo' -HelpView $typeNameSuffix
    }
}
