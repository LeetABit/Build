#requires -version 6
using namespace System.Collections
using namespace System.Collections.Generic
using namespace Microsoft.PowerShell.Commands
using module LeetABit.Build.Common
using module LeetABit.Build.Extensibility

Set-StrictMode -Version 3.0
Import-LocalizedData -BindingVariable LocalizedData -FileName LeetABit.Build.Resources.psd1

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-Module LeetABit.Build.* -Force
}


##################################################################################################################
# Public Commands
##################################################################################################################


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
        [String]
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
        $projectPath = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'SourceRoot'

        LeetABit.Build.Extensibility\Resolve-Project $projectPath 'LeetABit.Build.Repository' $TaskName | Select-Object -Unique | ForEach-Object {
            $projectPath, $extensionName = $_
            LeetABit.Build.Extensibility\Invoke-BuildTask $extensionName $TaskName $projectPath
        }
    }
}


##################################################################################################################
# Private Commands
##################################################################################################################


function Initialize-WellKnownParameters {
    <#
    .SYNOPSIS
        Initializes a set of well known parameters with its default values.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The directory to the repository's root directory path.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $RepositoryRoot,
        
        # Collection fo extension modules to import.
        [Parameter(Mandatory = $False,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [ModuleSpecification[]]
        $ExtensionModule)

    process {
        LeetABit.Build.Arguments\Add-CommandArgument 'ArtifactsRoot' (Join-Path $RepositoryRoot 'artifacts') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Add-CommandArgument 'SourceRoot' (Join-Path $RepositoryRoot 'src') -ErrorAction SilentlyContinue
        LeetABit.Build.Arguments\Add-CommandArgument 'TestRoot' (Join-Path $RepositoryRoot 'test') -ErrorAction SilentlyContinue
        [ModuleSpecification[]]$existingExtensionModule = LeetABit.Build.Arguments\Find-CommandArgument -ParameterName 'ExtensionModule'
        [ModuleSpecification[]]$uniqueExtensionModule = (($existingExtensionModule + $ExtensionModule) | Select-Object -Unique)
        LeetABit.Build.Arguments\Add-CommandArgument 'ExtensionModule' $uniqueExtensionModule -ErrorAction SilentlyContinue
    }
}


function Import-RepositoryExtension {
    <#
    .SYNOPSIS
        Executes LeetABit.Build.Repository scripts from the specified repository.
    #>
    [CmdletBinding(PositionalBinding = $False)]

    param (
        # The directory to the repository's root directory path.
        [Parameter(HelpMessage = "Provide path to the repository's root directory.",
                   Position = 0,
                   Mandatory = $True,
                   ValueFromPipeline = $False,
                   ValueFromPipelineByPropertyName = $False)]
        [String]
        $RepositoryRoot)

    process {
        Get-ChildItem -Path $RepositoryRoot -Filter "LeetABit.Build.Repository.ps1" -Recurse | ForEach-Object {
            . "$_"
        }
    }
}


Export-ModuleMember -Function '*' -Variable '*' -Alias '*' -Cmdlet '*'
