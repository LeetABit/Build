#########################################################################################
# Copyright (c) Hubert Bukowski. All rights reserved.
# Licensed under the MIT License.
# See License.txt in the project root for full license information.
#########################################################################################
#requires -version 6
using namespace System.Collections
using namespace Microsoft.PowerShell.Commands
using module LeetABit.Build.Common

Set-StrictMode -Version 3.0

function Build-Repository {
    <#
    .SYNOPSIS
        Performs a build operation on all projects located in the specified repository.
    .DESCRIPTION
        Build-Repository cmdlet runs project resolution for all registered extensions against specified repository root directory. And then run specified task for all projects and its extensions.
    .EXAMPLE
        PS> Build-Repository '~/repository' 'help'

        Runs a help task for all extensions that supports it using no additional arguments.
    .EXAMPLE
        PS> Build-Repository '~/repository' 'build' -ExtensionModule @{ModuleName = "PowerShell"; ModuleVersion = "1.0.0"}

        Loads "PowerShell" extension and runs a build task for all extensions that supports it using no additional arguments.
    .EXAMPLE
        PS> Build-Repository '~/repository' -NamedArguments @{ 'CompilerVersion' = '1.0.0' } -UnknownArguments ("-Debug")

        Runs a default build task for all extensions that supports it using specified additional arguments.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The path to the repository root folder.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateContainerPathAttribute()]
        [String]
        $RepositoryRoot,

        # Name of the build task to invoke.
        [Parameter(Position = 1,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [ValidateIdentifierOrEmptyAttribute()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [String[]]
        $TaskName,

        # Extension modules to import.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [ModuleSpecification[]]
        $ExtensionModule,

        # Dictionary of buildstrapper arguments (including dynamic ones) that have been successfully bound.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [IDictionary]
        $NamedArguments,

        # Arguments to be passed to the target.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $True)]
        [String[]]
        $UnknownArguments)

    begin {
        LeetABit.Build.Common\Import-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        LeetABit.Build.Logging\Write-Invocation -Invocation $MyInvocation
        LeetABit.Build.Arguments\Set-CommandArgumentSet -RepositoryRoot $RepositoryRoot -NamedArguments $NamedArguments -UnknownArguments $UnknownArguments
        Initialize-WellKnownParameters -RepositoryRoot $RepositoryRoot -ExtensionModule $ExtensionModule

        $ExtensionModule = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'ExtensionModule'
        if ($ExtensionModule) {
            $ExtensionModule | ForEach-Object {
                if (-not (Get-Module -FullyQualifiedName @{ ModuleName="$($_.Name)"; ModuleVersion=$_.RequiredVersion } -ListAvailable)) {
                    Write-Verbose "Installing $($_.Name) v$($_.RequiredVersion) from the available PowerShell repositories..."
                    Install-Module -Name $_.Name -RequiredVersion $_.RequiredVersion -Scope CurrentUser -AllowPrerelease -Force
                }
            }

            Import-Module -FullyQualifiedName $ExtensionModule
        }

        Import-RepositoryExtension -RepositoryRoot $RepositoryRoot

        $TaskName = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'TaskName' -DefaultValue $TaskName
        $SourceRoot = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'SourceRoot'
        $projectPath = $SourceRoot

        $lastExtension = $Null
        $aggregatedProjects = @()

        LeetABit.Build.Extensibility\Resolve-Project $projectPath 'LeetABit.Build.Repository' $TaskName | Select-Object -Unique | ForEach-Object {
            $projectPath, $extensionName = $_
            if ($lastExtension -and $lastExtension -ne $extensionName) {
                LeetABit.Build.Extensibility\Invoke-BuildTask $lastExtension $TaskName $aggregatedProjects $SourceRoot
                $aggregatedProjects = @()
            }

            $lastExtension = $extensionName
            $aggregatedProjects += $projectPath
        }

        if ($lastExtension) {
            LeetABit.Build.Extensibility\Invoke-BuildTask $lastExtension $TaskName $aggregatedProjects $SourceRoot
        }
    }
}
