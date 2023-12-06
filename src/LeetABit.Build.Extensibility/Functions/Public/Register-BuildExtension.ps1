#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Management.Automation

Set-StrictMode -Version 3.0

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
    .PARAMETER Resolver
        ScriptBlock that resolves path to the projects recognized by the specified extension.
    .PARAMETER ExtensionName
        Name of the extension for which the registration shall be performed.
    .PARAMETER BuildInitializer
        ScriptBlock that gets called at the begining of each repository build.
    .PARAMETER Force
        Indicates that this cmdlet overwrites already registered extension removing all registered tasks and resolver.
    .EXAMPLE
        PS> Register-BuildExtension -ExtensionName "PowerShell"

        Register a default resolver for a "PowerShell" extension if it is not already registered.
    .EXAMPLE
        PS> Register-BuildExtension { "./Project.sln" } -Force

        Tries to evaluate name of the module that called Register-BuildExtension cmdlet and in case of success register a specified resolver for the extension with the name of the evaluated module regardless the extension is already registered or not.
    .NOTES
        When an extension has already registered a resolver of task and a -Force switch is used any registered resolver and all registered tasks are removed during execution of this cmdlet.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default',
                   PositionalBinding = $False)]


    param (
        [Parameter(HelpMessage = 'Provide a resolver ScriptBlock.',
                   Position = 0,
                   Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False,
                   ParameterSetName = "Resolver")]
        [Object]
        $Resolver = $script:DefaultResolver,

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

        [Parameter()]
        [Object]
        $BuildInitializer,

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
        $resolverScriptBlock = if ($Resolver -is [CommandInfo]) {
            $Resolver.ScriptBlock
        } else {
            $Resolver
        }

        $initializerScriptBlock = if ($BuildInitializer -is [CommandInfo]) {
            $BuildInitializer.ScriptBlock
        } else {
            $BuildInitializer
        }

        if (-not $ExtensionName) {
            $usedScriptBlock = if ($resolverScriptBlock -ne $script:DefaultResolver) {
                $resolverScriptBlock
            } else {
                $initializerScriptBlock
            }

            $callingModuleName = Get-CallingModuleName $usedScriptBlock
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
        $extension.Resolver = $resolverScriptBlock
        $extension.BuildInitializer = $initializerScriptBlock
        $script:Extensions.Add($ExtensionName, $extension)
    }
}
