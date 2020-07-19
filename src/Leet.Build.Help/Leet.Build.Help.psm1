#requires -version 6
using namespace System.Collections

Set-StrictMode -Version 2
Import-LocalizedData -BindingVariable LocalizedData -FileName Leet.Build.Help.Resources.psd1

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    if (Get-Module 'Leet.Build.Extensibility') {
        Leet.Build.Extensibility\Unregister-Extension "Leet.Build.Help" -ErrorAction SilentlyContinue
    }
}

$Regex_ScriptBlockSyntax_FunctionName = '(?<={0})(.+?)(?=\[(-WhatIf|-Confirm|\<CommonParameters\>))'


##################################################################################################################
# Target Handlers
##################################################################################################################

Register-BuildTask "help" -Jobs {
    <#
    .SYNOPSIS
    Gets help for the build script or one of its targets.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        Get-LeetBuildHelp $ExtensionTopic $TaskTopic | Out-Default
    }
}


##################################################################################################################
# Public Commands
##################################################################################################################


function Get-LeetBuildHelp {
    <#
    .SYNOPSIS
    Writes help message about build scripts usage.
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
        Leet.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
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
        $helpInfo.Synopsis = $LocalizedData.Get_LeetBuildHelp_Buildstrapper_Synopsis
        $helpInfo.TaskTopic = $TaskTopic
        $helpInfo.ExtensionTopic = $ExtensionTopic
        $helpInfo.Extensions = @()

        foreach ($currentExtension in Leet.Build.Extensibility\Get-BuildExtension) {
            if ($ExtensionTopic -and $ExtensionTopic -ne $currentExtension.Name) {
                continue
            }

            $extension = @{}
            $extension.Name = $currentExtension.Name
            $extension.Description = ''

            if ($currentExtension.Resolver.Module -and $currentExtension.Resolver.Module.Name -ne 'Leet.Build.Extensibility') {
                $extension.Description = $currentExtension.Resolver.Module.Description
            }

            $extension.Tasks = @()

            foreach ($currentTask in $currentExtension.Tasks.Values) {
                if ($TaskTopic -and $TaskTopic -ne $currentTask.Name) {
                    continue
                }

                $task = @{}
                $task.Name = $currentTask.Name
                $task.Before = $currentTask.Before.Clone()
                $task.After = $currentTask.After.Clone()
                $task.IsDefault = $currentTask.IsDefault
                $task.Jobs = @()

                $currentTask.Jobs | ForEach-Object {
                    if ($_ -is [String]) {
                        $task.Jobs += $_
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

                        if ($helpObject.parameters.PSobject.Properties.Name -contains 'parameter') {
                            foreach ($parameterObject in $helpObject.parameters.parameter) {
                                if (Get-Member -InputObject $parameterObject -Name "description" -ErrorAction SilentlyContinue) {
                                    $parameter = @{}
                                    $parameter.Name = $parameterObject.Name
                                    $parameter.Type = $parameterObject.type.name
                                    $parameter.Description = $parameterObject.description.Text
                                    $parameter.Mandatory = [System.Convert]::ToBoolean($parameterObject.required)
                                    $job.Parameters += Convert-DictionaryToHelpObject $parameter 'Parameter' $typeNameSuffix
                                }
                            }
                        }

                        $task.Jobs += Convert-DictionaryToHelpObject $job 'Job' $typeNameSuffix
                    }
                }

                $extension.Tasks += Convert-DictionaryToHelpObject $task 'Task' $typeNameSuffix
            }

            if (-not $TaskTopic -or $extension.Tasks) {
                $helpInfo.Extensions += Convert-DictionaryToHelpObject $extension 'Extension' $typeNameSuffix
            }
        }

        Convert-DictionaryToHelpObject $helpInfo 'HelpInfo' $typeNameSuffix
    }
}


##################################################################################################################
# Private Commands
##################################################################################################################



function Convert-DictionaryToHelpObject {
    <#
    .SYNOPSIS
        Convets a hashtable to a PSObject using keys as property names with associated values.
    #>
    [CmdletBinding(PositionalBinding = $False)]
    [OutputType([String])]

    param (
        # A hashtable with desired object's properties.
        [Parameter(Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [IDictionary]
        $Properties,

        # A name of the help object's type that shall be assigned to the object.
        [Parameter(Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $HelpObjectName,

        # A name of the help object's type suffix that shall be assigned to the object as a secondary type.
        [Parameter(Position = 2,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String]
        $HelpView
    )

    begin {
        $typeNameNamespace = 'Leet.Build.'
    }

    process {
        Convert-DictionaryToPSObject $Properties ($typeNameNamespace + $HelpObjectName + ".$HelpView"), ($typeNameNamespace + $HelpObjectName)
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
